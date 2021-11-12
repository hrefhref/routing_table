defmodule TreeBitmapTest do
  use ExUnit.Case
  doctest TreeBitmap
  alias TreeBitmap.NIF
  alias TreeBitmap

  test "TreeBitmap" do
    t = TreeBitmap.new()
    assert nil == TreeBitmap.add(t, {192, 168, 1, 0}, 24, :lan)
    assert nil == TreeBitmap.add(t, {8193, 3512, 34211, 0, 0, 35374, 880, 1}, 64, :lan)

    assert %{value: :lan} = TreeBitmap.longest_match(t, {192, 168, 1, 2})
    assert true = TreeBitmap.longest_match?(t, {192, 168, 1, 2})
    assert %{value: :lan} = TreeBitmap.longest_match(t, {8193, 3512, 34211, 0, 0, 35374, 880, 29492})
    assert true = TreeBitmap.longest_match?(t, {8193, 3512, 34211, 0, 0, 35374, 880, 29492})

    assert :lan = TreeBitmap.exact_match(t, {192, 168, 1, 1}, 24)
    assert true = TreeBitmap.exact_match?(t, {192, 168, 1, 1}, 24)
    assert :lan = TreeBitmap.exact_match(t, {8193, 3512, 34211, 0, 0, 35374, 880, 29492}, 64)
    assert true = TreeBitmap.exact_match?(t, {8193, 3512, 34211, 0, 0, 35374, 880, 29492}, 64)

    assert nil == TreeBitmap.longest_match(t, {8, 8, 8, 8})
    assert false == TreeBitmap.longest_match?(t, {8, 8, 8, 8})
    assert nil == TreeBitmap.exact_match(t, {8, 8, 8, 8}, 32)
    assert false == TreeBitmap.exact_match?(t, {8, 8, 8, 8}, 32)

    assert %{ets: 335, inet4: {1248, 1168}, inet6: {1344, 1168}} = TreeBitmap.memory(t)

    assert %{ets: 3, inet4: 1, inet6: 1} = TreeBitmap.length(t)
    assert :lan = TreeBitmap.remove(t, {8193, 3512, 34211, 0, 0, 35374, 880, 1}, 64)
    assert nil == TreeBitmap.longest_match(t, {8193, 3512, 34211, 0, 0, 35374, 880, 29492})
    assert %{ets: 2, inet4: 1, inet6: 0} = TreeBitmap.length(t)

    assert nil == TreeBitmap.add(t, {8193, 3512, 34211, 0, 0, 35374, 880, 1}, 64, :lan)
    assert :lan = TreeBitmap.add(t, {8193, 3512, 34211, 0, 0, 35374, 880, 1}, 64, :lan2)
    assert %{ets: 3, inet4: 1, inet6: 1} = TreeBitmap.length(t)
  end

  test "new/0" do
    table = NIF.new()
    assert is_reference(table)
  end

  test "memory/1" do
    table = NIF.new()
    assert {1200, 1152} == NIF.memory(table)
    {:ok, _} = NIF.add(table, {:inet4, 192, 168, 1, 0}, 24, 0)
    assert {1248, 1168} == NIF.memory(table)
  end

  test "new_with_capacity/1" do
    table = NIF.new_with_capacity(1000)
    assert is_reference(table)
    assert {109152, 37152} = NIF.memory(table)
  end

  test "length/1" do
    table = NIF.new()
    assert 0 == NIF.length(table)
  end

  test "add/4 and longest_match/2" do
    table = NIF.new()
    assert {:ok, _} = NIF.add(table, {:inet4, 192, 168, 1, 0}, 24, 0)
    assert {:ok, _, 24, 0} = NIF.longest_match(table, {:inet4, 192, 168, 1, 1})
    assert {:ok, nil} = NIF.longest_match(table, {:inet4, 1, 1, 1, 1})
  end

  test "add/2 existing" do
    table = NIF.new()
    {:ok, nil} = NIF.add(table, {:inet4, 10, 69, 0, 0}, 16, 0)
    assert {:ok, 0} = NIF.add(table, {:inet4, 10, 69, 0, 0}, 16, 1)
    assert {:ok, _, _, 1} = NIF.longest_match(table, {:inet4, 10, 69, 1, 1})
  end

  test "remove/3" do
    table = NIF.new()
    {:ok, _} = NIF.add(table, {:inet4, 192, 168, 1, 0}, 24, 0)
    assert {:ok, 0} == NIF.remove(table, {:inet4, 192, 168, 1, 0}, 24)
    assert {:ok, nil} = NIF.longest_match(table, {:inet4, 192, 168, 1, 1})
  end

  test "exact_match/3" do
    table = NIF.new()
    {:ok, _} = NIF.add(table, {:inet4, 192, 168, 1, 0}, 24, 0)
    assert {:ok, 0} = NIF.exact_match(table, {:inet4, 192, 168, 1, 0}, 24)
    assert {:ok, nil} = NIF.exact_match(table, {:inet4, 192, 168, 1, 1}, 32)
  end

  test "default route" do
    table = NIF.new()
    assert {:ok, nil} == NIF.add(table, {:inet4, 0, 0, 0, 0}, 0, 0)
    assert {:ok, _, 0, 0} = NIF.longest_match(table, {:inet4, 192, 168, 1, 1})
  end

  test "more to less specific" do
    table = NIF.new()
    {:ok, _} = NIF.add(table, {:inet4, 10, 69, 1, 0}, 24, 2)
    {:ok, _} = NIF.add(table, {:inet4, 10, 69, 0, 0}, 16, 1)
    {:ok, _} = NIF.add(table, {:inet4, 0, 0, 0, 0}, 0, 0)
    assert {:ok, _, _, 0} = NIF.longest_match(table, {:inet4, 8, 8, 8, 8})
    assert {:ok, _, _, 2} = NIF.longest_match(table, {:inet4, 10, 69, 1, 2})
    assert {:ok, _, _, 1} = NIF.longest_match(table, {:inet4, 10, 69, 2, 2})
  end

  test "less to more specific" do
    table = NIF.new()
    {:ok, _} = NIF.add(table, {:inet4, 0, 0, 0, 0}, 0, 0)
    {:ok, _} = NIF.add(table, {:inet4, 10, 69, 0, 0}, 16, 1)
    {:ok, _} = NIF.add(table, {:inet4, 10, 69, 1, 0}, 24, 2)
    assert {:ok, _, _, 0} = NIF.longest_match(table, {:inet4, 8, 8, 8, 8})
    assert {:ok, _, _, 2} = NIF.longest_match(table, {:inet4, 10, 69, 1, 2})
    assert {:ok, _, _, 1} = NIF.longest_match(table, {:inet4, 10, 69, 2, 2})
  end

  test "multiple routes" do
    table = NIF.new()
    {:ok, _} = NIF.add(table, {:inet4, 8, 8, 8, 0}, 24, 8)
    {:ok, _} = NIF.add(table, {:inet4, 1, 1, 0, 0}, 16, 1)
    {:ok, _} = NIF.add(table, {:inet4, 192, 168, 1, 1}, 32, 200)
    assert {:ok, _, _, 8} = NIF.longest_match(table, {:inet4, 8, 8, 8, 8})
    assert {:ok, _, _, 1} = NIF.longest_match(table, {:inet4, 1, 1, 0, 0})
    assert {:ok, _, _, 200} = NIF.longest_match(table, {:inet4, 192, 168, 1, 1})
  end

end
