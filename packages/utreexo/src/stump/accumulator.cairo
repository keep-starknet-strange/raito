use crate::stump::state::UtreexoStumpState;
use crate::stump::proof::{UtreexoBatchProof, UtreexoBatchProofTrait};
use crate::parent_hash;

use utils::bit_shifts::{shr_u64};

#[generate_trait]
pub impl StumpUtreexoAccumulatorImpl of StumpUtreexoAccumulator {
    /// Adds multiple items to the accumulator.
    fn add(self: @UtreexoStumpState, hashes: Span<felt252>) -> UtreexoStumpState {
        let mut leaves = *self.num_leaves;

        // This array will hold state of roots after adding new hashes
        // IMPORTANT: This line copies all roots from the current state
        // to the new array
        let mut new_roots: Array<Option<felt252>> = (*self.roots).into();

        for add in hashes {
            // We will use new_roots_span to iterate over the roots that we
            // will merge (thus remove from the state) with the new hash.
            let mut new_roots_span = new_roots.span();
            let mut h = 0;
            let mut to_add = *add;

            // This is similar to the vanilla algorithm
            while shr_u64(leaves, h) % 2 == 1 {
                let root = new_roots_span.pop_back();

                // Checks that new_roots_span is not empty
                if let Option::Some(root) = root {
                    // Chechs that root has value
                    if let Option::Some(root) = root {
                        // Merging with the hash
                        to_add = parent_hash(*root, to_add);
                    }
                }
                h += 1;
            };

            new_roots = new_roots_span.into();
            new_roots.append(Option::Some(to_add));
            leaves += 1;
        };

        UtreexoStumpState { roots: new_roots.span(), num_leaves: leaves, }
    }

    /// Verifies that specified leaves are part of the utreexo forest given a proof.
    fn verify(
        self: @UtreexoStumpState, proof: @UtreexoBatchProof, leaves: Span<felt252>
    ) -> Result<(), ByteArray> {
        let mut computed_roots = proof.compute_roots(leaves, *self.num_leaves)?;
        let mut res = Result::Ok(());
        while let Option::Some(computed_root) = computed_roots.pop_front() {
            let mut root_exists = false;
            for root_opt in *self
                .roots {
                    if let Option::Some(root) = *root_opt {
                        if root == computed_root {
                            root_exists = true;
                            break;
                        }
                    }
                };
            if !root_exists {
                res = Result::Err("Proof verification failed");
                break;
            }
        };
        res
    }

    /// Verifies that the specified leaves are part of the utreexo forest given the proof,
    /// deletes them and returns an updated state.
    fn verify_and_delete(
        self: @UtreexoStumpState, proof: @UtreexoBatchProof, leaves: Span<felt252>
    ) -> Result<UtreexoStumpState, ByteArray> {
        let mut updated_roots = proof.compute_roots_with_deletion(leaves, *self.num_leaves)?;
        let mut roots = array![];

        for root_opt in *self
            .roots {
                if let Option::Some(root) = root_opt {
                    if let Option::Some(updated_root) = updated_roots.get(0) {
                        let (old_root, new_root) = updated_root.unbox();
                        if *root == *old_root {
                            updated_roots.pop_front().unwrap();
                            roots.append(*new_root);
                            continue;
                        }
                    }
                }
                roots.append(*root_opt);
            };

        if !updated_roots.is_empty() {
            return Result::Err("Proof verification failed");
        }

        Result::Ok(UtreexoStumpState { roots: roots.span(), num_leaves: *self.num_leaves })
    }

    /// Legacy implementation of proof verification.
    fn verify_legacy(
        self: @UtreexoStumpState, proof: @UtreexoBatchProof, del_hashes: Span<felt252>
    ) -> Result<(), ByteArray> {
        let computed_roots: Span<felt252> = proof
            .compute_roots_legacy(del_hashes, *self.num_leaves)?;
        let mut number_matched_roots: u32 = 0;

        for i in 0
            ..computed_roots
                .len() {
                    for root in *self
                        .roots {
                            match root {
                                Option::Some(root) => {
                                    if (computed_roots[i] == root) {
                                        number_matched_roots += 1;
                                    };
                                },
                                Option::None => {},
                            };
                        };
                };

        let computed_roots_len = computed_roots.len();

        if (computed_roots_len != number_matched_roots && computed_roots_len != 0) {
            return Result::Err("Proof verification failed");
        }

        Result::Ok(())
    }
}

