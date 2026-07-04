/-
A Verified Quine — The Program chapter.

The two runnable pieces: `Quine.out`, the reconstructed source as a closed `List Char`, and
`main`, which prints it. A side-by-side card pairs the informal description with the Lean.
-/

import Verso
import VersoManual
import VersoBlueprint
import Quine

open Verso.Genre
open Verso.Genre.Manual
open Informal

#doc (Manual) "The Program" =>

:::group "program"
The runnable program: reconstruct the source from `N`, then print it.
:::

With the encoding in place, the program is short. Decoding `N` gives the file's byte groups;
splicing turns them back into characters — expanding the marker into `N`'s own digits — and the
result is the file's text. Nothing is read from disk; the output is a closed term.

:::definition "def:out" (lean := "Quine.out") (parent := "program") (uses := "def:splice, def:decode, def:N")
The reconstructed source, as a `List Char`: `splice (decode 1000000 N [])`. Decoding $`N`
recovers its base-1000 groups (with a generous fuel bound), and {uses "def:splice"}[] rebuilds the
characters — the marker group expanding into the digits of {uses "def:N"}[]. This is the value the
running program prints, and the value the quineness theorem is about.
:::

:::definition "def:main" (lean := "main") (parent := "program") (uses := "def:out")
The entry point: `IO.print (String.ofList Quine.out)`. It uses `IO.print` rather than `println`
because the trailing newline is already part of {uses "def:out"}[] — the file ends in a newline,
so `out` does too, and adding another would break the quine. `main` lives at the top level of the
file (outside the `Quine` namespace) so it is the executable's entry point.
:::

# Side-by-side

The card below pairs each informal description with its attached Lean declaration. Toggle the
proof/value bodies to see the reconstructed-source computation and the one-line entry point.

:::blueprint_side_by_side +boxed
{blueprint_node "def:out" (displayLabel := "Reconstructed source")}

{blueprint_node "def:main" (displayLabel := "Entry point") -header +compact}
:::
