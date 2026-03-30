/*******************************************************************************
  BELLEZA VERDE - SALES & PRODUCT ANALYSIS
  Course: BigQuery Mastery
  Structure: 
    1. Basic Queries & Filtering
    2. Aggregations & Grouping
    3. Arrays & Structs (Nested Data)
    4. Advanced Flattening & Correlation
*******************************************************************************/

--------------------------------------------------------------------------------
-- SECTION 1: BASIC QUERIES & FILTERING
--------------------------------------------------------------------------------

-- Filtering customers by location and seller identifier
SELECT c.nome 
FROM `curso-bigquery-490113.belleza_verde_vendas.clientes` AS c
WHERE c.localizacao = 'Rio de Janeiro'
  AND c.id_vendedor = 4;

-- Filtering sales by calculated revenue (Standard Query)
SELECT id_venda, id_produto, id_cliente, data, (quantidade * preco) AS faturamento
FROM `curso-bigquery-490113.belleza_verde_vendas.vendas`
WHERE (quantidade * preco) >= 600
LIMIT 10;

-- Filtering using a Subquery for alias reuse
SELECT * FROM (
    SELECT id_venda, id_produto, id_cliente, data, (quantidade * preco) AS faturamento
    FROM `curso-bigquery-490113.belleza_verde_vendas.vendas`)
WHERE faturamento >= 600
LIMIT 10;

-- Filtering using a CTE (Common Table Expression) - Recommended for readability
WITH vendas_faturamento AS (
    SELECT id_venda, id_produto, id_cliente, data,
    (quantidade * preco) AS faturamento
    FROM `curso-bigquery-490113.belleza_verde_vendas.vendas`
)
SELECT *
FROM vendas_faturamento 
WHERE faturamento >= 600 
LIMIT 10;

--------------------------------------------------------------------------------
-- SECTION 2: AGGREGATIONS & GROUPING
--------------------------------------------------------------------------------

-- Statistical summary per product, customer, and year
SELECT 
  id_produto AS produto, 
  id_cliente AS cliente,
  EXTRACT(YEAR FROM data) AS year, 
  ROUND(SUM(quantidade * preco), 0) AS total_revenue,
  ROUND(MAX(quantidade * preco), 0) AS max_revenue,
  ROUND(AVG(quantidade * preco), 0) AS avg_revenue,
  ROUND(MIN(quantidade * preco), 0) AS min_revenue,
  COUNT(*) AS qty
FROM `curso-bigquery-490113.belleza_verde_vendas.vendas`
GROUP BY 1, 2, 3 -- Using position-based grouping
ORDER BY 3, 4 DESC;

-- Filtering grouped data using HAVING
SELECT 
  id_produto AS produto, 
  id_cliente AS cliente,
  EXTRACT(YEAR FROM data) AS year, 
  ROUND(SUM(quantidade * preco), 0) AS total_revenue
FROM `curso-bigquery-490113.belleza_verde_vendas.vendas`
GROUP BY 1, 2, 3
HAVING total_revenue >= 3000 
ORDER BY year, total_revenue DESC;

--------------------------------------------------------------------------------
-- SECTION 3: ARRAYS & STRUCTS (NESTED DATA)
--------------------------------------------------------------------------------

-- Consolidating yearly revenue into an ordered Array
SELECT
  produto, 
  cliente,
  ARRAY_AGG(total_revenue ORDER BY year) AS array_revenue
FROM (
  SELECT 
    id_produto AS produto, 
    id_cliente AS cliente,
    EXTRACT(YEAR FROM data) AS year, 
    ROUND(SUM(quantidade * preco), 0) AS total_revenue
  FROM `curso-bigquery-490113.belleza_verde_vendas.vendas`
  WHERE id_produto = 1 AND id_cliente = 1
  GROUP BY 1, 2, 3
)
GROUP BY 1, 2;

-- Navigation in nested structures using OFFSET (Zero-based indexing)
SELECT 
  result[OFFSET(0)].produto AS first_product,
  result[OFFSET(0)].array_revenue[OFFSET(0)] AS first_revenue_entry
FROM (
  SELECT [
    STRUCT (1 AS produto, 1 AS cliente, [3443.80, 1562.23] AS array_revenue),
    STRUCT (1 AS produto, 2 AS cliente, [3855.00, 2316.41] AS array_revenue) 
  ] AS result
);

