-- ============================================================
-- ไฟล์ข้อมูลตั้งต้นสำหรับ Lab 2 (SQL ขั้นสูง: JOIN / GROUP BY / Transaction)
-- วิธีใช้: phpMyAdmin > เลือกฐานข้อมูล atsoft_day1 > แท็บ Import > เลือกไฟล์นี้ > Go
-- ไฟล์นี้ self-contained: สร้างตาราง products ให้ในตัว (ไม่ต้อง import basic.sql ก่อน)
-- ============================================================

-- ลบของเดิม (ลบตารางที่อ้างถึงตารางอื่นก่อน เพื่อเลี่ยง error เรื่อง FOREIGN KEY)
DROP TABLE IF EXISTS order_items;
DROP TABLE IF EXISTS orders;
DROP TABLE IF EXISTS customers;
DROP TABLE IF EXISTS accounts;
DROP TABLE IF EXISTS products;

-- ---------- ตารางสินค้า (ใช้เป็นฝั่ง "หนึ่ง" ของ Many-to-Many) ----------
CREATE TABLE products (
  id       INT AUTO_INCREMENT PRIMARY KEY,
  name     VARCHAR(100)  NOT NULL,
  category VARCHAR(50)   NOT NULL,
  price    DECIMAL(10,2) NOT NULL DEFAULT 0,
  stock    INT           NOT NULL DEFAULT 0
) ENGINE=InnoDB;

INSERT INTO products (name, category, price, stock) VALUES
  ('น้ำดื่ม 600ml',        'เครื่องดื่ม',   7.00,  500),  -- id 1
  ('น้ำโซดา 325ml',        'เครื่องดื่ม',  10.00,  300),  -- id 2
  ('ชาเขียวขวด 500ml',     'เครื่องดื่ม',  20.00,  150),  -- id 3
  ('กล่องกระดาษลูกฟูก',     'บรรจุภัณฑ์',   12.50,  800),  -- id 4
  ('ฉลากสติกเกอร์ม้วน',     'บรรจุภัณฑ์',   45.00,   40),  -- id 5
  ('ถุงมือผ้า',            'อุปกรณ์',      18.00,  120),  -- id 6
  ('หมวกนิรภัย',           'อุปกรณ์',     250.00,   25),  -- id 7
  ('เทปกาวใส',             'อุปกรณ์',       9.50,  200),  -- id 8
  ('แอลกอฮอล์ทำความสะอาด',  'อุปกรณ์',      35.00,   60),  -- id 9
  ('ผ้าเช็ดทำความสะอาด',    'อุปกรณ์',      15.00,   90);  -- id 10

-- ---------- ตารางลูกค้า ----------
CREATE TABLE customers (
  id    INT AUTO_INCREMENT PRIMARY KEY,
  name  VARCHAR(100) NOT NULL,
  phone VARCHAR(20)
) ENGINE=InnoDB;

INSERT INTO customers (name, phone) VALUES
  ('สมชาย ใจดี',   '081-111-1111'),  -- id 1
  ('มานี รักเรียน', '082-222-2222'),  -- id 2
  ('ปิติ ขยัน',     '083-333-3333'),  -- id 3
  ('วีณา สุขใจ',    '084-444-4444');  -- id 4 (ยังไม่เคยสั่งซื้อ ไว้ทดสอบ LEFT JOIN)

-- ---------- ตารางคำสั่งซื้อ ----------
CREATE TABLE orders (
  id          INT AUTO_INCREMENT PRIMARY KEY,
  customer_id INT NOT NULL,
  product     VARCHAR(100) NOT NULL,
  amount      INT NOT NULL,
  price       DECIMAL(10,2) NOT NULL,
  order_date  DATE NOT NULL,
  FOREIGN KEY (customer_id) REFERENCES customers(id)
) ENGINE=InnoDB;

INSERT INTO orders (customer_id, product, amount, price, order_date) VALUES
  (1, 'น้ำดื่ม 600ml',    2,  7.00, '2026-06-01'),
  (1, 'สมุด',            1, 25.00, '2026-06-01'),
  (2, 'ชาเขียวขวด',      5, 20.00, '2026-06-02'),
  (2, 'ปากกา',           3, 15.00, '2026-06-03'),
  (3, 'น้ำโซดา 325ml',   4, 10.00, '2026-06-03'),
  (3, 'หมวกนิรภัย',      1, 250.00,'2026-06-05');

-- ---------- ตารางบัญชี (สำหรับฝึก Transaction โอนเงิน) ----------
CREATE TABLE accounts (
  id      INT AUTO_INCREMENT PRIMARY KEY,
  owner   VARCHAR(100) NOT NULL,
  balance DECIMAL(12,2) NOT NULL
) ENGINE=InnoDB;

INSERT INTO accounts (owner, balance) VALUES
  ('บัญชี A (สมชาย)', 1000.00),
  ('บัญชี B (มานี)',   500.00);

-- ---------- ตารางกลาง order_items (ตัวอย่างความสัมพันธ์ Many-to-Many) ----------
-- โจทย์: 1 คำสั่งซื้อ (orders) มีได้ "หลายสินค้า" และ 1 สินค้า (products) อยู่ได้ "หลายคำสั่งซื้อ"
-- ความสัมพันธ์แบบนี้เก็บตรงๆ ไม่ได้ ต้องมี "ตารางกลาง (junction table)" มาคั่น = order_items
-- หนึ่งแถวของ order_items = "สินค้า 1 รายการ ในคำสั่งซื้อ 1 ใบ"
CREATE TABLE order_items (
  id         INT AUTO_INCREMENT PRIMARY KEY,
  order_id   INT NOT NULL,
  product_id INT NOT NULL,
  quantity   INT NOT NULL,
  FOREIGN KEY (order_id)   REFERENCES orders(id),
  FOREIGN KEY (product_id) REFERENCES products(id)
) ENGINE=InnoDB;

-- product_id อ้างถึง id ในตาราง products ด้านบน
INSERT INTO order_items (order_id, product_id, quantity) VALUES
  (1, 1, 2),   -- คำสั่งซื้อ #1 มี: น้ำดื่ม x2
  (1, 4, 1),   -- คำสั่งซื้อ #1 มี: กล่องกระดาษ x1   → 1 ใบ หลายสินค้า
  (2, 3, 5),   -- คำสั่งซื้อ #2 มี: ชาเขียว x5
  (2, 1, 3),   -- คำสั่งซื้อ #2 มี: น้ำดื่ม x3        → น้ำดื่มอยู่หลายใบ
  (3, 2, 4),   -- คำสั่งซื้อ #3 มี: น้ำโซดา x4
  (3, 7, 1),   -- คำสั่งซื้อ #3 มี: หมวกนิรภัย x1
  (4, 6, 2),   -- คำสั่งซื้อ #4 มี: ถุงมือผ้า x2
  (5, 1, 6),   -- คำสั่งซื้อ #5 มี: น้ำดื่ม x6        → น้ำดื่มอยู่ใบที่ 1,2,5
  (6, 7, 1);   -- คำสั่งซื้อ #6 มี: หมวกนิรภัย x1
