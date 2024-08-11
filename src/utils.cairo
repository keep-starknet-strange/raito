use core::num::traits::{Zero, One, BitSize};
use starknet::{SyscallResult, SyscallResultTrait};

/// A handle to the state of a SHA-256 hash.
#[derive(Copy, Drop)]
pub(crate) extern type Sha256StateHandle;

/// Initializes a new SHA-256 state handle.
extern fn sha256_state_handle_init(state: Box<[u32; 8]>) -> Sha256StateHandle nopanic;

/// returns the state of a SHA-256 hash.
extern fn sha256_state_handle_digest(state: Sha256StateHandle) -> Box<[u32; 8]> nopanic;

const SHA256_INITIAL_STATE: [
    u32
    ; 8] = [
    0x6a09e667, 0xbb67ae85, 0x3c6ef372, 0xa54ff53a, 0x510e527f, 0x9b05688c, 0x1f83d9ab, 0x5be0cd19,
];

pub fn shl<
    T,
    U,
    +Zero<T>,
    +Zero<U>,
    +One<T>,
    +One<U>,
    +Add<T>,
    +Add<U>,
    +Sub<U>,
    +Mul<T>,
    +Div<U>,
    +Rem<U>,
    +Copy<T>,
    +Copy<U>,
    +Drop<T>,
    +Drop<U>,
    +PartialOrd<U>,
    +PartialEq<U>,
    +BitSize<T>,
    +Into<usize, U>
>(
    self: T, shift: U,
) -> T {
    if shift > BitSize::<T>::bits().into() - One::one() {
        return Zero::zero();
    }
    let two = One::one() + One::one();
    self * fast_pow(two, shift)
}

pub fn shr<
    T,
    U,
    +Zero<T>,
    +Zero<U>,
    +One<T>,
    +One<U>,
    +Add<T>,
    +Add<U>,
    +Sub<U>,
    +Div<T>,
    +Mul<T>,
    +Div<U>,
    +Rem<U>,
    +Copy<T>,
    +Copy<U>,
    +Drop<T>,
    +Drop<U>,
    +PartialOrd<U>,
    +PartialEq<U>,
    +BitSize<T>,
    +Into<usize, U>
>(
    self: T, shift: U
) -> T {
    if shift > BitSize::<T>::bits().try_into().unwrap() - One::one() {
        return Zero::zero();
    }

    let two = One::one() + One::one();
    self / fast_pow(two, shift)
}


// Fast exponentiation using the square-and-multiply algorithm
// Reference:
// https://github.com/keep-starknet-strange/alexandria/blob/bcdca70afdf59c9976148e95cebad5cf63d75a7f/packages/math/src/fast_power.cairo#L12
pub fn fast_pow<
    T,
    U,
    +Zero<T>,
    +Zero<U>,
    +One<T>,
    +One<U>,
    +Add<U>,
    +Mul<T>,
    +Rem<U>,
    +Div<U>,
    +Copy<T>,
    +Copy<U>,
    +Drop<T>,
    +Drop<U>,
    +PartialEq<U>,
>(
    base: T, exp: U
) -> T {
    if exp == Zero::zero() {
        return One::one();
    }

    let mut res: T = One::one();
    let mut base: T = base;
    let mut exp: U = exp;

    let two: U = One::one() + One::one();

    loop {
        if exp % two == One::one() {
            res = res * base;
        }
        exp = exp / two;
        if exp == Zero::zero() {
            break res;
        }
        base = base * base;
    }
}

pub extern fn sha256_process_block_syscall(
    state: Sha256StateHandle, input: Box<[u32; 16]>
) -> SyscallResult<Sha256StateHandle> implicits(GasBuiltin, System) nopanic;

pub fn double_sha256(inputs: Box<[u32; 16]>) -> [u32; 8] {
    //stage 1
    let mut state1 = sha256_state_handle_init(BoxTrait::new(SHA256_INITIAL_STATE));
    state1 = sha256_process_block_syscall(state1, inputs).unwrap_syscall();
    let input_padding: Box<[u32; 16]> = BoxTrait::new(
        [0x80000000, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x200]
    );
    state1 = sha256_process_block_syscall(state1, input_padding).unwrap_syscall();
    let output1: [u32; 8] = sha256_state_handle_digest(state1).unbox();

    //stage 2
    let mut state2 = sha256_state_handle_init(BoxTrait::new(SHA256_INITIAL_STATE));
    let [i0, i1, i2, i3, i4, i5, i6, i7] = output1;
    let temp: Box<[u32; 16]> = BoxTrait::new(
        [i0, i1, i2, i3, i4, i5, i6, i7, 0x80000000, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x100],
    );
    state2 = sha256_process_block_syscall(state2, temp).unwrap_syscall();

    sha256_state_handle_digest(state2).unbox()
}
