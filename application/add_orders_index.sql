-- Add indexes to orders table for performance
-- PROJ-1239: Improve order query performance

CREATE TABLE IF NOT EXISTS orders (
    order_id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT,
    order_date DATETIME,
    status VARCHAR(50)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE INDEX idx_order_user ON orders(user_id, order_date);
CREATE INDEX idx_order_status ON orders(status);

ANALYZE TABLE orders;
