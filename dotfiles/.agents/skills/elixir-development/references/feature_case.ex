defmodule MyAppWeb.FeatureCase do
  @moduledoc """
  Test case for user journeys exercised through PhoenixTest.
  """

  use ExUnit.CaseTemplate

  using opts do
    opts = Keyword.put_new(opts, :async, true)

    quote bind_quoted: [opts: opts] do
      use MyAppWeb.ConnCase, opts

      alias MyApp.Accounts.User

      import PhoenixTest
      import MyApp.Factory
      import MyAppWeb.FeatureCase
      import Swoosh.TestAssertions
    end
  end

  import PhoenixTest
  import Phoenix.ConnTest, only: [build_conn: 0]

  setup do
    :ok = Swoosh.Adapters.Sandbox.checkout()
    on_exit(&Swoosh.Adapters.Sandbox.checkin/0)
  end

  def visit(path) do
    build_conn()
    |> visit(path)
  end

  def visit!(conn, path, opts \\ []) do
    conn
    |> visit(path)
    |> assert_path(path, opts)
  end

  def sign_in(email) do
    build_conn()
    |> sign_in(email)
  end

  def sign_in(conn, email) do
    conn
    |> visit("/sign-in")
    |> fill_in("Email", with: email)
    |> click_button("Request magic link")

    assert_receive {:email, email}
    [_, path] = Regex.run(~r{https?://[^/]+(/magic_link/[^"]+)}, email.html_body)

    build_conn()
    |> visit(path)
    |> click_button("Sign in")
  end
end
