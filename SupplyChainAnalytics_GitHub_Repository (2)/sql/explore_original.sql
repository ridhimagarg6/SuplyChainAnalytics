CREATE DATABASE supply_chain_analytics;

USE supply_chain_analytics;

SELECT DATABASE();
show tables;
select count(*) from order_list;

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

DESCRIBE order_list;
DESCRIBE freight_rates;
DESCRIBE wh_costs;
DESCRIBE wh_capacities;
DESCRIBE products_per_plant;
DESCRIBE vmi_customers;
DESCRIBE plant_ports;

select count(*) as total_rows, count(Order_ID) as non_null_ids,COUNT(DISTINCT Order_ID) AS unique_ids from order_list; 

select distinct o.Plant_Code from order_list as o left join products_per_plant as p on o.Plant_Code = p.Plant_Code
where p.Plant_Code is null;
select Plant_Code , count(*) as Total_orders from order_list group by Plant_Code order by Total_orders desc ;
select  Plant_Code , sum(Unit_quantity) as total_quantity from order_list group by Plant_Code order by total_quantity desc;
select Plant_Code , count(*) as total_orders, sum(Unit_quantity) as total_quantity from order_list group by Plant_code ;
select Plant_code, count(*)as total_orders from order_list group by Plant_code having total_orders >100;
select Plant_Code , sum(Unit_quantity) as total_quantity from order_list where Unit_quantity>5 group by plant_code having total_quantity >10000;
select count(*) from order_list;
select plant_code , count(*) as total_orders, Round(count(*) *100.0/(select count(*) from order_list), 2)  as percentage  from order_list group by plant_code;
with customer_summary as (select customer , count(*) as total_orders , case when count(*)> 500 then  'High Volume' when count(*) between 200 and 500 then 'Medium Volume' when count(*) <200 then 'Low Volume' else 'nowhere' end as customer_category from order_list group by customer )
select customer_category , count(*) as number_of_customers from customer_summary group by customer_category;
select o.Order_ID , o.Plant_Code , o.Product_ID from order_list as o left join products_per_plant as p on o.Plant_Code=p.Plant_Code and o.Product_ID=p.Product_ID;
select o.Order_ID , o.Plant_Code , o.Product_ID from order_list as o left join products_per_plant as p on o.Plant_Code=p.Plant_Code and o.Product_ID=p.Product_ID;
select o.Order_ID , o.Plant_Code , o.Product_ID from order_list as o left join products_per_plant as p on o.Plant_Code=p.Plant_Code and o.Product_ID=p.Product_ID where p.Product_ID is null;
select o.Order_ID , o.Plant_Code , o.Product_ID from order_list as o left join products_per_plant as p on o.Plant_Code=p.Plant_Code and o.Product_ID=p.Product_ID where p.Product_ID is not null;
select p.plant_code , count(o.order_id) as total_orders , coalesce(sum(o.unit_quantity),0) as total_quantity from plant_ports  as p left join order_list as o on p.plant_code=o.plant_code group by plant_code order by total_quantity desc limit 5;
select p.plant_code , count(distinct o.product_id) as total_products from plant_ports as p left join products_per_plant as o on p.plant_code=o.plant_code group by p.plant_code  order by total_products desc limit 3;

with plant_summary as (select p.plant_code , count(distinct o.product_id) as total_products from plant_ports as p left join products_per_plant as o on p.plant_code=o.plant_code group by p.plant_code)
select plant_code , dense_rank() over (order by total_products desc) as ranking from plant_summary;

with customer_ranking as (select plant_code , customer , sum(unit_quantity) as total_orders , dense_rank() over(partition by plant_code  order by sum(unit_quantity) desc) as ranking  from order_list group by plant_code, customer )
select * from customer_ranking where ranking <=3 order by plant_code,ranking asc ;

select plant_code , order_id , unit_quantity , lag(unit_quantity) over (partition by plant_code order by order_id ) as previous_quantity , unit_quantity - lag(unit_quantity) over ( partition by plant_code order by order_id)  as difference from order_list where unit_quantity > lag(unit_quantity) over(partition by plant_code order by order_id );

with plant_summary as( select p.plant_code ,count(distinct o.product_id) as product_count ,dense_rank() over ( order by count(distinct o.product_id) desc ) as ranking from plant_ports as p left join products_per_plant as o  on p.plant_code=o.plant_code group by plant_code)
select plant_code , ranking from plant_summary where ranking =2 ;

select count(*) from order_list where Carrier is null;
select order_id , carrier , coalesce(carrier,'Unknown') as carrier_status from order_list;

select year(order_date) as year , count(*) as total_orders from order_list group by  year(order_date);

select * from order_list where datediff(order_date, '2013-05-26') >0; 