--------------------------------------------------------------------------------
-- SECTION 4: FLATTENING (UNNESTING) DATA
--------------------------------------------------------------------------------

-- Deep Flattening: Accessing values within nested arrays
WITH array_sct AS (
  SELECT * FROM
  UNNEST ([
    STRUCT (1 AS produto, 1 AS cliente, [3443.79, 1562.22, 776.86] AS array_revenue),
    STRUCT (1 AS produto, 2 AS cliente, [3855.00, 2316.40, 1331.76] AS array_revenue)
  ])
)
SELECT produto, cliente, revenue
FROM array_sct, UNNEST(array_revenue) AS revenue;

-- Aggregating statistics from unnested arrays
WITH array_sct AS (
  SELECT * FROM
  UNNEST ([
    STRUCT (1 AS produto, 1 AS cliente, [3443.79, 1562.22, 776.86] AS array_revenue),
    STRUCT (1 AS produto, 2 AS cliente, [3855.00, 2316.40, 1331.76] AS array_revenue)
  ])
)
SELECT
  produto, cliente,
  SUM(revenue) AS total_revenue,
  AVG(revenue) AS avg_revenue
FROM array_sct, UNNEST(array_revenue) AS revenue
GROUP BY 1, 2;

--------------------------------------------------------------------------------
-- SECTION 5: ADVANCED CORRELATION (HANDLING MULTIPLE ARRAYS)
--------------------------------------------------------------------------------

/* WARNING: CARTESIAN PRODUCT RISK
   Unnesting two arrays simultaneously without correlation creates 
   incorrect combinations (N x M rows). 
*/
SELECT id_produto, id_materia, perc_dist
FROM `curso-bigquery-490113.belleza_verde_vendas.produtos`, 
UNNEST(materiasprimas) AS id_materia,
UNNEST(distribuicao) AS perc_dist;

-- SOLUTION A: THE "ROOT" METHOD (Using ROW_NUMBER and CTE)
-- Useful for understanding manual indexing and join logic.
WITH indexed_data AS (
  SELECT 
    id_produto, nome,
    ARRAY(SELECT AS STRUCT val, ROW_NUMBER() OVER() AS idx FROM UNNEST(materiasprimas) AS val) AS m_idx,
    ARRAY(SELECT AS STRUCT val, ROW_NUMBER() OVER() AS idx FROM UNNEST(distribuicao) AS val) AS d_idx
  FROM `curso-bigquery-490113.belleza_verde_vendas.produtos`
)
SELECT 
    ip.id_produto, 
    m.val AS id_materia, 
    d.val AS distribuicao_materia
FROM indexed_data ip
CROSS JOIN UNNEST(ip.m_idx) AS m
CROSS JOIN UNNEST(ip.d_idx) AS d
ON m.idx = d.idx;

-- SOLUTION B: THE MODERN METHOD (Using WITH OFFSET)
-- Best practice for BigQuery: cleaner and more efficient.
SELECT 
  id_produto, 
  id_materia,
  perc_dist AS distribuicao_materia
FROM 
  `curso-bigquery-490113.belleza_verde_vendas.produtos`,
  UNNEST(materiasprimas) AS id_materia WITH OFFSET AS pos1,
  UNNEST(distribuicao) AS perc_dist WITH OFFSET AS pos2
WHERE pos1 = pos2;

/*******************************************************************************
  SECTION 6: COMPLEX AGGREGATION & DATA TYPE ALIGNMENT
  Objective: Correlate multiple arrays, flatten them using index-pairing to 
             avoid Cartesian products, and perform an INNER JOIN with type casting.
*******************************************************************************/

-- STEP 1: Generate manual indexes for both arrays to ensure 1:1 correlation
WITH index_produtos AS (
  SELECT 
    id_produto, 
    nome, 
    categoria, 
    preco,
    -- Creates a helper STRUCT with the value and its position (idx)
    ARRAY(
      SELECT AS STRUCT mp, ROW_NUMBER() OVER() AS idx 
      FROM UNNEST(materiasprimas) AS mp
    ) AS materiaprima_index,
    -- Creates a matching helper STRUCT for distribution percentages
    ARRAY(
      SELECT AS STRUCT ds, ROW_NUMBER() OVER() AS idx 
      FROM UNNEST(distribuicao) AS ds
    ) AS distribuicao_index
  FROM `curso-bigquery-490113.belleza_verde_vendas.produtos`
),

