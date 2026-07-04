/-
A Verified Quine — Introduction chapter.

Prose only: what a quine is, the "cheating vs. genuine" distinction, the trust story
(kernel-only `rfl`, axiom-free), and how to run and verify it. No blueprint nodes here.
-/

import Verso
import VersoManual
import VersoBlueprint

open Verso.Genre
open Verso.Genre.Manual
open Informal

#doc (Manual) "Introduction" =>

:::author "eric" (name := "Eric Vergo")
:::

A *quine* is a program that prints its own source code, exactly, with no input and without
reading itself from disk. This blueprint documents a Lean 4 program that is a genuine quine and,
more than that, carries a machine-checked proof of its own quineness: a theorem, verified by
Lean's kernel with no extra axioms, stating that the bytes the program emits are byte-for-byte
this very source file.

# Cheating versus genuine

It is easy to *cheat*. A program that runs `IO.FS.readFile "Quine.lean"` and prints the result
reproduces its source, but it is a photocopier, not a quine: delete the file and it is silent.
The interesting constraint is that the output must be *computed* from a closed term of the
program, so the program reconstructs itself from itself.

That is exactly what happens here. The reconstructed source is the definition `Quine.out`, a
closed `List Char` computed from a single natural number `Quine.N` — no file access, no `IO`,
nothing read at runtime. The program's `main` simply prints `String.ofList Quine.out`. The word
`include_str` appears in the file exactly once, and only inside the *statement of the theorem*,
never in the computation of the output. The theorem uses `include_str` to name "the actual bytes
of this file on disk" so it can assert that the computed value equals them; the running program
never touches it.

# The trust story

The headline theorem is

```
theorem out_eq_source : String.ofList out = include_str "Quine.lean" := rfl
```

Three things make this a strong claim:

- **It is closed by `rfl`.** The proof term is reflexivity: Lean's *kernel* — the small, trusted
  core that re-checks every proof — evaluates both sides and confirms they are the same string.
  Nothing is taken on faith from the elaborator or from compiled code.
- **It is axiom-free.** Running `#print axioms Quine.out_eq_source` reports that the theorem
  *depends on no axioms at all* — not even the three that ordinary Lean developments (propositional
  extensionality, quotient soundness, choice) routinely use. `Test.lean` pins this with a
  `#guard_msgs`, so any regression that smuggled in an axiom would fail the build.
- **It is stronger than `native_decide`.** A common way to discharge a big computational goal is
  `native_decide`, which compiles the decision procedure to native code and trusts its `true`
  answer — recorded as a dependency on the `Lean.ofReduceBool` axiom, and on the correctness of the
  compiler and your CPU. The kernel `rfl` here trusts none of that: the comparison is performed by
  the kernel's own reduction, so the axiom list is genuinely empty.

The theorem is checked at *compile time*, every time the file is elaborated. As an independent
cross-check, an external run of the built program is compared against the file on disk:

```
lake exe quine | cmp - Quine.lean
```

`cmp` reports no differences. The script `scripts/verify.sh` bundles the whole story: it re-runs
the generator in `--check` mode (confirming the checked-in `Quine.lean` is a fixpoint of the
encoder), builds the core together with the axiom-freeness regression and the round-trip lemmas,
and finally byte-compares the program's output against its own source.

# A note on ASCII

The quine file is deliberately pure ASCII: it writes `->` rather than `→` and `n < 2` rather than
`n ≤ 1`. The encoder only handles byte codes 10 (newline) and 32–126 (printable ASCII), so every
character of the file must land in that range. This keeps the Gödel numbering — described in the
next chapter — a clean one-group-per-byte affair, and it sidesteps any UTF-8 subtleties in the
kernel's string comparison.
