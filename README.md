# lean_quine — a machine-verified Lean quine

A Lean 4 program that prints its own source code and carries a kernel-checked, **axiom-free**
proof of its own quineness. The output is *computed* from a single natural number — the file's
base-1000 Gödel number — not read from disk, so it is a genuine quine rather than a photocopier.
The whole thing is also published as a [verso-blueprint](https://github.com/eric-vergo/verso-blueprint) site.

## The theorem

```lean
theorem out_eq_source : String.ofList out = include_str "Quine.lean" := rfl
```

`out` is a closed `List Char` reconstructed from `Quine.N`; `include_str "Quine.lean"` is the
file's actual on-disk bytes, read at elaboration time. The proof is `rfl` — Lean's kernel
evaluates both sides and confirms they are identical, trusting no axioms. `#print axioms
Quine.out_eq_source` reports none (checked in `Test.lean` via `#guard_msgs`), which is strictly
stronger than a `native_decide` proof (that would depend on `Lean.ofReduceBool`, the compiler, and
the CPU). The theorem is re-verified at every compile, and corroborated at run time by `cmp`.

## Run and verify

```bash
# print the source (a genuine quine — output is byte-identical to Quine.lean)
lake exe quine | cmp - Quine.lean

# full end-to-end check: generator fixpoint, builds, axiom-freeness, byte-for-byte output
scripts/verify.sh
```

## The blueprint site

The `LeanQuine.*` modules author a verso-blueprint site over the quine's declarations
(encoding, program, and the quineness theorem). Generate it with:

```bash
lake build Site
rm -rf _out/site
lake env lean GenSite.lean          # writes the site into _out/site
# open _out/site/html-multi/index.html
```

The generated site is fully self-contained (no CDN / off-origin assets). Generation is driven
by an elaboration-time `#eval` in `GenSite.lean` rather than a `main` executable: `Quine.lean`
already exports a top-level `main` (the `quine` binary's entry point), so any generator that
imports the quine's declarations cannot also declare `main`.

## Layout

| Path | What it is |
|------|------------|
| `Quine.lean` | The quine itself — **generated; do not hand-edit** (see below). |
| `QuineFacts.lean` | Sorry-free round-trip lemmas for the encoder, outside the quine payload. |
| `Test.lean` | Axiom-freeness regression (`#guard_msgs` on `#print axioms`) + independent re-proof. |
| `scripts/template.lean`, `scripts/gen_quine.py`, `scripts/verify.sh` | Generator and end-to-end check. |
| `LeanQuine.lean`, `LeanQuine/` | The blueprint site content (top-level doc + four chapters). |
| `GenSite.lean` | Site generator (elaboration-time `#eval`; see above). |

## `Quine.lean` is generated

`Quine.lean` is a fixpoint of the encoder and must **not** be hand-edited — any change breaks the
theorem. To modify the quine, edit `scripts/template.lean` and regenerate:

```bash
python3 scripts/gen_quine.py        # rewrites Quine.lean from the template
python3 scripts/gen_quine.py --check   # verify the checked-in file is a fixpoint
```

## Building this repo

`lean_quine` builds **standalone** — no sibling checkouts required. Its blueprint dependencies are
the `eric-vergo` forks (branch `viewer-integration`), pinned by git at exact SHAs in `lakefile.lean`:

| Package | Repo | Pinned SHA |
|---------|------|------------|
| `subverso` | `eric-vergo/subverso` | `62b4fda523e8b367180fac5e3c47a7d0f81dadd4` |
| `verso` | `eric-vergo/verso` | `128e6d844a8ae57abb0bc19b7f64e1887429c4a2` |
| `VersoBlueprint` | `eric-vergo/verso-blueprint` | `cb14b7467721ebaf5c8f5d13798d6d86288ca356` |

`lake update` (or the first `lake build`) clones them into `.lake/packages/`. The quine core
(`Quine`, `QuineFacts`, `Test`, and the `quine` executable) imports nothing but the Lean prelude and
builds without touching verso; only the blueprint site lib pulls in the forks.

Toolchain: `leanprover/lean4:v4.31.0`.
