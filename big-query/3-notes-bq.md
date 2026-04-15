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

### 3.5 Data Binning & Categorization
Used to transform continuous values (such as revenue, age, or scores) into discrete buckets (labels or tiers) without the need for complex and verbose `CASE WHEN` statements.

* **`RANGE_BUCKET(value, boundaries)`**: This function returns the index (integer) of the "bucket" in which the provided value fits, based on the defined array of boundaries.


#### **Practical Applications in Marketing & Sales**
The `RANGE_BUCKET` function is a game-changer for segmentation and business intelligence:

* **RFM Analysis (Recency, Frequency, Monetary)**:
    * Categorize customers by days since last purchase (Recency), total orders (Frequency), or total spend (Monetary) to identify "VIPs" vs. "At Risk" customers instantly.
* **Price Tier Performance**:
    * Group products into price ranges (e.g., Budget, Mid-range, Premium) to identify which price points drive the highest volume or margin.
* **Conversion Time-to-Purchase**:
    * Bin the time elapsed between the first lead touchpoint and the final sale (e.g., 0-24h, 1-7 days, 30+ days) to optimize follow-up automation.
* **Engagement Scoring**:
    * Segment users based on Email Click-Through Rates (CTR) or App Usage sessions into "Highly Active", "Passive", or "Churn-prone".
* **Marketing Scalability (CAC Analysis)**:
    * Group ad spend into investment tiers to analyze if Customer Acquisition Cost (CAC) remains stable as investment scales up.

## 4. SQL Logical Operators

Logical operators serve as the core logic for data filtration, allowing you to establish rigorous conditional rules. They are indispensable for shaping result sets and ensuring that your queries reflect the specific business logic required for your data analysis.

### 4.1 Operators Table

| Operator | Description | Usage Example |
| :--- | :--- | :--- |
| **AND** | True if all conditions are met. | `price > 100 AND stock > 0` |
| **OR** | True if at least one condition is met. | `status = 'Sold' OR status = 'Pending'` |
| **NOT** | Reverses the condition. | `NOT category = 'Clearance'` |

### 4.2 SQL Examples

**Using AND:**
```sql
SELECT *
FROM `your_project.dataset.products`
WHERE price < 50
  AND stock > 10;
```

### 4.3 Best Practice: The Power of Parentheses
Always use parentheses when mixing `AND` and `OR` to ensure the correct order of operations.

```sql
SELECT *
FROM `your_project.dataset.products`
WHERE (category = 'Electronics' OR category = 'Books')
  AND on_sale = TRUE;
  ```

### 4.4 Boolean Logic (TRUE, FALSE, and NULL)

In SQL, every condition in the `WHERE` clause is a **Boolean Expression**. This means that for every row, the database evaluates the condition and returns one of three states:

