# Introduction
There is a new innovation in the financial industry called Neo-Banks: new aged digital only banks without physical branches.
Danny thought that there should be some sort of intersection between these new age banks, cryptocurrency and the data world…so he decides to launch a new initiative - Data Bank!
Data Bank runs just like any other digital bank - but it isn’t only for banking activities, they also have the world’s most secure distributed data storage platform!
Customers are allocated cloud data storage limits which are directly linked to how much money they have in their accounts. There are a few interesting caveats that go with this business model, and this is where the Data Bank team need your help!
The management team at Data Bank want to increase their total customer base - but also need some help tracking just how much data storage their customers will need.
This case study is all about calculating metrics, growth and helping the business analyse their data in a smart way to better forecast and plan for their future developments!

# Available Data
The Data Bank team have prepared a data model for this case study as well as a few example rows from the complete dataset below to get you familiar with their tables.

### Table 1: Regions
Just like popular cryptocurrency platforms - Data Bank is also run off a network of nodes where both money and data is stored across the globe. In a traditional banking sense - you can think of these nodes as bank branches or stores that exist around the world.
This regions table contains the region_id and their respective region_name values

### Table 2: Customer Nodes
Customers are randomly distributed across the nodes according to their region - this also specifies exactly which node contains both their cash and data.
This random distribution changes frequently to reduce the risk of hackers getting into Data Bank’s system and stealing customer’s money and data!
Below is a sample of the top 10 rows of the data_bank.customer_nodes

### Table 3: Customer Transactions
This table stores all customer deposits, withdrawals and purchases made using their Data Bank debit card.

Complete Data set available on this 'https://8weeksqlchallenge.com/case-study-4/'

# Case Study Questions
The following case study questions include some general data exploration analysis for the nodes and transactions before diving right into the core business questions and finishes with a challenging final request!

### Basic analysis 
```sql
select min(start_date) as min_date_start, max(start_date) as max_date_start, min(end_date) as min_date_end, max(end_date) as max_date_end from customer_nodes;
```
       
```sql 
select month(start_date) as start_month from customer_nodes group by 1;
```      
```sql 
select count(*) from customer_nodes where end_date > '2020-12-31';
```
```sql 
select * from customer_nodes where end_date > '2020-12-31';
```

```sql 
select txn_type, txn_amount from customer_transactions group by txn_type,txn_amount order by txn_amount desc limit 1;
```
```sql
select month(txn_date) as txn_dates, count(*) from customer_transactions group by 1;
```
```sql
select distinct txn_type, sum(txn_amount) from customer_transactions group by txn_type;
```

# A. Customer Nodes Exploration
### 1> How many unique nodes are there on the Data Bank system?
```sql
select count(distinct node_id) from customer_nodes;
```

### 2> What is the number of nodes per region?
```sql
select region_name, count(*) Number_of_nodes from customer_nodes join regions on customer_nodes.region_id = regions.region_id 
group by region_name;
```

### 3> How many customers are allocated to each region?
```sql
select region_name, count(distinct customer_id) No_customer from customer_nodes join regions on customer_nodes.region_id = regions.region_id
group by region_name;
```

### 4> How many days on average are customers reallocated to a different node?
```sql
with temp as (
select  customer_id, node_id, region_id, round(avg(DATEDIFF(end_date, start_date)), 1) avg_days
from customer_nodes where end_date<='2020-12-31' group by customer_id, node_id order by customer_id, node_id)

select customer_id, round(avg(avg_days),0) as ag_days from temp group by 1;
```

### 5> What is the median, 80th and 95th percentile for this same reallocation days metric for each region?
```sql
with temp2 as (
select customer_nodes.customer_id, customer_nodes.node_id, regions.region_name, 
round(avg(DATEDIFF(end_date, start_date)), 0) avg_days 
from customer_nodes join regions on customer_nodes.region_id = regions.region_id 
where end_date is not null and end_date <'2020-12-31' 
group by customer_id, node_id, regions.region_name 
order by region_name, avg_days)

select 
region_name, 
round(count(region_name)/2,0) as median,
round(count(region_name)/1.25,0) as 80_percentile,
round(count(region_name)/1.11,0) as 90_percentile
from temp2 group by region_name;
```

# B. Customer Transactions
### 6> What is the unique count and total amount for each transaction type?
```sql
with klp as(
select customer_id, txn_date, txn_type, txn_amount,concat(customer_id, txn_date, txn_type, txn_amount) as con,
rank() over(partition by concat(customer_id, txn_date, txn_type, txn_amount)) as rn
from customer_transactions)

select txn_type, count(distinct txn_amount) as uq, sum(txn_amount) as total_amount from customer_transactions group by txn_type;
```

### 7> What is the average total historical deposit counts and amounts for all customers?
```sql
select customer_id, sum(txn_amount), count(*) from customer_transactions 
where txn_type = 'deposit' group by customer_id;
```

### 8> For each month - how many Data Bank customers make more than 1 deposit and either 1 purchase or 1 withdrawal in a single month?
```sql
with tbl as(
select customer_id, month(txn_date) ydt, count(txn_type='deposit') as dpcnt, count(txn_type='withdrawal') as wdcnt, count(txn_type='purchase') as prcnt 
from customer_transactions GROUP BY customer_id, MONTH(txn_date))

select customer_id from tbl where dpcnt>1 group by customer_id having count(*)>=4;
```

