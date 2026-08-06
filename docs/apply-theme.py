#!/usr/bin/env python3
"""Apply a theme spec (the design panel's JSON) to index.html.

Only touches the block between the THEME markers, so re-theming never disturbs
layout or behaviour. Run: ./apply-theme.py theme.json
"""
import json, re, sys

spec = json.load(open(sys.argv[1], encoding='utf-8'))
v = spec['vars']

theme = f"""  /* ==== THEME:START ==== {spec['name']} — {spec['oneLine']} */
  :root{{
    --desk:{v['desk']}; --desk2:{v['desk2']};
    --face:{v['face']}; --hi:{v['hi']}; --lt:{v['lt']}; --sh:{v['sh']}; --dk:{v['dk']};
    --field:{v['field']};
    --title1:{v['title1']}; --title2:{v['title2']}; --title-ink:{v['titleInk']};
    --bg:{v['desk']}; --panel:{v['face']}; --panel2:{v['lt']};
    --line:{v['sh']}; --line2:{v['sh']};
    --ink:{v['ink']}; --dim:{v['dim']}; --faint:{v['faint']};
    --crab:{v['crab']}; --gold:{v['gold']};
  }}
  body{{background:{v['deskBackground']}}}
  .track > header > .wrap,
  .track > section > .wrap,
  .track > footer > .wrap{{
    border:{spec['windowBorder']};box-shadow:{spec['windowShadow']};
    border-radius:{spec['windowRadius']};
  }}
  .track > * > .wrap::before{{{spec['titleBarCss']};color:var(--title-ink)}}
  .track > * > .wrap::after{{background:var(--face);color:var(--ink)}}
  .btn,.controls button,.taskbar .start,.taskbar .tasks button{{{spec['buttonCss']}}}
  .taskbar{{{spec['taskbarCss']}}}
"""
for rule in spec.get('extras', []):
    theme += '  ' + rule.strip() + '\n'
theme += '  /* ==== THEME:END ==== */\n'

html = open('index.html', encoding='utf-8').read()
if 'THEME:START' in html:
    html = re.sub(r'  /\* ==== THEME:START ==== .*?/\* ==== THEME:END ==== \*/\n',
                  theme, html, flags=re.S)
else:
    html = html.replace('\n</style>', '\n' + theme + '</style>', 1)
open('index.html', 'w', encoding='utf-8').write(html)
print(f"applied: {spec['name']}")
