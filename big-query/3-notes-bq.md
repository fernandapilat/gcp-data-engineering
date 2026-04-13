# BigQuery Study Notes

## Official Documentation & Resources
* **Official Google Cloud Documentation:** [BigQuery Docs](https://docs.cloud.google.com/bigquery/docs?hl=pt-br)
* **Recommended Reading:** [Google BigQuery: The Definitive Guide (O'Reilly)](https://www.amazon.com/Google-BigQuery-Definitive-Warehousing-Analytics/dp/1492044466)

---

## Course 3: Google BigQuery - Mastering Logical and Numerical Functions

This course focuses on advanced data transformation, implementing business logic directly in SQL, and handling complex numerical operations within the Google Cloud Platform.

### 1. Data Types Fundamentals (Review)
* **Definition:** Understanding data types is crucial for data integrity and query performance. BigQuery is strictly typed, meaning operations between incompatible types require explicit conversion (Casting).
* **Core Groupings:** Data types are divided into Textual, Numeric, Temporal, and Complex (Nested) categories.

#### **1.1 Textual Data Types**
* **STRING:** Variable-length Unicode character data. The most common type for names, addresses, and IDs.
* **BYTES:** Raw binary data. Useful for encoded information or blobs that do not require text interpretation.

#### **1.2 Numeric Data Types**
| Type | Description | Best Use Case |
| :--- | :--- | :--- |
| **INT64** | 64-bit integer (whole numbers). | Counts, IDs, ages. |
| **NUMERIC** | Exact fixed-precision decimal (38 digits). | Financial data (Money/Currency). |
| **BIGNUMERIC** | Ultra-high precision decimal (76+ digits). | Complex scientific calculations. |
| **FLOAT64** | Double-precision floating point. | Approximate values (Percentages, geographic coordinates). |

#### **1.3 Logical and Other Types**
* **BOOL:** Represents `TRUE` or `FALSE` (or `NULL`). Essential for conditional filtering and flags.
* **GEOGRAPHY:** Represents points, lines, and polygons based on the WGS84 reference ellipsoid.

#### **1.4 Complex and Nested Data Types**
* **ARRAY (Repeated):** An ordered list of zero or more elements of the same data type. It allows storing multiple values in a single row, optimizing performance and reducing JOINs.
* **STRUCT (Record):** A container of ordered fields. Used to group related data into a single object (e.g., `address.city`).

#### **1.5 Overview of Function Categories**
In BigQuery, functions are categorized based on how they process data and what they return. Understanding these categories is essential for choosing the right tool for each analytical task.

* **Scalar Functions:** Operates on a single row and returns a single value (e.g., `ROUND`, `UPPER`).
* **Aggregate Functions:** Operates on a group of rows and returns a single summarized value (e.g., `SUM`, `COUNT`, `AVG`).
* **Analytic (Window) Functions:** Operates on a group of rows (a window) but returns a value for **each** row. Used for rankings and moving averages (e.g., `ROW_NUMBER()`, `RANK()`).
* **Table-Valued Functions (TVFs):** Functions that return an entire table instead of a single value.
* **User-Defined Functions (UDFs):** Custom functions created by the user using SQL or JavaScript to perform specific logic not available in built-in functions.

> **Note:** Our primary focus in this course will be **Scalar Functions**, specifically for manipulating **Numeric**, **Text (String)**, and **Date** types.

---

## 2. Numerical Functions
Numerical functions are scalar functions used to perform mathematical operations on numeric data types. They are essential for ensuring data precision and reporting accuracy.

### 2.1 Rounding and Truncating Functions
These functions control how decimal values are handled, either by approximating to the nearest value or by forcing a specific direction (up or down).

* **`ROUND(expression [, digits])`**: Rounds a number to the nearest value based on the specified number of decimal places.
    * **Logic:** Standard mathematical rounding (0.5 and up goes to the next integer).
    * **Example:** `ROUND(15.79)` results in `16`.
* **`TRUNC(expression [, digits])`**: "Chops off" the decimal part without any rounding.
    * **Logic:** Simply discards digits. It is the "honest" representation of the base value.
    * **Example:** `TRUNC(15.79)` results in `15`.
* **`FLOOR(expression)`**: Always rounds **down** to the nearest integer.
    * **Logic:** Moves towards negative infinity.
    * **Example:** `FLOOR(15.79)` results in `15`.
* **`CEIL(expression)`**: Always rounds **up** to the nearest integer.
    * **Logic:** Moves towards positive infinity. It ensures no "overflow" is left behind.
    * **Example:** `CEIL(15.11)` results in `16`.

---

### 2.2 Comparison Matrix: Decision Making
To choose the right function, we compare how each one reacts to the same input value. This is crucial for financial and logistical reports.

| Input (x) | `ROUND(x)` | `TRUNC(x)` | `FLOOR(x)` | `CEIL(x)` | Business Context |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **2.1** | 2 | 2 | 2 | 3 | **CEIL** is used for "at least one more" (e.g., extra box). |
| **2.5** | 3 | 2 | 2 | 3 | **ROUND** starts pushing up from .5. |
| **2.9** | 3 | 2 | 2 | 3 | **TRUNC/FLOOR** ignore proximity to the next integer. |
| **-2.1** | -2 | -2 | -3 | -2 | **FLOOR** is the only one that drops to -3. |

### 2.3 Handling "Infinity" and Division by Zero
In real-world datasets, encountering a zero in the denominator is common. Standard SQL operations will crash if they try to divide by zero. BigQuery provides specific scalar functions to ensure process continuity and handle these mathematical exceptions.

* **`SAFE_DIVIDE(numerator, denominator)`**: 
    * **Logic:** If the denominator is `0`, it returns `NULL`.
    * **Business Context:** Best for clean reports where you want to hide errors or missing data.
* **`IEEE_DIVIDE(numerator, denominator)`**: 
    * **Logic:** Follows the IEEE 754 standard. Instead of `NULL`, it returns mathematical symbols:
        * `Infinity` (if numerator > 0)
        * `-Infinity` (if numerator < 0)
        * `NaN` (Not a Number, if 0/0)
    * **Business Context:** Acts as a "signal flare." `Infinity` in a report quickly points out data anomalies (like a product sold with zero cost) without stopping the entire data pipeline.

* **`IS_INF(expression)`**: Returns `TRUE` if the value is infinite.
* **`IS_NAN(expression)`**: Returns `TRUE` if the value is "Not a Number".

### 2.4 The `SAFE.` Prefix (Global Safety Net)
In BigQuery, the `SAFE.` prefix can be applied to many scalar functions to handle "dirty data." It is a best practice to ensure your data pipeline doesn't crash due to unexpected values.

* **Definition:** Prepending `SAFE.` to a function tells BigQuery to return `NULL` instead of throwing a runtime error when an operation is logically or mathematically impossible.
* **Why use it?** It shifts the problem from **"The query failed"** to **"Some rows contain incompatible data"**, allowing you to finish the analysis and investigate the nulls later.

#### Essential Examples for Data Analysis:

| Function | Standard Behavior (Crashes Query) | SAFE Behavior (Returns NULL) | Context |
| :--- | :--- | :--- | :--- |
| **CAST** | `CAST('ABC' AS INT64)` | `SAFE.CAST('ABC' AS INT64)` | When a numeric column contains text. |
| **LOG/SQRT** | `SQRT(-1)` | `SAFE.SQRT(-1)` | When performing invalid math operations. |
| **PARSE_DATE** | Invalid date strings (e.g., 'Feb 31') | `SAFE.PARSE_DATE('%b %d', 'Feb 31')` | When dealing with messy date formats. |
| **SUBSTR** | Out-of-bounds references | `SAFE.SUBSTR(text, 1000, 5)` | When extracting text from variable strings. |

> **💡 Tip: Not all functions support the `SAFE.` prefix**
>
> While `SAFE.` is a powerful tool to prevent execution errors, it only works with **scalar functions** (functions that process one value at a time, such as `CAST`, `SUBSTR`, or mathematical functions).
>
> **Common functions that DO NOT support `SAFE.`:**
> * **Aggregate Functions:** `SUM()`, `AVG()`, `COUNT()`, `MAX()`. These functions naturally ignore `NULL` values, so the prefix is unnecessary (and will cause an error).
> * **Direct Logical/Math Operators:** You cannot use `SAFE.(2 + 2)`. Instead, use specific functions like `SAFE_DIVIDE`, `SAFE_ADD`, or `SAFE_MULTIPLY`.
> * **Window Functions:** Functions like `RANK()` or `ROW_NUMBER()` do not accept the prefix.

---

## 3. Numeric Functions and Advanced Precision

This topic explores mathematical data processing in BigQuery, focusing on ensuring financial integrity, handling scale, and automating data categorization.

### 3.1 Numerical Notations and Precision (NUMERIC vs. FLOAT64)

* **NUMERIC / BIGNUMERIC:** Best practice for financial calculations. Uses decimal base to prevent binary rounding errors (crucial for exact currency calculations).
* **FLOAT64:** Used for scientific and statistical modeling where absolute penny-level precision is secondary to high-speed computation.

### 3.2 Directional Functions and Logical Math

#### `SIGN(X)`
The `SIGN` function identifies the direction of a numeric value. It serves as a high-performance alternative to `CASE WHEN` for simple trend classification.

* **Returns 1:** If the value is positive.
* **Returns -1:** If the value is negative.
* **Returns 0:** If the value is zero.

> **Practical Example (Section 23):** Identifying stock health trends.

### 3.3 Randomization and Data Sampling

#### `RAND()`
Generates a pseudo-random `FLOAT64` value between 0 and 1. Essential for sampling and A/B testing.

* **Data Sampling:** Used to inspect a representative subset of a massive dataset without processing the entire table.
* **A/B Testing:** Useful for splitting users into random cohorts for experiments.

```sql
-- Section 24: Random Sampling (Sampling 1% of the data)
SELECT *
FROM `projeto.dataset.tabela_gigante`
WHERE RAND() < 0.01;

-- Section 24: A/B Testing Cohorts
SELECT 
  id_usuario,
  IF(RAND() < 0.5, 'Group_A', 'Group_B') AS experiment_cohort
FROM `projeto.dataset.usuarios`;
```

> **Pro-Tip:** If you need a reproducible result (e.g., a "random" group assignment that stays the same every time you query for a specific user), use  ``` FARM_FINGERPRINT()``` instead of ```RAND()```. This hashes a value into a stable integer.

### 3.4 Advanced Mathematical Toolkit

This section documents the auxiliary mathematical functions in BigQuery, categorized by their practical application in Analytics Engineering.

#### Comparison and Boundary Functions
Used to enforce business rules and data normalization.

* **`GREATEST(x, y, ...)`:** Returns the maximum value.
* **`LEAST(x, y, ...)`:** Returns the minimum value.

```sql
-- Example: Capping a discount between 0% and 50%
SELECT 
  nome_produto,
  GREATEST(0, LEAST(desconto_aplicado, 0.5)) AS desconto_final
FROM `curso-bigquery-490113.belleza_verde_vendas.produtos`;
```

#### Modulo and Safe Operations
Essential for data partitioning and defensive programming.

* `MOD(x, y)`: Returns the remainder of the division.
* `SAFE_MULTIPLY(x, y)`: Prevents query failure by returning `NULL` instead of an error on overflow.

```sql
-- Example: Distributing users into 2 groups (A/B Testing)
SELECT 
  id_usuario,
  IF(MOD(id_usuario, 2) = 0, 'Group_A', 'Group_B') AS cohort
FROM `curso-bigquery-490113.belleza_verde_vendas.usuarios`;
```

#### Logarithmic, Power, and Trigonometric Functions
Used for advanced statistical modeling, data transformation, and spatial analysis.

* `POW(x, y)`: Calculates x raised to the power of y.
* `LN(x)`: Natural logarithm of x.
* `LOG(x, base)`: Logarithm of x in the specified base (defaults to 10).
* `SAFE.LOG(x, base)`: Similar to `LOG`, but returns `NULL` instead of an error if x <= 0.
* `SIN(x)`, `COS(x)`, `TAN(x)`: Trigonometric functions (input in radians).
* `RADIANS(x)`, `DEGREES(x)`: Angular conversions.

```sql
-- Example: Using POW for compound growth calculations
SELECT 
  valor_inicial * POW(1 + taxa_juros, periodo) AS valor_futuro
FROM `projeto.dataset.financeiro`;
```
