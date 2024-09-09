use crate::utils::hash::Digest;
use core::dict::Felt252Dict;
use core::nullable::NullableImpl;

#[derive(Copy, Drop, Debug)]
pub enum Frame {
    BlockHeight: u32,
    Transaction: u32,
    TxIn: (Digest, u32),
    TxOut: u32,
    Message: @ByteArray,
}

pub struct TraceContext {
    frames: Felt252Dict<Nullable<Frame>>,
    len: u32,
    trace: Array<ByteArray>,
}

impl DestructTraceContext of Destruct<TraceContext> {
    fn destruct(self: TraceContext) nopanic {
        self.frames.squash();
    }
}

#[generate_trait]
pub impl TraceContextImpl of TraceContextTrait {
    fn new() -> TraceContext {
        TraceContext { frames: Default::default(), len: 0, trace: array![] }
    }

    fn push(ref self: TraceContext, frame: Frame) {
        self.frames.insert(self.len.into(), NullableImpl::new(frame));
        self.len += 1;
    }

    fn pop(ref self: TraceContext) {
        assert!(self.len > 0, "pop from empty context!");
        self.len -= 1;
    }

    fn with_context(ref self: TraceContext, error: ByteArray) -> ByteArray {
        let mut r: ByteArray = Default::default();
        for f in 0
            ..self.len - 1 {
                r.append(@format!("{:?}/", self.frames.get(f.into()).deref()));
            };
        r.append(@": ");
        r.append(@error);
        return r;
    }

    fn err_with_context<T>(ref self: TraceContext, error: ByteArray) -> Result<T, ByteArray> {
        Result::Err(self.with_context(error))
    }

    fn trace(ref self: TraceContext, message: ByteArray) {
        self.trace.append(message);
    }
}

