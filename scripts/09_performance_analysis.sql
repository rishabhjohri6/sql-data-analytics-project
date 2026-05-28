/*
===============================================================================
Performance Analysis (Year-over-Year, Month-over-Month)
===============================================================================
Purpose:
    - To measure the performance of products, customers, or regions over time.
    - For benchmarking and identifying high-performing entities.
    - To track yearly trends and growth.

SQL Functions Used:
    - LAG(): Accesses data from previous rows.
    - AVG() OVER(): Computes average values within partitions.
    - CASE: Defines conditional logic for trend analysis.
===============================================================================
*/

/* Analyze the yearly performance of products by comparing their sales 
to both the average sales performance of the product and the previous year's sales */
SELECT
    order_year,
    product_name,
    current_sales,
    AVG(current_sales) OVER(PARTITION BY product_name) AS avg_sales,
    current_sales - AVG(current_sales) OVER(PARTITION BY product_name) AS diff_avg,
    CASE
        WHEN current_sales - AVG(current_sales) OVER(PARTITION BY product_name) > 0 THEN 'Above Avg'
        WHEN current_sales - AVG(current_sales) OVER(PARTITION BY product_name) < 0 THEN 'Below Avg'
        ELSE 'Avg'
    END AS avg_change,
    previous_year_sales,
    current_sales - previous_year_sales AS diff_previous_year,
    CASE
        WHEN current_sales - previous_year_sales > 0 THEN 'Increase'
        WHEN current_sales - previous_year_sales < 0 THEN 'Decrease'
        ELSE 'No Change'
    END AS py_change,
    CASE
        WHEN previous_year_sales IS NOT NULL THEN CONCAT(ROUND(((current_sales-previous_year_sales)/previous_year_sales)*100,2),'%')
        ELSE 'n/a'
    END AS perc_change
FROM (
    SELECT
        YEAR(f.order_date) AS order_year,
        p.product_name,
        CAST(SUM(f.sales_amount) AS FLOAT) AS current_sales,
        CAST(LAG(SUM(f.sales_amount)) OVER (ORDER BY p.product_name, YEAR(f.order_date)) AS FLOAT) AS previous_year_sales
    FROM gold.fact_sales AS f
    LEFT JOIN gold.dim_products AS p
        ON f.product_key = p.product_key
    WHERE f.order_date IS NOT NULL
    GROUP BY YEAR(order_date), p.product_name
    ) AS t