-- STEP 2: Flatten arrays and pair them by their index (Avoiding Cartesian Product)
resultado_produto AS (
  SELECT 
    ip.id_produto, 
    ip.nome, 
    ip.categoria, 
    ip.preco, 
    mpUN.mp AS id_materia, 
    dsUN.ds AS distribuicao_materia
  FROM index_produtos ip
  CROSS JOIN UNNEST(ip.materiaprima_index) AS mpUN
  CROSS JOIN UNNEST(ip.distribuicao_index) AS dsUN
  -- Crucial: Join condition ensures Material[1] pairs with Distribution[1]
  ON mpUN.idx = dsUN.idx
)

-- STEP 3: Final Join with Raw Materials table using Type Casting
SELECT 
  rp.id_produto, 
  rp.nome AS product_name, 
  rp.categoria, 
  rp.preco, 
  rp.id_materia,
  mp.nome AS material_name,
  rp.distribuicao_materia
FROM resultado_produto rp 
INNER JOIN `curso-bigquery-490113.belleza_verde_vendas.materiasprimas` AS mp
  -- Resolving Type Mismatch: Casting id_materia from STRING/FLOAT to INT64
  ON CAST(rp.id_materia AS INT64) = mp.id_materia;

  --------------------------------------------------------------------------------
-- SECTION 7: BUSINESS INTELLIGENCE & GOAL TRACKING
--------------------------------------------------------------------------------

-- Query 7.1: Yearly Sales Summary by Seller and Product
WITH sales_by_seller_per_year AS (
    SELECT
      EXTRACT(YEAR FROM v.data) AS year,
      vd.nome AS seller_name,
      p.nome AS product_name,
      SUM(v.quantidade) AS qty
    FROM `curso-bigquery-490113.belleza_verde_vendas.vendas` AS v
    INNER JOIN `curso-bigquery-490113.belleza_verde_vendas.produtos` AS p
      ON v.id_produto = p.id_produto
    INNER JOIN `curso-bigquery-490113.belleza_verde_vendas.clientes` AS c
      ON v.id_cliente = c.id_cliente
    INNER JOIN `curso-bigquery-490113.belleza_verde_vendas.vendedores` AS vd
      ON c.id_vendedor = vd.id_vendedor
    GROUP BY ALL
    ORDER BY year
)
SELECT * FROM sales_by_seller_per_year;

-- Query 7.2: Target Tracking and Performance Ranking
-- Correlates sales with a 'metas' table to calculate attainment % and annual rank
WITH sales_by_seller_per_year AS (
    SELECT
      EXTRACT(YEAR FROM v.data) AS year,
      vd.id_vendedor,
      vd.nome AS seller_name,
      p.id_produto,
      p.nome AS product_name,
      SUM(v.quantidade) AS qty
    FROM `curso-bigquery-490113.belleza_verde_vendas.vendas` AS v
    INNER JOIN `curso-bigquery-490113.belleza_verde_vendas.produtos` AS p
      ON v.id_produto = p.id_produto
    INNER JOIN `curso-bigquery-490113.belleza_verde_vendas.clientes` AS c
      ON v.id_cliente = c.id_cliente
    INNER JOIN `curso-bigquery-490113.belleza_verde_vendas.vendedores` AS vd
      ON c.id_vendedor = vd.id_vendedor
    GROUP BY ALL
)
SELECT
  s.year,
  s.seller_name,
  s.product_name,
  s.qty,
  mt.quantidade_meta AS target_qty,
  ROUND(((s.qty - mt.quantidade_meta) / mt.quantidade_meta) * 100, 2) || '%' AS target_perc,
  CASE
    WHEN s.qty >= mt.quantidade_meta THEN "Above"
    ELSE "Below"
  END AS performance_seller,
  RANK() OVER (PARTITION BY s.year ORDER BY s.qty DESC) AS rank_seller
FROM sales_by_seller_per_year AS s
LEFT JOIN `curso-bigquery-490113.belleza_verde_vendas.metas` AS mt
  ON s.id_vendedor = mt.id_vendedor
  AND s.id_produto = mt.id_produto
  AND s.year = mt.ano;

--------------------------------------------------------------------------------
-- SECTION 8: REVENUE & CUSTOMER RANKING
--------------------------------------------------------------------------------