select date_format(order_date ,'%b %Y') as order_month  , count(*) as total_orders from order_list group by date_format(order_date,'%b %Y'); 
with plant_sum as (select plant_code, sum(unit_quantity) as total_quantity from order_list group by plant_code),
plant_ranking as (select plant_code , total_quantity , dense_rank() over (order by total_quantity desc ) as ranking from plant_sum)
select plant_code , total_quantity , ranking from plant_ranking where ranking =2;

select p.plant_code , count(o.order_id), coalesce(sum(o.unit_quantity),0) as total_quantity  from  plant_ports as p left join order_list as o on p.plant_code =o.plant_code group by p.plant_code;

select customer , sum(unit_quantity) as total_order_quantity , case when sum(unit_quantity) >500 then 'high' when sum(unit_quantity) between 200 and 500 then 'medium ' else 'low' end as customer_category from order_list group by customer;

with plant_summary as (select plant_code , sum(unit_quantity) as total_quantity from order_list  group by plant_code ),
plant_ranking as (select plant_code , dense_rank() over (partition by plant_code order by total_quantity desc ) as ranking from plant_summary)
select plant_code , ranking from plant_ranking  where ranking =2 order by ranking desc ;

WITH order_summary AS (
    SELECT
        Plant_Code,
        COUNT(*) AS total_orders,
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
    COALESCE(os.total_orders, 0) AS total_orders,
    COALESCE(os.total_quantity, 0) AS total_quantity,
    COALESCE(ps.total_products, 0) AS total_products,
    wc.Daily_Capacity,
    costs.Cost_unit
FROM (
    SELECT DISTINCT Plant_Code
    FROM plant_ports
) AS pp
LEFT JOIN order_summary os
    ON pp.Plant_Code = os.Plant_Code
LEFT JOIN product_summary ps
    ON pp.Plant_Code = ps.Plant_Code
LEFT JOIN wh_capacities wc
    ON pp.Plant_Code = wc.Plant_ID
LEFT JOIN wh_costs costs
    ON pp.Plant_Code = costs.WH
ORDER BY total_quantity DESC;


WITH plant_summary AS (
    SELECT
        p.Plant_Code,
        COUNT(o.Order_ID) AS total_orders,
        COALESCE(SUM(o.Unit_quantity), 0) AS total_quantity
    FROM plant_ports p
    LEFT JOIN order_list o
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

        DENSE_RANK() OVER (
            ORDER BY total_quantity DESC
        ) AS plant_rank
    FROM plant_summary
)

SELECT *
FROM plant_analysis
ORDER BY plant_rank;


WITH customer_summary AS (
    SELECT
        Customer,
        COUNT(*) AS total_orders,
        SUM(Unit_quantity) AS total_quantity
    FROM order_list
    GROUP BY Customer
),

customer_analysis AS (
    SELECT
        Customer,
        total_orders,
        total_quantity,
        ROUND(
            total_quantity * 100.0 /
            SUM(total_quantity) OVER (),
            2
        ) AS quantity_contribution_pct,
        DENSE_RANK() OVER (
            ORDER BY total_quantity DESC
        ) AS customer_rank
    FROM customer_summary
)

SELECT *
FROM customer_analysis
ORDER BY customer_rank;

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
                ROWS BETWEEN UNBOUNDED PRECEDING
                AND CURRENT ROW
            ) * 100.0 /
            SUM(total_quantity) OVER (),
            2
        ) AS cumulative_percentage
    FROM customer_summary
)

SELECT *
FROM customer_pareto
ORDER BY total_quantity DESC;

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

SELECT
    mode_dsc,
    COUNT(*) AS total_rate_records,
    ROUND(AVG(rate), 2) AS average_rate,
    ROUND(MIN(rate), 2) AS minimum_rate,
    ROUND(MAX(rate), 2) AS maximum_rate
FROM freight_rates
GROUP BY mode_dsc
ORDER BY average_rate DESC;

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

SELECT
    orig_port_cd,
    dest_port_cd,
    mode_dsc,
    COUNT(*) AS rate_records,
    ROUND(AVG(rate), 2) AS avg_rate,
    ROUND(MIN(rate), 2) AS min_rate,
    ROUND(MAX(rate), 2) AS max_rate
FROM freight_rates
GROUP BY
    orig_port_cd,
    dest_port_cd,
    mode_dsc
HAVING COUNT(*) >= 5
ORDER BY avg_rate DESC
LIMIT 10;

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
GROUP BY
    Carrier,
    svc_cd,
    minm_wgh_qty,
    max_wgh_qty
ORDER BY avg_rate DESC;

DESCRIBE freight_rates;

SELECT *
FROM freight_rates
WHERE orig_port_cd = 'PORT03'
  AND dest_port_cd = 'PORT09'
  AND mode_dsc = 'GROUND'
ORDER BY rate DESC;


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
    SELECT *,
        rate - avg_rate AS deviation
    FROM route_rates
)

SELECT *
FROM rate_deviation
WHERE deviation > 50
ORDER BY deviation DESC;
