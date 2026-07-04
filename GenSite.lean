/-
Blueprint SITE generator for lean_quine.

Run it with:

    lake build Site
    rm -rf _out/site
    lake env lean GenSite.lean          # writes the site into _out/site

Why `#eval` and not a `def main` / `lean_exe`?  `Quine.lean` exports a top-level `main`
(the entry point of the `quine` executable). Every generator that references the quine's
declarations must `import Quine` transitively (through the chapters' `(lean := "Quine.…")`
links), which pulls that `_root_.main` into scope — so a second `def main` here, or in any
`lean_exe` root that imports this closure, is a hard "`main` has already been declared"
error. It cannot be resolved without editing the GENERATED `Quine.lean`. Driving generation
at elaboration time via `#eval` needs no `_root_.main`, so it sidesteps the clash cleanly.
-/

import VersoManual
import VersoBlueprint.Main
import LeanQuine.Blueprint

open Verso Doc
open Verso.Genre Manual

/-- Generate the blueprint site into `_out/site`. `blueprintMainWithFeatures` bakes in the
per-node pages and the PM pages (worklist / owners / tags) + progress badge in the correct
order after the preview-data step. -/
def generateSite : IO UInt32 :=
  Informal.PreviewManifest.blueprintMainWithFeatures
    (%doc LeanQuine.Blueprint)
    ["--output", "_out/site"]
    (extensionImpls := by exact extension_impls%)

#eval generateSite
