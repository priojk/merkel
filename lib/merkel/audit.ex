defmodule Merkel.Proof.Audit do

  alias Merkel.Proof.Audit

  alias Merkel.BinaryHashTree, as: BHTree
  alias Merkel.BinaryNode, as: BNode

  require Logger

  defstruct key: nil, path: []

  # Create audit proof
  # This includes the set of sibling hashes in the path to the merkle root, 
  # that will ensure verification

  # Either create the audit proof with the hash or with the original string data

  def create(%BHTree{root: nil}, _key), do: nil
  def create(%BHTree{root: %BNode{} = root}, key) when is_binary(key) do

    path = traverse(root, key, [], [])

    %Audit{key: key, path: path}
  end


  def verify(%Audit{key: key, path: trail}, tree_hash) 
  when is_binary(key) and is_tuple(trail) and is_binary(tree_hash) do

    # Basically we walk through the list of audit hashes (trail) which represent
    # a distinct tree level
    
    # Given the nested tuple trail, we tail recurse to the leaf level 
    # using pattern matching, then create the hash accumulation
    acc_hash = prove(key, trail, [])

    acc_hash == tree_hash
  end



  #####################
  # Private functions #
  #####################


  # Recursive traverse implementation which builds the audit hash verification trail
  # These are the sibling node hashes along the way from the leaf in question to the
  # merkle tree root.

  # We start from the root, and the trail is composed backwards starting with leaf level

  defp traverse(%BNode{height: 0}, _key, audit_trail, pattern_trail)
  when is_list(audit_trail) and is_list(pattern_trail) do 

    # Lists are from leaf level to next to root level

    # Combine the two lists so we can easily reduce
    # audit trail is just a list of the audit hashes
    # pattern trail tracks the ordering
    zipper = Enum.zip(audit_trail, pattern_trail) 

    # Create the audit path with the hash order information already encoded into the path
    # The path is a nested tuple :)
    # (This way we don't have to keep track of left and rights separately or use extra overhead structures)
    Enum.reduce(zipper, {}, fn {audit_hash, directive}, acc ->      
      case directive do
        :audit_on_right -> {acc, audit_hash}
        :audit_on_left -> {audit_hash, acc}
      end
    end)

  end


  defp traverse(%BNode{search_key: s_key, left: l, right: r} = i, key, audit_trail, pattern_trail) 
  when is_binary(key) and is_list(audit_trail) and is_list(pattern_trail) 
  and not(is_nil(l)) and not(is_nil(r)) do

    # At each tree level we generate:
    # 1) the next audit pattern order, 
    # 2) the next audit hash,
    # 3) and the next node level to traverse to

    # true means the path is on the left and the audit hash is the right sibling hash
    # so when we verify, we do hash(hash_acc, audit_hash)

    # false means the path is on the right and the audit hash is the left sibling
    # so when we verify, instead of hash(hash_acc, audit_hash) we do hash(audit_hash, hash_acc)

    {next_pattern, next_audit, next_node} =
      case key <= s_key do
        true -> {:audit_on_right, r.key_hash, l}
        false -> {:audit_on_left, l.key_hash, r}
      end

    # By putting the accumulated states within the function as params, we are tail recursive
    traverse(next_node, key, 
             [next_audit] ++ audit_trail, 
             [next_pattern] ++ pattern_trail)
  end


  # We use pattern matching to descend through our tuple, 
  # audit path representation, keeping track of the audit path via a stack
  # Eventually we reduce the stack with the hash accumulated value

  defp prove(key, {acc, r}, stack) when is_binary(r) and is_tuple(acc) do
    prove(key, acc, [{r, :audit_on_right}] ++ stack)
  end

  defp prove(key, {l, acc}, stack) when is_binary(l) and is_tuple(acc) do
    prove(key, acc, [{l, :audit_on_left}] ++ stack)
  end

  defp prove(key, {}, stack) when is_binary(key) and is_list(stack) do

    key_hash = BHTree.hash(key)

    # We verify the key from bottom up
    # Hence the stack is prepended to, allowing us to start at the leaf level

    Enum.reduce(stack, key_hash, fn {audit_hash, directive}, hash_acc ->

      case directive do
        :audit_on_left -> BHTree.hash(audit_hash <> hash_acc)
        :audit_on_right -> BHTree.hash(hash_acc <> audit_hash)
      end

    end)
  end


end
