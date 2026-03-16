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