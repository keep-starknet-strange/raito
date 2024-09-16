from poseidon_py.poseidon_hash import poseidon_hash_many

# The array of trees in the forest
# [T_1, T_2, T_4, T_8, ... ]
root_nodes = [None] * 27

# The set of leaf nodes in the forest
leaf_nodes = dict()


class Node:
    def __init__(self, key, left=None, right=None):
        self.val = key
        self.left = left
        self.right = right
        self.parent = None


def parent_node(root1, root2):
    # Convert hexadecimal strings to integers
    val1 = int(root1.val, 16)
    val2 = int(root2.val, 16)
    # Perform Poseidon hash
    root = poseidon_hash_many([val1, val2])
    # Convert the result back to a left-padded hexadecimal string
    root_hex = f"0x{root:064x}"
    root_node = Node(root_hex, root1, root2)
    root1.parent = root_node
    root2.parent = root_node
    return root_node


def utreexo_add(leaf):
    if leaf in leaf_nodes:
        raise Exception("Leaf exists already")

    n = Node(f"0x{leaf:064x}")
    leaf_nodes[leaf] = n
    h = 0
    r = root_nodes[h]
    while r is not None:
        n = parent_node(r, n)
        root_nodes[h] = None
        h = h + 1
        r = root_nodes[h]

    root_nodes[h] = n
    return root_nodes


def utreexo_delete(leaf):
    leaf_node = leaf_nodes[leaf]
    del leaf_nodes[leaf]

    proof, leaf_index = inclusion_proof(leaf_node)

    n = None
    h = 0
    while h < len(proof):
        p = proof[h]  # Iterate over each proof element
        if n is not None:
            n = parent_node(p, n)
        elif root_nodes[h] is None:
            p.parent = None
            root_nodes[h] = p
        else:
            n = parent_node(p, root_nodes[h])
            root_nodes[h] = None
        h = h + 1

    if n is not None:
        n.parent = None

    root_nodes[h] = n

    proof = list(map(lambda node: node.val, proof))
    return proof, leaf_index


def inclusion_proof(node):
    if node.parent is None:
        return [], 0

    parent = node.parent
    path, leaf_index = inclusion_proof(parent)

    if node == parent.left:
        path.insert(0, parent.right)
        leaf_index = leaf_index * 2
    else:
        path.insert(0, parent.left)
        leaf_index = leaf_index * 2 + 1

    return path, leaf_index


def reset_utreexo():
    global root_nodes, leaf_nodes
    root_nodes = [None] * 27
    leaf_nodes = dict()


def print_roots():
    print(
        "Roots:",
        list(map(lambda node: node.val if node is not None else "", root_nodes)),
    )


# Example usage
if __name__ == "__main__":
    # Add some elements
    utreexo_add(0x111111111111111111111111)
    utreexo_add(0x222222222222222222222222)
    utreexo_add(0x333333333333333333333333)
    utreexo_add(0x444444444444444444444444)
    print_roots()

    # Reset the Utreexo
    reset_utreexo()
    print_roots()
