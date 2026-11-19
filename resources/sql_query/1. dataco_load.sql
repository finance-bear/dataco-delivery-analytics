CREATE SCHEMA dataco;
USE dataco;

SELECT COUNT(*) FROM raw;
DESCRIBE raw;

#FIXING COLUMN NAME
SELECT
    COLUMN_NAME AS old_name,
    TRIM(BOTH '_' FROM
        LOWER(
            REGEXP_REPLACE(COLUMN_NAME, '[^a-zA-Z0-9]+', '_')
			 )
			 ) AS new_name
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'dataco'
  AND TABLE_NAME = 'raw'
ORDER BY ORDINAL_POSITION;

SET SESSION group_concat_max_len = 20000;

SELECT CONCAT(
    'ALTER TABLE `raw` ',
    GROUP_CONCAT(
        CONCAT(
            'RENAME COLUMN `',
            REPLACE(COLUMN_NAME, '`', '``'),
            '` TO `',
            TRIM(BOTH '_' FROM
                LOWER(
                    REGEXP_REPLACE(
                        COLUMN_NAME,
                        '[^a-zA-Z0-9]+',
                        '_'
                    )
                )
            ),
            '`'
        )
        ORDER BY ORDINAL_POSITION
        SEPARATOR ', '
    ),
    ';'
) AS generated_sql
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'dataco'
  AND TABLE_NAME = 'raw';


ALTER TABLE `raw` 
	RENAME COLUMN `﻿Type` TO `type`,
	RENAME COLUMN `Days for shipping (real)` TO `days_for_shipping_real`,
	RENAME COLUMN `Days for shipment (scheduled)` TO `days_for_shipping_scheduled`;

ALTER TABLE `raw`
	RENAME COLUMN `Benefit per order` TO `benefit`,
	RENAME COLUMN `Sales per customer` TO `sales_per_customer`,
	RENAME COLUMN `Delivery Status` TO `delivery_status`,
	RENAME COLUMN `Late_delivery_risk` TO `late_delivery_risk`,
	RENAME COLUMN `Category Id` TO `category_id`,
	RENAME COLUMN `Category Name` TO `category_name`,
	RENAME COLUMN `Customer City` TO `customer_city`,
	RENAME COLUMN `Customer Country` TO `customer_country`,
	RENAME COLUMN `Customer Email` TO `email`,
	RENAME COLUMN `Customer Fname` TO `first_name`,
	RENAME COLUMN `Customer Id` TO `customer_id`,
	RENAME COLUMN `Customer Lname` TO `last_name`, 
	RENAME COLUMN `Customer Password` TO `customer_password`, 
    RENAME COLUMN `Customer Segment` TO `customer_segment`, 
    RENAME COLUMN `Customer State` TO `customer_state`, 
    RENAME COLUMN `Customer Street` TO `customer_street`,
    RENAME COLUMN `Customer Zipcode` TO `customer_zipcode`,
	RENAME COLUMN `Department Id` TO `department_id`,
	RENAME COLUMN `Department Name` TO `department_name`,
	RENAME COLUMN `Latitude` TO `latitude`,
	RENAME COLUMN `Longitude` TO `longitude`,
	RENAME COLUMN `Market` TO `market`,
	RENAME COLUMN `Order City` TO `order_city`,
	RENAME COLUMN `Order Country` TO `order_country`,
	RENAME COLUMN `Order Customer Id` TO `order_customer_id`,
	RENAME COLUMN `order date (DateOrders)` TO `order_date`,
	RENAME COLUMN `Order Id` TO `order_id`,
	RENAME COLUMN `Order Item Cardprod Id` TO `item_product_id`,
	RENAME COLUMN `Order Item Discount` TO `item_discount`,
	RENAME COLUMN `Order Item Discount Rate` TO `item_discount_rate`,
	RENAME COLUMN `Order Item Id` TO `item_id`,
	RENAME COLUMN `Order Item Product Price` TO `item_product_price`,
	RENAME COLUMN `Order Item Profit Ratio` TO `item_profit_ratio`,
	RENAME COLUMN `Order Item Quantity` TO `item_quantity`,
	RENAME COLUMN `Sales` TO `total_before_discount`,
	RENAME COLUMN `Order Item Total` TO `total_after_discount`,
	RENAME COLUMN `Order Profit Per Order` TO `profit`,
	RENAME COLUMN `Order Region` TO `order_region`,
	RENAME COLUMN `Order State` TO `order_state`,
	RENAME COLUMN `Order Status` TO `order_status`,
	RENAME COLUMN `Order Zipcode` TO `order_zipcode`,
	RENAME COLUMN `Product Card Id` TO `product_id`,
	RENAME COLUMN `Product Category Id` TO `product_category_id`,
	RENAME COLUMN `Product Description` TO `product_description`,
	RENAME COLUMN `Product Image` TO `product_imgage`,
	RENAME COLUMN `Product Name` TO `product_name`,
	RENAME COLUMN `Product Price` TO `product_price`,
	RENAME COLUMN `Product Status` TO `product_status`,
	RENAME COLUMN `shipping date (DateOrders)` TO `shipping_date`,
	RENAME COLUMN `Shipping Mode` TO `shipping_mode`;

# WORKING TABLE FOR CLEANING
CREATE TABLE cleaning AS
	SELECT
		-- orders + delivery
        order_id,
		order_status,
        order_date,
        order_customer_id,
        type,
        total_before_discount,
        total_after_discount,
        benefit,
        profit,
        market,
        order_region,
		order_country,
		order_city,
        order_state,
        delivery_status,
        shipping_date,
        shipping_mode,
        days_for_shipping_real,
        days_for_shipping_scheduled,
        late_delivery_risk,
        
        -- order_items
        item_id,
        item_product_id,
        item_product_price,
        item_quantity,
        item_discount_rate,
        item_discount,
        item_profit_ratio,
        
        -- products
        product_id,
        product_name,
        product_price,
        product_status,
        category_id,
        category_name,
        department_id,
        department_name,
        
        -- customers
        customer_id,
        customer_segment,
        customer_country,
        customer_state,
        customer_city
	FROM raw;



































