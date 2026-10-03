# Source and third-party notices

Serial Scope is an independent community build maintained by ahpasserby.
Based on Serial Studio v4.0.2, commit 50b3ce7fc9e0a72585cfa3bdccb7a1c92dde7493.
Upstream copyright (c) 2020–2026 Alex Spataru; modifications (c) 2026 ahpasserby.

The GPL application source and build scripts are provided in this repository and release tags.
The upstream licensing files remain in LICENSE.md and LICENSES/.
Bundled third-party source and license notices remain in lib/.
Qt is obtained from Homebrew; its modules and versions used for each package are recorded in BUILD-INFO.txt. Qt source: https://download.qt.io/archive/qt/ . Homebrew formulas: https://github.com/Homebrew/homebrew-core/tree/HEAD/Formula/q .
OpenSSL is fetched by the unmodified upstream CMake recipe from https://github.com/alex-spataru/OpenSSL-Builder/releases/tag/4.0.0 ; source: https://github.com/openssl/openssl/tree/openssl-4.0.0 .
macOS system zlib and expat are linked as system libraries. Other dependencies are built from lib/ in this source tree.
See lib/ subdirectories and bundled Qt notices for third-party license terms.