#[cfg(test)]
mod tests {
    use super::{UtreexoStumpState, StumpUtreexoAccumulator, UtreexoBatchProof};

    #[test]
    fn test_verification_1_legacy() {
        let state = UtreexoStumpState {
            roots: array![
                Option::Some(0x371cb6995ea5e7effcd2e174de264b5b407027a75a231a70c2c8d196107f0e7)
            ]
                .span(),
            num_leaves: 2
        };
        let proof = UtreexoBatchProof { targets: array![0].span(), proof: array![2].span() };
        let del_hashes = array![1];

        let result = state.verify_legacy(@proof, del_hashes.span(),);
        assert_eq!(result, Result::Ok(()));
    }

    #[test]
    fn test_verification_2_legacy() {
        let state = UtreexoStumpState {
            roots: array![
                Option::Some(0x1702d734e291ad551b886a70b96446b99e19e405511e71fb5edfc4d2d83ce92),
                Option::Some(0x770ad1be69d195e821c8c35051b32492e71592e230b950a99ebf87e98967ca),
                Option::Some(0x2392042cbfda7371c81c9d7b456563533c2d6998b9e690a0d97421e6ae51a98),
                Option::Some(0xf),
            ]
                .span(),
            num_leaves: 15
        };
        let proof = UtreexoBatchProof {
            targets: array![1, 3, 10, 13].span(),
            proof: array![
                0x1,
                0x3,
                0xC,
                0xD,
                0x436e91732c0a83fa238d71460463f4b1fe0dc0b1ebcbc10967a84cec9d13154,
                0xdc9cc50aff0bdadd82a05bbab54015a07fccf2a4e30fa528fdca5a35d5423f
            ]
                .span()
        };
        let del_hashes = array![2, 4, 11, 14];

        let result = state.verify_legacy(@proof, del_hashes.span(),);
        assert_eq!(result, Result::Ok(()));
    }

    #[test]
    fn test_verification_3_legacy() {
        let state = UtreexoStumpState {
            roots: array![
                Option::Some(0x519631921e4905a63203f0cca7f6e6917082f30cef0930aa05bdc4323f6a398),
                Option::Some(0x5198dcd61c969dfa8396dd27439ab776d120c2d67294fbcded0aa5f658f9150),
                Option::Some(0x21d7ab8efac0146b5b47c8ad5431c3d14d9210319b0be7428fb2382ef115671),
                Option::Some(0x74f794e653e00357d8a8ed45fcb74659841190c0821aa4e20bc4e30b2f3dd20),
            ]
                .span(),
            num_leaves: 30
        };
        let proof = UtreexoBatchProof {
            targets: array![4, 8, 12, 16, 20, 24, 28].span(),
            proof: array![
                0x6,
                0xA,
                0xE,
                0x12,
                0x16,
                0x1A,
                0x1E,
                0x2797a40dbb8ea4b69a4e3bb4a9ccaa21a9585fcc71f3e5bb053ccae27910f90,
                0x7877cc14d4c8e76cc51aa4c49aa7aadaade0cf475ad63bb37c27c324e145393,
                0x556ea8bad1db13c6bdc3150a8289cd12044fb7e03cf201f35924a8afd4265a6,
                0x41a4ec75a27497daa51261588a60f0956d3fd61e521634bbf36bba6343c3a1b,
                0x3ba731d3734536d7cd5382cb4004ca4c24f1325b6fbeae27bcd6b4f9c0ed714,
                0x117ed04a65093683f13c16cf73d2855f1f099a96581d1dad74eaf34c9a343c8,
                0x79b32f615bbd57783700ae5f8e7b1ef79677c3545c4c69dc31b3aecce1d8fa6
            ]
                .span()
        };

        let del_hashes = array![5, 9, 13, 17, 21, 25, 29];

        let result = state.verify_legacy(@proof, del_hashes.span(),);
        assert_eq!(result, Result::Ok(()));
    }

