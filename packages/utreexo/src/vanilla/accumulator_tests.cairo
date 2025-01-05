use super::accumulator::VanillaUtreexoAccumulator;
use super::proof::UtreexoProof;
use super::state::UtreexoState;

/// Tests the basic functionality of the Utreexo accumulator.
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
    let proof = UtreexoProof { leaf_index: 0, proof: array![].span() };
    let result = utxo_state.verify(leaf1, @proof);
    assert!(result.is_ok(), "Root at index 0 should be 0x111111111111111111111111");

    // Add the second leaf (0x222222222222222222222222)
    let leaf2 = 0x222222222222222222222222;

    utxo_state =
        UtreexoState {
            roots: array![
                Option::None,
                Option::Some(0x181a554869978703143b97d281460c38e30fe6ba52eb0a03641e446beb0f610),
            ]
                .into(),
        };

    let proof = UtreexoProof { leaf_index: 1, proof: array![0x111111111111111111111111].span() };
    let result = utxo_state.verify(leaf2, @proof);
    assert!(
        result.is_ok(),
        "Root at index 1 should be 0x181a554869978703143b97d281460c38e30fe6ba52eb0a03641e446beb0f610",
    );

    // Add the third leaf (0x333333333333333333333333)
    let leaf3 = 0x333333333333333333333333;
    utxo_state =
        UtreexoState {
            roots: array![
                Option::Some(leaf3),
                Option::Some(0x181a554869978703143b97d281460c38e30fe6ba52eb0a03641e446beb0f610),
            ]
                .into(),
        };

    let proof = UtreexoProof { leaf_index: 1, proof: array![0x111111111111111111111111].span() };
    let result = utxo_state.verify(leaf2, @proof);
    assert!(
        result.is_ok(),
        "Root at index 1 should be 0x181a554869978703143b97d281460c38e30fe6ba52eb0a03641e446beb0f610",
    );

    // Add the fourth leaf (0x444444444444444444444444)

    let leaf4 = 0x444444444444444444444444;

    utxo_state =
        UtreexoState {
            roots: array![
                Option::None,
                Option::None,
                Option::Some(0x73f11135a8f669c50ec8257ea06c9e231c140db996458f698b2be1f771a318f),
            ]
                .into(),
        };

    // Create the UtreexoProof for leaf 1
    let proof = UtreexoProof {
        leaf_index: 0,
        proof: array![
            0x222222222222222222222222,
            0x3f2d79e3abddc2b8ac61fba19928ef4882b1c784bff13c633513dd49818384c,
        ]
            .span(),
    };
    // Call the verify function
    let result = utxo_state.verify(leaf1, @proof);
    assert!(result.is_ok(), "verify leaf index 0 failed");
    // Create the UtreexoProof for leaf 2
    let proof = UtreexoProof {
        leaf_index: 1,
        proof: array![leaf1, 0x3f2d79e3abddc2b8ac61fba19928ef4882b1c784bff13c633513dd49818384c]
            .span(),
    };
    // Call the verify function
    let result = utxo_state.verify(leaf2, @proof);
    assert!(result.is_ok(), "verify leaf index 1 failed");

    // Create the UtreexoProof for leaf 3
    let proof = UtreexoProof {
        leaf_index: 2,
        proof: array![leaf4, 0x181a554869978703143b97d281460c38e30fe6ba52eb0a03641e446beb0f610]
            .span(),
    };
    // Call the verify function
    let result = utxo_state.verify(leaf3, @proof);
    assert!(result.is_ok(), "verify leaf index 2 failed");

    // Create the UtreexoProof for leaf 4
    let proof = UtreexoProof {
        leaf_index: 3,
        proof: array![leaf3, 0x181a554869978703143b97d281460c38e30fe6ba52eb0a03641e446beb0f610]
            .span(),
    };
    // Call the verify function
    let result = utxo_state.verify(leaf4, @proof);
    assert!(result.is_ok(), "verify leaf index 3 failed");

    // Create the UtreexoProof for leaf 4
    let proof = UtreexoProof {
        leaf_index: 3,
        proof: array![leaf2, 0x181a554869978703143b97d281460c38e30fe6ba52eb0a03641e446beb0f610]
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

    // Add first leave to empty utreexo
    utreexo_state = utreexo_state.add(outpoint);

    let expected: Span<Option<felt252>> = array![
        Option::Some(0x291F8F5FC449D42C715B529E542F24A80136D18F4A85DE28829CD3DCAAC1B9C),
        Option::None,
    ]
        .span();
    assert_eq!(utreexo_state.roots, expected, "cannot add first leave");

    // Add second leave
    utreexo_state = utreexo_state.add(outpoint);

    let expected: Span<Option<felt252>> = array![
        Option::None,
        Option::Some(0x6b255e34b8c22a48b7821a867bea0a697d6a0820a6f827482cf0c25cfc08338),
        Option::None,
    ]
        .span();
    assert_eq!(utreexo_state.roots, expected, "cannot add second leave");

    // Add thirdth leave
    utreexo_state = utreexo_state.add(outpoint);

    let expected: Span<Option<felt252>> = array![
        Option::Some(0x291f8f5fc449d42c715b529e542f24a80136d18f4a85de28829cd3dcaac1b9c),
        Option::Some(0x6b255e34b8c22a48b7821a867bea0a697d6a0820a6f827482cf0c25cfc08338),
        Option::None,
    ]
        .span();
    assert_eq!(utreexo_state.roots, expected, "cannot add thirdth leave");

    // Add fourth leave
    utreexo_state = utreexo_state.add(outpoint);

    let expected: Span<Option<felt252>> = array![
        Option::None,
        Option::None,
        Option::Some(0x3b3ed120874d97b712f68895b658659ee8055a82ea5bef26fa210fa956754c7),
        Option::None,
    ]
        .span();
    assert_eq!(utreexo_state.roots, expected, "cannot add fourth leave");

    // Add fifth leave
    utreexo_state = utreexo_state.add(outpoint);

    let expected: Span<Option<felt252>> = array![
        Option::Some(0x291F8F5FC449D42C715B529E542F24A80136D18F4A85DE28829CD3DCAAC1B9C),
        Option::None,
        Option::Some(0x3b3ed120874d97b712f68895b658659ee8055a82ea5bef26fa210fa956754c7),
        Option::None,
    ]
        .span();
    assert_eq!(utreexo_state.roots, expected, "cannot add fifth leave");

    // Add 3 leaves
    for _ in 1..4_u8 {
        utreexo_state = utreexo_state.add(outpoint);
    };

    let expected: Span<Option<felt252>> = array![
        Option::None,
        Option::None,
        Option::None,
        Option::Some(0x7c9dbc3d6eba8cb43284ce97423a48d660612c0834baad3c2f8b423530a5619),
        Option::None,
    ]
        .span();
    assert_eq!(utreexo_state.roots, expected, "cannot add 3 leaves");

    // Add 22 leaves
    for _ in 1..23_u8 {
        utreexo_state = utreexo_state.add(outpoint);
    };

    let expected: Span<Option<felt252>> = [
        Option::None(()),
        Option::Some(0x6b255e34b8c22a48b7821a867bea0a697d6a0820a6f827482cf0c25cfc08338),
        Option::Some(0x3b3ed120874d97b712f68895b658659ee8055a82ea5bef26fa210fa956754c7),
        Option::Some(0x7c9dbc3d6eba8cb43284ce97423a48d660612c0834baad3c2f8b423530a5619),
        Option::Some(0x54d5e7a4e449e914bed7a4acd2dc7660125e1e69dc4e887bbbfba58b3643e98),
        Option::None(()),
    ]
        .span();
    assert_eq!(utreexo_state.roots, expected, "cannot add 22 leaves");
}

