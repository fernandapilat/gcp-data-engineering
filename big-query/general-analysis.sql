/* In the Belleza Verde database, we want to identify all customers located in Rio de Janeiro whose seller identifier is 4. */

SELECT c.nome 
FROM `curso-bigquery-490113.belleza_verde_vendas.clientes` AS c
WHERE
  c.localizacao = 'Rio de Janeiro'
  AND c.id_vendedor = 4;

-- Standard query without using subqueries
SELECT id_venda, id_produto, id_cliente, data, (quantidade * preco) AS faturamento
FROM `curso-bigquery-490113.belleza_verde_vendas.vendas`
WHERE (quantidade * preco) >= 600
LIMIT 10;

-- Using a subquery
SELECT * FROM (
    SELECT id_venda, id_produto, id_cliente, data, (quantidade * preco) AS faturamento
    FROM `curso-bigquery-490113.belleza_verde_vendas.vendas`)
WHERE faturamento >= 600
LIMIT 10;

-- Using a CTE (Common Table Expression)
WITH vendas_faturamento AS
(
    SELECT id_venda, id_produto, id_cliente, data,
    (quantidade * preco) AS faturamento
    FROM `curso-bigquery-490113.belleza_verde_vendas.vendas`
)
SELECT id_venda, id_produto, id_cliente, data, faturamento
FROM vendas_faturamento 
WHERE faturamento >= 600 
LIMIT 10;

-- Grouping data with GROUP BY
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
GROUP BY 
  id_produto, 
  id_cliente,
  EXTRACT (YEAR FROM data)
ORDER BY 
  EXTRACT (YEAR FROM data),
  ROUND(SUM(quantidade * preco), 0) DESC;

-- Using HAVING to filter after grouping
-- Note: BigQuery allows using aliases (like 'year') in GROUP BY and HAVING clauses, 
-- but this behavior may vary in other SQL dialects.
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
GROUP BY 
  id_produto, 
  id_cliente,
  year 
HAVING
  SUM(quantidade * preco) >= 3000 AND MIN(quantidade * preco) <= 60
ORDER BY 
  year,
  total_revenue DESC;

-- Aggregating annual revenue into a nested array
-- This structure consolidates multiple yearly records into a single row per product/client

SELECT
  produto, 
  cliente,
  -- Aggregates total revenue into an ordered array by year
  ARRAY_AGG(total_revenue ORDER BY year) AS array_revenue
FROM (
  SELECT 
    id_produto AS produto, 
    id_cliente AS cliente,
    EXTRACT(YEAR FROM data) AS year, 
    -- Calculates annual revenue rounded to the nearest integer
    ROUND(SUM(quantidade * preco), 0) AS total_revenue
  FROM `curso-bigquery-490113.belleza_verde_vendas.vendas`
  WHERE
    id_produto = 1 AND id_cliente = 1
  GROUP BY produto, cliente, year
)
GROUP BY produto, cliente;

-- Checking the number of elements in an array of structs
-- Context: This is useful to count how many entities (like customers or products) 
-- are nested within a single record.
SELECT ARRAY_LENGTH(result) AS total_elements
FROM (
  SELECT [
    -- Each STRUCT represents a logical grouping of a product, customer, and their revenue history
    STRUCT (1 AS produto, 1 AS cliente, [3443.80, 1562.23, 776.86] AS array_revenue),
    STRUCT (1 AS produto, 2 AS cliente, [3855.00, 2316.41, 1331.76] AS array_revenue) 
  ] AS result
);

-- Navigating Deeply Nested Structures using OFFSET
SELECT 
  result[OFFSET(0)].produto AS product_first_line,
  result[OFFSET(0)].cliente AS customer_first_line,
  result[OFFSET(1)].cliente AS customer_second_line,
  result[OFFSET(0)].array_revenue[OFFSET(0)] AS revenue_21_first_line,
  result[OFFSET(1)].array_revenue[OFFSET(2)] AS revenue_23_second_line
FROM (SELECT [
    STRUCT (1 AS produto, 1 AS cliente, [3443.7999999999993, 1562.2299999999998, 776.86]
    AS array_revenue),
    STRUCT (1 AS produto, 2 AS cliente, [3855.0000000000005, 2316.4099999999994, 1331.76]
    AS array_revenue) 
] AS result);


-- Flattening an array of structs into individual rows
-- The UNNEST function expands the 'result' array, allowing us to access internal fields as columns
WITH array_sct AS (
  SELECT * FROM
  UNNEST ([
    STRUCT (1 AS produto, 1 AS cliente, [3443.79, 1562.22, 776.86] AS array_revenue),
    STRUCT (1 AS produto, 2 AS cliente, [3855.00, 2316.40, 1331.76] AS array_revenue)
  ])
)
SELECT * FROM array_sct;

-- Deep Flattening: Accessing values within nested arrays
-- By using a comma followed by UNNEST, we create a cross join between the main row and each element of 'array_revenue'
WITH array_sct AS (
  SELECT * FROM
  UNNEST ([
    STRUCT (1 AS produto, 1 AS cliente, [3443.79, 1562.22, 776.86] AS array_revenue),
    STRUCT (1 AS produto, 2 AS cliente, [3855.00, 2316.40, 1331.76] AS array_revenue)
  ])
)
SELECT
  produto,
  cliente,
  revenue -- The alias for the unnested array element
FROM array_sct, UNNEST(array_revenue) AS revenue;

-- Understanding basic UNNEST syntax for simple arrays
-- This command transforms a list of values (literal array) into a single column with multiple rows
SELECT * FROM UNNEST([3855.00, 2316.40, 1331.76]);

/* Advanced Analysis: Aggregating Unnested Data
   Context: Once data is unnested, we can calculate statistical metrics (SUM, MAX, MIN, AVG) 
   that were previously "trapped" inside the array structure. */
WITH array_sct AS (
  SELECT * FROM
  UNNEST ([
    STRUCT (1 AS produto, 1 AS cliente, [3443.79, 1562.22, 776.86] AS array_revenue),
    STRUCT (1 AS produto, 2 AS cliente, [3855.00, 2316.40, 1331.76] AS array_revenue)
  ])
)
SELECT
  produto,
  cliente,
  SUM(revenue) AS total_revenue,
  MAX(revenue) AS max_revenue,
  MIN(revenue) AS min_revenue,
  AVG(revenue) AS avg_revenue,
  COUNT(revenue) AS qty
FROM array_sct, UNNEST(array_revenue) AS revenue
GROUP BY 1, 2;

-- DANGER: Multiple UNNESTs and the Cartesian Product effect
-- When unnesting 'materiasprimas' and 'distribuicao' together, BigQuery 
-- crosses every material with every percentage, duplicating rows.
-- Example: 2 materials x 2 percentages = 4 rows (incorrect data duplication).
SELECT 
  id_produto,
  nome,
  categoria,
  preco,
  id_materia,
  perc_dist
FROM 
  `curso-bigquery-490113.belleza_verde_vendas.produtos`, 
  UNNEST(materiasprimas) AS id_materia,
  UNNEST(distribuicao) AS perc_dist;