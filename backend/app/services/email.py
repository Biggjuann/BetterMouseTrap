"""Email service using Resend HTTP API."""

import logging

import httpx

from app.core.config import settings

log = logging.getLogger("mousetrap.email")

RESEND_API_URL = "https://api.resend.com/emails"


async def send_email(to: str, subject: str, html: str) -> bool:
    """Send an email via Resend. Returns True on success."""
    if not settings.resend_api_key:
        log.warning("RESEND_API_KEY not set — email not sent to %s", to)
        return False

    try:
        async with httpx.AsyncClient() as client:
            resp = await client.post(
                RESEND_API_URL,
                headers={
                    "Authorization": f"Bearer {settings.resend_api_key}",
                    "Content-Type": "application/json",
                },
                json={
                    "from": settings.resend_from_email,
                    "to": [to],
                    "subject": subject,
                    "html": html,
                },
                timeout=10.0,
            )
        if resp.status_code in (200, 201):
            log.info("Email sent to %s", to)
            return True
        else:
            log.error("Resend API error %s: %s", resp.status_code, resp.text)
            return False
    except Exception as e:
        log.error("Failed to send email: %s", e)
        return False


async def send_reset_code(to: str, code: str) -> bool:
    """Send a password reset code email."""
    html = f"""
    <div style="font-family: 'Manrope', Arial, sans-serif; max-width: 480px; margin: 0 auto; padding: 32px;">
        <h2 style="color: #3D2E1F; margin-bottom: 8px;">Reset Your Password</h2>
        <p style="color: #4C4639; font-size: 16px;">
            Enter this code in the app to reset your password:
        </p>
        <div style="background: #FFF9F0; border: 2px solid #D4A954; border-radius: 12px;
                    padding: 24px; text-align: center; margin: 24px 0;">
            <span style="font-size: 36px; font-weight: 800; letter-spacing: 8px; color: #D4A954;">
                {code}
            </span>
        </div>
        <p style="color: #7D7667; font-size: 14px;">
            This code expires in 15 minutes. If you didn't request a password reset,
            you can safely ignore this email.
        </p>
        <hr style="border: none; border-top: 1px solid #E8E2D5; margin: 24px 0;" />
        <p style="color: #94A3B8; font-size: 12px;">MouseTrap - Turn any product into your next big idea.</p>
    </div>
    """
    return await send_email(to, "Your MouseTrap Reset Code", html)
