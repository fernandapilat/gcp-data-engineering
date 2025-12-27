/* In the Belleza Verde database, we want to identify all customers located in Rio de Janeiro whose seller identifier is 4. */

SELECT c.nome 
FROM `curso-bigquery-481720.belleza_verde_vendas.clientes` AS c
WHERE
  c.localizacao = 'Rio de Janeiro'
  AND c.id_vendedor = 4;

-- Standard query without using subqueries
SELECT id_venda, id_produto, id_cliente, data, (quantidade * preco) AS faturamento
FROM `curso-bigquery-481720.belleza_verde_vendas.vendas`
WHERE (quantidade * preco) >= 600
LIMIT 10;

-- Using a subquery
SELECT * FROM (
    SELECT id_venda, id_produto, id_cliente, data, (quantidade * preco) AS faturamento
    FROM `curso-bigquery-481720.belleza_verde_vendas.vendas`)
WHERE faturamento >= 600
LIMIT 10;

-- Using a CTE (Common Table Expression)
WITH vendas_faturamento AS
(
    SELECT id_venda, id_produto, id_cliente, data,
    (quantidade * preco) AS faturamento
    FROM `curso-bigquery-481720.belleza_verde_vendas.vendas`
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
FROM curso-bigquery-481720.belleza_verde_vendas.vendas
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
FROM `curso-bigquery-481720.belleza_verde_vendas.vendas`
GROUP BY 
  id_produto, 
  id_cliente,
  year 
HAVING
  SUM(quantidade * preco) >= 3000 AND MIN(quantidade * preco) <= 60
ORDER BY 
  year,
  total_revenue DESC;

