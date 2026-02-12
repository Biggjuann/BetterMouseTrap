"""LLM service abstraction — pluggable between Anthropic and OpenAI."""

import json
import logging
import re

import anthropic
import httpx

from app.core.config import settings

log = logging.getLogger("mousetrap.llm")


class LLMError(Exception):
    """Raised when an LLM call fails or returns unparseable output."""


# ── Anthropic ────────────────────────────────────────────────────────

def _call_anthropic(prompt: str, system: str | None = None, max_tokens: int | None = None) -> str:
    client = anthropic.Anthropic(api_key=settings.anthropic_api_key)
    messages = [{"role": "user", "content": prompt}]
    kwargs: dict = {
        "model": settings.llm_model,
        "max_tokens": max_tokens or settings.llm_max_tokens,
        "messages": messages,
    }
    if system:
        kwargs["system"] = system
    response = client.messages.create(**kwargs)
    return response.content[0].text


# ── OpenAI ───────────────────────────────────────────────────────────

def _call_openai(prompt: str, system: str | None = None, max_tokens: int | None = None) -> str:
    headers = {
        "Authorization": f"Bearer {settings.openai_api_key}",
        "Content-Type": "application/json",
    }
    messages = []
    if system:
        messages.append({"role": "system", "content": system})
    messages.append({"role": "user", "content": prompt})
    body = {
        "model": settings.llm_model,
        "max_tokens": max_tokens or settings.llm_max_tokens,
        "messages": messages,
    }
    resp = httpx.post(
        "https://api.openai.com/v1/chat/completions",
        headers=headers,
        json=body,
        timeout=120,
    )
    resp.raise_for_status()
    return resp.json()["choices"][0]["message"]["content"]


# ── Shared ───────────────────────────────────────────────────────────

_PROVIDERS = {
    "anthropic": _call_anthropic,
    "openai": _call_openai,
}


def _repair_truncated_json(text: str) -> dict | None:
    """Attempt to repair JSON that was truncated mid-output by closing open brackets."""
    # Find the first { or [
    start = -1
    for i, ch in enumerate(text):
        if ch in ('{', '['):
            start = i
            break
    if start == -1:
        return None

    fragment = text[start:]

    # Walk through the fragment tracking open structures, respecting strings
    stack: list[str] = []
    in_string = False
    escape_next = False
    last_valid = start  # track last position that could end a value

    for i, ch in enumerate(fragment):
        if escape_next:
            escape_next = False
            continue
        if ch == '\\' and in_string:
            escape_next = True
            continue
        if ch == '"' and not escape_next:
            in_string = not in_string
            continue
        if in_string:
            continue
        if ch in ('{', '['):
            stack.append('}' if ch == '{' else ']')
        elif ch in ('}', ']'):
            if stack:
                stack.pop()
            if not stack:
                # Fully closed — try parsing
                try:
                    return json.loads(fragment[: i + 1])
                except json.JSONDecodeError:
                    pass

    # If we get here, JSON was truncated. Try to close it.
    if not stack:
        return None

    # Trim trailing incomplete key/value: remove back to last complete value
    repair = fragment.rstrip()
    # Remove trailing comma or colon (incomplete pair)
    while repair and repair[-1] in (',', ':', '"'):
        if repair[-1] == '"':
            # Remove the incomplete string value back to the opening quote
            repair = repair[:-1]
            quote_pos = repair.rfind('"')
            if quote_pos >= 0:
                repair = repair[:quote_pos]
            repair = repair.rstrip().rstrip(',').rstrip(':')
            # If we stripped a key, also remove its preceding quote
            if repair.endswith('"'):
                repair = repair[:-1]
                qp = repair.rfind('"')
                if qp >= 0:
                    repair = repair[:qp]
                repair = repair.rstrip().rstrip(',')
            break
        repair = repair[:-1].rstrip()

    # Close all open brackets
    closing = "".join(reversed(stack))
    candidate = repair + closing

    try:
        result = json.loads(candidate)
        log.warning("Repaired truncated JSON (closed %d open brackets)", len(stack))
        return result
    except json.JSONDecodeError:
        pass

    # Last resort: more aggressive trim — find last complete value boundary
    # Look for last occurrence of `"` followed by `,` or `}` or `]`
    for trim_to in range(len(repair) - 1, max(0, len(repair) - 500), -1):
        ch = repair[trim_to]
        if ch in ('}', ']', '"') and trim_to > 0:
            candidate = repair[: trim_to + 1]
            # Remove trailing comma if any
            candidate = candidate.rstrip().rstrip(',')
            candidate += closing
            try:
                result = json.loads(candidate)
                log.warning("Repaired truncated JSON with aggressive trim")
                return result
            except json.JSONDecodeError:
                continue

    return None


def _extract_json(text: str) -> dict:
    """Extract the first JSON object or array from LLM text output."""
    # Try the whole string first
    text = text.strip()
    try:
        return json.loads(text)
    except json.JSONDecodeError:
        pass

    # Look for ```json ... ``` fenced blocks
    m = re.search(r"```(?:json)?\s*\n?(.*?)```", text, re.DOTALL)
    if m:
        try:
            return json.loads(m.group(1).strip())
        except json.JSONDecodeError:
            pass

    # Look for first { ... } or [ ... ]
    for start_char, end_char in [("{", "}"), ("[", "]")]:
        start = text.find(start_char)
        if start == -1:
            continue
        end = text.rfind(end_char)
        if end > start:
            try:
                return json.loads(text[start : end + 1])
            except json.JSONDecodeError:
                continue

    # Try to repair truncated JSON (common when max_tokens cuts off output)
    repaired = _repair_truncated_json(text)
    if repaired is not None:
        return repaired

    raise LLMError(f"Could not extract JSON from LLM response:\n{text[:500]}")


def call_llm(
    prompt: str,
    json_schema_hint: str = "",
    system: str | None = None,
    max_tokens: int | None = None,
) -> dict:
    """Call the configured LLM provider and return parsed JSON.

    Args:
        prompt: The user-facing prompt text.
        json_schema_hint: A JSON schema example appended to the prompt so the
            model knows the expected output shape.
        system: Optional system prompt.
        max_tokens: Override the default max_tokens for this call.

    Returns:
        Parsed dict from the LLM's JSON output.
    """
    provider = settings.llm_provider.lower()
    call_fn = _PROVIDERS.get(provider)
    if call_fn is None:
        raise LLMError(f"Unknown LLM provider: {provider!r}. Use 'anthropic' or 'openai'.")

    full_prompt = prompt
    if json_schema_hint:
        full_prompt += (
            "\n\nYou MUST respond with ONLY valid JSON matching this schema "
            "(no markdown fences, no extra text):\n"
            f"{json_schema_hint}"
        )

    log.info("Calling %s (model=%s, max_tokens=%s)", provider, settings.llm_model, max_tokens or settings.llm_max_tokens)
    try:
        raw = call_fn(full_prompt, system=system, max_tokens=max_tokens)
    except Exception as exc:
        raise LLMError(f"LLM call failed: {exc}") from exc

    log.debug("Raw LLM response: %s", raw[:300])
    return _extract_json(raw)


async def call_llm_async(
    prompt: str,
    json_schema_hint: str = "",
    system: str | None = None,
    max_tokens: int | None = None,
) -> dict:
    """Async wrapper around call_llm using asyncio.to_thread."""
    import asyncio
    return await asyncio.to_thread(call_llm, prompt, json_schema_hint, system, max_tokens)
