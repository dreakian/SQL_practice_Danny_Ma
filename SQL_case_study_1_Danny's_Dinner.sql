// -- 1. What is the total amount each customer spent at the restaurant?

// -- Need to join the sales and menu tables together
// -- Take the sum of the price field and order the results by customer_id
// -- The final table result should be 3 rows and 2 columns, where the rows are customer_id and the columns are customer_id and sum_price

SELECT sales.customer_id, SUM(menu.price) AS total_amount_spent
FROM sales
INNER JOIN menu ON sales.product_id = menu.product_id
GROUP BY sales.customer_id;

------------------------------------------------------------------------------------------------------------------------------------------

// -- 2. How many days has each customer visited the restaurant?

SELECT sales.customer_id, COUNT(DISTINCT(sales.order_date)) AS visits
FROM sales
GROUP BY sales.customer_id;

------------------------------------------------------------------------------------------------------------------------------------------

// -- 3. What was the first item from the menu purchased by each customer?

WITH data AS 
(
    SELECT sales.customer_id, menu.product_name, sales.order_date, menu.product_id, 
    ROW_NUMBER() OVER (PARTITION BY sales.customer_id ORDER BY sales.customer_id) AS row_num
    FROM sales
    INNER JOIN menu ON sales.product_id = menu.product_id
    WHERE sales.order_date = (SELECT MIN(sales.order_date) FROM sales)
)

SELECT data.customer_id, data.product_name AS first_product_ordered, data.order_date
FROM data
WHERE row_num = 1;

------------------------------------------------------------------------------------------------------------------------------------------

// -- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?

SELECT menu.product_name, COUNT(menu.product_name) AS product_count
FROM sales
INNER JOIN menu ON sales.product_id = menu.product_id
GROUP BY menu.product_name
ORDER BY product_count DESC
LIMIT 1;

------------------------------------------------------------------------------------------------------------------------------------------

// -- 5. Which item was the most popular for each customer?

WITH data AS 
(
    SELECT sales.customer_id, menu.product_name, COUNT(menu.product_name) AS count_product, 
    ROW_NUMBER() OVER (PARTITION BY sales.customer_id ORDER BY sales.customer_id) AS row_num
    FROM sales
    INNER JOIN menu ON sales.product_id = menu.product_id
    GROUP BY sales.customer_id, menu.product_name
)

SELECT data.customer_id, data.product_name, data.count_product
FROM data
WHERE row_num IN (1, 3)
ORDER BY data.count_product DESC
LIMIT 3;

------------------------------------------------------------------------------------------------------------------------------------------

// -- 6. Which item was purchased first by the customer after they became a member?

WITH data AS 
(
    SELECT sales.customer_id, sales.order_date, members.join_date, menu.product_name, 
    ROW_NUMBER() OVER (PARTITION BY sales.customer_id ORDER BY sales.customer_id) AS row_num 
    FROM sales
    INNER JOIN menu ON sales.product_id = menu.product_id
    INNER JOIN members ON sales.customer_id = members.customer_id
    WHERE sales.order_date > members.join_date
    ORDER BY row_num ASC
    LIMIT 2
)

SELECT data.customer_id, data.product_name, data.order_date, data.join_date
FROM data;

------------------------------------------------------------------------------------------------------------------------------------------

// -- 7. Which item was purchased just before the customer became a member?

WITH data AS 
(
    SELECT sales.customer_id, sales.order_date, members.join_date, menu.product_name, 
    ROW_NUMBER() OVER (PARTITION BY sales.customer_id ORDER BY sales.customer_id) AS row_num 
    FROM sales
    INNER JOIN menu ON sales.product_id = menu.product_id
    INNER JOIN members ON sales.customer_id = members.customer_id
    WHERE sales.order_date < members.join_date
    ORDER BY row_num ASC
    LIMIT 2
)

SELECT data.customer_id, data.product_name, data.order_date, data.join_date
FROM data;

------------------------------------------------------------------------------------------------------------------------------------------

// -- 8. What is the total items and amount spent for each member before they became a member?

WITH data AS 
(
    SELECT sales.customer_id, sales.order_date, members.join_date, COUNT(menu.product_name) AS count_product, 
    SUM(menu.price) AS total_price, 
    ROW_NUMBER() OVER (PARTITION BY count_product ORDER BY sales.customer_id) AS row_num 
    FROM sales
    INNER JOIN menu ON sales.product_id = menu.product_id
    INNER JOIN members ON sales.customer_id = members.customer_id
    WHERE sales.order_date < members.join_date
    GROUP BY sales.customer_id, sales.order_date, members.join_date
)

