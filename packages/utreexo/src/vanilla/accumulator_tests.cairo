use super::accumulator::VanillaUtreexoAccumulator;
use super::proof::UtreexoProof;
use super::state::UtreexoState;

/// Test the basic functionality of the Utreexo accumulator
///
/// This test covers the following scenarios:
/// 1. Adding a single leaf and verifying it
/// 2. Adding a second leaf and verifying both leaves
/// 3. Adding a third leaf and verifying previous leaves
/// 4. Adding a fourth leaf and verifying all leaves
///
/// For each scenario, the test:
/// - Initializes the UtreexoState with the appropriate roots and number of leaves
/// - Creates an OutPoint representing the leaf
/// - Constructs a UtreexoProof for the leaf
/// - Calls the verify function and asserts that it succeeds
///
/// The test uses predefined txid values (0x111111..., 0x222222..., etc.) for simplicity.
/// It checks the correct root values at each stage of the Utreexo tree's growth.
#[test]
fn test_verify_inclusion() {
    // Add the first leaf (0x111111111111111111111111)
    let leaf1 = 0x111111111111111111111111;

    let mut utxo_state = UtreexoState {
        roots: array![Option::Some(0x111111111111111111111111)].into(),
    };
    let proof = UtreexoProof { leaf_index: 0, proof: array![].span(), };
    let result = utxo_state.verify(leaf1, @proof);
    assert!(result.is_ok(), "Root at index 0 should be 0x111111111111111111111111");

    // Add the second leaf (0x222222222222222222222222)
    let leaf2 = 0x222222222222222222222222;

    utxo_state =
        UtreexoState {
            roots: array![
                Option::None,
                Option::Some(0x05fb342b44641ae6d67310cf9da5566e1a398fd6b0121d40e2c5acd16e1ddb4a)
            ]
                .into(),
        };

    let proof = UtreexoProof { leaf_index: 1, proof: array![0x111111111111111111111111].span(), };
    let result = utxo_state.verify(leaf2, @proof);
    assert!(
        result.is_ok(),
        "Root at index 1 should be 0x05fb342b44641ae6d67310cf9da5566e1a398fd6b0121d40e2c5acd16e1ddb4a"
    );

    // Add the third leaf (0x333333333333333333333333)
    let leaf3 = 0x333333333333333333333333;
    utxo_state =
        UtreexoState {
            roots: array![
                Option::Some(leaf3),
                Option::Some(0x05fb342b44641ae6d67310cf9da5566e1a398fd6b0121d40e2c5acd16e1ddb4a)
            ]
                .into(),
        };

    let proof = UtreexoProof { leaf_index: 1, proof: array![0x111111111111111111111111].span(), };
    let result = utxo_state.verify(leaf2, @proof);
    assert!(
        result.is_ok(),
        "Root at index 1 should be 0x05fb342b44641ae6d67310cf9da5566e1a398fd6b0121d40e2c5acd16e1ddb4a"
    );

    // Add the fourth leaf (0x444444444444444444444444)

    let leaf4 = 0x444444444444444444444444;

    utxo_state =
        UtreexoState {
            roots: array![
                Option::None,
                Option::None,
                Option::Some(0x018674e0c40577cb5ba4728d6ac7bedfd9548f4020161223261941b2a8ae84b2)
            ]
                .into(),
        };

    // Create the UtreexoProof for leaf 1
    let proof = UtreexoProof {
        leaf_index: 0,
        proof: array![
            0x222222222222222222222222,
            0x02a6b2ae998d30e1ac356c32b2750c3126cd6b3ecf02e6918a93021d17b2b026
        ]
            .span(),
    };
    // Call the verify function
    let result = utxo_state.verify(leaf1, @proof);
    assert!(result.is_ok(), "verify leaf index 0 failed");
    // Create the UtreexoProof for leaf 2
    let proof = UtreexoProof {
        leaf_index: 1,
        proof: array![leaf1, 0x02a6b2ae998d30e1ac356c32b2750c3126cd6b3ecf02e6918a93021d17b2b026]
            .span(),
    };
    // Call the verify function
    let result = utxo_state.verify(leaf2, @proof);
    assert!(result.is_ok(), "verify leaf index 1 failed");

    // Create the UtreexoProof for leaf 3
    let proof = UtreexoProof {
        leaf_index: 2,
        proof: array![leaf4, 0x05fb342b44641ae6d67310cf9da5566e1a398fd6b0121d40e2c5acd16e1ddb4a]
            .span(),
    };
    // Call the verify function
    let result = utxo_state.verify(leaf3, @proof);
    assert!(result.is_ok(), "verify leaf index 2 failed");

    // Create the UtreexoProof for leaf 4
    let proof = UtreexoProof {
        leaf_index: 3,
        proof: array![leaf3, 0x05fb342b44641ae6d67310cf9da5566e1a398fd6b0121d40e2c5acd16e1ddb4a]
            .span(),
    };
    // Call the verify function
    let result = utxo_state.verify(leaf4, @proof);
    assert!(result.is_ok(), "verify leaf index 3 failed");

    // Create the UtreexoProof for leaf 4
    let proof = UtreexoProof {
        leaf_index: 3,
        proof: array![leaf2, 0x05fb342b44641ae6d67310cf9da5566e1a398fd6b0121d40e2c5acd16e1ddb4a]
            .span(),
    };
    // Call the verify function
    let result = utxo_state.verify(leaf4, @proof);
    assert!(result.is_err(), "verify leaf index 3 should fail");
}

