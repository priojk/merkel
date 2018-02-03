defmodule Merkel.TreeTest do
  use ExUnit.Case, async: true

  # Test tree create, lookup, keys, insert, delete, size, tree_hash operations

  require Logger

  import Merkel.TestHelper
  import Merkel.Crypto

  alias Merkel.BinaryHashTree, as: Tree
  alias Merkel.BinaryNode, as: Node

  @list_size 20

  # Would like to use quick check or some property testing
  # But will do it the old fashioned way to build intuition first
  # Plus its fun drawing

  # Run before all tests
  setup_all do
    # seed random number generator with random seed
    <<a::32, b::32, c::32>> = :crypto.strong_rand_bytes(12)
    r_seed = {a, b, c}

    _ = :rand.seed(:exsplus, r_seed)

    :ok
  end

  # nil

  test "empty tree" do
    pair = {k0, _v} = {"starfish", :blue}
    pair2 = {"starfish", "green"}

    empty = Merkel.new()
    empty2 = Merkel.new([])

    assert empty == empty2

    assert %Tree{size: 0, root: nil} == empty

    # lookup item
    assert {:error, "key: starfish not found in tree"} == Merkel.lookup(empty, k0)

    # get keys list
    assert [] == Merkel.keys(empty)

    root_hash = "3755b417b0f937026ac1b867a397d6dec80dfd463c232c2daaf1de974b93da82"

    assert root_hash == hash(k0)

    # insert item
    root = %Node{
      key_hash: root_hash,
      search_key: k0,
      key: k0,
      value: :blue,
      height: 0,
      left: nil,
      right: nil
    }

    tree = %Tree{size: 1, root: root}

    assert tree == Merkel.insert(empty, pair)

    # Test update
    tree = Merkel.insert(tree, pair2)
    assert {:ok, "green"} == Merkel.lookup(tree, k0)

    # delete item
    assert {:error, "key: starfish not found in tree"} == Merkel.delete(empty, k0)

    # size
    assert 0 == Merkel.size(empty)

    # root hash
    assert nil == Merkel.tree_hash(empty)

    # audit
    proof = %Merkel.Audit{key: "starfish", path: nil}
    assert proof == Merkel.audit(empty, "starfish")
    assert false == Merkel.verify(proof, nil)
  end

  # root

  describe "tree of size 1" do
    setup :build_tree

    @tag size: 1
    test "crud", %{
      size: _sz,
      trees: {t0, t1, t2},
      valid_keys: vkeys,
      invalid_keys: ikeys,
      valid_values: vvs
    } do
      assert t0 == t1
      assert t1 == t2

      pair = {k2, v2} = {"starfish", :blue}

      k1 = Enum.at(vkeys, 0)
      v1 = Enum.at(vvs, 0)
      ik = Enum.at(ikeys, 0)

      k1_hash = hash(k1)

      root = %Node{
        key_hash: k1_hash,
        search_key: k1,
        key: k1,
        value: v1,
        height: 0,
        left: nil,
        right: nil
      }

      tree = %Tree{size: 1, root: root}

      assert tree == t0

      # lookup item
      assert {:ok, ^v1} = Merkel.lookup(t0, k1)
      assert {:error, _} = Merkel.lookup(t0, ik)

      # get keys list
      assert vkeys == Merkel.keys(t0)

      # setup for insert item

      k2_hash = hash(k2)

      k1_node = %Node{
        key_hash: k1_hash,
        search_key: k1,
        key: k1,
        value: v1,
        height: 0,
        left: nil,
        right: nil
      }

      k2_node = %Node{
        key_hash: k2_hash,
        search_key: k2,
        key: k2,
        value: v2,
        height: 0,
        left: nil,
        right: nil
      }

      root =
        case k1 > k2 do
          true ->
            root_hash = hash_concat(k2_hash, k1_hash)

            %Node{
              key_hash: root_hash,
              search_key: k2,
              key: nil,
              value: nil,
              height: 1,
              left: k2_node,
              right: k1_node
            }

          false ->
            root_hash = hash_concat(k1_hash, k2_hash)

            %Node{
              key_hash: root_hash,
              search_key: k1,
              key: nil,
              value: nil,
              height: 1,
              left: k1_node,
              right: k2_node
            }
        end

      # insert item but don't save merkel tree
      tree = %Tree{size: 2, root: root}

      assert tree == Merkel.insert(t0, pair)

      d_tree = %Tree{size: 0, root: nil}

      # delete item
      assert {:error, _} = Merkel.delete(t0, ik)
      assert {:ok, d_tree} == Merkel.delete(t0, k1)

      # size
      assert 1 == Merkel.size(t0)

      # root hash
      assert ^k1_hash = Merkel.tree_hash(t0)

      # audit
      proof = %Merkel.Audit{key: k1, path: {}}
      assert proof == Merkel.audit(t0, k1)
      assert true == Merkel.verify(proof, k1_hash)
    end
  end

  # root 
  #  / \
  # l   r

  # to

  #       root                 root
  #      /    \               /    \
  #  inner     r             l      inner
  #  / \                            /    \
  # l   r                          l      r

  # (Manually going through expectations in long function)
  describe "tree of size 2" do
    setup :build_tree

    @tag size: 2
    test "crud", %{
      size: _sz,
      trees: {t0, t1, t2},
      valid_keys: vkeys,
      invalid_keys: ikeys,
      valid_values: vvs
    } do
      assert t0 == t1
      assert t1 == t2

      pair = {k3, v3} = {"centipede", :long}

      k1 = Enum.at(vkeys, 0)
      k2 = Enum.at(vkeys, 1)
      v1 = Enum.at(vvs, 0)
      v2 = Enum.at(vvs, 1)

      ik = Enum.at(ikeys, 0)

      k1_hash = hash(k1)
      k2_hash = hash(k2)

      # Construct a tree of size 2
      k1_node = %Node{
        key_hash: k1_hash,
        search_key: k1,
        key: k1,
        value: v1,
        height: 0,
        left: nil,
        right: nil
      }

      k2_node = %Node{
        key_hash: k2_hash,
        search_key: k2,
        key: k2,
        value: v2,
        height: 0,
        left: nil,
        right: nil
      }

      root =
        case k1 > k2 do
          true ->
            root_hash = hash_concat(k2_hash, k1_hash)

            %Node{
              key_hash: root_hash,
              search_key: k2,
              key: nil,
              value: nil,
              height: 1,
              left: k2_node,
              right: k1_node
            }

          false ->
            root_hash = hash_concat(k1_hash, k2_hash)

            %Node{
              key_hash: root_hash,
              search_key: k1,
              key: nil,
              value: nil,
              height: 1,
              left: k1_node,
              right: k2_node
            }
        end

      t0_hash = root.key_hash

      tree = %Tree{size: 2, root: root}

      # Ensure the tree of size two matches t0
      assert tree == t0

      # Logger.debug("trees of size 2, 1: #{inspect tree} 2: #{inspect t0}")

      # lookup item
      assert {:ok, ^v1} = Merkel.lookup(t0, k1)
      assert {:error, _} = Merkel.lookup(t0, ik)

      # get keys list
      assert vkeys |> Enum.sort() == Merkel.keys(t0) |> Enum.sort()

      # setup for insert item, creating a tree of size 3
      k3_hash = hash(k3)

      k3_node = %Node{
        key_hash: k3_hash,
        search_key: k3,
        key: k3,
        value: v3,
        height: 0,
        left: nil,
        right: nil
      }

      root =
        case k3 > root.search_key do
          true ->
            # Logger.debug("root.right is #{inspect root.right}")
            inner =
              if k3 > root.right.search_key do
                h = hash_concat(root.right.key_hash, k3_hash)
                # Create new inner node
                %Node{
                  key_hash: h,
                  search_key: root.right.key,
                  key: nil,
                  value: nil,
                  height: 1,
                  left: root.right,
                  right: k3_node
                }
              else
                h = hash_concat(k3_hash, root.right.key_hash)
                # Create new inner node
                %Node{
                  key_hash: h,
                  search_key: k3,
                  key: nil,
                  value: nil,
                  height: 1,
                  left: k3_node,
                  right: root.right
                }
              end

            # Update root hash
            root_hash = hash_concat(root.left.key_hash, inner.key_hash)

            %Node{root | height: 2, key_hash: root_hash, right: inner}

          false ->
            # Logger.debug("root.left is #{inspect root.left}")
            inner =
              if k3 > root.left.search_key do
                h = hash_concat(root.left.key_hash, k3_hash)
                # Create new inner node
                %Node{
                  key_hash: h,
                  search_key: root.left.key,
                  key: nil,
                  value: nil,
                  height: 1,
                  left: root.left,
                  right: k3_node
                }
              else
                h = hash_concat(k3_hash, root.left.key_hash)
                # Create new inner node
                %Node{
                  key_hash: h,
                  search_key: k3,
                  key: nil,
                  value: nil,
                  height: 1,
                  left: k3_node,
                  right: root.left
                }
              end

            # Update root hash
            root_hash = hash_concat(inner.key_hash, root.right.key_hash)

            %Node{root | height: 2, key_hash: root_hash, left: inner}
        end

      # insert item
      tree_new = %Tree{size: 3, root: root}

      assert tree_new == Merkel.insert(t0, pair)

      # delete item in newly inserted tree, ensure it matches previous tree
      assert {:error, _} = Merkel.delete(tree_new, ik)
      assert {:ok, tree} == Merkel.delete(tree_new, k3)

      # size
      assert 2 == Merkel.size(t0)

      # root hash
      assert ^t0_hash = Merkel.tree_hash(t0)

      # audit
      assert true == Merkel.verify(Merkel.audit(t0, k1), t0_hash)
    end
  end

  test "verify audit hashes work for each key in tree of size n and are height balanced" do
    # Build trees of size 1 to and including list size
    Enum.map(1..@list_size, fn size ->
      tdata = build_tree(size)

      {:ok, {t0, t1, t2}} = tdata |> Keyword.fetch(:trees)
      {:ok, valid_keys} = tdata |> Keyword.fetch(:valid_keys)

      sorted_vkeys = valid_keys |> Enum.sort()

      # Process each tree
      Enum.map([t0, t1, t2], fn tree ->
        tree_keys = Merkel.keys(tree) |> Enum.sort()

        # Sanity check 
        assert sorted_vkeys == tree_keys

        # Logger.debug("tree_keys are #{inspect tree_keys}")

        # Process each of the valid keys for each tree
        # Specifically we create an audit proof for each key, verify it
        # And ensure the audit path length reflects that the tree is balanced
        Enum.map(sorted_vkeys, fn k ->
          proof = Merkel.audit(tree, k)
          assert true == Merkel.verify(proof, Merkel.tree_hash(tree))

          # Let's make sure the tree is balanced
          length = Merkel.Audit.length(proof)
          balanced_height = round(:math.log2(size))
          is_balanced = abs(length - balanced_height) <= 1
          assert true == is_balanced

          # Logger.debug("audit trail length is #{length}, tree size is #{size}, log2size is #{balanced_height}")

          true
        end)
      end)
    end)
  end

  # This proves that the inner key data is propagated properly upon delete
  test "deleting middle key in tree of size n and ensuring state is well-formed" do
    # Build trees of size 4 to and including list size
    Enum.map(4..@list_size, fn size ->
      tdata = build_tree(size)

      {:ok, {t0, t1, t2}} = tdata |> Keyword.fetch(:trees)
      {:ok, valid_keys} = tdata |> Keyword.fetch(:valid_keys)

      sorted_vkeys = Enum.sort(valid_keys)

      # 1) Grab the key that is the inner key for the root.
      # 2) Delete that key
      # 3) Ensure in the new tree, the key is not found
      # 4) Ensure the new root search key is < than the previous inner key 
      # (since it has to pick it from the left subtree and we don't rebalance after a delete)

      # 5) To be more exact this key should be the next decreasing key after the deleted key in 
      # the sorted keys list

      l =
        Enum.map([t0, t1, t2], fn tree ->
          # 1
          skey1 = tree.root.search_key

          # Sanity check
          {:ok, _} = Merkel.lookup(tree, skey1)

          # 2
          {:ok, tree} = Merkel.delete(tree, skey1)
          # 3
          {:error, _} = Merkel.lookup(tree, skey1)

          skey2 = tree.root.search_key

          # 4
          assert true = skey2 < skey1

          iskey1 = Enum.find_index(sorted_vkeys, fn x -> x == skey1 end)
          skey_smaller = Enum.at(sorted_vkeys, iskey1 - 1)
          # 5
          assert skey_smaller == skey2

          # Logger.debug("valid keys #{inspect sorted_vkeys}")
          # Logger.debug("skey1 #{inspect skey1}, skey2 #{inspect skey2}, skey_smaller #{inspect skey_smaller}")

          true
        end)

      assert true == Enum.uniq(l) |> List.first()
    end)
  end
end
