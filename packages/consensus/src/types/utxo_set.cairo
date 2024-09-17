//! Unspent transaction output set contains outputs from the previous blocks
//! that can be referenced in the transaction inputs.
//!
//! UTXO set is very large hence it is infeasible to pass it entirely as a program input.
//! Instead we provide only a subset of outputs that are:
//!   - going to be spent in the validated blocks
//!   - created in the previous blocks (i.e. are not spent in the same block)
//!
//! In order to prove that the UTXOs provided actually belong to the set we use either
//! Utreexo accumulator or local cache.

//input contain outpoint contain output
use core::dict::Felt252Dict;
use core::hash::{HashStateTrait, HashStateExTrait};
use core::poseidon::PoseidonTrait;
use super::transaction::OutPoint;
use super::utreexo::{UtreexoState, UtreexoAccumulator};

#[derive(Default, Destruct)]
pub struct UtxoSet {
    /// Utreexo state.
    pub utreexo_state: UtreexoState,
    /// Hashes of UTXOs created within the current block(s).
    /// Note that to preserve the ordering, cache has to be updated right after a
    /// particular output is created or spent.
    pub cache: Felt252Dict<bool>,
}

#[generate_trait]
pub impl UtxoSetImpl of UtxoSetTrait {
    fn new(utreexo_state: UtreexoState) -> UtxoSet {
        UtxoSet { utreexo_state, ..Default::default() }
    }

    fn add(ref self: UtxoSet, output: OutPoint) {
        let outpoint_hash = PoseidonTrait::new().update_with(output).finalize();
        if output.data.cached {
            self.cache.insert(outpoint_hash, true);
        } else {
            self.utreexo_state.add(outpoint_hash);
        }
    }

    // coexistant ?
    fn leaves_to_add(ref self: UtxoSet, leaves_hash: Array<felt252>) {
        for leave in leaves_hash {
            self.utreexo_state.add(leave);
        }
    }

    fn delete(ref self: UtxoSet, output: @OutPoint) {
        if *output.data.cached {
            let outpoint_hash = PoseidonTrait::new().update_with(*output).finalize();
            // Extra check that can be removed later.
            assert(self.cache.get(outpoint_hash), 'output is not cached');
            self.cache.insert(outpoint_hash, false);
        } else { // TODO: update utreexo roots (+ verify inclusion)
        // If batched proofs are used then do nothing.
        }
    }
}

#[cfg(test)]
mod tests {
    use super::{UtxoSet, UtxoSetTrait, OutPoint};
    use consensus::types::transaction::TxOut;

    use core::hash::{HashStateTrait, HashStateExTrait};
    use core::poseidon::PoseidonTrait;

