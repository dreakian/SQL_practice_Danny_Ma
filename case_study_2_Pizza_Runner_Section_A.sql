//  -- 1. How many pizzas were ordered? 

SELECT COUNT(*) AS count_of_pizza_orders
FROM customer_orders AS co
INNER JOIN runner_orders AS ro ON co.order_id = ro.order_id

// -- 2. How many unique customer orders were made? 

SELECT COUNT(DISTINCT(co.order_id)) AS unique_count_of_customer_orders
FROM customer_orders AS co
INNER JOIN runner_orders AS ro ON co.order_id = ro.order_id

// -- 3. How many successful orders were delivered by each runner? 

// -- It's not enough that an order was made. 
// -- Orders actually had to be delivered, which means they would need to have non-null pickup_time values

SELECT runner_id, COUNT(order_id) AS successful_deliveries
FROM runner_orders
WHERE pickup_time NOT LIKE 'null'
GROUP BY runner_id

// -- 4. How many of each type of pizza was delivered? 

SELECT pn.pizza_name, COUNT(pn.pizza_name) AS count_of_pizza_type
FROM customer_orders AS co
INNER JOIN runner_orders AS ro ON co.order_id = ro.order_id
INNER JOIN pizza_names AS pn ON co.pizza_id = pn.pizza_id
WHERE pickup_time NOT LIKE 'null'
GROUP BY pn.pizza_name;

// -- 5. How many Vegetarian and Meatlovers were ordered by each customer? 

// -- Remember the difference between a pizza being ordered versus being delivered. There should be more orders than deliveries.

SELECT customer_id, pizza_name, COUNT(co.pizza_id) AS count_of_orders
FROM customer_orders AS co
INNER JOIN pizza_names AS pn ON co.pizza_id = pn.pizza_id
GROUP BY pn.pizza_name, co.customer_id;

// -- 6. What was the maximum number of pizzas delivered in a single order? 

SELECT co.order_id, COUNT(co.pizza_id) AS count_of_pizza_in_a_single_order
FROM customer_orders AS co
INNER JOIN runner_orders AS ro ON co.order_id = ro.order_id
WHERE pickup_time NOT LIKE 'null'
GROUP BY co.order_id
ORDER BY COUNT(co.pizza_id) DESC
LIMIT 1; 

// -- 7. For each customer, how many delivered pizzas had at least 1 change and how many had no changes? 

// -- Change refers to whether or not an order included an exclusion or an extra. 
// -- Basically, this means whether or not toppings were added or removed from an order. 

SELECT co.customer_id, 
    SUM(CASE 
        WHEN (
                exclusions IS NOT NULL AND exclusions NOT IN ('null', '') OR
                extras IS NOT NULL AND exclusions NOT IN ('null', '')
            ) = TRUE
                THEN 1
                ELSE 0
    END) AS changes,

    SUM(CASE 
        WHEN (
                exclusions IS NOT NULL AND exclusions NOT IN ('null', '') OR
                extras IS NOT NULL AND exclusions NOT IN ('null', '')
            ) = TRUE
                THEN 0
                ELSE 1
    END) AS no_changes
    
FROM customer_orders AS co
INNER JOIN runner_orders AS ro ON co.order_id = ro.order_id
WHERE pickup_time NOT LIKE 'null'
GROUP BY co.customer_id;

// -- 8. How many pizzas were delivered that had both exclusions and extras? 

SELECT COUNT(pizza_id) AS count_of_pizzas_delivered_with_exclusions_and_extras
FROM customer_orders AS co
INNER JOIN runner_orders AS ro ON co.order_id = ro.order_id
WHERE pickup_time NOT LIKE 'null'
AND exclusions IS NOT NULL AND exclusions NOT IN ('null', '')
AND extras IS NOT NULL AND extras NOT IN ('null', '')

// -- 9. What was the total volume of pizzas ordered for each hour of the day? 

SELECT COUNT(order_id) AS count_of_pizzas, EXTRACT(HOUR from order_time) AS hour
FROM customer_orders
GROUP BY hour

// -- 10. What was the volume of orders for each day of the week? 

SELECT DAYNAME(order_time) AS day, COUNT(pizza_id) AS count_of_pizzas
FROM customer_orders
GROUP BY day
