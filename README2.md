show tables in databank;
select * from customer_nodes limit 10;
select * from customer_transactions limit 10;
select * from regions limit 10;

-- Basic analysis 
select min(start_date) as min_date_start,
	   max(start_date) as max_date_start,
       min(end_date) as min_date_end,
	   max(end_date) as max_date_end from customer_nodes;
       
select month(start_date) as start_month from customer_nodes group by 1;       
select count(*) from customer_nodes where end_date > '2020-12-31';
select * from customer_nodes where end_date > '2020-12-31';

select txn_type, txn_amount from customer_transactions group by txn_type,txn_amount order by txn_amount desc limit 1;
select month(txn_date) as txn_dates, count(*) from customer_transactions group by 1;
select distinct txn_type, sum(txn_amount) from customer_transactions group by txn_type;

-- A. Customer Nodes Exploration
-- 1> How many unique nodes are there on the Data Bank system?
select count(distinct node_id) from customer_nodes;

-- 2> What is the number of nodes per region?
select region_name, count(*) Number_of_nodes from customer_nodes join regions on customer_nodes.region_id = regions.region_id 
group by region_name;

-- 3> How many customers are allocated to each region?
select region_name, count(distinct customer_id) No_customer from customer_nodes join regions on customer_nodes.region_id = regions.region_id
group by region_name;

-- 4> How many days on average are customers reallocated to a different node?
with temp as (
select  customer_id, node_id, region_id, round(avg(DATEDIFF(end_date, start_date)), 1) avg_days
from customer_nodes where end_date<='2020-12-31' group by customer_id, node_id order by customer_id, node_id)

select customer_id, round(avg(avg_days),0) as ag_days from temp group by 1;

-- 5> What is the median, 80th and 95th percentile for this same reallocation days metric for each region?
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

-- 6> What is the unique count and total amount for each transaction type?
with klp as(
select customer_id, txn_date, txn_type, txn_amount,concat(customer_id, txn_date, txn_type, txn_amount) as con,
rank() over(partition by concat(customer_id, txn_date, txn_type, txn_amount)) as rn
from customer_transactions)

select txn_type, count(distinct txn_amount) as uq, sum(txn_amount) as total_amount from customer_transactions group by txn_type;

-- 7> What is the average total historical deposit counts and amounts for all customers?
select customer_id, sum(txn_amount), count(*) from customer_transactions 
where txn_type = 'deposit' group by customer_id;

-- 8> For each month - how many Data Bank customers make 
--    more than 1 deposit and either 1 purchase or 1 withdrawal in a single month?
with tbl as(
select customer_id, month(txn_date) ydt, count(txn_type='deposit') as dpcnt, count(txn_type='withdrawal') as wdcnt, count(txn_type='purchase') as prcnt 
from customer_transactions GROUP BY customer_id, MONTH(txn_date))

select customer_id from tbl where dpcnt>1 group by customer_id having count(*)>=4;

-- 9> What is the closing balance for each customer at the end of the month?
select customer_id, 
sum(case 
when txn_type='deposit' then txn_amount
when txn_type='purchase' then (-txn_amount)
when txn_type='withdrawal' then (-txn_amount)
end) as Total 
from customer_transactions group by customer_id order by customer_id;

-- 10> What is the percentage of customers who increase their closing balance by more than 5%?
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
            
-- 11> data is allocated based off the amount of money at the end of the previous month.
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

-- 12> Data is allocated on the average amount of money kept in the account in the previous 30 days
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

-- 13> Data is updated real-time
CREATE EVENT update_data_event
ON SCHEDULE EVERY 1 MINUTE
DO
UPDATE customer_transactions SET last_checked = NOW();

-- 14> running customer balance column that includes the impact each transaction
select *, sum(CASE 
        WHEN txn_type = 'deposit' THEN txn_amount
        WHEN txn_type = 'purchase' THEN -txn_amount
        WHEN txn_type = 'withdrawal' THEN -txn_amount
    END) over(PARTITION BY customer_id ORDER BY txn_date) AS running_total
from customer_transactions order by customer_id, txn_date, txn_type;

-- 15> customer balance at the end of each month
select customer_id, month(txn_date), txn_type, txn_amount,
sum(CASE 
        WHEN txn_type = 'deposit' THEN txn_amount
        WHEN txn_type = 'purchase' THEN -txn_amount
        WHEN txn_type = 'withdrawal' THEN -txn_amount
    END) over(PARTITION BY customer_id, month(txn_date) ORDER BY txn_date) AS running_total
from customer_transactions order by customer_id, txn_date;

-- 16> Min, Max and Average of customer runiing total
with jkl as (
select customer_id, month(txn_date), txn_type, txn_amount,
sum(CASE 
        WHEN txn_type = 'deposit' THEN txn_amount
        WHEN txn_type = 'purchase' THEN -txn_amount
        WHEN txn_type = 'withdrawal' THEN -txn_amount
    END) over(PARTITION BY customer_id, month(txn_date) ORDER BY txn_date) AS running_total
from customer_transactions order by customer_id, txn_date)
select customer_id, min(running_total), max(running_total), round(avg(running_total),0) from jkl group by customer_id;

-- 17> Calculate compound interest of daily basis closing balance
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
