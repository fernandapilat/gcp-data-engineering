# BigQuery Study Notes

## Official Documentation & Resources
* **Official Google Cloud Documentation:** [BigQuery Docs](https://docs.cloud.google.com/bigquery/docs?hl=pt-br)
* **Recommended Reading:** [Google BigQuery: The Definitive Guide (O'Reilly)](https://www.amazon.com/Google-BigQuery-Definitive-Warehousing-Analytics/dp/1492044466)

---

## Course 5: Google BigQuery - Advanced Queries

### **1. Stored Procedures**

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

### **2. Scripting & Variables**

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

##### **Architectural Concepts Introduced:**
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

#### **2.5 Modern Modularization using OUT Parameters**

To decouple database execution from user interface messaging, we implement `OUT` parameters. This allows a procedure to export its execution status as variables back to the calling script, which then evaluates the metrics using external `IF / ELSEIF` logic.

##### Architectural Benefits:
* **Separation of Concerns:** The procedure focuses strictly on data validation and ingestion, while the calling environment handles message rendering.
* **Reusable Outputs:** Output variables can be passed to other service nodes or systems without printing raw text on the console.

---

##### **Step 1: Writing the Decoupled Procedure**

```sql
CREATE OR REPLACE PROCEDURE `curso-bigquery-490113.belleza_verde_lib.incluiVenda4` (
  p_id_produto INT64, 
  p_id_cliente INT64, 
  p_data DATE, 
  p_quantidade INT64, 
  p_preco FLOAT64,
  OUT p_id_retorno_produto INT64, -- Explicit output parameter
  OUT p_id_retorno_cliente INT64  -- Explicit output parameter
)
BEGIN
  -- Declaring internal evaluation states
  DECLARE v_id_venda INT64;
  DECLARE v_produto_existe BOOL DEFAULT FALSE;
  DECLARE v_cliente_existe BOOL DEFAULT FALSE;

  -- Validation routines
  SET v_produto_existe = (
    SELECT EXISTS (
      SELECT 1 FROM `curso-bigquery-490113.belleza_verde_vendas.produtos` 
      WHERE id_produto = p_id_produto
    )
  );
  
  SET v_cliente_existe = (
    SELECT EXISTS (
      SELECT 1 FROM `curso-bigquery-490113.belleza_verde_vendas.clientes` 
      WHERE id_cliente = p_id_cliente
    )
  );

  -- Core execution tree
  IF v_produto_existe AND v_cliente_existe THEN
    BEGIN
      SET v_id_venda = (
        SELECT IFNULL(MAX(id_venda), 0) + 1 
        FROM `curso-bigquery-490113.belleza_verde_vendas.vendas`
      );

      INSERT INTO `curso-bigquery-490113.belleza_verde_vendas.vendas`
        (id_venda, id_produto, id_cliente, data, quantidade, preco)
      VALUES 
        (v_id_venda, p_id_produto, p_id_cliente, p_data, p_quantidade, p_preco);

      -- Exposing success state to OUT variables
      SET p_id_retorno_produto = 1;
      SET p_id_retorno_cliente = 1;
    END;
  ELSE
    BEGIN
      -- Exposing specific failure matrices to OUT variables
      SET p_id_retorno_produto = IF(v_produto_existe, 1, 0);
      SET p_id_retorno_cliente = IF(v_cliente_existe, 1, 0);
    END;
  END IF;
END;
```
---

##### **Step 2: Calling the Procedure and Evaluating Output Flags**

To capture the data exported by the `OUT` modifiers, we execute the procedure inside an active scripting session that interprets the response:

```sql
-- 1. Allocate external variable space to trap the OUT results
DECLARE ext_retorno_produto INT64;
DECLARE ext_retorno_cliente INT64;

-- 2. Trigger execution passing invalid records to test fallback logic
CALL `curso-bigquery-490113.belleza_verde_lib.incluiVenda4`(
  100, 100, '2024-01-01', 10, 5.0, 
  ext_retorno_produto, ext_retorno_cliente
);

-- 3. Dynamic Message Router (Conditional UI Feedback)
IF ext_retorno_produto = 0 AND ext_retorno_cliente = 0 THEN
  SELECT 'Identificador do PRODUTO e do CLIENTE inválidos' AS message;
ELSEIF ext_retorno_produto = 1 AND ext_retorno_cliente = 0 THEN  
  SELECT 'Identificador do CLIENTE inválido' AS message;
ELSEIF ext_retorno_produto = 0 AND ext_retorno_cliente = 1 THEN  
  SELECT 'Identificador do PRODUTO inválido' AS message;
ELSE
  SELECT 'Venda incluída com sucesso' AS message;
END IF;
```
---

#### **2.6 Practice Challenge: Internal Business Rule Validation (`inclui_qty`)**

To enforce data quality at the ingestion level without database cross-referencing.

##### **Architectural Benefits:**
* **Input Isolation:** Validates arithmetic logic directly from parameters before executing any table queries.
* **Proactive Data Quality:** Prevents corrupt or unrealistic metrics (e.g., negative amounts or extreme typos) from entering downstream analysis.

---

##### **Step 1: Writing the Validated Procedure**

```sql
CREATE OR REPLACE PROCEDURE `curso-bigquery-490113.belleza_verde_lib.inclui_qty`(
  p_id_produto INT64,
  p_id_cliente INT64,
  p_data DATE,
  p_quantidade INT64,
  p_preco FLOAT64
)
BEGIN

  -- Declaring internal evaluation states
  DECLARE v_id_venda INT64;
  DECLARE v_quantidade_valida BOOL DEFAULT FALSE;
  DECLARE v_message_text STRING;

  -- Validating internal input boundaries (Accepts only 1 to 99 units)
  SET v_quantidade_valida = (p_quantidade > 0 AND p_quantidade < 100);

  -- Conditional execution branch based on validation results
  IF v_quantidade_valida THEN
    BEGIN
      -- Calculates the next sequential ID (IFNULL fallback handles empty tables)
      SET v_id_venda = (
        SELECT IFNULL(MAX(id_venda), 0) + 1
        FROM `curso-bigquery-490113.belleza_verde_vendas.vendas`
      );

      -- Commits clean operational record into the sales table
      INSERT INTO `curso-bigquery-490113.belleza_verde_vendas.vendas`
        (id_venda, id_produto, id_cliente, data, quantidade, preco)
      VALUES
        (v_id_venda, p_id_produto, p_id_cliente, p_data, p_quantidade, p_preco);
    END;
  ELSE
    BEGIN
      -- Rejects insertion and triggers standard console warning message
      SET v_message_text = 'error: the quantity need to be bigger than 0 and smaller than 100.';
      SELECT v_message_text AS message;
    END;
  END IF;

END;
```

---

##### **Step 2: Testing and Homologation**

**Scenario A:** Valid entry (Succeeds silently and populates next ID)
```sql
CALL `curso-bigquery-490113.belleza_verde_lib.inclui_qty`(1, 1, '2026-05-19', 50, 10.5);
```
**Scenario B:** Invalid entry (Aborts transaction and throws custom error message)

```sql
CALL `curso-bigquery-490113.belleza_verde_lib.inclui_qty`(1, 1, '2026-05-19', 150, 10.5);
```

#### **2.7 Practice Challenge: Multi-Layer Business Rule and Data Integrity Validation (`register_sales`)**

To enforce data quality at the ingestion level by cross-referencing operational input parameters against relational dimension tables, isolating execution paths, and dynamically compounding validation errors.

##### **Architectural Benefits:**
* **Relational Cross-Referencing:** Verifies entity existence (`produtos` and `clientes`) prior to committing transactions.
* **Price Ingestion Security:** Automatically fetches active pricing directly from the catalog database, eliminating parameter tampering risks.
* **Error Aggregation Framework:** Collects and isolates independent logical failures, appending error logs seamlessly via concatenation instead of short-circuiting execution.

---

##### **Step 1: Writing the Multi-Layer Validated Procedure**

```sql
CREATE OR REPLACE PROCEDURE `curso-bigquery-490113.belleza_verde_lib.register_sales`(
  p_id_produto INT64,
  p_id_cliente INT64,
  p_data DATE,
  p_quantidade INT64
)
BEGIN

  -- STEP 1: Memory variables allocation
  DECLARE v_id_venda INT64;
  DECLARE v_quantidade_valida BOOL DEFAULT FALSE;
  DECLARE v_produto_existe BOOL DEFAULT FALSE;
  DECLARE v_cliente_existe BOOL DEFAULT FALSE;
  DECLARE v_preco_produto FLOAT64;
  DECLARE v_message_text STRING;

  -- STEP 2: Input Rules Validation
  SET v_quantidade_valida = (p_quantidade > 0 AND p_quantidade < 100);

  -- STEP 2.1: Check if product exists in database
  SET v_produto_existe = (
    SELECT EXISTS (SELECT 1 FROM `curso-bigquery-490113.belleza_verde_vendas.produtos` WHERE id_produto = p_id_produto)
  );  
  
  -- STEP 2.2: Check if client exists in database
  SET v_cliente_existe = (
    SELECT EXISTS (SELECT 1 FROM `curso-bigquery-490113.belleza_verde_vendas.clientes` WHERE id_cliente = p_id_cliente)
  ); 

  -- STEP 2.3: Fetch the product price to validate or override input price
  SET v_preco_produto = (
    SELECT po.preco FROM `curso-bigquery-490113.belleza_verde_vendas.produtos` AS po WHERE po.id_produto = p_id_produto
  );

  -- STEP 3: Conditional Decision Tree (IF / ELSE)
  IF v_quantidade_valida AND v_produto_existe AND v_cliente_existe THEN
    BEGIN
      SET v_id_venda = (
        SELECT IFNULL(MAX(id_venda), 0) + 1
        FROM `curso-bigquery-490113.belleza_verde_vendas.vendas`
      );

      INSERT INTO `curso-bigquery-490113.belleza_verde_vendas.vendas`
        (id_venda, id_produto, id_cliente, data, quantidade, preco)
      VALUES
        (v_id_venda, p_id_produto, p_id_cliente, p_data, p_quantidade, v_preco_produto);

      SELECT 'success: sale registered successfully!' AS message;
    END;
  ELSE
    BEGIN
      -- STEP 4: Diagnosing the Specific Error
      SET v_message_text = 'error: ';

      IF NOT v_quantidade_valida THEN
        SET v_message_text = CONCAT(v_message_text, '[invalid quantity] ');
      END IF; 

      IF NOT v_produto_existe THEN
        SET v_message_text = CONCAT(v_message_text, '[product not found] ');
      END IF; 

      IF NOT v_cliente_existe THEN
        SET v_message_text = CONCAT(v_message_text, '[client not found] ');
      END IF; 

      SELECT v_message_text AS message;
    END;
  END IF; 
END;
```

---

##### **Step 2: Testing and Homologation Scenarios**

```sql
-- Scenario A: Clean insertion (Valid rules, auto-assigns next ID and catalog price)
CALL `curso-bigquery-490113.belleza_verde_lib.register_sales`(1, 1, '2026-05-20', 10);
```

```sql
-- Scenario B: Compounded failure (Invalid quantity and non-existent entity IDs)
CALL `curso-bigquery-490113.belleza_verde_lib.register_sales`(9999, 8888, '2026-05-20', 250);
```

### **3. User-Defined Functions (UDFs)**

UDFs allow you to extend BigQuery SQL by creating custom functions using SQL expressions or JavaScript code. They are ideal for reusable calculations and complex logic that standard SQL functions cannot handle natively.

#### **3.1 SQL vs. JavaScript UDFs**
*   **SQL UDFs:** Optimized for performance; the BigQuery engine can optimize the logic directly.
*   **JavaScript UDFs:** Allow complex logic (loops, regex, JSON parsing) using the V8 engine, but consume more slot resources.

#### **3.2 Persistent vs. Temporary**
*   **Temporary:** Defined within a single script/query. Expires when the session ends.
*   **Persistent:** Stored in a dataset and can be reused by any authorized user across the project.

---

##### **Example: Creating a Persistent SQL UDF (Category Tiering)**

```sql
CREATE OR REPLACE FUNCTION `belleza_verde_lib.get_customer_tier`(revenue FLOAT64) 
RETURNS STRING AS (
  CASE 
    WHEN revenue > 5000 THEN 'Platinum'
    WHEN revenue > 2000 THEN 'Gold'
    ELSE 'Silver'
  END
);
```
#### **3.3 Practice Challenge: Custom Mathematical Randomization Engine (`aleatorio`)**

To engineer a persistent SQL-based custom function that overrides BigQuery's standard `RAND()` constraints, forcing the generation of bounded random integers within a strict user-defined dynamic range (`min` and `max`).

##### **Architectural Benefits:**
* **Constraint Overriding:** Translates continuous floating-point decimals ($0 \le x < 1$) into discrete, controlled integer distributions.
* **Mathematical Precision:** Employs the `FLOOR` function to truncate trailing decimals, guaranteeing uniform probability boundaries.
* **Global Reusability:** Functions as a centralized micro-service utility inside the `lib` dataset, eliminating the need to repeat heavy casting math across analytical dashboards.

---

##### **Step 1: Writing the Bounded Randomization Function**

```sql
CREATE OR REPLACE FUNCTION `curso-bigquery-490113.belleza_verde_lib.random_int`(
  min INT64, 
  max INT64
) 
RETURNS INT64 AS (
  CAST(FLOOR((RAND() * (max - min + 1))) AS INT64) + min
);
```

---

##### **Step 2: Testing and Practical Implementation**

```sql
-- Scenario A: Simulating a dynamic marketing coupon between 5% and 30% for active clients
SELECT 
  id_cliente,
  `curso-bigquery-490113.belleza_verde_lib.random_int`(5, 30) AS personalized_coupon_percentage
FROM `curso-bigquery-490113.belleza_verde_vendas.clientes`
LIMIT 5;
```

#### **3.4 Operational Use Cases for Bounded Randomization in Data Engineering**

While generating random boundaries may seem like a purely mathematical exercise, custom randomization engines are critical assets in modern data platforms. Below are the primary real-world architectures where the `aleatorio` UDF is applied:

##### **1. Production Data Mocking (Environment De-identification)**
Before launching a new analytical dashboard or staging environment, data engineers often need large volumes of transactional logs to test system latency and visualization layouts. 
* **Application:** By using the UDF, you can synthesize thousands of fake orders, assigning random product IDs, customer IDs, and quantities to populate sandbox tables instantly without exposing sensitive or compliance-restricted live consumer records.

##### **2. Business Gamification & Real-Time Dynamic Ingestion**
Modern e-commerce applications use the database layer to securely compute promotional rewards at the exact moment a transaction is finalized (e.g., dynamic loyalty points or "spin-the-wheel" app features).
* **Application:** Triggering the UDF directly within an ingestion query ensures that the reward assignment happens under strict database encryption and integrity rules, completely preventing malicious users from reverse-engineering the application's front-end code to manipulate or force maximum payouts.

##### **3. Controlled A/B Testing & Data Sampling (Feature Flagging)**
When data science teams want to test a new pricing algorithm, product recommendation model, or interface design, they must split user traffic into perfectly balanced, unbiased cohorts (Group A vs. Group B).
* **Application:** By executing the random function over active customer lists, the engine tags each record with a dynamic integer identifier. If the UDF returns `1`, the customer routes to the control group; if it returns `2`, they route to the variant group, ensuring a uniform and statistically valid distribution.

#### **3.5 Advanced Integration: Embedding UDFs Inside Stored Procedures**

This section details the consolidation of your custom Persistent SQL UDF (random_int) directly inside the transactional orchestration logic of the Stored Procedure (register_sales). 

Instead of relying on external scripts or hardcoded inputs, the procedure acts as a **fully automated transaction simulator**. It dynamically queries dimension table boundaries at runtime, feeds them into the UDF, and attempts to log randomized sales entries to generate synthetic mock data for downstream analytics training.

##### Architectural Benefits:
* **Encapsulated Automation:** The procedure becomes entirely self-contained, requiring only metadata fields (p_data, p_quantidade) to operate.
* **Hybrid Structural Security:** Even though data generation is randomized, the embedded validation shield (v_produto_existe and v_cliente_existe) remains active to capture any reference gaps or dead IDs before writing to the database.
* **Granular Traceability:** Success logs dynamically return the exact randomized IDs deployed inside the isolated execution block.

---

##### Production DDL Definition:

```sql
CREATE OR REPLACE PROCEDURE `curso-bigquery-490113.belleza_verde_lib.register_sales`(
  p_data DATE,
  p_quantidade INT64
)
BEGIN

  -- STEP 1: Memory variables allocation
  DECLARE v_id_venda INT64;
  DECLARE v_produto_existe BOOL DEFAULT FALSE;
  DECLARE v_cliente_existe BOOL DEFAULT FALSE;
  DECLARE v_preco_produto FLOAT64;
  DECLARE v_message_text STRING;
  DECLARE v_min_produto INT64;
  DECLARE v_max_produto INT64;
  DECLARE v_min_cliente INT64;
  DECLARE v_max_cliente INT64;
  DECLARE v_id_produto_final INT64;
  DECLARE v_id_cliente_final INT64;

  -- STEP 1.1: Generate Random Product ID directly using your UDF
  SET v_min_produto = (SELECT MIN(id_produto) FROM `curso-bigquery-490113.belleza_verde_vendas.produtos`);
  SET v_max_produto = (SELECT MAX(id_produto) FROM `curso-bigquery-490113.belleza_verde_vendas.produtos`);
  SET v_id_produto_final = (`curso-bigquery-490113.belleza_verde_lib.random_int`(v_min_produto, v_max_produto));

  -- STEP 1.2: Generate Random Client ID directly using your UDF
  SET v_min_cliente = (SELECT MIN(id_cliente) FROM `curso-bigquery-490113.belleza_verde_vendas.clientes`);
  SET v_max_cliente = (SELECT MAX(id_cliente) FROM `curso-bigquery-490113.belleza_verde_vendas.clientes`);
  SET v_id_cliente_final = (`curso-bigquery-490113.belleza_verde_lib.random_int`(v_min_cliente, v_max_cliente));

  -- STEP 2: Validation Shield
  -- STEP 2.1: Check if product exists in database (validation shield)
  SET v_produto_existe = (
    SELECT EXISTS (SELECT 1 FROM `curso-bigquery-490113.belleza_verde_vendas.produtos` WHERE id_produto = v_id_produto_final)
  );  
  
  -- STEP 2.2: Check if client exists in database (validation shield)
  SET v_cliente_existe = (
    SELECT EXISTS (SELECT 1 FROM `curso-bigquery-490113.belleza_verde_vendas.clientes` WHERE id_cliente = v_id_cliente_final)
  ); 

  -- STEP 2.3: Fetch the product price dynamically for the randomized product
  SET v_preco_produto = (
    SELECT po.preco FROM `curso-bigquery-490113.belleza_verde_vendas.produtos` AS po WHERE po.id_produto = v_id_produto_final
  );

  -- STEP 3: Conditional Decision Tree (IF / ELSE)
  IF v_produto_existe AND v_cliente_existe THEN
    BEGIN
      SET v_id_venda = (
        SELECT IFNULL(MAX(id_venda), 0) + 1
        FROM `curso-bigquery-490113.belleza_verde_vendas.vendas`
      );

      INSERT INTO `curso-bigquery-490113.belleza_verde_vendas.vendas`
        (id_venda, id_produto, id_cliente, data, quantidade, preco)
      VALUES
        (v_id_venda, v_id_produto_final, v_id_cliente_final, p_data, p_quantidade, v_preco_produto);

      SELECT CONCAT('success: sale registered successfully! [Product ID used: ', CAST(v_id_produto_final AS STRING), ' | Client ID used: ', CAST(v_id_cliente_final AS STRING), ']') AS message;
    END;
  ELSE
    BEGIN
      -- STEP 4: Diagnosing the Specific Error
      SET v_message_text = 'error: ';

      IF NOT v_produto_existe THEN
        SET v_message_text = CONCAT(v_message_text, '[product not found: ', CAST(v_id_produto_final AS STRING), '] ');
      END IF; 

      IF NOT v_cliente_existe THEN
        SET v_message_text = CONCAT(v_message_text, '[client not found: ', CAST(v_id_cliente_final AS STRING), '] ');
      END IF; 

      SELECT v_message_text AS message;
    END;
  END IF; 
END;
```
---

##### **Execution and Verification:**

To execute a single simulation and dynamically append a randomized sale transaction to your training pipeline, issue the following standard query execution block:

```sql
CALL `curso-bigquery-490113.belleza_verde_lib.register_sales`('2026-05-26', 15);
```

### **4. Cost Enrichment and Analytical Calculations**

Adding financial dimensions to your existing data models allows you to compute metrics directly inside BigQuery. By enriching structural reference tables with specific attributes, you can combine nested datasets with inventory values to dynamically calculate manufacturing costs and final prices.

#### **4.1 Index-Driven Array Alignment and Relational Joins**
* **Array Synchronization:** Using window functions like ROW_NUMBER() allows you to pair independent arrays line-by-line, creating an artificial relational structure between independent lists.
* **Data Type Standardization:** When handling unstructured array values, explicit type conversions (such as CAST) are required to safely bridge the data into structured formats for relational INNER JOIN operations.
* **Integrated Pipeline Logic:** This analytical model works in tandem with data generation structures, allowing you to extract cost valuations and total pricing metrics dynamically.

---

#### **4.2 Analytical Pricing Query DDL**

```sql
WITH indexed_products AS (
  SELECT
    id_produto,
    nome,
    categoria,
    preco,
    ARRAY(
      SELECT AS STRUCT raw_mat, ROW_NUMBER() OVER() AS idx
      FROM UNNEST(materiasprimas) AS raw_mat
    ) AS raw_material_index,
    ARRAY(
      SELECT AS STRUCT dist, ROW_NUMBER() OVER() AS idx
      FROM UNNEST(distribuicao) AS dist
    ) AS distribution_index
  FROM `curso-bigquery-490113.belleza_verde_vendas.produtos` AS p
  WHERE id_produto = 1
),

product_distribution AS (
  SELECT
    mat.raw_mat AS material_id,
    dst.dist AS material_distribution,
    m.custo AS material_cost
  FROM indexed_products AS ip
  CROSS JOIN UNNEST(ip.raw_material_index) AS mat
  CROSS JOIN UNNEST(ip.distribution_index) AS dst
  INNER JOIN `curso-bigquery-490113.belleza_verde_vendas.materiasprimas` AS m
    ON CAST(mat.raw_mat AS INT64) = m.id_materia
  WHERE mat.idx = dst.idx
)

SELECT
  SUM(pd.material_distribution * pd.material_cost) AS total_price
FROM product_distribution AS pd;
```

#### **4.3 End-to-End Orchestration: The Automated Sales Procedure**
* **Dynamic Variable Ingestion:** Integrating the cost-calculation CTE inside an executable procedural block requires assigning query outputs directly into memory indicators using scoped scalar assignments.
* **Fallback Pricing Logic:** By implementing standard conditional branches (IF/ELSE), the transaction logic evaluates the raw baseline product catalog price against the dynamically derived manufacturing cost (plus a predefined profit margin threshold), picking the optimal commercial value.
* **Atomic Transaction Integrity:** Combining analytical array conversions, external UDF calls, and relational validations inside a single execution block ensures that database mutation events (INSERT statements) only persist when data integrity parameters are fully satisfied.

---

#### **Automated Transaction Execution DDL**

```sql
CREATE OR REPLACE PROCEDURE `curso-bigquery-490113.belleza_verde_lib.register_sales`(
  p_data DATE,
  p_quantidade INT64, 
  margin INT64
)
BEGIN

  -- STEP 1: Memory variables allocation
  DECLARE v_id_venda INT64;
  DECLARE v_produto_existe BOOL DEFAULT FALSE;
  DECLARE v_cliente_existe BOOL DEFAULT FALSE;
  DECLARE v_preco_produto FLOAT64;

  DECLARE v_preco_produto_tb FLOAT64;
  DECLARE v_preco_produto_mp FLOAT64;
  
  DECLARE v_message_text STRING;
  DECLARE v_min_produto INT64;
  DECLARE v_max_produto INT64;
  DECLARE v_min_cliente INT64;
  DECLARE v_max_cliente INT64;
  DECLARE v_id_produto_final INT64;
  DECLARE v_id_cliente_final INT64;

  -- STEP 1.1: Generate Random Product ID directly using your UDF
  SET v_min_produto = (SELECT MIN(id_produto) FROM `curso-bigquery-490113.belleza_verde_vendas.produtos`);
  SET v_max_produto = (SELECT MAX(id_produto) FROM `curso-bigquery-490113.belleza_verde_vendas.produtos`);
  SET v_id_produto_final = (`curso-bigquery-490113.belleza_verde_lib.random_int`(v_min_produto, v_max_produto));

  -- STEP 1.2: Generate Random Client ID directly using your UDF
  SET v_min_cliente = (SELECT MIN(id_cliente) FROM `curso-bigquery-490113.belleza_verde_vendas.clientes`);
  SET v_max_cliente = (SELECT MAX(id_cliente) FROM `curso-bigquery-490113.belleza_verde_vendas.clientes`);
  SET v_id_cliente_final = (`curso-bigquery-490113.belleza_verde_lib.random_int`(v_min_cliente, v_max_cliente));

  -- STEP 2: Validation Shield
  -- STEP 2.1: Check if product exists in database (validation shield)
  SET v_produto_existe = (
    SELECT EXISTS (SELECT 1 FROM `curso-bigquery-490113.belleza_verde_vendas.produtos` WHERE id_produto = v_id_produto_final)
  );  
  
  -- STEP 2.2: Check if client exists in database (validation shield)
  SET v_cliente_existe = (
    SELECT EXISTS (SELECT 1 FROM `curso-bigquery-490113.belleza_verde_vendas.clientes` WHERE id_cliente = v_id_cliente_final)
  ); 

  -- STEP 2.3: Fetch the product price dynamically for the randomized product
  SET v_preco_produto_tb = (
    SELECT po.preco FROM `curso-bigquery-490113.belleza_verde_vendas.produtos` AS po WHERE po.id_produto = v_id_produto_final
  );

  -- STEP 2.4: Execute financial cost CTE and encapsulate the scalar result using SET
  SET v_preco_produto_mp = (
    WITH indexed_products AS (
      SELECT
        id_produto,
        ARRAY(
          SELECT AS STRUCT CAST(raw_mat AS INT64) AS raw_mat, ROW_NUMBER() OVER() AS idx
          FROM UNNEST(materiasprimas) AS raw_mat
        ) AS raw_material_index,
        ARRAY(
          SELECT AS STRUCT CAST(dist AS FLOAT64) AS dist, ROW_NUMBER() OVER() AS idx
          FROM UNNEST(distribuicao) AS dist
        ) AS distribution_index
      FROM `curso-bigquery-490113.belleza_verde_vendas.produtos` AS p
      WHERE id_produto = v_id_produto_final
    ), 
    product_distribution AS (
      SELECT
        mat.raw_mat AS material_id,
        dst.dist AS material_distribution,
        m.custo AS material_cost
      FROM indexed_products AS ip
      CROSS JOIN UNNEST(ip.raw_material_index) AS mat
      CROSS JOIN UNNEST(ip.distribution_index) AS dst
      INNER JOIN `curso-bigquery-490113.belleza_verde_vendas.materiasprimas` AS m
        ON mat.raw_mat = m.id_materia
      WHERE mat.idx = dst.idx
    )
    SELECT IFNULL(SUM(CAST(pd.material_distribution AS FLOAT64) * CAST(pd.material_cost AS FLOAT64)), 0.0)
    FROM product_distribution AS pd
  );

  -- STEP 2.5: Evaluate base threshold first (Compare raw cost vs raw table price)
  IF v_preco_produto_mp >= v_preco_produto_tb THEN 
    SET v_preco_produto = v_preco_produto_mp;
  ELSE 
    SET v_preco_produto = v_preco_produto_tb;
  END IF;

  -- STEP 2.6: Apply the profit margin dynamically and round to 2 decimal places
  SET v_preco_produto = ROUND(v_preco_produto * (1.0 + (CAST(margin AS FLOAT64) / 100.0)), 2);

  -- STEP 3: Conditional Decision Tree (IF / ELSE)
  IF v_produto_existe AND v_cliente_existe THEN
    BEGIN
      SET v_id_venda = (
        SELECT IFNULL(MAX(id_venda), 0) + 1
        FROM `curso-bigquery-490113.belleza_verde_vendas.vendas`
      );

      INSERT INTO `curso-bigquery-490113.belleza_verde_vendas.vendas`
        (id_venda, id_produto, id_cliente, data, quantidade, preco)
      VALUES
        (v_id_venda, v_id_produto_final, v_id_cliente_final, p_data, p_quantidade, v_preco_produto);

      SELECT CONCAT('success: sale registered successfully! [Product ID used: ', CAST(v_id_produto_final AS STRING), ' | Price applied (with margin): ', CAST(v_preco_produto AS STRING), ']') AS message;
    END;
  ELSE
    BEGIN
      -- STEP 4: Diagnosing the Specific Error
      SET v_message_text = 'error: ';

      IF NOT v_produto_existe THEN
        SET v_message_text = CONCAT(v_message_text, '[product not found: ', CAST(v_id_produto_final AS STRING), '] ');
      END IF; 

      IF NOT v_cliente_existe THEN
        SET v_message_text = CONCAT(v_message_text, '[client not found: ', CAST(v_id_cliente_final AS STRING), '] ');
      END IF; 

      SELECT v_message_text AS message;
    END;
  END IF; 
END;
```  

### 5. Best Practices: When to Use and Avoid FOR Loops in BigQuery

While `FOR` loops are powerful tools for orchestration and automating procedural tasks, they should be used with caution in a cloud data warehouse like Google BigQuery. 

#### 5.1 The Anti-Pattern: Row-by-Row DML Operations
You should **avoid** using `FOR` loops to execute Data Manipulation Language (DML) commands—such as `DELETE`, `UPDATE`, or row-by-row `INSERT`—over large datasets. 

BigQuery is a columnar, analytical database optimized for processing massive amounts of data in **bulk**. When you wrap a `DELETE` or `UPDATE` statement inside a `FOR` loop, you force the engine to process data line-by-line, resulting in:
* **High Latency:** Opening and closing thousands of separate transactions instead of just one.
* **Quota Exhaustion:** Risking hitting BigQuery's daily DML concurrency and mutation limits.
* **Increased Costs:** Over-processing slots for repetitive, small queries.

**The "Supermarket" Analogy:**
Using a `FOR` loop to delete or insert rows one by one is like going to the supermarket to buy 10 items, but walking back and forth 10 times to bring only one item home on each trip. A bulk SQL statement (using `IN` or a `JOIN`) is like taking a shopping cart, loading all 10 items at once, and checking out in a single trip.

#### 5.2 Correct Bulk Alternative (The Efficient Way)
Instead of looping through dates or IDs to delete records, leverage set-based SQL logic using the `IN` clause:

```sql
-- ❌ BAD PRACTICE: Avoid looping to delete
FOR record IN (SELECT date FROM `project.dataset.dates_to_remove`)
DO
  DELETE FROM `project.dataset.sales` WHERE data = record.date;
END FOR;

--  GOOD PRACTICE: Perform a single bulk operation
DELETE FROM `project.dataset.sales`
WHERE data IN (SELECT date FROM `project.dataset.dates_to_remove`);
```

#### 5.3 When is a FOR Loop Appropriate?
`FOR` loops are highly welcomed when your goal is **Task Orchestration** or **Simulation**, rather than direct data manipulation:
* **Data Generation:** Simulating historical business records to create random test datasets (mock data).
* **Dynamic Exporting:** Looping through a list of table names to export each one into separate Google Cloud Storage buckets.
* **Procedures Execution:** Calling distinct analytical pipelines sequentially for a limited number of high-profile clients.