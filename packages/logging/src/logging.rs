use cairo_lang_macro::{inline_macro, Diagnostic, ProcMacroResult, TokenStream};
use cairo_lang_parser::utils::SimpleParserDatabase;
use cairo_lang_syntax::node::kind::SyntaxKind;

#[inline_macro]
pub fn log(token_stream: TokenStream) -> ProcMacroResult {
    let db = SimpleParserDatabase::default();
    let (parsed, _diag) = db.parse_virtual_with_diagnostics(token_stream);

    let mut args = parsed
        .descendants(&db)
        .filter(|node| matches!(node.kind(&db), SyntaxKind::Arg));

    // Extract log level
    let level = match args.next() {
        Some(node) => node.get_text(&db),
        _ => return create_error_result("Invalid log level"),
    };

    // Validate log level
    if !["\"TRACE\"", "\"DEBUG\""].contains(&level.as_str()) {
        return create_error_result("Invalid log level. Use TRACE or DEBUG");
    }

    // Extract format string
    let format_string = match args.next() {
        Some(node) => node.get_text(&db),
        _ => return create_error_result("Invalid format string"),
    };

    // Extract remaining arguments
    let log_args: Vec<String> = args
        .map(|node| {
            if matches!(node.kind(&db), SyntaxKind::Arg) {
                Ok(node.get_text(&db))
            } else {
                Err(())
            }
        })
        .collect::<Result<Vec<String>, ()>>()
        .unwrap_or_else(|_| {
            create_error_result("Invalid log argument");
            Vec::new()
        });

    // Generate the log statement
    let log_statement = generate_log_statement(&level, &format_string, &log_args);

    println!("Log statement: {}", log_statement);
    ProcMacroResult::new(TokenStream::new(log_statement))
}

fn create_error_result(message: &str) -> ProcMacroResult {
    ProcMacroResult::new(TokenStream::empty()).with_diagnostics(Diagnostic::error(message).into())
}

fn generate_log_statement(level: &str, format_string: &str, log_args: &[String]) -> String {
    let level_str = level.trim_matches('"');
    let condition = match level_str {
        "TRACE" => "LOG_LEVEL_TRACE",
        "DEBUG" => "LOG_LEVEL_DEBUG",
        _ => unreachable!(),
    };
    let level_str = format!("{}", level);
    let print_statement = if log_args.is_empty() {
        format!(
            "println!(\"{{}}: {{}}\", format!({}), format!({}))",
            level_str, format_string
        )
    } else {
        format!(
            "println!(\"{{}}: {{}}\", format!({}), format!({}, {}))",
            level_str,
            format_string,
            log_args.join(", ")
        )
    };

    format!("if crate::logging::{} {{ {} }}", condition, print_statement)
}
mod tests {
    use super::*;
    use cairo_lang_macro::TokenStream;

    // Helper function to expand macros
    #[allow(unused)]
    fn expand_macro(macro_fn: fn(TokenStream) -> ProcMacroResult, input: &str) -> String {
        let token_stream = TokenStream::new(input.to_string());
        let result = macro_fn(token_stream);
        result.token_stream.to_string()
    }

    #[test]
    fn test_log_macro_debug() {
        let expanded = expand_macro(
            log_02lvnd9pht92k,
            r#"log!("DEBUG", "test message: {}", '123')"#,
        );
        assert_eq!(
            expanded,
            r#"if crate::logging::LOG_LEVEL_DEBUG { println!("{}: {}", format!("DEBUG"), format!("test message: {}", '123')) }"#
        );
    }

    #[test]
    fn test_log_macro_trace() {
        let expanded = expand_macro(log_02lvnd9pht92k, r#"log!("TRACE", "entering function")"#);
        assert_eq!(
            expanded,
            r#"if crate::logging::LOG_LEVEL_TRACE { println!("{}: {}", format!("TRACE"), format!("entering function")) }"#
        );
    }

    #[test]
    fn test_log_macro_invalid_level() {
        let expanded = expand_macro(log_02lvnd9pht92k, r#"log!("INFO", "test message")"#);
        assert_eq!(expanded, ""); // Empty TokenStream for error case
    }

    #[test]
    fn test_log_macro_empty_format() {
        let expanded = expand_macro(log_02lvnd9pht92k, r#"log!("DEBUG", '')"#);
        assert_eq!(
            expanded,
            r#"if crate::logging::LOG_LEVEL_DEBUG { println!("{}: {}", format!("DEBUG"), format!('')) }"#
        );
    }

    #[test]
    fn test_log_macro_multiple_arguments() {
        let expanded = expand_macro(
            log_02lvnd9pht92k,
            r#"log!("DEBUG", "Values: {}, {}, {}", '1', '2', '3')"#,
        );
        assert_eq!(
            expanded,
            r#"if crate::logging::LOG_LEVEL_DEBUG { println!("{}: {}", format!("DEBUG"), format!("Values: {}, {}, {}", '1', '2', '3')) }"#
        );
    }

    #[test]
    fn test_log_macro_exact_string() {
        let expanded = expand_macro(
            log_02lvnd9pht92k,
            r#"log!("DEBUG", "Exact {} string", 'test')"#,
        );
        assert_eq!(
            expanded,
            r#"if crate::logging::LOG_LEVEL_DEBUG { println!("{}: {}", format!("DEBUG"), format!("Exact {} string", 'test')) }"#
        );
    }
}
