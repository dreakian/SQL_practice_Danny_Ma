// -- 1.How many runners signed up for each 1 week period? (i.e. week starts 2021-01-01)

SELECT DATE_TRUNC('week', registration_date) + 4 AS first_week_registration, COUNT(runner_id) AS count_of_runners
FROM runners AS r
GROUP BY first_week_registration;

// -- 2. What was the average time in minutes it took for each runner to arrive at the Pizza Hunter HQ to pickup the order?

SELECT runner_id,
AVG(TIMEDIFF(MINUTE, order_time, pickup_time::timestamp_ntz)) AS average_time_for_pickup
FROM runner_orders AS ro
INNER JOIN customer_orders AS co ON ro.order_id = co.order_id
WHERE pickup_time NOT LIKE 'null'
GROUP BY runner_id;

// -- 3. Is there any relationshp between the number of pizzas and how long the order takes to prepare?

WITH data AS (
 
    SELECT co.order_id,
    COUNT(pizza_id) AS pizza_count,
    MAX(TIMEDIFF('minute', order_time, pickup_time)) AS prep_time
    FROM runner_orders AS ro
    INNER JOIN customer_orders AS co ON ro.order_id = co.order_id
    WHERE pickup_time<>'null'
    GROUP BY co.order_id
)

SELECT pizza_count,
        AVG(prep_time) AS avg_prep_time
FROM data
GROUP BY pizza_count;

// -- 4. What was the average distance travelled for each customer?

SELECT co.customer_id, AVG(REPLACE(distance, 'km'):: NUMERIC(3, 1)) AS avg_distance
FROM runner_orders AS ro
INNER JOIN customer_orders AS co ON ro.order_id = co.order_id
WHERE pickup_time NOT LIKE 'null'
GROUP BY co.customer_id;

// -- 5. What was the difference between the longest and shortest delivery times for all orders?

SELECT
    MAX(REGEXP_REPLACE(duration, '[^0-9]', '')::INTEGER) - MIN(REGEXP_REPLACE(duration, '[^0-9]', '')::INTEGER) AS time_difference
FROM runner_orders AS ro
INNER JOIN customer_orders AS co ON ro.order_id = co.order_id
WHERE duration NOT LIKE 'null'
ORDER BY co.order_id;

// -- 6. What was the average speed for each runner for each delivery and do you notice any trend for these values?

SELECT
    runner_id,
    co.order_id, 
    AVG(REPLACE(distance, 'km')::numeric(3,1) / REGEXP_REPLACE(duration, '[^0-9]', '')::numeric(3,1)) AS avg_speed
FROM runner_orders AS ro
INNER JOIN customer_orders AS co ON ro.order_id = co.order_id
WHERE pickup_time NOT LIKE 'null'
GROUP BY runner_id, co.order_id
ORDER BY runner_id, co.order_id;

// -- 7. What is the successful delivery percentage for each runner?

SELECT 
    runner_id,  
    SUM(CASE
        WHEN pickup_time NOT LIKE 'null' THEN 1
        ELSE 0
    END) / COUNT(order_id) * 100
    AS successful_delivery_percentage
FROM runner_orders
GROUP BY runner_id;



