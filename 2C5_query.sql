--2C 5. Generate an alphabetically ordered comma separated ingredient list for each pizza order 
--from the customer_orders table and add a 2x in front of any relevant ingredients
--For example: "Meat Lovers: 2xBacon, Beef, ... , Salami"

-- TO split the list of ingredients separated by comma to individual rows
WITH topping_list AS(
SELECT pizza_id,
CAST(unnest(string_to_array(toppings,',')) AS Integer) AS toppings
FROM pizza_recipes),

--Populating the topping names
topping_name AS(
SELECT list.pizza_id,list.toppings, top.topping_name,pi.pizza_name
FROM topping_list list 
INNER JOIN pizza_toppings top
ON list.toppings=top.topping_id
INNER JOIN pizza_names pi
ON list.pizza_id=pi.pizza_id),

--Aggregating the standard toppings
default_toppings AS(
SELECT pizza_id,pizza_name,
STRING_AGG(topping_name,',') AS default_toppings
FROM topping_name
GROUP BY pizza_id,pizza_name
ORDER BY pizza_id),

--To add a row num value to customer_orders_clean table for easy manipulation
cust_row_num AS(
SELECT *,
ROW_NUMBER() OVER(PARTITION BY order_id, customer_id ORDER BY order_id, customer_id) AS row_num
FROM customer_orders_clean),

-- To unnest the exclusion and extra values from customer_orders_clean table
unnest_cust_orders AS(
SELECT order_id, customer_id, pizza_id, row_num,
unnest(string_to_array(exclusions,',')) AS exclusions,
unnest(string_to_array(extras,',')) AS extras
FROM cust_row_num),

--To convert the NA values to NULL in unnest_cust_orders table for datatype conversion further
cust_NA_to_Null AS(
SELECT order_id, customer_id, pizza_id,row_num,
CASE WHEN exclusions='NA' THEN null ELSE exclusions END AS exclusions,
CASE WHEN extras='NA' THEN null ELSE extras END AS extras
FROM unnest_cust_orders
ORDER BY order_id),

--Datatype conversion of exclusions and extras columns to integer
cust_clean AS(
SELECT order_id, customer_id, pizza_id, row_num,
CAST(exclusions AS integer),
CAST(extras AS integer)
FROM cust_NA_to_Null),

--Populating the extras and exclusion names from pizza_toppings table
extra_exclusions AS(
SELECT order_id, customer_id, pizza_id, exclusions, extras, row_num,
CASE WHEN exclusions ISNULL THEN null ELSE top.topping_name END AS excluded_topping,
CASE WHEN extras ISNULL THEN null ELSE top1.topping_name END AS extra_topping
FROM cust_clean cust
LEFT JOIN pizza_toppings top
ON cust.exclusions=top.topping_id
LEFT JOIN pizza_toppings top1
ON cust.extras=top1.topping_id
ORDER BY order_id, customer_id, row_num),

-- Aggregating the excluded and extras topping names into single row
extra_exclude_agg AS(
SELECT order_id, customer_id, pizza_id, row_num,
STRING_AGG(excluded_topping,',' ORDER BY excluded_topping) AS exclusions,
STRING_AGG(extra_topping,',' ORDER BY extra_topping) AS extras
FROM extra_exclusions
GROUP BY order_id, customer_id, row_num, pizza_id
ORDER BY order_id, customer_id),


--Populating the standard topping values in the cust_clean from pizza_toppings table
std_toppings AS(
SELECT cust.order_id, cust.customer_id, cust.pizza_id,pi.pizza_name, list.toppings,top.topping_name,cust.row_num
FROM cust_row_num cust
INNER JOIN pizza_names pi
ON cust.pizza_id=pi.pizza_id
INNER JOIN topping_list list 
ON cust.pizza_id=list.pizza_id
INNER JOIN pizza_toppings top
ON list.toppings=top.topping_id
ORDER BY order_id, customer_id,row_num, pizza_name,topping_name),

--Joining  from extra_exclusions_agg with std_toppings by inner join

full_table AS(
SELECT std.order_id, std.customer_id, std.row_num,std.pizza_name,std.topping_name,
ex.excluded_topping, ex.extra_topping, exag.exclusions, exag.extras
FROM std_toppings std
INNER JOIN extra_exclusions ex
ON std.order_id=ex.order_id AND std.customer_id=ex.customer_id
AND std.row_num=ex.row_num 
INNER JOIN extra_exclude_agg exag
ON std.order_id=exag.order_id AND std.customer_id=exag.customer_id
AND std.row_num=exag.row_num 	
ORDER BY std.order_id, std.customer_id, std.row_num),

