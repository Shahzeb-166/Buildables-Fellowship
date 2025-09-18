**Why did we use a row hash?**

A row-level hash (MD5) allows us to quickly detect any change across multiple columns (price, genre, developer, PS Plus status, etc.) without writing long column by column comparisons. Even if one character changes the whole hash changes making it clear to detect if any changes were made.



**What if you had a column lastUpdateDate in both staging and main tables, would**

**you still have calculated row hash?**

Using lastUpdateDate would tell us when the change was made but what was changed. We can use lastUpdateDate to detect potential changes, and then use row hash to confirm whether any attribute values actually changed.



**What are different types of SCD you have explored and when to use them?**

1. SCD Type 0 – Fixed Dimension

Definition: Data never changes once inserted (static reference data).

Use Case: Historical data like date dimension, currency codes, country codes.



2\. SCD Type 1 – Overwrite

Definition: Old data is overwritten with new values. No history is kept.

Use Case: Correcting mistakes (e.g., fixing a typo in a customer’s name, updating address when history isn’t important).



3\. SCD Type 2 – Historical Tracking

Definition: Keeps history by inserting new rows with effective dates and an is\_active flag. Old rows are expired.

Use Case: When you must track changes over time (e.g., product price changes, employee department transfers, customer subscription status).



4\. SCD Type 3 – Limited History

Definition: Stores previous value in separate columns (e.g., current\_value, previous\_value).

Use Case: When you only care about latest + one previous value (e.g., current vs. last year’s sales region).







