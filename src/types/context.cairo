use crate::utils::hash::Digest;

#[derive(Copy, Drop, Debug)]
pub enum Frame {
    BlockHeight: u32,
    Transaction: u32,
    TxIn: (Digest, u32),
    TxOut: u32,
    Message: @ByteArray,
}

pub trait TraceContextTrait<C> {
    fn new() -> C;
    fn push(ref self: C, frame: Frame);

    fn pop(ref self: C);
    fn err_with_context<T>(ref self: C, error: ByteArray) -> Result<T, ByteArray>;
    fn trace(ref self: C, message: ByteArray);
}


#[cfg(feature: 'trace_context')]
mod trace_context_impl {
    use core::dict::Felt252Dict;
    use core::nullable::NullableImpl;
    use super::{Frame, TraceContextTrait};

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

    pub impl TraceContextImpl of TraceContextTrait<TraceContext> {
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

        fn err_with_context<T>(ref self: TraceContext, error: ByteArray) -> Result<T, ByteArray> {
            Result::Err(with_context(ref self, error))
        }

        fn trace(ref self: TraceContext, message: ByteArray) {
            self.trace.append(with_context(ref self, message));
        }
    }
}

#[cfg(feature: 'without_trace_context')]
mod trace_context_impl {
    use super::{Frame, TraceContextTrait};

    #[derive(Copy, Drop)]
    pub struct TraceContext {}

    pub impl TraceContextImpl of TraceContextTrait<TraceContext> {
        fn new() -> TraceContext {
            TraceContext {}
        }

        fn push(ref self: TraceContext, frame: Frame) {}

        fn pop(ref self: TraceContext) {}

        fn err_with_context<T>(ref self: TraceContext, error: ByteArray) -> Result<T, ByteArray> {
            Result::Err(error)
        }

        fn trace(ref self: TraceContext, message: ByteArray) {}
    }
}


#[cfg(feature: "trace_context")]
pub use trace_context_impl::TraceContext;
#[cfg(feature: "trace_context")]
pub use trace_context_impl::TraceContextImpl;

#[cfg(feature: "without_trace_context")]
pub use trace_context_impl::TraceContext;
#[cfg(feature: "without_trace_context")]
pub use trace_context_impl::TraceContextImpl;
