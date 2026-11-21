/*
PROJECT: Supply Chain Analytics
DATABASE: supply_chain_analytics
DIALECT: MySQL 8.0+ (CTEs and window functions are used)

This is the organized working copy of the author's explore.sql.
The original upload is preserved unchanged as explore_original.sql.

READING THE FILE
1. Run sections in order after importing the seven source tables.
2. Each section begins with the business question and, where available,
   a finding observed during the analysis.
3. Findings are documented observations from the project work, not
   recalculated by this script. Re-run the query against your own database
   to validate them.
4. Exploratory/learning queries are retained where useful. Known invalid
   syntax or misleading logic is explicitly corrected or explained.
*/

CREATE DATABASE IF NOT EXISTS supply_chain_analytics;
USE supply_chain_analytics;

/* ============================================================ */
/* 00. DATABASE AND DATASET VALIDATION */
/* Business question: Is the expected database and source data available? */
/* Observed dataset: 7 tables; 12,865 rows in total. */
/* Per-table counts recorded during project work: */
/* order_list 9,215; freight_rates 1,540; wh_costs 19; */
/* wh_capacities 19; products_per_plant 2,036; */
/* vmi_customers 14; plant_ports 22. */
/* ============================================================ */

SELECT DATABASE();
SHOW TABLES;

SELECT 'order_list' AS table_name, COUNT(*) AS total_rows FROM order_list
UNION ALL
SELECT 'freight_rates', COUNT(*) FROM freight_rates
UNION ALL
SELECT 'wh_costs', COUNT(*) FROM wh_costs
UNION ALL
SELECT 'wh_capacities', COUNT(*) FROM wh_capacities
UNION ALL
SELECT 'products_per_plant', COUNT(*) FROM products_per_plant
UNION ALL
SELECT 'vmi_customers', COUNT(*) FROM vmi_customers
UNION ALL
SELECT 'plant_ports', COUNT(*) FROM plant_ports;

/* Inspect schemas before joining tables. */
DESCRIBE order_list;
DESCRIBE freight_rates;
DESCRIBE wh_costs;
DESCRIBE wh_capacities;
DESCRIBE products_per_plant;
DESCRIBE vmi_customers;
DESCRIBE plant_ports;

/* Check Order_ID completeness and uniqueness. */
SELECT
    COUNT(*) AS total_rows,
    COUNT(Order_ID) AS non_null_ids,
    COUNT(DISTINCT Order_ID) AS unique_ids
FROM order_list;


/* ============================================================ */
/* 01. ORDER AND PLANT OVERVIEW */
/* Business question: How are order records and ordered quantities */
/* distributed across plants? */
/* Observed finding: PLANT03 contributes 96.94% of recorded Unit_quantity. */
/* 12 plants in the 19-plant reporting set had no matching order records. */
/* Important: COUNT(*) is a count of rows/order records, not proven */
/* unique shipments. Quantity share is not capacity utilization. */
/* ============================================================ */

SELECT
    Plant_Code,
    COUNT(*) AS total_order_records
FROM order_list
GROUP BY Plant_Code
ORDER BY total_order_records DESC;

SELECT
    Plant_Code,
    SUM(Unit_quantity) AS total_quantity
FROM order_list
GROUP BY Plant_Code
ORDER BY total_quantity DESC;

SELECT
    Plant_Code,
    COUNT(*) AS total_order_records,
    SUM(Unit_quantity) AS total_quantity
FROM order_list
GROUP BY Plant_Code
ORDER BY total_quantity DESC;

SELECT
    Plant_Code,
    COUNT(*) AS total_order_records
FROM order_list
GROUP BY Plant_Code
HAVING COUNT(*) > 100
ORDER BY total_order_records DESC;

/* Quantity contribution by plant, using all order_list records as denominator. */
SELECT
    Plant_Code,
    COUNT(*) AS total_order_records,
    ROUND(
        COUNT(*) * 100.0 / (SELECT COUNT(*) FROM order_list),
        2
    ) AS order_record_percentage
FROM order_list
GROUP BY Plant_Code
ORDER BY order_record_percentage DESC;