    #[test]
    fn test_verification_1() {
        let state = UtreexoStumpState {
            roots: array![
                Option::Some(0x371cb6995ea5e7effcd2e174de264b5b407027a75a231a70c2c8d196107f0e7)
            ]
                .span(),
            num_leaves: 2
        };
        let proof = UtreexoBatchProof { targets: array![0].span(), proof: array![2].span() };
        let del_hashes = array![1];

        let result = state.verify(@proof, del_hashes.span(),);
        assert_eq!(result, Result::Ok(()));
    }

    #[test]
    fn test_verification_2() {
        let state = UtreexoStumpState {
            roots: array![
                Option::Some(0x1702d734e291ad551b886a70b96446b99e19e405511e71fb5edfc4d2d83ce92),
                Option::Some(0x770ad1be69d195e821c8c35051b32492e71592e230b950a99ebf87e98967ca),
                Option::Some(0x2392042cbfda7371c81c9d7b456563533c2d6998b9e690a0d97421e6ae51a98),
                Option::Some(0xf),
            ]
                .span(),
            num_leaves: 15
        };
        let proof = UtreexoBatchProof {
            targets: array![1, 3, 10, 13].span(),
            proof: array![
                0x1,
                0x3,
                0xC,
                0xD,
                0x436e91732c0a83fa238d71460463f4b1fe0dc0b1ebcbc10967a84cec9d13154,
                0xdc9cc50aff0bdadd82a05bbab54015a07fccf2a4e30fa528fdca5a35d5423f
            ]
                .span()
        };
        let del_hashes = array![2, 4, 11, 14];

        let result = state.verify(@proof, del_hashes.span(),);
        assert_eq!(result, Result::Ok(()));
    }

    #[test]
    fn test_verification_3() {
        let state = UtreexoStumpState {
            roots: array![
                Option::Some(0x519631921e4905a63203f0cca7f6e6917082f30cef0930aa05bdc4323f6a398),
                Option::Some(0x5198dcd61c969dfa8396dd27439ab776d120c2d67294fbcded0aa5f658f9150),
                Option::Some(0x21d7ab8efac0146b5b47c8ad5431c3d14d9210319b0be7428fb2382ef115671),
                Option::Some(0x74f794e653e00357d8a8ed45fcb74659841190c0821aa4e20bc4e30b2f3dd20),
            ]
                .span(),
            num_leaves: 30
        };
        let proof = UtreexoBatchProof {
            targets: array![4, 8, 12, 16, 20, 24, 28].span(),
            proof: array![
                0x6,
                0xA,
                0xE,
                0x12,
                0x16,
                0x1A,
                0x1E,
                0x2797a40dbb8ea4b69a4e3bb4a9ccaa21a9585fcc71f3e5bb053ccae27910f90,
                0x7877cc14d4c8e76cc51aa4c49aa7aadaade0cf475ad63bb37c27c324e145393,
                0x556ea8bad1db13c6bdc3150a8289cd12044fb7e03cf201f35924a8afd4265a6,
                0x41a4ec75a27497daa51261588a60f0956d3fd61e521634bbf36bba6343c3a1b,
                0x3ba731d3734536d7cd5382cb4004ca4c24f1325b6fbeae27bcd6b4f9c0ed714,
                0x117ed04a65093683f13c16cf73d2855f1f099a96581d1dad74eaf34c9a343c8,
                0x79b32f615bbd57783700ae5f8e7b1ef79677c3545c4c69dc31b3aecce1d8fa6
            ]
                .span()
        };

        let del_hashes = array![5, 9, 13, 17, 21, 25, 29];

        let result = state.verify(@proof, del_hashes.span(),);
        assert_eq!(result, Result::Ok(()));
    }

