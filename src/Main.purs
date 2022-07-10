module Main where

import Prelude

import Control.Monad.Rec.Class (forever)
import Data.Bifunctor (lmap)
import Data.Either (either)
import Data.Maybe (Maybe(..), fromMaybe)
import Data.Time.Duration (Milliseconds(..))
import Effect (Effect)
import Effect.Aff (Aff)
import Effect.Aff as Aff
import Effect.Aff.Class (class MonadAff)
import Effect.Console as Console
import Halogen as H
import Halogen.Aff as HA
import Halogen.Subscription as HS
import Halogen.VDom.Driver (runUI)
import Kwap.App as Kwap
import Kwap.Action as Kwap.Action
import Kwap.Css as Kwap.Css
import Kwap.Query as Kwap.Query
import Kwap.Route as Kwap.Route
import Kwap.State as Kwap.State
import Kwap.Concept as Concept
import Kwap.Navigate (navigate)
import Routing.Duplex as Routing.Duplex
import Routing.Hash as Routing.Hash
import Web.Event.Event as Event
import Web.UIEvent.MouseEvent as MouseEvent

main :: Effect Unit
main =
  let
    tellAppRouteChanged _ (Just prev) new | prev == new = pure unit
    tellAppRouteChanged io _ route = void <<< Aff.launchAff $
      Kwap.Query.sendNavigate (fromMaybe Kwap.Route.Home route) io
  in
    HA.runHalogenAff do
      body <- HA.awaitBody
      io <- runUI (H.hoist Kwap.runM component) unit body
      H.liftEffect <<< void <<< Routing.Hash.matchesWith
        (Routing.Duplex.parse $ Routing.Duplex.optional Kwap.Route.codec) $
        tellAppRouteChanged io

component :: ∀ i o. H.Component Kwap.Query.Query i o Kwap.M
component =
  H.mkComponent
    { initialState: const Kwap.State.init
    , render: Kwap.render
    , eval: H.mkEval H.defaultEval
        { handleAction = handleAction
        , handleQuery = handleQuery
        , initialize = Just Kwap.Action.Init
        }
    }

timer :: ∀ m a. MonadAff m => Milliseconds -> a -> m (HS.Emitter a)
timer ms val = do
  { emitter, listener } <- H.liftEffect HS.create
  _ <- H.liftAff <<< Aff.forkAff <<< forever $ do
    Aff.delay ms
    H.liftEffect $ HS.notify listener val
  pure emitter

handleQuery
  :: ∀ a s o
   . Kwap.Query.Query a
  -> H.HalogenM Kwap.State.State Kwap.Action.Action s o Kwap.M (Maybe a)
handleQuery = case _ of
  Kwap.Query.Navigate route _ -> do
    Kwap.put route
    pure Nothing

handleAction
  :: ∀ s o
   . Kwap.Action.Action
  -> H.HalogenM Kwap.State.State Kwap.Action.Action s o Kwap.M Unit
handleAction =
  case _ of
    Kwap.Action.Init -> do
      _ <- H.subscribe =<< timer (Milliseconds 100.0) Kwap.Action.Tick

      decl <- H.liftAff $ Concept.fetchDecl
      either (H.liftEffect <<< Console.error) (const <<< pure $ unit) decl

      Kwap.put $ lmap (const "An error occurred fetching concepts.") decl
    Kwap.Action.NavbarSectionPicked n -> navigate (Kwap.Route.ofNavbarSection n)
    Kwap.Action.Tick -> do
      kwapGradientState <- Kwap.State.kwapGradient <$> H.get
      Kwap.put $ Kwap.Css.tick kwapGradientState
    Kwap.Action.Nop -> mempty