/* Plants listed in plant_ports, including plants with no matching orders. */
SELECT
    p.Plant_Code,
    COUNT(o.Order_ID) AS total_order_records,
    COALESCE(SUM(o.Unit_quantity), 0) AS total_quantity
FROM plant_ports AS p
LEFT JOIN order_list AS o
    ON p.Plant_Code = o.Plant_Code
GROUP BY p.Plant_Code
ORDER BY total_quantity DESC
LIMIT 5;

/* Plant quantity share and rank across the plant_ports reporting set. */
WITH plant_summary AS (
    SELECT
        p.Plant_Code,
        COUNT(o.Order_ID) AS total_order_records,
        COALESCE(SUM(o.Unit_quantity), 0) AS total_quantity
    FROM plant_ports AS p
    LEFT JOIN order_list AS o
        ON p.Plant_Code = o.Plant_Code
    GROUP BY p.Plant_Code
),
plant_analysis AS (
    SELECT
        *,
        ROUND(
            total_quantity * 100.0 /
            NULLIF(SUM(total_quantity) OVER (), 0),
            2
        ) AS quantity_contribution_pct,
        DENSE_RANK() OVER (ORDER BY total_quantity DESC) AS plant_rank
    FROM plant_summary
)
SELECT *
FROM plant_analysis
ORDER BY plant_rank, Plant_Code;


/* ============================================================ */
/* 02. PLANT PRODUCT MAPPING */
/* Business question: Which plants have product mappings, and are any */
/* order rows unmatched to the plant-product mapping? */
/* ============================================================ */

/* Plants in orders that do not appear in products_per_plant. */
SELECT DISTINCT
    o.Plant_Code
FROM order_list AS o
LEFT JOIN products_per_plant AS p
    ON o.Plant_Code = p.Plant_Code
WHERE p.Plant_Code IS NULL;

/* Inspect order rows against a plant + product mapping. */
SELECT
    o.Order_ID,
    o.Plant_Code,
    o.Product_ID
FROM order_list AS o
LEFT JOIN products_per_plant AS p
    ON o.Plant_Code = p.Plant_Code
   AND o.Product_ID = p.Product_ID;

/* Order rows without a matching plant + product mapping. */
SELECT
    o.Order_ID,
    o.Plant_Code,
    o.Product_ID
FROM order_list AS o
LEFT JOIN products_per_plant AS p
    ON o.Plant_Code = p.Plant_Code
   AND o.Product_ID = p.Product_ID
WHERE p.Product_ID IS NULL;

/* Order rows with a matching plant + product mapping. */
SELECT
    o.Order_ID,
    o.Plant_Code,
    o.Product_ID
FROM order_list AS o
LEFT JOIN products_per_plant AS p
    ON o.Plant_Code = p.Plant_Code
   AND o.Product_ID = p.Product_ID
WHERE p.Product_ID IS NOT NULL;

/* Product assortment size per plant. */
SELECT
    p.Plant_Code,
    COUNT(DISTINCT o.Product_ID) AS total_products
FROM plant_ports AS p
LEFT JOIN products_per_plant AS o
    ON p.Plant_Code = o.Plant_Code
GROUP BY p.Plant_Code
ORDER BY total_products DESC
LIMIT 3;

WITH plant_summary AS (
    SELECT
        p.Plant_Code,
        COUNT(DISTINCT o.Product_ID) AS total_products
    FROM plant_ports AS p
    LEFT JOIN products_per_plant AS o
        ON p.Plant_Code = o.Plant_Code
    GROUP BY p.Plant_Code
)
SELECT
    Plant_Code,
    total_products,
    DENSE_RANK() OVER (ORDER BY total_products DESC) AS product_rank
FROM plant_summary
ORDER BY product_rank, Plant_Code;

/* Second-highest distinct product-count rank (ties are retained). */
WITH plant_summary AS (
    SELECT
        p.Plant_Code,
        COUNT(DISTINCT o.Product_ID) AS product_count
    FROM plant_ports AS p
    LEFT JOIN products_per_plant AS o
        ON p.Plant_Code = o.Plant_Code
    GROUP BY p.Plant_Code
),
ranked_plants AS (
    SELECT
        Plant_Code,
        product_count,
        DENSE_RANK() OVER (ORDER BY product_count DESC) AS ranking
    FROM plant_summary
)
SELECT Plant_Code, product_count, ranking
FROM ranked_plants
WHERE ranking = 2;


