#!/usr/bin/env bash
# Re-verifies every change described in docs/CHANGES.md.
#
#   tool/verify_changes.sh            # data checks, analyzer, tests
#   tool/verify_changes.sh --regen    # also rebuild the Explore assets and
#                                     # confirm the sources reproduce them
#
# Exits non-zero on the first failing stage. Needs flutter on PATH (or set
# FLUTTER=/path/to/flutter) and python3; --regen also needs Pillow and either
# network access or FEDB_DATASET / FEDB_CACHE pointing at a local copy of
# free-exercise-db.
set -euo pipefail
cd "$(dirname "$0")/.."
FLUTTER="${FLUTTER:-flutter}"
step() { printf '\n== %s\n' "$1"; }

step "1/5 Independent data checks (tool/verify_assets.py)"
python3 tool/verify_assets.py

if [[ "${1:-}" == "--regen" ]]; then
  step "2/5 Regenerate Explore assets and compare with git"
  args=()
  [[ -n "${FEDB_DATASET:-}" ]] && args+=(--dataset "$FEDB_DATASET")
  [[ -n "${FEDB_CACHE:-}" ]] && args+=(--cache "$FEDB_CACHE")
  sums() { find assets/library assets/programs -type f -name '*.json' -o -type f -name '*.jpg' | sort | xargs sha256sum; }
  before="$(sums)"
  # A different hash seed each run proves the output does not depend on it.
  PYTHONHASHSEED="$RANDOM" python3 tool/build_library.py "${args[@]}" | tail -1
  if [[ "$before" != "$(sums)" ]]; then
    diff <(echo "$before") <(sums) | head -20
    echo "FAIL: the sources in tool/ no longer reproduce the assets. Review the diff (git diff assets/) and commit the regenerated files or fix tool/library_*.py." >&2
    exit 1
  fi
  echo "PASS: regenerating from tool/ reproduces the current assets exactly"
else
  step "2/5 Asset regeneration skipped (pass --regen to include it)"
fi

step "3/5 flutter analyze (no errors or warnings allowed)"
out="$("$FLUTTER" analyze 2>&1 || true)"
echo "$out" | tail -1
if echo "$out" | grep -qE '^\s*(error|warning) •'; then
  echo "$out" | grep -E '^\s*(error|warning) •' >&2
  exit 1
fi

step "4/5 Tests named in docs/CHANGES.md"
"$FLUTTER" test \
  test/features/endurance_track_test.dart \
  test/features/distance_logging_test.dart \
  test/features/session_detail_test.dart \
  test/data/library_model_test.dart \
  test/features/explore_test.dart \
  test/features/progress_hub_navigation_test.dart

step "5/5 Full test suite"
"$FLUTTER" test

printf '\nAll changes verified.\n'
