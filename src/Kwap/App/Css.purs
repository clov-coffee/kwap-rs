module Kwap.App.Css
  ( MaskComposite(..)
  , MaskMode(..)
  , anySize
  , mask
  , style
  , refinements
  , kwapEasing
  , module X
  ) where

import Prelude

import CSS as Css
import CSS hiding
  ( Color(..)
  , FontStyle(..)
  , FontWeight(..)
  , backgroundColor
  , color
  , fontFamily
  , fontSize
  , fontWeight
  ) as X
import CSS.Common as Css.Common
import CSS.Render as Css.Render
import CSS.Transition as Css.Transition
import CSS.Selector as Css.Selector
import CSS.Size as Css.Size
import Data.Array as Array
import Data.Either (Either(..))
import Data.Foldable (foldMap, foldl)
import Data.Map as Map
import Data.Maybe (Maybe(..), maybe)
import Data.Profunctor.Strong (second)
import Data.String as String
import Data.Tuple (Tuple(..), snd)
import Data.Tuple.Nested ((/\))
import Halogen.HTML as HH
import Halogen.HTML.Core as HC
import Halogen.HTML.Elements as HE
import Halogen.HTML.Properties as HP
import Kwap.App.Css.Color as X
import Kwap.App.Css.Font as X

kwapEasing :: Css.Transition.TimingFunction
kwapEasing = Css.Transition.cubicBezier 0.25 1.0 0.5 1.0

refinements :: Array Css.Selector.Refinement -> Css.Selector.Refinement
refinements =
  foldl (\preds (Css.Selector.Refinement preds') -> preds <> preds') [] >>>
    Css.Selector.Refinement

anySize :: ∀ s o. Css.Size.Size s -> Css.Size.Size o
anySize = Css.Size.sizeToString >>> Css.value >>> Css.Size.BasicSize

--| copied from purescript-halogen-css, but modified to
--| preserve duplicate rules for vendoring
style :: ∀ i r. Css.CSS -> HP.IProp (style :: String | r) i
style =
  HP.attr (HC.AttrName "style")
    <<< toString
    <<< rules
    <<< Css.runS
  where
  toString :: Array (Tuple String String) -> String
  toString = String.joinWith "; " <<< map
    (\(Tuple key val) -> key <> ": " <> val)

  rules :: Array Css.Rule -> Array (Tuple String String)
  rules rs = Array.mapMaybe property rs
    >>= Css.Render.collect
      >>> rights

  property :: Css.Rule -> Maybe (Tuple (Css.Key Unit) Css.Value)
  property (Css.Property k v) = Just (Tuple k v)
  property _ = Nothing

  rights :: ∀ a b. Array (Either a b) -> Array b
  rights = Array.concatMap $ foldMap Array.singleton

data MaskComposite = MaskAdd | MaskSubtract | MaskIntersect | MaskExclude

instance valueMaskComposite :: Css.Val MaskComposite where
  value = case _ of
    MaskAdd -> Css.fromString "add"
    MaskSubtract -> Css.fromString "subtract"
    MaskIntersect -> Css.fromString "intersect"
    MaskExclude -> Css.fromString "exclude"

webkitMaskComposite :: MaskComposite -> Css.Value
webkitMaskComposite = Css.fromString <<< case _ of
  MaskAdd -> Css.fromString "source-over"
  MaskSubtract -> Css.fromString "source-out"
  MaskIntersect -> Css.fromString "source-in"
  MaskExclude -> Css.fromString "xor"

data MaskMode = MaskAlpha | MaskLuminance

instance valueMaskMode :: Css.Val MaskMode where
  value = case _ of
    MaskAlpha -> Css.fromString "alpha"
    MaskLuminance -> Css.fromString "luminance"

mask
  :: ∀ loc size
   . Css.Loc loc
  => Array Css.BackgroundImage
  -> MaskComposite
  -> MaskMode
  -> loc
  -> Css.Size size
  -> Css.CSS
mask images composite mode loc size =
  let
    key :: ∀ a. Css.Val a => String -> a -> Css.CSS
    key k = Css.prefixed (Css.Common.browsers <> Css.Plain k)
  in
    do
      key "mask-image" images
      key "mask-mode" mode
      key "mask-position" loc
      key "mask-size" size
      key "mask-repeat" "no-repeat"
      Css.key (Css.fromString "mask-composite") $ Css.value composite
      Css.key (Css.fromString "-webkit-mask-composite") $ webkitMaskComposite
        composite
