**Supply Chain Analytics**

A simple SQL project that looks at orders, plants, customers and delivery costs. The aim is to understand what is happening in the supply chain by asking clear questions and checking the answers in MySQL.

**Project status**

The SQL work and written findings are included. A Power BI dashboard is a future step. It has not been built yet.

**Original dataset**

This project uses the Supply Chain Logistics Problem Dataset from Brunel University London.

- [Open the original dataset page](https://brunel.figshare.com/articles/dataset/Supply_Chain_Logistics_Problem_Dataset/7558679)
- [Open the dataset DOI](https://doi.org/10.17633/rd.brunel.7558679)
- [Download the dataset files](https://brunel.figshare.com/ndownloader/articles/7558679/versions/2)

The dataset has seven tables. They contain order details, delivery rates, plant and port links, product and plant links, customer rules, plant capacity and warehouse costs. The source page also explains how these tables are meant to be used.

**What is in this repository**

- [Original SQL file](./sql/explore_original.sql): The SQL file uploaded for this project. It is kept as it was received.
- [Organized SQL file](./sql/supply_chain_analysis.sql): The project work arranged into clear sections. Each section explains the question and the finding.
- [Data checks](./sql/01_data_audit.sql): Checks the tables, row counts, missing values and dates.
- [Plant analysis](./sql/02_plant_analysis.sql): Looks at order activity and product lists for each plant.
- [Customer analysis](./sql/03_customer_analysis.sql): Looks at customer order quantities and how much each customer contributes.
- [Freight analysis](./sql/04_freight_analysis.sql): Compares delivery rates by carrier, route and transport type.
- [Route investigation](./sql/05_route_investigation.sql): Checks one route with a rate that looks unusually high.
- [Full findings](./docs/findings.md): A simple summary of all findings and things to be careful about.
- [Dataset findings](./docs/dataset_findings.md): Table names and row counts.
- [Plant findings](./docs/plant_findings.md): What the data shows about plants.
- [Customer findings](./docs/customer_findings.md): What the data shows about customers.
- [Freight findings](./docs/freight_findings.md): What the data shows about delivery rates.
- [Data limits](./docs/data_limits.md): What the data cannot tell us yet.

**Dataset overview**

The seven tables contain 12,865 rows in total, based on the counts recorded during the project.

- `order_list`: 9,215 rows
- `freight_rates`: 1,540 rows
- `wh_costs`: 19 rows
- `wh_capacities`: 19 rows
- `products_per_plant`: 2,036 rows
- `vmi_customers`: 14 rows
- `plant_ports`: 22 rows
- **Total: 12,865 rows**

**Main findings**

**1. Plant activity**

PLANT03 handled 8,541 order records. This was much more than any other plant. It also contributed 96.94% of the total recorded order quantity. Twelve plants in the 19-plant list had no matching order records.

Read more: [Plant findings](./docs/plant_findings.md) and [Plant SQL](./sql/02_plant_analysis.sql).

**2. Customer activity**

The data has 46 different customers. Customer `V55555555_5` had the highest recorded quantity, with 8,020,417 units. This was 27.18% of all recorded quantity. The nine largest customers together accounted for 80.18%.

Read more: [Customer findings](./docs/customer_findings.md) and [Customer SQL](./sql/03_customer_analysis.sql).

**3. Delivery rates**

The AIR group had 1,511 rate records and an average rate of 2.61. The GROUND group had 29 rate records and an average rate of 17.61. These averages are not a fair direct comparison unless route, service and weight are also considered.

One GROUND rate for the PORT03 to PORT09 route was 128.0272. This is much higher than the route average of about 17.7475. It needs checking, but the data does not prove that it is wrong.

Read more: [Freight findings](./docs/freight_findings.md), [Freight SQL](./sql/04_freight_analysis.sql) and [Route investigation SQL](./sql/05_route_investigation.sql).

**4. Date information**

The order date was recorded as 26 May 2013 for all rows checked. This means the current data cannot show how orders changed over several months or years.

Read more: [Data limits](./docs/data_limits.md) and [Data checks SQL](./sql/01_data_audit.sql).

**How to use the project**

1. Download the source files from the dataset page linked above.
2. Import the seven tables into MySQL.
3. Open MySQL Workbench.
4. Run the queries in `sql/supply_chain_analysis.sql` section by section.
5. Check the result of each query against the findings documents.

MySQL 8.0 or later is recommended because the queries use common table expressions and window functions.

**A few things to keep in mind**

The number of rows is not always the same as the number of unique shipments. A plant's share of order quantity does not tell us how much of its daily capacity was used. The customer groups use sample cutoffs chosen during analysis. The high delivery rate is only a warning for further checking. These results describe this dataset and do not prove why something happened.

**Tools used**

- MySQL
- MySQL Workbench
- SQL queries, joins, grouping, common table expressions and window functions

**Next step**

The next planned step is to export checked SQL results and use them to build a Power BI dashboard. The dashboard will be added after it has actually been completed.

**Author**

Ridhima Garg  
B.Tech, Computer Science and Engineering, Data Science and AI/ML
