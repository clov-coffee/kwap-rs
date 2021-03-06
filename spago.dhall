{ name = "toad-dev-halogen"
, dependencies =
  [ "aff"
  , "argonaut-core"
  , "arrays"
  , "bifunctors"
  , "codec-argonaut"
  , "console"
  , "control"
  , "css"
  , "datetime"
  , "dom-indexed"
  , "effect"
  , "either"
  , "enums"
  , "exceptions"
  , "filterable"
  , "foldable-traversable"
  , "halogen"
  , "halogen-css"
  , "halogen-subscriptions"
  , "halogen-svg-elems"
  , "integers"
  , "toad-dev"
  , "lists"
  , "maybe"
  , "newtype"
  , "now"
  , "numbers"
  , "ordered-collections"
  , "parsing"
  , "partial"
  , "prelude"
  , "profunctor"
  , "routing"
  , "routing-duplex"
  , "spec"
  , "strings"
  , "tailrec"
  , "transformers"
  , "tuples"
  , "unordered-collections"
  , "yoga-fetch"
  ]
, packages = ./packages.dhall
, sources = [ "src/**/*.purs", "test/**/*.purs" ]
}
