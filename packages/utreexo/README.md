# Utreexo accumulator in Cairo

Utreexo is a dynamic hash-based accumulator designed to be used as a set membership proof system and it is used in the Bitcoin network to compress the UTXO set.  

Comes in two flavors:
- **Vanilla** implementation of the accumulator described in the [paper](https://eprint.iacr.org/2019/611.pdf)
- **Stump** – compatible with [rustreexo](https://github.com/mit-dci/rustreexo) adopted in Utreexod and Floresta Bitcoin nodes