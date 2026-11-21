USE supply_chain_analytics;

/* Customer quantity and contribution */
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
            NULLIF(SUM(total_quantity) OVER (), 0), 2
        ) AS quantity_contribution_pct,
        DENSE_RANK() OVER (ORDER BY total_quantity DESC) AS customer_rank
    FROM customer_summary
)
SELECT *
FROM customer_analysis
ORDER BY customer_rank, Customer;

/* Cumulative Pareto contribution */
WITH customer_summary AS (
    SELECT Customer, SUM(Unit_quantity) AS total_quantity
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
            NULLIF(SUM(total_quantity) OVER (), 0), 2
        ) AS cumulative_percentage
    FROM customer_summary
)
SELECT *
FROM customer_pareto
ORDER BY total_quantity DESC;

/* Customer segmentation */
SELECT
    Customer,
    SUM(Unit_quantity) AS total_quantity,
    CASE
        WHEN SUM(Unit_quantity) > 500 THEN 'High'
        WHEN SUM(Unit_quantity) BETWEEN 200 AND 500 THEN 'Medium'
        ELSE 'Low'
    END AS customer_category
FROM order_list
GROUP BY Customer
ORDER BY total_quantity DESC;
