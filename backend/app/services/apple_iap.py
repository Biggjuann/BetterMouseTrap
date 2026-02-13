"""Apple App Store Server API v2 receipt verification.

StoreKit 2 transactions are signed JWS tokens. We verify the signature
chain against Apple's root certificate and extract the transaction data.
"""

import base64
import json
import logging

import httpx
from cryptography import x509
from cryptography.hazmat.primitives import hashes
from cryptography.hazmat.primitives.asymmetric import ec

from app.core.config import settings

log = logging.getLogger("mousetrap.apple_iap")

APPLE_ROOT_CERT_URL = "https://www.apple.com/certificateauthority/AppleRootCA-G3.cer"

_apple_root_cert = None


async def _get_apple_root_cert():
    """Download and cache Apple's root CA certificate."""
    global _apple_root_cert
    if _apple_root_cert is not None:
        return _apple_root_cert

    async with httpx.AsyncClient() as client:
        resp = await client.get(APPLE_ROOT_CERT_URL)
        resp.raise_for_status()
        _apple_root_cert = x509.load_der_x509_certificate(resp.content)
    return _apple_root_cert


def _base64url_decode(s: str) -> bytes:
    """Decode base64url without padding."""
    s += "=" * (4 - len(s) % 4)
    return base64.urlsafe_b64decode(s)


async def verify_and_decode_receipt(
    signed_transaction: str,
    expected_product_id: str,
    expected_bundle_id: str,
) -> dict:
    """Verify a StoreKit 2 JWS-signed transaction.

    Returns dict with original_transaction_id, product_id, bundle_id, environment.
    Raises ValueError if verification fails.
    """
    parts = signed_transaction.split(".")
    if len(parts) != 3:
        raise ValueError("Invalid JWS format")

    header_b64, payload_b64, signature_b64 = parts

    # Decode header
    header = json.loads(_base64url_decode(header_b64))
    if header.get("alg") != "ES256":
        raise ValueError(f"Unsupported algorithm: {header.get('alg')}")

    # Extract certificate chain from x5c header
    x5c = header.get("x5c", [])
    if len(x5c) < 2:
        raise ValueError("Certificate chain too short")

    # Build cert chain and verify
    leaf_cert = x509.load_der_x509_certificate(base64.b64decode(x5c[0]))
    intermediate_cert = x509.load_der_x509_certificate(base64.b64decode(x5c[1]))

    # Verify intermediate is signed by Apple root
    root_cert = await _get_apple_root_cert()
    try:
        root_cert.public_key().verify(
            intermediate_cert.signature,
            intermediate_cert.tbs_certificate_bytes,
            ec.ECDSA(intermediate_cert.signature_hash_algorithm),
        )
    except Exception as e:
        raise ValueError(f"Intermediate cert not signed by Apple: {e}")

    # Verify leaf is signed by intermediate
    try:
        intermediate_cert.public_key().verify(
            leaf_cert.signature,
            leaf_cert.tbs_certificate_bytes,
            ec.ECDSA(leaf_cert.signature_hash_algorithm),
        )
    except Exception as e:
        raise ValueError(f"Leaf cert not signed by intermediate: {e}")

    # Verify JWS signature using leaf cert
    signed_data = f"{header_b64}.{payload_b64}".encode()
    signature = _base64url_decode(signature_b64)
    try:
        leaf_cert.public_key().verify(
            signature,
            signed_data,
            ec.ECDSA(hashes.SHA256()),
        )
    except Exception as e:
        raise ValueError(f"JWS signature verification failed: {e}")

    # Decode and validate payload
    payload = json.loads(_base64url_decode(payload_b64))

    if payload.get("bundleId") != expected_bundle_id:
        raise ValueError(f"Bundle ID mismatch: {payload.get('bundleId')} != {expected_bundle_id}")

    if payload.get("productId") != expected_product_id:
        raise ValueError(f"Product ID mismatch: {payload.get('productId')} != {expected_product_id}")

    environment = payload.get("environment", "")
    if not settings.debug and environment == "Sandbox":
        raise ValueError("Sandbox receipt in production mode")

    return {
        "original_transaction_id": payload["originalTransactionId"],
        "product_id": payload["productId"],
        "bundle_id": payload["bundleId"],
        "environment": environment,
    }
