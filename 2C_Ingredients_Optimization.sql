-- C. Ingredient Optimization
-- 1. What are the standard ingredients for each pizza?

WITH CTE AS(
SELECT pizza_id, 
CAST(unnest(string_to_array(toppings,',')) AS integer)AS ingredient_id
FROM Pizza_recipes),

CTE1 AS(
SELECT pizza_id, ingredient_id, top.topping_name FROM CTE
INNER JOIN pizza_toppings top
ON CTE.ingredient_id=top.topping_id
ORDER BY pizza_id, ingredient_id)

SELECT pizza_id,
STRING_AGG(topping_name,',') AS standard_ingredients
FROM CTE1
GROUP BY pizza_id;

-- 2. What was the most commonly added extra?
WITH CTE AS(
SELECT order_id, customer_id, pizza_id, extras,
CAST(unnest(STRING_TO_ARRAY(extras,',')) AS integer)AS add_on
FROM customer_orders_clean
WHERE extras !='NA'),

CTE1 AS
(SELECT add_on, count(add_on) AS total_times_added
FROM CTE
GROUP BY add_on),

CTE2 AS(
SELECT add_on, total_times_added,
RANK() OVER(ORDER BY total_times_added DESC) AS Rank_extras
FROM CTE1)

SELECT add_on, top.topping_name,total_times_added,Rank_extras 
FROM CTE2
INNER JOIN pizza_toppings top
ON CTE2.add_on=top.topping_id
WHERE Rank_extras=1;

-- 3. What was the most common exclusion?

WITH CTE AS(
SELECT order_id, customer_id, pizza_id, exclusions,
CAST(unnest(STRING_TO_ARRAY(exclusions,',')) AS integer)AS excluded
FROM customer_orders_clean
WHERE exclusions !='NA'),

CTE1 AS
(SELECT excluded, count(excluded) AS total_times_excluded
FROM CTE
GROUP BY excluded),

CTE2 AS(
SELECT excluded, total_times_excluded,
RANK() OVER(ORDER BY total_times_excluded DESC) AS Rank_excluded
FROM CTE1)

SELECT excluded, top.topping_name,total_times_excluded,Rank_excluded 
FROM CTE2
INNER JOIN pizza_toppings top
ON CTE2.excluded=top.topping_id
WHERE Rank_excluded=1;

-- 4. Generate an order item for each record in the customers_orders table in the format of one of the following:
--Meat Lovers
--Meat Lovers - Exclude Beef
--Meat Lovers - Extra Bacon
--Meat Lovers - Exclude Cheese, Bacon - Extra Mushroom, Peppers
WITH CTE AS(
SELECT cust.order_id, cust.customer_id, pi.pizza_name, cust.exclusions, cust.extras,
unnest(string_to_array(exclusions,','))AS exclusion_id,
unnest(string_to_array(extras,','))AS extras_id
FROM customer_orders_clean cust
INNER JOIN pizza_names pi
on cust.pizza_id=pi.pizza_id
ORDER BY cust.order_id),

CTE2 AS(
SELECT order_id, customer_id, pizza_name,
CASE WHEN exclusion_id='NA' THEN null ELSE exclusion_id END AS exclusion_id,
CASE WHEN extras_id='NA' THEN null ELSE extras_id END AS extras_id
FROM CTE),

CTE3 AS(
SELECT order_id, customer_id, pizza_name,
CAST(exclusion_id AS integer) AS exclusion_id,
CAST(extras_id AS integer) AS extras_id
FROM CTE2),

CTE4 AS(
SELECT order_id, customer_id, pizza_name,exclusion_id,extras_id,
CASE WHEN exclusion_id ISNULL THEN null ELSE top.topping_name END AS excluded_topping,
CASE WHEN extras_id ISNULL THEN null ELSE top1.topping_name END AS extra_topping
FROM CTE3 LEFT JOIN pizza_toppings top
ON CTE3.exclusion_id=top.topping_id 
LEFT JOIN pizza_toppings top1
ON CTE3.extras_id=top1.topping_id
ORDER BY order_id, customer_id),
	
CTE5 AS(
SELECT order_id, customer_id, pizza_name, excluded_topping, extra_topping
FROM CTE4
WHERE (exclusion_id ISNULL AND extras_id ISNULL) OR
(exclusion_id NOTNULL AND extras_id ISNULL) OR
(exclusion_id ISNULL AND extras_id NOTNULL)
AND (order_id NOT IN(9,10))),

CTE6 AS(
SELECT order_id, customer_id, pizza_name, excluded_topping, extra_topping
FROM CTE4
WHERE 
order_id IN (9,10)
AND NOT (exclusion_id ISNULL AND extras_id ISNULL)),

CTE7 AS(
SELECT order_id, customer_id, pizza_name,
STRING_AGG(excluded_topping,',') AS excluded_topping,
STRING_AGG(extra_topping,',') AS extra_topping
FROM CTE6
GROUP BY order_id,customer_id,pizza_name),

FINAL_LIST AS(
SELECT * FROM CTE5
UNION ALL
SELECT * FROM CTE7
ORDER BY order_id)

SELECT order_id, customer_id,pizza_name, 
CASE WHEN excluded_topping ISNULL AND extra_topping ISNULL THEN pizza_name
	WHEN excluded_topping NOTNULL AND extra_topping NOTNULL 
		THEN CONCAT(pizza_name,'-','Exclude ',excluded_topping,'-','Extra ',extra_topping)
	WHEN excluded_topping NOTNULL AND extra_topping ISNULL THEN CONCAT(pizza_name,'-','Exclude ',excluded_topping)
	WHEN excluded_topping ISNULL AND extra_topping NOTNULL THEN CONCAT(pizza_name,'-','Extra ',extra_topping) 
	END AS order_item
FROM FINAL_LIST;

