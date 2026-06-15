# ชีท 03 · SQL ขั้นสูง (Relationship, JOIN, Aggregate, Transaction)

## จุดประสงค์
- เข้าใจหลักการ **Relational Database**: ชนิดความสัมพันธ์ (1:1, 1:N, M:N), Anomaly, Normalization
- เชื่อมข้อมูลหลายตารางด้วย **FOREIGN KEY** (+ `ON DELETE`) และ **JOIN**
- สรุปข้อมูลด้วยฟังก์ชัน **Aggregate** + `GROUP BY`
- ใช้ **Transaction** (COMMIT / ROLLBACK / SAVEPOINT) เพื่อให้ข้อมูลถูกต้องเมื่อทำหลายคำสั่งพร้อมกัน

> เตรียมข้อมูล: Import ไฟล์ [`src/advanced.sql`](./src/advanced.sql) เข้าฐานข้อมูล `atsoft_day1` ก่อน

---

## 1. Relational Database คืออะไร?

**ฐานข้อมูลเชิงสัมพันธ์ (Relational Database)** คือฐานข้อมูลที่เก็บข้อมูลเป็น **หลายตาราง** แล้ว
"เชื่อมโยง" กันด้วยรหัส แทนที่จะยัดทุกอย่างไว้ตารางเดียว — MySQL/MariaDB ที่เราใช้อยู่ก็เป็นแบบนี้

### 1.1 ปัญหาของการเก็บไว้ตารางเดียว

สมมติเราเก็บ "คำสั่งซื้อ" ไว้ตารางเดียว แล้วใส่ชื่อลูกค้าซ้ำๆ ทุกแถว:

| order_id | customer_name | customer_phone | product | amount |
| :-- | :-- | :-- | :-- | :-- |
| 1 | สมชาย | 081-111 | น้ำดื่ม | 2 |
| 2 | สมชาย | 081-111 | สมุด | 1 |

ปัญหานี้เรียกว่า **ความผิดปกติของข้อมูล (Data Anomaly)** มี 3 แบบ:

| ชนิด | ปัญหา | ตัวอย่าง |
| :-- | :-- | :-- |
| **Update Anomaly** | แก้ที่เดียวไม่พอ ต้องไล่แก้ทุกแถว | สมชายเปลี่ยนเบอร์ ต้องแก้ทุกแถวที่มีสมชาย ถ้าลืมแถวใด ข้อมูลจะขัดกันเอง |
| **Insert Anomaly** | เพิ่มข้อมูลบางอย่างไม่ได้ถ้ายังไม่มีอีกอย่าง | อยากเก็บลูกค้าใหม่ที่ "ยังไม่เคยสั่งซื้อ" ทำไม่ได้ เพราะตารางนี้บังคับต้องมี product |
| **Delete Anomaly** | ลบของอย่างหนึ่ง แล้วข้อมูลอีกอย่างหายไปด้วย | ลบคำสั่งซื้อสุดท้ายของสมชาย → ข้อมูลเบอร์โทรของสมชายหายไปเลย |

**ทางแก้:** แยกเป็น 2 ตาราง แล้วเชื่อมกันด้วย "รหัส"

ตาราง `customers`

| id | name | phone |
| :-- | :-- | :-- |
| 1 | สมชาย | 081-111 |

ตาราง `orders` (เก็บแค่ `customer_id` อ้างไปหาลูกค้า)

| id | customer_id | product | amount |
| :-- | :-- | :-- | :-- |
| 1 | 1 | น้ำดื่ม | 2 |
| 2 | 1 | สมุด | 1 |

`customer_id` ในตาราง orders ที่ชี้ไปหา `id` ในตาราง customers เรียกว่า **FOREIGN KEY (กุญแจนอก)**

<div class="page-break"></div>

### 1.2 ชนิดของความสัมพันธ์ (Relationship) — 3 แบบ

| แบบ | อ่านว่า | ความหมาย | ตัวอย่าง |
| :-- | :-- | :-- | :-- |
| **1 : 1** | One-to-One | 1 แถวฝั่งนี้ จับคู่กับ 1 แถวฝั่งโน้น | 1 พนักงาน มี 1 ข้อมูลเงินเดือน |
| **1 : N** | One-to-Many | 1 แถวฝั่งนี้ มีได้ "หลายแถว" ฝั่งโน้น | 1 ลูกค้า มีได้หลายคำสั่งซื้อ |
| **M : N** | Many-to-Many | หลายแถวฝั่งนี้ จับกับหลายแถวฝั่งโน้น | 1 คำสั่งซื้อมีหลายสินค้า / 1 สินค้าอยู่ในหลายคำสั่งซื้อ |

