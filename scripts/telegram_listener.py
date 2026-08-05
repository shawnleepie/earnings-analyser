#!/usr/bin/env python3
"""
telegram_listener.py

Long-polls the Telegram Bot API for new messages and, when one matches an
"analyse <company>" pattern against config/companies.yaml aliases, invokes
Claude Code non-interactively to run the /analyse-earnings pipeline.

Why polling, not a webhook: a webhook needs a publicly reachable HTTPS
endpoint, which is awkward behind a corporate network (same constraint that
pushed news-crawler onto Telegram Bot API for outbound delivery rather than
Microsoft 365/Gmail). getUpdates long-polling is outbound-only from this
machine, so no inbound firewall/port changes are needed. Run this as an
always-on background process (Windows Task Scheduler "on logon" trigger,
or a persistent terminal) on a machine that's on when you want the trigger
to be responsive.

Env vars required (same as news-crawler):
  TELEGRAM_BOT_TOKEN
  TELEGRAM_CHAT_ID      (only messages from this chat are actioned)

Run:
  python scripts/telegram_listener.py
"""

import os
import re
import sys
import time
import subprocess
import yaml
import requests

BOT_TOKEN = os.environ.get("TELEGRAM_BOT_TOKEN")
CHAT_ID = os.environ.get("TELEGRAM_CHAT_ID")
POLL_INTERVAL_SECONDS = 5
COMPANIES_YAML = os.path.join(os.path.dirname(__file__), "..", "config", "companies.yaml")

TRIGGER_PATTERN = re.compile(
    r"\banaly[sz]\w*\b.*?\b(?:result|earnings|release)s?\b.*?\bfrom\b\s+(?P<company>.+)",
    re.IGNORECASE,
)
# Also accept the simpler "analyse/analyze <company>" form without "result(s) from".
SIMPLE_PATTERN = re.compile(r"\banaly[sz]\w*\b\s+(?P<company>.+)", re.IGNORECASE)


def load_aliases():
    with open(COMPANIES_YAML, "r") as f:
        data = yaml.safe_load(f)
    alias_map = {}
    for entity in data.get("entities", []):
        for alias in entity.get("aliases", []) + [entity["ticker"]]:
            alias_map[alias.lower()] = entity["ticker"]
    return alias_map


def match_company(text, alias_map):
    m = TRIGGER_PATTERN.search(text) or SIMPLE_PATTERN.search(text)
    if not m:
        return None
    candidate = m.group("company").strip().lower().rstrip(".!? ")
    # exact alias match first
    if candidate in alias_map:
        return alias_map[candidate]
    # loose substring match as a fallback
    for alias, ticker in alias_map.items():
        if alias in candidate or candidate in alias:
            return ticker
    return None


def send_telegram_message(text):
    requests.post(
        f"https://api.telegram.org/bot{BOT_TOKEN}/sendMessage",
        json={"chat_id": CHAT_ID, "text": text},
        timeout=15,
    )


def log(msg):
    print(f"[{time.strftime('%H:%M:%S')}] {msg}", flush=True)


def trigger_analysis(ticker):
    log(f"Starting /analyse-earnings {ticker} (headless, this may take 20-60+ minutes)...")
    send_telegram_message(f"Got it — running earnings analysis for {ticker} now. This can take a while (expect 15-40+ minutes).")
    try:
        result = subprocess.run(
            ["claude", "-p", f"/analyse-earnings {ticker}",
             "--allowedTools", "WebSearch", "WebFetch", "Read", "Write", "Bash",
             "--max-turns", "150"],
            cwd=os.path.join(os.path.dirname(__file__), ".."),
            check=True,
            timeout=3600,
            capture_output=True,
            text=True,
        )
        log(f"{ticker} run finished. Last 500 chars of output:\n{result.stdout[-500:]}")
        send_telegram_message(f"{ticker} analysis run finished — check Telegram for the report, or archive/{ticker}/analysis/ if delivery didn't fire.")
    except subprocess.TimeoutExpired:
        log(f"{ticker} run exceeded 1 hour timeout — killed.")
        send_telegram_message(f"{ticker} analysis run exceeded 1 hour and was stopped — check logs before retrying.")
    except subprocess.CalledProcessError as e:
        log(f"{ticker} run failed (exit {e.returncode}). stderr:\n{e.stderr[-1000:] if e.stderr else '(none)'}")
        send_telegram_message(f"Analysis run for {ticker} failed: {e}")


def main():
    if not BOT_TOKEN or not CHAT_ID:
        print("TELEGRAM_BOT_TOKEN and TELEGRAM_CHAT_ID must be set.", file=sys.stderr)
        sys.exit(1)

    alias_map = load_aliases()
    offset = None
    log("Telegram listener running (Ctrl+C to stop)...")

    while True:
        try:
            resp = requests.get(
                f"https://api.telegram.org/bot{BOT_TOKEN}/getUpdates",
                params={"timeout": 30, "offset": offset},
                timeout=35,
            )
            updates = resp.json().get("result", [])
            for update in updates:
                offset = update["update_id"] + 1
                msg = update.get("message", {})
                if str(msg.get("chat", {}).get("id")) != str(CHAT_ID):
                    continue
                text = msg.get("text", "")
                if not text:
                    continue
                log(f"Received message: {text!r}")
                ticker = match_company(text, alias_map)
                if ticker:
                    log(f"Matched ticker: {ticker}")
                    trigger_analysis(ticker)
                    log("Back to listening for new messages...")
                else:
                    log("No ticker match — ignoring.")
                alias_map = load_aliases()
        except requests.exceptions.RequestException as e:
            log(f"Poll error (will retry): {e}")
            time.sleep(POLL_INTERVAL_SECONDS)


if __name__ == "__main__":
    main()
