Olist E-Commerce Business Performance & Customer Analytics

Project ini merupakan analisis data e-commerce menggunakan PostgreSQL, SQL, Power BI, dan DAX untuk memahami performa penjualan, perilaku pelanggan, performa pengiriman, serta hubungannya dengan customer satisfaction.

Analisis menggunakan Brazilian E-Commerce Public Dataset by Olist, yang berisi data transaksi e-commerce pada periode 2016–2018.

Project ini dibuat sebagai portfolio project untuk posisi Data Analyst Internship/PKL, dengan pendekatan yang berfokus pada business questions, data validation, exploratory analysis, KPI, data visualization, dan business insights.

## 🎯 Business Questions

Analisis ini berfokus pada beberapa pertanyaan bisnis:

1. Bagaimana perkembangan revenue dan jumlah order dari waktu ke waktu?
2. Kategori produk apa yang memiliki kontribusi revenue dan order terbesar?
3. Bagaimana karakteristik customer berdasarkan frekuensi pembelian?
4. Seberapa besar kontribusi repeat customer terhadap revenue?
5. Bagaimana performa pengiriman berdasarkan status keterlambatan?
6. Apakah terdapat hubungan antara keterlambatan pengiriman dengan customer review?
7. Bagaimana variasi performa delivery antar-state di Brazil?

## 🔄 Data Analysis Workflow

Proses analisis dilakukan melalui beberapa tahap:

1. **Data Understanding**
   - Memahami struktur dan relasi antar tabel.
   - Mengidentifikasi grain pada setiap tabel.
   - Menentukan metrik dan business questions.

2. **Data Validation & Cleaning**
   - Memeriksa duplicate records.
   - Memeriksa missing values.
   - Membersihkan timestamp.
   - Memvalidasi relasi antar tabel.
   - Memastikan tidak terjadi double counting pada revenue dan orders.

3. **SQL Analysis**
   - Menggunakan PostgreSQL untuk melakukan data transformation dan business analysis.
   - Menggunakan aggregation, CTE, window functions, JOIN, dan conditional logic.

4. **Exploratory Data Analysis**
   - Menganalisis sales trend.
   - Customer behavior.
   - Category performance.
   - Delivery performance.
   - Review distribution.

5. **Power BI & DAX**
   - Membuat KPI.
   - Membuat interactive dashboard.
   - Membuat calculated measures menggunakan DAX.

6. **Business Insights**
   - Menginterpretasikan hasil analisis.
   - Mengidentifikasi pola yang relevan dengan bisnis.
   - Menyusun potential business actions.

   ## 🔍 Key Findings

### 1. Customer Retention

Dari 96.096 unique customers:

- 93.099 customer (96,88%) hanya melakukan satu kali pembelian.
- 2.997 customer (3,12%) melakukan repeat purchase.
- Repeat customer menghasilkan rata-rata revenue per customer sekitar
  R$259,87, dibandingkan R$137,66 pada one-time customer.

Temuan ini menunjukkan adanya perbedaan revenue contribution antara
customer yang melakukan repeat purchase dan customer yang hanya
melakukan satu transaksi.

---

### 2. Customer Revenue Concentration

10% customer dengan revenue tertinggi berkontribusi sekitar **41,23%**
terhadap total product revenue.

Hal ini menunjukkan bahwa revenue tidak tersebar secara merata di
seluruh customer base.

---

### 3. Delivery Performance

Dari order yang telah delivered:

- On Time: 89,15%
- Late: 7,87%
- Late Delivery Rate: 8,11%

Late Delivery Rate dihitung hanya berdasarkan order yang sudah delivered,
sehingga order dengan status `Not Delivered` tidak dikategorikan sebagai
late delivery.

---

### 4. Delivery & Customer Satisfaction

Pada order yang memiliki review:

| Delivery Status | Average Review |
|---|---:|
| On Time | 4,29 |
| Late | 2,57 |

Terdapat perbedaan rata-rata review sebesar **1,72 poin** antara order
late dan on-time.

