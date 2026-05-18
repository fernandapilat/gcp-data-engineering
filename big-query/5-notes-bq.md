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

#### **2.3 Data Validation and Conditional Logic (Validação e Estruturas Condicionais)**

To preserve data integrity, a procedure must validate that foreign keys exist before committing modifications to the database. In this session, we implement conditional branching (`IF / ELSE`) to verify if a product exists in the catalog before registering a sale.

##### **New Procedural Concepts:**
* **EXISTS():** A logical function that returns `TRUE` if a subquery returns at least one row, optimizing check performance.
* **BOOL DEFAULT FALSE:** Initializes a boolean variable with a default state of `FALSE`.
* **Conditional Branching:** Runs the `INSERT` block only `IF` the validation is true, otherwise (`ELSE`) it triggers an error message block.

---

##### **Step 1: Writing the Code (Production Standards)**

```sql
    CREATE OR REPLACE PROCEDURE `curso-bigquery-490113.belleza_verde_lib.incluiVenda3` (
      p_id_produto INT64, 
      p_id_cliente INT64, 
      p_data DATE, 
      p_quantidade INT64, 
      p_preco FLOAT64
    )
    BEGIN
      -- Declaring internal variables for logic handling
      DECLARE v_id_venda INT64;
      DECLARE v_produto_existe BOOL DEFAULT FALSE;
      DECLARE v_message_text STRING;

      -- Checking if the product ID exists in the master products table
      SET v_produto_existe = (
        SELECT EXISTS (
          SELECT 1 
          FROM `curso-bigquery-490113.belleza_verde_vendas.produtos` 
          WHERE id_produto = p_id_produto
        )
      );

      -- Conditional flow execution
      IF v_produto_existe THEN
        BEGIN
          -- Calculate automated incremented transaction ID
          SET v_id_venda = (
            SELECT IFNULL(MAX(id_venda), 0) + 1 
            FROM `curso-bigquery-490113.belleza_verde_vendas.vendas`
          );

          -- Execute data ingestion using official schema column names
          INSERT INTO `curso-bigquery-490113.belleza_verde_vendas.vendas`
            (id_venda, id_produto, id_cliente, data, quantidade, preco)
          VALUES 
            (v_id_venda, p_id_produto, p_id_cliente, p_data, p_quantidade, p_preco);
        END;
      ELSE
        BEGIN
          -- Fallback error handling if product is missing
          SET v_message_text = "error: product dosen't exist";
          SELECT v_message_text;
        END;
      END IF;
    END;
```
---

##### **Step 2: Testing Valid vs Invalid Ingestions**

To test the validation mechanism, we run two different CALL statements.

###### Test case A: Executing with a Valid Product ID
If product ID 1 exists in the products database, the record will append cleanly:

```sql
    CALL `curso-bigquery-490113.belleza_verde_lib.incluiVenda3`(1, 1, '2024-01-01', 10, 5.0);
```

###### **Test case B: Executing with an Invalid Product ID**
If product ID 9999 does not exist, the insert is skipped and the custom error string is returned:

```sql
    CALL `curso-bigquery-490113.belleza_verde_lib.incluiVenda3`(9999, 1, '2024-01-01', 10, 5.0);
```
---

#### **2.4 Advanced Multi-Entity Validation & Return Flags**

As pipeline architectures evolve, logging static error text messages becomes inefficient for automated applications. In this session, we upgrade the procedure to validate multiple target entities simultaneously (Products and Clients) and implement integer status flags (`0` or `1`) to return structured diagnostic matrices.

##### Architectural Concepts Introduced:
* **Multi-Entity Evaluation:** Splitting logic checks into separate `EXISTS` subqueries across different master tables.
* **Boolean Conjunction (`AND`):** The conditional block `IF conditionA AND conditionB` requires both criteria to evaluate to `TRUE` before execution.
* **Inline Functional IF:** The conditional function `IF(expression, true_value, false_value)` acts as a clean inline ternary operator to dynamically assign flag values.

