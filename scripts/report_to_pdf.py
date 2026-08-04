#!/usr/bin/env python3
"""
report_to_pdf.py

Converts an earnings-analysis markdown report into a formatted PDF.
Uses markdown -> HTML -> PDF via xhtml2pdf, which is pure Python — no
native GTK/Pango/Cairo libraries required (WeasyPrint needs those on
Windows and they're a genuine install headache, often needing admin
rights). xhtml2pdf's CSS support is more limited but entirely sufficient
for headers + tables.

Install once:
  pip install markdown xhtml2pdf

Run:
  python scripts/report_to_pdf.py <path/to/report.md> <path/to/output.pdf>
"""

import sys
import markdown
from xhtml2pdf import pisa

CSS = """
@page { size: A4; margin: 2cm; }
body { font-family: 'Georgia', 'Times New Roman', serif; font-size: 10.5pt; line-height: 1.4; color: #1a1a1a; }
h1 { font-size: 16pt; border-bottom: 2px solid #1a1a1a; padding-bottom: 6px; }
h2 { font-size: 13pt; margin-top: 20px; border-bottom: 1px solid #999; padding-bottom: 3px; }
h3 { font-size: 11pt; margin-top: 14px; }
table { border-collapse: collapse; width: 100%; margin: 10px 0; font-size: 9pt; }
th, td { border: 1px solid #ccc; padding: 4px 8px; text-align: right; }
th, td:first-child { text-align: left; }
th { background: #f0f0f0; font-weight: bold; }
ul, ol { margin: 6px 0; padding-left: 20px; }
code { background: #f5f5f5; padding: 1px 4px; }
"""


def convert(md_path, pdf_path):
    with open(md_path, "r", encoding="utf-8") as f:
        md_text = f.read()

    html_body = markdown.markdown(md_text, extensions=["tables", "fenced_code"])
    full_html = f"<html><head><style>{CSS}</style></head><body>{html_body}</body></html>"

    with open(pdf_path, "wb") as f:
        result = pisa.CreatePDF(full_html, dest=f)

    if result.err:
        print(f"xhtml2pdf reported {result.err} error(s) converting {md_path}", file=sys.stderr)
        sys.exit(1)

    print(f"Wrote {pdf_path}")


if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: python report_to_pdf.py <input.md> <output.pdf>", file=sys.stderr)
        sys.exit(1)
    convert(sys.argv[1], sys.argv[2])
