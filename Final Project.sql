USE instacart;

-- Question 1: How frequently do users place orders?
SELECT 
    frequency_category,
    COUNT(DISTINCT user_id) AS number_of_users,
    ROUND(COUNT(DISTINCT user_id) * 100.0 / (SELECT COUNT(DISTINCT user_id) FROM orders), 2) AS percentage
FROM (
    SELECT 
        user_id,
        CASE 
            WHEN AVG(days_since_prior) <= 7 THEN 'once_a_week'
            WHEN AVG(days_since_prior) > 7 AND AVG(days_since_prior) <= 14 THEN 'once_2_weeks'
            WHEN AVG(days_since_prior) >= 30 THEN 'once_a_month'
            ELSE 'other'
        END AS frequency_category
    FROM orders
    WHERE days_since_prior IS NOT NULL
    GROUP BY user_id
) AS user_frequency
GROUP BY frequency_category
ORDER BY number_of_users DESC;

-- Question 2: Average number of products per order
SELECT 
    'Overall Average' AS user_type,
    ROUND(AVG(products_per_order), 2) AS avg_products_per_order
FROM (
    SELECT order_id, COUNT(product_id) AS products_per_order
    FROM order_products
    GROUP BY order_id
) AS order_sizes;

SELECT 
    'Once a Week' AS user_type,
    ROUND(AVG(products_per_order), 2) AS avg_products_per_order
FROM (
    SELECT op.order_id, COUNT(op.product_id) AS products_per_order
    FROM order_products op
    INNER JOIN orders o ON op.order_id = o.order_id
    WHERE o.user_id IN (
        SELECT user_id
        FROM orders
        WHERE days_since_prior IS NOT NULL
        GROUP BY user_id
        HAVING AVG(days_since_prior) <= 7
    )
    GROUP BY op.order_id
) AS weekly_orders;

SELECT 
    'Once a Month' AS user_type,
    ROUND(AVG(products_per_order), 2) AS avg_products_per_order
FROM (
    SELECT op.order_id, COUNT(op.product_id) AS products_per_order
    FROM order_products op
    INNER JOIN orders o ON op.order_id = o.order_id
    WHERE o.user_id IN (
        SELECT user_id
        FROM orders
        WHERE days_since_prior IS NOT NULL
        GROUP BY user_id
        HAVING AVG(days_since_prior) >= 30
    )
    GROUP BY op.order_id
) AS monthly_orders;

-- Question 3: Top 5 reordered products by weekly purchasers
SELECT 
    p.product_id,
    p.product_name,
    COUNT(*) AS reorder_count
FROM order_products op
INNER JOIN products p ON op.product_id = p.product_id
INNER JOIN orders o ON op.order_id = o.order_id
WHERE op.reordered = '1'
AND o.user_id IN (
    SELECT user_id
    FROM orders
    WHERE days_since_prior IS NOT NULL
    GROUP BY user_id
    HAVING AVG(days_since_prior) <= 7
)
GROUP BY p.product_id, p.product_name
ORDER BY reorder_count DESC
LIMIT 5;

-- Question 4: Relationship between reorders and add_to_cart_order
SELECT 
    product_id,
    SUM(CASE WHEN reordered = '1' THEN 1 ELSE 0 END) AS total_reorders,
    ROUND(AVG(add_to_cart_order), 2) AS avg_cart_position
FROM order_products
GROUP BY product_id
HAVING total_reorders > 0
ORDER BY total_reorders DESC
LIMIT 100;

-- Question 5: User segmentation by reorder interval
SELECT 
    segment,
    COUNT(user_id) AS number_of_users,
    ROUND(COUNT(user_id) * 100.0 / (SELECT COUNT(DISTINCT user_id) 
                                      FROM orders 
                                      WHERE days_since_prior IS NOT NULL), 2) AS percentage
