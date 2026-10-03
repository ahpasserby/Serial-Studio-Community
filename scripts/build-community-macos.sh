#!/bin/bash
# SPDX-License-Identifier: GPL-3.0-only
set -euo pipefail
repo_dir="$(cd "$(dirname "$0")/.." && pwd)"
qt_prefix="${QT_PREFIX:-$(brew --prefix)}"
cmake -S "$repo_dir" -B "$repo_dir/build-community" -G Ninja \
  -DCMAKE_BUILD_TYPE=Release -DCMAKE_PREFIX_PATH="$qt_prefix" \
  -DCMAKE_OSX_ARCHITECTURES="$(uname -m)" \
  -DBUILD_GPL3=ON -DBUILD_COMMERCIAL=OFF -DWITH_WEBENGINE=OFF \
  -DSS_USE_MIMALLOC=OFF -DUSE_SYSTEM_ZLIB=ON -DUSE_SYSTEM_EXPAT=ON
cmake --build "$repo_dir/build-community" --parallel "${BUILD_JOBS:-6}"

python3 "$repo_dir/scripts/fix-homebrew-qml-links.py" "$repo_dir/build-community/app/Serial-Scope.app"