SELECT data.customer_id, COUNT(data.count_product) AS count_product, SUM(data.total_price) AS total_price
FROM data
WHERE data.order_date < data.join_date
GROUP BY data.customer_id;

------------------------------------------------------------------------------------------------------------------------------------------

// -- 9. If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?

-- Get the count of products. For non-sushi items, multiply those counts by 1. 
-- For sushi-items, multiple those counts by 2. 
-- Add up the resulting values and group the results by customers.

WITH data AS 
(
    SELECT sales.customer_id, menu.product_name, COUNT(menu.product_name) AS count_product, menu.price
    FROM sales
    INNER JOIN menu ON sales.product_id = menu.product_id
    GROUP BY sales.customer_id, menu.product_name, menu.price
),

points_data AS 
(
    SELECT *,
    CASE
        WHEN data.product_name LIKE '%sushi%' THEN (data.price * data.count_product) * 2
        WHEN data.product_name LIKE '%ramen%' THEN (data.price * data.count_product) * 1
        WHEN data.product_name LIKE '%curry%' THEN (data.price * data.count_product) * 1
    END AS points
    FROM data
)

SELECT points_data.customer_id, SUM(points_data.points) AS total_points
FROM points_data
GROUP BY points_data.customer_id;

------------------------------------------------------------------------------------------------------------------------------------------

// -- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?

WITH data AS
(
    SELECT sales.customer_id, sales.order_date, members.join_date, COUNT(menu.product_name) AS count_product, menu.price, menu.product_name
    FROM sales
    INNER JOIN members ON sales.customer_id = members.customer_id
    INNER JOIN menu ON sales.product_id = menu.product_id
    GROUP BY sales.customer_id, sales.order_date, members.join_date, menu.price, menu.product_name
),

points_data AS
(
    SELECT *, 
    CASE
        WHEN data.order_date BETWEEN '2021-01-01' AND '2021-01-08' THEN (data.price * data.count_product) * 2
        WHEN data.order_date BETWEEN '2021-01-09' AND '2021-01-31' AND data.product_name LIKE '%sushi%' THEN (data.price * data.count_product) * 2
        WHEN data.order_date BETWEEN '2021-01-09' AND '2021-01-31' AND data.product_name LIKE '%ramen%' THEN (data.price * data.count_product) * 1
        WHEN data.order_date BETWEEN '2021-01-09' AND '2021-01-31' AND data.product_name LIKE '%curry%' THEN (data.price * data.count_product) * 1
    END AS points
    FROM data
    WHERE data.order_date BETWEEN '2021-01-01' AND '2021-01-31'
)

SELECT points_data.customer_id, SUM(points_data.points) AS total_points
FROM points_data
GROUP BY points_data.customer_id;

------------------------------------------------------------------------------------------------------------------------------------------

// -- Bonus Question: Join All The Things

WITH data AS 
(
    SELECT sales.customer_id, sales.order_date, menu.product_name, menu.price,
    CASE
        WHEN sales.customer_id LIKE '%C%' THEN 'N'
        WHEN sales.order_date >= members.join_date AND sales.customer_id IN ('A', 'B') THEN 'Y'
        WHEN sales.order_date < members.join_date AND sales.customer_id IN ('A', 'B') THEN 'N'
    END AS member
    FROM sales
    INNER JOIN menu ON sales.product_id = menu.product_id
    LEFT JOIN members ON sales.customer_id = members.customer_id
    ORDER BY sales.customer_id ASC, sales.order_date ASC, menu.product_name ASC
)

SELECT *
FROM data;

------------------------------------------------------------------------------------------------------------------------------------------

// -- Bonus question: Rank All The Things

WITH data AS 
(
    SELECT sales.customer_id, sales.order_date, menu.product_name, menu.price,
    CASE
        WHEN sales.customer_id LIKE '%C%' THEN 'N'
        WHEN sales.order_date >= members.join_date AND sales.customer_id IN ('A', 'B') THEN 'Y'
        WHEN sales.order_date < members.join_date AND sales.customer_id IN ('A', 'B') THEN 'N'
    END AS member,
    CASE 
        WHEN member LIKE 'N' THEN NULL
        WHEN member LIKE 'Y' THEN DENSE_RANK() OVER (PARTITION BY sales.customer_id, member ORDER BY sales.order_date)
    END AS ranking
    FROM sales
    INNER JOIN menu ON sales.product_id = menu.product_id
    LEFT JOIN members ON sales.customer_id = members.customer_id
    ORDER BY sales.customer_id ASC, sales.order_date ASC, menu.product_name ASC
)

SELECT *
FROM data;
