/-
A Verified Quine — The Encoding chapter.

The base-1000 Goedel numbering: `Quine.N` is this file's own Goedel number, and `digits`,
`decode`, and `splice` peel it back apart into the file's bytes. The round-trip lemma
`QuineFacts.decode_encode` justifies the scheme by a real induction.
-/

import Verso
import VersoManual
import VersoBlueprint
import Quine
import QuineFacts

open Verso.Genre
open Verso.Genre.Manual
open Informal

#doc (Manual) "The Encoding" =>

:::group "encoding"
How the file is turned into one natural number and back: the base-1000 Gödel numbering with a
leading sentinel and a single self-referential marker.
:::

Gödel's arithmetization of syntax assigns to each piece of text a number, so that statements
*about* text become statements about numbers. This quine takes the idea literally: the whole
file is encoded as one natural number `Quine.N`, and — because the file must contain its own
source — the decimal digits of that number appear inside the file itself. The file literally
contains its own Gödel number.

# The scheme

Read the file as a list of byte codes $`c_1, c_2, \ldots, c_m` (each a newline, $`10`, or a
printable ASCII byte, $`32`–$`126`). Encoding folds them into a single number, most significant
group first, behind a leading sentinel of $`1`:
$$`N \;=\; 1000^{m} + c_1 \cdot 1000^{\,m-1} + c_2 \cdot 1000^{\,m-2} + \cdots + c_{m-1}\cdot 1000 + c_m.`
Each byte occupies its own base-1000 group — three decimal digits — so the groups never collide
(every byte code is at most $`126 < 1000`). The leading $`1000^m` is the *sentinel*: it is the
initial accumulator, and decoding halts when nothing but it remains.

One interior group is special. Exactly one $`c_j` is set to the *marker* value $`1` — smaller
than any real byte code, and the place where the digits of $`N` themselves must be printed. When
the file is reconstructed, every ordinary group $`c_i` turns back into its character, but the
marker turns into the decimal digits of $`N`. That is the self-reference: the number describes a
file that, at one spot, prints the number.

# Decoding, digit by digit

:::definition "def:N" (lean := "Quine.N") (parent := "encoding")
The file's Gödel number: a single `Nat` of 5797 decimal digits. Its base-1000 groups are the
byte codes of this file in order, behind the sentinel group $`1`, with one interior group equal
to the marker $`1`. These very digits appear on the `def N` line of the source — the number is a
fixpoint of the encoder.
:::

:::definition "def:digits" (lean := "Quine.digits") (parent := "encoding")
`digits f n acc` prepends the decimal digits of $`n` onto `acc`, peeling one low-order digit per
step. The leading `Nat` is *fuel*: making it the first match argument forces the equation
compiler to use plain structural recursion (no `WellFounded.fix`), and the accumulator doubles as
the append target, so no `List.append` ever appears. This is how the marker group expands into the
5797 characters of $`N`.
:::

:::definition "def:decode" (lean := "Quine.decode") (parent := "encoding")
`decode f n acc` peels base-1000 groups off $`n` — a group $`n \bmod 1000`, then $`n / 1000` —
prepending each onto `acc`, and stops at the sentinel (`n < 2`). Fuel-first again, for structural
recursion. Applied to $`N`, it recovers the list of groups $`c_1, \ldots, c_m` that were encoded.
:::

:::definition "def:splice" (lean := "Quine.splice") (parent := "encoding") (uses := "def:digits, def:N")
`splice` turns a list of groups back into characters. The marker group $`1` becomes the decimal
digits of $`N` (via {uses "def:digits"}[]), and any other group $`k` becomes `Char.ofNat k`. This
is where the self-reference is discharged: the one place that said "the number goes here" is
filled in with $`N`'s own digits.
:::

# The round-trip is honest

The quine's correctness rests on decoding being a genuine inverse of encoding. That fact is proved
outside the quine file — in `QuineFacts`, so it adds nothing to the encoded payload — by an
ordinary induction rather than by kernel evaluation.

:::lemma_ "lem:decode-encode" (lean := "QuineFacts.decode_encode") (parent := "encoding") (uses := "def:decode") (tags := "encoding")
For any list of base-1000 groups whose entries are all below $`1000`, decoding its encoding (with
at least $`\text{length} + 1` fuel) returns exactly that list:
$$`\mathsf{decode}\,(|l| + 1)\,(\mathsf{encode}\ l)\,[] \;=\; l.`
`Quine.N` is one such encoding — the marker $`1` and every byte code are below $`1000` — so
decoding it really does recover the file's group list.
:::

:::proof "lem:decode-encode"
By reverse induction on the group list $`l` — appending one group at a time on the right — with
the accumulator and the fuel generalized. Appending a group $`a` multiplies the encoding by the
base and adds $`a` ($`\mathsf{encode}(l \mathbin{+\!+} [a]) = \mathsf{encode}(l)\cdot 1000 + a`),
so one `decode` step recovers $`a` as $`(\ldots) \bmod 1000` and continues on
$`(\ldots) / 1000 = \mathsf{encode}(l)`. The sentinel keeps the encoding at least $`1` throughout,
which is what lets `decode` distinguish "a real group remains" from "only the sentinel is left".
The arithmetic side conditions are discharged by `omega`; there is no `sorry` and no
`native_decide`.
:::
