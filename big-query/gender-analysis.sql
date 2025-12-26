/* ORIGINAL QUERY 
   Initial approach using nested subqueries.
*/

SELECT 
    gender,
    ROUND(qty / (SELECT COUNT(*) AS total FROM `bigquery-public-data.new_york_citibike.citibike_trips` WHERE tripduration IS NOT NULL AND gender != 'unknown') * 100, 2) || '%' AS perc_gender
FROM (
    SELECT 
        gender, 
        COUNT(*) AS qty 
    FROM `bigquery-public-data.new_york_citibike.citibike_trips` 
    WHERE tripduration IS NOT NULL 
    GROUP BY gender
);

------------------------------------------------------------------------------------------

/* OPTIMIZED QUERY (Refactored with CTEs)
   Improvements:
   - Readability: Logical steps are separated into named blocks (WITH clause).
   - Performance: The total count is calculated once, avoiding redundant scanning.
   - Maintainability: Filters and logic are centralized in the 'base_data' block.
*/

WITH base_data AS (
    SELECT 
        gender, 
        COUNT(*) AS qty 
    FROM `bigquery-public-data.new_york_citibike.citibike_trips` 
    WHERE tripduration IS NOT NULL AND gender != 'unknown'
    GROUP BY gender
),
total_count AS (
    SELECT SUM(qty) AS total FROM base_data
)

SELECT 
    gender,
    qty,
    ROUND(qty / (SELECT total FROM total_count) * 100, 2) || '%' AS perc_gender
FROM base_data
ORDER BY qty DESC;