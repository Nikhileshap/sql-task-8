
CREATE DATABASE IF NOT EXISTS ecommerce_db;
USE ecommerce_db;

CREATE TABLE Customers (
    customer_id INT NOT NULL AUTO_INCREMENT PRIMARY KEY, 
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    phone VARCHAR(20) 
);

CREATE TABLE Products (
    product_id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    price DECIMAL(10, 2) NOT NULL,
    stock_quantity INT NOT NULL
);

CREATE TABLE Orders (
    order_id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    customer_id INT NOT NULL,
    order_date DATETIME NOT NULL,
    total_amount DECIMAL(10, 2) NOT NULL,
    FOREIGN KEY (customer_id) REFERENCES Customers(customer_id)
        ON DELETE CASCADE
);

CREATE TABLE Order_Items (
    order_item_id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    order_id INT NOT NULL,
    product_id INT NOT NULL,
    quantity INT NOT NULL,
    unit_price DECIMAL(10, 2) NOT NULL,
    FOREIGN KEY (order_id) REFERENCES Orders(order_id) ON DELETE CASCADE,
    FOREIGN KEY (product_id) REFERENCES Products(product_id)
);

INSERT INTO Customers (first_name, last_name, email, phone) 
VALUES ('John', 'Doe', 'john.doe@tech.com', '555-1234');

INSERT INTO Customers (first_name, last_name, email) 
VALUES ('Jane', 'Smith', 'jane.smith@email.com');

INSERT INTO Products (name, description, price, stock_quantity)
VALUES ('Gaming Laptop', 'High performance model.', 1200.00, 15);

INSERT INTO Products (name, description, price, stock_quantity)
VALUES ('Wireless Mouse', 'Ergonomic design.', 25.50, 200);

INSERT INTO Orders (customer_id, order_date, total_amount)
VALUES (1, NOW(), 1225.50);

INSERT INTO Orders (customer_id, order_date, total_amount)
VALUES (2, NOW(), 25.50);

INSERT INTO Order_Items (order_id, product_id, quantity, unit_price) VALUES
(1, 1, 1, 1200.00),
(1, 2, 1, 25.50),
(2, 2, 1, 25.50);

UPDATE Products
SET price = price * 1.10
WHERE product_id = 2;

DELETE FROM Orders
WHERE order_id = 2;

SELECT '--- Customers (Verify NULL handling) ---' AS Status;
SELECT * FROM Customers;

SELECT '--- Orders (Verify DELETE operation) ---' AS Status;
SELECT * FROM Orders;

SELECT '--- Products (Verify UPDATE operation) ---' AS Status;
SELECT * FROM Products;

SELECT '--- Order Items (Verify CASCADE deletion) ---' AS Status;
SELECT * FROM Order_Items;

-- Use specific columns (Projection) and filter by price (WHERE)
SELECT name, price
FROM Products
WHERE price > 100.00;

SELECT first_name, last_name, email
FROM Customers
WHERE last_name LIKE 'S%';

SELECT name, price, stock_quantity
FROM Products
WHERE price BETWEEN 10.00 AND 50.00
  AND stock_quantity > 100;
  
  -- Sorts by price in Descending (DESC) order
SELECT name, price
FROM Products
ORDER BY price DESC;

-- Orders records by date (most recent first) and displays only the top 2
SELECT order_id, customer_id, order_date
FROM Orders
ORDER BY order_date DESC
LIMIT 2;

SELECT DISTINCT last_name AS Customer_Surname
FROM Customers;	 	

SELECT COUNT(*) AS Total_Orders_Placed
FROM Orders;

SELECT SUM(total_amount) AS Total_Revenue
FROM Orders;

-- Use ROUND() for cleaner output
SELECT ROUND(AVG(price), 2) AS Average_Product_Price
FROM Products;

SELECT 
    customer_id, 
    COUNT(order_id) AS Number_of_Orders
FROM Orders
GROUP BY customer_id;

