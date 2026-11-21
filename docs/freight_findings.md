**Freight findings**

**What we wanted to know**

How do delivery rates differ by transport type, carrier and route?

**What the results showed**

- AIR had 1,511 rate records. Its average rate was 2.61.
- GROUND had 29 rate records. Its average rate was 17.61.
- Carrier V444_4 had 906 AIR rate records and an average rate of 3.79.
- The average GROUND rate for PORT03 to PORT09 was about 17.7475.
- One V444_7 rate on that route was 128.0272.
- That rate was about 7.21 times the route average.

**What this means**

The V444_7 rate is much higher than the other rates in the route group. It is worth checking the original record and its conditions.

**What this does not tell us**

The high rate is not confirmed to be a mistake. AIR and GROUND averages should not be compared directly without checking the route, service type and weight range. The query that found the high rate is a simple check against the route average, not a formal statistical test.

Related files: [Freight analysis SQL](../sql/04_freight_analysis.sql) and [Route investigation SQL](../sql/05_route_investigation.sql).
