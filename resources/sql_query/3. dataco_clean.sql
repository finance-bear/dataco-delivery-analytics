#VALIDITY AND CONSISTENCY
#NUMERICAL COLUMN
SELECT
	total_before_discount,
    total_after_discount,
    benefit,
    profit,
    item_discount_rate,
    item_discount,
    item_profit_ratio,
    product_price
FROM cleaning
LIMIT 10;

SELECT 																																				-- Format validity
GROUP_CONCAT(
	CONCAT(
    'SELECT ',
     QUOTE(COLUMN_NAME), ' AS column_name, ',
		'SUM(
			CASE WHEN NOT REGEXP_LIKE(
			TRIM(', COLUMN_NAME, '), ',
			QUOTE('^-?[0-9]+(\\.[0-9]+)?$'), ')
			THEN 1
			ELSE 0
			END) AS invalid_count',
	' FROM cleaning'
    )
	ORDER BY ORDINAL_POSITION
	SEPARATOR ' UNION ALL ') 
INTO @number_valid
FROM   INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'dataco' AND TABLE_NAME = 'cleaning'
 AND COLUMN_NAME IN (
	'total_before_discount',
    'total_after_discount',
    'benefit',
    'profit',
    'item_discount_rate',
    'item_discount',
    'item_profit_ratio',
    'product_price');
    
SELECT @number_valid;
PREPARE stmt FROM @number_valid;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SELECT *
FROM cleaning
WHERE ABS(
    CAST(item_discount AS DECIMAL(5,2))
    - ROUND(CAST(item_discount AS DECIMAL(5,2)), 2)
) > 0.001;

ALTER TABLE cleaning 																																-- Change datatype
MODIFY COLUMN total_before_discount DECIMAL(10,2),
MODIFY COLUMN total_after_discount DECIMAL(10,2),
MODIFY COLUMN benefit DECIMAL(10,2),
MODIFY COLUMN profit DECIMAL(10,2),
MODIFY COLUMN item_discount DECIMAL(10,2),
MODIFY COLUMN product_price DECIMAL(10,2),
MODIFY COLUMN item_product_price DECIMAL(10,2),
MODIFY COLUMN item_discount_rate DECIMAL(5,4),
MODIFY COLUMN item_profit_ratio DECIMAL(5,4);


SELECT GROUP_CONCAT( 																																-- Range Check
    CONCAT(
        'SELECT ',
        QUOTE(COLUMN_NAME), ' AS column_name, ',
        'MIN(`', COLUMN_NAME, '`) AS min_value, ',
        'MAX(`', COLUMN_NAME, '`) AS max_value, ',
        'SUM(CASE WHEN `', COLUMN_NAME, '` < 0 THEN 1 ELSE 0 END) AS negative_count, ',
        'SUM(CASE WHEN `', COLUMN_NAME, '` = 0 THEN 1 ELSE 0 END) AS zero_count ',
        'FROM cleaning'
    )
    ORDER BY ORDINAL_POSITION
    SEPARATOR ' UNION ALL '
)
INTO @range_check
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'dataco'
  AND TABLE_NAME = 'cleaning'
  AND (DATA_TYPE = 'decimal' OR DATA_TYPE = 'int')
  ;
  
PREPARE stmt FROM @range_check;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

ALTER TABLE cleaning																																-- Drop duplicate column
DROP COLUMN benefit;


SELECT order_id,																																	-- Consistency Check
	ROUND(total_before_discount - item_discount,2) AS check_discount,
    total_after_discount,
    ROUND(item_quantity*item_product_price*item_discount_rate,2) AS check_item_discount,
    item_discount
FROM cleaning
WHERE ABS(ROUND(total_before_discount - item_discount,2) - total_after_discount) >1
OR ABS(ROUND(item_quantity*item_product_price*item_discount_rate,2) - item_discount) >1;


#DATETIME COLUMN
SELECT
	order_date,
    shipping_date
FROM cleaning
LIMIT 10;

SELECT order_id																																		-- Validity Check
FROM cleaning
WHERE STR_TO_DATE(order_date, '%m/%d/%Y %H:%i') > STR_TO_DATE(shipping_date, '%m/%d/%Y %H:%i');

SELECT																																				-- Consistency Check												
	order_id,
    DATEDIFF(STR_TO_DATE(shipping_date, '%m/%d/%Y %H:%i'), STR_TO_DATE(order_date, '%m/%d/%Y %H:%i')) AS check_shippping_day,
    days_for_shipping_real
FROM cleaning
WHERE DATEDIFF(STR_TO_DATE(shipping_date, '%m/%d/%Y %H:%i'), STR_TO_DATE(order_date, '%m/%d/%Y %H:%i')) <> days_for_shipping_real;

ALTER TABLE cleaning
ADD COLUMN order_date_new DATETIME,
ADD COLUMN shipping_date_new DATETIME;