-- orders with no exclusion and no extras
No_exclusion_extras AS(
SELECT * FROM full_table 
WHERE exclusions isnull and extras isnull),

--Aggregating the toppings into a single row for each order
No_exclusion_extras_agg AS(
SELECT order_id,customer_id,pizza_name,
STRING_AGG(topping_name,',' ORDER BY topping_name) AS ingredients
FROM No_exclusion_extras
GROUP BY order_id,customer_id,pizza_name),


--Orders with exclusions or extras or both
With_exclusion_extras AS(
SELECT * FROM full_table 
WHERE (exclusions notnull and extras notnull) OR
(exclusions isnull and extras notnull) OR
(exclusions notnull and extras isnull)),

--Removing the rows with excluded toppings
Exclusions AS(
SELECT * FROM With_exclusion_extras
WHERE exclusions isnull  OR
POSITION(topping_name in exclusions)=0),

--Records from With_exclusions_extras where extras is null
No_extras AS(
SELECT * FROM Exclusions
WHERE extras isnull),

--Aggregating the toppings into a single row for each order that has no extras(with row_num)
No_extras_agg_row_num AS(
SELECT order_id,customer_id,pizza_name, row_num,
STRING_AGG(topping_name,',' ORDER BY topping_name) AS ingredients
FROM No_extras
GROUP BY order_id,customer_id,pizza_name,row_num),

--No_extras dropping row_num
No_extras_agg AS(
SELECT order_id,customer_id,pizza_name, ingredients
FROM No_extras_agg_row_num),

--Adding 2x to the extra topping which are part of std ingredients
extra_std_ingredient AS(
SELECT Ex.order_id, ex.customer_id, ex.row_num, ex.pizza_name, ex.topping_name,
	ex.excluded_topping, ex.extra_topping,ex.exclusions,ex.extras,de.default_toppings,
CASE WHEN extras notnull AND POSITION(topping_name IN extras)>0 
	THEN CONCAT('2x',topping_name) 
	WHEN extras notnull AND POSITION(topping_name IN extras)=0 AND POSITION(extra_topping IN de.default_toppings)>0
	THEN topping_name
	ELSE topping_name 
	END AS topping_name_new,
CASE WHEN extras notnull AND POSITION(topping_name IN extras)=0 AND POSITION(extra_topping IN de.default_toppings)=0
	THEN extra_topping
	ELSE ''
	END AS new_addition
FROM Exclusions Ex
INNER JOIN default_toppings de
ON Ex.pizza_name=de.pizza_name
WHERE extras notnull
ORDER BY order_id, customer_id, row_num),

--Merging the ingredients into single row
extra_std_ingredient_agg AS(
SELECT order_id,customer_id,row_num,pizza_name,new_addition,
STRING_AGG(DISTINCT topping_name_new,',' ORDER BY topping_name_new) AS Ingredients
FROM extra_std_ingredient
GROUP BY order_id,customer_id,row_num,pizza_name,new_addition),

--Concatenating the new additional ingredients
extra_new_ingredient AS(
SELECT order_id,customer_id, pizza_name,
CONCAT (new_addition,',',Ingredients) AS complete_ingredients
FROM extra_std_ingredient_agg),

--Unnesting the complete ingredient and re-aggregating to ensure the alphabetical list
Ingredient_unnest AS (
SELECT order_id,customer_id, pizza_name,
unnest(string_to_array(complete_ingredients,',')) AS ingredients
FROM extra_new_ingredient),

-- Recombining and removing the blanks
All_extra_exclusion AS(
SELECT order_id,customer_id,pizza_name,
STRING_AGG(ingredients,',' ORDER BY ingredients) AS ingredients
FROM Ingredient_unnest
WHERE ingredients <> ''
GROUP BY order_id, customer_id,pizza_name),

--Combining all the tables
--1.No_exclusion_extras_agg
--2.No_extras_agg
--3.All_extra_exclusion
Final_combine AS 
(SELECT * FROM No_exclusion_extras_agg
UNION ALL
SELECT * FROM No_extras_agg
UNION ALL
SELECT * FROM All_extra_exclusion)

SELECT order_id,customer_id, CONCAT(pizza_name, ' : ',ingredients) AS Ingredients
FROM Final_combine
ORDER BY order_id,customer_id;




