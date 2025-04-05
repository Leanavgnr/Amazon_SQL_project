# Amazon USA Sales Analysis: Exploration and Insights

In this project, I analyzed a dataset containing more than 20,000 sales records from an e-commerce platform similar to Amazon. The main objective is to explore customer behavior, evaluate product performance, and identify sales trends using PostgreSQL.

This project allowed me to address various challenges such as revenue analysis, customer segmentation, and inventory management, while focusing on data cleaning, handling missing values, and applying queries for operational needs.

To complement this analysis, an ERD diagram was created to illustrate the database structure and the relationships between the different tables.

![ERD Scratch](https://github.com/Leanavgnr/Amazon_SQL_project/blob/main/Amazon%20ERD.png)

## Configuration and Database Design

### Schema Structure

```sql
-- Table Category
DROP TABLE IF EXISTS category;
CREATE TABLE category 
(
	category_id INT PRIMARY KEY,
	category_name VARCHAR(50)
);

-- Table Customers
DROP TABLE IF EXISTS customers;
CREATE TABLE customers 
(
	customer_id INT PRIMARY KEY,
	first_name VARCHAR(50),
	last_name VARCHAR(50),
	state VARCHAR(50),
	address VARCHAR(5) DEFAULT 'xxxx'
);

-- Table Sellers
DROP TABLE IF EXISTS sellers;
CREATE TABLE sellers 
(
	seller_id INT PRIMARY KEY,
	seller_name VARCHAR(50),
	origin VARCHAR(50)
);

-- Table Products
DROP TABLE IF EXISTS products;
CREATE TABLE products
(
	product_id INT PRIMARY KEY,
	product_name VARCHAR(70),
	price FLOAT,
	cogs FLOAT,
	category_id INT, -- foreign key
	CONSTRAINT product_fk_category FOREIGN KEY (category_id) REFERENCES category(category_id)
);

-- Table Orders
DROP TABLE IF EXISTS orders;
CREATE TABLE orders 
(
	order_id INT PRIMARY KEY,
	order_date DATE,
	customer_id INT, -- FK
	seller_id INT, -- FK
	order_status VARCHAR(25), 
	CONSTRAINT orders_fk_customer_id FOREIGN KEY (customer_id) REFERENCES customers(customer_id),
	CONSTRAINT orders_fk_seller_id FOREIGN KEY (seller_id) REFERENCES sellers(seller_id)
);

-- Table Order_Items
DROP TABLE IF EXISTS order_items;
CREATE TABLE order_items 
(
	order_item_id INT PRIMARY KEY,
	order_id INT, -- FK
	product_id INT,
	quantity INT,
	price_per_unit FLOAT,  
	CONSTRAINT order_item_fk_order_id FOREIGN KEY (order_id) REFERENCES orders(order_id),
	CONSTRAINT order_item_fk_product_id FOREIGN KEY (product_id) REFERENCES products(product_id)
);

-- Table Payments
DROP TABLE IF EXISTS payments;
CREATE TABLE payments 
(
	payment_id INT PRIMARY KEY,
	order_id INT,  -- Foreign key
	payment_date DATE,
	payment_status VARCHAR(50),
	CONSTRAINT payment_fk_order_id FOREIGN KEY (order_id) REFERENCES orders(order_id)
);

-- Table Shipping
DROP TABLE IF EXISTS shipping;
CREATE TABLE shipping 
(
	shipping_id INT PRIMARY KEY,
	order_id INT,  -- FK
	shipping_date DATE,
	return_date DATE,
	shipping_providers VARCHAR(50),
	delivery_status VARCHAR(50),
	CONSTRAINT shipping_fk_order_id FOREIGN KEY (order_id) REFERENCES orders(order_id)
);

-- Table Inventory
DROP TABLE IF EXISTS inventory;
CREATE TABLE inventory
(
	inventory_id INT PRIMARY KEY,
	product_id INT, -- FK
	stock INT,
	warehouse_id INT,
	last_stock_date DATE,
	CONSTRAINT inventory_fk_product_id FOREIGN KEY (product_id) REFERENCES products(product_id)
);
```

## **Data Cleaning**

- **Removing Duplicates**: Duplicates present in the customers and orders tables were identified and removed.
- **Handling Missing Values**: Null values in critical fields (e.g., customer address, payment status) were filled with default values or treated using appropriate methods.

## **Handling Null Values**

Null values were handled based on their context:
- **Customer Addresses**: Missing addresses were replaced with default values.
- **Payment Statuses**: Orders with null payment statuses were categorized as "Pending."
- **Shipping Information**: Null return dates were left as-is since not all shipments are returned.

## Objective

The main goal of this project is to demonstrate SQL proficiency through complex queries addressing real-world e-commerce challenges.  
The analysis covers various aspects of e-commerce operations, including:

- Customer behavior
- Sales trends
- Inventory management
- Payment and shipping analysis
- Forecasts and product performance

## Identification of Business Problems

1. Low product availability due to irregular restocking.
2. High return rates for certain product categories.
3. Significant shipping delays and inconsistencies in delivery times.
4. High customer acquisition costs combined with low retention rates.

## **Business Problem Resolutions**

<br>

**1. Top 10 Products by Revenue**  
Identify the 10 products generating the highest revenue.  
Include the product name, total quantity sold, and total sales value.

```sql
-- Add a new 'total_sale' column to the 'order_items' table
ALTER TABLE order_items
ADD COLUMN total_sale FLOAT;

-- Update the 'total_sale' column with calculated values
UPDATE order_items
SET total_sale = quantity * price_per_unit;

-- Query to retrieve the top 10 products by total revenue
SELECT 
    p.product_id,
    p.product_name,
    SUM(oi.quantity) AS total_quantity,
    SUM(oi.total_sale) AS total_sales
FROM 
    order_items AS oi
JOIN 
    products AS p ON oi.product_id = p.product_id
GROUP BY 
    p.product_id, p.product_name
ORDER BY 
    total_sales DESC
LIMIT 10;
```
<br>

**2. Total Revenue by Category**  
Calculate the total revenue generated by each product category.  
Challenge: Include each category's contribution percentage to total revenue.

```sql
WITH total_quantity_sales AS (
    SELECT
        c.category_name, 
        c.category_id,
        SUM(oi.total_sale) AS total_sales,
        SUM(oi.quantity) AS total_quantity
    FROM 
        order_items AS oi
    JOIN 
        products AS p ON p.product_id = oi.product_id
    JOIN 
        category AS c ON c.category_id = p.category_id
    GROUP BY 
        c.category_name, c.category_id
    ORDER BY 
        total_sales DESC
) 
-- Calculate the sales percentage for each category
SELECT 
    tqs.category_name, 
    tqs.category_id,
    tqs.total_sales,
    tqs.total_quantity,
    (tqs.total_sales * 100) / SUM(tqs.total_sales) OVER () AS percentage_sales
FROM 
    total_quantity_sales AS tqs;
```
<br>

**3. Average Order Value (AOV)**  
Calculate the average order value for each customer.  
Challenge: Include only customers who placed more than 5 orders.

```sql
SELECT
    o.customer_id,
    c.first_name, 
    c.last_name, 
    SUM(total_sale) / COUNT(o.order_id) AS AOV, -- Average Order Value
    COUNT(o.order_id) AS total_count_orders -- Total number of orders
FROM 
    orders o
INNER JOIN customers c ON c.customer_id = o.customer_id
INNER JOIN order_items oi ON oi.order_id = o.order_id
GROUP BY 
    o.customer_id, c.first_name, c.last_name
HAVING 
    COUNT(o.order_id) > 5
ORDER BY 
    AOV DESC;
```
<br>

**4. Monthly Sales Trends**  
Identify total monthly sales over the past year.  
Challenge: Show the sales trend grouped by month, including sales for the current and previous month.

```sql
-- CTE showing monthly sales for the last 12 months
WITH schedule AS (
    SELECT 
        EXTRACT(YEAR FROM order_date) AS year, 
        EXTRACT(MONTH FROM order_date) AS months, 
        ROUND(SUM(oi.total_sale)::NUMERIC, 2) AS total_sales
    FROM orders o
    INNER JOIN order_items oi ON oi.order_id = o.order_id 
    WHERE order_date >= CURRENT_DATE - INTERVAL '1 year'
    GROUP BY months, year 
    ORDER BY total_sales DESC 
)
-- Calculate previous month's total sales
SELECT 
    year,
    months, 
    total_sales,
    LAG(total_sales) OVER (ORDER BY year, months) AS last_month_sales
FROM schedule
ORDER BY year, months;
```
<br>

**5. Least Sold**
## **6. Customer Lifetime Value (CLTV)**  
Calculate the total value of orders placed by each customer over their lifetime.  
Challenge: Rank customers based on their CLTV.

```sql
-- Select customers with their CLTV and ranking
SELECT
    o.customer_id,
    c.first_name, 
    c.last_name,
    ROUND(SUM(total_sale)::decimal, 2) AS CLTV, -- Customer Lifetime Value
    DENSE_RANK() OVER (ORDER BY SUM(total_sale) DESC) AS cx_ranking
FROM orders o
INNER JOIN customers c ON c.customer_id = o.customer_id 
INNER JOIN order_items oi ON oi.order_id = o.order_id 
GROUP BY 
    o.customer_id, 
    c.first_name, 
    c.last_name 
ORDER BY 
    CLTV DESC;
```
<br>

**7. Sales Forecast by Category**  
Forecast the total sales by category for the next month based on the trend of the last 6 months.

```sql
-- Calculate monthly sales for the last 6 months by category
WITH monthly_sales AS (
    SELECT
        c.category_id, 
        c.category_name,
        DATE_TRUNC('month', o.order_date) AS sales_month,
        SUM(oi.total_sale) AS total_sales 
    FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id 
    JOIN products p ON oi.product_id = p.product_id 
    JOIN category AS c ON p.category_id = c.category_id 
    WHERE o.order_date >= CURRENT_DATE - INTERVAL '6 months' 
    GROUP BY c.category_id, c.category_name, sales_month 
)
-- Step 2: Calculate average monthly sales and forecast
SELECT 
    category_id, 
    category_name, 
    ROUND(AVG(total_sales)::numeric, 2) AS avg_monthly_sales, 
    ROUND(AVG(total_sales)::numeric * 1.05, 2) AS predicted_sales_next_month -- +5% forecast
FROM monthly_sales
GROUP BY category_id, category_name
ORDER BY predicted_sales_next_month DESC;
```
<br>

**8. Delivery Delays**  
Identify orders where the shipping date is more than 3 days after the order date.  
Challenge: Include customer, order, and shipping provider details.

```sql
-- Query to identify delivery delays (more than 3 days after order date)
SELECT
    s.order_id, 
    c.first_name, 
    c.last_name,
    o.order_date,
    s.shipping_date, 
    s.shipping_providers
FROM shipping s
INNER JOIN orders o ON o.order_id = s.order_id
INNER JOIN customers c ON c.customer_id = o.customer_id
WHERE s.shipping_date > o.order_date + INTERVAL '3 days';
```
<br>

**10. Top Sellers**  
Identify the top 5 sellers by total sales value.  
Challenge: Include both successful and failed orders, and display the success rate.

```sql
-- CTE calculating total sales, total orders, and successful orders per seller
WITH sales_per_seller AS (
    SELECT 
        seller_id,
        ROUND(SUM(total_sale)::numeric, 2) AS total_sales,
        COUNT(*) AS total_orders,
        COUNT(*) FILTER (WHERE payments.payment_status = 'Payment Successed') AS successful_orders
    FROM order_items oi
    INNER JOIN orders o ON o.order_id = oi.order_id
    INNER JOIN payments p ON p.order_id = o.order_id
    GROUP BY seller_id
    ORDER BY total_sales DESC
)
-- Calculate the success rate and retrieve seller info
SELECT 
    sp.seller_id, 
    s.seller_name, 
    sp.total_sales, 
    sp.total_orders, 
    sp.successful_orders,
    ROUND((sp.successful_orders * 100.0 / sp.total_orders)::numeric, 2) AS success_rate
FROM sales_per_seller sp
INNER JOIN sellers s ON s.seller_id = sp.seller_id
ORDER BY sp.total_sales DESC 
LIMIT 5;
```
<br>

**11. Product Profit Margin**  
Calculate the profit margin for each product.  
Challenge: Rank products by their profit margin, from highest to lowest.

```sql
-- Select products with their profit margin and ranking
SELECT
    product_id, 
    product_name, 
    total_sales,
    total_cost, 
    pourcentage_profit_margin,
    DENSE_RANK() OVER (ORDER BY pourcentage_profit_margin DESC) AS product_ranking
FROM (
    -- Subquery calculating profit margins per product
    SELECT 
        p.product_id,
        p.product_name,
        ROUND(SUM(oi.quantity * p.price)::numeric, 2) AS total_sales,
        ROUND(SUM(oi.quantity * p.cogs)::numeric, 2) AS total_cost,
        ROUND(
            SUM(oi.quantity * p.price - (oi.quantity * p.cogs)) 
            / SUM(oi.quantity * p.price) * 100, 
            2
        ) AS pourcentage_profit_margin
    FROM order_items oi
    JOIN products p ON oi.product_id = p.product_id
    GROUP BY p.product_id, p.product_name
) AS t1
ORDER BY pourcentage_profit_margin DESC;
```
<br>

**12. Returns Analysis**  
Analyze products with the highest return rates and detect potential causes.

```sql
-- Aggregating data to calculate the return rate by product
WITH return_rates AS (
    SELECT
        p.product_id,
        p.product_name, 
        COUNT(*) AS total_orders,
        SUM(CASE WHEN o.order_status = 'Returned' THEN 1 ELSE 0 END) AS total_returns,
        ROUND(
            SUM(CASE WHEN o.order_status = 'Returned' THEN 1 ELSE 0 END)::numeric 
            / COUNT(*)::numeric * 100, 
            2
        ) AS return_rate
    FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    JOIN products p ON oi.product_id = p.product_id
    GROUP BY p.product_id, p.product_name
)

SELECT 
    rr.product_id,
    rr.product_name,
    rr.total_orders, 
    rr.total_returns, 
    rr.return_rate, 
    CASE 
        WHEN rr.return_rate > 30 THEN 'Investigate'
        ELSE 'Normal'
    END AS action_required 
FROM return_rates rr
ORDER BY rr.return_rate DESC;
```
<br>

**13. Customer Churn Analysis**  
Identify "inactive" customers who haven't ordered in the past 6 months and estimate their churn risk based on their purchase frequency.

```sql
-- Calculate the difference between order dates for each customer
WITH order_differences AS (
    SELECT 
        customer_id,
        order_date,
        LAG(order_date) OVER (PARTITION BY customer_id ORDER BY order_date) AS previous_order_date,
        DATE_PART('day', order_date::timestamp 
             - LAG(order_date) OVER (PARTITION BY customer_id ORDER BY order_date)::timestamp) AS days_between_orders
    FROM orders
),

-- Calculate customer activity
customer_activity AS (
    SELECT 
        customer_id,
        MAX(order_date) AS last_order_date,
        COUNT(*) AS total_orders,
        AVG(days_between_orders) AS avg_days_between_orders
    FROM order_differences
    GROUP BY customer_id
)

-- Analyze churn risk
SELECT 
    c.customer_id,
    c.first_name,
    c.last_name,
    ca.last_order_date,                         
    ca.total_orders,                            
    ca.avg_days_between_orders,                 
    CASE 
        WHEN CURRENT_DATE - ca.last_order_date > COALESCE(ca.avg_days_between_orders, 180) 
        THEN 'High Risk'
        ELSE 'Low Risk'
    END AS churn_risk                           
FROM customers AS c
LEFT JOIN customer_activity AS ca 
    ON c.customer_id = ca.customer_id
WHERE CURRENT_DATE - ca.last_order_date > 180;
```
## **14. Identification of High Return Rate Customers**  
Classify customers who made more than 5 returns as "High Return Rate" and others as "Normal Return Rate".  
Challenge: List customer ID, name, total orders, and total returns.

```sql
-- Identify customers with returns and count the number of returned orders
WITH returned_orders AS (
    SELECT
        orders.customer_id,
        customers.last_name,
        COUNT(*) AS count_returned_orders
    FROM orders
    LEFT JOIN customers ON customers.customer_id = orders.customer_id
    WHERE orders.order_status = 'Returned'
    GROUP BY orders.customer_id, customers.last_name
)

-- Classify customers into two categories and count total orders
SELECT 
    ro.customer_id,
    ro.last_name,
    ro.count_returned_orders, 
    COUNT(o.order_id) AS total_orders,
    CASE 
        WHEN ro.count_returned_orders > 5 THEN 'High Return Rate' 
        ELSE 'Normal Return Rate' 
    END AS category
FROM returned_orders ro
INNER JOIN orders o ON ro.customer_id = o.customer_id
GROUP BY ro.customer_id, ro.last_name, ro.count_returned_orders;
```
<br>

**15. Top 10 Products with the Greatest Revenue Decline**  
Identify the 10 products with the highest revenue drop ratio between 2022 and 2023.  
Challenge: Return product ID, product name, category name, 2022 and 2023 revenues, and the revenue drop percentage.  
Note: Drop Ratio = (sales_2023 - sales_2022) / sales_2022 * 100

```sql
-- CTE to calculate total sales amount for 2022
WITH totalsales_2022 AS (
    SELECT
        p.product_id,
        p.product_name,
        c.category_name,
        SUM(total_sale) AS sales2022 
    FROM order_items oi
    INNER JOIN orders o ON o.order_id = oi.order_id
    INNER JOIN products p ON p.product_id = oi.product_id
    INNER JOIN category c ON c.category_id = p.category_id
    WHERE EXTRACT(YEAR FROM o.order_date) = 2022 
    GROUP BY p.product_id, c.category_name, p.product_name
),

-- CTE to calculate total sales amount for 2023
totalsales_2023 AS (
    SELECT
        p.product_id,
        p.product_name,
        c.category_name,
        SUM(total_sale) AS sales2023 
    FROM order_items oi
    INNER JOIN orders o ON o.order_id = oi.order_id
    INNER JOIN products p ON p.product_id = oi.product_id
    INNER JOIN category c ON c.category_id = p.category_id
    WHERE EXTRACT(YEAR FROM o.order_date) = 2023 
    GROUP BY p.product_id, c.category_name, p.product_name
)

-- Calculate the revenue decline ratio between 2022 and 2023
SELECT 
    t22.product_id,
    t22.product_name,
    t22.category_name,
    t22.sales2022, 
    t23.sales2023, 
    ROUND((t23.sales2023 - t22.sales2022)::numeric / t22.sales2022::numeric * 100, 2) AS Decrease_ratio
FROM totalsales_2022 t22
INNER JOIN totalsales_2023 t23 ON t22.product_id = t23.product_id
WHERE t22.sales2022 > t23.sales2023
ORDER BY Decrease_ratio
LIMIT 10;
```
<br>

**16. Stored Procedure**  
Development of a function that automatically updates the inventory stock at each sale.  
As soon as a new sales record is added, the sold quantity must be deducted from the available stock in the inventory.

```sql
CREATE OR REPLACE FUNCTION update_inventory()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE inventory
    SET stock = stock - NEW.quantity
    WHERE product_id = NEW.product_id;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create the trigger
CREATE TRIGGER after_sale_trigger
AFTER INSERT ON order_items
FOR EACH ROW
EXECUTE FUNCTION update_inventory();
```
<br>

# **Learning Outcomes**

This project allowed me to:
- Design and implement a normalized database schema.
- Clean and preprocess real-world datasets for analysis.
- Use advanced SQL techniques including window functions, subqueries, joins, and stored procedures.
- Conduct deep commercial data analysis using SQL.
- Optimize query performance and efficiently handle large datasets.

# **Conclusion**

This advanced SQL project successfully demonstrates my ability to solve real-world e-commerce challenges using structured queries.  
From improving customer retention to optimizing stock and logistics, this project provides valuable insights into operational challenges and their solutions.

By completing this project, I acquired a deep understanding of how to use SQL to solve complex data problems and support business decision-making.