/* ============================================================ */
/* 03. CUSTOMER ANALYSIS */
/* Business question: Which customers account for the largest order */
/* quantities, and how concentrated is the customer base? */
/* Observed findings from project analysis: */
/* 46 distinct customers. */
/* Largest customer: V55555555_5, quantity 8,020,417 (27.18%). */
/* Top 5 customer shares: 27.18%, 17.94%, 6.49%, 6.47%, 5.12%. */
/* Top 9 customers together: 80.18% of recorded quantity. */
/* These are concentration findings, not evidence of customer risk by */
/* themselves. Customer segment thresholds below are exploratory choices. */
/* ============================================================ */

/* Customer order-record volume segmentation (thresholds are analyst-defined). */
WITH customer_summary AS (
    SELECT
        Customer,
        COUNT(*) AS total_order_records,
        CASE
            WHEN COUNT(*) > 500 THEN 'High Volume'
            WHEN COUNT(*) BETWEEN 200 AND 500 THEN 'Medium Volume'
            ELSE 'Low Volume'
        END AS customer_category
    FROM order_list
    GROUP BY Customer
)
SELECT
    customer_category,
    COUNT(*) AS number_of_customers
FROM customer_summary
GROUP BY customer_category
ORDER BY number_of_customers DESC;

/* Customer quantity segmentation (thresholds are analyst-defined). */
SELECT
    Customer,
    SUM(Unit_quantity) AS total_order_quantity,
    CASE
        WHEN SUM(Unit_quantity) > 500 THEN 'High'
        WHEN SUM(Unit_quantity) BETWEEN 200 AND 500 THEN 'Medium'
        ELSE 'Low'
    END AS customer_category
FROM order_list
GROUP BY Customer
ORDER BY total_order_quantity DESC;

/* Top-ranked customers within each plant. */
WITH customer_ranking AS (
    SELECT
        Plant_Code,
        Customer,
        SUM(Unit_quantity) AS total_quantity,
        DENSE_RANK() OVER (
            PARTITION BY Plant_Code
            ORDER BY SUM(Unit_quantity) DESC
        ) AS ranking
    FROM order_list
    GROUP BY Plant_Code, Customer
)
SELECT *
FROM customer_ranking
WHERE ranking <= 3
ORDER BY Plant_Code, ranking, Customer;

/* Customer contribution and overall rank. */
WITH customer_summary AS (
    SELECT
        Customer,
        COUNT(*) AS total_order_records,
        SUM(Unit_quantity) AS total_quantity
    FROM order_list
    GROUP BY Customer
),
customer_analysis AS (
    SELECT
        Customer,
        total_order_records,
        total_quantity,
        ROUND(
            total_quantity * 100.0 /
            NULLIF(SUM(total_quantity) OVER (), 0),
            2
        ) AS quantity_contribution_pct,
        DENSE_RANK() OVER (ORDER BY total_quantity DESC) AS customer_rank
    FROM customer_summary
)
SELECT *
FROM customer_analysis
ORDER BY customer_rank, Customer;

/* Pareto-style cumulative contribution by customer. */
WITH customer_summary AS (
    SELECT
        Customer,
        SUM(Unit_quantity) AS total_quantity
    FROM order_list
    GROUP BY Customer
),
customer_pareto AS (
    SELECT
        Customer,
        total_quantity,
        ROUND(
            SUM(total_quantity) OVER (
                ORDER BY total_quantity DESC
                ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
            ) * 100.0 /
            NULLIF(SUM(total_quantity) OVER (), 0),
            2
        ) AS cumulative_percentage
    FROM customer_summary
)
SELECT *
FROM customer_pareto
ORDER BY total_quantity DESC;


