defmodule RoutingTable.TreeBitmap do
  use Rustler, otp_app: :routing_table, crate: "treebitmap_nif"

  def new(), do: :erlang.nif_error(:nif_not_loaded)
  def new_with_capacity(_), do: :erlang.nif_error(:nif_not_loaded)
  def length(_), do: :erlang.nif_error(:nif_not_loaded)
  def add(_, _, _, _), do: :erlang.nif_error(:nif_not_loaded)
  def longest_match(_, _), do: :erlang.nif_error(:nif_not_loaded)
  def exact_match(_, _, _), do: :erlang.nif_error(:nif_not_loaded)
  def remove(_, _, _), do: :erlang.nif_error(:nif_not_loaded)
  def memory(_), do: :erlang.nif_error(:nif_not_loaded)

end
