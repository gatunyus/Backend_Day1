# ชีท 01 · SQL พื้นฐาน (CRUD)

## จุดประสงค์
เข้าใจโครงสร้างฐานข้อมูล และเขียนคำสั่ง SQL พื้นฐานเพื่อ **เพิ่ม / อ่าน / แก้ / ลบ** ข้อมูลได้

> วิธีฝึก: เปิด phpMyAdmin → เลือกฐานข้อมูล `atsoft_day1` → แท็บ **SQL** → พิมพ์ตามตัวอย่างทีละอัน แล้วกด **Go** ดูผลลัพธ์

---

## 1. ฐานข้อมูลหน้าตาเป็นอย่างไร

ลองนึกถึงไฟล์ Excel:

| คำศัพท์ | คือ | เทียบกับ Excel |
| :-- | :-- | :-- |
| **Database** | ฐานข้อมูล 1 ก้อน | ไฟล์ Excel 1 ไฟล์ |
| **Table** (ตาราง) | ตารางเก็บข้อมูลเรื่องหนึ่ง | 1 ชีท (sheet) |
| **Column** (คอลัมน์/ฟิลด์) | หัวข้อข้อมูล | หัวคอลัมน์ A, B, C |
| **Row** (แถว/เรคคอร์ด) | ข้อมูล 1 รายการ | 1 แถวข้อมูล |
| **Primary Key (PK)** | คอลัมน์ที่ใช้ระบุแถวแบบไม่ซ้ำ | เลขที่/รหัสประจำตัว |

ตัวอย่างตาราง `products` (สินค้า):

| id (PK) | name | price | stock |
| :-- | :-- | :-- | :-- |
| 1 | ปากกา | 15.00 | 100 |
| 2 | สมุด | 25.00 | 50 |
| 3 | ดินสอ | 8.00 | 200 |

<div class="page-break"></div>

## 2. ชนิดข้อมูล (Data Types) ที่ใช้บ่อย

เวลาสร้างคอลัมน์ ต้องบอกว่าจะเก็บข้อมูลชนิดไหน:

| ชนิด | เก็บอะไร | ตัวอย่าง |
| :-- | :-- | :-- |
| `INT` | จำนวนเต็ม | 1, 250, -7 |
| `DECIMAL(10,2)` | ทศนิยม (เหมาะกับเงิน) | 15.00, 999.50 |
| `VARCHAR(100)` | ข้อความสั้น (กำหนดความยาวสูงสุด) | "ปากกา", ชื่อคน |
| `TEXT` | ข้อความยาว | รายละเอียด, หมายเหตุ |
| `DATE` | วันที่ | 2026-06-08 |
| `DATETIME` | วันที่+เวลา | 2026-06-08 14:30:00 |
| `TINYINT(1)` | ค่า 0/1 (ใช้แทน true/false) | 1 = ใช่, 0 = ไม่ |

> เก็บ **เงิน** ใช้ `DECIMAL` อย่าใช้ทศนิยมลอยตัว (FLOAT) เพราะอาจปัดเศษเพี้ยน

---

## 3. สร้างตาราง (CREATE TABLE)

```sql
CREATE TABLE products (
  id     INT AUTO_INCREMENT PRIMARY KEY,
  name   VARCHAR(100) NOT NULL,
  price  DECIMAL(10,2) NOT NULL DEFAULT 0,
  stock  INT NOT NULL DEFAULT 0
);
```

อธิบายทีละบรรทัด:
- `id INT AUTO_INCREMENT PRIMARY KEY` → คอลัมน์ id เป็นเลขเพิ่มอัตโนมัติ (1,2,3,...) และเป็นกุญแจหลัก
- `NOT NULL` → ห้ามเว้นว่าง (ต้องมีค่าเสมอ)
- `DEFAULT 0` → ถ้าไม่ใส่ค่า ให้ใช้ 0

> ใน phpMyAdmin คุณสร้างตารางด้วยหน้าจอ (กรอกชื่อคอลัมน์/ชนิด) ก็ได้ แต่ขอให้ลองพิมพ์ SQL เองด้วย เพราะ Day 2 ต้องใช้

<div class="page-break"></div>

## 4. CRUD — หัวใจของการจัดการข้อมูล

CRUD ย่อมาจาก **C**reate, **R**ead, **U**pdate, **D**elete

| อยากทำ | คำสั่ง SQL |
| :-- | :-- |
| เพิ่มข้อมูล (Create) | `INSERT` |
| อ่านข้อมูล (Read) | `SELECT` |
| แก้ข้อมูล (Update) | `UPDATE` |
| ลบข้อมูล (Delete) | `DELETE` |

---

### 4.1 INSERT — เพิ่มข้อมูล

```sql
INSERT INTO products (name, price, stock)
VALUES ('ปากกา', 15.00, 100);
```

