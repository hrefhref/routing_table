defmodule RoutingTableTest do
  use ExUnit.Case
  doctest RoutingTable

  test "RoutingTable" do
    t = RoutingTable.new()
    assert nil == RoutingTable.add(t, {192, 168, 1, 0}, 24, :lan)
    assert nil == RoutingTable.add(t, {8193, 3512, 34211, 0, 0, 35374, 880, 1}, 64, :lan)

    assert %{value: :lan} = RoutingTable.longest_match(t, {192, 168, 1, 2})
    assert true = RoutingTable.longest_match?(t, {192, 168, 1, 2})
    assert %{value: :lan} = RoutingTable.longest_match(t, {8193, 3512, 34211, 0, 0, 35374, 880, 29492})
    assert true = RoutingTable.longest_match?(t, {8193, 3512, 34211, 0, 0, 35374, 880, 29492})

    assert :lan = RoutingTable.exact_match(t, {192, 168, 1, 1}, 24)
    assert true = RoutingTable.exact_match?(t, {192, 168, 1, 1}, 24)
    assert :lan = RoutingTable.exact_match(t, {8193, 3512, 34211, 0, 0, 35374, 880, 29492}, 64)
    assert true = RoutingTable.exact_match?(t, {8193, 3512, 34211, 0, 0, 35374, 880, 29492}, 64)

    assert nil == RoutingTable.longest_match(t, {8, 8, 8, 8})
    assert false == RoutingTable.longest_match?(t, {8, 8, 8, 8})
    assert nil == RoutingTable.exact_match(t, {8, 8, 8, 8}, 32)
    assert false == RoutingTable.exact_match?(t, {8, 8, 8, 8}, 32)

    assert %{ets: 330, inet4: {1248, 1168}, inet6: {1344, 1168}} = RoutingTable.memory(t)

    assert %{ets: 2, inet4: 1, inet6: 1} = RoutingTable.length(t)
    assert :lan = RoutingTable.remove(t, {8193, 3512, 34211, 0, 0, 35374, 880, 1}, 64)
    assert nil == RoutingTable.longest_match(t, {8193, 3512, 34211, 0, 0, 35374, 880, 29492})
    assert %{ets: 2, inet4: 1, inet6: 0} = RoutingTable.length(t)
    assert :lan == RoutingTable.remove(t, {192, 168, 1, 0}, 24)
    assert %{ets: 1, inet4: 0, inet6: 0} = RoutingTable.length(t)

    assert nil == RoutingTable.add(t, {8193, 3512, 34211, 0, 0, 35374, 880, 1}, 64, :lan)
    assert :lan = RoutingTable.add(t, {8193, 3512, 34211, 0, 0, 35374, 880, 1}, 64, :lan2)
    assert %{ets: 2, inet4: 0, inet6: 1} = RoutingTable.length(t)
  end


end
