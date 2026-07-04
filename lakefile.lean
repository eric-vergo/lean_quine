import Lake
open Lake DSL

-- Local-wired consumer of the SIBLING fork checkouts, so edits to ../verso or
-- ../verso-blueprint are picked up on the next `lake build` with no push / `lake update` cycle.
--
-- `require verso` is a ROOT-level direct require on purpose: verso-slides transitively pins
-- upstream leanprover/verso, which otherwise wins resolution and would re-introduce the CDN
-- `marked`. A root direct require overrides that, so our self-hosting fork is used.
require verso from "../verso"
require VersoBlueprint from "../verso-blueprint"

package LeanQuine where
  precompileModules := false

-- The verified quine itself. Imports NOTHING (pure Prelude), so building `Quine` / `quine`
-- must never compile verso. `experimental.module` is deliberately NOT set here (nor at the
-- package level): the quine core must build as an ordinary Prelude program.
@[default_target]
lean_lib Quine where

-- Supporting sorry-free lemmas OUTSIDE the quine payload (round-trip round the encoder).
lean_lib QuineFacts where

-- Axiom regression + re-proof harness.
lean_lib Test where

-- The verso-blueprint SITE content (chapters + top-level doc). `experimental.module` is
-- scoped to THIS lib only — the blueprint DSL needs it, but the quine core libs above must
-- not. The lib target is named `Site` to avoid clashing with the package target `LeanQuine`;
-- `roots := #[`LeanQuine]` keeps the MODULE names `LeanQuine` / `LeanQuine.*`.
lean_lib Site where
  roots := #[`LeanQuine]
  leanOptions := #[⟨`experimental.module, true⟩]

-- The runnable quine: `main` lives at the top level of `Quine.lean`.
lean_exe quine where
  root := `Quine

-- NOTE: there is deliberately NO `blueprint-gen` executable. `Quine.lean` exports a
-- top-level `main`, which every site-generator module inherits transitively (the chapters
-- `(lean := "Quine.…")`-link the quine's decls), so a `lean_exe` whose root defines its own
-- `main` fails to build ("`main` has already been declared") and cannot be fixed without
-- editing the generated `Quine.lean`. The site is generated instead by elaborating
-- `GenSite.lean` (`lake env lean GenSite.lean`), whose `#eval` needs no `_root_.main`.