SET SQL_SAFE_UPDATES = 0; 																															-- Change Datatype
UPDATE cleaning
SET
	order_date_new = STR_TO_DATE(order_date, '%m/%d/%Y %H:%i'),
    shipping_date_new = STR_TO_DATE(shipping_date, '%m/%d/%Y %H:%i');

SELECT
	order_date_new,
    shipping_date_new
FROM cleaning
LIMIT 10;

SELECT
    COUNT(*) AS total_rows,
    SUM(order_date_new IS NULL) AS order_null,
    SUM(shipping_date_new IS NULL) AS shipping_null,
    SUM(
        STR_TO_DATE(order_date, '%m/%d/%Y %H:%i') <> order_date_new
    ) AS order_mismatch,
    SUM(
        STR_TO_DATE(shipping_date, '%m/%d/%Y %H:%i') <> shipping_date_new
    ) AS shipping_mismatch
FROM cleaning;

ALTER TABLE cleaning
	DROP COLUMN order_date,
	DROP COLUMN shipping_date,
	RENAME COLUMN order_date_new TO order_date,
	RENAME COLUMN shipping_date_new TO shipping_date;

SET SQL_SAFE_UPDATES = 1;
DESCRIBE cleaning;



-- CATEGORICAL COLUMNS
SELECT DISTINCT(customer_segment)  -- Consistent Columns: order_status,type, market,order_region,delivery_status,shipping_mode,category_name,department_name,customer_segment
FROM cleaning
ORDER BY customer_segment ASC;

SELECT 							   -- ID+Name Consistency: product, category, department
	category_id,
    COUNT(DISTINCT(category_name))
FROM cleaning
GROUP BY category_id
HAVING COUNT(DISTINCT(category_name)) >1
ORDER BY category_id ASC;


-- LOCATIONAL COLUMNS 
SELECT DISTINCT(customer_country) FROM cleaning;						-- Customers only come from EE. UU (the US in Spanish) and Puerto.Rico																																															

SELECT customer_country, customer_state									-- In addition, the customers' states are record in STATE CODE, not full
FROM cleaning
WHERE customer_country = 'EE. UU.'
GROUP BY customer_country, customer_state;

SELECT order_country, order_state										-- Howerver in order_country, the US is Estados Unidos, not EE.UU 
FROM cleaning 															-- And orders' states are record in their fullname 
WHERE order_country = 'Estados Unidos'
GROUP BY order_country, order_state;


SET SQL_SAFE_UPDATES = 0;
UPDATE cleaning
SET
    customer_state = CASE customer_state
        WHEN 'CA' THEN 'California'
        WHEN 'NY' THEN 'Nueva York'
        WHEN 'FL' THEN 'Florida'
        WHEN 'MA' THEN 'Massachusetts'
        WHEN 'IL' THEN 'Illinois'
        WHEN 'MT' THEN 'Montana'
        WHEN 'PA' THEN 'Pensilvania'
        WHEN 'MI' THEN 'Michigan'
        WHEN 'TX' THEN 'Texas'
        WHEN 'DE' THEN 'Delaware'
        WHEN 'GA' THEN 'Georgia'
        WHEN 'MD' THEN 'Maryland'
        WHEN 'OH' THEN 'Ohio'
        WHEN 'HI' THEN 'Hawái'
        WHEN 'NJ' THEN 'Nueva Jersey'
        WHEN 'WI' THEN 'Wisconsin'
        WHEN 'AZ' THEN 'Arizona'
        WHEN 'CO' THEN 'Colorado'
        WHEN 'MN' THEN 'Minnesota'
        WHEN 'NC' THEN 'Carolina del Norte'
        WHEN 'NM' THEN 'Nuevo México'
        WHEN 'OR' THEN 'Oregón'
        WHEN 'SC' THEN 'Carolina del Sur'
        WHEN 'VA' THEN 'Virginia'
        WHEN 'UT' THEN 'Utah'
        WHEN 'WA' THEN 'Washington'
        WHEN 'KY' THEN 'Kentucky'
        WHEN 'WV' THEN 'Virginia Occidental'
        WHEN 'RI' THEN 'Rhode Island'
        WHEN 'CT' THEN 'Connecticut'
        WHEN 'LA' THEN 'Luisiana'
        WHEN 'TN' THEN 'Tennessee'
        WHEN 'DC' THEN 'Distrito de Columbia'
        WHEN 'ND' THEN 'Dakota del Norte'
        WHEN 'MO' THEN 'Misuri'
        WHEN 'IN' THEN 'Indiana'
        WHEN 'ID' THEN 'Idaho'
        WHEN 'NV' THEN 'Nevada'
        WHEN 'KS' THEN 'Kansas'
        WHEN 'AR' THEN 'Arkansas'
        WHEN 'OK' THEN 'Oklahoma'
        WHEN 'AL' THEN 'Alabama'
        WHEN 'IA' THEN 'Iowa'
        ELSE customer_state
    END,
    customer_country = 'Estados Unidos'
WHERE customer_country = 'EE. UU.';

SELECT customer_country, customer_state
FROM cleaning
GROUP BY customer_country, customer_state;




