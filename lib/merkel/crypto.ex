defmodule Merkel.Crypto do
  @moduledoc """
  Module to perform merkle tree hashing
  """

  alias Merkel.BinaryNode, as: Node

  @default_hash_type :sha256
  @default_hash_function &:crypto.hash/2

  @hash_type Application.get_env(:merkel, :hash_algorithm, @default_hash_type)
  @hash_function Application.get_env(:merkel, :hash_function, @default_hash_function)

  # For use with the Erlang crypto library
  @hash_algorithms [
    :md5,
    :ripemd160,
    :sha,
    :sha224,
    :sha256,
    :sha384,
    :sha512,
    :sha256_sha256
  ]

  @doc """
  Performs hash

  Either uses the default Erlang crypto library or accepts a user specified
  anonymous function with arity 1 which accepts a binary argument
  """

  @spec hash(binary, none | atom, none | function) :: String.t()

  def hash(bin), do: hash(bin, @hash_type, @hash_function)
  def hash(bin, type), do: hash(bin, type, @hash_function)

  def hash(bin, type, func) when is_binary(bin) and is_atom(type) do
    cond do
      func == @default_hash_function ->
        do_hash(bin, type)

      # if a hash function has been specified other than the default
      true ->
        try do
          # Anonymous function must have arity 1
          func.(bin)
        rescue
          _ ->
            # Remind user
            msg =
              "Please ensure hash function passed in has arity 1, " <>
                "accepting a single binary argument."

            raise ArgumentError, message: msg
        end
    end
  end

  # Private helper routine to hash with the default hash function
  @spec do_hash(binary, atom) :: String.t()
  defp do_hash(bin, type) when is_binary(bin) do
    case type do
      # Handle the double hash separately
      :sha256_sha256 ->
        :crypto.hash(:sha256, :crypto.hash(:sha256, bin))
        |> Base.encode16(case: :lower)

      t when t in @hash_algorithms ->
        :crypto.hash(type, bin) |> Base.encode16(case: :lower)

      _ ->
        :crypto.hash(@default_hash_type, bin) |> Base.encode16(case: :lower)
    end
  end

  # Public helper routine to concat hashes takes hash strings or Nodes as args
  @spec hash_concat(binary | Node.t(), binary | Node.t()) :: String.t()
  def hash_concat(lh, rh) when is_binary(lh) and is_binary(rh), do: hash(lh <> rh)
  def hash_concat(%Node{} = l, %Node{} = r), do: hash(l.key_hash <> r.key_hash)
end
