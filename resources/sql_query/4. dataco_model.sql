#MODELING
DESCRIBE cleaning;

/*locations*/
CREATE TABLE locations 
	(location_id INT AUTO_INCREMENT PRIMARY KEY,
    market TEXT,
    region TEXT,
    country TEXT,
    state TEXT,
    city TEXT);
    
INSERT INTO locations (market, region, country, state, city)
WITH
cte1 AS 
    (SELECT order_country AS country, order_state AS state, order_city AS city FROM cleaning
    UNION
    SELECT customer_country, customer_state, customer_city FROM cleaning),

cte2 AS 
    (SELECT
        order_country AS country,
        order_state AS state,
        MAX(market) AS market,
        MAX(order_region) AS region
    FROM cleaning
    GROUP BY order_country, order_state),

loc_map AS 
    (SELECT
        b.market,
        b.region,
        a.country,
        a.state,
        a.city
    FROM cte1 AS a
    LEFT JOIN cte2 AS b
        ON a.country = b.country
        AND a.state = b.state)
SELECT market, region, country, state,city
FROM loc_map;

SELECT country, state 					-- Fill in NULL market and region
FROM locations
WHERE market IS NULL or region IS NULL
GROUP BY country, state;

SELECT DISTINCT(market) FROM locations;  -- Only 03 States needed to be manually filled in market and region (Puerto Rico, Hawaii and Oregon)
UPDATE locations
SET 
	market = 
		CASE WHEN country = 'Puerto Rico' THEN 'USCA'
        WHEN state IN ('Hawái', 'Oregón') THEN 'USCA'
		ELSE market
		END,
    
    region = CASE
	WHEN state IN ('Hawái', 'Oregón') THEN 'West of USA'
    WHEN country = 'Puerto Rico' THEN 'Caribbean'
    ELSE region
    END
WHERE market IS NULL or region IS NULL;


/*products*/
SELECT																																			-- Grain Chek
	product_id
FROM cleaning
GROUP BY product_id
HAVING COUNT(DISTINCT(product_name)) >1
	OR COUNT(DISTINCT(category_id)) >1
	OR COUNT(DISTINCT(category_name)) >1
	OR COUNT(DISTINCT(department_id)) >1
	OR COUNT(DISTINCT(department_name)) >1
    OR COUNT(DISTINCT(product_price)) >1;

CREATE TABLE products																															
	(product_id INT PRIMARY KEY,
	product_name TEXT,
	product_price DECIMAL(10,2),
    category_id INT,
    category_name TEXT,
    department_id INT,
    department_name TEXT);
    
INSERT INTO products(
	product_id, 
    product_name, 
    product_price,
    category_id,
    category_name,
    department_id,
    department_name)
SELECT DISTINCT 
	product_id,
    product_name,
    product_price,
    category_id,
    category_name,
    department_id,
    department_name
FROM cleaning;

SELECT 																																			-- Double Check
 (SELECT COUNT(DISTINCT(product_id)) FROM cleaning) AS source_cnt,
 (SELECT COUNT(DISTINCT(product_id)) FROM products) AS new_cnt;
 
 
/*customer*/
SELECT customer_id																																-- Grain Chek
FROM cleaning
GROUP BY customer_id
HAVING COUNT(DISTINCT(customer_segment)) > 1
	OR COUNT(DISTINCT(customer_country))> 1 
    OR COUNT(DISTINCT(customer_state))> 1 
    OR COUNT(DISTINCT(customer_city))> 1 ;

CREATE TABLE customers
	(customer_id INT PRIMARY KEY,
     customer_segment TEXT,
     location_id INT);
 
 INSERT INTO customers 
	(customer_id, 
    customer_segment, 
    location_id)
SELECT DISTINCT 
	customer_id,
    customer_segment,
    location_id
FROM locations l INNER JOIN cleaning c
ON l.country = c.customer_country
	AND l.state = c.customer_state
    AND l.city = c.customer_city;
 
 SELECT 																																		-- Double Check
	(SELECT COUNT(DISTINCT(customer_id)) FROM cleaning) AS source_cnt,
    (SELECT COUNT(DISTINCT(customer_id)) FROM customers) AS new_cnt;
 
 
 
 /*order*/
SELECT COUNT(*) AS mismatch_count
FROM cleaning
WHERE customer_id <> order_customer_id;