    #[test]
    fn test_verification_4() {
        let state = UtreexoStumpState {
            roots: array![
                Option::None,
                Option::None,
                Option::None,
                Option::None,
                Option::Some(
                    2778277074578782368986165095004756321440748237082580104984033528445453379385
                )
            ]
                .span(),
            num_leaves: 16
        };

        assert_eq!(
            state
                .verify(
                    @UtreexoBatchProof {
                        targets: array![0].span(),
                        proof: array![
                            1,
                            359114454570462701179676018441683730149326686283278794303413350979946254235,
                            2920447154653459698578961030005574439730780339384884329678783637696763668074,
                            361638375607381126502342109490869021742109399020176111227133094637834041180,
                        ]
                            .span()
                    },
                    array![0].span()
                ),
            Result::Ok(())
        );

        assert_eq!(
            state
                .verify(
                    @UtreexoBatchProof {
                        targets: array![15].span(),
                        proof: array![
                            14,
                            3009277733733429566191908933097273596911357184294896938062356457901603258437,
                            2224391216833402212724735773212940252356536072547264452695587483243907176367,
                            1010147253610699894986241683624609428739638206544914327400350896031110287324,
                        ]
                            .span()
                    },
                    array![15].span()
                ),
            Result::Ok(())
        );

        assert_eq!(
            state
                .verify(
                    @UtreexoBatchProof {
                        targets: array![0, 2, 5].span(),
                        proof: array![
                            1,
                            3,
                            4,
                            2476911194812244264213538976037850550079366744233323933541290896048104351430,
                            361638375607381126502342109490869021742109399020176111227133094637834041180,
                        ]
                            .span()
                    },
                    array![0, 2, 5].span()
                ),
            Result::Ok(())
        );

        assert_eq!(
            state
                .verify(
                    @UtreexoBatchProof {
                        targets: array![0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15]
                            .span(),
                        proof: array![].span()
                    },
                    array![0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15].span()
                ),
            Result::Ok(())
        );

        assert_eq!(
            state
                .verify(
                    @UtreexoBatchProof {
                        targets: array![16, 2, 5].span(),
                        proof: array![
                            3,
                            4,
                            2476911194812244264213538976037850550079366744233323933541290896048104351430,
                            361638375607381126502342109490869021742109399020176111227133094637834041180,
                        ]
                            .span()
                    },
                    array![
                        2808234728617536643410270558566096818021668177546200472079927509023409591575,
                        2,
                        5
                    ]
                        .span()
                ),
            Result::Ok(())
        );

        assert_eq!(
            state
                .verify(
                    @UtreexoBatchProof {
                        targets: array![24, 18, 10, 15].span(),
                        proof: array![
                            11,
                            14,
                            2476911194812244264213538976037850550079366744233323933541290896048104351430,
                            3115762988631556491925147498418117978906005591291390166955707455104569660364,
                            3009277733733429566191908933097273596911357184294896938062356457901603258437,
                        ]
                            .span()
                    },
                    array![
                        1229371501456391789924831928153470943555736434402105893904574254763197682709,
                        3613143053999770272842665473502706307602279676970981102529837756866990003067,
                        10,
                        15,
                    ]
                        .span()
                ),
            Result::Ok(())
        );

        assert_eq!(
            state
                .verify(
                    @UtreexoBatchProof {
                        targets: array![24, 29].span(),
                        proof: array![
                            2920447154653459698578961030005574439730780339384884329678783637696763668074,
                        ]
                            .span()
                    },
                    array![
                        1229371501456391789924831928153470943555736434402105893904574254763197682709,
                        361638375607381126502342109490869021742109399020176111227133094637834041180,
                    ]
                        .span()
                ),
            Result::Ok(())
        );

        assert_eq!(
            state
                .verify(
                    @UtreexoBatchProof { targets: array![28, 29].span(), proof: array![].span() },
                    array![
                        1010147253610699894986241683624609428739638206544914327400350896031110287324,
                        361638375607381126502342109490869021742109399020176111227133094637834041180,
                    ]
                        .span()
                ),
            Result::Ok(())
        );

        assert_eq!(
            state
                .verify(
                    @UtreexoBatchProof { targets: array![30].span(), proof: array![].span() },
                    array![
                        2778277074578782368986165095004756321440748237082580104984033528445453379385,
                    ]
                        .span()
                ),
            Result::Ok(())
        );
    }

