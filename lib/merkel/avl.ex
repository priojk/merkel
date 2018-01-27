defmodule Merkel.AVL do
  @moduledoc """
  A self-balancing AVL tree ensures all insert operations are O(log n) 
  and tree height is always O(log n)
  """

  alias Merkel.BinaryHashTree, as: Tree
  alias Merkel.BinaryNode, as: Node


  ##############################################################################
  # AVL balance and rotation helpers
  def balance?(%Node{} = n), do: (n |> height_delta |> Kernel.abs) > 1

  def balance(%Node{left: l, right: r} = node, search_key, fn_updater)
  when is_binary(search_key) do
    
    # Using height delta we determine if we need to balance the tree at this node
    delta = height_delta(node)

    # 4 cases to handle a node imbalance

    _node = cond do

      # These are the 4 Cases

      # 1) y is left child of z and x is left child of y (Left Left Case)
      # 2) y is right child of z and x is right child of y (Right Right Case)
      # 3) y is left child of z and x is right child of y (Left Right Case)
      # 4) y is right child of z and x is left child of y (Right Left Case)

      # Case 1, Left Left
      
      # Since the delta is greater than 1, z's left subtree is higher
      # and since search_key is less than y's search_key it was inserted on its left
      # Hence - left left

      #         z                                      y 
      #        / \                                   /   \
      #       y   T4      Right Rotate (z)          x      z
      #      / \          - - - - - - - - ->      /  \    /  \ 
      #     x   T3                               T1  T2  T3  T4
      #    / \
      #  T1   T2

      delta > 1 and l != nil and search_key <= l.search_key ->
        right_rotate(node, fn_updater)

      
      # Case 2, Right Right

      # Since the delta is less than -1, z's right subtree is higher
      # and since the search_key is greater than y's search_key 
      # it was inserted on the right
      # Hence - right right

      #    z                                y
      #   /  \                            /   \ 
       #  T1   y     Left Rotate(z)       z      x
      #      /  \   - - - - - - - ->    / \    / \
      #     T2   x                     T1  T2 T3  T4
      #         / \
      #       T3  T4


      delta < -1 and r != nil and search_key > r.search_key -> 
        left_rotate(node, fn_updater)
          

      # Case 3, Left Right
      
      # Since the delta is greater than 1, z's left subtree is higher
      # Since the search_key is greater than y's search key, the node
      # was inserted on y's right subtree
      # Hence - left right

      #      z                               z                           x
      #     / \                            /   \                        /  \ 
      #    y   T4  Left Rotate (y)        x    T4  Right Rotate(z)    y      z
      #   / \      - - - - - - - - ->    /  \      - - - - - - - ->  / \    / \
      # T1   x                          y    T3                    T1  T2 T3  T4
      #     / \                        / \
      #   T2   T3                    T1   T2


      delta > 1 and l != nil and search_key > l.search_key ->
        %Node{node | left: left_rotate(l, fn_updater)} |> right_rotate(fn_updater)


      # Case 4, Right Left

      # Since the delta is less than -1, z's right subtree is higher
      # Since the search_key is less than y's search key, the node
      # was inserted on y's left subtree
      # Hence - right left

      #    z                            z                            x
      #   / \                          / \                          /  \ 
      # T1   y   Right Rotate (y)    T1   x      Left Rotate(z)   z      y
      #     / \  - - - - - - - - ->     /  \   - - - - - - - ->  / \    / \
      #    x   T4                      T2   y                  T1  T2  T3  T4
      #   / \                              /  \
      # T2   T3                           T3   T4


      delta < -1 and r != nil and search_key <= r.search_key ->
        %Node{node | right: right_rotate(r, fn_updater)} |> left_rotate(fn_updater)


      # Default case
      true -> node
    end

  end


_ =  """
  Right rotate subtree rooted at z. See following diagram
  We rotate z (the old root) to the right leaving y as the new root
  T1, T2, T3 and T4 are subtrees.
         z                                      y 
        / \                                   /   \
       y   T4      Right Rotate (z)          x      z
      / \          - - - - - - - - ->      /  \    /  \ 
     x   T3                               T1  T2  T3  T4
    / \
  T1   T2
  """

  defp right_rotate(%Node{left: %Node{left: x, right: t3} = y, right: t4} = z, updater) do
    
    # Perform rotation, update heights and max interval
    z = 
      %Node{ z | left: t3, height: max_height(t3, t4) + 1 }
      |> updater

    _y = 
      %Node{ y | right: z, height: max_height(x, z) + 1 }
      |> updater
  end


_ = """
  Left rotate subtree rooted at z. See following diagram
  We rotate z (the old root) to the left leaving y as the new root
    z                                y
   /  \                            /   \ 
  T1   y     Left Rotate(z)       z      x
      /  \   - - - - - - - ->    / \    / \
     T2   x                     T1  T2 T3  T4
         / \
       T3  T4
  """

  defp left_rotate(%Node{left: t1, right: %Node{left: t2, right: x} = y} = z, updater) do

    # Perform rotation, update heights and max interval
    z = 
      %Node{ z | right: t2, height: max_height(t1, t2) + 1 }
      |> updater

    _y = 
      %Node{ y | left: z, height: max_height(z, x) + 1 }
      |> updater
  end




  # Height helpers

  # Update max tree height
  defp max_height(left, right) do
    Kernel.max(do_height(left), do_height(right))
  end

  defp height_delta(nil), do: 0
  defp height_delta(%Node{left: l, right: r}), do: do_height(l) - do_height(r)

  defp do_height(nil), do: 0
  defp do_height(%Node{height: height}), do: height


end
