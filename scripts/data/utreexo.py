# SPDX-FileCopyrightText: 2022 ZeroSync <hello@zerosync.org>
#
# SPDX-License-Identifier: MIT
from poseidon_py.poseidon_hash import poseidon_hash_many


class Node:
    def __init__(self, key, left=None, right=None):
        self.val = key
        self.left = left
        self.right = right
        self.parent = None

    def __repr__(self) -> str:
        return str(self.val)


class Utreexo:
    def __init__(self):
        self.root_nodes = []
        self.leaf_nodes = {}

    def print_state(self):
        print("--- Utreexo State ---")
        print("Root Nodes:")
        for idx, node in enumerate(self.root_nodes):
            if node is not None:
                print(f"  Height {idx}: {node.val}")
        print("\nLeaf Nodes:")
        for leaf_val, node in self.leaf_nodes.items():
            print(f"  Leaf {leaf_val}: {node.val}")
        print("---------------------\n")

    def print_tree(self):
        print("--- Utreexo Tree ---")

        def _print_subtree(node, prefix=""):
            if node is not None:
                print(f"{prefix}{node.val}")
                if node.left is not None or node.right is not None:
                    # Display branches of the left subtree
                    _print_subtree(node.left, prefix + "├── ")
                    # Display branches of the right subtree
                    _print_subtree(node.right, prefix + "└── ")

        for idx, root in enumerate(self.root_nodes):
            if root is not None:
                print(f"Root at height {idx}:")
                _print_subtree(root)
        print("---------------------\n")

    def parent_node(self, root1, root2):
        val1 = int(root1.val, 16)
        val2 = int(root2.val, 16)
        root = poseidon_hash_many([val1, val2])
        root_hex = f"0x{root:064x}"
        root_node = Node(root_hex, root1, root2)
        root1.parent = root_node
        root2.parent = root_node
        return root_node

    def add(self, leaf):
        if leaf in self.leaf_nodes:
            raise Exception("Leaf exists already")

        n = Node(f"0x{leaf:064x}")
        self.leaf_nodes[leaf] = n
        h = 0

        while len(self.root_nodes) <= h:
            self.root_nodes.append(None)

        r = self.root_nodes[h]
        while r is not None:
            n = self.parent_node(r, n)
            self.root_nodes[h] = None
            h += 1
            r = self.root_nodes[h]
        self.root_nodes[h] = n

        if h == len(self.root_nodes) - 1:
            self.root_nodes.append(None)

        return self.root_nodes

    def delete(self, leaf):
        if leaf not in self.leaf_nodes:
            raise Exception(f"Leaf {leaf} does not exist in the Utreexo accumulator")

        leaf_node = self.leaf_nodes[leaf]
        del self.leaf_nodes[leaf]

        proof, leaf_index = self.inclusion_proof(leaf_node)

        n = None
        h = 0
        while h < len(proof):
            p = proof[h]
            if n is not None:
                n = self.parent_node(p, n)
            elif self.root_nodes[h] is None:
                p.parent = None
                self.root_nodes[h] = p
            else:
                n = self.parent_node(p, self.root_nodes[h])
                self.root_nodes[h] = None
            h += 1

        if n is not None:
            n.parent = None

        self.root_nodes[h] = n

        return proof, leaf_index

    def inclusion_proof(self, node):
        if node.parent is None:
            return [], 0

        parent = node.parent
        path, leaf_index = self.inclusion_proof(parent)

        if node == parent.left:
            path.insert(0, parent.right)
            leaf_index *= 2
        else:
            path.insert(0, parent.left)
            leaf_index = leaf_index * 2 + 1

        return path, leaf_index

    def reset(self):
        self.root_nodes = []
        self.leaf_nodes = {}

    def print_roots(self):
        roots = [node.val if node is not None else "" for node in self.root_nodes]
        print("Roots:", roots)


if __name__ == "__main__":
    utreexo = Utreexo()

    # Add some elements
    utreexo.add(0x111111111111111111111111)
    utreexo.add(0x222222222222222222222222)
    utreexo.add(0x333333333333333333333333)
    utreexo.add(0x444444444444444444444444)
    utreexo.add(0x555555555555555555555555)
    utreexo.add(0x666666666666666666666666)
    utreexo.add(0x777777777777777777777777)
    utreexo.add(0x888888888888888888888888)
    utreexo.add(0x999999999999999999999999)
    utreexo.add(0xAAAAAAAAAAAAAAAAAAAAAAAA)
    utreexo.print_roots()

    # Reset the Utreexo
    utreexo.reset()
    utreexo.print_roots()
