# BigQuery Study Notes

## First Query: NYC CitiBike Analysis
- Accessed public datasets using the project ID: `bigquery-public-data`.
- Implemented subqueries and CTEs to calculate gender distribution percentages.
- **Key Takeaway:** Always filter for `NULL` or `unknown` values to avoid biased statistical analysis.

## Data Engineering Best Practices
- **CTEs (WITH clause):** Much more readable and maintainable than nested subqueries.
- **Formatting:** Using clear aliases (e.g., `AS qty`, `AS perc_gender`) makes the output user-friendly for stakeholders.

## Create a Dataset
1. In the **BigQuery Explorer** pane, click on the three dots (actions) next to your Project ID.
2. Select **Create dataset**.
3. **Dataset ID:** Enter a unique name (e.g., `trips_analysis`).
4. **Location type:** Choose a region (e.g., `us-multi-region` if using public datasets).
5. Click **Create Dataset**.

## Create a Table
1. Click on the three dots next to your new Dataset and select **Create table**.
2. **Source:** Choose where your data is coming from (e.g., `Upload`, `Google Cloud Storage`, or `Empty table`).
3. **Destination:** Ensure the correct Project and Dataset are selected.
4. **Table name:** Enter your table name (e.g., `gender_summary`).
5. **Schema:** - Toggle **Edit as text** to paste a JSON schema, or 
   - Click **Add field** to define columns manually, or
   - Use **Auto detect** for CSV/JSON files.
6. Click **Create Table**.

## SQL Standards
- BigQuery uses GoogleSQL (formerly known as Standard SQL) as its default query language.
- It is compliant with the ISO SQL: 2011 standard.

## Performance and Best Practices
- **Standard Query:** Best for very simple tasks but lacks code reuse.
- **Subqueries:** Useful for scoping but harder to read when nested.
- **CTEs:** Preferred method for complex logic; improves maintainability and readability without sacrificing BigQuery performance.

## Grouping and Aliases
- **GROUP BY:** Does not support aliases; the full expression or function (e.g., `EXTRACT`) must be used.
- **ORDER BY:** Can use either the alias or the full expression, but using aliases is often cleaner for final output sorting.

## Alias Visibility in BigQuery
- In BigQuery, aliases defined in the SELECT clause can often be referenced in GROUP BY, HAVING, and ORDER BY clauses.
- Standard SQL Rule: Most SQL engines require the full expression in GROUP BY and HAVING, only allowing aliases in the ORDER BY clause.
- Best Practice: While using aliases in BigQuery is convenient, being aware of the full expression requirement ensures compatibility with other SQL platforms.

## Nested and Repeated Data (JSON/BigQuery)
- **STRUCT (Curly Braces `{ }`):** Represents a single object or a logical grouping of fields. In BigQuery, it acts like a row within a cell.
- **ARRAY (Square Brackets `[ ]`):** Represents an ordered list of elements. In BigQuery schema, this is defined as a REPEATED field.
- **Relationship:** An Array of Structs `[{}, {}]` is the standard way to represent a "table within a table," allowing multiple related records to exist inside a single parent row.

## Why use STRUCT?
- **Logical Grouping:** Combines related columns into a single field (e.g., grouping `street`, `city`, and `zip` into an `address` struct).
- **Cleaner Schemas:** Reduces the number of top-level columns in massive tables, making them easier to navigate.
- **Data Integrity:** Ensures that related values stay together. When you move or copy a STRUCT, all its internal fields go with it.
- **Nested Power:** When combined with ARRAYS, it allows BigQuery to store hierarchical data (like a list of order items) inside a single row, avoiding heavy JOINs.

## Accessing Array Elements (OFFSET)
- **Zero-based indexing:** The first element is always accessed via `OFFSET(0)`.
- **Direct Access:** Allows retrieving specific data from a nested structure without needing to flatten (UNNEST) the entire table.
- **Deep Navigation:** You can chain offsets to reach data inside nested arrays (e.g., `array[OFFSET(0)].sub_array[OFFSET(1)]`).
- **Safety Tip:** Use `SAFE_OFFSET` to avoid query failures if the specified index does not exist in the array.