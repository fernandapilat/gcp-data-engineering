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