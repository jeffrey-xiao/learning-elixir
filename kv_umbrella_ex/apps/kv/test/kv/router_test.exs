defmodule Kv.RouterTest do
  use ExUnit.Case, async: true

  @tag :distributed
  test "route requests across nodes" do
    assert Kv.Router.route("hello", Kernel, :node, []) == :"foo@olivia-2"
    assert Kv.Router.route("world", Kernel, :node, []) == :"bar@olivia-2"
  end

  test "raises error on unknown entries" do
    assert_raise RuntimeError, ~r/Could not find entry/, fn ->
      Kv.Router.route("1", Kernel, :node, [])
    end
  end
end
