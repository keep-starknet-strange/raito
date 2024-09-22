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

#[cfg(test)]
mod tests{
    #[test]
    fn test_log_level_debug() {
        log!("DEBUG", "log! works")
    }

    #[test]
    fn test_log_level_trace() {
        log!("DEBUG", "log! works")
    }
}