module NixForge.Model exposing (..)

import NixForge.Config exposing (..)
import NixForge.Config.App exposing (..)
import NixForge.Config.Package exposing (..)
import NixForge.Route exposing (..)
import NixForge.Select.Model exposing (ModelSelect)


type Model
    = Model_Select ModelSelect
