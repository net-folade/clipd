#!/bin/bash
# Shared SwiftPM environment fixes for building Clipd with Command Line Tools
# (no Xcode.app). Source this from build-app.sh / test.sh; safe no-op elsewhere.
#
# Workaround 1 — stale ManifestAPI interfaces:
# Some CLT installs leave behind old *.private.swiftinterface files in
# usr/lib/swift/pm/ManifestAPI from a previous CLT version. swiftc prefers the
# private interface, so every Package.swift fails to link against the newer
# libPackageDescription.dylib. If the stale files are present, point SwiftPM at
# a patched copy via SWIFTPM_CUSTOM_LIBS_DIR. (Permanent fix: sudo delete the
# stale *.private.swiftinterface files, or reinstall the CLT.)

CLT=/Library/Developer/CommandLineTools
PM="$CLT/usr/lib/swift/pm"
STALE_IFACE="$PM/ManifestAPI/PackageDescription.swiftmodule/arm64-apple-macos.private.swiftinterface"

if [ -z "${SWIFTPM_CUSTOM_LIBS_DIR:-}" ] && [ -f "$STALE_IFACE" ] \
    && ! grep -q swiftLanguageModes "$STALE_IFACE" 2>/dev/null; then
  PATCHED="${TMPDIR:-/tmp}/clipd-pm-libs"
  if [ ! -d "$PATCHED/ManifestAPI" ]; then
    mkdir -p "$PATCHED"
    cp -R "$PM/ManifestAPI" "$PM/PluginAPI" "$PATCHED/"
    rm -f "$PATCHED"/ManifestAPI/PackageDescription.swiftmodule/*.private.swiftinterface
    rm -f "$PATCHED"/PluginAPI/PackagePlugin.swiftmodule/*.private.swiftinterface
  fi
  export SWIFTPM_CUSTOM_LIBS_DIR="$PATCHED"
  echo "note: using patched SwiftPM manifest libs at $PATCHED (stale CLT interfaces detected)"
fi

# Workaround 2 — Swift Testing framework paths (used by test.sh):
# The CLT ships Testing.framework outside the default search paths, and its
# lib_TestingInterop.dylib one directory off from where the framework's own
# rpaths look.
CLT_TESTING_FRAMEWORKS="$CLT/Library/Developer/Frameworks"
CLT_TESTING_LIB="$CLT/Library/Developer/usr/lib"
export CLT_TESTING_FRAMEWORKS CLT_TESTING_LIB
