"""Check local Markdown links and current release descriptions."""
from pathlib import Path
from urllib.parse import unquote
import re
ROOT=Path(__file__).resolve().parents[1]
checked=0
for p in ROOT.rglob('*.md'):
 if any(x in p.relative_to(ROOT).parts for x in ('.git','outputs')):continue
 for target in re.findall(r'\]\(([^)]+)\)',p.read_text()):
  target=target.split(' "')[0].strip('<>');target=unquote(target.split('#')[0])
  if not target or re.match(r'^[a-z]+:',target):continue
  assert (p.parent/target).exists(),f'Broken link: {p.relative_to(ROOT)} -> {target}'
  checked+=1
assert '15 October 2026' in (ROOT/'README.md').read_text()
print(f'Documentation links PASS: {checked} local links.')
