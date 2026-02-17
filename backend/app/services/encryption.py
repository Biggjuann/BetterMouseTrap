"""
Application-level field encryption using Fernet (AES-128-CBC + HMAC-SHA256).

- When ENCRYPTION_KEYS is set: encrypts/decrypts with MultiFernet (supports key rotation)
- When ENCRYPTION_KEYS is empty (local dev): data passes through unchanged
- Backward-compatible: detects unencrypted data by checking for Fernet token prefix
"""

import json
import logging
from typing import Any

from cryptography.fernet import Fernet, InvalidToken, MultiFernet

from app.core.config import settings

log = logging.getLogger("mousetrap.encryption")

_fernet: MultiFernet | None = None
_initialized = False

FERNET_PREFIX = "gAAAAA"


def _get_fernet() -> MultiFernet | None:
    """Lazy-init MultiFernet from settings. Returns None if no keys configured."""
    global _fernet, _initialized
    if _initialized:
        return _fernet

    raw = settings.encryption_keys.strip()
    if not raw:
        log.info("ENCRYPTION_KEYS not set — field encryption disabled (dev mode)")
        _initialized = True
        return None

    keys = [k.strip().encode() for k in raw.split(",") if k.strip()]
    fernets = [Fernet(k) for k in keys]
    _fernet = MultiFernet(fernets)
    _initialized = True
    log.info("Field encryption initialized with %d key(s)", len(fernets))
    return _fernet


def validate_keys() -> None:
    """Call on startup to fail fast if keys are malformed."""
    _get_fernet()


def encrypt_text(plaintext: str | None) -> str | None:
    """Encrypt a plaintext string. Returns ciphertext or None if input is None."""
    if plaintext is None:
        return None
    f = _get_fernet()
    if f is None:
        return plaintext
    return f.encrypt(plaintext.encode("utf-8")).decode("ascii")


def decrypt_text(ciphertext: str | None) -> str | None:
    """Decrypt a ciphertext string. Passes through plaintext gracefully."""
    if ciphertext is None:
        return None
    f = _get_fernet()
    if f is None:
        return ciphertext
    if not ciphertext.startswith(FERNET_PREFIX):
        return ciphertext  # not encrypted (legacy data)
    try:
        return f.decrypt(ciphertext.encode("ascii")).decode("utf-8")
    except InvalidToken:
        log.warning("Failed to decrypt value (wrong key?), returning raw")
        return ciphertext


def encrypt_json(data: Any) -> str | None:
    """JSON-serialize then encrypt. Returns ciphertext string or None."""
    if data is None:
        return None
    serialized = json.dumps(data, ensure_ascii=False)
    return encrypt_text(serialized)


def decrypt_json(ciphertext: str | None) -> Any:
    """Decrypt then JSON-parse. Handles raw dicts/lists from old JSON columns."""
    if ciphertext is None:
        return None
    # If it's already a dict or list (loaded from old JSON column before migration), pass through
    if isinstance(ciphertext, (dict, list)):
        return ciphertext
    plaintext = decrypt_text(ciphertext)
    if plaintext is None:
        return None
    try:
        return json.loads(plaintext)
    except (json.JSONDecodeError, TypeError):
        return plaintext
