defmodule UrlShortener.HelpersTest do
  use ExUnit.Case
  alias UrlShortener.Helpers

  describe "helpers" do
    test "create_random_slug/0" do
      :rand.seed(:exsss, {1000, 1000, 1000})
      for _ <- 1..1000 do
        assert Helpers.create_random_slug()
        |> String.match?(~r/^[[:alnum:]]{5}$/)
      end
    end

    test "create_random_slug/1 with seed" do
      :rand.seed(:exsss, {1000, 1000, 1000})
      for slug_length <- [0, 1, 7, 12] do
        assert Helpers.create_random_slug(slug_length)
        |> String.match?(~r/^[[:alnum:]]{#{slug_length}}$/)
      end
    end
  end
end
