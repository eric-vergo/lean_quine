/-
Gate A — validates the whole kernel theory on a tiny payload.

Payload "a\x01b" (marker byte 0x01 between 'a' and 'b'):
  N = 1 (sentinel); N = N*1000 + 97 ('a'); N = N*1000 + 1 (marker); N = N*1000 + 98 ('b')
    = 1097001098
The decimal digits of N stand where the marker is, so the decoded/spliced string must be
"a" ++ "1097001098" ++ "b" = "a1097001098b".

We check:
  * `gateA := rfl`         — the `String.ofList out =?= "literal"` kernel fast path works.
  * `#print axioms gateA`  — the proof is axiom-free (kernel-only, no native_decide).
  * `#print` of the 3 defs — the equation compiler chose STRUCTURAL recursion (no WellFounded.fix).
-/
namespace GateA

def N : Nat := 1097001098

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

theorem gateA : String.ofList out = "a1097001098b" := rfl

#print axioms gateA
#print digits
#print decode
#print splice

end GateA
