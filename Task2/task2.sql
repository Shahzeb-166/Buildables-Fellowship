-- CREATE TABLE QUERIES 
CREATE TABLE dim_customers (
  	customer_sk SERIAL PRIMARY KEY,
    customer_id INT,
    name VARCHAR(100),
    email VARCHAR(150),
    effective_date DATE NOT NULL,
    end_date DATE,
    is_active CHAR(1) CHECK (is_active IN ('Y','N'))
);
CREATE TABLE dim_products(
	product_sk SERIAL PRIMARY KEY,
	product_id INT,
	name VARCHAR(50),
	category VARCHAR(50)
);
CREATE TABLE dim_date(
	date_sk SERIAL PRIMARY KEY,
	full_date DATE,
	year INT,
	month INT,
	day_of_the_week VARCHAR(15)
);
CREATE TABLE fact_orders(
	order_id SERIAL PRIMARY KEY,
	order_date_sk INT REFERENCES dim_date(date_sk),
	customer_sk INT REFERENCES dim_customers(customer_sk),
	product_sk INT REFERENCES dim_products(product_sk),
	quantity INT CHECK (quantity > 0),
    price NUMERIC(10,2) CHECK (price > 0),
    total_amount NUMERIC(12,2)
);

-- Insert customers
INSERT INTO dim_customers (customer_id, name, email, effective_date, end_date, is_active)
VALUES 
(1, 'Ali Wasiq', 'aliwasiq@example.com', '2025-01-01', '2025-12-01', 'Y'),
(2, 'Baber Riaz', 'baberriaz@example.com', '2025-01-01', '2025-12-01', 'Y'),
(3, 'Shahzeb Ahmed', 'Shahzebahmed@example.com', '2025-01-01', NULL, 'Y'),
(4, 'Ashir Ali', 'ashirali@example.com', '2025-01-01', '2025-12-01', 'Y'),
(5, 'Jamal Mubeen', 'jamalmubeen@example.com', '2025-01-01', '2025-12-01', 'Y');

-- Insert products
INSERT INTO dim_products (product_id, name, category)
VALUES
(1, 'Laptop', 'Electronics'),
(2, 'Phone', 'Electronics'),
(3, 'Shoes', 'Fashion'),
(4, 'Backpack', 'Fashion'),
(5, 'Headphones', 'Electronics');

-- Insert date dimension (for simplicity only a few rows)
INSERT INTO dim_date (full_date, year, month, day_of_the_week)
VALUES
('2025-01-05', 2025, 1, 'Sunday'),
('2025-01-15', 2025, 1, 'Wednesday'),
('2025-02-10', 2025, 2, 'Monday'),
('2025-03-05', 2025, 3, 'Wednesday'),
('2025-03-10', 2025, 3, 'Monday');

-- Insert fact orders
INSERT INTO fact_orders (order_date_sk, customer_sk, product_sk, quantity, price, total_amount)
VALUES
(6, 11, 11, 1, 1000, 1000),
(7, 12, 12, 2, 600, 1200),
(8, 13, 13, 1, 80, 80),
(9, 14, 14, 2, 50, 100),
(10, 15, 15, 1, 150, 150),
(6, 12, 11, 1, 1000, 1000),
(7, 13, 12, 1, 600, 600),
(8, 11, 13, 2, 80, 160),
(9, 14, 15, 1, 150, 150),
(10, 15, 14, 3, 50, 150);

---- SCD Type-2 update
UPDATE dim_customers
SET end_date = '2025-03-01', is_active = 'N'
WHERE customer_id = 3 AND is_active = 'Y';
-- new insertion with same customer_id
INSERT INTO dim_customers (customer_id, name, email, effective_date, end_date, is_active)
VALUES (3, 'Shahzeb Iqbal', 'Shahzebiqbal55@gmail.com', '2025-03-02', NULL, 'Y');

-- QUERIES 
SELECT * FROM fact_orders;

-- 1. Show total revenue per product category. 
SELECT p.category, SUM(f.total_amount) AS total_revenue 
FROM fact_orders f
JOIN  dim_products p ON f.product_sk = p.product_sk
GROUP BY p.category;

-- 2. Show monthly revenue trend 
SELECT d.month,d.year , SUM(f.total_amount) AS monthly_revenue
FROM fact_orders f
JOIN dim_date d ON d.date_sk=f.order_date_sk
GROUP BY d.year, d.month
ORDER BY d.year, d.month;

--3. Customer whoise info has changed over time
SELECT customer_id, COUNT(*) AS version_count
FROM dim_customers
GROUP BY customer_id
HAVING COUNT(*) >= 1;

-- 4. Top 2 customers by spend in each month 
WITH monthly_spend AS (
    SELECT d.month,d.year, c.customer_id, c.name,
           SUM(f.total_amount) AS spend,
		    -- ROW_NUMBER assigns ranks starting from 1,
           -- reset for each month (PARTITION BY d.year, d.month).
           -- Customers are ordered by total spend (highest first).
           ROW_NUMBER() OVER (PARTITION BY d.year, d.month ORDER BY SUM(f.total_amount) DESC) AS rank
    FROM fact_orders f
    JOIN dim_date d ON f.order_date_sk = d.date_sk
    JOIN dim_customers c ON f.customer_sk = c.customer_sk
    GROUP BY d.year, d.month, c.customer_id, c.name
)
SELECT * FROM monthly_spend WHERE rank <= 2;

-- 5. Each customer’s order rank by date
SELECT c.name, d.full_date, f.total_amount,
-- Use RANK() to assign the order number for each customer.
-- RANK() is reset for each customer (PARTITION BY c.customer_id),
-- and ordered by date (ORDER BY d.full_date).
-- This means: the earliest order = rank 1, the next = rank 2, etc.
       RANK() OVER (PARTITION BY c.customer_id ORDER BY d.full_date) AS order_rank
FROM fact_orders f
JOIN dim_customers c ON f.customer_sk = c.customer_sk
JOIN dim_date d ON f.order_date_sk = d.date_sk;