    #[test]
    fn test_verification_5() {
        let state = UtreexoStumpState {
            roots: array![
                Option::Some(14),
                Option::Some(
                    3009277733733429566191908933097273596911357184294896938062356457901603258437
                ),
                Option::Some(
                    2224391216833402212724735773212940252356536072547264452695587483243907176367
                ),
                Option::Some(
                    1010147253610699894986241683624609428739638206544914327400350896031110287324
                )
            ]
                .span(),
            num_leaves: 15
        };

        assert_eq!(
            state
                .verify(
                    @UtreexoBatchProof {
                        targets: array![0].span(),
                        proof: array![
                            1,
                            359114454570462701179676018441683730149326686283278794303413350979946254235,
                            2920447154653459698578961030005574439730780339384884329678783637696763668074,
                        ]
                            .span()
                    },
                    array![0].span()
                ),
            Result::Ok(())
        );

        assert_eq!(
            state
                .verify(
                    @UtreexoBatchProof { targets: array![14].span(), proof: array![].span() },
                    array![14].span()
                ),
            Result::Ok(())
        );

        assert_eq!(
            state
                .verify(
                    @UtreexoBatchProof { targets: array![13].span(), proof: array![12].span() },
                    array![13].span()
                ),
            Result::Ok(())
        );

        assert_eq!(
            state
                .verify(
                    @UtreexoBatchProof {
                        targets: array![0, 2, 5, 14].span(),
                        proof: array![
                            1,
                            3,
                            4,
                            2476911194812244264213538976037850550079366744233323933541290896048104351430,
                        ]
                            .span()
                    },
                    array![0, 2, 5, 14].span()
                ),
            Result::Ok(())
        );

        assert_eq!(
            state
                .verify(
                    @UtreexoBatchProof {
                        targets: array![0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14].span(),
                        proof: array![].span()
                    },
                    array![0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14].span()
                ),
            Result::Ok(())
        );

        assert_eq!(
            state
                .verify(
                    @UtreexoBatchProof {
                        targets: array![16, 2, 5, 14].span(),
                        proof: array![
                            3,
                            4,
                            2476911194812244264213538976037850550079366744233323933541290896048104351430,
                        ]
                            .span()
                    },
                    array![
                        2808234728617536643410270558566096818021668177546200472079927509023409591575,
                        2,
                        5,
                        14
                    ]
                        .span()
                ),
            Result::Ok(())
        );

        assert_eq!(
            state
                .verify(
                    @UtreexoBatchProof { targets: array![24, 25].span(), proof: array![].span() },
                    array![
                        1229371501456391789924831928153470943555736434402105893904574254763197682709,
                        2920447154653459698578961030005574439730780339384884329678783637696763668074,
                    ]
                        .span()
                ),
            Result::Ok(())
        );

        assert_eq!(
            state
                .verify(
                    @UtreexoBatchProof {
                        targets: array![24, 26].span(),
                        proof: array![
                            2920447154653459698578961030005574439730780339384884329678783637696763668074
                        ]
                            .span()
                    },
                    array![
                        1229371501456391789924831928153470943555736434402105893904574254763197682709,
                        2224391216833402212724735773212940252356536072547264452695587483243907176367,
                    ]
                        .span()
                ),
            Result::Ok(())
        );

        assert_eq!(
            state
                .verify(
                    @UtreexoBatchProof { targets: array![28].span(), proof: array![].span() },
                    array![
                        1010147253610699894986241683624609428739638206544914327400350896031110287324,
                    ]
                        .span()
                ),
            Result::Ok(())
        );
    }

    #[test]
    fn test_deletion_1_1() {
        let state = UtreexoStumpState { roots: array![Option::Some('a')].span(), num_leaves: 1 };

        let proof = UtreexoBatchProof { targets: array![].span(), proof: array![].span() };

        let leaves = array![];

        let new_state = state
            .verify_and_delete(@proof, leaves.span())
            .expect('Verification failed');

        assert_eq!(new_state.num_leaves, 1);
        assert_eq!(new_state.roots, array![Option::Some('a')].span());
    }

    #[test]
    fn test_deletion_1_2() {
        let state = UtreexoStumpState { roots: array![Option::Some('a')].span(), num_leaves: 1 };

        let proof = UtreexoBatchProof { targets: array![0].span(), proof: array![].span() };

        let leaves = array!['a'];

        let new_state = state
            .verify_and_delete(@proof, leaves.span())
            .expect('Verification failed');

        assert_eq!(new_state.num_leaves, 1);
        assert_eq!(new_state.roots, array![Option::None].span());
    }