**1 : N (พบบ่อยที่สุด)** — `customers` ↔ `orders`
ฝั่ง "หลาย" (orders) เก็บ FOREIGN KEY ชี้กลับไปหาฝั่ง "หนึ่ง" (customers)

```
customers                 orders
+----+--------+           +----+-------------+---------+
| id | name   |  1     N  | id | customer_id | product |
+----+--------+ <-------- +----+-------------+---------+
|  1 | สมชาย  |           |  1 |     1       | น้ำดื่ม  |
+----+--------+           |  2 |     1       | สมุด    |
                          +----+-------------+---------+
```

**M : N** — `orders` ↔ `products`
ความสัมพันธ์แบบนี้ใส่ FOREIGN KEY ตรงๆ ไม่ได้ ต้องสร้าง **ตารางกลาง (junction table)** มาคั่น
ในแล็บเราใช้ตาราง `order_items` (1 แถว = "สินค้า 1 รายการในคำสั่งซื้อ 1 ใบ")

```
orders          order_items (ตารางกลาง)        products
+----+   1    N  +----------+------------+   N    1  +----+----------+
| id | <-------- | order_id | product_id | --------> | id | name     |
+----+           |    1     |     1      |           +----+----------+
                 |    1     |     4      |  ← คำสั่งซื้อ #1 มี 2 สินค้า
                 |    2     |     1      |  ← สินค้า #1 อยู่หลายคำสั่งซื้อ
                 +----------+------------+
```

> สรุป: **M:N = แตกออกเป็นสอง 1:N** ผ่านตารางกลาง — ตารางกลางมักมีคอลัมน์เสริม เช่น `quantity` (จำนวน)

<div class="page-break"></div>

### 1.3 Normalization — จัดระเบียบตารางให้ไม่ซ้ำซ้อน

**Normalization** คือการ "แตกตารางใหญ่ที่ข้อมูลซ้ำซ้อน ออกเป็นตารางเล็กที่สะอาด" เพื่อกัน Anomaly
มี 3 ขั้นที่ใช้บ่อย (ทำไล่จากบนลงล่าง):

| ขั้น | กฎแบบเข้าใจง่าย |
| :-- | :-- |
| **1NF** | แต่ละช่องเก็บ "ค่าเดียว" ห้ามยัดหลายค่าในช่องเดียว (เช่นห้ามเก็บ `"ปากกา, สมุด"` ในช่องเดียว) |
| **2NF** | ผ่าน 1NF + ทุกคอลัมน์ต้องขึ้นกับ **Primary Key ทั้งตัว** (สำคัญตอน PK เป็นหลายคอลัมน์) |
| **3NF** | ผ่าน 2NF + คอลัมน์ที่ไม่ใช่ key ต้อง **ไม่ขึ้นต่อกันเอง** (เช่นอย่าเก็บทั้ง `customer_id` และ `customer_phone` ในตาราง orders — เบอร์ควรอยู่ที่ customers) |

**ตัวอย่าง:** ตารางเดิม (ไม่ผ่าน normalization)

| order_id | customer_name | customer_phone | products |
| :-- | :-- | :-- | :-- |
| 1 | สมชาย | 081-111 | น้ำดื่ม, สมุด |

จัดระเบียบเป็น 3 ตาราง: `customers` (ข้อมูลลูกค้า), `orders` (หัวคำสั่งซื้อ), `order_items` (รายการสินค้าในแต่ละใบ)
→ ไม่มีข้อมูลซ้ำ, แก้เบอร์ที่เดียว, เพิ่มลูกค้าที่ยังไม่สั่งซื้อได้

> ในทางปฏิบัติ มักทำถึง **3NF** ก็เพียงพอ บางครั้งงานที่เน้นความเร็วในการอ่านอาจจงใจ "de-normalize"
> (ยอมเก็บซ้ำบ้าง) เพื่อแลกกับ JOIN ที่น้อยลง — เป็นการเลือกตามสถานการณ์

---

## 2. FOREIGN KEY — สร้างความสัมพันธ์

