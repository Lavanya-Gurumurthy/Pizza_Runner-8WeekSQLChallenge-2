-- D. Pricing and Ratings
--1. If a Meat Lovers pizza costs $12 and Vegetarian costs $10 and there were no charges for changes - 
--how much money has Pizza Runner made so far if there are no delivery fees?

WITH cost_pizza AS
(SELECT c.order_id, c.pizza_id, p.pizza_name,
CASE WHEN c.pizza_id=1 THEN 12 ELSE 10 END AS cost_in_$
FROM customer_orders_clean c
INNER JOIN runner_orders_clean r
on c.order_id=r.order_id
INNER JOIN pizza_names p
on c.pizza_id=p.pizza_id
WHERE r.cancellation='NA'
ORDER BY c.order_id)

SELECT SUM(cost_in_$) AS Total_cost FROM cost_pizza;

--2. What if there was an additional $1 charge for any pizza extras?
--Add cheese is $1 extra

WITH cost_pizza AS
(SELECT c.order_id, c.pizza_id, c.extras,p.pizza_name,
CASE WHEN extras='NA' THEN 0
 ELSE(CHAR_LENGTH(extras)-CHAR_LENGTH(REPLACE(extras,',','')))+1 END AS no_of_extras,
CASE WHEN c.pizza_id=1 THEN 12 ELSE 10 END AS cost_in_$
FROM customer_orders_clean c
INNER JOIN runner_orders_clean r
on c.order_id=r.order_id
INNER JOIN pizza_names p
on c.pizza_id=p.pizza_id
WHERE r.cancellation='NA'
ORDER BY c.order_id),

total_cost AS
(SELECT *,
((no_of_extras*1) + cost_in_$) AS new_cost FROM cost_pizza)

SELECT SUM(new_cost) AS Total_cost FROM total_cost;

--3. The Pizza Runner team now wants to add an additional ratings system that allows customers to rate their runner, 
--how would you design an additional table for this new dataset - 
--generate a schema for this new table and insert your own data for ratings for each successful customer order between 1 to 5.
--Note that for this question, the below query (commented) has been executed and table created and data was also inserted.
--Finally commented to not interrupt with the running of any queries taht followed
/*
CREATE TABLE runner_rating(
runner_id INTEGER REFERENCES runners(runner_id),
customer_id integer NOT NULL,
order_id integer NOT NULL,
rating integer CHECK (rating>=1 and rating <=5)
);

INSERT INTO runner_rating VALUES
(1,101,1,4),
(1,101,2,3),
(1,102,3,5),
(2,103,4,5),
(2,105,7,3),
(2,102,8,2);
*/

--4. Using your newly generated table - can you join all of the information together 
--to form a table which has the following information for successful deliveries?
--customer_id
--order_id
--runner_id
--rating
--order_time
--pickup_time
--Time between order and pickup
--Delivery duration
--Average speed
--Total number of pizzas

SELECT c.customer_id, c.order_id, r.runner_id, ra.rating, c.order_time, r.pickup_time, 
(CAST(r.pickup_time AS timestamp) - c.order_time) AS time_diff, 
r.duration,
r.distance/r.duration AS speed,
count(*) AS total_pizzas
FROM customer_orders_clean c
LEFT JOIN runner_orders_clean r
ON c.order_id=r.order_id
LEFT JOIN runner_rating ra
ON r.order_id=ra.order_id
WHERE r.cancellation='NA'
GROUP BY c.customer_id, c.order_id, r.runner_id, ra.rating, c.order_time, r.pickup_time,
time_diff, r.duration, speed
ORDER BY c.order_id;

--5. If a Meat Lovers pizza was $12 and Vegetarian $10 fixed prices with no cost for extras and 
--each runner is paid $0.30 per kilometre traveled - 
--how much money does Pizza Runner have left over after these deliveries?

WITH cost_pizza AS
(SELECT c.order_id, c.pizza_id, p.pizza_name,r.distance,
 CASE WHEN c.pizza_id=1 THEN 12 ELSE 10 END AS cost_in_$
FROM customer_orders_clean c
INNER JOIN runner_orders_clean r
on c.order_id=r.order_id
INNER JOIN pizza_names p
on c.pizza_id=p.pizza_id
WHERE r.cancellation='NA'
ORDER BY c.order_id),

Total_pizza_cost AS (
SELECT SUM(cost_in_$) AS Total_cost FROM cost_pizza),

runner_payment AS
(SELECT c.order_id, 
 distance*0.30 AS runner_payment
FROM customer_orders_clean c
INNER JOIN runner_orders_clean r
on c.order_id=r.order_id
INNER JOIN pizza_names p
on c.pizza_id=p.pizza_id
WHERE r.cancellation='NA'
GROUP BY c.order_id,r.distance
 ORDER BY c.order_id),

Total_runner_payment AS(
SELECT SUM(runner_payment) AS total_runner_payment FROM runner_payment)

SELECT Total_cost, Total_runner_payment,
Total_cost-total_runner_payment AS Balance_available
FROM Total_pizza_cost,Total_runner_payment;