    #[test]
    fn test_deletion_8_1() {
        let state = UtreexoStumpState {
            roots: array![
                Option::None,
                Option::None,
                Option::None,
                Option::Some(
                    555370024363052154426534073187628105642230667669796211052131558433241164031
                )
            ]
                .span(),
            num_leaves: 8
        };

        let proof = UtreexoBatchProof {
            targets: array![0].span(),
            proof: array![
                'b',
                1702961261074558847535372708423978610134065667337563473891781271138689292959,
                1970675917964935639615849678644334216784892342767290630432190461589093258001
            ]
                .span()
        };

        let leaves = array!['a'];

        let new_state = state
            .verify_and_delete(@proof, leaves.span())
            .expect('Verification failed');

        assert_eq!(new_state.num_leaves, 8);
        assert_eq!(
            new_state.roots,
            array![
                Option::None,
                Option::None,
                Option::None,
                Option::Some(
                    3345421944025286217980549018138297349958141750618054570424649972274280624201
                ),
            ]
                .span()
        );
    }

    #[test]
    fn test_deletion_8_2() {
        let state = UtreexoStumpState {
            roots: array![
                Option::None,
                Option::None,
                Option::None,
                Option::Some(
                    555370024363052154426534073187628105642230667669796211052131558433241164031
                )
            ]
                .span(),
            num_leaves: 8
        };

        let proof = UtreexoBatchProof {
            targets: array![0, 1].span(),
            proof: array![
                1702961261074558847535372708423978610134065667337563473891781271138689292959,
                1970675917964935639615849678644334216784892342767290630432190461589093258001
            ]
                .span()
        };

        let leaves = array!['a', 'b'];

        let new_state = state
            .verify_and_delete(@proof, leaves.span())
            .expect('Verification failed');

        assert_eq!(new_state.num_leaves, 8);
        assert_eq!(
            new_state.roots,
            array![
                Option::None,
                Option::None,
                Option::None,
                Option::Some(
                    2850064462912342803614938379907776937447719434508740518644801944855647065404
                ),
            ]
                .span()
        );
    }

    #[test]
    fn test_deletion_8_3() {
        let state = UtreexoStumpState {
            roots: array![
                Option::None,
                Option::None,
                Option::None,
                Option::Some(
                    555370024363052154426534073187628105642230667669796211052131558433241164031
                )
            ]
                .span(),
            num_leaves: 8
        };

        let proof = UtreexoBatchProof {
            targets: array![0, 1, 2].span(),
            proof: array![
                'd', 1970675917964935639615849678644334216784892342767290630432190461589093258001
            ]
                .span()
        };

        let leaves = array!['a', 'b', 'c'];

        let new_state = state
            .verify_and_delete(@proof, leaves.span())
            .expect('Verification failed');

        assert_eq!(new_state.num_leaves, 8);
        assert_eq!(
            new_state.roots,
            array![
                Option::None,
                Option::None,
                Option::None,
                Option::Some(
                    3021045430882547327596950725247172779074256595054900316875788021760349090257
                ),
            ]
                .span()
        );
    }

    #[test]
    fn test_deletion_8_4() {
        let state = UtreexoStumpState {
            roots: array![
                Option::None,
                Option::None,
                Option::None,
                Option::Some(
                    555370024363052154426534073187628105642230667669796211052131558433241164031
                )
            ]
                .span(),
            num_leaves: 8
        };

        let proof = UtreexoBatchProof {
            targets: array![0, 1, 2, 3, 4, 5, 6].span(), proof: array!['h'].span()
        };

        let leaves = array!['a', 'b', 'c', 'd', 'e', 'f', 'g'];

        let new_state = state
            .verify_and_delete(@proof, leaves.span())
            .expect('Verification failed');

        assert_eq!(new_state.num_leaves, 8);
        assert_eq!(
            new_state.roots,
            array![Option::None, Option::None, Option::None, Option::Some('h')].span()
        );
    }

    #[test]
    fn test_deletion_8_5() {
        let state = UtreexoStumpState {
            roots: array![
                Option::None,
                Option::None,
                Option::None,
                Option::Some(
                    555370024363052154426534073187628105642230667669796211052131558433241164031
                )
            ]
                .span(),
            num_leaves: 8
        };

        let proof = UtreexoBatchProof {
            targets: array![0, 1, 2, 3, 4, 5, 6, 7].span(), proof: array![].span()
        };

        let leaves = array!['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h'];

        let new_state = state
            .verify_and_delete(@proof, leaves.span())
            .expect('Verification failed');

        assert_eq!(new_state.num_leaves, 8);
        assert_eq!(
            new_state.roots, array![Option::None, Option::None, Option::None, Option::None].span()
        );
    }