    #[test]
    /// To check the validity of expected fields, there is a python program from ZeroSync
    /// https://github.com/ZeroSync/ZeroSync/blob/main/src/utxo_set/bridge_node.py
    /// $ python scripts/data/utreexo.py
    fn test_utreexo_add1() {
        let mut utxo_set: UtxoSet = UtxoSetTrait::new(Default::default());

        // https://learnmeabitcoin.com/explorer/tx/b1fea52486ce0c62bb442b530a3f0132b826c74e473d1f2c220bfa78111c5082#input-0
        // coinbase outpoint
        let outpoint1 = OutPoint {
            txid: 0x0000000000000000000000000000000000000000000000000000000000000000_u256.into(),
            vout: 4294967295,
            data: TxOut { value: 0, pk_script: @"0x", cached: false },
            block_height: 0,
            block_time: 0,
            is_coinbase: false
        };
        let outpoint1: felt252 = PoseidonTrait::new().update_with(outpoint1).finalize();

        // add first leave to empty utreexo
        utxo_set.leaves_to_add(array![outpoint1]);
        let expected: Span<Option<felt252>> = array![
            Option::Some(0x291F8F5FC449D42C715B529E542F24A80136D18F4A85DE28829CD3DCAAC1B9C),
            Option::None
        ]
            .span();
        assert_eq!(utxo_set.utreexo_state.roots, expected, "cannot add first leave");
        assert_eq!(utxo_set.utreexo_state.num_leaves, 1);

        // add second leave
        utxo_set.leaves_to_add(array![outpoint1]);
        let expected: Span<Option<felt252>> = array![
            Option::None,
            Option::Some(0x738A7C495E564574993BBCB6A62D65C3C570BB81C63801066AF8934649F66F6),
            Option::None
        ]
            .span();
        assert_eq!(utxo_set.utreexo_state.roots, expected, "cannot add second leave");
        assert_eq!(utxo_set.utreexo_state.num_leaves, 2);

        // add thirdth leave
        utxo_set.leaves_to_add(array![outpoint1]);
        let expected: Span<Option<felt252>> = array![
            Option::Some(0x291F8F5FC449D42C715B529E542F24A80136D18F4A85DE28829CD3DCAAC1B9C),
            Option::Some(0x738A7C495E564574993BBCB6A62D65C3C570BB81C63801066AF8934649F66F6),
            Option::None
        ]
            .span();
        assert_eq!(utxo_set.utreexo_state.roots, expected, "cannot add thirdth leave");
        assert_eq!(utxo_set.utreexo_state.num_leaves, 3);

        // add fourth leave
        utxo_set.leaves_to_add(array![outpoint1]);
        let expected: Span<Option<felt252>> = array![
            Option::None,
            Option::None,
            Option::Some(0x25D0DE35DD446E3D35504866FD7A04D4245E01B5908E19EAA70ABA84DD5A1F1),
            Option::None
        ]
            .span();
        assert_eq!(utxo_set.utreexo_state.roots, expected, "cannot add fourth leave");
        assert_eq!(utxo_set.utreexo_state.num_leaves, 4);

        // add fifth leave
        utxo_set.leaves_to_add(array![outpoint1]);
        let expected: Span<Option<felt252>> = array![
            Option::Some(0x291F8F5FC449D42C715B529E542F24A80136D18F4A85DE28829CD3DCAAC1B9C),
            Option::None,
            Option::Some(0x25D0DE35DD446E3D35504866FD7A04D4245E01B5908E19EAA70ABA84DD5A1F1),
            Option::None
        ]
            .span();
        assert_eq!(utxo_set.utreexo_state.roots, expected, "cannot add fifth leave");
        assert_eq!(utxo_set.utreexo_state.num_leaves, 5);

        // add 3 leaves
        utxo_set.leaves_to_add(array![outpoint1, outpoint1, outpoint1]);
        let expected: Span<Option<felt252>> = array![
            Option::None,
            Option::None,
            Option::None,
            Option::Some(0x708EB39E30B035376EC871F8F17CD3BADAE6A68406B13C3BB671009D56F5AD),
            Option::None
        ]
            .span();
        assert_eq!(utxo_set.utreexo_state.roots, expected, "cannot add 3 leaves");
        assert_eq!(utxo_set.utreexo_state.num_leaves, 8);

        // add 22 leaves
        utxo_set
            .leaves_to_add(
                array![
                    outpoint1,
                    outpoint1,
                    outpoint1,
                    outpoint1,
                    outpoint1,
                    outpoint1,
                    outpoint1,
                    outpoint1,
                    outpoint1,
                    outpoint1,
                    outpoint1,
                    outpoint1,
                    outpoint1,
                    outpoint1,
                    outpoint1,
                    outpoint1,
                    outpoint1,
                    outpoint1,
                    outpoint1,
                    outpoint1,
                    outpoint1,
                    outpoint1
                ]
            );
        let expected: Span<Option<felt252>> = [
            Option::None(()),
            Option::Some(0x738A7C495E564574993BBCB6A62D65C3C570BB81C63801066AF8934649F66F6),
            Option::Some(0x25D0DE35DD446E3D35504866FD7A04D4245E01B5908E19EAA70ABA84DD5A1F1),
            Option::Some(0x708EB39E30B035376EC871F8F17CD3BADAE6A68406B13C3BB671009D56F5AD),
            Option::Some(0x58D6BEF6CFC28638FB4C8271355961F50922BCC1577DD2B6D04E11B7A911702),
            Option::None(())
        ].span();
        assert_eq!(utxo_set.utreexo_state.roots, expected, "cannot add 22 leaves");
        assert_eq!(utxo_set.utreexo_state.num_leaves, 30);
    }
    ///
/// python scripts/data/utreexo.py
///
/// Roots:
/// ['0x0291f8f5fc449d42c715b529e542f24a80136d18f4a85de28829cd3dcaac1b9c', '', '', '', '', '',
/// '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '']
///
/// Roots:
/// ['', '0x0738a7c495e564574993bbcb6a62d65c3c570bb81c63801066af8934649f66f6', '', '', '', '',
/// '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '']
///
/// Roots: ['0x0291f8f5fc449d42c715b529e542f24a80136d18f4a85de28829cd3dcaac1b9c',
/// '0x0738a7c495e564574993bbcb6a62d65c3c570bb81c63801066af8934649f66f6', '', '', '', '', '',
/// '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '']
///
/// Roots: ['', '', '0x025d0de35dd446e3d35504866fd7a04d4245e01b5908e19eaa70aba84dd5a1f1', '',
/// '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '']
///
/// Roots: ['0x0291f8f5fc449d42c715b529e542f24a80136d18f4a85de28829cd3dcaac1b9c', '',
/// '0x025d0de35dd446e3d35504866fd7a04d4245e01b5908e19eaa70aba84dd5a1f1', '', '', '', '', '',
/// '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '']
///
/// Roots: ['', '', '', '0x00708eb39e30b035376ec871f8f17cd3badae6a68406b13c3bb671009d56f5ad',
/// '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '']
///
/// Roots: ['', '0x0738a7c495e564574993bbcb6a62d65c3c570bb81c63801066af8934649f66f6',
/// '0x025d0de35dd446e3d35504866fd7a04d4245e01b5908e19eaa70aba84dd5a1f1',
/// '0x00708eb39e30b035376ec871f8f17cd3badae6a68406b13c3bb671009d56f5ad',
/// '0x058d6bef6cfc28638fb4c8271355961f50922bcc1577dd2b6d04e11b7a911702', '', '', '', '', '',
/// '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '']
}
