defmodule Tower.PhoenixApp.Router do
  use Phoenix.Router, helpers: false

  get("/runtime-error", Tower.PhoenixApp.HomeController, :runtime_error)
  get("/abnormal-exit", Tower.PhoenixApp.HomeController, :abnormal_exit)
  get("/uncaught-throw", Tower.PhoenixApp.HomeController, :uncaught_throw)
  get("/show", Tower.PhoenixApp.HomeController, :show)
end