/* ============================================================ */
/* 04. DATA QUALITY AND DATE CHECKS */
/* Business question: Are carrier values missing, and what date range */
/* is represented in the order data? */
/* Observed limitation: all Order_Date values were found to be */
/* 2013-05-26 in the earlier audit. Therefore meaningful time trends */
/* cannot be inferred from this dataset as currently loaded. */
/* ============================================================ */

SELECT COUNT(*) AS missing_carrier_rows
FROM order_list
WHERE Carrier IS NULL;

SELECT
    Order_ID,
    Carrier,
    COALESCE(Carrier, 'Unknown') AS carrier_status
FROM order_list;

SELECT
    YEAR(Order_Date) AS order_year,
    COUNT(*) AS total_order_records
FROM order_list
GROUP BY YEAR(Order_Date);

/* Check for records after the observed date. */
SELECT *
FROM order_list
WHERE DATEDIFF(Order_Date, '2013-05-26') > 0;

SELECT
    DATE_FORMAT(Order_Date, '%b %Y') AS order_month,
    COUNT(*) AS total_order_records
FROM order_list
GROUP BY DATE_FORMAT(Order_Date, '%b %Y');

/* NOTE: Original exploratory LAG query attempted to use LAG() in WHERE. */
/* MySQL does not allow window functions directly in WHERE; calculate */
/* the window value in a CTE, then filter in the outer query. */
WITH order_lag AS (
    SELECT
        Plant_Code,
        Order_ID,
        Unit_quantity,
        LAG(Unit_quantity) OVER (
            PARTITION BY Plant_Code
            ORDER BY Order_ID
        ) AS previous_quantity
    FROM order_list
)
SELECT
    Plant_Code,
    Order_ID,
    Unit_quantity,
    previous_quantity,
    Unit_quantity - previous_quantity AS quantity_difference
FROM order_lag
WHERE previous_quantity IS NOT NULL
  AND Unit_quantity > previous_quantity
ORDER BY Plant_Code, Order_ID;


/* ============================================================ */
/* 05. PLANT CAPACITY AND COST CONTEXT */
/* Business question: Can order activity, product assortment, warehouse */
/* capacity and unit cost be viewed together for each plant? */
/* Caution: this is a joined comparison, not a utilization calculation. */
/* Utilization requires a comparable time period and a clearly defined */
/* throughput/capacity measure. Validate key uniqueness before joining. */
/* ============================================================ */

WITH order_summary AS (
    SELECT
        Plant_Code,
        COUNT(*) AS total_order_records,
        SUM(Unit_quantity) AS total_quantity
    FROM order_list
    GROUP BY Plant_Code
),
product_summary AS (
    SELECT
        Plant_Code,
        COUNT(DISTINCT Product_ID) AS total_products
    FROM products_per_plant
    GROUP BY Plant_Code
)
SELECT
    pp.Plant_Code,
    COALESCE(os.total_order_records, 0) AS total_order_records,
    COALESCE(os.total_quantity, 0) AS total_quantity,
    COALESCE(ps.total_products, 0) AS total_products,
    wc.Daily_Capacity,
    costs.Cost_unit
FROM (
    SELECT DISTINCT Plant_Code
    FROM plant_ports
) AS pp
LEFT JOIN order_summary AS os
    ON pp.Plant_Code = os.Plant_Code
LEFT JOIN product_summary AS ps
    ON pp.Plant_Code = ps.Plant_Code
LEFT JOIN wh_capacities AS wc
    ON pp.Plant_Code = wc.Plant_ID
LEFT JOIN wh_costs AS costs
    ON pp.Plant_Code = costs.WH
ORDER BY total_quantity DESC;


/* ============================================================ */
/* 06. FREIGHT RATE ANALYSIS */
/* Business question: How do freight rates vary by carrier, mode and route? */
/* Observed findings: */
/* freight_rates contains 1,540 rows. */
/* GROUND: 29 records, average rate 17.61 (min 6.42, max 128.03). */
/* AIR: 1,511 records, average rate 2.61 (min 0.03, max 18.96). */
/* Carrier V444_4 AIR: 906 records, average rate 3.79. */
/* Route/mode averages are not directly comparable without controlling */
/* for route, service code and weight bracket. */
/* ============================================================ */

