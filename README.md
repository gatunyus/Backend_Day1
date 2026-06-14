# Day 1 — SQL & phpMyAdmin

วันแรกเราจะทำความรู้จัก **ฐานข้อมูล (Database)** และภาษา **SQL** ที่ใช้คุยกับฐานข้อมูล
โดยใช้ **phpMyAdmin** (หน้าจอจัดการฐานข้อมูลที่มากับ XAMPP) เป็นสนามฝึก

> เป้าหมายของวันนี้: เขียน SQL จัดการข้อมูลได้คล่อง ตั้งแต่ระดับพื้นฐานจนถึง JOIN และ Transaction

---

## จุดประสงค์การเรียนรู้
เมื่อจบ Day 1 คุณจะสามารถ:
- เข้าใจว่า Database / Table / Row / Column / Primary Key คืออะไร
- สร้างตารางและเลือกชนิดข้อมูล (datatype) ได้เหมาะสม
- เขียน **CRUD** ได้: `INSERT` (เพิ่ม), `SELECT` (อ่าน), `UPDATE` (แก้), `DELETE` (ลบ)
- กรอง/เรียง/ค้นหาข้อมูลด้วย `WHERE`, `ORDER BY`, `LIKE`, `LIMIT`
- เข้าใจหลัก **Relational Database**: ความสัมพันธ์ 1:1 / 1:N / M:N, Anomaly, Normalization
- เชื่อมหลายตารางด้วย `JOIN` และใช้ `FOREIGN KEY` (รวมถึง `ON DELETE` และตารางกลาง M:N)
- สรุปข้อมูลด้วย `COUNT / SUM / AVG` + `GROUP BY`
- ใช้ **Transaction** (`COMMIT` / `ROLLBACK` / `SAVEPOINT`) เพื่อความถูกต้องของข้อมูล

---

## สารบัญ Day 1 (ทำตามลำดับ)

| ลำดับ | ไฟล์ | ประเภท | เนื้อหา |
| :-- | :-- | :-- | :-- |
| 0 | [00_setup_xampp.md](./00_setup_xampp.md) | เตรียมตัว | เปิด XAMPP, เข้า phpMyAdmin, สร้าง Database แรก |
| 1 | [01_sheet_sql_basic.md](./01_sheet_sql_basic.md) | ชีท | พื้นฐานตาราง + CRUD + WHERE/ORDER/LIKE/LIMIT |
| 2 | [02_lab_sql_basic.md](./02_lab_sql_basic.md) | Lab 1 | ฝึก CRUD บนตารางสินค้า |
| 3 | [03_sheet_sql_advanced.md](./03_sheet_sql_advanced.md) | ชีท | Relational (1:N, M:N, Normalization), FOREIGN KEY, JOIN, Aggregate, Transaction |
| 4 | [04_lab_sql_advanced.md](./04_lab_sql_advanced.md) | Lab 2 | ฝึก JOIN (รวม M:N) + GROUP BY + Transaction |

ไฟล์ประกอบ:
- [`src/basic.sql`](./src/basic.sql) — ใช้ใน Lab 1
- [`src/advanced.sql`](./src/advanced.sql) — ใช้ใน Lab 2