เพิ่มหลายแถวพร้อมกัน:

```sql
INSERT INTO products (name, price, stock) VALUES
  ('สมุด', 25.00, 50),
  ('ดินสอ', 8.00, 200);
```

> ไม่ต้องใส่ `id` เพราะ `AUTO_INCREMENT` จะเติมให้เอง

---

### 4.2 SELECT — อ่านข้อมูล

อ่านทุกคอลัมน์ ทุกแถว:
```sql
SELECT * FROM products;
```

เลือกเฉพาะบางคอลัมน์:
```sql
SELECT name, price FROM products;
```

**ผลลัพธ์:**
```
+--------+-------+
| name   | price |
+--------+-------+
| ปากกา  | 15.00 |
| สมุด    | 25.00 |
| ดินสอ   |  8.00 |
+--------+-------+
```

---

### 4.3 WHERE — กรองเฉพาะที่ต้องการ

```sql
-- สินค้าราคามากกว่า 10 บาท
SELECT * FROM products WHERE price > 10;

-- สินค้าชื่อ "สมุด" พอดี
SELECT * FROM products WHERE name = 'สมุด';

-- สต็อกน้อยกว่าหรือเท่ากับ 50
SELECT * FROM products WHERE stock <= 50;
```

ตัวเปรียบเทียบที่ใช้ได้: `=`, `>`, `<`, `>=`, `<=`, `<>` (ไม่เท่ากับ)

รวมหลายเงื่อนไขด้วย `AND` / `OR`:
```sql
-- ราคามากกว่า 10 และ สต็อกมากกว่า 50
SELECT * FROM products WHERE price > 10 AND stock > 50;
```

หาค่าในช่วงด้วย `BETWEEN ... AND ...` (รวมค่าขอบทั้งสองข้าง):
```sql
-- สินค้าราคา 10 ถึง 50 บาท
-- เทียบเท่ากับ WHERE price >= 10 AND price <= 50 แต่เขียนสั้นกว่า
SELECT * FROM products WHERE price BETWEEN 10 AND 50;
```

---

### 4.4 LIKE — ค้นหาข้อความบางส่วน

`%` แทน "ตัวอักษรอะไรก็ได้กี่ตัวก็ได้"

```sql
-- ชื่อที่ขึ้นต้นด้วย "ด"
SELECT * FROM products WHERE name LIKE 'ด%';

-- ชื่อที่มีคำว่า "มุด" อยู่ข้างใน
SELECT * FROM products WHERE name LIKE '%มุด%';
```

---

### 4.5 ORDER BY — เรียงลำดับ

```sql
-- เรียงราคาจากน้อยไปมาก (ASC = น้อย→มาก, เป็นค่าเริ่มต้น)
SELECT * FROM products ORDER BY price ASC;

-- เรียงราคาจากมากไปน้อย
SELECT * FROM products ORDER BY price DESC;
```

---

### 4.6 LIMIT — จำกัดจำนวนแถว

```sql
-- เอามาแค่ 2 แถวแรก
SELECT * FROM products LIMIT 2;

-- สินค้าราคาแพงสุด 3 อันดับ
SELECT * FROM products ORDER BY price DESC LIMIT 3;
```

---

### 4.7 UPDATE — แก้ไขข้อมูล

```sql
-- เปลี่ยนราคาปากกา (id = 1) เป็น 18 บาท
UPDATE products
SET price = 18.00
WHERE id = 1;
```

> **สำคัญมาก:** อย่าลืม `WHERE` ! ถ้าลืม จะแก้ **ทุกแถว** ในตาราง
> ```sql
> UPDATE products SET price = 0;   -- ราคาเป็น 0 หมดทุกชิ้น!
> ```

---

### 4.8 DELETE — ลบข้อมูล

```sql
-- ลบสินค้า id = 3
DELETE FROM products WHERE id = 3;
```

> เช่นเดียวกับ UPDATE — ลืม `WHERE` = **ลบหมดทั้งตาราง**

---

## 5. สรุป Cheat Sheet พื้นฐาน

```sql
-- CREATE
INSERT INTO ตาราง (คอลัมน์1, คอลัมน์2) VALUES (ค่า1, ค่า2);

-- READ
SELECT * FROM ตาราง WHERE เงื่อนไข ORDER BY คอลัมน์ DESC LIMIT จำนวน;

-- UPDATE
UPDATE ตาราง SET คอลัมน์ = ค่าใหม่ WHERE เงื่อนไข;

-- DELETE
DELETE FROM ตาราง WHERE เงื่อนไข;
```

**กฎทอง:** `UPDATE` และ `DELETE` ต้องมี `WHERE` เสมอ (ยกเว้นตั้งใจทำกับทุกแถวจริงๆ)
