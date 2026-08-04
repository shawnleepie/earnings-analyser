#!/usr/bin/env python3
"""
send_telegram_document.py

Sends a file (the earnings-analysis PDF) to the configured Telegram chat.
Reuses the same TELEGRAM_BOT_TOKEN / TELEGRAM_CHAT_ID env vars as
news-crawler's delivery mechanism.

Run:
  python scripts/send_telegram_document.py <path/to/file.pdf> "<caption>"
"""

import os
import sys
import requests

BOT_TOKEN = os.environ.get("TELEGRAM_BOT_TOKEN")
CHAT_ID = os.environ.get("TELEGRAM_CHAT_ID")


def send_document(filepath, caption=""):
    if not BOT_TOKEN or not CHAT_ID:
        print("TELEGRAM_BOT_TOKEN and TELEGRAM_CHAT_ID must be set.", file=sys.stderr)
        sys.exit(1)

    with open(filepath, "rb") as f:
        resp = requests.post(
            f"https://api.telegram.org/bot{BOT_TOKEN}/sendDocument",
            data={"chat_id": CHAT_ID, "caption": caption[:1024]},
            files={"document": f},
            timeout=60,
        )
    resp.raise_for_status()
    print(f"Sent {filepath} to chat {CHAT_ID}")


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print('Usage: python send_telegram_document.py <file> ["caption"]', file=sys.stderr)
        sys.exit(1)
    path = sys.argv[1]
    cap = sys.argv[2] if len(sys.argv) > 2 else ""
    send_document(path, cap)
