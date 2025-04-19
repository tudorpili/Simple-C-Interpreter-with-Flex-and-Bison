# Programming Language Project: Interpreter Goals

This document outlines the requirements for a simple programming language interpreter, covering language features and execution environment.


## Core Language Features

1.  **Variable Declaration:**
    * Support for declaring variables of the following data types: `int`, `double`, `float`.

2.  **Arithmetic Operations:**
    * Implementation of standard arithmetic operators: addition (`+`), subtraction (`-`), multiplication (`*`), division (`/`).
    * Operations must respect C-style implicit type conversion and promotion rules.

3.  **Control Flow Statements:**
    * Implementation of `if` / `else` conditional statements.
    * Conditional execution and loops must be based on logical (`&&`, `||`, `!`) and comparison (`<`, `>`, `==`, `!=`, etc.) operations.

4.  **Input/Output:**
    * Provide basic console input/output functionality, similar in concept to C's `printf` (for formatted output) and `scanf` (for formatted input).
    * Allow reading values into variables and printing variable values or string literals to the console.

5.  **Error Handling:**
    * Implement runtime error detection and reporting for common issues:
        * Division by zero.
        * Potential data type overflows/underflows (if within project scope).
    * Provide clear and adequate error messages.

6.  **Code Blocks and Scoping:**
    * Support for code blocks delimited by curly braces (`{ }`).
    * Variables declared within a block must have local scope (only accessible within that block and its nested blocks).

7.  **Explicit Type Casting:**
    * Implement explicit type conversions (casting) between `int`, `double`, and `float` types (e.g., using syntax like `(int)my_float_var`).

8.  **Comments:**
    * Allow single-line comments (e.g., using `//`).
    * Allow multi-line comments (e.g., using `/* ... */`).

## Interpreter & Execution Features

9. **User Interface:**
    * Provides a simple Command-Line Interface (CLI) for interacting with the interpreter.
    * Ensures the interpreter can execute:
        * Individual commands entered interactively (e.g., `int x = 5;`).
        * Scripts read from files (e.g., by issuing a command like `run script.txt`).

## Implementation Phases Mentioned

* **Lexer:** Responsible for breaking the source code into tokens.
* **Parser:** Responsible for checking grammar

---