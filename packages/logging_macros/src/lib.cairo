#[cfg(feature: 'log_level_trace')]
pub const LOG_LEVEL_TRACE: bool = true;

#[cfg(feature: 'log_level_trace')]
pub const LOG_LEVEL_DEBUG: bool = true;

#[cfg(feature: 'log_level_debug')]
pub const LOG_LEVEL_TRACE: bool = false;

#[cfg(feature: 'log_level_debug')]
pub const LOG_LEVEL_DEBUG: bool = true;

#[cfg(feature: 'log_level_none')]
pub const LOG_LEVEL_TRACE: bool = false;

#[cfg(feature: 'log_level_none')]
pub const LOG_LEVEL_DEBUG: bool = false;