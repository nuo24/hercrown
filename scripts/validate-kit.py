#!/usr/bin/env python3
"""Validate packaged artwork, SVG syntax, relative imports and recorded checksums."""
from pathlib import Path
import json,hashlib,struct,re,xml.etree.ElementTree as ET
root=Path(__file__).resolve().parents[1]
errors=[]
for asset in json.loads((root/'design/asset-inventory.json').read_text()):
 f=root/asset['source'];raw=f.read_bytes()
 if hashlib.sha256(raw).hexdigest()!=asset['sha256']:errors.append('Asset hash: '+asset['id'])
 if tuple(struct.unpack('>II',raw[16:24]))!=(asset['width'],asset['height']):errors.append('Asset dimensions: '+asset['id'])
 catalog=root/asset['nativeCatalog'];entries=json.loads((catalog/'Contents.json').read_text())['images']
 for entry in entries:
  if not (catalog/entry['filename']).is_file():errors.append('Catalog file: '+asset['id'])
for f in (root/'design').rglob('*.svg'):
 try:ET.parse(f)
 except Exception as exc:errors.append(f'SVG {f.name}: {exc}')
for f in (root/'reference-web/dist').glob('*'):
 if f.suffix not in ['.js','.mjs']:continue
 for path in re.findall(r"(?:from\s*|import\s*)['\"](\./[^'\"]+)['\"]",f.read_text()):
  if not (f.parent/path.split('?')[0]).exists():errors.append(f'Import {f.name}: {path}')
manifest=root/'FILE-MANIFEST.json'
if manifest.exists():
 for entry in json.loads(manifest.read_text())['files']:
  f=root/entry['path']
  if not f.exists() or hashlib.sha256(f.read_bytes()).hexdigest()!=entry['sha256']:errors.append('File hash: '+entry['path'])
if errors:raise SystemExit('\n'.join(errors))
print('PASS: artwork hashes/dimensions, Xcode catalog entries, SVG syntax, local module imports and available file manifest.')