### 9> What is the closing balance for each customer at the end of the month?
```sql
select customer_id, 
sum(case 
when txn_type='deposit' then txn_amount
when txn_type='purchase' then (-txn_amount)
when txn_type='withdrawal' then (-txn_amount)
end) as Total 
from customer_transactions group by customer_id order by customer_id;
```

### 10> What is the percentage of customers who increase their closing balance by more than 5%?
```sql
select customer_id,  
    SUM(CASE 
        WHEN txn_type = 'deposit' THEN txn_amount
        WHEN txn_type = 'purchase' THEN -txn_amount
        WHEN txn_type = 'withdrawal' THEN -txn_amount
    END) AS Total
FROM customer_transactions
GROUP BY customer_id
HAVING Total >= (
        SELECT SUM(CASE 
                WHEN txn_type = 'deposit' THEN txn_amount
                WHEN txn_type = 'purchase' THEN -txn_amount
                WHEN txn_type = 'withdrawal' THEN -txn_amount
            END) * 0.05 FROM customer_transactions);
```

# C. Data Allocation Challenge     
### 11> data is allocated based off the amount of money at the end of the previous month.
```sql
WITH MonthlyTotals AS (
    SELECT 
        customer_id, MONTHNAME(txn_date) AS months,
        SUM(CASE 
            WHEN txn_type = 'deposit' THEN txn_amount
            WHEN txn_type = 'purchase' THEN -txn_amount
            WHEN txn_type = 'withdrawal' THEN -txn_amount
        END) AS Total FROM customer_transactions GROUP BY customer_id, months)
SELECT 
    customer_id, months, Total, 
    LAG(Total, 1, 0) OVER (PARTITION BY customer_id ORDER BY months) AS Prev_Month_Total
FROM MonthlyTotals ORDER BY customer_id;
```

### 12> Data is allocated on the average amount of money kept in the account in the previous 30 days
```sql
select customer_id, sum(txn_amount), count(*),
SUM(CASE 
        WHEN txn_type = 'deposit' THEN txn_amount
        WHEN txn_type = 'purchase' THEN -txn_amount
        WHEN txn_type = 'withdrawal' THEN -txn_amount
    END) as tmp,
SUM(CASE 
        WHEN txn_type = 'deposit' THEN txn_amount
        WHEN txn_type = 'purchase' THEN -txn_amount
        WHEN txn_type = 'withdrawal' THEN -txn_amount
    END)/count(*) as avg_total 
from customer_transactions 
where txn_date <= (SELECT MAX(txn_date) FROM customer_transactions) - INTERVAL 30 DAY group by customer_id;
```

### 13> Data is updated real-time
```sql
CREATE EVENT update_data_event
ON SCHEDULE EVERY 1 MINUTE
DO
UPDATE customer_transactions SET last_checked = NOW();
```

### 14> running customer balance column that includes the impact each transaction
```sql select *, sum(CASE 
        WHEN txn_type = 'deposit' THEN txn_amount
        WHEN txn_type = 'purchase' THEN -txn_amount
        WHEN txn_type = 'withdrawal' THEN -txn_amount
    END) over(PARTITION BY customer_id ORDER BY txn_date) AS running_total
from customer_transactions order by customer_id, txn_date, txn_type;
```

### 15> customer balance at the end of each month
```sql
select customer_id, month(txn_date), txn_type, txn_amount,
sum(CASE 
        WHEN txn_type = 'deposit' THEN txn_amount
        WHEN txn_type = 'purchase' THEN -txn_amount
        WHEN txn_type = 'withdrawal' THEN -txn_amount
    END) over(PARTITION BY customer_id, month(txn_date) ORDER BY txn_date) AS running_total
from customer_transactions order by customer_id, txn_date;
```

### 16> Min, Max and Average of customer runiing total
```sql
with jkl as (
select customer_id, month(txn_date), txn_type, txn_amount,
sum(CASE 
        WHEN txn_type = 'deposit' THEN txn_amount
        WHEN txn_type = 'purchase' THEN -txn_amount
        WHEN txn_type = 'withdrawal' THEN -txn_amount
    END) over(PARTITION BY customer_id, month(txn_date) ORDER BY txn_date) AS running_total
from customer_transactions order by customer_id, txn_date)
select customer_id, min(running_total), max(running_total), round(avg(running_total),0) from jkl group by customer_id;
```

### 17> Calculate compound interest of daily basis closing balance
```sql
WITH RunningTotal AS (
    SELECT 
        customer_id, 
        txn_date, 
        txn_type, 
        txn_amount,
        SUM(CASE 
            WHEN txn_type = 'deposit' THEN txn_amount
            WHEN txn_type = 'purchase' THEN -txn_amount
            WHEN txn_type = 'withdrawal' THEN -txn_amount
        END) OVER (PARTITION BY customer_id ORDER BY txn_date) AS running_total
    FROM 
        customer_transactions
),
InterestCalculation AS (
    SELECT 
        customer_id, 
        txn_date, 
        txn_date 
        txn_type, 
        txn_amount, 
        running_total,
        (running_total * 0.06 / 365) AS daily_interest_amount
    FROM 
        RunningTotal
)
SELECT 
    customer_id, 
    txn_date, 
    txn_type, 
    txn_amount, 
    running_total,
    daily_interest_amount,
    (running_total + daily_interest_amount) AS Total_balance
FROM 
    InterestCalculation
ORDER BY 
    customer_id, txn_date;
```
