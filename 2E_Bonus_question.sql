--E. Bonus Questions
--If Danny wants to expand his range of pizzas - how would this impact the existing data design? 
--Write an INSERT statement to demonstrate what would happen if a new Supreme pizza with all 
--the toppings was added to the Pizza Runner menu?

SELECT * FROM pizza_names;
--The below insert statement is executed once and is commented so that it doesnt insert repeatedly
/*
INSERT INTO pizza_names VALUES
(3,'Supreme Pizza');

DELETE FROM pizza_names WHERE pizza_id=3;
*/

SELECT * FROM pizza_recipes;

--The below insert statement is executed once and is commented so that it doesnt insert repeatedly
/*
INSERT INTO pizza_recipes VALUES
(3, '1,2,3,4,5,6,7,8,9,10,11,12');
*/