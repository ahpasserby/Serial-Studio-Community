#!/bin/bash
# SPDX-License-Identifier: GPL-3.0-only
set -euo pipefail
repo_dir="$(cd "$(dirname "$0")/.." && pwd)"
built_app="$repo_dir/build-community/app/Serial-Scope.app"
package_dir="$repo_dir/dist/Serial-Scope"
app_dir="$package_dir/Serial-Scope.app"
if [ ! -d "$built_app" ]; then echo 'Build first: ./scripts/build-community-macos.sh' >&2; exit 1; fi
if [ -e "$package_dir" ]; then echo "Output already exists: $package_dir (move it aside before packaging again)" >&2; exit 1; fi
python3 "$repo_dir/scripts/fix-homebrew-qml-links.py" "$built_app"
mkdir -p "$package_dir"
# Dereference build-tree QML links before deployment so tools never edit Homebrew files.
python3 - "$built_app" "$app_dir" <<'PY_COPY'
import shutil, sys
shutil.copytree(sys.argv[1], sys.argv[2], symlinks=False)
PY_COPY
qt_prefix="${QT_PREFIX:-$(brew --prefix)}"
"$qt_prefix/bin/macdeployqt" "$app_dir" -qmldir="$repo_dir/app/qml" -always-overwrite
# The CLI's headless mode needs the offscreen platform plugin too.
qt_plugins="$("$qt_prefix/bin/qmake6" -query QT_INSTALL_PLUGINS)"
mkdir -p "$app_dir/Contents/PlugIns/platforms"
cp -L "$qt_plugins/platforms/libqoffscreen.dylib" "$app_dir/Contents/PlugIns/platforms/"
for module in QtGui QtCore; do
  install_name_tool -change "@rpath/$module.framework/Versions/A/$module" \
    "@executable_path/../Frameworks/$module.framework/Versions/A/$module" \
    "$app_dir/Contents/PlugIns/platforms/libqoffscreen.dylib"
done
python3 "$repo_dir/scripts/fix-homebrew-qml-links.py" "$app_dir"
mkdir -p "$app_dir/Contents/Resources/Community"
ditto "$repo_dir/examples/Community" "$app_dir/Contents/Resources/Community/Examples"
ditto "$repo_dir/LICENSES" "$app_dir/Contents/Resources/Community/LicenseTexts"
cp "$repo_dir/LICENSE.md" "$repo_dir/THIRD_PARTY_COMMUNITY.md" "$repo_dir/README.md" "$app_dir/Contents/Resources/Community/"
python3 "$repo_dir/scripts/collect-community-notices.py" "$repo_dir" "$app_dir/Contents/Resources/Community/ThirdParty"
{
  echo 'Serial Scope — independent community GPL build'
  echo 'Source: https://github.com/ahpasserby/Serial-Studio-Community'
  echo "Commit: $(git -C "$repo_dir" rev-parse HEAD)"
  echo "Architecture: $(uname -m)"
  echo 'Options: BUILD_GPL3=ON BUILD_COMMERCIAL=OFF WITH_WEBENGINE=OFF SS_USE_MIMALLOC=OFF'
  echo "Qt: $("$qt_prefix/bin/qmake6" -query QT_VERSION)"
  brew list --versions | awk '/^(qt|openssl|cmake|ninja)/'
} > "$app_dir/Contents/Resources/Community/BUILD-INFO.txt"
python3 "$repo_dir/scripts/sign-community-macos.py" "$app_dir"
ditto "$repo_dir/examples/Community" "$package_dir/Examples"
cp "$repo_dir/README.md" "$repo_dir/LICENSE.md" "$repo_dir/THIRD_PARTY_COMMUNITY.md" "$package_dir/"
ditto -c -k --sequesterRsrc --keepParent "$package_dir" "$repo_dir/dist/Serial-Scope-macOS-$(uname -m).zip"
(cd "$repo_dir/dist" && shasum -a 256 "Serial-Scope-macOS-$(uname -m).zip" > SHA256SUMS.txt)
echo "Packaged: $repo_dir/dist"
