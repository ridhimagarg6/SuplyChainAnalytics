USE supply_chain_analytics;

/* Inspect table structures */
DESCRIBE order_list;
DESCRIBE freight_rates;
DESCRIBE wh_costs;
DESCRIBE wh_capacities;
DESCRIBE products_per_plant;
DESCRIBE vmi_customers;
DESCRIBE plant_ports;

/* Verify row counts */
SELECT 'order_list' AS table_name, COUNT(*) AS row_count FROM order_list
UNION ALL SELECT 'freight_rates', COUNT(*) FROM freight_rates
UNION ALL SELECT 'wh_costs', COUNT(*) FROM wh_costs
UNION ALL SELECT 'wh_capacities', COUNT(*) FROM wh_capacities
UNION ALL SELECT 'products_per_plant', COUNT(*) FROM products_per_plant
UNION ALL SELECT 'vmi_customers', COUNT(*) FROM vmi_customers
UNION ALL SELECT 'plant_ports', COUNT(*) FROM plant_ports;

/* Check important missing values */
SELECT
    SUM(Order_ID IS NULL) AS null_order_ids,
    SUM(Order_Date IS NULL) AS null_order_dates,
    SUM(Plant_Code IS NULL) AS null_plant_codes,
    SUM(Product_ID IS NULL) AS null_product_ids,
    SUM(Carrier IS NULL) AS null_carriers
FROM order_list;

/* Check order ID uniqueness */
SELECT COUNT(*) AS total_rows,
       COUNT(DISTINCT Order_ID) AS distinct_order_ids
FROM order_list;

/* Duplicate carrier/route combinations */
SELECT Carrier, orig_port_cd, dest_port_cd, COUNT(*) AS duplicate_count
FROM freight_rates
GROUP BY Carrier, orig_port_cd, dest_port_cd
HAVING COUNT(*) > 1
ORDER BY duplicate_count DESC;

/* Date coverage */
SELECT MIN(Order_Date) AS first_order_date,
       MAX(Order_Date) AS last_order_date,
       COUNT(DISTINCT Order_Date) AS distinct_order_dates
FROM order_list;
