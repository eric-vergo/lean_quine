/-
A Verified Quine — top-level blueprint document.

Ties together the four chapters (Introduction, The Encoding, The Program, Quineness) with the
dashboard, dependency graph, and progress summary. The star result is `Quine.out_eq_source`,
proved axiom-free by the kernel alone.
-/

import Verso
import VersoManual
import VersoBlueprint
import VersoBlueprint.Commands.Graph
import VersoBlueprint.Commands.Summary
import LeanQuine.Chapters.Introduction
import LeanQuine.Chapters.Encoding
import LeanQuine.Chapters.Program
import LeanQuine.Chapters.Quineness

open Verso.Genre
open Verso.Genre.Manual
open Informal

#doc (Manual) "A Verified Quine" =>

%%%
shortTitle := "Lean Quine"
authors := ["Eric Vergo", "Claude Fable 5"]
%%%

{blueprint_dashboard}

{include 0 LeanQuine.Chapters.Introduction}

{include 0 LeanQuine.Chapters.Encoding}

{include 0 LeanQuine.Chapters.Program}

{include 0 LeanQuine.Chapters.Quineness}

{blueprint_graph}

{blueprint_summary}
