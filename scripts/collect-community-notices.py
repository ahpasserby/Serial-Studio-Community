"""Collect notices from bundled sources and the Homebrew Qt dependencies."""
from pathlib import Path
import shutil
import subprocess
import sys
repo, output = map(Path, sys.argv[1:])
roots = [(repo / 'lib', 'vendored')]
qt = [name for name in subprocess.check_output(['brew', 'list', '--formula'], text=True).splitlines() if name.startswith('qt')]
deps = subprocess.check_output(['brew', 'deps', '--union', '--installed', *qt], text=True).splitlines()
formulas = sorted(set(qt + deps))
for formula in formulas:
    root = Path(subprocess.check_output(['brew', '--prefix', formula], text=True).strip())
    roots.append((root, formula))
# Record precise source downloads rather than publishing any local Homebrew metadata.
import json
info = json.loads(subprocess.check_output(['brew', 'info', '--json=v2', *formulas], text=True))
output.mkdir(parents=True, exist_ok=True)
sources = [{'name': f['name'], 'version': f['versions']['stable'], 'license': f.get('license'),
            'homepage': f.get('homepage'), 'source': f.get('urls', {}).get('stable')} for f in info['formulae']]
(output / 'SOURCES.json').write_text(json.dumps(sources, indent=2) + '\n')
for root, label in roots:
    for source in root.rglob('*'):
        if source.is_file() and (source.name.upper().startswith(('LICENSE', 'COPYING', 'NOTICE')) or 'LICENSES' in source.parts):
            dest = output / label / source.relative_to(root)
            dest.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(source, dest)
