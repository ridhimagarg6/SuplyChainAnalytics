USE supply_chain_analytics;

/* Carrier and weight/service breakdown for PORT03 -> PORT09 GROUND */
SELECT
    Carrier,
    svc_cd,
    minm_wgh_qty,
    maxm_wgh_qty,
    COUNT(*) AS rate_records,
    ROUND(AVG(rate), 2) AS avg_rate,
    ROUND(MIN(rate), 2) AS min_rate,
    ROUND(MAX(rate), 2) AS max_rate,
    ROUND(AVG(minimum_cost), 2) AS avg_minimum_cost
FROM freight_rates
WHERE orig_port_cd = 'PORT03'
  AND dest_port_cd = 'PORT09'
  AND mode_dsc = 'GROUND'
GROUP BY Carrier, svc_cd, minm_wgh_qty, maxm_wgh_qty
ORDER BY avg_rate DESC;

/* Inspect individual records for the high-rate observation */
SELECT *
FROM freight_rates
WHERE orig_port_cd = 'PORT03'
  AND dest_port_cd = 'PORT09'
  AND mode_dsc = 'GROUND'
ORDER BY rate DESC;

/* Preliminary deviation screen; this is not a formal IQR test */
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
    SELECT *, rate - avg_rate AS deviation
    FROM route_rates
)
SELECT *
FROM rate_deviation
WHERE deviation > 50
ORDER BY deviation DESC;
