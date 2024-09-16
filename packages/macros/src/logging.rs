use bigdecimal::{num_traits::pow, BigDecimal};
use cairo_lang_macro::{inline_macro, Diagnostic, ProcMacroResult, TokenStream};
use cairo_lang_parser::utils::SimpleParserDatabase;
use cairo_lang_syntax::node::{self, kind::SyntaxKind};

/// Compile-time power function.
///
/// Takes two arguments, `x, y`, calculates the value of `x` raised to the power of `y`.
///
/// ```
/// const MEGABYTE: u64 = pow!(2, 20);
/// assert_eq!(MEGABYTE, 1048576);
/// ```



#[inline_macro]
pub fn pow(token_stream: TokenStream) -> ProcMacroResult {
    let db = SimpleParserDatabase::default();
    let (parsed, _diag) = db.parse_virtual_with_diagnostics(token_stream);

    let macro_args: Vec<String> = parsed
        .descendants(&db)
        .filter_map(|node| {
            if let SyntaxKind::Arg = node.kind(&db) {
                Some(node.get_text(&db))
            } else {
                None
            }
        })
        .collect();

    if macro_args.len() != 2 {
        return ProcMacroResult::new(TokenStream::empty())
            .with_diagnostics(Diagnostic::error("Invalid number of arguments").into());
    }

    let base: BigDecimal = match macro_args[0].parse() {
        Ok(val) => val,
        Err(_) => {
            return ProcMacroResult::new(TokenStream::empty())
                .with_diagnostics(Diagnostic::error("Invalid base value").into());
        }
    };

    let exp: usize = match macro_args[1].parse() {
        Ok(val) => val,
        Err(_) => {
            return ProcMacroResult::new(TokenStream::empty())
                .with_diagnostics(Diagnostic::error("Invalid exponent value").into());
        }
    };

    let result: BigDecimal = pow(base, exp);

    ProcMacroResult::new(TokenStream::new(result.to_string()))
}
#[inline_macro]
pub fn log(token_stream: TokenStream) -> ProcMacroResult {
    let db = SimpleParserDatabase::default();
    let (parsed, _diag) = db.parse_virtual_with_diagnostics(token_stream);

    let mut args = parsed.descendants(&db).filter(|node| 
        matches!(node.kind(&db), 
            SyntaxKind::Arg         )
    );



    // Extract log level
    let level = match args.next() {
        Some(node)  => node.get_text(&db),
        _ => {
            return ProcMacroResult::new(TokenStream::empty())
            .with_diagnostics(Diagnostic::error("Invalid log level").into())
        },
    };

    // Validate log level
    println!("Level: {}", level);
    if level != "\"TRACE\"" && level != "\"DEBUG\"" {
        return ProcMacroResult::new(TokenStream::empty())
            .with_diagnostics(Diagnostic::error("Invalid log level. Use TRACE or DEBUG").into());
    }

    // Extract format string
    let format_string = match args.next() {
        Some(node) => node.get_text(&db),
        _ => return ProcMacroResult::new(TokenStream::empty())
            .with_diagnostics(Diagnostic::error("Invalid format string").into()),
    };

    // Extract remaining arguments
    let log_args: Vec<String> = args
        .filter_map(|node| {
            if matches!(node.kind(&db), SyntaxKind::Arg) {
                Some(node.get_text(&db))
            } else {
                println!("Invalid argument: {:?} {:?}", node.get_text(&db), node.kind(&db));
                None
            }
        })
        .collect();

       // Generate the log statement with feature checks
       let log_statement = match level.as_str() {
        "\"TRACE\"" => {
            if log_args.is_empty() {
                format!(
                    "println!(\"{{}}: {{}}\", {}, format!({}))",
                    "'TRACE'",
                    format_string
                )
            } else {
                format!(
                    "println!(\"{{}}: {{}}\", {}, format!({}, {}))",
                    "'TRACE'",
                    format_string,
                    log_args.join(", ")
                )
            }
        },
        "\"DEBUG\"" => {
            if log_args.is_empty() {
                format!(
                    "println!(\"{{}}: {{}}\", {}, format!({}))",
                    "'DEBUG'",
                    format_string
                )
            } else {
                format!(
                    "println!(\"{{}}: {{}}\", {}, format!({}, {}))",
                    "'DEBUG'",
                    format_string,
                    log_args.join(", ")
                )
            }
        },
        _ => unreachable!(),
    };
    ProcMacroResult::new(TokenStream::new(log_statement))
}

 // Helper function to expand macros

mod tests{
    use super::*;
    use cairo_lang_macro::TokenStream;
     // Tests for log macro
    // Updated tests for log macro
    fn expand_macro(macro_fn: fn(TokenStream) -> ProcMacroResult, input: &str) -> String {
        let token_stream = TokenStream::new(input.to_string());
        let result = macro_fn(token_stream);
        result.token_stream.to_string()
    }
    
    #[test]
    fn test_log_macro_debug() {
        let expanded = expand_macro(log_02lvnd9pht92k, r#"log!("DEBUG", "test message: {}", 123)"#);
        assert_eq!(expanded, "println!(\"{}: {}\", 'DEBUG', format!(\"test message: {}\", 123))");
    }

    #[test]
    fn test_log_macro_trace() {
        let expanded = expand_macro(log_02lvnd9pht92k, r#"log!("TRACE", "entering function")"#);
        assert_eq!(expanded, "println!(\"{}: {}\", 'TRACE', format!(\"entering function\"))");
    }

    #[test]
    fn test_log_macro_invalid_level() {
        let expanded = expand_macro(log_02lvnd9pht92k, r#"log!("INFO", "test message")"#);
        assert_eq!(expanded, "");  // Empty TokenStream for error case
    }

    #[test]
    fn test_log_macro_empty_format() {
        let expanded = expand_macro(log_02lvnd9pht92k, r#"log!("DEBUG", "")"#);
        assert_eq!(expanded, "println!(\"{}: {}\", 'DEBUG', format!(\"\"))");
    }

    #[test]
    fn test_log_macro_multiple_arguments() {
        let expanded = expand_macro(log_02lvnd9pht92k, r#"log!("DEBUG", "Values: {}, {}, {}", 1, "two", 3.0)"#);
        assert_eq!(expanded, "println!(\"{}: {}\", 'DEBUG', format!(\"Values: {}, {}, {}\", 1, \"two\", 3.0))");
    }

    // New test for exact string matching
    #[test]
    fn test_log_macro_exact_string() {
        let expanded = expand_macro(log_02lvnd9pht92k, r#"log!("DEBUG", "Exact {} string", "test")"#);
        assert_eq!(expanded, "println!(\"{}: {}\", 'DEBUG', format!(\"Exact {} string\", \"test\"))");
    }

 }
 