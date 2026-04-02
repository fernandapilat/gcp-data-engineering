# BigQuery Study Notes

## Official Documentation & Resources
* **Official Google Cloud Documentation:** [BigQuery Docs](https://docs.cloud.google.com/bigquery/docs?hl=pt-br)
* **String Functions Reference:** [Standard SQL String Functions](https://cloud.google.com/bigquery/docs/reference/standard-sql/string_functions)
* **Date & Time Functions Reference:** [Standard SQL Date Functions](https://cloud.google.com/bigquery/docs/reference/standard-sql/date_functions)

---

## 1. Data Types Fundamentals
* **Definition:** Understanding data types is crucial for data integrity and query performance. BigQuery is strictly typed, meaning operations between incompatible types require explicit conversion.
* **Core Groupings:** Data types are divided into Textual, Numeric, Temporal, and Complex (Nested) categories.

### 1.1 Textual Data Types
* **STRING:** Variable-length Unicode character data. The most common type for names, addresses, and IDs.
* **BYTES:** Raw binary data. Useful for encoded information or blobs that do not require text interpretation.

### 1.2 Numeric Data Types
| Type | Description | Best Use Case |
| :--- | :--- | :--- |
| **INT64** | 64-bit integer (whole numbers). | Counts, IDs, ages. |
| **NUMERIC** | Exact fixed-precision decimal (38 digits). | Financial data (Money/Currency). |
| **BIGNUMERIC** | Ultra-high precision decimal (76+ digits). | Scientific calculations. |
| **FLOAT64** | Double-precision floating point. | Approximate values (Percentages, scientific constants). |

### 1.3 Logical and Other Types
* **BOOL:** Represents `TRUE` or `FALSE` (or `NULL`). Essential for conditional filtering.
* **GEOGRAPHY:** Represents points, lines, and polygons on the Earth's surface (WGS84).

## 2. Function Classifications (Scope)
* **Definition:** BigQuery categorizes functions based on how many rows they process and what they return. Understanding these types is essential for structuring correct SQL syntax.

### 2.1 Scalar Functions
* **Scope:** Operates on a single row (one or more input values) and returns a **single value** for each row.
* **Examples:** `CONCAT()`, `UPPER()`, `ROUND()`, `CAST()`.
* **Usage:** Commonly used in `SELECT` and `WHERE` clauses to transform data.

### 2.2 Aggregate Functions
* **Scope:** Takes a set of values from multiple rows (a collection) and returns a **single summarized value**.
* **Examples:** `SUM()`, `COUNT()`, `AVG()`, `MIN()`, `MAX()`.
* **Requirement:** Usually requires a `GROUP BY` clause for non-aggregated columns.

### 2.3 Analytic (Window) Functions
* **Scope:** Applied over a collection (window) but returns a **value for every row** in the set.
* **Examples:** `RANK()`, `ROW_NUMBER()`, `SUM() OVER()`.
* **Key Feature:** Allows calculation across rows without collapsing them into a single summary line.

### 2.4 Table Functions (TVFs)
* **Scope:** Functions that return an entire **table structure** (rows and columns).
* **Usage:** These are placed in the `FROM` clause of a query, acting as a dynamic data source.

## 3. String Functions (Textual Manipulation)
* **Goal:** Cleaning, formatting, and extracting patterns from `STRING` data. Essential for data normalization.

### 3.1 Case Normalization
* **UPPER(string):** Converts all characters to uppercase.
* **LOWER(string):** Converts all characters to lowercase.
* **INITCAP(string):** Converts the first letter of each word to uppercase and the rest to lowercase.
    * *Example:* `INITCAP('BELLEZA VERDE')` results in `'Belleza Verde'`.

### 3.2 Positional Extraction
* **LEFT(string, n):** Extracts the first `n` characters from the left side of the string.
* **RIGHT(string, n):** Extracts the last `n` characters from the right side of the string.
    * *Use Case:* Extracting fixed prefixes, suffixes, or product codes.

### 3.3 Trimming and Character Removal
* **LTRIM(string, [characters]):** Removes leading spaces (or a specific character) from the left.
* **RTRIM(string, [characters]):** Removes trailing spaces (or a specific character) from the right.
* **TRIM(string):** Removes spaces from both sides.
    * **Technical Note:** BigQuery allows an optional second argument to remove specific symbols, such as hyphens or dots (e.g., `LTRIM(name, "-")`).

### 3.4 Best Practices
* **Aliasing:** Always use `AS` to name transformed columns (e.g., `AS clean_name`) to ensure the output table is readable.
* **Backticks:** Use backticks ( ` ) when referencing project IDs or datasets that contain hyphens to prevent syntax errors.

### 3.5 Boolean Search Functions (Pattern Matching)
* **STARTS_WITH(string, prefix):** Returns `TRUE` if the string begins with the specified prefix. Case-sensitive.
* **ENDS_WITH(string, suffix):** Returns `TRUE` if the string ends with the specified suffix. 
    * *Use Case:* Identifying product categories or specific starting strings (e.g., checking if a product name starts with "Óleo").

### 3.6 String Concatenation & Nesting
* **CONCAT(val1, val2, ...):** Joins multiple strings or column values into a single string.
* **Nested Functions (Function Inception):** You can nest multiple string functions to perform complex cleaning in a single line.
    * *Example:* `TRIM(LTRIM(nome, '-'))` first removes leading hyphens and then cleans surrounding spaces.

### 3.7 Conditional Logic (CASE WHEN)
* **Definition:** A logical expression that returns a value based on specified conditions (similar to If-Then-Else).
* **Syntax:** ```sql
  CASE 
    WHEN condition THEN result 
    ELSE default_result 
  END AS alias```

## 4. Advanced Search & Modification
* **Goal:** Precise manipulation of strings by locating, extracting, or swapping specific patterns.

### 4.1 INSTR(string, substring)
* **Definition:** Returns the 1-based position of the first occurrence of a substring. Returns `0` if not found.
* **Business Use:** Finding the position of delimiters like `@` in emails or `-` in serial numbers.

### 4.2 SUBSTR(string, start_position, [length])
* **Definition:** Extracts a portion of a string starting at a specific index.
* **Business Use:** Extracting area codes (DDD) from phone numbers or specific segments from product SKUs.
* **Note:** Remember that BigQuery uses 1-based indexing.

### 4.3 REPLACE(original_string, search_pattern, replacement)
* **Definition:** Replaces all occurrences of a specified pattern with a new string.
* **Business Use:** Normalizing financial values (replacing `,` with `.`) or updating outdated brand names in a database.

### 4.4 Advanced Regex & Substring Logic
* **Regex Raw Strings (`r''`):** Use the prefix `r` before quotes in Regex to ensure special characters are read literally (Raw String).
* **Flexible Substring:** `SUBSTRING(text, start)` 
    * If the *length* parameter is omitted, it extracts everything from the start position to the **very end** of the string.

### 4.5 Regex Patterns for Emails
* **Rigid Pattern (`^[a-z...`):** Validates the entire structure (start, middle, domain, extension).
* **Flexible Pattern (`\S+@\S+`):** Quickly checks for "anything-but-space" around the @ and dot.
* **Pro Tip:** Use `\` before a dot (`\.`) when you want to search for a literal period, otherwise Regex thinks it means "any character."

### 4.6 Advanced Formatting with `FORMAT()` and `CONCAT()`
* **Data Storytelling:** Using `CONCAT()` to merge raw data with natural language strings, making reports human-readable.
* **The `FORMAT()` Function:** Acts as a "translator" for numbers.
    * **`%d` (Integer):** Formats the number as a whole integer, removing decimals.
    * **`%.2f` (Float):** Formats the number as a decimal with exactly **2 decimal places**.
* **Combined Logic:** When using `SUM()` inside `FORMAT()`, you ensure that the aggregated result is styled correctly before being concatenated into a final string.

