#!/usr/bin/env bash
# End-to-end verification of the verified quine:
#   1. the checked-in Quine.lean matches what the generator produces (self-consistency),
#   2. the quine core + its axiom-freeness test + the round-trip lemmas all build,
#   3. the built program prints bytes byte-identical to Quine.lean (a genuine quine).
#
# Run from anywhere; paths are resolved relative to this script.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$ROOT"

echo "[1/3] generator self-consistency (gen_quine.py --check)"
python3 scripts/gen_quine.py --check

echo "[2/3] building Quine, Test (axiom-free regression), QuineFacts, quine"
lake build Quine Test QuineFacts quine

echo "[3/3] program output is byte-identical to its own source"
./.lake/build/bin/quine | cmp - Quine.lean

echo "PASS: Quine.lean is a genuine, kernel-verified quine."