FROM (
    SELECT 
        user_id,
        AVG(days_since_prior) AS avg_days,
        CASE 
            WHEN AVG(days_since_prior) <= 5 THEN 'Segment 1: Very Frequent (<=5 days)'
            WHEN AVG(days_since_prior) <= 10 THEN 'Segment 2: Frequent (6-10 days)'
            WHEN AVG(days_since_prior) <= 15 THEN 'Segment 3: Regular (11-15 days)'
            WHEN AVG(days_since_prior) <= 25 THEN 'Segment 4: Occasional (16-25 days)'
            ELSE 'Segment 5: Rare (>25 days)'
        END AS segment
    FROM orders
    WHERE days_since_prior IS NOT NULL
    GROUP BY user_id
) AS user_segments
GROUP BY segment
ORDER BY segment;

-- Question 6: Department with most/least units ordered
SELECT 
    d.department,
    SUM(1) AS total_units_ordered
FROM order_products op
INNER JOIN products p ON op.product_id = p.product_id
INNER JOIN departments d ON p.department_id = d.department_id
GROUP BY d.department
ORDER BY total_units_ordered DESC
LIMIT 1;

SELECT 
    d.department,
    SUM(1) AS total_units_ordered
FROM order_products op
INNER JOIN products p ON op.product_id = p.product_id
INNER JOIN departments d ON p.department_id = d.department_id
GROUP BY d.department
ORDER BY total_units_ordered ASC
LIMIT 1;

SELECT 
    d.department,
    COUNT(DISTINCT p.product_id) AS distinct_products_ordered
FROM order_products op
INNER JOIN products p ON op.product_id = p.product_id
INNER JOIN departments d ON p.department_id = d.department_id
GROUP BY d.department
ORDER BY distinct_products_ordered DESC
LIMIT 1;

SELECT 
    d.department,
    COUNT(DISTINCT p.product_id) AS distinct_products_ordered
FROM order_products op
INNER JOIN products p ON op.product_id = p.product_id
INNER JOIN departments d ON p.department_id = d.department_id
GROUP BY d.department
ORDER BY distinct_products_ordered ASC
LIMIT 1;

-- Question 7: Products that have never been ordered
SELECT 
    p.product_id,
    p.product_name
FROM products p
LEFT JOIN order_products op ON p.product_id = op.product_id
WHERE op.product_id IS NULL;

-- Question 8: Aisle with most top-selling products
WITH top_products AS (
    SELECT 
        product_id,
        COUNT(DISTINCT order_id) AS order_count
    FROM order_products
    GROUP BY product_id
    ORDER BY order_count DESC
    LIMIT 100
)
SELECT 
    p.aisle_id,
    a.aisle,
    COUNT(*) AS top_product_count
FROM top_products tp
INNER JOIN products p ON tp.product_id = p.product_id
INNER JOIN aisles a ON p.aisle_id = a.aisle_id
GROUP BY p.aisle_id, a.aisle
ORDER BY top_product_count DESC
LIMIT 1;

-- Question 9: Products ordered once in top-selling aisle
WITH top_aisle AS (
    SELECT p.aisle_id
    FROM (
        SELECT product_id, COUNT(DISTINCT order_id) AS order_count
        FROM order_products
        GROUP BY product_id
        ORDER BY order_count DESC
        LIMIT 100
    ) AS top_products
    INNER JOIN products p ON top_products.product_id = p.product_id
    GROUP BY p.aisle_id
    ORDER BY COUNT(*) DESC
    LIMIT 1
),
product_reorder_counts AS (
    SELECT 
        product_id,
        SUM(CASE WHEN reordered = '1' THEN 1 ELSE 0 END) AS reorder_count
    FROM order_products
    GROUP BY product_id
)
SELECT 
    p.product_id,
    p.product_name,
    prc.reorder_count
FROM products p
INNER JOIN top_aisle ta ON p.aisle_id = ta.aisle_id
INNER JOIN product_reorder_counts prc ON p.product_id = prc.product_id
WHERE prc.reorder_count = 0
ORDER BY p.product_id;

-- Question 10: Top 10 products most often added first to cart
SELECT 
    p.product_id,
    p.product_name,
    d.department,
    COUNT(*) AS first_in_cart_count