* **TRUE**: The row meets the criteria and **will** be displayed.
* **FALSE**: The row does not meet the criteria and **will not** be displayed.
* **NULL**: The value is unknown or missing. In filters, `NULL` behaves like a `FALSE` (it won't show the row).

#### The Truth Table
This table shows how SQL decides the final result when combining conditions:

| Condition A | Condition B | A AND B | A OR B |
| :--- | :--- | :--- | :--- |
| **TRUE** | **TRUE** | **TRUE** | **TRUE** |
| **TRUE** | **FALSE** | **FALSE** | **TRUE** |
| **FALSE** | **FALSE** | **FALSE** | **FALSE** |

### 4.5 The "Unknown" (NULL)
A common pitfall in SQL is how `NULL` interacts with logic. If a value is `NULL`, it isn't "True" nor "False"—it's unknown.

* `TRUE AND NULL` results in `NULL`
* `FALSE AND NULL` results in `FALSE`
* `TRUE OR NULL` results in `TRUE`

**Practical Example:**
If you want to find products that are explicitly marked as "Not Active", you use:
```sql
SELECT *
FROM `your_project.dataset.products`
WHERE is_active = FALSE;
```

### 4.6 Conditional Logic: IF & CASE

Conditional logic allows you to transform your data dynamically during a query, creating new categories or labels based on specific criteria.

#### The IF() Function
The IF() function is a concise way to evaluate a single condition and return one of two results.
*Syntax: IF(condition, value_if_true, value_if_false)*

```sql
SELECT 
  product_name,
  IF(price > 50, 'Expensive', 'Affordable') AS price_category
FROM `your_project.dataset.products`;
```

#### The CASE WHEN Statement
CASE WHEN is the industry standard in SQL. It is more versatile than IF() because it can handle multiple conditions and improves code readability.

```sql
SELECT 
  product_name,
  CASE 
    WHEN price > 100 THEN 'Premium'
    WHEN price > 50 THEN 'Mid-range'
    ELSE 'Budget'
  END AS price_category
FROM `your_project.dataset.products`;
```

## 5. Logical Functions & Conditional Expressions

This section covers functions used to handle null values and convert data dynamically. These are essential for ensuring data quality and preventing errors in calculations.

### 5.1 COALESCE Function
The `COALESCE()` function returns the first non-null value in a list of arguments. It is widely used to provide default values when a column contains `NULL`.

**Syntax:** `COALESCE(value_1, value_2, ..., default_value)`

```sql
SELECT 
  product_name,
  price,
  COALESCE(discount, 0) AS final_discount,
  price - COALESCE(discount, 0) AS net_price
FROM `your_project.dataset.sales`;
```

### 5.2 COALESCE vs IFNULL
While `COALESCE` is the SQL standard and accepts multiple arguments, BigQuery also supports `IFNULL()`, which is a simpler version for exactly two arguments.

* **IFNULL(val, default)**: Specific for two values.
* **COALESCE(v1, v2, v3, ...)**: More flexible, evaluates multiple options in order.

```sql
-- Using IFNULL for a simple replacement
SELECT IFNULL(phone_number, 'No phone provided') as contact_info
FROM `your_project.dataset.customers`;
```

### 5.3 Data Type Conversion (CAST)

Data often arrives in formats that prevent mathematical operations — for instance, a numeric value stored as a string (`'100'`). The `CAST()` function allows you to explicitly convert data from one type to another, ensuring your calculations work correctly.

**Syntax:** `CAST(expression AS data_type)`

**Example:**
Converting a string column to an integer:
```sql
SELECT 
  CAST(product_id AS INT64) AS product_id_int
FROM `your_project.dataset.products`;
```

#### Why and when to use CAST?
* **Aggregations:** You cannot `SUM()` a column that is defined as a `STRING`.
* **Joins:** You cannot join two tables if the join key in Table A is a `STRING` and in Table B it is an `INT64`.
* **Date Handling:** Converting `STRING` dates (e.g., '2026-04-15') into actual `DATE` types to use calendar functions.

#### The "Safe" Approach: SAFE_CAST
A very common problem is trying to cast a non-numeric string (e.g., 'ABC') into an integer, which causes the query to fail. BigQuery offers `SAFE_CAST()`, which returns `NULL` instead of an error if the conversion fails.

```sql
SELECT 
  SAFE_CAST(price_string AS FLOAT64) AS price_numeric
FROM `your_project.dataset.products`;
```

### 5.5 Conditional Categorization (CASE WHEN)

The `CASE WHEN` statement is the most powerful tool for creating custom business logic within your queries. It evaluates a sequence of conditions and returns a value as soon as the first condition is met.

**Standard Syntax:**
```sql
CASE 
  WHEN condition_1 THEN result_1
  WHEN condition_2 THEN result_2
  ELSE default_result
END AS new_column_name
```

**Practical Example: Dynamic Categorization**
In data analysis, we often need to group continuous variables (like price) into segments (like 'Low', 'Medium', 'High').

```sql
SELECT 
  product_name,
  price,
  CASE 
    WHEN price < 20 THEN 'Budget'
    WHEN price BETWEEN 20 AND 100 THEN 'Standard'
    WHEN price > 100 THEN 'Premium'
    ELSE 'Uncategorized'
  END AS price_segment
FROM `your_project.dataset.products`;
```

> **Note:** `CASE WHEN` is evaluated sequentially. The first `WHEN` that evaluates to `TRUE` will determine the result, and the engine will stop checking subsequent conditions for that row. This is why the order of your conditions matters!