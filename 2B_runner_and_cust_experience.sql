-- Runner and Customer Experience

-- 1.How many runners signed up for each 1 week period? (i.e. week starts 2021-01-01)
WITH CTE AS (
select runner_id, registration_date,
(date_part('day', registration_date) - date_part('day',date '2021-01-01')) AS day_no,
CAST(((date_part('day', registration_date) - date_part('day',date '2021-01-01'))/7) AS integer) AS week_no
from runners)

SELECT week_no, COUNT(runner_id) FROM CTE
GROUP BY week_no
ORDER BY week_no;

-- 2.What was the average time in minutes it took for each runner to arrive at the Pizza Runner HQ to pickup the order? 
WITH CTE AS (
SELECT run.runner_id,--run.order_id, cust.order_time,  run.pickup_time,
(CAST(run.pickup_time AS timestamp) - cust.order_time) AS time_diff
FROM customer_orders_clean cust
INNER JOIN runner_orders_clean run
ON cust.order_id=run.order_id
WHERE run.pickup_time != 'NA'
GROUP BY run.runner_id, time_diff
ORDER BY run.runner_id)

SELECT runner_id, AVG(time_diff) AS avg_time FROM CTE
GROUP BY runner_id
ORDER BY runner_id;

-- 3.Is there any relationship between the number of pizzas and how long the order takes to prepare?

SELECT cust.order_id, cust.order_time, run.pickup_time, COUNT(cust.*) AS No_of_Pizzas,
(CAST(run.pickup_time AS timestamp)-cust.order_time) AS time_diff
FROM customer_orders_clean cust
INNER JOIN runner_orders_clean run
ON cust.order_id=run.order_id
WHERE run.pickup_time !='NA'
GROUP BY cust.order_id,cust.order_time, run.pickup_time
ORDER BY cust.order_id, cust.order_time, run.pickup_time;

-- 4.What was the average distance travelled for each customer?
WITH CTE AS(
SELECT  cust.customer_id, cust.order_id, run.distance
FROM customer_orders_clean cust
INNER JOIN runner_orders_clean run
ON cust.order_id= run.order_id
WHERE run.pickup_time !='NA'
GROUP BY cust.customer_id, cust.order_id, run.distance
ORDER BY cust.customer_id, cust.order_id)

SELECT customer_id, AVG(distance) AS Average_distance_travelled
FROM CTE
GROUP BY customer_id
ORDER BY customer_id;

-- 5.What was the difference between the longest and shortest delivery times for all orders?
SELECT MAX(duration) AS Longest_delivery_time,
MIN(duration) AS Shortest_Delivery_time,
(MAX(duration) - MIN(duration)) AS difference
FROM runner_orders_clean
WHERE duration !=0;

-- 6.What was the average speed for each runner for each delivery and do you notice any trend for these values?

SELECT runner_id, order_id, distance, duration,
(distance/duration) AS Speed
FROM runner_orders_clean
WHERE duration !=0
ORDER BY runner_id, order_id;

-- 7.What is the successful delivery percentage for each runner?

WITH CTE AS(
SELECT runner_id, cancellation, COUNT(*) AS No_success
FROM runner_orders_clean
GROUP BY runner_id, cancellation
ORDER BY runner_id),

CTE2 AS(
SELECT runner_id, SUM(no_success) AS total_delivery FROM CTE
GROUP BY runner_id
ORDER BY runner_id)

SELECT CTE2.runner_id, ((cte.No_success/cte2.total_delivery)*100) AS percent_success_delivery
FROM CTE INNER JOIN CTE2
ON CTE.runner_id=CTE2.runner_id
WHERE CTE.cancellation='NA';