```sql
CREATE TABLE customers (
  id    INT AUTO_INCREMENT PRIMARY KEY,
  name  VARCHAR(100) NOT NULL,
  phone VARCHAR(20)
);

CREATE TABLE orders (
  id          INT AUTO_INCREMENT PRIMARY KEY,
  customer_id INT NOT NULL,
  product     VARCHAR(100) NOT NULL,
  amount      INT NOT NULL,
  FOREIGN KEY (customer_id) REFERENCES customers(id)
);
```

ประโยชน์: ฐานข้อมูลจะ **ปกป้องความถูกต้อง** เช่น ห้ามใส่ `customer_id` ที่ไม่มีอยู่จริงในตาราง customers
(เรียกว่า **Referential Integrity** — ความถูกต้องของการอ้างอิง)

### 2.1 จะเกิดอะไรเมื่อลบ "แม่" ที่มี "ลูก" อ้างอยู่?

ถ้าลองลบลูกค้า id=1 ทั้งที่ยังมี orders อ้างถึงอยู่ ฐานข้อมูลจะ **ปฏิเสธ** (error) เพื่อกันข้อมูลกำพร้า
เรากำหนดพฤติกรรมตรงนี้ได้ด้วย `ON DELETE` / `ON UPDATE`:

| ตัวเลือก | ความหมายเมื่อ "ลบ/แก้ แถวแม่" |
| :-- | :-- |
| `RESTRICT` / `NO ACTION` | **ห้าม** ลบถ้ายังมีลูกอ้างอยู่ (ค่าเริ่มต้น ปลอดภัยสุด) |
| `CASCADE` | ลบแม่แล้ว **ลบลูกตามไปด้วย** อัตโนมัติ |
| `SET NULL` | ลบแม่แล้ว ตั้งค่า FK ในลูกเป็น `NULL` (คอลัมน์ต้องอนุญาต NULL) |

```sql
CREATE TABLE orders (
  id          INT AUTO_INCREMENT PRIMARY KEY,
  customer_id INT NOT NULL,
  product     VARCHAR(100) NOT NULL,
  amount      INT NOT NULL,
  FOREIGN KEY (customer_id) REFERENCES customers(id)
    ON DELETE CASCADE      -- ลบลูกค้า → ลบคำสั่งซื้อของเขาทิ้งด้วย
    ON UPDATE CASCADE      -- ถ้า id ลูกค้าเปลี่ยน → อัปเดต customer_id ตามให้
);
```

### 2.2 สร้างตารางกลางสำหรับ Many-to-Many

ความสัมพันธ์ M:N ระหว่าง `orders` กับ `products` ทำผ่านตารางกลาง `order_items`
ที่มี FOREIGN KEY **สองตัว** ชี้ไปทั้งสองฝั่ง:

```sql
CREATE TABLE order_items (
  id         INT AUTO_INCREMENT PRIMARY KEY,
  order_id   INT NOT NULL,
  product_id INT NOT NULL,
  quantity   INT NOT NULL,
  FOREIGN KEY (order_id)   REFERENCES orders(id),
  FOREIGN KEY (product_id) REFERENCES products(id)
);
```

> 1 แถว = "สินค้า 1 รายการในคำสั่งซื้อ 1 ใบ" — คอลัมน์ `quantity` คือข้อมูลเสริมของความสัมพันธ์นั้น

---

## 3. JOIN — เชื่อมตารางตอนอ่านข้อมูล

เราอยากเห็น "ชื่อลูกค้า" คู่กับ "สินค้าที่สั่ง" ในตารางเดียว → ใช้ JOIN

### 3.1 INNER JOIN (เอาเฉพาะที่จับคู่กันได้)

```sql
SELECT orders.id, customers.name, orders.product, orders.amount
FROM orders
INNER JOIN customers ON orders.customer_id = customers.id;
```

**ผลลัพธ์:**
```
+----+--------+----------+--------+
| id | name   | product  | amount |
+----+--------+----------+--------+
|  1 | สมชาย  |   น้ำดื่ม   |    2   |
|  2 | สมชาย  |   สมุด    |    1   |
+----+--------+----------+--------+
```

ใช้ชื่อย่อ (alias) ให้สั้นลงได้ด้วย:
```sql
SELECT o.id, c.name, o.product, o.amount
FROM orders o
INNER JOIN customers c ON o.customer_id = c.id;
```

