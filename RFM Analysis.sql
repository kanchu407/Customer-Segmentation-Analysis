create database customer_shopping_data;
use customer_shopping_data;

/* RFM analysis, is a type of customer segmentation and behavioral targeting used to 
help businesses rank and segment customers based on the recency, 
frequency, and monetary value of a transaction.
			— mailchimp.com/resources/rfm-analysis/  */
	
select *
from customer_shopping_data;

-- inspect data

select count(*) -- check how many records
from customer_shopping_data;

select count(distinct(customer_id)) -- customer id has to be unique, check if it's correct
from customer_shopping_data;

select *
from customer_shopping_data -- check if there are null values
where shopping_mall is null;

-- let's add the total column
ALTER TABLE customer_shopping_data ADD COLUMN total INT AFTER price;
UPDATE customer_shopping_data SET total = price * quantity;

-- Total Sales
select sum(total) from customer_shopping_data;


-- spending by gender
select gender, count(distinct(invoice_no)) orders, round(sum(total),2) sales
from customer_shopping_data
group by gender
order by 3 desc;

-- most popular payment method among women and men
select gender,  round(sum(total),2) sales, payment_method
from customer_shopping_data
group by gender, payment_method
order by sales desc; 

-- spending by mall
select shopping_mall, count(distinct(invoice_no)) orders, ROUND(sum(total),2) sales
from customer_shopping_data
group by shopping_mall
order by sales desc;

-- spending by category
select category , round(sum(total),2) sales
from customer_shopping_data
group by category
order by sales desc;

-- spending by customer age groups
SELECT
    CASE
        WHEN age < 20 THEN 'Under 20'
        WHEN age BETWEEN 20 and 29 THEN '20 - 29'
        WHEN age BETWEEN 30 and 39 THEN '30 - 39'
        WHEN age BETWEEN 40 and 49 THEN '40 - 49'
        WHEN age BETWEEN 50 and 59 THEN '50 - 59'
        WHEN age BETWEEN 60 and 69 THEN '60 - 69'
        WHEN age BETWEEN 70 and 79 THEN '70 - 79'
        WHEN age >= 80 THEN 'Over 80'
    END as age_range,
    COUNT(*) AS customer_count, sum(total) as total
    FROM customer_shopping_data 
    GROUP BY age_range
    ORDER BY total desc;
    
    select count(distinct(invoice_no)), sum(total) from customer_shopping_data;

-- top spending by year, genderwise
select distinct(year(invoice_date)) year, gender, count(distinct(invoice_no)) total_invoices, round(sum(total),0) total_revenue
from customer_shopping_data
group by year, gender
order by total_revenue desc; 

-- top sales by year
select distinct(year(invoice_date)) as year, count(distinct(invoice_no)) total_orders
from customer_shopping_data
group by year
order by total_orders desc;

-- top sales by months
select year(invoice_date) as year, monthname(invoice_date) as months, sum(total) as sales
from customer_shopping_data 
group by year,months
having year=2021
order by sales desc;

-- top sales by months
select monthname(invoice_date) as months, sum(total) as sales
from customer_shopping_data 
group by months
order by sales desc;

-- different days between the last customer's purchase
select
  customer_id, gender, age, payment_method, shopping_mall, 
  datediff('2023-03-10', invoice_date) last_date_order,
  count(distinct(invoice_no)) total_orders,
  sum(price) spending
from customer_shopping_data
group by customer_id, gender, age, payment_method, shopping_mall, invoice_date
order by last_date_order;

with rfm as (
select
  customer_id, gender, age, payment_method, shopping_mall, 
  datediff('2023-03-08', invoice_date) last_date_order,
  count(distinct(invoice_no)) total_orders,
  sum(price) spending
from customer_shopping_data
group by customer_id, gender, age, payment_method, shopping_mall, invoice_date
order by last_date_order
)
select *,
  ntile(3) over (order by last_date_order) rfm_recency,
  ntile(3) over (order by total_orders) rfm_frequency,
  ntile(3) over (order by spending) rfm_monetary
 from rfm;

with rfm as (
select
  customer_id, gender, age, payment_method, shopping_mall, 
  datediff('2023-03-08', invoice_date) last_date_order,
  count(distinct(invoice_no)) total_orders,
  sum(price) spending
from customer_shopping_data
group by customer_id, gender, age, payment_method, shopping_mall, invoice_date
order by last_date_order
),
rfm_calc as (
 select *,
  ntile(3) over (order by last_date_order) rfm_recency,
  ntile(3) over (order by total_orders) rfm_frequency,
  ntile(3) over (order by spending) rfm_monetary
 from rfm
 order by rfm_monetary desc
)
select *, rfm_recency + rfm_frequency + rfm_monetary as rfm_score,
concat(rfm_recency, rfm_frequency, rfm_monetary) as rfm
from rfm_calc;

-- RFM
select *, case
 when rfm in (311, 312, 311) then 'new customers'
 when rfm in (111, 121, 131, 122, 133, 113, 112, 132) then 'lost customers'
 when rfm in (212, 313, 123, 221, 211, 232) then 'regular customers'
 when rfm in (223, 222, 213, 322, 231, 321, 331) then 'loyal customers'
 when rfm in (333, 332, 323, 233) then 'champion customers'
end rfm_segment
from
(
with rfm as (
select
  customer_id, gender, age, payment_method, shopping_mall, 
  datediff('2023-03-08', invoice_date) last_date_order,
  count(distinct(invoice_no)) total_orders,
  sum(price) spending
from customer_shopping_data
group by customer_id, gender, age, payment_method, shopping_mall, invoice_date
order by last_date_order
),
rfm_calc as (
 select *,
  ntile(3) over (order by last_date_order) rfm_recency,
  ntile(3) over (order by total_orders) rfm_frequency,
  ntile(3) over (order by spending) rfm_monetary
 from rfm
 order by rfm_monetary desc
)

select *, rfm_recency + rfm_frequency + rfm_monetary as rfm_score,
concat(rfm_recency, rfm_frequency, rfm_monetary) as rfm
from rfm_calc
) rfm_tb;