    #[test]
    fn test_deletion_7_1() {
        let state = UtreexoStumpState {
            roots: array![
                Option::Some(103),
                Option::Some(
                    411226027934254579827031836427260754155547814753354544773152242745331653508
                ),
                Option::Some(
                    2858081605429646247202638041541950020464262679066089136848920825648707910133
                )
            ]
                .span(),
            num_leaves: 7
        };

        let proof = UtreexoBatchProof {
            targets: array![0].span(),
            proof: array![
                'b', 1702961261074558847535372708423978610134065667337563473891781271138689292959
            ]
                .span()
        };

        let leaves = array!['a'];

        let new_state = state
            .verify_and_delete(@proof, leaves.span())
            .expect('Verification failed');

        assert_eq!(new_state.num_leaves, 7);
        assert_eq!(
            new_state.roots,
            array![
                Option::Some('g'),
                Option::Some(
                    411226027934254579827031836427260754155547814753354544773152242745331653508
                ),
                Option::Some(
                    1229642933490472299984329107953625663040621781839429280809499005981139964854
                )
            ]
                .span()
        );
    }

    #[test]
    fn test_deletion_7_2() {
        let state = UtreexoStumpState {
            roots: array![
                Option::Some(103),
                Option::Some(
                    411226027934254579827031836427260754155547814753354544773152242745331653508
                ),
                Option::Some(
                    2858081605429646247202638041541950020464262679066089136848920825648707910133
                )
            ]
                .span(),
            num_leaves: 7
        };

        let proof = UtreexoBatchProof {
            targets: array![0, 2, 4, 6].span(), proof: array!['b', 'd', 'f'].span()
        };

        let leaves = array!['a', 'c', 'e', 'g'];

        let new_state = state
            .verify_and_delete(@proof, leaves.span())
            .expect('Verification failed');

        assert_eq!(new_state.num_leaves, 7);
        assert_eq!(
            new_state.roots,
            array![
                Option::None,
                Option::Some('f'),
                Option::Some(
                    1012329657042087226062405582801477394059887655150284803644932492275110107160
                )
            ]
                .span()
        );
    }

    #[test]
    fn test_deletion_7_3() {
        let state = UtreexoStumpState {
            roots: array![
                Option::Some(103),
                Option::Some(
                    411226027934254579827031836427260754155547814753354544773152242745331653508
                ),
                Option::Some(
                    2858081605429646247202638041541950020464262679066089136848920825648707910133
                )
            ]
                .span(),
            num_leaves: 7
        };

        let proof = UtreexoBatchProof {
            targets: array![1, 3, 5].span(), proof: array!['a', 'c', 'e'].span()
        };

        let leaves = array!['b', 'd', 'f'];

        let new_state = state
            .verify_and_delete(@proof, leaves.span())
            .expect('Verification failed');

        assert_eq!(new_state.num_leaves, 7);
        assert_eq!(
            new_state.roots,
            array![
                Option::Some('g'),
                Option::Some('e'),
                Option::Some(
                    1442415957443312626722273931205158047965396421097404482753913691074484308909
                )
            ]
                .span()
        );
    }

    #[test]
    fn test_deletion_7_4() {
        let state = UtreexoStumpState {
            roots: array![
                Option::Some(103),
                Option::Some(
                    411226027934254579827031836427260754155547814753354544773152242745331653508
                ),
                Option::Some(
                    2858081605429646247202638041541950020464262679066089136848920825648707910133
                )
            ]
                .span(),
            num_leaves: 7
        };

        let proof = UtreexoBatchProof {
            targets: array![0, 6].span(),
            proof: array![
                'b', 1702961261074558847535372708423978610134065667337563473891781271138689292959
            ]
                .span()
        };

        let leaves = array!['a', 'g'];

        let new_state = state
            .verify_and_delete(@proof, leaves.span())
            .expect('Verification failed');

        assert_eq!(new_state.num_leaves, 7);
        assert_eq!(
            new_state.roots,
            array![
                Option::None,
                Option::Some(
                    411226027934254579827031836427260754155547814753354544773152242745331653508
                ),
                Option::Some(
                    1229642933490472299984329107953625663040621781839429280809499005981139964854
                )
            ]
                .span()
        );
    }

