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

def _call_anthropic(prompt: str, system: str | None = None) -> str:
    client = anthropic.Anthropic(api_key=settings.anthropic_api_key)
    messages = [{"role": "user", "content": prompt}]
    kwargs: dict = {
        "model": settings.llm_model,
        "max_tokens": settings.llm_max_tokens,
        "messages": messages,
    }
    if system:
        kwargs["system"] = system
    response = client.messages.create(**kwargs)
    return response.content[0].text


# ── OpenAI ───────────────────────────────────────────────────────────

def _call_openai(prompt: str, system: str | None = None) -> str:
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
        "max_tokens": settings.llm_max_tokens,
        "messages": messages,
    }
    resp = httpx.post(
        "https://api.openai.com/v1/chat/completions",
        headers=headers,
        json=body,
        timeout=60,
    )
    resp.raise_for_status()
    return resp.json()["choices"][0]["message"]["content"]


# ── Shared ───────────────────────────────────────────────────────────

_PROVIDERS = {
    "anthropic": _call_anthropic,
    "openai": _call_openai,
}


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

    raise LLMError(f"Could not extract JSON from LLM response:\n{text[:500]}")


def call_llm(prompt: str, json_schema_hint: str = "", system: str | None = None) -> dict:
    """Call the configured LLM provider and return parsed JSON.

    Args:
        prompt: The user-facing prompt text.
        json_schema_hint: A JSON schema example appended to the prompt so the
            model knows the expected output shape.
        system: Optional system prompt.

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

    log.info("Calling %s (model=%s)", provider, settings.llm_model)
    try:
        raw = call_fn(full_prompt, system=system)
    except Exception as exc:
        raise LLMError(f"LLM call failed: {exc}") from exc

    log.debug("Raw LLM response: %s", raw[:300])
    return _extract_json(raw)


async def call_llm_async(
    prompt: str, json_schema_hint: str = "", system: str | None = None
) -> dict:
    """Async wrapper around call_llm using asyncio.to_thread."""
    import asyncio
    return await asyncio.to_thread(call_llm, prompt, json_schema_hint, system)
