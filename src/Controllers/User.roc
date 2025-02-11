module [handleRoutes]

import web.Http exposing [Request, Response]
import Sql.User
import Models.Session exposing [Session]
import Views.Layout
import Views.Pages
import Helpers exposing [respondTemplate, parseQueryParams]

# TODO this should be a module parameter
staticBaseUrl = "static"

handleRoutes :
    {
        req : Request,
        urlSegments : List Str,
        dbPath : Str,
        getSession : Request, Str -> Task Session _,
    }
    -> Task Response _
handleRoutes = \{ req, urlSegments, dbPath, getSession } ->

    session = getSession! req dbPath
    # confirm the user is Authenticated
    Models.Session.isAuthenticated session.user |> Task.fromResult!

    queryParams =
        req.url
        |> parseQueryParams
        |> Result.withDefault (Dict.empty {})

    partial =
        queryParams
        |> Dict.get "partial"
        |> Result.map \val -> if val == "true" then Bool.true else Bool.false
        |> Result.withDefault Bool.false

    when (req.method, urlSegments) is
        (Get, []) ->
            users = Sql.User.list! { dbPath }

            view = Views.Pages.pageUsers {
                staticBaseUrl,
                users,
            }

            if partial then
                view
                |> respondTemplate 200 [
                    { name: "HX-Push-Url", value: "/users" },
                ]
            else
                view
                |> Views.Layout.sidebar
                |> respondTemplate 200 [
                    { name: "HX-Push-Url", value: "/users" },
                ]

        _ -> Task.err (NotHandled req)
