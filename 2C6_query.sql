--2C 6. What is the total quantity of each ingredient used in all delivered pizzas sorted by most frequent first?

--Table with the pizzas that were delivered by removing the cancelled orders
WITH pizzas_delivered AS(
SELECT cust.order_id, cust.customer_id, cust.pizza_id, cust.exclusions, cust.extras,
ROW_NUMBER() OVER(PARTITION BY cust.order_id,cust.customer_id ORDER BY cust.order_id,cust.customer_id) AS row_num
FROM customer_orders_clean cust
INNER JOIN runner_orders_clean run
ON cust.order_id=run.order_id
WHERE run.pickup_time <> 'NA'
ORDER BY cust.order_id, cust.customer_id),

--Joining the pizzas_delivered with pizza_recipes table
pizza_joined_to_toppings AS
(SELECT pi.*, reci.toppings 
FROM pizzas_delivered pi
INNER JOIN pizza_recipes reci
on pi.pizza_id=reci.pizza_id),

--concatenating the extras values to toppings if not NA
extras_concat AS 
(SELECT *,
CASE WHEN extras <> 'NA' 
	THEN CONCAT (extras,',',toppings)
	ELSE toppings
	END AS toppings_new
FROM pizza_joined_to_toppings),

--unnesting the toppings
Topping_unnest AS
(SELECT order_id,customer_id, row_num,pizza_id, exclusions,
CAST(unnest(STRING_TO_ARRAY(toppings_new,',')) AS varchar) AS toppings
FROM extras_concat
ORDER BY order_id, customer_id),

--Removing the exclusions
Exclusion_removal AS
(SELECT *
FROM topping_unnest
WHERE POSITION(TRIM(toppings) in exclusions)=0),

--Joining the toppings with the topping_name
topping_name AS
(SELECT CAST(EX.toppings AS integer), pi.topping_name 
FROM exclusion_removal ex
INNER JOIN pizza_toppings pi
ON CAST(EX.toppings AS integer)= pi.topping_id)

-- Final output of quantity of each ingredient
SELECT topping_name, COUNT(*) AS quantity
FROM topping_name
GROUP BY topping_name
ORDER BY quantity desc;





