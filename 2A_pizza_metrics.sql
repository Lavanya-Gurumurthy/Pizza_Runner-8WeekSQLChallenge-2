-- 1. How Many Pizzas were orderd?

SELECT COUNT(*) AS No_of_Pizzas_Orderd FROM customer_orders;

-- 2. How many unique customer orders were made?
SELECT COUNT(DISTINCT(order_id)) AS Unique_customer_orders FROM customer_orders;

-- 3. How many successful orders were delivered by each runner? 
SELECT Runner_id,COUNT(*) AS Successful_delivery  FROM runner_orders
WHERE pickup_time != 'null'
GROUP BY runner_id
ORDER BY runner_id;

-- 4. How many of each type of pizza was delivered?
SELECT Pi.pizza_name, COUNT(cust.pizza_id) AS No_Of_Pizzas
FROM customer_orders AS CUST INNER JOIN pizza_names AS Pi
ON cust.pizza_id=pi.pizza_id
INNER JOIN Runner_orders AS run ON run.order_id=cust.order_id
WHERE run.pickup_time != 'null'
GROUP BY Pi.pizza_name;

-- 5. How many Vegetarian and Meatlovers were ordered by each customer?
SELECT cust.customer_id, pi.pizza_name, COUNT(cust.pizza_id) AS No_of_Pizzas
FROM customer_orders cust INNER JOIN pizza_names pi
ON cust.pizza_id=pi.pizza_id
GROUP BY cust.customer_id, pi.pizza_name
ORDER BY cust.customer_id, pi.pizza_name;

-- 6. What was the maximum number of pizzas delivered in a single order?

with cte1 AS (SELECT cust.order_id,count(cust.pizza_id) AS cnt_pizza
FROM customer_orders AS cust INNER JOIN runner_orders AS run
ON cust.order_id=run.order_id
WHERE run.pickup_time != 'null'
GROUP BY cust.order_id
ORDER BY cust.order_id),

cte2 AS (SELECT order_id, cnt_pizza, 
RANK() OVER(ORDER BY cnt_pizza desc) AS R
FROM cte1)

SELECT order_id, cnt_pizza, R FROM cte2
WHERE R=1;

-- 7. For each customer, how many delivered pizzas had at least 1 change and how many had no changes?

WITH CTE AS (SELECT cust.customer_id, cust.order_id,
CASE WHEN cust.exclusions='NA' AND cust.extras='NA' THEN 0 END AS No_change,
CASE WHEN cust.exclusions!='NA' OR cust.extras!='NA' THEN 1 END AS Extras
FROM customer_orders_clean cust INNER JOIN runner_orders_clean run
ON cust.order_id=run.order_id
WHERE run.pickup_time!='NA'
ORDER BY  cust.customer_id,run.order_id)

SELECT customer_id, COUNT(no_change) AS Pizzas_without_change, COUNT(extras) AS pizzas_with_change
FROM CTE
GROUP BY customer_id;


-- 8. How many pizzas were delivered that had both exclusions and extras?

SELECT cust.customer_id, cust.order_id
FROM customer_orders_clean cust INNER JOIN runner_orders_clean run
ON cust.order_id=run.order_id
WHERE run.pickup_time!='NA' AND 
cust.exclusions!='NA' AND cust.extras!='NA'
ORDER BY  cust.customer_id,run.order_id;

-- 9. What was the total volume of pizzas ordered for each hour of the day?

SELECT 
EXTRACT(DAY FROM order_time) AS Date_part, 
EXTRACT(HOUR FROM order_time) AS Hour_Part, count(Order_id) AS No_of_pizzas 
FROM customer_orders_clean
GROUP BY Date_part, hour_part
ORDER BY Date_part, Hour_part;

--10. What was the volume of orders for each day of the week?

SELECT 
(CASE WHEN EXTRACT(DOW FROM order_time)=0 THEN 'Sunday'
	 WHEN EXTRACT(DOW FROM order_time)=1 THEN 'Monday'
	 WHEN EXTRACT(DOW FROM order_time)=2 THEN 'Tuesday'
	 WHEN EXTRACT(DOW FROM order_time)=3 THEN 'Wednesday'
	 WHEN EXTRACT(DOW FROM order_time)=4 THEN 'Thursday'
	 WHEN EXTRACT(DOW FROM order_time)=5 THEN 'Friday'
	 ELSE 'Saturday'
	 END) AS Day_of_week,	 
count(Order_id) AS No_of_pizzas 
FROM customer_orders_clean
GROUP BY Day_of_Week
ORDER BY Day_of_Week;