/* Average/minimum/maximum rate by carrier and mode. */
SELECT
    Carrier,
    mode_dsc,
    COUNT(*) AS rate_records,
    ROUND(AVG(rate), 2) AS avg_freight_rate,
    ROUND(MIN(rate), 2) AS min_rate,
    ROUND(MAX(rate), 2) AS max_rate
FROM freight_rates
GROUP BY Carrier, mode_dsc
ORDER BY avg_freight_rate DESC;

/* Overall comparison by freight mode. */
SELECT
    mode_dsc,
    COUNT(*) AS total_rate_records,
    ROUND(AVG(rate), 2) AS average_rate,
    ROUND(MIN(rate), 2) AS minimum_rate,
    ROUND(MAX(rate), 2) AS maximum_rate
FROM freight_rates
GROUP BY mode_dsc
ORDER BY average_rate DESC;

/* Carrier/mode rate variability. Groups with fewer than 20 rows are excluded. */
SELECT
    Carrier,
    mode_dsc,
    COUNT(*) AS rate_records,
    ROUND(AVG(rate), 2) AS avg_rate,
    ROUND(STDDEV(rate), 2) AS rate_std_dev
FROM freight_rates
GROUP BY Carrier, mode_dsc
HAVING COUNT(*) >= 20
ORDER BY avg_rate DESC;

/* Highest-average routes with at least five rate records. */
SELECT
    orig_port_cd,
    dest_port_cd,
    mode_dsc,
    COUNT(*) AS rate_records,
    ROUND(AVG(rate), 2) AS avg_rate,
    ROUND(MIN(rate), 2) AS min_rate,
    ROUND(MAX(rate), 2) AS max_rate
FROM freight_rates
GROUP BY orig_port_cd, dest_port_cd, mode_dsc
HAVING COUNT(*) >= 5
ORDER BY avg_rate DESC
LIMIT 10;

/* Drill-down: PORT03 to PORT09, GROUND service. */
SELECT
    Carrier,
    svc_cd,
    minm_wgh_qty,
    max_wgh_qty,
    COUNT(*) AS rate_records,
    ROUND(AVG(rate), 2) AS avg_rate,
    ROUND(MIN(rate), 2) AS min_rate,
    ROUND(MAX(rate), 2) AS max_rate,
    ROUND(AVG(minimum_cost), 2) AS avg_minimum_cost
FROM freight_rates
WHERE orig_port_cd = 'PORT03'
  AND dest_port_cd = 'PORT09'
  AND mode_dsc = 'GROUND'
GROUP BY Carrier, svc_cd, minm_wgh_qty, max_wgh_qty
ORDER BY avg_rate DESC;

/* Inspect individual rate rows for the same route/mode. */
SELECT *
FROM freight_rates
WHERE orig_port_cd = 'PORT03'
  AND dest_port_cd = 'PORT09'
  AND mode_dsc = 'GROUND'
ORDER BY rate DESC;

/* Potential high-rate anomaly screen: deviation greater than 50 from */
/* the average for the same origin/destination/mode. */
/* This is a simple deviation screen, NOT a formal IQR/statistical test. */
WITH route_rates AS (
    SELECT
        Carrier,
        orig_port_cd,
        dest_port_cd,
        mode_dsc,
        rate,
        AVG(rate) OVER (
            PARTITION BY orig_port_cd, dest_port_cd, mode_dsc
        ) AS avg_rate
    FROM freight_rates
),
rate_deviation AS (
    SELECT
        *,
        rate - avg_rate AS deviation
    FROM route_rates
)
SELECT *
FROM rate_deviation
WHERE deviation > 50
ORDER BY deviation DESC;

/* Observed investigation note: */
/* PORT03 -> PORT09, GROUND, carrier V444_7 had one record at 128.0272. */
/* Route/mode average was approximately 17.7475; this is a potential */
/* anomaly to investigate, not proof of an incorrect rate. */
/* Other carrier groups on this route had substantially lower rates. */
/* Compare service code, weight range and minimum_cost before conclusions. */

/* End of organized analysis. */