-- Query 8.1: Customer Invoicing Analysis (2021)
-- Calculates total revenue per customer based on quantity * price
WITH invoicing AS (
    SELECT
      EXTRACT(YEAR FROM v.data) AS year,
      c.nome AS customer,
      ROUND(SUM(v.quantidade * v.preco), 2) AS total_revenue
    FROM `curso-bigquery-490113.belleza_verde_vendas.vendas` AS v
    INNER JOIN `curso-bigquery-490113.belleza_verde_vendas.produtos` AS p
      ON v.id_produto = p.id_produto
    INNER JOIN `curso-bigquery-490113.belleza_verde_vendas.clientes` AS c
      ON v.id_cliente = c.id_cliente
    INNER JOIN `curso-bigquery-490113.belleza_verde_vendas.vendedores` AS vd
      ON c.id_vendedor = vd.id_vendedor
    WHERE EXTRACT(YEAR FROM v.data) = 2021
    GROUP BY ALL
)
SELECT * FROM invoicing;

-- Query 8.2: Daily Customer Ranking (Snapshot)
-- Identifies top customers by volume on a specific date using Window Functions
WITH total_sales AS (
    SELECT
      c.id_cliente,
      SUM(v.quantidade) AS qty
    FROM `curso-bigquery-490113.belleza_verde_vendas.vendas` AS v
    INNER JOIN `curso-bigquery-490113.belleza_verde_vendas.produtos` AS p
      ON v.id_produto = p.id_produto
    INNER JOIN `curso-bigquery-490113.belleza_verde_vendas.clientes` AS c
      ON v.id_cliente = c.id_cliente
    INNER JOIN `curso-bigquery-490113.belleza_verde_vendas.vendedores` AS vd
      ON c.id_vendedor = vd.id_vendedor
    WHERE v.data = '2021-01-01'
    GROUP BY ALL
)
SELECT
  *,
  RANK() OVER (ORDER BY qty DESC) AS ranking
FROM total_sales;

-- ##########################################################################
-- SECTION 9: TEXT NORMALIZATION (CASE SENSITIVITY)
-- Goal: Standardizing string casing for consistent data display and filtering.
-- ##########################################################################

SELECT 
  nome, 
  UPPER(nome) AS upper_name,   -- Converts to all caps
  LOWER(nome) AS lower_name,   -- Converts to all lowercase
  INITCAP(nome) AS initcap_name -- Capitalizes only the first letter of each word
FROM `curso-bigquery-490113.belleza_verde_vendas.clientes`
WHERE id_cliente IN (1, 8, 15, 17);

-- ##########################################################################
-- SECTION 10: STRING EXTRACTION (LEFT & RIGHT)
-- Goal: Extracting a fixed number of characters from the beginning or end of a string.
-- ##########################################################################

-- Extracting first 4 characters
SELECT 
  nome, 
  LEFT(nome, 4) AS short_code 
FROM `curso-bigquery-490113.belleza_verde_vendas.produtos` 
WHERE id_produto IN (3, 9);

-- Extracting last 8 characters
SELECT 
  categoria, 
  RIGHT(categoria, 8) AS category_suffix 
FROM `curso-bigquery-490113.belleza_verde_vendas.produtos` 
WHERE id_produto IN (5, 10);

-- ##########################################################################
-- SECTION 11: STRING TRIMMING & CLEANING
-- Goal: Removing unwanted spaces or specific characters from text.
-- ##########################################################################

-- Standard trimming (White spaces)
SELECT 
  nome, 
  LTRIM(nome) AS ltrim_space, -- Removes leading spaces
  RTRIM(nome) AS rtrim_space, -- Removes trailing spaces
  TRIM(nome) AS trim_both     -- Removes spaces from both sides
FROM `curso-bigquery-490113.belleza_verde_vendas.produtos` 
WHERE id_produto IN (7, 4);

-- Character-specific trimming
-- Note: LTRIM can remove specific symbols if provided as the second argument
SELECT 
  nome, 
  LTRIM(nome, "-") AS ltrim_hyphen 
FROM `curso-bigquery-490113.belleza_verde_vendas.produtos` 
WHERE id_produto = 1;

-- ##########################################################################
-- SECTION 12: DATA QUALITY CALCULATION & CONDITIONAL LOGIC
-- Goal: Using CASE WHEN to flag records that need data cleaning.
-- ##########################################################################

