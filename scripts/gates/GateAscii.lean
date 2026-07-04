-- Micro-test: confirm the pure-ASCII syntax (`->` arrows, `if n < 2` for `n <= 1`) still
-- reduces the string-literal fast path axiom-free, so the generated file can be ASCII-only.
namespace GateAscii

def N : Nat := 1097001098

def digits : Nat -> Nat -> List Char -> List Char
  | 0, _, acc => acc
  | f + 1, n, acc =>
    if n = 0 then acc else digits f (n / 10) (Char.ofNat (48 + n % 10) :: acc)

def decode : Nat -> Nat -> List Nat -> List Nat
  | 0, _, acc => acc
  | f + 1, n, acc =>
    if n < 2 then acc else decode f (n / 1000) (n % 1000 :: acc)

def splice : List Nat -> List Char
  | [] => []
  | k :: ks => if k = 1 then digits 1000000 N (splice ks) else Char.ofNat k :: splice ks

def out : List Char := splice (decode 1000000 N [])

theorem gateAscii : String.ofList out = "a1097001098b" := rfl

#print axioms gateAscii

end GateAscii