SELECT order_id 																																-- Grain Check
FROM cleaning 	
GROUP BY order_id
HAVING COUNT(DISTINCT (customer_id)) > 1
    OR COUNT(DISTINCT (type)) > 1
    OR COUNT(DISTINCT (order_status)) > 1
	OR COUNT(DISTINCT (order_date)) > 1
    OR COUNT(DISTINCT (delivery_status)) > 1
    OR COUNT(DISTINCT (shipping_date)) > 1
    OR COUNT(DISTINCT (shipping_mode)) > 1
    OR COUNT(DISTINCT (shipping_date)) > 1
	OR COUNT(DISTINCT (late_delivery_risk)) > 1
    OR COUNT(DISTINCT (days_for_shipping_real)) > 1
    OR COUNT(DISTINCT (days_for_shipping_scheduled)) > 1
	OR COUNT(DISTINCT (market)) > 1
	OR COUNT(DISTINCT (order_region)) > 1
    OR COUNT(DISTINCT (order_country)) > 1
    OR COUNT(DISTINCT (order_state)) > 1
    OR COUNT(DISTINCT (order_city)) > 1;			-- Category Columns are indeed orders grain
    
    
SELECT order_id										-- But Financial Columns ar in order_items grain (not like the damned data dictionary suggests)
FROM cleaning
GROUP BY order_id
HAVING COUNT(DISTINCT (total_before_discount)) > 1
    OR COUNT(DISTINCT (total_after_discount)) > 1
    OR COUNT(DISTINCT (profit)) > 1;

CREATE TABLE orders
	(order_id INT PRIMARY KEY,
     order_date DATETIME,
     order_status TEXT,
     transaction_type TEXT,
	 delivery_status TEXT,
     shipping_date DATETIME,
     shipping_mode TEXT,
     days_for_shipping_real INT,
     days_for_shipping_scheduled INT,
     late_delivery_risk INT,
     location_id INT,
     customer_id INT);
     
INSERT INTO orders
	(order_id,
     order_date, 
     order_status,
     transaction_type,
     delivery_status,
     shipping_date,
     shipping_mode,
     days_for_shipping_real,
     days_for_shipping_scheduled,
     late_delivery_risk,
     location_id,
     customer_id)
     
SELECT DISTINCT
	order_id,
    order_date,
    order_status,
    type,
    delivery_status,
    shipping_date,
    shipping_mode,
    days_for_shipping_real,
	days_for_shipping_scheduled,
	late_delivery_risk,
	location_id,
	customer_id
FROM cleaning c INNER JOIN locations l
ON  c.order_country = l.country 
	AND c.order_state = l.state
    AND c.order_city = l.city;
    
SELECT 
	(SELECT COUNT(DISTINCT(order_id)) FROM cleaning) AS source_cnt,
    (SELECT COUNT(DISTINCT(order_id)) FROM orders) AS new_cnt;
    
    

/*order_items*/
SELECT COUNT(*) AS mismatch_count
FROM cleaning
WHERE product_id <> item_product_id
OR item_product_price <> product_price;

CREATE TABLE order_items
	(item_id INT PRIMARY KEY,
     product_id INT,
     quantity INT,
     product_price DECIMAL(10,2),
     item_discount_rate DECIMAL(5,4),
     item_total_before_discount DECIMAL(10,2),
     item_discount DECIMAL(10,2),
     item_total_after_discount DECIMAL(10,2),
     item_profit DECIMAL(10,2),
     item_profit_ratio DECIMAL(5,4),
     order_id INT);

INSERT INTO order_items
	(item_id,
     product_id,
     quantity,
     product_price,
     item_discount_rate,
     item_total_before_discount,
     item_discount,
     item_total_after_discount,
     item_profit,
     item_profit_ratio,
     order_id)
SELECT
item_id,
     product_id,
     item_quantity,
     product_price,
     item_discount_rate,
     total_before_discount,
     item_discount,
     total_after_discount,
     profit,
     item_profit_ratio,
     order_id
FROM cleaning;
	
SELECT
    (SELECT COUNT(*) FROM cleaning) AS source_cnt,
    (SELECT COUNT(*) FROM order_items) AS new_cnt;


#EXPORT
SELECT * FROM locations;



