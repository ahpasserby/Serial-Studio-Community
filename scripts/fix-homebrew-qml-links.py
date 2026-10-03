"""Materialize Qt metadata links copied relative to Homebrew's Cellar into a bundle.

Qt's post-build QML deploy copies Homebrew's relative metadata symlinks verbatim.
Those targets do not exist relative to an app's Resources/qml directory.
Only broken links with a matching Qt source file are replaced.
"""
from pathlib import Path
import shutil
import subprocess
import sys
bundle = Path(sys.argv[1])
qml_root = bundle / 'Contents/Resources/qml'
qt_qml = Path(subprocess.check_output(['qmake6', '-query', 'QT_INSTALL_QML'], text=True).strip())
for dest in qml_root.rglob('*'):
    if dest.is_symlink() and not dest.exists():
        source = qt_qml / dest.relative_to(qml_root)
        if not source.is_file():
            raise RuntimeError(f'Cannot resolve Qt resource: {dest}')
        dest.unlink()
        shutil.copy2(source.resolve(), dest)
        print(f'Repaired Qt resource: {dest.relative_to(qml_root)}')
