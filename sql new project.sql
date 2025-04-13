create database danny_dinners;
set search_path = danny_dinners;
use danny_dinners;
create table sales
(customer_id varchar(10),order_date date,product_id integer);
insert into sales (customer_id,order_date,product_id)
values('A', '2021-01-01', '1'),
  ('A', '2021-01-01', '2'),
  ('A', '2021-01-07', '2'),
  ('A', '2021-01-10', '3'),
  ('A', '2021-01-11', '3'),
  ('A', '2021-01-11', '3'),
  ('B', '2021-01-01', '2'),
  ('B', '2021-01-02', '2'),
  ('B', '2021-01-04', '1'),
  ('B', '2021-01-11', '1'),
  ('B', '2021-01-16', '3'),
  ('B', '2021-02-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-07', '3');
  create table menu 
  (product_id int,product_name varchar(10),price int);
  insert into menu (product_id,product_name,price)
  values ('1', 'sushi', '10'),
  ('2', 'curry', '15'),
  ('3', 'ramen', '12');
  create table member (customer_id varchar(50),join_date date);
  insert into	member (customer_id,join_date)
  values('A', '2021-01-07'),
  ('B', '2021-01-09');
  -- total amount spent by customer
  select customer_id,sum(price) as total_spent
  from sales join menu on sales.product_id = menu.product_id 
  group by customer_id;
  -- days visited by the customer
  select customer_id,count(distinct order_date) as days_visited
  from sales group by customer_id;
  -- first item purchased by customer
WITH FirstPurchase AS (
    SELECT 
        customer_id,
        MIN(order_date) AS first_date
    FROM 
        sales
    GROUP BY 
        customer_id
)
SELECT 
    sales.customer_id,
    menu.product_name
FROM 
    sales
JOIN 
    FirstPurchase
ON 
    sales.customer_id = FirstPurchase.customer_id 
    AND sales.order_date = FirstPurchase.first_date
JOIN 
    menu
ON 
    sales.product_id = menu.product_id;
-- most purchased item and how many times it was purchased
select menu.product_name,count(sales.product_id) as total_purchased
from sales join menu on sales.product_id = menu.product_id
group by menu.product_name order by total_purchased desc limit 1;
-- most popular item for each customer
with customeritemcount as (select customer_id,product_id,
count(product_id) as product_count from sales group by customer_id
,product_id),mostpopularitem as (select customer_id,product_id,
product_count from customeritemcount where product_count = (
select max(product_count) from customeritemcount as subquery where
subquery.customer_id = customeritemcount.customer_id)) select mostpopularitem.customer_id,
menu.product_name,mostpopularitem.product_count as times_purchased
from mostpopularitem join menu on mostpopularitem.product_id = menu.product_id;
-- first purchased after became member
with purchasedaftermembership as (select sales.customer_id,
sales.order_date,sales.product_id from sales join member on 
sales.customer_id = member.customer_id where sales.order_date >=
member.join_date),firstpurchasedaftermembership as (select customer_id,
min(order_date) as first_order_date from purchasedaftermembership
group by customer_id )
select firstpurchasedaftermembership.customer_id,menu.product_name,
firstpurchasedaftermembership.first_order_date from
firstpurchasedaftermembership join purchasedaftermembership on 
firstpurchasedaftermembership.customer_id = purchasedaftermembership.customer_id
and firstpurchasedaftermembership.first_order_date = purchasedaftermembership.order_date
join menu on purchasedaftermembership.product_id = menu.product_id;
-- item purchased before became member
WITH PurchasesBeforeMembership AS (
    SELECT sales.customer_id,sales.order_date,sales.product_id
    FROM sales JOIN member ON sales.customer_id = member.customer_id
    WHERE sales.order_date < member.join_date),
LastPurchaseBeforeMembership AS (
    SELECT customer_id,MAX(order_date) AS last_order_date
    FROM PurchasesBeforeMembership
    GROUP BY customer_id)
SELECT LastPurchaseBeforeMembership.customer_id,menu.product_name,
    LastPurchaseBeforeMembership.last_order_date
FROM LastPurchaseBeforeMembership
JOIN PurchasesBeforeMembership
ON LastPurchaseBeforeMembership.customer_id = PurchasesBeforeMembership.customer_id AND LastPurchaseBeforeMembership.last_order_date = PurchasesBeforeMembership.order_date
JOIN menu ON PurchasesBeforeMembership.product_id = menu.product_id;
-- total item and amount spent for each before they became member
SELECT sales.customer_id,COUNT(sales.product_id) AS total_items,SUM(menu.price) AS total_spent
FROM sales
JOIN member
ON sales.customer_id = member.customer_id
JOIN menu
ON sales.product_id = menu.product_id
WHERE sales.order_date < member.join_date
GROUP BY sales.customer_id;
-- $1=10 points sushi have 2x points how many points each customer have
SELECT sales.customer_id,SUM(CASE WHEN menu.product_name = 'sushi' THEN (menu.price * 10 * 2)ELSE (menu.price * 10)END) AS total_points
FROM sales JOIN menu ON sales.product_id = menu.product_id GROUP BY sales.customer_id;
-- how many does A and B have after join the membership at the end of the january
WITH PointsCalculation AS (
    SELECT 
        sales.customer_id,
        sales.order_date,
        menu.product_name,
        menu.price,
        member.join_date,
        CASE 
            WHEN sales.order_date >= member.join_date AND sales.order_date <= DATE_ADD(member.join_date, INTERVAL 6 DAY) THEN menu.price * 10 * 2
            WHEN menu.product_name = 'sushi' THEN menu.price * 10 * 2
            ELSE menu.price * 10
        END AS points_earned
    FROM 
        sales
    LEFT JOIN 
        member
    ON 
        sales.customer_id = member.customer_id
    JOIN 
        menu
    ON 
        sales.product_id = menu.product_id
),
TotalPoints AS (
    SELECT 
        customer_id,
        SUM(points_earned) AS total_points
    FROM 
        PointsCalculation
    WHERE 
        order_date <= '2021-01-31'
    GROUP BY 
        customer_id
)
SELECT 
    customer_id,
    total_points
FROM 
    TotalPoints
WHERE 
    customer_id IN ('A', 'B');


