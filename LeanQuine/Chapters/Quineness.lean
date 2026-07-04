/-
A Verified Quine — Quineness chapter.

The star result: `Quine.out_eq_source`, the kernel-checked, axiom-free proof that the program's
output equals its own source. Includes the informal statement, why `rfl` closes it, and the
connection to Kleene's recursion theorem / the diagonal lemma.
-/

import Verso
import VersoManual
import VersoBlueprint
import Quine

open Verso.Genre
open Verso.Genre.Manual
open Informal

#doc (Manual) "Quineness" =>

:::group "quineness"
The theorem that makes it a *verified* quine: the computed output equals this file's bytes,
by the kernel alone, with no axioms.
:::

:::theorem "thm:quine" (lean := "Quine.out_eq_source") (parent := "quineness") (uses := "def:out") (tags := "quine") (effort := "small")
Running the program prints the program's own source, byte for byte:
$$`\mathsf{String.ofList}\ \mathsf{out} \;=\; \texttt{include\_str "Quine.lean"}.`
The left-hand side is the string the program emits — the reconstructed source of
{uses "def:out"}[], computed from `N`. The right-hand side is the actual on-disk bytes of this
file. The theorem asserts they are identical, and is discharged by `rfl`.
:::

:::proof "thm:quine"
`include_str "Quine.lean"` is resolved *at elaboration time*: the elaborator reads the file's
on-disk bytes, relative to the current file, and freezes them into a string literal in the
theorem statement. So the right-hand side is quite literally "this file's bytes as of the moment
it was compiled".

The proof term is `rfl`, and it goes through because of a defeq fast path that both the elaborator
and the kernel implement for `String.ofList cs =?= "literal"`. Rather than build the UTF-8 /
`ByteArray` model of each side and compare bytes — which would route through `String.decEq` and its
quadratic reduction — the kernel expands the string *literal* in C++ into a list of
`Char.ofNat ⟨code⟩` cons cells and compares it, cell by cell, against `cs`. Here `cs` is `out`,
which reduces (again in the kernel) to exactly that shape. The comparison is therefore roughly 7700
character-code equalities on `Nat` literals — GMP integer comparisons — with no strings materialized
at all.

Two forces are needed to keep this in reach of the kernel. First, `out` must reduce to a literal
`Char.ofNat` list without invoking any `opaque` primitive: this is why the encoding avoids
`String.quote` / `String.replace` (whose Lean 4 definitions bottom out in `opaque`
`String.Internal` functions the kernel cannot unfold) and instead builds everything from structural
recursion over `List Char`. Second, `maxRecDepth` is raised, because the metatheory recurses about
one frame per cons cell — some 4500 deep.

The result is that `#print axioms Quine.out_eq_source` reports *no axioms*. This is strictly
stronger than a `native_decide` proof, which would compile the check to native code and record a
dependency on `Lean.ofReduceBool` (trusting the compiler and the hardware). Here the kernel does the
reduction itself.

Finally, the check happens at *compile time* — the theorem is re-verified every time the file is
elaborated — and it is corroborated at *run time* by an entirely separate mechanism:
`lake exe quine | cmp - Quine.lean` compiles `out` to native code, runs it, and byte-compares the
output against the file. The compile-time kernel proof and the run-time `cmp` agree.
:::

# Self-reference, arithmetized

The construction is a concrete instance of the diagonalization behind Kleene's second recursion
theorem: a program can be built with access to its own description. Here the "description" is the
number $`N`, and the file contains $`N`'s own digits at the marker position — the arithmetized
analogue of the diagonal lemma, where a sentence refers to its own Gödel number. `splice` plays the
role of the diagonalization operator: it is the step that substitutes the number back into the very
place that names it, turning "print the digits that go *here*" into a fixpoint.

What makes this version unusual is not the self-reference — every quine has that — but that the
fixpoint is *proved*. The equation "output = source" is not established by running the program and
eyeballing the result; it is a theorem, closed by Lean's kernel, depending on nothing.