### 3.2 LEFT JOIN (เอาทุกแถวฝั่งซ้าย แม้ไม่มีคู่)

```sql
-- เอาลูกค้า "ทุกคน" แม้คนที่ยังไม่เคยสั่งซื้อ
SELECT c.name, o.product
FROM customers c
LEFT JOIN orders o ON o.customer_id = c.id;
```

ลูกค้าที่ยังไม่เคยสั่ง จะได้ค่า `NULL` ในคอลัมน์ product

### 3.3 RIGHT JOIN (เอาทุกแถวฝั่งขวา แม้ไม่มีคู่)

ทำงานกลับด้านกับ LEFT JOIN — เอาทุกแถวของตาราง "ฝั่งขวา" (ตารางหลัง `JOIN`) ให้ครบ

```sql
-- เอาคำสั่งซื้อ "ทุกใบ" แม้ใบที่ไม่มีข้อมูลลูกค้าผูกอยู่
SELECT c.name, o.product
FROM customers c
RIGHT JOIN orders o ON o.customer_id = c.id;
```

> จริงๆ แล้ว `A LEFT JOIN B` ให้ผลเหมือน `B RIGHT JOIN A` — เลือกใช้ตัวที่อ่านเข้าใจง่ายกว่าได้เลย โดยทั่วไปนิยมใช้ LEFT JOIN มากกว่า

> **จำง่ายๆ:**
> - `INNER JOIN` = เฉพาะที่ "แมตช์กันทั้งสองฝั่ง"
> - `LEFT JOIN` = "เอาฝั่งซ้ายให้ครบ" ฝั่งขวาไม่มีก็ใส่ NULL
> - `RIGHT JOIN` = "เอาฝั่งขวาให้ครบ" ฝั่งซ้ายไม่มีก็ใส่ NULL

### 3.4 JOIN หลายตาราง (เดินผ่านตารางกลาง M:N)

อยากดู "คำสั่งซื้อใบไหน มีสินค้าอะไรบ้าง กี่ชิ้น" ต้องเดินผ่าน 3 ตาราง:
`orders` → `order_items` → `products` โดย `JOIN` ต่อกันเป็นทอดๆ

```sql
SELECT
  o.id           AS order_id,
  p.name         AS product,
  oi.quantity    AS จำนวน,
  p.price        AS ราคาต่อชิ้น
FROM orders o
INNER JOIN order_items oi ON oi.order_id   = o.id
INNER JOIN products    p  ON p.id          = oi.product_id
ORDER BY o.id;
```

**ผลลัพธ์ (บางส่วน):**
```
+----------+----------------+--------+-------------+
| order_id | product        | จำนวน  | ราคาต่อชิ้น  |
+----------+----------------+--------+-------------+
|    1     | น้ำดื่ม 600ml    |   2    |    7.00     |
|    1     | กล่องกระดาษ...  |   1    |   12.50     |
|    2     | ชาเขียวขวด...   |   5    |   20.00     |
+----------+----------------+--------+-------------+
```

> เทคนิค M:N ที่ใช้บ่อย: `JOIN` 3 ตารางแล้ว `GROUP BY` เพื่อสรุป เช่น "ยอดเงินรวมต่อ 1 คำสั่งซื้อ"
> = `SUM(oi.quantity * p.price)` (จะได้ฝึกในแล็บ)

---

## 4. Aggregate — สรุปข้อมูล

ฟังก์ชันสรุปผล:

| ฟังก์ชัน | ความหมาย |
| :-- | :-- |
| `COUNT(*)` | นับจำนวนแถว |
| `SUM(คอลัมน์)` | ผลรวม |
| `AVG(คอลัมน์)` | ค่าเฉลี่ย |
| `MIN` / `MAX` | ค่าน้อยสุด / มากสุด |
| `STDDEV(คอลัมน์)` | ส่วนเบี่ยงเบนมาตรฐาน (S.D.) |
| `VARIANCE(คอลัมน์)` | ความแปรปรวน (variance) |

```sql
-- มีคำสั่งซื้อทั้งหมดกี่รายการ
SELECT COUNT(*) FROM orders;

-- รวมจำนวนสินค้าที่สั่งทั้งหมด
SELECT SUM(amount) FROM orders;
```

### 4.1 GROUP BY — สรุปแบบแยกกลุ่ม

