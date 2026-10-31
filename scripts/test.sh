#!/bin/bash
# Run every package's suite, then the workspace tooling tests.
#
#   ./scripts/test.sh                     # all packages, default tags
#   ./scripts/test.sh --only slow         # the same selection in every package
#   TEST_PACKAGES=actor_simulation ./scripts/test.sh   # one package only
set -e

cd "$(dirname "$0")/.."

packages=${TEST_PACKAGES:-"gen_server_virtual_time actor_simulation actor_simulation_codegen"}

for package in $packages; do
  echo ""
  echo "=== $package ==="
  (cd "packages/$package" && mix test "$@")
done

if [ -z "${TEST_PACKAGES:-}" ]; then
  echo ""
  echo "=== workspace (maintainer tooling) ==="
  mix test "$@"
fi
