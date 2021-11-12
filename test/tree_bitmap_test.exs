defmodule TreeBitmapTest do
  use ExUnit.Case
  alias RoutingTable.TreeBitmap

  test "new/0" do
    table = TreeBitmap.new()
    assert is_reference(table)
  end

  test "memory/1" do
    table = TreeBitmap.new()
    assert {1200, 1152} == TreeBitmap.memory(table)
    {:ok, _} = TreeBitmap.add(table, {:inet4, 192, 168, 1, 0}, 24, 0)
    assert {1248, 1168} == TreeBitmap.memory(table)
  end

  test "new_with_capacity/1" do
    table = TreeBitmap.new_with_capacity(1000)
    assert is_reference(table)
    assert {109152, 37152} = TreeBitmap.memory(table)
  end

  test "length/1" do
    table = TreeBitmap.new()
    assert 0 == TreeBitmap.length(table)
  end

  test "add/4 and longest_match/2" do
    table = TreeBitmap.new()
    assert {:ok, _} = TreeBitmap.add(table, {:inet4, 192, 168, 1, 0}, 24, 0)
    assert {:ok, _, 24, 0} = TreeBitmap.longest_match(table, {:inet4, 192, 168, 1, 1})
    assert {:ok, nil} = TreeBitmap.longest_match(table, {:inet4, 1, 1, 1, 1})
  end

  test "add/2 existing" do
    table = TreeBitmap.new()
    {:ok, nil} = TreeBitmap.add(table, {:inet4, 10, 69, 0, 0}, 16, 0)
    assert {:ok, 0} = TreeBitmap.add(table, {:inet4, 10, 69, 0, 0}, 16, 1)
    assert {:ok, _, _, 1} = TreeBitmap.longest_match(table, {:inet4, 10, 69, 1, 1})
  end

  test "remove/3" do
    table = TreeBitmap.new()
    {:ok, _} = TreeBitmap.add(table, {:inet4, 192, 168, 1, 0}, 24, 0)
    assert {:ok, 0} == TreeBitmap.remove(table, {:inet4, 192, 168, 1, 0}, 24)
    assert {:ok, nil} = TreeBitmap.longest_match(table, {:inet4, 192, 168, 1, 1})
  end

  test "exact_match/3" do
    table = TreeBitmap.new()
    {:ok, _} = TreeBitmap.add(table, {:inet4, 192, 168, 1, 0}, 24, 0)
    assert {:ok, 0} = TreeBitmap.exact_match(table, {:inet4, 192, 168, 1, 0}, 24)
    assert {:ok, nil} = TreeBitmap.exact_match(table, {:inet4, 192, 168, 1, 1}, 32)
  end

  test "default route" do
    table = TreeBitmap.new()
    assert {:ok, nil} == TreeBitmap.add(table, {:inet4, 0, 0, 0, 0}, 0, 0)
    assert {:ok, _, 0, 0} = TreeBitmap.longest_match(table, {:inet4, 192, 168, 1, 1})
  end

  test "more to less specific" do
    table = TreeBitmap.new()
    {:ok, _} = TreeBitmap.add(table, {:inet4, 10, 69, 1, 0}, 24, 2)
    {:ok, _} = TreeBitmap.add(table, {:inet4, 10, 69, 0, 0}, 16, 1)
    {:ok, _} = TreeBitmap.add(table, {:inet4, 0, 0, 0, 0}, 0, 0)
    assert {:ok, _, _, 0} = TreeBitmap.longest_match(table, {:inet4, 8, 8, 8, 8})
    assert {:ok, _, _, 2} = TreeBitmap.longest_match(table, {:inet4, 10, 69, 1, 2})
    assert {:ok, _, _, 1} = TreeBitmap.longest_match(table, {:inet4, 10, 69, 2, 2})
  end

  test "less to more specific" do
    table = TreeBitmap.new()
    {:ok, _} = TreeBitmap.add(table, {:inet4, 0, 0, 0, 0}, 0, 0)
    {:ok, _} = TreeBitmap.add(table, {:inet4, 10, 69, 0, 0}, 16, 1)
    {:ok, _} = TreeBitmap.add(table, {:inet4, 10, 69, 1, 0}, 24, 2)
    assert {:ok, _, _, 0} = TreeBitmap.longest_match(table, {:inet4, 8, 8, 8, 8})
    assert {:ok, _, _, 2} = TreeBitmap.longest_match(table, {:inet4, 10, 69, 1, 2})
    assert {:ok, _, _, 1} = TreeBitmap.longest_match(table, {:inet4, 10, 69, 2, 2})
  end

  test "multiple routes" do
    table = TreeBitmap.new()
    {:ok, _} = TreeBitmap.add(table, {:inet4, 8, 8, 8, 0}, 24, 8)
    {:ok, _} = TreeBitmap.add(table, {:inet4, 1, 1, 0, 0}, 16, 1)
    {:ok, _} = TreeBitmap.add(table, {:inet4, 192, 168, 1, 1}, 32, 200)
    assert {:ok, _, _, 8} = TreeBitmap.longest_match(table, {:inet4, 8, 8, 8, 8})
    assert {:ok, _, _, 1} = TreeBitmap.longest_match(table, {:inet4, 1, 1, 0, 0})
    assert {:ok, _, _, 200} = TreeBitmap.longest_match(table, {:inet4, 192, 168, 1, 1})
  end

end
