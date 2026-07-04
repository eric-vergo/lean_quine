#!/usr/bin/env python3
"""Throwaway generator for Gate B: a synthetic ~4.5 KB payload to time `rfl` at scale.

Builds a ~1100-char body of plausible ASCII (codes 10 or 32-126) with exactly one marker
byte, folds it into N (base 1000, sentinel 1, marker->1), then emits GateB.lean containing
N and the corresponding string literal so that
    String.ofList (splice (decode 1000000 N [])) = "<literal>"
should hold by `rfl` iff the kernel fast path scales.
"""
import random

random.seed(362583)

BODY_CHARS = 1100          # ~1100 groups -> N ~3300 digits -> spliced literal ~4.4 KB
ALPHABET = [10] + list(range(32, 127))

# Build a body of char codes with exactly one marker (sentinel handling is in the fold).
body = [random.choice(ALPHABET) for _ in range(BODY_CHARS)]
marker_pos = BODY_CHARS // 2
MARKER = 1
body[marker_pos] = MARKER

# Fold into N: sentinel 1, then one base-1000 group per body char.
N = 1
for code in body:
    N = N * 1000 + code

# The spliced/decoded string: marker -> decimal digits of N, else the literal char.
digits_of_N = str(N)
out_codes = []
for code in body:
    if code == MARKER:
        out_codes.extend(ord(d) for d in digits_of_N)
    else:
        out_codes.append(code)

# Lean-escape into a string literal (only \, ", and newline need escaping here).
def lean_escape(code: int) -> str:
    if code == 92:   # backslash
        return "\\\\"
    if code == 34:   # double quote
        return "\\\""
    if code == 10:   # newline
        return "\\n"
    return chr(code)

literal = "".join(lean_escape(c) for c in out_codes)

lean = f'''/-
Gate B — scale timebox. Synthetic ~4.5 KB payload ({BODY_CHARS} groups, N has {len(digits_of_N)} digits).
Measures whether the `String.ofList out =?= "literal"` `rfl` fast path scales; if this is
slow (> ~2 min) or crashes, the real Quine.lean theorem falls back to `native_decide`.
-/
namespace GateB

def N : Nat := {N}

def digits : Nat → Nat → List Char → List Char
  | 0, _, acc => acc
  | f + 1, n, acc =>
    if n = 0 then acc else digits f (n / 10) (Char.ofNat (48 + n % 10) :: acc)

def decode : Nat → Nat → List Nat → List Nat
  | 0, _, acc => acc
  | f + 1, n, acc =>
    if n ≤ 1 then acc else decode f (n / 1000) (n % 1000 :: acc)

def splice : List Nat → List Char
  | [] => []
  | k :: ks => if k = 1 then digits 1000000 N (splice ks) else Char.ofNat k :: splice ks

def out : List Char := splice (decode 1000000 N [])

set_option maxRecDepth 100000 in
set_option maxHeartbeats 4000000 in
theorem gateB : String.ofList out = "{literal}" := rfl

#print axioms gateB

end GateB
'''

with open("scripts/gates/GateB.lean", "w", newline="") as f:
    f.write(lean)

print(f"BODY_CHARS={BODY_CHARS} N_digits={len(digits_of_N)} literal_bytes={len(literal)} out_codes={len(out_codes)}")