#[test]
fn test_utreexo_delete() {
    // Test data is generated using scripts/data/utreexo.py

    let mut utreexo_state: UtreexoState = Default::default();

    // Adds 16 leaves to empty utreexo
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
        Option::Some(0x1818a64c0ecbcb9fec43227f7b137c9567b936cabbc378711c52c2bb5b4b53a),
        Option::None,
    ]
        .span();
    assert_eq!(utreexo_state.roots, expected, "cannot add second leave");

    let proof_for_3rd_leaf: UtreexoProof = UtreexoProof {
        leaf_index: 2,
        proof: array![
            0x444444444444444444444444,
            0x181a554869978703143b97d281460c38e30fe6ba52eb0a03641e446beb0f610,
            0x1f35ec8aaadbda4f4f28d098ad0d073f8acbba791a8ef10d6b798c5b6150ebe,
            0x600961c4f15bc633f584abbd7f10c77a053552ef53baebfedc689c223c2a314,
        ]
            .span(),
    };

    // Deletes the 3rd leaf
    utreexo_state = utreexo_state.delete(@proof_for_3rd_leaf);

    let expected: Span<Option<felt252>> = array![
        Option::Some(0x444444444444444444444444),
        Option::Some(0x181a554869978703143b97d281460c38e30fe6ba52eb0a03641e446beb0f610),
        Option::Some(0x1f35ec8aaadbda4f4f28d098ad0d073f8acbba791a8ef10d6b798c5b6150ebe),
        Option::Some(0x600961c4f15bc633f584abbd7f10c77a053552ef53baebfedc689c223c2a314),
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

    // Adds 7 leaves to empty utreexo
    utreexo_state = utreexo_state
        .add(0x111111111111111111111111)
        .add(0x222222222222222222222222)
        .add(0x333333333333333333333333)
        .add(0x444444444444444444444444)
        .add(0x555555555555555555555555)
        .add(0x666666666666666666666666)
        .add(0x777777777777777777777777);

    let expected: Span<Option<felt252>> = array![
        Option::Some(0x777777777777777777777777),
        Option::Some(0x4e94ad0a594972f27a4a9b0ce1d32a9d5994d4a109932c44ce1359818bd6c08),
        Option::Some(0x73f11135a8f669c50ec8257ea06c9e231c140db996458f698b2be1f771a318f),
        Option::None,
    ]
        .span();
    assert_eq!(utreexo_state.roots, expected, "cannot add second leave");

    let proof: UtreexoProof = UtreexoProof { leaf_index: 6, proof: array![].span() };

    // Deletes the last added leaf which corresponds to the root at h=0
    utreexo_state = utreexo_state.delete(@proof);

    let expected: Span<Option<felt252>> = array![
        Option::None,
        Option::Some(0x4e94ad0a594972f27a4a9b0ce1d32a9d5994d4a109932c44ce1359818bd6c08),
        Option::Some(0x73f11135a8f669c50ec8257ea06c9e231c140db996458f698b2be1f771a318f),
        Option::None,
    ]
        .span();

    assert_eq!(utreexo_state.roots, expected, "cannot remove leave");
}
