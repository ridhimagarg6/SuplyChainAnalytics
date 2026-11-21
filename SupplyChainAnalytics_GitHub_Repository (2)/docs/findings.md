**Project findings**

This file gives a simple summary of the results recorded during the SQL work. Run the queries again after importing the data to check that the numbers still match.

**Dataset**

The project uses seven tables with 12,865 rows in total. See [dataset findings](dataset_findings.md).

**Plants**

PLANT03 had 8,541 order records and contributed 96.94% of the recorded order quantity. Twelve plants in the 19-plant list had no matching order records. See [plant findings](plant_findings.md).

**Customers**

There were 46 different customers. Customer `V55555555_5` had 8,020,417 units, or 27.18% of the total quantity. The nine largest customers together made up 80.18%. See [customer findings](customer_findings.md).

**Delivery rates**

The AIR group had 1,511 records and an average rate of 2.61. The GROUND group had 29 records and an average rate of 17.61. A GROUND rate of 128.0272 on the PORT03 to PORT09 route needs further checking. See [freight findings](freight_findings.md).

**Important limits**

All order dates checked were 26 May 2013. The data cannot show a useful trend over time. Order row counts should not be described as unique shipment counts unless that has been checked. See [data limits](data_limits.md).
