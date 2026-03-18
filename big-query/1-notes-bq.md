# BigQuery Study Notes

## Official Documentation & Resources
* **Official Google Cloud Documentation:** [BigQuery Docs](https://docs.cloud.google.com/bigquery/docs?hl=pt-br)
* **Recommended Reading:** [Google BigQuery: The Definitive Guide (O'Reilly)](https://www.amazon.com/Google-BigQuery-Definitive-Warehousing-Analytics/dp/1492044466)

---

## Course 1: Navigating the Cloud - BigQuery Fundamentals

## 1. What is BigQuery and How it Behaves
* **Definition:** A multi-cloud, **serverless**, highly scalable, and cost-effective data warehouse designed for business agility.
* **Architecture:** Based on the **Dremel** execution engine (compute) and the **Colossus** file system (storage).
* **OLAP vs OLTP:** BigQuery is an **OLAP** (Analytical) system, optimized for massive reads and complex aggregations, unlike **OLTP** databases (MySQL/PostgreSQL) made for individual row transactions.
* **"No-Lock" Philosophy:** It does not enforce Primary Keys (PK) or Foreign Keys (FK). You can declare them for documentation, but the engine won't block duplicates. Data integrity is the responsibility of the **ETL process**.
* **Resource Hierarchy:** `Organization -> Folder -> Project -> Dataset -> Table/View`.

---

## 2. Performance Pillar: Columnar vs. Row Storage
* **Traditional DBs (Row-oriented):** Read the entire row even if you only need one column.
* **BigQuery (Columnar-oriented):** Operates on "Vertical Slices" (Capacitor format).
* **Theoretical Impact:** This is why `SELECT *` is discouraged; you are billed and performance is hit based on the specific columns (bytes) processed.
* **Storage and Compute Separation:** Processing power (**Slots**) is independent of data storage (**Colossus**), allowing for automatic and instant scaling.



---

## 3. Market Context and Data Structures

### 3.1 BigQuery vs. Competitors
| Feature | **Google BigQuery** | **AWS Redshift** | **Azure Synapse** |
| :--- | :--- | :--- | :--- |
| **Architecture** | **Serverless** (Total) | **Node-based** (Cluster) | **Hybrid** |
| **Scaling** | Automatic & Instant | Manual or Auto-scaling | Manual or Semi-auto |
| **Pricing Model** | Per Query (Bytes) | Per Hour/Instance | Per Data Processed |

### 3.2 Nested Data (Denormalization)
* **STRUCT `{ }` (Record):** A "Folder" that groups related fields (Atomic data).
* **ARRAY `[ ]` (Repeated):** A "Stack" of values within a single row (One-to-many relationship).

| Feature | STRUCT (Record) | ARRAY (Repeated) |
| :--- | :--- | :--- |
| **JSON Symbol** | `{ }` (Curly Braces) | `[ ]` (Square Brackets) |
| **BQ Schema** | `RECORD` | `REPEATED` |

---

## 4. The Mechanics of UNNEST and Joins
* **UNNEST:** A function that "unpacks" an `ARRAY` and turns it into a set of rows, allowing standard SQL operations (like `WHERE` or `GROUP BY`) on nested elements.
* **Cross Join Effect:** When using `UNNEST`, BigQuery multiplies the "Parent" row by every "Child" element inside the array. Watch out for "Data Explosion."
* **Type Compatibility:** BigQuery requires exact types for Joins. Use `CAST(expression AS type)` to fix "Type Mismatch" errors (e.g., String to Int64).

---

## 5. Correlation Theory: Avoiding the Cartesian Product
* **The Problem:** Unnesting two independent arrays simultaneously causes incorrect combinations (**N x M rows**) because positional context is lost.
* **The Solution (Indexing):** Reintroduce order via positional logic using `OFFSET` or `ROW_NUMBER()`.

```sql
-- Modern Method (Best Practice)
SELECT id_product, mp, ds
FROM `project.dataset.products`,
UNNEST(raw_materials) AS mp WITH OFFSET AS p1,
UNNEST(distribution) AS ds WITH OFFSET AS p2
WHERE p1 = p2; -- Ensures 1:1 correlation
```


## 6. Strategic Optimization and Data Objects

### 6.1 Performance Best Practices
* **Early Casting:** Convert data types inside CTEs, not within JOIN clauses.
* **Predicate Pushdown:** Apply filters (`WHERE`) as early as possible in the query flow.
* **Column Pruning:** Avoid `SELECT *`. Call only the required columns to minimize the columnar engine's scan.

### 6.2 Partitioning vs. Clustering
* **Partitioning:** Segments a table (usually by **Date**). It limits the number of bytes scanned.
* **Clustering:** Sorts data based on specific columns. It improves performance for filters and aggregations within partitions.



### 6.3 Table Types and Ingestion
* **Native Tables:** Data stored in Colossus (High performance).
* **External Tables:** BQ reads data directly from Google Drive or Cloud Storage (No storage cost, but slower).
* **Views:** Saved queries that act as logical shortcuts (No extra storage cost).
* **Batch vs. Streaming:** Batch loading is usually free; Real-time ingestion (Streaming) incurs costs per GB.

---

## 7. Analytical Functions and Editor Tips
* **Window Functions (`OVER`):** Performs calculations across a set of rows related to the current row without collapsing them. Essential for `RANK()`, `DENSE_RANK()`, and Market Share.
* **Editor Shortcuts:**
    * **Ctrl + Shift + F**: Format Query.
    * **Ctrl + /**: Comment/Uncomment line.
    * **Ctrl + Enter**: Run Query.
    * **Backticks (\`):** Mandatory for projects or datasets containing hyphens (`-`) or special characters.