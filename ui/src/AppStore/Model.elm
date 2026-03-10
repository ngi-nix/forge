module AppStore.Model exposing (..)

import AppStore.Config exposing (..)
import AppStore.Config.App exposing (..)
import AppStore.Route exposing (..)
import AppStore.Select.Model exposing (ModelSelect)


type Model
    = Model_Select ModelSelect