-- Insert Customer 3 (ID 3) who has not placed an order
INSERT INTO Customers (first_name, last_name, email, phone) 
VALUES ('Sam', 'Vimes', 'sam.vimes@watch.org', '555-0003');

SELECT
    C.first_name,
    C.last_name,
    O.order_id,
    O.order_date
FROM Customers C
INNER JOIN Orders O ON C.customer_id = O.customer_id;

-- Standard SQL implementation for FULL OUTER JOIN (required for concept demonstration)
(
    -- LEFT JOIN part
    SELECT C.first_name, C.last_name, O.order_id
    FROM Customers C
    LEFT JOIN Orders O ON C.customer_id = O.customer_id
)
UNION
(
    -- RIGHT JOIN part (excluding matching rows already covered by the LEFT JOIN)
    SELECT C.first_name, C.last_name, O.order_id
    FROM Customers C
    RIGHT JOIN Orders O ON C.customer_id = O.customer_id
    WHERE C.customer_id IS NULL
);

SELECT 
    first_name, 
    last_name
FROM Customers
WHERE customer_id IN (
    -- Subquery returns a list of customer_ids who meet the criteria
    SELECT customer_id
    FROM Orders
    WHERE total_amount > 1000.00
);

SELECT
    order_id,
    total_amount
FROM Orders
WHERE total_amount > (
    -- Scalar subquery: returns a single value (the average amount)
    SELECT AVG(total_amount)
    FROM Orders
);

SELECT
    P.name AS Product_Name,
    P.price,
    -- Scalar Subquery: returns the total quantity sold for that specific product
    (
        SELECT SUM(OI.quantity)
        FROM Order_Items OI
        WHERE OI.product_id = P.product_id
    ) AS Total_Quantity_Sold
FROM Products P;

--  Creates a reusable structure for basic customer data
CREATE VIEW Customer_Contact_Info AS
SELECT
    first_name,
    last_name,
    email
FROM Customers;

-- View Usage: Treat the view like a regular table
SELECT *
FROM Customer_Contact_Info
WHERE last_name = 'Doe';

--  Calculates total lifetime spending per customer
CREATE VIEW Customer_Spending_Summary AS
SELECT
    C.customer_id,
    C.first_name,
    C.last_name,
    SUM(O.total_amount) AS Total_Spent,
    COUNT(O.order_id) AS Total_Orders
FROM Customers C
JOIN Orders O ON C.customer_id = O.customer_id
GROUP BY C.customer_id, C.first_name, C.last_name;

-- View Usage: Use the pre-calculated view for simple queries
SELECT
    first_name,
    Total_Spent
FROM Customer_Spending_Summary
ORDER BY Total_Spent DESC
LIMIT 1; -- Find the top spender


DELIMITER //

CREATE PROCEDURE AddNewProduct (
    IN p_name VARCHAR(100),
    IN p_desc TEXT,
    IN p_price DECIMAL(10, 2),
    IN p_stock INT
)
BEGIN
    INSERT INTO Products (name, description, price, stock_quantity)
    VALUES (p_name, p_desc, p_price, p_stock);
END //

DELIMITER ;

-- USAGE (How to call the procedure):
CALL AddNewProduct('E-book Reader', 'Lightweight E-Ink tablet.', 99.99, 50);
CALL AddNewProduct('Mechanical Keyboard', 'RGB backlighting.', 120.00, 25);

-- Verification
SELECT * FROM Products;


CREATE FUNCTION GetCustomerFullName (
    customer_id_in INT
)
RETURNS VARCHAR(101) -- Max length of first_name (50) + space (1) + last_name (50)
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE full_name_out VARCHAR(101);

    SELECT CONCAT(first_name, ' ', last_name)
    INTO full_name_out
    FROM Customers
    WHERE customer_id = customer_id_in;

    RETURN full_name_out;
END //

DELIMITER ;

-- USAGE (How to call the function):
SELECT GetCustomerFullName(1) AS Customer_Name;
SELECT order_id, total_amount, GetCustomerFullName(customer_id) AS Placed_By
FROM Orders;