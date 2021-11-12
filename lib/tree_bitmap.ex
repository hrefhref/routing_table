defmodule TreeBitmap do
  alias TreeBitmap.NIF
  defstruct [:i4, :i6, :ets]

  @opaque t() :: %__MODULE__{}
  @type masklen :: non_neg_integer()

  def new(_opts \\ []) do
    %__MODULE__{i4: NIF.new(), i6: NIF.new(), ets: :ets.new(__MODULE__, [:public])}
  end

  @spec add(t(), :inet.ip_address(), masklen(), any()) :: nil | any()
  def add(tree, ip, masklen, value)

  def add(tree, {a, b, c, d}, masklen, value) do
    add(tree, tree.i4, {:inet4, a, b, c, d}, masklen, value)
  end

  def add(tree, {a, b, c, d, e, f, g, h}, masklen, value) do
    add(tree, tree.i6, {:inet6, a, b, c, d, e, f, g, h}, masklen, value)
  end

  @spec remove(t(), :inet.ip_address(), masklen()) :: nil | any()
  def remove(tree, ip, masklen)

  def remove(tree, {a, b, c, d}, masklen) do
    remove(tree, tree.i4, {:inet4, a, b, c, d}, masklen)
  end

  def remove(tree, {a, b, c, d, e, f, g, h}, masklen) do
    remove(tree, tree.i6, {:inet6, a, b, c, d, e, f, g, h}, masklen)
  end

  @spec longest_match(t(), :inet.ip_address()) :: map() | nil
  def longest_match(tree, ip)

  def longest_match(tree, {a, b, c, d}) do
    longest_match(tree, tree.i4, {:inet4, a, b, c, d})
  end

  def longest_match(tree, {a, b, c, d, e, f, g, h}) do
    longest_match(tree, tree.i6, {:inet6, a, b, c, d, e, f, g, h})
  end

  @spec longest_match?(t(), :inet.ip_address()) :: boolean()
  def longest_match?(tree, ip)

  def longest_match?(tree, {a, b, c, d}) do
    longest_match?(tree, tree.i4, {:inet4, a, b, c, d})
  end

  def longest_match?(tree, {a, b, c, d, e, f, g, h}) do
    longest_match?(tree, tree.i6, {:inet6, a, b, c, d, e, f, g, h})
  end

  @spec exact_match(t(), :inet.ip_address(), masklen()) :: map() | nil
  def exact_match(tree, ip, masklen)

  def exact_match(tree, {a, b, c, d}, masklen) do
    exact_match(tree, tree.i4, {:inet4, a, b, c, d}, masklen)
  end

  def exact_match(tree, {a, b, c, d, e, f, g, h}, masklen) do
    exact_match(tree, tree.i6, {:inet6, a, b, c, d, e, f, g, h}, masklen)
  end

  @spec exact_match?(t(), :inet.ip_address(), masklen()) :: boolean()
  def exact_match?(tree, ip, masklen)

  def exact_match?(tree, {a, b, c, d}, masklen) do
    exact_match?(tree, tree.i4, {:inet4, a, b, c, d}, masklen)
  end

  def exact_match?(tree, {a, b, c, d, e, f, g, h}, masklen) do
    exact_match?(tree, tree.i6, {:inet6, a, b, c, d, e, f, g, h}, masklen)
  end

  @type tree_memory() :: {nodes :: non_neg_integer(), results :: non_neg_integer()}
  @spec memory(t()) :: %{inet4: tree_memory(), inet6: tree_memory(), ets: non_neg_integer()}
  def memory(tree) do
    %{inet4: NIF.memory(tree.i4), inet6: NIF.memory(tree.i6), ets: :ets.info(tree.ets, :memory)}
  end

  @spec length(t()) :: %{inet4: non_neg_integer(), inet6: non_neg_integer(), ets: non_neg_integer()}
  def length(tree) do
    %{inet4: NIF.length(tree.i4), inet6: NIF.length(tree.i6), ets: :ets.info(tree.ets, :size)}
  end

  defp add(tree, tbm, ip, masklen, value) do
    id = :ets.update_counter(tree.ets, {__MODULE__, :counter}, 1, {{__MODULE__, :counter}, -1})
    :ets.insert(tree.ets, {id, value})
    {:ok, prev_id} = NIF.add(tbm, ip, masklen, id)
    prev = if prev_id do
      [{^prev_id, value}] = :ets.lookup(tree.ets, prev_id)
      :ets.delete(tree.ets, prev_id)
      value
    end
    prev
  end

  defp remove(tree, tbm, ip, masklen) do
    {:ok, id} = NIF.remove(tbm, ip, masklen)
    prev = if id do
      [{^id, value}] = :ets.lookup(tree.ets, id)
      :ets.delete(tree.ets, id)
      value
    end
    prev
  end

  defp longest_match(tree, tbm, ip) do
    case NIF.longest_match(tbm, ip) do
      {:ok, prefix, masklen, id} ->
        [{^id, value}] = :ets.lookup(tree.ets, id)
        %{prefix: to_inet(prefix), len: masklen, value: value}
      {:ok, nil} ->
        nil
    end
  end

  defp longest_match?(_, tbm, ip) do
	  case NIF.longest_match(tbm, ip) do
      {:ok, nil} -> false
      {:ok, _, _, _} -> true
    end
  end

  defp exact_match(tree, tbm, ip, masklen) do
    case NIF.exact_match(tbm, ip, masklen) do
      {:ok, nil} ->
        nil
      {:ok, id} ->
        [{^id, value}] = :ets.lookup(tree.ets, id)
        value
    end
  end

  defp exact_match?(_, tbm, ip, masklen) do
	  case NIF.exact_match(tbm, ip, masklen) do
      {:ok, nil} -> false
      {:ok, _} -> true
    end
  end

  defp to_inet({:inet4, a, b, c, d}), do: {a, b, c, d}
  defp to_inet({:inet6, a, b, c, d, e, f, g, h}), do: {a, b, c, d, e, f, g, h}

end
