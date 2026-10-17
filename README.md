# Lua 5.4 Lexical Analyzer (Flex & C)

A lexical analyzer (scanner) built with **Flex (Fast Lexical Analyzer Generator)** and **C** designed to read Lua 5.4 source code and tokenize it into a color-coded, tabular stream of valid lexical tokens and error reports. Developed as a Programming Languages (PL) course project.

---

## 1. Project Overview

This lexical analyzer scans source code written in **Lua 5.4** and classifies lexemes into their respective token categories. Rather than halting on the first invalid character, the scanner is engineered for resilience—flagging unrecognized characters and unterminated literals in real time while continuing to analyze the remainder of the file.

### Supported Language Scope
* **Reserved Keywords (19):** `and`, `break`, `do`, `else`, `elseif`, `end`, `for`, `function`, `goto`, `if`, `in`, `local`, `not`, `or`, `repeat`, `return`, `then`, `until`, `while`
* **Identifiers:** Valid variable and function names beginning with a letter or underscore (`[A-Za-z_][A-Za-z0-9_]*`)
* **Numeric Literals:** Decimal integers, IEEE-754 floating-point numbers (with optional scientific exponent notation), and `0x`/`0X`-prefixed hexadecimal literals
* **String Literals:** Single-quoted (`'...'`), double-quoted (`"..."`) with escape-sequence support, and multi-line long strings delimited by `[[` and `]]`
* **Boolean & Nil Literals:** `true`, `false`, and `nil`
* **Operators:** Arithmetic (`+`, `-`, `*`, `/`, `//`, `%`, `^`), relational (`==`, `~=`, `<=`, `>=`, `<`, `>`), bitwise (`&`, `|`, `~`, `<<`, `>>`), length (`#`), string concatenation (`..`), vararg (`...`), and assignment (`=`)
* **Delimiters:** `(`, `)`, `[`, `]`, `{`, `}`, `,`, `;`, `:`, `.`, and label delimiters (`::`)
* **Comments:** Single-line (`--`) and multi-line block comments (`--[[ ... ]]`)

> **Scope Note:** This tool performs **lexical analysis only**. Syntactic and semantic validation are outside its scope; it strictly reports lexical invalidity such as unknown characters and unterminated strings or comments.

---

## 2. Methodology & Architecture

The scanner (`lua_lexer.l`) is organized into three primary sections following standard Flex architecture:

1. **Definitions Section:**
   * Declares C headers, line/token/error counters, ANSI terminal color macros, and a 4096-byte static buffer (`mlbuf`) for accumulating multi-line tokens.
   * Defines modular regular expression macros (`KEYWORD`, `IDENT`, `FLOAT`, `HEX`, `OPERATOR`, `DELIMITER`, etc.).
   * Declares **Exclusive Start Conditions (`%x`)**—specifically `IN_BLOCK_COMMENT` and `IN_LONG_STRING`—to isolate stateful scanning of multi-line constructs until a closing `]]` delimiter or `<<EOF>>` is encountered.
   * Implements a custom `yywrap()` function to eliminate external linking dependencies (`-lfl`) across macOS and Linux environments.

2. **Rules Section (Pattern-Action Pairs):**
   * Matches input patterns against defined regular expressions and dispatches tokens to `print_token()`, which formats the output and truncates values exceeding 45 characters for clean table alignment.
   * Explicitly ignores horizontal whitespace (`[ \t\r]+`) while incrementing `line_number` on newline (`\n`) characters across all states.

3. **Error Recovery Strategy:**
   * **Single-Line Unterminated Strings:** Rules matching `\"[^\"\n]*$` and `\'[^\'\n]*$` catch unclosed quotes before the newline and report an `Unterminated string` error.
   * **Multi-Line EOF Traps:** State-specific `<<EOF>>` rules inside `IN_BLOCK_COMMENT` and `IN_LONG_STRING` detect unclosed `[[` blocks at the end of a file, report the exact error via `print_error()`, and reset the scanner state (`BEGIN(INITIAL)`).
   * **Catch-All Rule:** A final dot (`.`) rule captures any unrecognized symbol (such as `@`), logs an `Unknown character` error in red, and continues scanning the rest of the file.

### Token Specification Table

