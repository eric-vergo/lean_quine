import Quine

-- The quineness theorem is proved by the kernel alone, with no extra axioms. This
-- `#guard_msgs` turns any axiom regression -- a stray `sorry`, or a `native_decide`
-- fallback that would introduce `Lean.ofReduceBool` -- into a hard build failure.
/-- info: 'Quine.out_eq_source' does not depend on any axioms -/
#guard_msgs in
#print axioms Quine.out_eq_source

-- Re-prove quineness here, where `include_str "Quine.lean"` is resolved independently
-- (Test.lean sits in the same directory), cross-checking that the statement really is
-- about this file's on-disk bytes.
example : String.ofList Quine.out = include_str "Quine.lean" := Quine.out_eq_source
