#[cfg(feature: 'log_level_trace')]
mod log_levels {
    pub const LOG_LEVEL_TRACE: bool = true;
    pub const LOG_LEVEL_DEBUG: bool = true;
}

#[cfg(feature: 'log_level_debug')]
mod log_levels {
    pub const LOG_LEVEL_TRACE: bool = false;
    pub const LOG_LEVEL_DEBUG: bool = true;
}

#[cfg(feature: 'log_level_none')]
mod log_levels {
    pub const LOG_LEVEL_TRACE: bool = false;
    pub const LOG_LEVEL_DEBUG: bool = false;
}

pub use log_levels::LOG_LEVEL_TRACE;
pub use log_levels::LOG_LEVEL_DEBUG;

pub const ABC: bool = false;