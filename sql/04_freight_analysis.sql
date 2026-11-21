USE supply_chain_analytics;

/* Freight-rate comparison by transport mode */
SELECT
    mode_dsc,
    COUNT(*) AS total_rate_records,
    ROUND(AVG(rate), 2) AS average_rate,
    ROUND(MIN(rate), 2) AS minimum_rate,
    ROUND(MAX(rate), 2) AS maximum_rate
FROM freight_rates
GROUP BY mode_dsc
ORDER BY average_rate DESC;

/* Carrier-level comparison by mode; groups with at least 20 records */
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

/* Route-level comparison */
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