```sql
-- ลูกค้าแต่ละคน สั่งสินค้ารวมกี่ชิ้น
SELECT c.name, SUM(o.amount) AS total_amount
FROM orders o
INNER JOIN customers c ON o.customer_id = c.id
GROUP BY c.name;
```

**ผลลัพธ์:**
```
+--------+--------------+
| name   | total_amount |
+--------+--------------+
| สมชาย  |       3      |
| มานี    |       5      |
+--------+--------------+
```

### 4.2 HAVING — กรองหลังจากสรุป

`WHERE` กรองก่อนรวมกลุ่ม ส่วน `HAVING` กรอง **ผลที่รวมกลุ่มแล้ว**

```sql
-- เฉพาะลูกค้าที่สั่งรวมเกิน 3 ชิ้น
SELECT c.name, SUM(o.amount) AS total_amount
FROM orders o
INNER JOIN customers c ON o.customer_id = c.id
GROUP BY c.name
HAVING total_amount > 3;
```

### 4.3 ส่วนเบี่ยงเบนมาตรฐาน (S.D.) ด้วย STDDEV

`STDDEV()` บอกว่าข้อมูล "กระจายตัว" มากแค่ไหนรอบๆ ค่าเฉลี่ย — ค่ายิ่งมากยิ่งกระจายห่าง

```sql
-- ค่าเฉลี่ย, ส่วนเบี่ยงเบนมาตรฐาน และความแปรปรวน ของราคาในคำสั่งซื้อ
SELECT
  AVG(price)      AS ราคาเฉลี่ย,
  STDDEV(price)   AS ส่วนเบี่ยงเบนมาตรฐาน,
  VARIANCE(price) AS ความแปรปรวน
FROM orders;
```

> MySQL/MariaDB ยังมี `STDDEV_POP()` (คิดแบบประชากรทั้งหมด) และ `STDDEV_SAMP()` (คิดแบบกลุ่มตัวอย่าง) ให้เลือกตามหลักสถิติ โดย `STDDEV()` มีค่าเท่ากับ `STDDEV_POP()`

### 4.4 ปรับข้อมูลให้เป็นมาตรฐาน (Standardization / Normalization)

ก่อนนำตัวเลขไปวิเคราะห์ต่อ มักต้อง "ปรับสเกล" ให้เทียบกันได้ มี 2 วิธีที่พบบ่อย:

**1) Standardization (Z-score)** = (ค่า − ค่าเฉลี่ย) ÷ ส่วนเบี่ยงเบนมาตรฐาน
อ่านได้ว่า "ค่านี้ห่างจากค่าเฉลี่ยกี่เท่าของ S.D."

```sql
SELECT
  product,
  price,
  (price - (SELECT AVG(price) FROM orders))
    / (SELECT STDDEV(price) FROM orders) AS z_score
FROM orders;
```

**2) Min-Max Normalization** = บีบให้อยู่ในช่วง 0 ถึง 1
สูตร: (ค่า − ค่าต่ำสุด) ÷ (ค่าสูงสุด − ค่าต่ำสุด)

```sql
SELECT
  product,
  price,
  (price - (SELECT MIN(price) FROM orders))
    / ((SELECT MAX(price) FROM orders) - (SELECT MIN(price) FROM orders)) AS normalized
FROM orders;
```

> ทั้งสองสูตรเอา "ค่าสรุปของทั้งตาราง" (AVG/STDDEV/MIN/MAX) มาคำนวณกับ "ค่ารายแถว" จึงต้องดึงค่าสรุปด้วย subquery ในวงเล็บ `( ... )`

### 4.5 คำนวณช่วงวันด้วย DATEDIFF()

`DATEDIFF(วันที่หลัง, วันที่ก่อน)` คืนจำนวน "วัน" ที่ห่างกัน เหมาะกับงานรายงาน

```sql
-- คำสั่งซื้อแต่ละใบ ผ่านมากี่วันแล้ว (นับถึงวันนี้)
SELECT
  product,
  order_date,
  DATEDIFF(CURDATE(), order_date) AS ผ่านมากี่วัน
FROM orders;
```

ใช้ร่วมกับ aggregate ได้ เช่น หาค่าเฉลี่ยจำนวนวันที่ผ่านมาของทุกคำสั่งซื้อ:

```sql
SELECT AVG(DATEDIFF(CURDATE(), order_date)) AS เฉลี่ยจำนวนวัน
FROM orders;
```

