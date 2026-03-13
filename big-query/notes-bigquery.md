# BigQuery Study Notes

## 1. First Query: NYC CitiBike Analysis
- Accessed public datasets using the project ID: `bigquery-public-data`.
- Implemented subqueries and CTEs to calculate gender distribution percentages.
- **Key Takeaway:** Always filter for `NULL` or `unknown` values to avoid biased statistical analysis.

---

## 2. Data Engineering Best Practices
- **CTEs (WITH clause):** Much more readable and maintainable than nested subqueries.
- **Formatting:** Using clear aliases (e.g., `AS qty`, `AS perc_gender`) makes the output user-friendly for stakeholders.

---

## 3. Create a Dataset
1. In the **BigQuery Explorer** pane, click on the three dots (actions) next to your Project ID.
2. Select **Create dataset**.
3. **Dataset ID:** Enter a unique name (e.g., `trips_analysis`).
4. **Location type:** Choose a region (e.g., `us-multi-region` if using public datasets).
5. Click **Create Dataset**.

---

## 4. Create a Table
1. Click on the three dots next to your new Dataset and select **Create table**.
2. **Source:** Choose where your data is coming from (e.g., `Upload`, `Google Cloud Storage`, or `Empty table`).
3. **Destination:** Ensure the correct Project and Dataset are selected.
4. **Table name:** Enter your table name (e.g., `gender_summary`).
5. **Schema:** - Toggle **Edit as text** to paste a JSON schema, or 
   - Click **Add field** to define columns manually, or
   - Use **Auto detect** for CSV/JSON files.
6. Click **Create Table**.

---

## 5. SQL Standards
- BigQuery uses GoogleSQL (formerly known as Standard SQL) as its default query language.
- It is compliant with the ISO SQL: 2011 standard.

---

## 6. Performance and Best Practices
- **Standard Query:** Best for very simple tasks but lacks code reuse.
- **Subqueries:** Useful for scoping but harder to read when nested.
- **CTEs:** Preferred method for complex logic; improves maintainability and readability without sacrificing BigQuery performance.

---

## 7. Grouping and Aliases
- **GROUP BY:** Does not support aliases in many standard SQL engines; the full expression or function (e.g., `EXTRACT`) must be used.
- **ORDER BY:** Can use either the alias or the full expression, but using aliases is often cleaner for final output sorting.

---

## 8. Alias Visibility in BigQuery
- In BigQuery, aliases defined in the SELECT clause can often be referenced in GROUP BY, HAVING, and ORDER BY clauses.
- Standard SQL Rule: Most SQL engines require the full expression in GROUP BY and HAVING, only allowing aliases in the ORDER BY clause.
- Best Practice: While using aliases in BigQuery is convenient, being aware of the full expression requirement ensures compatibility with other SQL platforms.

---

## 9. Nested and Repeated Data (JSON/BigQuery)
- **STRUCT (Curly Braces `{ }`):** Represents a single object or a logical grouping of fields. In BigQuery, it acts like a row within a cell.
- **ARRAY (Square Brackets `[ ]`):** Represents an ordered list of elements. In BigQuery schema, this is defined as a REPEATED field.
- **Relationship:** An Array of Structs `[{}, {}]` is the standard way to represent a "table within a table," allowing multiple related records to exist inside a single parent row.

---

## 10. Why use STRUCT?
- **Logical Grouping:** Combines related columns into a single field (e.g., grouping `street`, `city`, and `zip` into an `address` struct).
- **Cleaner Schemas:** Reduces the number of top-level columns in massive tables, making them easier to navigate.
- **Data Integrity:** Ensures that related values stay together. When you move or copy a STRUCT, all its internal fields go with it.
- **Nested Power:** When combined with ARRAYS, it allows BigQuery to store hierarchical data (like a list of order items) inside a single row, avoiding heavy JOINs.

---

## 11. Accessing Array Elements (OFFSET)
- **Zero-based indexing:** The first element is always accessed via `OFFSET(0)`.
- **Direct Access:** Allows retrieving specific data from a nested structure without needing to flatten (UNNEST) the entire table.
- **Deep Navigation:** You can chain offsets to reach data inside nested arrays (e.g., `array[OFFSET(0)].sub_array[OFFSET(1)]`).
- **Safety Tip:** Use `SAFE_OFFSET` to avoid query failures if the specified index does not exist in the array.

---

## 12. UNNEST: Flattening Data for Analysis
- **The Purpose:** Arrays are great for storage, but standard SQL functions (like `SUM` or `AVG`) cannot look inside a list. `UNNEST` "explodes" an array into individual rows.
- **Cross Join Logic:** When you use `FROM table, UNNEST(array_column)`, BigQuery performs a cross join, repeating the parent row information for every element inside the array.

- **Data Manipulation:** `UNNEST` is essential for filtering specific values hidden inside arrays (e.g., finding customers who bought a specific item within an order list).
- **Transformation Flow:** Typically, the workflow is: **Unnest** the data -> **Manipulate/Filter** -> **Re-aggregate** (using `ARRAY_AGG` if needed).

### ⚠️ Important: The Cartesian Product Trap
- **The Problem:** If you `UNNEST` two or more separate arrays in the same `SELECT` statement, BigQuery combines every element of the first array with every element of the second.
- **Visualizing the Issue:** - Array A: `[Matéria 1, Matéria 2]` (2 items)
    - Array B: `[0.4, 0.6]` (2 items)
    - **Result:** 4 rows instead of 2. BigQuery crosses everything (`Matéria 1` with `0.4` AND `0.6`).
- **The Impact:** This creates data duplication. If you try to sum the percentages, the result will be incorrect (e.g., 200% instead of 100%).
- **Current Status:** Understanding that multiple UNNESTs require a "pairing" logic (like matching by index) to avoid incorrect statistical analysis.

---

## 13. Why is BigQuery so fast? (The Big Three)
1. **Partitioning:** Only scans relevant data segments (usually by date).
2. **Clustering:** Sorts data within partitions for faster filtering.
3. **Columnar Storage:** Unlike traditional databases that read entire rows, BigQuery only reads the specific columns requested in the query.