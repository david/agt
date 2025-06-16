defmodule AgtTest do
  use ExUnit.Case
  doctest Agt

  test "greets the world" do
    assert Agt.hello() == :world
  end
end
