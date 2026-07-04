/-
Quine.lean: a self-printing Lean program with a kernel-checked proof of its own quineness.
`main` prints this file's bytes, COMPUTED from the one number `N` (this file's base-1000
Goedel number: one group per byte, a leading sentinel group `1`, and the single interior
group `1` marking where the digits of `N` themselves stand). Nothing is read from disk at
runtime. `out_eq_source` proves, axiom-free, that the computed `out` equals this very file.
GENERATED -- do not hand-edit; edit scripts/template.lean and run scripts/gen_quine.py.
-/
namespace Quine

/-- This file, base-1000 encoded (sentinel `1`, one group per byte, marker `1` = digits of `N`). -/
def N : Nat := __PAYLOAD__

/-- Decimal digits of `n`, prepended onto `acc` (fuel-first: structural recursion, tail call). -/
def digits : Nat -> Nat -> List Char -> List Char
  | 0, _, acc => acc
  | f + 1, n, acc => if n = 0 then acc else digits f (n / 10) (Char.ofNat (48 + n % 10) :: acc)

/-- Base-1000 groups of `n`, prepended onto `acc`, stopping at the sentinel (`n < 2`). -/
def decode : Nat -> Nat -> List Nat -> List Nat
  | 0, _, acc => acc
  | f + 1, n, acc => if n < 2 then acc else decode f (n / 1000) (n % 1000 :: acc)

/-- Marker group `1` becomes the digits of `N`; any other group `k` becomes `Char.ofNat k`. -/
def splice : List Nat -> List Char
  | [] => []
  | k :: ks => if k = 1 then digits 1000000 N (splice ks) else Char.ofNat k :: splice ks

/-- This file's reconstructed source text. -/
def out : List Char := splice (decode 1000000 N [])

set_option maxRecDepth 200000 in
set_option maxHeartbeats 2000000 in
/-- Heart of the quine: `out` equals this file's bytes, by the kernel alone (`rfl`, axiom-free). -/
theorem out_eq_source : String.ofList out = include_str "Quine.lean" := rfl

end Quine

/-- Print this file's own bytes (`IO.print`, not `println`: the trailing newline is in `out`). -/
def main : IO Unit := IO.print (String.ofList Quine.out)
