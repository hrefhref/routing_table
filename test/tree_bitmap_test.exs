defmodule TreeBitmapTest do
  use ExUnit.Case
  doctest TreeBitmap
  alias TreeBitmap.NIF

  test "new/0" do
    table = NIF.new()
    assert is_reference(table)
  end

  test "length/1" do
    table = NIF.new()
    assert 0 == NIF.length(table)
  end

  test "add/4 and lookup/2" do
    table = NIF.new()
    assert :ok == NIF.add(table, {:inet4, 192, 168, 1, 0}, 24, 0)
    assert {:ok, _, 24, 0} = NIF.lookup(table, {:inet4, 192, 168, 1, 1})
    assert {:ok, nil} = NIF.lookup(table, {:inet4, 1, 1, 1, 1})
  end

  test "remove/2" do
    table = NIF.new()
    assert :ok == NIF.add(table, {:inet4, 192, 168, 1, 0}, 24, 0)
    assert {:ok, _, 24, 0} = NIF.lookup(table, {:inet4, 192, 168, 1, 1})
    assert :ok == NIF.remove(table, {:inet4, 192, 168, 1, 0}, 24)
    assert {:ok, nil} = NIF.lookup(table, {:inet4, 192, 168, 1, 1})
  end

  test "default route" do
    table = NIF.new()
    assert :ok == NIF.add(table, {:inet4, 0, 0, 0, 0}, 0, 0)
    assert {:ok, _, 0, 0} = NIF.lookup(table, {:inet4, 192, 168, 1, 1})
  end

  test "more to less specific" do
    table = NIF.new()
    :ok = NIF.add(table, {:inet4, 10, 69, 1, 0}, 24, 2)
    :ok = NIF.add(table, {:inet4, 10, 69, 0, 0}, 16, 1)
    :ok = NIF.add(table, {:inet4, 0, 0, 0, 0}, 0, 0)
    assert {:ok, _, _, 0} = NIF.lookup(table, {:inet4, 8, 8, 8, 8})
    assert {:ok, _, _, 2} = NIF.lookup(table, {:inet4, 10, 69, 1, 2})
    assert {:ok, _, _, 1} = NIF.lookup(table, {:inet4, 10, 69, 2, 2})
  end

  test "less to more specific" do
    table = NIF.new()
    :ok = NIF.add(table, {:inet4, 0, 0, 0, 0}, 0, 0)
    :ok = NIF.add(table, {:inet4, 10, 69, 0, 0}, 16, 1)
    :ok = NIF.add(table, {:inet4, 10, 69, 1, 0}, 24, 2)
    assert {:ok, _, _, 0} = NIF.lookup(table, {:inet4, 8, 8, 8, 8})
    assert {:ok, _, _, 2} = NIF.lookup(table, {:inet4, 10, 69, 1, 2})
    assert {:ok, _, _, 1} = NIF.lookup(table, {:inet4, 10, 69, 2, 2})
  end

  test "multiple routes" do
    table = NIF.new()
    :ok = NIF.add(table, {:inet4, 8, 8, 8, 0}, 24, 8)
    :ok = NIF.add(table, {:inet4, 1, 1, 0, 0}, 16, 1)
    :ok = NIF.add(table, {:inet4, 192, 168, 1, 1}, 32, 200)
    assert {:ok, _, _, 8} = NIF.lookup(table, {:inet4, 8, 8, 8, 8})
    assert {:ok, _, _, 1} = NIF.lookup(table, {:inet4, 1, 1, 0, 0})
    assert {:ok, _, _, 200} = NIF.lookup(table, {:inet4, 192, 168, 1, 1})
  end

end
