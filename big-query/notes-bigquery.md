# BigQuery Study Notes

## First Query: NYC CitiBike Analysis
- Accessed public datasets using the project ID: `bigquery-public-data`.
- Implemented subqueries and CTEs to calculate gender distribution percentages.
- **Key Takeaway:** Always filter for `NULL` or `unknown` values to avoid biased statistical analysis.

## Data Engineering Best Practices
- **CTEs (WITH clause):** Much more readable and maintainable than nested subqueries.
- **Formatting:** Using clear aliases (e.g., `AS qty`, `AS perc_gender`) makes the output user-friendly for stakeholders.