SELECT
  nome,
  CHAR_LENGTH(nome) AS original_size,
  CHAR_LENGTH(TRIM(nome)) AS trimmed_size,
  -- Calculating the difference to find hidden spaces
  CHAR_LENGTH(nome) - CHAR_LENGTH(TRIM(nome)) AS space_count,
  -- Classification logic based on character count
  CASE
    WHEN CHAR_LENGTH(nome) - CHAR_LENGTH(TRIM(nome)) > 0 THEN 'Character Problems'
    ELSE 'Characters OK'
  END AS quality_status
FROM `curso-bigquery-490113.belleza_verde_vendas.produtos`
WHERE id_produto IN (7, 4);

-- ##########################################################################
-- SECTION 13: BOOLEAN SEARCH FUNCTIONS (STARTS_WITH & ENDS_WITH)
-- Goal: Validating if strings follow a specific pattern (Returns TRUE/FALSE).
-- ##########################################################################

-- Checking if product name begins with "Óleo"
SELECT 
  nome, 
  STARTS_WITH(nome, 'Óleo') AS is_oil
FROM `curso-bigquery-490113.belleza_verde_vendas.produtos`
WHERE id_produto IN (3, 9);

-- Checking if category ends with "pessoais"
SELECT 
  categoria, 
  ENDS_WITH(categoria, 'pessoais') AS is_personal_care
FROM `curso-bigquery-490113.belleza_verde_vendas.produtos`
WHERE id_produto IN (5, 10);

-- ##########################################################################
-- SECTION 14: STRING CONCATENATION & NESTED CLEANING
-- Goal: Merging multiple columns or strings into a single value.
-- ##########################################################################

-- Basic Concatenation
SELECT 
  CONCAT(nome, ' | ', categoria) AS product_full_info
FROM `curso-bigquery-490113.belleza_verde_vendas.produtos`;

-- Advanced Concatenation with Nested Trimming
-- Note: Cleaning the name (removing hyphens and spaces) before merging with category
SELECT 
  CONCAT(TRIM(LTRIM(nome, ' - ')), ' - ', categoria) AS cleaned_description
FROM `curso-bigquery-490113.belleza_verde_vendas.produtos`;


-- ##########################################################################
-- SECTION 15: NESTED STRING MANIPULATION (INSTR + SUBSTRING + REPLACE)
-- Goal: Dynamically extracting and cleaning the first word of a product name.
-- ##########################################################################

SELECT
  nome,
  -- 1. Finding the position of the first space (after cleaning leading spaces)
  INSTR(LTRIM(nome), ' ') AS first_space_pos,
  
  -- 2. Dynamic Extraction & Cleaning:
  --    a. LTRIM: Removes leading spaces.
  --    b. INSTR: Finds where the first word ends.
  --    c. SUBSTRING: Cuts the text from the start to that space.
  --    d. REPLACE: Removes any hyphens found in that first word.
  REPLACE(
    SUBSTRING(LTRIM(nome), 1, INSTR(LTRIM(nome), ' ')), 
    '-', 
    ''
  ) AS cleaned_first_word

FROM `curso-bigquery-490113.belleza_verde_vendas.produtos`;

-- ##########################################################################
-- SECTION 16: ADVANCED DATA CLEANING (CTE + REGEX + DYNAMIC SUBSTRING)
-- Goal: Standardizing Postal Codes (CEPs) by extracting patterns and injecting hyphens.
-- ##########################################################################

WITH subquery_cleaning AS (
  SELECT
    cep,
    -- REGEXP_EXTRACT: Searches for the pattern with a hyphen OR 8 consecutive digits.
    -- The 'r' prefix indicates a "Raw String" (interprets Regex symbols literally).
    REGEXP_EXTRACT(cep, r'[0-9]{5}-[0-9]{3}|[0-9]{8}') AS cep_extract
  FROM
    `curso-bigquery-490113.belleza_verde_vendas.clientes`
)

SELECT
  cep,
  CASE
    -- When the extracted CEP has 8 digits (missing hyphen), we format it:
    WHEN REGEXP_CONTAINS(cep_extract, r'[0-9]{8}')
      THEN
        CONCAT(
          SUBSTRING(cep_extract, 1, 5), -- Extract the first 5 digits
          '-',                          -- Inject the hyphen
          SUBSTRING(cep_extract, 6)     -- Extract from the 6th character to the END
        )
    ELSE cep_extract -- If already formatted, keep as is
  END AS cep_final
FROM subquery_cleaning;