# BigQuery Study Notes

## 1. What is BigQuery and How it Behaves
* **Definition:** A serverless, highly scalable, and cost-effective multi-cloud data warehouse designed for business agility.
* **OLAP vs OLTP:** BigQuery is an **OLAP** (Analytical) system optimized for massive reads and complex aggregations, unlike traditional **OLTP** databases (MySQL/PostgreSQL) made for individual row transactions.
* **The "No-Lock" Philosophy:** It does not enforce Primary Keys (PK) or Foreign Keys (FK). You can declare them for documentation, but the engine won't block duplicates.
* **Data Integrity:** Since there are no hard constraints, responsibility moves to the **ETL process** or the **application level**.

---

## 2. Performance Pillar: Columnar vs. Row Storage
* **Traditional DBs (Row-oriented):** Read the whole row even if you only need one column.
* **BigQuery (Columnar-oriented):** Operates on "Vertical Slices."
* **Theoretical Impact:** This is why `SELECT *` is discouraged; you are billed and performance is hit based on the specific columns (bytes) processed.

* **Storage and Compute:** It separates processing power (Slots) from data storage (Colossus), allowing independent and automatic scaling.

---

## 3. Market Context and Key Advantages

### 3.1 BigQuery vs. Competitors (The Big Three)

| Feature | **Google BigQuery** | **AWS Redshift** | **Azure Synapse** |
| :--- | :--- | :--- | :--- |
| **Architecture** | **Serverless** (Total) | **Node-based** (Cluster) | **Hybrid** (Dedicated/Serverless) |
| **Scaling** | Automatic & Instant | Manual or Auto-scaling groups | Manual or Semi-auto |
| **Pricing Model** | Per Query (Bytes scanned) | Per Hour/Instance | Per Data Processed or DWU |

### 3.2 Core Advantages (Professor's Insights)
* **Serverless:** Zero infrastructure management. Focus on SQL, not servers.
* **Standard SQL:** Uses ANSI 2011, reducing the learning curve for SQL professionals.
* **Real-Time Analysis:** Excellent performance for streaming and high-speed data ingestion.
* **Economic Impact:** TCO (Total Cost of Ownership) can be **50% to 80% lower** than traditional databases.
* **Auto-Discounts:** Automatic 50% price drop for data stored over 90 days without modification.
* **Integrated ML:** Native BigQuery ML for creating AI models using only SQL.

---

## 4. SQL Query Architecture & Data Structures
* **Query Comparison:**
    * *Standard Query:* Direct but rigid.
    * *Subqueries:* Useful for immediate calculations but can become a "black box."
    * *CTEs:* Virtual temporary tables that make code "self-explanatory."
* **Theory of Nested and Repeated Data (Denormalization):**
    * **STRUCT `{ }` (Record):** A "Folder" that groups related fields (Atomic data).
    * **ARRAY `[ ]` (Repeated):** A "Stack" of values within a single row (One-to-many relationship).

| Feature | STRUCT (Record) | ARRAY (Repeated) |
| :--- | :--- | :--- |
| **JSON Symbol** | `{ }` (Curly Braces) | `[ ]` (Square Brackets) |
| **BigQuery Schema** | `RECORD` | `REPEATED` |
| **Analogy** | A "Folder" within a cell | A "Stack" of values |

---

## 5. The Mechanics of UNNEST and Joins

### 5.1 UNNEST: The Bridge
* **Definition:** `UNNEST` is a function that takes an `ARRAY` and turns it into a set of rows. 
* **Conceptual Shift:** Think of it as "unpacking" a suitcase. Each item inside the array becomes its own row in the result set, allowing you to perform standard SQL operations (like `WHERE` or `GROUP BY`) on nested elements.


### 5.2 The Cross Join Effect
* **Behavior:** When you use `CROSS JOIN UNNEST`, BigQuery multiplies the "Parent" row by every "Child" element inside the array.
* **Caution:** This increases the row count of your result set significantly (Exploding the data).

### 5.3 Data Type Compatibility (Joining)
* **Strict Typing:** BigQuery requires exact type matches for Joins.
* **Casting:** Use `CAST(expression AS type)` to fix "Type Mismatch" errors.
    * *Example:* `ON CAST(rp.id_materia AS INT64) = mp.id_materia`

---

## 6. Correlation Theory: Avoiding the Cartesian Product
* **The Problem:** Unnesting two independent arrays simultaneously causes incorrect combinations (**N x M rows**) because the "positional context" is lost.
* **The Solution (Indexing):** Re-introduce order through positional logic using `OFFSET` or `ROW_NUMBER()` to ensure Array A pairs correctly with Array B.

### Practical Example (Step-by-Step)
```sql
-- Pairing Materials with their specific Distribution percentages
WITH index_produtos AS (
  SELECT id_produto, nome,
    ARRAY(SELECT AS STRUCT mp, ROW_NUMBER() OVER() AS idx FROM UNNEST(materiasprimas) AS mp) AS mp_idx,
    ARRAY(SELECT AS STRUCT ds, ROW_NUMBER() OVER() AS idx FROM UNNEST(distribuicao) AS ds) AS ds_idx
  FROM `curso-bigquery-490113.belleza_verde_vendas.produtos`
)
SELECT p.nome, m.mp AS id_materia, d.ds AS pct_distribuicao
FROM index_produtos p
CROSS JOIN UNNEST(p.mp_idx) AS m
CROSS JOIN UNNEST(p.ds_idx) AS d
ON m.idx = d.idx; -- Crucial correlation to avoid Cartesian Product
```

## 7. Performance Pillar: Columnar vs. Row Storage

### 7.1 Strategic Optimization
- **Early Casting:** Convert data types inside CTEs to ensure JOINs compare native types, avoiding per-row function overhead.
- **Native Unnesting:** Use `UNNEST(...) WITH OFFSET` instead of manual subqueries to pair arrays efficiently.
- **Predicate Pushdown:** Apply `WHERE` filters in the earliest possible CTE to reduce the volume of data flowing through the pipeline.
- **Column Pruning:** Avoid `SELECT *`. Only call specific columns to minimize the bytes scanned by the columnar engine.