| Token Category | Regular Expression / Pattern | Examples |
| :--- | :--- | :--- |
| **Keywords** | `("and"\|"break"\|"do"\|"else"\|"elseif"\|"end"\|"for"\|"function"\|"goto"\|"if"\|"in"\|"local"\|"not"\|"or"\|"repeat"\|"return"\|"then"\|"until"\|"while")` | `local`, `function`, `elseif` |
| **Boolean & Nil** | `"true" \| "false" \| "nil"` | `true`, `false`, `nil` |
| **Identifiers** | `[A-Za-z_][A-Za-z0-9_]*` | `greet`, `student`, `_` |
| **Integers** | `[0-9]+` | `100`, `42`, `0` |
| **Floats** | `{DIGIT}+\.{DIGIT}*{EXPONENT}?\|{DIGIT}+{EXPONENT}\|\.{DIGIT}+{EXPONENT}?` | `5.4`, `1.75` |
| **Hexadecimal** | `0[xX][0-9A-Fa-f]+` | `0xFF5733`, `0x0F` |
| **Strings** | `\"(\\.|[^\"\\])*\"` or `\'(\\.|[^\'\\])*\'` | `"Hello, Lua!"`, `'Single quoted string'` |
| **Long Strings** | `[[` ... `]]` *(handled via `%x IN_LONG_STRING`)* | `[[ multiline long string ]]` |
| **Comments** | `--[^\n]*` or `--[[` ... `]]` *(via `%x IN_BLOCK_COMMENT`)* | `-- Loop`, `--[[ multiline comment ]]` |
| **Operators** | `("..."\|".."\|"//"\|"<<"\|">>"\|"=="\|"~="\|"<="\|">="\|"+"\|"-"\|"*"\|"/"\|"%"\|"^"\|"#"\|"&"\|"\|"\|"~"\|"<"\|">"\|"=")` | `..`, `<<`, `==`, `#` |
| **Delimiters** | `("::"\|"(" \| ")" \| "[" \| "]" \| "{" \| "}" \| "," \| ";" \| ":" \| ".")` | `(`, `)`, `{`, `}`, `,` |

---

## 3. Repository Structure

```text
lua-lexer-project/
├── README.md                      # Project documentation and usage guide
├── lua_lexer.l                    # Flex lexical analyzer source file
├── sample.lua                     # Valid Lua 5.4 test script covering all token types
├── broken.lua                     # Invalid Lua test script for error-handling verification
└── docs/
    └── LEXERDoc_Lanuzo_BSCS3A.pdf # Formal project documentation```

---

## 4. Setup, Compilation & Execution

### Prerequisites
* **Flex** (Fast Lexical Analyzer Generator)
* **GCC** (or any standard C compiler)

### Build Instructions
Run the following commands in your terminal from the project root directory:

```bash
# 1. Generate the C source file (lex.yy.c) from the Flex specification
flex lua_lexer.l

# 2. Compile the generated C file into an executable
# Note: -lfl is omitted because a custom yywrap() is defined in the code
gcc lex.yy.c -o lua_lexer
```

### Running the Analyzer

**Option A: Analyze a Lua source file**
```bash
# Run against the valid comprehensive sample
./lua_lexer sample.lua

# Run against the error-testing sample
./lua_lexer broken.lua
```

**Option B: Interactive Standard Input (`stdin`)**
```bash
./lua_lexer
# Type in input lines, press Enter, and press Ctrl+D for EOF
```

---

## 5. Results & Sample Output

The analyzer outputs a color-coded table listing the **Token Type**, **Value**, and **Line Number**, followed by an execution summary.

### Test Case 1: Lexically Valid Input
Input:
```text
int main() {
int x = 10;
}
```

Output:
```text
TOKEN TYPE   | VALUE                                         | LINE
-------------+-----------------------------------------------+---------
IDENTIFIER   | int                                           | line 1
IDENTIFIER   | main                                          | line 1
DELIMITER    | (                                             | line 1
DELIMITER    | )                                             | line 1
DELIMITER    | {                                             | line 1
IDENTIFIER   | int                                           | line 2
IDENTIFIER   | x                                             | line 2
OPERATOR     | =                                             | line 2
INTEGER      | 10                                            | line 2
DELIMITER    | ;                                             | line 2
DELIMITER    | }                                             | line 3
-------------+-----------------------------------------------+---------

Summary
  Tokens : 11
  Lines  : 4
  Errors : 0

  Input is lexically valid Lua.
```

### Test Case 2: Lexically Invalid Input
Input:
```text
int x = 10 @ 5;
```

Output:
```text
TOKEN TYPE   | VALUE                                         | LINE
-------------+-----------------------------------------------+---------
IDENTIFIER   | int                                           | line 1
IDENTIFIER   | x                                             | line 1
OPERATOR     | =                                             | line 1
INTEGER      | 10                                            | line 1
ERROR        | Unknown character: '@'                        | line 1
INTEGER      | 5                                             | line 1
DELIMITER    | ;                                             | line 1
-------------+-----------------------------------------------+---------

Summary
  Tokens : 6
  Lines  : 2
  Errors : 1

  1 lexical error(s) found.
```

---

## Author
* **Jessica Mae Lanuzo**
