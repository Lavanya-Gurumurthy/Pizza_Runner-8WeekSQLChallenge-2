--Table creation, inserting data and data cleaning:

--1. Creating the database:
CREATE DATABASE pizza_runner;

--2. Creating Tables and inserting data:

--Table 1 - runners

CREATE TABLE runners (
runner_id integer primary key,
registration_date date NOT NULL );

--Inserting Data

INSERT INTO runners VALUES
(1, '2021-01-01'),
(2, '2021-01-03'),
(3, '2021-01-08'),
(4, '2021-01-15');

--Table 2 - customer_orders

CREATE TABLE customer_orders (
order_id integer,
customer_id integer NOT NULL,
pizza_id integer NOT NULL,
exclusions varchar,
extras varchar,
order_time timestamp NOT NULL);

--Inserting data

COPY customer_orders FROM 'E:\8 Week SQL challenge\pizza_customer_orders.csv' DELIMITER ',' CSV HEADER;

--Table 3 - runner_orders

CREATE TABLE runner_orders (
order_id integer NOT NULL,
runner_id integer,
pickup_time varchar,
distance varchar,
duration varchar,
cancellation varchar );

--Inserting data

COPY runner_orders FROM 'E:\8 Week SQL challenge\Pizza Runner\pizza_runner_orders.csv' DELIMITER ',' CSV HEADER;

--Table 4 - pizza_names

CREATE TABLE pizza_names (
pizza_id integer,
pizza_name varchar);

INSERT INTO pizza_names VALUES
(1, 'Meat Lovers'),
(2, 'Vegetarian');

--Table 5 - pizza_recipes

CREATE TABLE pizza_recipes (
pizza_id integer,
toppings varchar);

INSERT INTO pizza_recipes VALUES
(1, '1, 2, 3, 4, 5, 6, 8, 10'),
(2, '4, 6, 7, 9, 11, 12');

--Table 6 - pizza_toppings

CREATE TABLE pizza_toppings (
topping_id integer,
topping_name varchar);

COPY pizza_toppings FROM 'E:\8 Week SQL challenge\Pizza Runner\pizza_toppings.csv' DELIMITER ',' CSV HEADER;

---------- DATA CLEANING ------------------------------

--1. First we need clean data in the customer_orders table as it will help with filtering. 
--For this, we are not modifying the existing table but creating a new table customer_orders_clean 
--by copying the entire table customer_orders and then we will update the fields.

CREATE TABLE customer_orders_clean AS
TABLE customer_orders;

--Update Queries:
UPDATE customer_orders_clean SET exclusions='NA' WHERE exclusions IS NULL;
UPDATE customer_orders_clean SET exclusions='NA' WHERE exclusions ='null';
UPDATE customer_orders_clean SET extras='NA' WHERE extras IS NULL OR extras ='null' OR extras='NaN';

--2.We also have to update the inconsistent data in runner_order table. 
--For this as well, we are creating a new table by copying data from the old as below.
CREATE TABLE runner_orders_clean AS TABLE runner_orders;

--Update Queries:
UPDATE runner_orders_clean SET pickup_time='NA' WHERE pickup_time='null';
UPDATE runner_orders_clean SET cancellation='NA' WHERE cancellation='NaN' OR cancellation='null' OR cancellation=' ';
UPDATE runner_orders_clean SET distance='NA' WHERE distance='null';
UPDATE runner_orders_clean SET duration='NA' WHERE duration='null';

--3.In the runner_orders table, there is an issue with the values of pickup_time. 
--For some records, instead of 2021, it is recorded as 2020. 
--These are updated in the runner_orders_clean table with the below query

UPDATE runner_orders_clean SET pickup_time='08-01-2021 21:30:45' WHERE order_id=7;
UPDATE runner_orders_clean SET pickup_time='10-01-2021 00:15:02' WHERE order_id=8;
UPDATE runner_orders_clean SET pickup_time='11-01-2021 18:50:20' WHERE order_id=10;

--4. The distance value in runner_orders rable is varchar, 
--this first needs to be changed to float in order to facilitate numerical calculation.
--For this, first I updated the table by removing the 'km' portion from the distance 
--and also updating NA as 0 in runner_orders_clean table as below

UPDATE runner_orders_clean SET distance=20 WHERE order_id=1;
UPDATE runner_orders_clean SET distance=20 WHERE order_id=2;
UPDATE runner_orders_clean SET distance=13.4 WHERE order_id=3;
UPDATE runner_orders_clean SET distance=0 WHERE order_id=6;
UPDATE runner_orders_clean SET distance=25 WHERE order_id=7;
UPDATE runner_orders_clean SET distance=23.4 WHERE order_id=8;
UPDATE runner_orders_clean SET distance=0 WHERE order_id=9;
UPDATE runner_orders_clean SET distance=10 WHERE order_id=10;

--Now, we alter the datatype of the column as below
ALTER TABLE runner_orders_clean ALTER COLUMN distance TYPE FLOAT USING distance:: FLOAT;

--Since, the table has values, we need to use the 'USING' clause.

--5. We need to update/alter the duration column. 
--Similar to the previous one, first I manually changed the values in duration column 
--in runner_orders_clean by removing the minutes part of the string and then altered the datatype to double.

UPDATE runner_orders_clean SET duration=32 WHERE order_id=1;
UPDATE runner_orders_clean SET duration=27 WHERE order_id=2;
UPDATE runner_orders_clean SET duration=20 WHERE order_id=3;
UPDATE runner_orders_clean SET duration=0 WHERE order_id=6;
UPDATE runner_orders_clean SET duration=25 WHERE order_id=7;
UPDATE runner_orders_clean SET duration=15 WHERE order_id=8;
UPDATE runner_orders_clean SET duration=0 WHERE order_id=9;
UPDATE runner_orders_clean SET duration=10 WHERE order_id=10;

ALTER TABLE runner_orders_clean ALTER COLUMN duration TYPE FLOAT USING duration :: FLOAT;