FROM order_products op
INNER JOIN products p ON op.product_id = p.product_id
INNER JOIN departments d ON p.department_id = d.department_id
WHERE op.add_to_cart_order = 1
GROUP BY p.product_id, p.product_name, d.department
ORDER BY first_in_cart_count DESC
LIMIT 10;

-- Question 11: Are top 10 most-ordered products likely to be reordered?
WITH top_10_products AS (
    SELECT 
        product_id,
        COUNT(order_id) AS total_orders
    FROM order_products
    GROUP BY product_id
    ORDER BY total_orders DESC
    LIMIT 10
)
SELECT 
    p.product_id,
    p.product_name,
    tp.total_orders,
    SUM(CASE WHEN op.reordered = '1' THEN 1 ELSE 0 END) AS reorder_count,
    ROUND(SUM(CASE WHEN op.reordered = '1' THEN 1 ELSE 0 END) * 100.0 / tp.total_orders, 2) AS reorder_ratio,
    CASE 
        WHEN ROUND(SUM(CASE WHEN op.reordered = '1' THEN 1 ELSE 0 END) * 100.0 / tp.total_orders, 2) > 60 
        THEN 'High Reorder Likelihood' 
        ELSE 'Low Reorder Likelihood' 
    END AS reorder_likelihood
FROM top_10_products tp
INNER JOIN order_products op ON tp.product_id = op.product_id
INNER JOIN products p ON tp.product_id = p.product_id
GROUP BY p.product_id, p.product_name, tp.total_orders
ORDER BY reorder_ratio DESC;

-- Question 12: Organic vs Non-organic product sales
SELECT 
    CASE 
        WHEN LOWER(p.product_name) LIKE '%organic%' THEN 'Organic'
        ELSE 'Non-Organic'
    END AS product_type,
    COUNT(op.order_id) AS total_orders,
    COUNT(DISTINCT op.product_id) AS distinct_products,
    ROUND(COUNT(op.order_id) * 100.0 / (SELECT COUNT(*) FROM order_products), 2) AS percentage_of_total_orders
FROM order_products op
INNER JOIN products p ON op.product_id = p.product_id
GROUP BY product_type
ORDER BY total_orders DESC;

-- Question 13: Top 5 ordered products per department
WITH product_order_counts AS (
    SELECT 
        p.product_id,
        p.product_name,
        d.department,
        p.department_id,
        COUNT(op.order_id) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY d.department_id ORDER BY COUNT(op.order_id) DESC) AS rank_in_dept
    FROM order_products op
    INNER JOIN products p ON op.product_id = p.product_id
    INNER JOIN departments d ON p.department_id = d.department_id
    GROUP BY p.product_id, p.product_name, d.department, p.department_id
)
SELECT 
    department,
    product_name,
    order_count,
    rank_in_dept
FROM product_order_counts
WHERE rank_in_dept <= 5
ORDER BY department, rank_in_dept;

WITH product_aisle_counts AS (
    SELECT 
        p.product_id,
        p.product_name,
        a.aisle,
        p.aisle_id,
        COUNT(op.order_id) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY a.aisle_id ORDER BY COUNT(op.order_id) DESC) AS rank_in_aisle
    FROM order_products op
    INNER JOIN products p ON op.product_id = p.product_id
    INNER JOIN aisles a ON p.aisle_id = a.aisle_id
    GROUP BY p.product_id, p.product_name, a.aisle, p.aisle_id
)
SELECT 
    aisle,
    product_name,
    order_count,
    rank_in_aisle
FROM product_aisle_counts
WHERE rank_in_aisle <= 5
ORDER BY aisle, rank_in_aisle;

-- Question 14: Weekday with highest/lowest number of orders
SELECT 
    CASE order_dow
        WHEN 0 THEN 'Saturday'
        WHEN 1 THEN 'Sunday'
        WHEN 2 THEN 'Monday'
        WHEN 3 THEN 'Tuesday'
        WHEN 4 THEN 'Wednesday'
        WHEN 5 THEN 'Thursday'
        WHEN 6 THEN 'Friday'
    END AS weekday,
    COUNT(order_id) AS order_count
