//! ByteArray extensions.

use core::hash::{Hash, HashStateTrait};

pub impl ByteArraySnapSerde of Serde<@ByteArray> {
    fn serialize(self: @@ByteArray, ref output: Array<felt252>) {
        (*self).serialize(ref output);
    }

    fn deserialize(ref serialized: Span<felt252>) -> Option<@ByteArray> {
        match Serde::deserialize(ref serialized) {
            Option::Some(res) => Option::Some(@res),
            Option::None => Option::None,
        }
    }
}

pub impl ByteArraySnapHash<S, +HashStateTrait<S>, +Drop<S>> of Hash<@ByteArray, S> {
    fn update_state(mut state: S, value: @ByteArray) -> S {
        let mut serialized_bytearray: Array<felt252> = array![];
        value.serialize(ref serialized_bytearray);

        for felt in serialized_bytearray {
            state = state.update(felt);
        };
        state
    }
}
