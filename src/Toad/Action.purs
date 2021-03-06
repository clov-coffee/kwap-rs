module Toad.Action where

import Prelude

import Data.Foldable (class Foldable, foldl)
import Toad.Page.Concepts as Page.Concepts

data Action
  = Nop
  | Init
  | NavbarSectionPicked
  | Tick
  | DismissError
  | ConceptsPageOutput Page.Concepts.Output

fromFoldable :: ∀ f. Foldable f => f Action -> Action
fromFoldable = foldl (const identity) Nop
