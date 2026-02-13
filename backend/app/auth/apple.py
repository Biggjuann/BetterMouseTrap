"""Apple Sign-In identity token verification."""

import time

import httpx
from jose import jwt, JWTError

from app.core.config import settings

APPLE_KEYS_URL = "https://appleid.apple.com/auth/keys"
APPLE_ISSUER = "https://appleid.apple.com"

# Cache Apple's JWKS (keys rotate infrequently)
_jwks_cache: dict | None = None
_jwks_cache_time: float = 0
_JWKS_TTL = 3600  # 1 hour


async def _get_apple_jwks() -> dict:
    """Fetch and cache Apple's JSON Web Key Set."""
    global _jwks_cache, _jwks_cache_time

    if _jwks_cache and (time.time() - _jwks_cache_time) < _JWKS_TTL:
        return _jwks_cache

    async with httpx.AsyncClient() as client:
        resp = await client.get(APPLE_KEYS_URL)
        resp.raise_for_status()
        _jwks_cache = resp.json()
        _jwks_cache_time = time.time()
        return _jwks_cache


async def verify_apple_identity_token(identity_token: str) -> dict:
    """Verify an Apple identity token and return its claims.

    Returns dict with at least 'sub' (Apple user ID) and optionally 'email'.
    Raises ValueError if verification fails.
    """
    # Decode header to find the key ID
    try:
        unverified_header = jwt.get_unverified_header(identity_token)
    except JWTError as e:
        raise ValueError(f"Invalid token header: {e}")

    kid = unverified_header.get("kid")
    if not kid:
        raise ValueError("Token missing key ID (kid)")

    # Get Apple's public keys
    jwks = await _get_apple_jwks()

    # Find the matching key
    matching_key = None
    for key in jwks.get("keys", []):
        if key["kid"] == kid:
            matching_key = key
            break

    if matching_key is None:
        # Clear cache and retry once in case keys rotated
        global _jwks_cache
        _jwks_cache = None
        jwks = await _get_apple_jwks()
        for key in jwks.get("keys", []):
            if key["kid"] == kid:
                matching_key = key
                break

    if matching_key is None:
        raise ValueError("No matching Apple public key found")

    # Verify and decode the token
    try:
        claims = jwt.decode(
            identity_token,
            matching_key,
            algorithms=["RS256"],
            audience=settings.apple_bundle_id,
            issuer=APPLE_ISSUER,
        )
    except JWTError as e:
        raise ValueError(f"Token verification failed: {e}")

    if "sub" not in claims:
        raise ValueError("Token missing subject (sub) claim")

    return claims