FROM orders
GROUP BY order_dow
ORDER BY order_count DESC
LIMIT 1;

SELECT 
    CASE order_dow
        WHEN 0 THEN 'Saturday'
        WHEN 1 THEN 'Sunday'
        WHEN 2 THEN 'Monday'
        WHEN 3 THEN 'Tuesday'
        WHEN 4 THEN 'Wednesday'
        WHEN 5 THEN 'Thursday'
        WHEN 6 THEN 'Friday'
    END AS weekday,
    COUNT(order_id) AS order_count
FROM orders
GROUP BY order_dow
ORDER BY order_count ASC
LIMIT 1;

SELECT 
    CASE order_dow
        WHEN 0 THEN 'Saturday'
        WHEN 1 THEN 'Sunday'
        WHEN 2 THEN 'Monday'
        WHEN 3 THEN 'Tuesday'
        WHEN 4 THEN 'Wednesday'
        WHEN 5 THEN 'Thursday'
        WHEN 6 THEN 'Friday'
    END AS weekday,
    COUNT(order_id) AS order_count,
    ROUND(COUNT(order_id) * 100.0 / (SELECT COUNT(*) FROM orders), 2) AS percentage
FROM orders
GROUP BY order_dow
ORDER BY order_count DESC;

-- Question 15: Percentage of orders during daytime (8am-5pm)
SELECT 
    SUM(CASE WHEN order_hour_of_day BETWEEN 8 AND 17 THEN 1 ELSE 0 END) AS daytime_orders,
    COUNT(*) AS total_orders,
    ROUND(SUM(CASE WHEN order_hour_of_day BETWEEN 8 AND 17 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS daytime_percentage
FROM orders;

-- Question 16: Top 3 prime time-weekday combinations for reorders
SELECT 
    CASE order_dow
        WHEN 0 THEN 'Saturday'
        WHEN 1 THEN 'Sunday'
        WHEN 2 THEN 'Monday'
        WHEN 3 THEN 'Tuesday'
        WHEN 4 THEN 'Wednesday'
        WHEN 5 THEN 'Thursday'
        WHEN 6 THEN 'Friday'
    END AS weekday,
    order_hour_of_day,
    CONCAT(
        CASE order_dow
            WHEN 0 THEN 'Saturday'
            WHEN 1 THEN 'Sunday'
            WHEN 2 THEN 'Monday'
            WHEN 3 THEN 'Tuesday'
            WHEN 4 THEN 'Wednesday'
            WHEN 5 THEN 'Thursday'
            WHEN 6 THEN 'Friday'
        END,
        ' ',
        order_hour_of_day,
        CASE 
            WHEN order_hour_of_day = 0 THEN 'am'
            WHEN order_hour_of_day < 12 THEN 'am'
            WHEN order_hour_of_day = 12 THEN 'pm'
            ELSE 'pm'
        END
    ) AS prime_time,
    COUNT(o.order_id) AS reorder_count
FROM orders o
INNER JOIN order_products op ON o.order_id = op.order_id
WHERE op.reordered = '1' AND o.days_since_prior >= 0
GROUP BY order_dow, order_hour_of_day
ORDER BY reorder_count DESC
LIMIT 3;


-- Total overview statistics
SELECT 
    'Total Orders' AS metric,
    COUNT(*) AS value
FROM orders
UNION ALL
SELECT 
    'Total Users',
    COUNT(DISTINCT user_id)
FROM orders
UNION ALL
SELECT 
    'Total Products',
    COUNT(*)
FROM products
UNION ALL
SELECT 
    'Total Departments',
    COUNT(*)
FROM departments
UNION ALL
SELECT 
    'Total Aisles',
    COUNT(*)
FROM aisles
UNION ALL
SELECT 
    'Total Product Orders',
    COUNT(*)
FROM order_products;
