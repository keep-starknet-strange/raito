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

#[cfg(test)]
mod tests {
    #[test]
    fn test_log_level_debug() {
        log!("DEBUG", "log! works");
    }

    #[test]
    fn test_log_level_trace() {
        log!("DEBUG", "log! works");
    }
}
