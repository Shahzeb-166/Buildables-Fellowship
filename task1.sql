-- Create Tables

CREATE TABLE customers (
    customer_id SERIAL PRIMARY KEY,
    name VARCHAR(100),
    email VARCHAR(150) UNIQUE NOT NULL,
    created_at TIMESTAMP DEFAULT NOW()
);
CREATE TABLE products(
	product_id SERIAL PRIMARY KEY,
	name VARCHAR(100),
	category VARCHAR(150),
	price NUMERIC(10,2) CHECK(price>0)
);
CREATE TABLE orders(
	order_id SERIAL PRIMARY KEY,
	customer_id INT REFERENCES customers(customer_id),
    product_id INT REFERENCES products(product_id),
	quantity INT CHECK (quantity>0),
	order_date TIMESTAMP DEFAULT NOW()
);

-- Insert Dummy data

INSERT INTO customers (name, email) VALUES
('Ali Rizwan', 'ali@example.com'),
('Baber Aslam', 'babar@example.com'),
('Ahmed Iqbal', 'ahmediqbal@example.com'),
('Daniyal Ali', 'daniyal@example.com'),
('Shahzeb Ahmed', 'shahzeb@example.com'),
('Faizan Saeed', 'faizan@example.com'),
('Hashir Zuberi', 'Hashir@example.com'),
('Abdul Ahad', 'aa@example.com'),
('Basil Riaz ', 'basil@example.com'),
('Rizwan Sheikh', 'rizwan@example.com'),
('Ibrahim Meer', 'ibrahim@example.com'),
('Sameer Sheikh', 'sameer@example.com'),
('Talha Mazhar', 'talhaM@example.com');

INSERT INTO products (name, category, price) VALUES
('Laptop', 'Electronics', 1000.00),
('Headphones', 'Electronics', 150.00),
('Phone Cover', 'Accessories', 600.00),
('Shoes', 'Fashion', 80.00),
('Backpack', 'Fashion', 50.00),
('Pen', 'Stationary', 10.00);

INSERT INTO orders (customer_id, product_id, quantity) VALUES
(1, 1, 1), (1, 2, 2), (1, 4, 1),
(2, 2, 1), (2, 3, 3),
(3, 1, 1), (3, 5, 2),
(4, 2, 2), (4, 4, 1),
(5, 3, 1), (5, 4, 2), (5, 5, 1),
(6, 1, 2),
(7, 5, 3),
(8, 3, 1), (8, 1, 1),
(9, 2, 1), (9, 4, 2),
(10, 5, 1), (10, 2, 2),
(11,3,1),
(12,1,2),(12,3,1),
(13,1,1);

-- Queries

-- 1. Customers who ordered more than 2 different products
SELECT c.name, COUNT(DISTINCT o.product_id) AS product_count
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
GROUP BY c.customer_id, c.name
HAVING COUNT(DISTINCT o.product_id) > 2;
-- 2. List products that no one has ordered yet.
SELECT p.product_id, p.name
FROM products p
LEFT JOIN orders o ON p.product_id = o.product_id
WHERE o.product_id IS NULL;
-- 3. Show the latest order date per customer.
SELECT c.customer_id,
       c.name as customer_name,
       MAX(o.order_date) AS latest_order_date
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
GROUP BY c.customer_id, c.name
ORDER BY latest_order_date DESC;
--4. Create a view called customer_spend_summary that shows each customer and their total spend.
CREATE VIEW customer_spend_summary AS
SELECT c.customer_id, c.name, SUM(p.price * o.quantity) AS total_spend
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id
LEFT JOIN products p ON o.product_id = p.product_id
GROUP BY c.customer_id, c.name;
--5. Create an index on orders.customer_id and explain in 2–3 lines why indexing helps here.
CREATE INDEX idx_orders_customer_id ON orders(customer_id);
-- Indexing helps speed up queries that filter or join by customer_id,
-- since orders are frequently queried by customer.
--6.Using a CTE, show the top 2 customers by spending in each product category.
WITH customer_category_spend AS (
    SELECT c.customer_id, c.name, p.category,
           SUM(p.price * o.quantity) AS spend,
           ROW_NUMBER() OVER (PARTITION BY p.category ORDER BY SUM(p.price * o.quantity) DESC) AS rn
    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
    JOIN products p ON o.product_id = p.product_id
    GROUP BY c.customer_id, c.name, p.category
)
SELECT * FROM customer_category_spend
WHERE rn <= 2;
--7. Using a CTE, calculate the monthly sales trend (total revenue per month).
WITH monthly_sales AS (
    SELECT DATE_TRUNC('month', o.order_date) AS month,
           SUM(p.price * o.quantity) AS revenue
    FROM orders o
    JOIN products p ON o.product_id = p.product_id
    GROUP BY DATE_TRUNC('month', o.order_date)
)
SELECT * FROM monthly_sales ORDER BY month;
--8.Rank each customer’s orders by order_date
SELECT o.order_id, c.name, o.order_date,
       RANK() OVER (PARTITION BY c.customer_id ORDER BY o.order_date DESC) AS order_rank
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id;
--9.  Customer cumulative spending over time
SELECT c.name, o.order_date,
       SUM(p.price * o.quantity) OVER (PARTITION BY c.customer_id ORDER BY o.order_date) AS cumulative_spend
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
JOIN products p ON o.product_id = p.product_id;
--10. Find the product that generated the highest revenue in its category, using RANK() OVER (PARTITION BY category ORDER BY SUM(price*quantity) DESC).
WITH product_revenue AS (
    SELECT p.product_id, p.name, p.category,
           SUM(p.price * o.quantity) AS revenue,
           RANK() OVER (PARTITION BY p.category ORDER BY SUM(p.price * o.quantity) DESC) AS rn
    FROM products p
    JOIN orders o ON p.product_id = o.product_id
    GROUP BY p.product_id, p.name, p.category
)
SELECT * FROM product_revenue WHERE rn = 1;

/*
While building this mini e commerce database, I learned how to design a relational schema with proper constraints, foreign keys, and checks to enforce data integrity. I also practiced inserting realistic sample data that ensures relationships are meaningful (customers with multiple orders, products ordered by different people, etc.).

The most useful new concept for me was window functions (ROW_NUMBER, RANK, SUM OVER). They make advanced analytics much easier compared to just using GROUP BY. Creating views and indexes also showed me how databases can be optimized for frequent queries.

The hardest part was designing queries that required partitioning, such as top 2 customers by spending in each category or cumulative spend per customer. These required careful use of CTEs and window functions. However, once I understood the logic, they became powerful tools for answering complex business questions.
*/
-- Submission branch update

