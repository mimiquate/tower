defmodule Tower.PhoenixApp.ErrorHTML do
  def render("500.html", _assigns) do
    "Internal Server Error"
  end
end
