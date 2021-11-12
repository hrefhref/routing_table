# Routing Table

Efficient RIB for Elixir, implemented using a Rust NIF and [treebitmap](https://crates.io/crates/treebitmap).

The tables covers both IPv4 and IPv6, and values are any erlang term, stored in ets.

```elixir
table = RoutingTable.new()
RoutingTable.add(table, {10, 69, 0, 0}, 16, :vpn)
RoutingTable.add(table, {10, 69, 1, 0}, 24, :lan)
:vpn = RoutingTable.longest_match(table, {10, 69, 2, 1})
:lan = RoutingTable.longest_match(table, {10, 69, 1, 1})
nil = RoutingTable.longest_match(table, {10, 68, 1, 1})
```