#[test]
fn test_utreexo_add() {
    // Test data is generated using scripts/data/utreexo.py

    let mut utreexo_state: UtreexoState = Default::default();
    let outpoint: felt252 = 0x291F8F5FC449D42C715B529E542F24A80136D18F4A85DE28829CD3DCAAC1B9C;

    // add first leave to empty utreexo
    utreexo_state = utreexo_state.add(outpoint);

    let expected: Span<Option<felt252>> = array![
        Option::Some(0x291F8F5FC449D42C715B529E542F24A80136D18F4A85DE28829CD3DCAAC1B9C),
        Option::None
    ]
        .span();
    assert_eq!(utreexo_state.roots, expected, "cannot add first leave");

    // add second leave
    utreexo_state = utreexo_state.add(outpoint);

    let expected: Span<Option<felt252>> = array![
        Option::None,
        Option::Some(0x738A7C495E564574993BBCB6A62D65C3C570BB81C63801066AF8934649F66F6),
        Option::None
    ]
        .span();
    assert_eq!(utreexo_state.roots, expected, "cannot add second leave");

    // add thirdth leave
    utreexo_state = utreexo_state.add(outpoint);

    let expected: Span<Option<felt252>> = array![
        Option::Some(0x291F8F5FC449D42C715B529E542F24A80136D18F4A85DE28829CD3DCAAC1B9C),
        Option::Some(0x738A7C495E564574993BBCB6A62D65C3C570BB81C63801066AF8934649F66F6),
        Option::None
    ]
        .span();
    assert_eq!(utreexo_state.roots, expected, "cannot add thirdth leave");

    // add fourth leave
    utreexo_state = utreexo_state.add(outpoint);

    let expected: Span<Option<felt252>> = array![
        Option::None,
        Option::None,
        Option::Some(0x25D0DE35DD446E3D35504866FD7A04D4245E01B5908E19EAA70ABA84DD5A1F1),
        Option::None
    ]
        .span();
    assert_eq!(utreexo_state.roots, expected, "cannot add fourth leave");

    // add fifth leave
    utreexo_state = utreexo_state.add(outpoint);

    let expected: Span<Option<felt252>> = array![
        Option::Some(0x291F8F5FC449D42C715B529E542F24A80136D18F4A85DE28829CD3DCAAC1B9C),
        Option::None,
        Option::Some(0x25D0DE35DD446E3D35504866FD7A04D4245E01B5908E19EAA70ABA84DD5A1F1),
        Option::None
    ]
        .span();
    assert_eq!(utreexo_state.roots, expected, "cannot add fifth leave");

    // add 3 leaves
    for _ in 1..4_u8 {
        utreexo_state = utreexo_state.add(outpoint);
    };

    let expected: Span<Option<felt252>> = array![
        Option::None,
        Option::None,
        Option::None,
        Option::Some(0x708EB39E30B035376EC871F8F17CD3BADAE6A68406B13C3BB671009D56F5AD),
        Option::None
    ]
        .span();
    assert_eq!(utreexo_state.roots, expected, "cannot add 3 leaves");

    // add 22 leaves
    for _ in 1..23_u8 {
        utreexo_state = utreexo_state.add(outpoint);
    };

    let expected: Span<Option<felt252>> = [
        Option::None(()),
        Option::Some(0x738A7C495E564574993BBCB6A62D65C3C570BB81C63801066AF8934649F66F6),
        Option::Some(0x25D0DE35DD446E3D35504866FD7A04D4245E01B5908E19EAA70ABA84DD5A1F1),
        Option::Some(0x708EB39E30B035376EC871F8F17CD3BADAE6A68406B13C3BB671009D56F5AD),
        Option::Some(0x58D6BEF6CFC28638FB4C8271355961F50922BCC1577DD2B6D04E11B7A911702),
        Option::None(())
    ].span();
    assert_eq!(utreexo_state.roots, expected, "cannot add 22 leaves");
}

