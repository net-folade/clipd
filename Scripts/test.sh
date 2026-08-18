#!/bin/bash
# Runs the Clipd test suites (Swift Testing) with a CLT-only toolchain.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
source "$ROOT/Scripts/swiftpm-env.sh"
cd "$ROOT"

exec swift test \
  -Xswiftc -F"$CLT_TESTING_FRAMEWORKS" \
  -Xlinker -F"$CLT_TESTING_FRAMEWORKS" \
  -Xlinker -rpath -Xlinker "$CLT_TESTING_FRAMEWORKS" \
  -Xlinker -rpath -Xlinker "$CLT_TESTING_LIB" \
  "$@"