> ฟังก์ชันวันที่ที่ใช้บ่อยอื่นๆ: `CURDATE()` (วันนี้), `NOW()` (วันที่+เวลาปัจจุบัน), `YEAR()` / `MONTH()` / `DAY()` (ดึงปี/เดือน/วันออกมา)

---

## 5. Transaction — ทำหลายคำสั่งให้ "สำเร็จทั้งหมด หรือไม่ก็ยกเลิกทั้งหมด"

### ปัญหาที่ Transaction แก้
สมมติ "โอนเงิน" จากบัญชี A ไป B ต้องทำ 2 ขั้น:
1. ลดเงินบัญชี A
2. เพิ่มเงินบัญชี B

ถ้าทำขั้น 1 เสร็จแล้วไฟดับก่อนขั้น 2 → **เงินหายไปเฉยๆ**

Transaction บอกว่า "สองขั้นนี้ต้องสำเร็จคู่กัน ถ้าพังขั้นใดขั้นหนึ่ง ให้ย้อนกลับเหมือนไม่เคยทำ"

### คำสั่ง

```sql
START TRANSACTION;          -- เริ่ม

UPDATE accounts SET balance = balance - 100 WHERE id = 1;  -- ลดเงิน A
UPDATE accounts SET balance = balance + 100 WHERE id = 2;  -- เพิ่มเงิน B

COMMIT;                     -- ยืนยัน บันทึกจริงทั้งหมด
```

ถ้าระหว่างทางพบว่ามีปัญหา (เช่นเงินไม่พอ) ให้ยกเลิก:

```sql
ROLLBACK;                   -- ย้อนทุกอย่างกลับเหมือนไม่เคยทำ
```

### ACID — คุณสมบัติที่ Transaction รับประกัน (รู้ไว้พอเข้าใจ)

| ตัวอักษร | ความหมายแบบสั้น |
| :-- | :-- |
| **A** – Atomicity | ทำสำเร็จทั้งหมด หรือไม่ทำเลย |
| **C** – Consistency | ข้อมูลยังถูกต้องตามกฎเสมอ |
| **I** – Isolation | หลายงานพร้อมกันไม่กวนกัน |
| **D** – Durability | เมื่อ COMMIT แล้วข้อมูลอยู่ถาวร แม้ไฟดับ |

> Transaction ใช้ได้กับตารางชนิด **InnoDB** (ค่าเริ่มต้นของ MySQL/MariaDB ปัจจุบัน)
> ในงานจริง เรามักสั่ง Transaction ผ่านโค้ด PHP (จะได้เจอใน Day 2/Day 3)

### 5.1 ตัวอย่างจริง: สร้างคำสั่งซื้อ + ตัดสต็อกพร้อมกัน

งานขายของจริงต้องทำ 2 อย่างให้ "สำเร็จคู่กัน": บันทึกคำสั่งซื้อ **และ** หักสต็อกสินค้า
ถ้าบันทึกออเดอร์สำเร็จแต่หักสต็อกพลาด → ขายเกินจำนวนที่มี

```sql
START TRANSACTION;

-- 1) หักสต็อกน้ำดื่ม (product id = 1) ออก 2 ชิ้น
UPDATE products SET stock = stock - 2 WHERE id = 1;

-- 2) สร้างคำสั่งซื้อใหม่ของลูกค้า id = 2
INSERT INTO orders (customer_id, product, amount, price, order_date)
VALUES (2, 'น้ำดื่ม 600ml', 2, 7.00, CURDATE());

COMMIT;     -- ทั้งสองอย่างถูกบันทึกพร้อมกัน
```

### 5.2 เช็คเงื่อนไขก่อนตัดสินใจ COMMIT หรือ ROLLBACK

หัวใจของ Transaction คือ "ดูผลกลางทางก่อน แล้วค่อยตัดสินใจ"
เช่น โอนเงินแล้วเช็คว่าบัญชีต้นทาง **ติดลบ** หรือไม่:

```sql
START TRANSACTION;

UPDATE accounts SET balance = balance - 9999 WHERE id = 1;

-- ดูยอดก่อนยืนยัน
SELECT balance FROM accounts WHERE id = 1;
--  ถ้าผลออกมา "ติดลบ" (เงินไม่พอ) → สั่ง ROLLBACK
--  ถ้ายอดยังเป็นบวกตามปกติ        → ทำ UPDATE ฝั่งรับต่อ แล้ว COMMIT

ROLLBACK;   -- ในเคสนี้เงินไม่พอ จึงยกเลิกทั้งหมด ยอดกลับเป็นเดิม
```