---

##### **Step 1: Writing the Code (Production Standards)**

```sql
    CREATE OR REPLACE PROCEDURE `curso-bigquery-490113.belleza_verde_lib.incluiVenda4` (
      p_id_produto INT64, 
      p_id_cliente INT64, 
      p_data DATE, 
      p_quantidade INT64, 
      p_preco FLOAT64
    )
    BEGIN
      -- Declaring internal tracking variables
      DECLARE v_id_venda INT64;
      DECLARE v_produto_existe BOOL DEFAULT FALSE;
      DECLARE v_cliente_existe BOOL DEFAULT FALSE;
      DECLARE v_id_retorno_produto INT64;
      DECLARE v_id_retorno_cliente INT64;

      -- Entity Check 1: Product Master Validation
      SET v_produto_existe = (
        SELECT EXISTS (
          SELECT 1 
          FROM `curso-bigquery-490113.belleza_verde_vendas.produtos` 
          WHERE id_produto = p_id_produto
        )
      );

      -- Entity Check 2: Client Master Validation
      SET v_cliente_existe = (
        SELECT EXISTS (
          SELECT 1 
          FROM `curso-bigquery-490113.belleza_verde_vendas.clientes` 
          WHERE id_cliente = p_id_cliente
        )
      );

      -- Strict evaluation block
      IF v_produto_existe AND v_cliente_existe THEN
        BEGIN
          -- Generate automated sequential ID
          SET v_id_venda = (
            SELECT IFNULL(MAX(id_venda), 0) + 1 
            FROM `curso-bigquery-490113.belleza_verde_vendas.vendas`
          );

          -- Ingest transaction data
          INSERT INTO `curso-bigquery-490113.belleza_verde_vendas.vendas`
            (id_venda, id_produto, id_cliente, data, quantidade, preco)
          VALUES 
            (v_id_venda, p_id_produto, p_id_cliente, p_data, p_quantidade, p_preco);

          -- Success Flags
          SET v_id_retorno_produto = 1;
          SET v_id_retorno_cliente = 1;
        END;
      ELSE
        BEGIN
          -- Error Evaluation: Computing dynamic failure matrix paths
          SET v_id_retorno_produto = IF(v_produto_existe, 1, 0);
          SET v_id_retorno_cliente = IF(v_cliente_existe, 1, 0);
        END;
      END IF;

      -- Return the operational status block
      SELECT v_id_retorno_produto AS produto, v_id_retorno_cliente AS cliente;
    END;
```
---

##### **Step 2: Diagnostic Evaluation matrix (Test Scenarios)**

We evaluate the dynamic return response dashboard by targeting multiple dataset records:

###### **Scenario A: Both Entities Exist (Valid Entry)**
Flags output 1, 1. Ingestion executes smoothly.

```sql
    CALL `curso-bigquery-490113.belleza_verde_lib.incluiVenda4`(1, 1, '2024-01-01', 10, 5.0);
```

###### **Scenario B: Invalid Product ID and Valid Client ID**
Flags output 0, 1. Ingestion is bypassed.

```sql
    CALL `curso-bigquery-490113.belleza_verde_lib.incluiVenda4`(100, 1, '2024-01-01', 10, 5.0);
```

###### **Scenario C: Valid Product ID and Invalid Client ID**
Flags output 1, 0. Ingestion is bypassed.

```sql
    CALL `curso-bigquery-490113.belleza_verde_lib.incluiVenda4`(1, 100, '2024-01-01', 10, 5.0);
```

###### **Scenario D: Both Entities Are Invalid**
Flags output 0, 0. Ingestion is bypassed.

```sql
    CALL `curso-bigquery-490113.belleza_verde_lib.incluiVenda4`(100, 100, '2024-01-01', 10, 5.0);
```
---