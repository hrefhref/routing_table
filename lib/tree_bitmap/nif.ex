defmodule TreeBitmap.NIF do
  use Rustler, otp_app: :tree_bitmap, crate: "treebitmap_nif"

  def new(), do: :erlang.nif_error(:nif_not_loaded)
  def length(_), do: :erlang.nif_error(:nif_not_loaded)
  def add(_, _, _, _), do: :erlang.nif_error(:nif_not_loaded)
  def lookup(_, _), do: :erlang.nif_error(:nif_not_loaded)
  def remove(_, _, _), do: :erlang.nif_error(:nif_not_loaded)

end
