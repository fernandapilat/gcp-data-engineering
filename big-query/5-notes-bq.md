# BigQuery Study Notes

## Official Documentation & Resources
* **Official Google Cloud Documentation:** [BigQuery Docs](https://docs.cloud.google.com/bigquery/docs?hl=pt-br)
* **Recommended Reading:** [Google BigQuery: The Definitive Guide (O'Reilly)](https://www.amazon.com/Google-BigQuery-Definitive-Warehousing-Analytics/dp/1492044466)

---

## Course 5: Google BigQuery - Advanced Queries

### 1. Stored Procedures (Procedimentos Armazenados)

Standard SQL is excellent for querying data, but it is not natively a structured programming language. It lacks loops (`LOOP`, `WHILE`) and decision-making structures (`IF/ELSE`) to handle complex procedural logic. 

A **Stored Procedure** is a collection of SQL statements (such as `INSERT`, `UPDATE`, `DELETE`, and DDLs) that can be saved and executed repeatedly inside BigQuery using a single `CALL` command.

#### **1.1 Key Advantages**
* **Code Reusability:** Write complex script logic once and execute it anywhere within the project without rewriting the queries.
* **Simplified Maintenance:** The code lives directly inside the BigQuery repository as a dataset object, making it easier to track changes.
* **Multi-operation Execution:** Runs complex sequences of data modification (`DML`) and table creation (`DDL`) in a single call.
* **Procedural Logic:** Allows the implementation of control-flow structures like loops and conditional branches.

#### **1.2 Practical Architecture & Use Cases**
Procedures are widely used in data engineering pipelines to automate heavy backend database workflows.

* **Inventory Management:** A daily automated pipeline to calculate, verify, and update inventory balances at midnight.
* **Transaction Processing:** Batch processing end-of-day sales records, calculating margins, and loading them into analytical schemas.
* **Data Cleansing Pipelines:** Running sequential `DELETE`, `MERGE`, and `UPDATE` tasks to sync staging tables into production.

| Feature | Stored Procedure Control Rule |
| :--- | :--- |
| **Execution Command** | Called explicitly using the `CALL procedure_name()` statement. |
| **Data Modification** | **Allowed** (Fully capable of running `INSERT`, `DELETE`, `MERGE`). |
| **Control Flow** | Supports variables (`DECLARE`), conditional blocks (`IF`), and loops. |

---

#### **1.3 Practical Application: Creating and Executing Your First Procedure**

A Stored Procedure allows us to wrap sequential statements—like INSERT operations—into reusable blocks. Instead of typing a full query every time we need to add a record, we can invoke a procedure and pass values as arguments.

**Best Practice: Dataset Separation**

To keep production architecture clean, it is highly recommended to isolate database data from procedural logic. 
* **Data Layer:** belleza_verde_vendas (Contains physical tables).
* **Logic Layer (Library):** belleza_verde_lib (Contains routines, procedures, and functions).

> **Crucial Rule:** Both datasets **must reside in the exact same data location** (e.g., us-central1 or Multi-region US) to communicate with each other. If they are in different regions, BigQuery will throw a location mismatch error.

---

**Step 1: Writing the Code (Production Standards)**

To define a procedure, we use the CREATE OR REPLACE PROCEDURE syntax. 

To avoid conflicts between input parameter names and actual table columns during execution, the standard engineering practice is to prefix parameters with p_ and name them in English to match the official schema.

```sql
CREATE OR REPLACE PROCEDURE `curso-bigquery-490113.belleza_verde_lib.incluiVenda1` (
      p_id_venda INT64, 
      p_id_produto INT64, 
      p_id_cliente INT64, 
      p_data DATE, 
      p_quantidade INT64, 
      p_preco FLOAT64
    )
    BEGIN
      -- The procedure body is enclosed between BEGIN and END
      INSERT INTO `curso-bigquery-490113.belleza_verde_vendas.vendas`
        (id_venda, id_produto, id_cliente, data, quantidade, preco)
      VALUES 
        (p_id_venda, p_id_produto, p_id_cliente, p_data, p_quantidade, p_preco);
    END;
```

*Once executed successfully, this script creates an active object inside the **Routines (Rotinas)** section under the belleza_verde_lib dataset.*

---

**Step 2: Executing the Procedure via CALL**

Instead of rewriting the entire INSERT INTO block for new transactions, we pass the parameter values directly to the CALL statement:

```sql
-- Inserting transaction ID 10952 dynamically
    CALL `curso-bigquery-490113.belleza_verde_lib.incluiVenda1`(
      10952, 
      1, 
      1, 
      '2024-01-01', 
      10, 
      5.0
    );
```
---

### 2. Scripting & Variables

BigQuery allows the use of procedural language features outside and inside Stored Procedures. By using scripting, we can declare local variables, perform dynamic calculations, and store query results to use in subsequent database operations.

#### **2.1 Declaring and Setting Variables**
* **DECLARE:** Used to allocate memory for a variable with a specific data type. Local variables inside a procedure must be declared at the very beginning of the block.
* **SET:** Used to assign a value to a previously declared variable, either with a static value or using the scalar result of a subquery.

---

#### **2.2 Practical Application: Automating Ingestion with Incrementing IDs**

Instead of requiring the user to manually input a transaction ID, we can automate the process by scanning the table for the current maximum ID, incrementing it by 1, and storing it inside an internal variable before running the data insertion.

##### **Step 1: Writing the Automated Procedure**

```sql
    CREATE OR REPLACE PROCEDURE `curso-bigquery-490113.belleza_verde_lib.incluiVenda2` (
      p_id_produto INT64, 
      p_id_cliente INT64, 
      p_data DATE, 
      p_quantidade INT64, 
      p_preco FLOAT64
    )
    BEGIN
      -- Declaring a local variable to store the calculated incrementing ID
      DECLARE v_id_venda INT64;

      -- Fetching the current maximum ID and adding 1
      SET v_id_venda = (
        SELECT IFNULL(MAX(id_venda), 0) + 1 
        FROM `curso-bigquery-490113.belleza_verde_vendas.vendas`
      );

      -- Executing injection using the internally calculated ID
      INSERT INTO `curso-bigquery-490113.belleza_verde_vendas.vendas`
        (id_venda, id_produto, id_cliente, data, quantidade, preco)
      VALUES 
        (v_id_venda, p_id_produto, p_id_cliente, p_data, p_quantidade, p_preco);
    END;
```

---

##### **Step 2: Executing the Procedure via CALL**
Notice that we no longer pass an explicit ID as the first argument, as the internal script logic calculates it automatically:

```sql
    CALL `curso-bigquery-490113.belleza_verde_lib.incluiVenda2`(1, 1, '2024-01-01', 10, 5);
```

---

##### **Step 3: Auditing Data Ingestion**
To verify that the procedure calculated and appended the next sequential ID correctly, we filter the table:

```sql
    SELECT * FROM `curso-bigquery-490113.belleza_verde_vendas.vendas` 
    WHERE data = '2024-01-01';
```
---


