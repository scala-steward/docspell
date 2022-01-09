module Comp.BookmarkChooser exposing
    ( Model
    , Msg
    , Selection
    , emptySelection
    , getQueries
    , init
    , isEmpty
    , isEmptySelection
    , update
    , view
    )

import Api.Model.BookmarkedQuery exposing (BookmarkedQuery)
import Api.Model.ShareDetail exposing (ShareDetail)
import Data.Bookmarks exposing (AllBookmarks)
import Data.Icons as Icons
import Html exposing (Html, a, div, i, label, span, text)
import Html.Attributes exposing (class, classList, href)
import Html.Events exposing (onClick)
import Messages.Comp.BookmarkChooser exposing (Texts)
import Set exposing (Set)


type alias Model =
    { all : AllBookmarks
    }


init : AllBookmarks -> Model
init all =
    { all = all
    }


isEmpty : Model -> Bool
isEmpty model =
    model.all == Data.Bookmarks.empty


type alias Selection =
    { bookmarks : Set String
    , shares : Set String
    }


emptySelection : Selection
emptySelection =
    { bookmarks = Set.empty, shares = Set.empty }


isEmptySelection : Selection -> Bool
isEmptySelection sel =
    sel == emptySelection


type Kind
    = Bookmark
    | Share


type Msg
    = Toggle Kind String


getQueries : Model -> Selection -> List BookmarkedQuery
getQueries model sel =
    let
        member set bm =
            Set.member bm.id set

        filterBookmarks f bms =
            List.filter f bms |> List.map identity
    in
    List.concat
        [ filterBookmarks (member sel.bookmarks) model.all.bookmarks
        , List.map shareToBookmark model.all.shares
            |> List.filter (member sel.shares)
        ]



--- Update


update : Msg -> Model -> Selection -> ( Model, Selection )
update msg model current =
    let
        toggle name set =
            if Set.member name set then
                Set.remove name set

            else
                Set.insert name set
    in
    case msg of
        Toggle kind id ->
            case kind of
                Bookmark ->
                    ( model, { current | bookmarks = toggle id current.bookmarks } )

                Share ->
                    ( model, { current | shares = toggle id current.shares } )



--- View


view : Texts -> Model -> Selection -> Html Msg
view texts model selection =
    let
        ( user, coll ) =
            List.partition .personal model.all.bookmarks
    in
    div [ class "flex flex-col" ]
        [ userBookmarks texts user selection
        , collBookmarks texts coll selection
        , shares texts model selection
        ]


titleDiv : String -> Html msg
titleDiv label =
    div [ class "text-sm opacity-75 py-0.5 italic" ]
        [ text label

        --, text " ──"
        ]


userBookmarks : Texts -> List BookmarkedQuery -> Selection -> Html Msg
userBookmarks texts model sel =
    div
        [ class "mb-2"
        , classList [ ( "hidden", model == [] ) ]
        ]
        [ titleDiv texts.userLabel
        , div [ class "flex flex-col space-y-2 md:space-y-1" ]
            (List.map (mkItem "fa fa-bookmark" sel Bookmark) model)
        ]


collBookmarks : Texts -> List BookmarkedQuery -> Selection -> Html Msg
collBookmarks texts model sel =
    div
        [ class "mb-2"
        , classList [ ( "hidden", [] == model ) ]
        ]
        [ titleDiv texts.collectiveLabel
        , div [ class "flex flex-col space-y-2 md:space-y-1" ]
            (List.map (mkItem "fa fa-bookmark font-light" sel Bookmark) model)
        ]


shares : Texts -> Model -> Selection -> Html Msg
shares texts model sel =
    let
        bms =
            List.map shareToBookmark model.all.shares
    in
    div
        [ class ""
        , classList [ ( "hidden", List.isEmpty bms ) ]
        ]
        [ titleDiv texts.shareLabel
        , div [ class "flex flex-col space-y-2 md:space-y-1" ]
            (List.map (mkItem Icons.share sel Share) bms)
        ]


mkItem : String -> Selection -> Kind -> BookmarkedQuery -> Html Msg
mkItem icon sel kind bm =
    a
        [ class "flex flex-row items-center rounded px-1 py-1 hover:bg-blue-100 dark:hover:bg-slate-600"
        , href "#"
        , onClick (Toggle kind bm.id)
        ]
        [ if isSelected sel kind bm.id then
            i [ class "fa fa-check" ] []

          else
            i [ class icon ] []
        , span [ class "ml-2" ] [ text bm.name ]
        ]


isSelected : Selection -> Kind -> String -> Bool
isSelected sel kind id =
    Set.member id <|
        case kind of
            Bookmark ->
                sel.bookmarks

            Share ->
                sel.shares


shareToBookmark : ShareDetail -> BookmarkedQuery
shareToBookmark share =
    BookmarkedQuery share.id (Maybe.withDefault "-" share.name) share.name share.query False 0
