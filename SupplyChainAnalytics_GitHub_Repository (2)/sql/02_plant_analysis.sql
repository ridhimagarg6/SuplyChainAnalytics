USE supply_chain_analytics;

/* Plant-level orders and quantity, including plants with zero orders */
WITH plant_summary AS (
    SELECT
        pp.Plant_Code,
        COUNT(o.Order_ID) AS total_orders,
        COALESCE(SUM(o.Unit_quantity), 0) AS total_quantity
    FROM (SELECT DISTINCT Plant_Code FROM plant_ports) AS pp
    LEFT JOIN order_list AS o
        ON pp.Plant_Code = o.Plant_Code
    GROUP BY pp.Plant_Code
),
plant_analysis AS (
    SELECT
        Plant_Code,
        total_orders,
        total_quantity,
        ROUND(
            total_quantity * 100.0 /
            NULLIF(SUM(total_quantity) OVER (), 0), 2
        ) AS quantity_contribution_pct,
        DENSE_RANK() OVER (ORDER BY total_quantity DESC) AS plant_rank
    FROM plant_summary
)
SELECT *
FROM plant_analysis
ORDER BY plant_rank, Plant_Code;

/* Distinct products mapped to each plant */
SELECT
    pp.Plant_Code,
    COUNT(DISTINCT p.Product_ID) AS total_products
FROM plant_ports AS pp
LEFT JOIN products_per_plant AS p
    ON pp.Plant_Code = p.Plant_Code
GROUP BY pp.Plant_Code
ORDER BY total_products DESC;
