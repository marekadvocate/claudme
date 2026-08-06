#!/bin/bash
# The page's JS lives inline, so a syntax error is invisible until a browser loads it —
# and a single duplicate `const` silently kills every feature on the page. Parse it here.
set -e
cd "$(dirname "$0")"
python3 - <<'PY' > /tmp/claudme-inline.js
import re
html = open('index.html', encoding='utf-8').read()
blocks = re.findall(r'<script(?![^>]*\bsrc=)[^>]*>(.*?)</script>', html, re.S)
print('\n;\n'.join(blocks))
PY
node --check /tmp/claudme-inline.js && echo "index.html: inline script parses"