#[test]
fn test_utreexo_delete() {
    // Test data is generated using scripts/data/utreexo.py

    let mut utreexo_state: UtreexoState = Default::default();

    // adds 16 leaves to empty utreexo
    utreexo_state = utreexo_state
        .add(0x111111111111111111111111)
        .add(0x222222222222222222222222)
        .add(0x333333333333333333333333)
        .add(0x444444444444444444444444)
        .add(0x555555555555555555555555)
        .add(0x666666666666666666666666)
        .add(0x777777777777777777777777)
        .add(0x888888888888888888888888)
        .add(0x999999999999999999999999)
        .add(0xAAAAAAAAAAAAAAAAAAAAAAAA)
        .add(0xBBBBBBBBBBBBBBBBBBBBBBBB)
        .add(0xCCCCCCCCCCCCCCCCCCCCCCCC)
        .add(0xEEEEEEEEEEEEEEEEEEEEEEEE)
        .add(0xFFFFFFFFFFFFFFFFFFFFFFFF)
        .add(0xFFFFFFFFFFFFFFFFFFFFFFF0)
        .add(0xFFFFFFFFFFFFFFFFFFFFFFF1);

    let expected: Span<Option<felt252>> = array![
        Option::None,
        Option::None,
        Option::None,
        Option::None,
        Option::Some(0x03467aa210cc0b108229d9a7fc554f9175af4ee27ee08b128b96862f7beca2ea),
        Option::None,
    ]
        .span();
    assert_eq!(utreexo_state.roots, expected, "cannot add second leave");

    let proof_for_3rd_leaf: UtreexoProof = UtreexoProof {
        leaf_index: 2,
        proof: array![
            0x0000000000000000000000000000000000000000444444444444444444444444,
            0x05fb342b44641ae6d67310cf9da5566e1a398fd6b0121d40e2c5acd16e1ddb4a,
            0x01670d29719eae8deaa34a1d75752368d180a2c3e53f08d344ad784f1a034be7,
            0x04448e395061d8b58524c81978a17837c66c7f3286ea3c1773c7fafd77d29f69
        ]
            .span()
    };

    // deletes the 3rd leaf
    utreexo_state = utreexo_state.delete(@proof_for_3rd_leaf);

    let expected: Span<Option<felt252>> = array![
        Option::Some(0x0000000000000000000000000000000000000000444444444444444444444444),
        Option::Some(0x05fb342b44641ae6d67310cf9da5566e1a398fd6b0121d40e2c5acd16e1ddb4a),
        Option::Some(0x01670d29719eae8deaa34a1d75752368d180a2c3e53f08d344ad784f1a034be7),
        Option::Some(0x04448e395061d8b58524c81978a17837c66c7f3286ea3c1773c7fafd77d29f69),
        Option::None,
        Option::None,
    ]
        .span();

    assert_eq!(utreexo_state.roots, expected, "cannot remove leave");
}

#[test]
fn test_utreexo_delete_2() {
    // Test data is generated using scripts/data/utreexo.py

    let mut utreexo_state: UtreexoState = Default::default();

    // adds 7 leaves to empty utreexo
    utreexo_state = utreexo_state
        .add(0x111111111111111111111111)
        .add(0x222222222222222222222222)
        .add(0x333333333333333333333333)
        .add(0x444444444444444444444444)
        .add(0x555555555555555555555555)
        .add(0x666666666666666666666666)
        .add(0x777777777777777777777777);

    let expected: Span<Option<felt252>> = array![
        Option::Some(0x0000000000000000000000000000000000000000777777777777777777777777),
        Option::Some(0x0358bb901cdc1d0d68afdb06dfeb84f2472c254ea052a942d8640924386935a6),
        Option::Some(0x018674e0c40577cb5ba4728d6ac7bedfd9548f4020161223261941b2a8ae84b2),
        Option::None,
    ]
        .span();
    assert_eq!(utreexo_state.roots, expected, "cannot add second leave");

    let proof: UtreexoProof = UtreexoProof { leaf_index: 6, proof: array![].span() };

    // deletes the last added leaf which corresponds to the root at h=0
    utreexo_state = utreexo_state.delete(@proof);

    let expected: Span<Option<felt252>> = array![
        Option::None,
        Option::Some(0x0358bb901cdc1d0d68afdb06dfeb84f2472c254ea052a942d8640924386935a6),
        Option::Some(0x018674e0c40577cb5ba4728d6ac7bedfd9548f4020161223261941b2a8ae84b2),
        Option::None,
    ]
        .span();

    assert_eq!(utreexo_state.roots, expected, "cannot remove leave");
}
