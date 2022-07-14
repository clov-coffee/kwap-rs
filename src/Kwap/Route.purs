module Kwap.Route
  ( Route(..)
  , OneOrAll(..)
  , ofNavbarSection
  , toNavbarSection
  , init
  , codec
  , print
  ) where

import Data.Array (null)
import Data.BooleanAlgebra (not)
import Data.Either (Either)
import Data.Filterable (filter)
import Data.Generic.Rep (class Generic)
import Data.Maybe (Maybe(..), maybe)
import Data.Profunctor (dimap)
import Data.Show.Generic (genericShow)
import Data.String (joinWith, split)
import Data.String.Pattern (Pattern(..))
import Kwap.Concept as Concept
import Kwap.Navbar.Section as Navbar
import Prelude (class Eq, class Show, map, ($), (<<<), (>>>))
import Routing.Duplex (RouteDuplex', optional, rest, root)
import Routing.Duplex as Routing.Duplex
import Routing.Duplex.Generic (noArgs, sum)
import Routing.Duplex.Generic.Syntax ((/))
import Routing.Duplex.Parser (RouteError)

maybeConceptPath :: RouteDuplex' (Maybe Concept.Path)
maybeConceptPath =
  let
    toSegments = maybe [] (Concept.pathString >>> split (Pattern "/"))
    ofSegments = Just
      >>> filter (not <<< null)
      >>> map (joinWith "/" >>> Concept.Path)
  in
    dimap toSegments ofSegments rest

data OneOrAll a = One a | All

derive instance eqOneOrAll :: Eq a => Eq (OneOrAll a)
derive instance genericOneOrAll :: Generic (OneOrAll a) _
instance showOneOrAll :: Show a => Show (OneOrAll a) where
  show = genericShow

maybeOne :: forall a. OneOrAll a -> Maybe a
maybeOne (One a) = Just a
maybeOne All = Nothing

oneMaybe :: forall a. Maybe a -> OneOrAll a
oneMaybe (Just a) = One a
oneMaybe Nothing = All

orAll :: forall a. RouteDuplex' (Maybe a) -> RouteDuplex' (OneOrAll a)
orAll a = dimap maybeOne oneMaybe a

data Route
  = Home
  | Concepts (OneOrAll Concept.Path)
  | Book

derive instance genericRoute :: Generic Route _
derive instance eqRoute :: Eq Route
instance showRoute :: Show Route where
  show = genericShow

init :: Route
init = Home

ofNavbarSection :: Navbar.Section -> Route
ofNavbarSection Navbar.Home = Home
ofNavbarSection Navbar.Concepts = Concepts All
ofNavbarSection Navbar.Book = Book

toNavbarSection :: Route -> Navbar.Section
toNavbarSection Home = Navbar.Home
toNavbarSection (Concepts _) = Navbar.Concepts
toNavbarSection Book = Navbar.Book

print :: Route -> String
print = Routing.Duplex.print codec

codec :: RouteDuplex' Route
codec = root $ sum
  { "Home": noArgs
  , "Concepts": "concepts" / (orAll maybeConceptPath)
  , "Book": "book" / noArgs
  }