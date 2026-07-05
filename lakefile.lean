import Lake
open Lake DSL

-- Standalone consumer: the eric-vergo forks (branch `viewer-integration`) are pinned by git
-- at exact SHAs, so this repo builds in isolation with no sibling checkouts required.
--
-- All three pins are ROOT-level direct requires on purpose. Lake resolves deps name-first,
-- root-first: a package resolved once by name is reused for every later `require` of that
-- name, so these root pins SHADOW the forks' own internal path requires (verso's
-- `require subverso from "../subverso"`, verso-blueprint's `../verso` / `../subverso`) AND
-- verso-slides' transitive pin of upstream leanprover/verso (which would otherwise win and
-- re-introduce the CDN `marked`). Order matters — subverso before verso before VersoBlueprint —
-- so each name is claimed by our fork before any transitive require can reach it. The subverso
-- pin is mandatory: without it the manifest inherits subverso as a `../subverso` path dep.
require subverso from git "https://github.com/eric-vergo/subverso.git" @ "62b4fda523e8b367180fac5e3c47a7d0f81dadd4"
require verso from git "https://github.com/eric-vergo/verso.git" @ "128e6d844a8ae57abb0bc19b7f64e1887429c4a2"
require VersoBlueprint from git "https://github.com/eric-vergo/verso-blueprint.git" @ "cb14b7467721ebaf5c8f5d13798d6d86288ca356"

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