    #[test]
    fn test_deletion_7_5() {
        let state = UtreexoStumpState {
            roots: array![
                Option::Some(103),
                Option::Some(
                    411226027934254579827031836427260754155547814753354544773152242745331653508
                ),
                Option::Some(
                    2858081605429646247202638041541950020464262679066089136848920825648707910133
                )
            ]
                .span(),
            num_leaves: 7
        };

        let proof = UtreexoBatchProof { targets: array![4, 5, 6].span(), proof: array![].span() };

        let leaves = array!['e', 'f', 'g'];

        let new_state = state
            .verify_and_delete(@proof, leaves.span())
            .expect('Verification failed');

        assert_eq!(new_state.num_leaves, 7);
        assert_eq!(
            new_state.roots,
            array![
                Option::None,
                Option::None,
                Option::Some(
                    2858081605429646247202638041541950020464262679066089136848920825648707910133
                )
            ]
                .span()
        );
    }

    #[test]
    fn test_deletion_7_6() {
        let state = UtreexoStumpState {
            roots: array![
                Option::Some(103),
                Option::Some(
                    411226027934254579827031836427260754155547814753354544773152242745331653508
                ),
                Option::Some(
                    2858081605429646247202638041541950020464262679066089136848920825648707910133
                )
            ]
                .span(),
            num_leaves: 7
        };

        let proof = UtreexoBatchProof {
            targets: array![0, 1, 2, 3, 4, 5, 6].span(), proof: array![].span()
        };

        let leaves = array!['a', 'b', 'c', 'd', 'e', 'f', 'g'];

        let new_state = state
            .verify_and_delete(@proof, leaves.span())
            .expect('Verification failed');

        assert_eq!(new_state.num_leaves, 7);
        assert_eq!(new_state.roots, array![Option::None, Option::None, Option::None].span());
    }

    #[test]
    fn test_deletion_7_7() {
        let state = UtreexoStumpState {
            roots: array![
                Option::Some(103),
                Option::Some(
                    411226027934254579827031836427260754155547814753354544773152242745331653508
                ),
                Option::Some(
                    2858081605429646247202638041541950020464262679066089136848920825648707910133
                )
            ]
                .span(),
            num_leaves: 7
        };

        // Remove 0

        let proof = UtreexoBatchProof {
            targets: array![0].span(),
            proof: array![
                'b', 1702961261074558847535372708423978610134065667337563473891781271138689292959
            ]
                .span()
        };

        let leaves = array!['a'];

        let new_state = state
            .verify_and_delete(@proof, leaves.span())
            .expect('Verification 0 failed');

        // Remove 1

        let proof = UtreexoBatchProof {
            targets: array![8].span(),
            proof: array![
                1702961261074558847535372708423978610134065667337563473891781271138689292959
            ]
                .span()
        };

        let leaves = array!['b'];

        let new_state = new_state
            .verify_and_delete(@proof, leaves.span())
            .expect('Verification 1 failed');

        // Remove 2

        let proof = UtreexoBatchProof { targets: array![8].span(), proof: array!['d'].span() };

        let leaves = array!['c'];

        let new_state = new_state
            .verify_and_delete(@proof, leaves.span())
            .expect('Verification 2 failed');

        // Remove 3

        let proof = UtreexoBatchProof { targets: array![12].span(), proof: array![].span() };

        let leaves = array!['d'];

        let new_state = new_state
            .verify_and_delete(@proof, leaves.span())
            .expect('Verification 3 failed');

        // Remove 4

        let proof = UtreexoBatchProof { targets: array![4].span(), proof: array!['f'].span() };

        let leaves = array!['e'];

        let new_state = new_state
            .verify_and_delete(@proof, leaves.span())
            .expect('Verification 4 failed');

        // Remove 5

        let proof = UtreexoBatchProof { targets: array![10].span(), proof: array![].span() };

        let leaves = array!['f'];

        let new_state = new_state
            .verify_and_delete(@proof, leaves.span())
            .expect('Verification 5 failed');

        // Remove 6

        let proof = UtreexoBatchProof { targets: array![6].span(), proof: array![].span() };

        let leaves = array!['g'];

        let new_state = new_state
            .verify_and_delete(@proof, leaves.span())
            .expect('Verification 6 failed');

        assert_eq!(new_state.num_leaves, 7);
        assert_eq!(new_state.roots, array![Option::None, Option::None, Option::None].span());
    }
}
