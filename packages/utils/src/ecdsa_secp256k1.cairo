use garaga::definitions::{G1Point, u384, get_n};
use garaga::ec_ops::{msm_g1, MSMHint, DerivePointFromXHint};
use garaga::basic_field_ops::{inv_mod_p, mul_mod_p};

const SECP256K1_CURVE_ID: usize = 2;
const SECP256K1_GENERATOR: G1Point =
    G1Point {
        x: u384 {
            limb0: 0x2dce28d959f2815b16f81798,
            limb1: 0x55a06295ce870b07029bfcdb,
            limb2: 0x79be667ef9dcbbac,
            limb3: 0x0
        },
        y: u384 {
            limb0: 0xa68554199c47d08ffb10d4b8,
            limb1: 0x5da4fbfc0e1108a8fd17b448,
            limb2: 0x483ada7726a3c465,
            limb3: 0x0
        }
    };
const SECP256K1_ORDER: u384 =
    u384 {
        limb0: 0xaf48a03bbfd25e8cd0364141,
        limb1: 0xfffffffffffffffebaaedce6,
        limb2: 0xffffffffffffffff,
        limb3: 0x0
    };

#[derive(Serde)]
struct PartialHint {
    scalars_digits_decompositions: Option<Span<(Span<felt252>, Span<felt252>)>>,
    msm_hint: MSMHint,
    derive_point_from_x_hint: DerivePointFromXHint,
}

// To create the hint_serialized that can be deserialized into PartialHint,
// use the msm calldata builder of garaga.
// Rust (import from github):
// https://github.com/keep-starknet-strange/garaga/blob/66abfdc0c825f60f96b3b83cb89ef7d1e9ff8f91/tools/garaga_rs/src/msm.rs#L25-L33
// Python (pypi garaga) :
// https://github.com/keep-starknet-strange/garaga/blob/66abfdc0c825f60f96b3b83cb89ef7d1e9ff8f91/hydra/garaga/starknet/tests_and_calldata_generators/msm.py#L379
// Typescript (npm garaga) :
// https://github.com/keep-starknet-strange/garaga/blob/66abfdc0c825f60f96b3b83cb89ef7d1e9ff8f91/tools/npm/garaga_ts/src/node/api.ts#L22
// with the options :
// -include_scalars_digits_decomposition = true,
// -include_points_and_scalars = false,
// -serialize_as_pure_felt252_array = false
// -risc0_mode = false.

// As input to rust or typescript function, or at initialization of the python class,
// provide the same points (SECP256K1_GENERATOR, public_key), scalars (u1, u2) and curve_id
// as in the signature verification.
pub fn is_valid_secp256k1_ecdsa_signature(
    msg_hash: u256, r: u256, s: u256, public_key: G1Point, mut hint_serialized: Span<felt252>
) -> bool {
    let _s_384: u384 = s.into();
    let s_inv = inv_mod_p(_s_384, SECP256K1_ORDER);
    let u1: u256 = mul_mod_p(msg_hash.into(), s_inv, SECP256K1_ORDER).try_into().unwrap();
    let u2: u256 = mul_mod_p(r.into(), s_inv, SECP256K1_ORDER).try_into().unwrap();

    let hint = Serde::<PartialHint>::deserialize(ref hint_serialized).unwrap();

    let sum: G1Point = msm_g1(
        scalars_digits_decompositions: hint.scalars_digits_decompositions,
        hint: hint.msm_hint,
        derive_point_from_x_hint: hint.derive_point_from_x_hint,
        points: array![SECP256K1_GENERATOR, public_key].span(),
        scalars: array![u1, u2].span(),
        curve_index: SECP256K1_CURVE_ID
    );

    return sum.x == r.into();
}
