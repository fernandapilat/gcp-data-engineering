# BigQuery Study Notes: Course 2

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