> ใน phpMyAdmin เราเช็คด้วยตาเอง แต่ในโค้ด PHP จะใช้ `if` ตรวจค่าแล้วเลือก commit/rollback อัตโนมัติ

### 5.3 SAVEPOINT — ย้อนกลับ "บางส่วน" ของ Transaction

บางที Transaction ยาวๆ เราอยากย้อนแค่บางขั้น ไม่ต้องทิ้งทั้งก้อน ใช้ `SAVEPOINT` ตั้ง "จุดเซฟ":

```sql
START TRANSACTION;

UPDATE accounts SET balance = balance - 100 WHERE id = 1;
SAVEPOINT after_withdraw;          -- ตั้งจุดเซฟไว้ตรงนี้

UPDATE accounts SET balance = balance + 100 WHERE id = 2;
-- เปลี่ยนใจ ไม่อยากให้ขั้นที่ 2 เกิดขึ้น
ROLLBACK TO after_withdraw;        -- ย้อนกลับมาที่จุดเซฟ (ขั้น 1 ยังอยู่)

COMMIT;     -- ยืนยันเฉพาะขั้นที่ 1
```

### 5.4 AUTOCOMMIT — ทำไมปกติพิมพ์ทีละคำสั่งถึง "บันทึกทันที"

ปกติ MySQL เปิด **AUTOCOMMIT** ไว้ คือทุกคำสั่งที่รันเดี่ยวๆ จะ `COMMIT` ให้ทันทีอัตโนมัติ
`START TRANSACTION;` คือการ "ปิด autocommit ชั่วคราว" จนกว่าจะ `COMMIT` หรือ `ROLLBACK` เอง

```sql
SET autocommit = 0;   -- ปิด: ตั้งแต่นี้ต้อง COMMIT เองทุกครั้ง
-- ... คำสั่งต่างๆ ...
COMMIT;
SET autocommit = 1;   -- เปิดกลับเป็นค่าเริ่มต้น
```

### 5.5 พรีวิว: Transaction ใน PHP (PDO) — เจอจริงใน Day 2

ในโค้ดจริง เราคุม commit/rollback ด้วยเงื่อนไข `try / catch`:

```php
try {
    $pdo->beginTransaction();              // = START TRANSACTION
    $pdo->prepare('UPDATE accounts SET balance = balance - ? WHERE id = ?')
        ->execute([100, 1]);
    $pdo->prepare('UPDATE accounts SET balance = balance + ? WHERE id = ?')
        ->execute([100, 2]);
    $pdo->commit();                        // สำเร็จทั้งหมด → ยืนยัน
} catch (Exception $e) {
    $pdo->rollBack();                      // มี error → ย้อนทั้งหมด
}
```

---

## 6. สรุป Cheat Sheet ขั้นสูง

```sql
-- FOREIGN KEY + พฤติกรรมตอนลบแม่
FOREIGN KEY (fk_col) REFERENCES parent(id)
  ON DELETE CASCADE;          -- หรือ RESTRICT / SET NULL

-- JOIN (เชื่อมหลายตารางต่อกันได้ เช่น M:N ผ่านตารางกลาง)
SELECT a.col, b.col
FROM tableA a
INNER JOIN tableB b ON a.fk = b.id;   -- LEFT JOIN ถ้าต้องการฝั่งซ้ายครบ

-- สรุปแบบกลุ่ม
SELECT กลุ่ม, SUM(ค่า) AS total
FROM ตาราง
GROUP BY กลุ่ม
HAVING total > X;

-- Transaction
START TRANSACTION;
  ... คำสั่งหลายอัน ...
  SAVEPOINT p1;               -- (ถ้าต้องการ) ตั้งจุดเซฟ
  ROLLBACK TO p1;             -- ย้อนเฉพาะบางส่วน
COMMIT;     -- หรือ ROLLBACK; เพื่อยกเลิกทั้งหมด
```

**ความสัมพันธ์ 3 แบบ:** `1:1` · `1:N` (ฝั่งหลายเก็บ FK) · `M:N` (ต้องมีตารางกลาง)
