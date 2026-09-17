# Olist E-Commerce Business Performance & Customer Analytics

> **End-to-end Data Analytics Project** analyzing e-commerce business performance, customer behavior, product categories, seller performance, delivery operations, and customer satisfaction using **PostgreSQL, SQL, Power BI, and DAX**.

---

## 📌 Project Overview

This project analyzes the **Brazilian E-Commerce Public Dataset by Olist**, covering approximately **99K orders from 2016–2018**.

The objective is to transform raw e-commerce data into actionable business insights across several key areas:

* 💰 Revenue and order performance
* 👥 Customer retention and purchase frequency
* 💎 Customer revenue concentration
* 🛍️ Product category performance
* 🏪 Seller performance
* 🚚 Delivery performance
* ⭐ Customer satisfaction
* 📍 Geographic delivery performance

The project follows an **end-to-end data analytics workflow**, beginning with data validation and cleaning in PostgreSQL, followed by SQL-based business analysis and interactive dashboard development in Power BI.

---

## 🎯 Business Questions

The analysis was designed to answer the following business questions:

1. How does revenue and order performance change over time?
2. Which product categories contribute the most revenue and order volume?
3. How significant are repeat customers?
4. How concentrated is revenue among high-value customers?
5. Which sellers contribute significantly to revenue and order volume?
6. How well does the platform perform in terms of delivery?
7. Is delivery performance associated with customer review scores?
8. How does delivery performance vary across Brazilian states?

---

## 🗂️ Dataset

**Dataset:** Brazilian E-Commerce Public Dataset by Olist

The dataset contains information related to:

* Customers
* Orders
* Order items
* Products
* Sellers
* Payments
* Reviews
* Product category translations

The dataset covers approximately **100K orders between 2016 and 2018**.

### Main Tables

| Table                               | Description                            |
| ----------------------------------- | -------------------------------------- |
| `customers`                         | Customer information and location      |
| `orders`                            | Order information and timestamps       |
| `order_items`                       | Products purchased within each order   |
| `products`                          | Product information and category       |
| `sellers`                           | Seller information and location        |
| `order_payments`                    | Payment information                    |
| `order_reviews`                     | Customer review scores                 |
| `product_category_name_translation` | Portuguese-to-English category mapping |

### Important Data Grain Consideration

`orders` and `order_items` have a **one-to-many relationship**.

Therefore, order-level metrics such as:

* Total Orders
* Customer Orders
* Delivery Status

must use **distinct order counting** when joined with `order_items`.

Example:

```sql
COUNT(DISTINCT order_id)
```

This prevents order duplication during analysis.

---

## 🧹 Data Preparation & Validation

Data preparation and validation were performed using **PostgreSQL**.

### Timestamp Cleaning

Several timestamp fields were originally stored as text values and contained empty strings.

Empty strings were handled using:

```sql
NULLIF(column_name, '')::TIMESTAMP
```

This preserves missing values as `NULL`, which is important for orders that have not yet been delivered.

### Delivery Status

Orders were classified into three delivery statuses:

| Status          | Definition                                         |
| --------------- | -------------------------------------------------- |
| `On Time`       | Delivered on or before the estimated delivery date |
| `Late`          | Delivered after the estimated delivery date        |
| `Not Delivered` | No delivered customer date available               |

An order was considered late when:

```text
Delivered Date > Estimated Delivery Date
```

Orders without a delivered customer date were classified as:

```text
Not Delivered
```

### Category Validation

The English product category is not stored directly in the `products` table.

The category mapping follows:

```text
products.product_category_name
            ↓
product_category_name_translation.product_category_name
            ↓
product_category_name_english
```

The translation table was also checked for duplicate category keys.

**Result:** No duplicate translation keys were found.

Some products had missing or empty categories, or categories without an English translation. These records were classified as:

```text
Unknown / Untranslated
```

Approximately **98.64% of product revenue** could be mapped to translated categories.

---

## 📊 Key Metrics

| Metric               |        Result |
| -------------------- | ------------: |
| Unique Customers     |    **96,096** |
| Total Orders         |    **99,441** |
| Orders with Items    |    **98,666** |
| Product Revenue      | **~R$13.60M** |
| Average Order Value  |  **R$137.74** |
| Repeat Customer Rate |     **3.12%** |
| Late Delivery Rate   |     **8.11%** |
| Average Review Score |     **~4.09** |

### Revenue Definition

Product revenue is calculated using:

```text
order_items.price
```

`freight_value` is excluded from the revenue metric.

### Average Order Value (AOV)

AOV is calculated as:

```text
Product Revenue
────────────────────
Orders with Items
```

Result:

```text
R$137.74
```

---

# 📈 Power BI Dashboard

The Power BI dashboard consists of **three analytical pages**, each designed around a specific business perspective.

---

## 1. Executive Overview

![Executive Overview](images/executive_overview.png)

The **Executive Overview** provides a high-level view of overall business performance.

### KPIs

* Total Revenue
* Total Orders
* Total Customers
* Average Order Value

### Visualizations

* Monthly Revenue Trend
* Revenue by Product Category
* Revenue by State
* Category / Seller Performance

### Business Question

> **How is the business performing?**

---

## 2. Customer Analytics

![Customer Analytics](images/customer_analytics.png)

The **Customer Analytics** page focuses on customer behavior and revenue contribution.

### KPIs

* Total Customers
* Repeat Customers
* Repeat Customer Rate
* Revenue from Repeat Customers

### Visualizations

* One-Time vs Repeat Customers
* Customer Order Frequency
* Revenue by Customer Type
* Customer Revenue Contribution

### Business Question

> **Who are the customers and how do they purchase?**

---

## 3. Delivery & Satisfaction

![Delivery & Satisfaction](images/delivery_satisfaction.png)

The **Delivery & Satisfaction** page analyzes logistics performance and customer experience.

### KPIs

* Late Delivery Rate
* On-Time Delivery Rate
* Not Delivered Orders
* Average Review Score

### Visualizations

* Review Score by Delivery Status
* Review Score Distribution
* Late Delivery Rate by State
* Delivery Performance Details

### Business Question

> **How does delivery performance relate to customer satisfaction?**

---

# 🔎 Key Findings

## 1. Revenue Grew Strongly During 2017

Monthly revenue increased substantially throughout 2017.

**November 2017** recorded approximately:

> ### R$1.01M

with:

* **7,451 orders**
* Approximately **52.10% month-over-month revenue growth** compared with October 2017

Revenue then fluctuated during 2018 while remaining at a relatively high level through August.

---

## 2. Repeat Customers Represent a Small Portion of the Customer Base

Only:

> ### 3.12%

of unique customers were classified as repeat customers.

However, repeat customers generated higher revenue per customer:

| Customer Type | Customers | Revenue / Customer |
| ------------- | --------: | -----------------: |
| One-Time      |    93,099 |           R$137.66 |
| Repeat        |     2,997 |           R$259.87 |

This indicates that **customer purchase frequency is an important dimension for further customer analysis**.

---

## 3. Revenue Is Concentrated Among High-Value Customers

The top **10% of customers**, ranked by product revenue, contributed:

> ### 41.23% of Total Product Revenue

This indicates that revenue contribution is not evenly distributed across the customer base.

**Important:** This analysis measures revenue contribution and should not be interpreted as a direct measure of customer loyalty.

---

## 4. Category Performance Differs Between Order Volume and Revenue

Order volume does not necessarily correspond directly to revenue contribution.

| Category                | Orders |  Revenue |
| ----------------------- | -----: | -------: |
| `health_beauty`         |  8,836 | R$1.259M |
| `watches_gifts`         |  5,624 | R$1.205M |
| `bed_bath_table`        |  9,417 | R$1.037M |
| `sports_leisure`        |  7,720 |   R$988K |
| `computers_accessories` |  6,689 |   R$912K |

For example, `bed_bath_table` generated more orders than `health_beauty`, while `health_beauty` generated higher product revenue.

This demonstrates why category performance should be evaluated using **both transaction volume and monetary contribution**.

---

## 5. Late Delivery Rate Was 8.11% Among Delivered Orders

Overall delivery performance:

| Status        | Orders |  Share |
| ------------- | -----: | -----: |
| On Time       | 88,649 | 89.15% |
| Late          |  7,827 |  7.87% |
| Not Delivered |  2,965 |  2.98% |

The late delivery rate among **delivered orders** was:

> ### 8.11%

`Not Delivered` orders were excluded from the denominator when calculating the late delivery rate.

---

## 6. Late Deliveries Were Associated With Lower Review Scores

Average review scores differed between late and on-time deliveries:

| Delivery Status | Reviewed Orders | Average Review |
| --------------- | --------------: | -------------: |
| Late            |           5,395 |           2.57 |
| On Time         |          62,371 |           4.29 |

The difference was:

> ### 1.72 Review Points

This indicates an **association between delivery status and customer review scores** in the observed data.

> ⚠️ **Important:** This analysis does **not establish causality**. The observed relationship does not prove that late delivery directly caused lower review scores.

---

## 7. Delivery Performance Varies Across States

Late delivery rates varied considerably across Brazilian states.

| State | Delivered Orders | Late Orders | Late Rate |
| ----- | ---------------: | ----------: | --------: |
| CE    |            1,279 |         196 |    15.32% |
| BA    |            3,256 |         457 |    14.04% |
| RJ    |           12,353 |       1,664 |    13.47% |
| SP    |           40,495 |       2,387 |     5.89% |
| MG    |           11,355 |         638 |     5.62% |
| PR    |            4,923 |         246 |     5.00% |

Both **delivery rate and order volume** should be considered when interpreting geographic delivery performance.

---

# 💡 Potential Business Actions

The observed patterns suggest several areas that could be investigated further.

### 1. Customer Retention

Further segment customers based on:

* Purchase frequency
* Revenue
* Recency
* Category preference

This can support more targeted retention and engagement analysis.

### 2. High-Value Customer Analysis

Monitor high-revenue customers using:

* Revenue contribution
* Purchase frequency
* Category preference
* Changes in purchasing behavior

### 3. Category Strategy

Evaluate categories using multiple dimensions:

* Order volume
* Revenue
* Revenue share
* Revenue per order

### 4. Delivery Performance

Investigate late delivery patterns by:

* State
* Seller
* Order characteristics
* Delivery duration

### 5. Customer Experience

Combine delivery KPIs with review metrics to monitor potential relationships between **logistics performance and customer satisfaction**.

---

# ⚠️ Limitations

Several limitations should be considered when interpreting this analysis.

### Historical Dataset

The dataset covers approximately **2016–2018** and therefore does not represent current e-commerce performance.

### Revenue Definition

Revenue is calculated using:

```text
order_items.price
```

and excludes:

```text
freight_value
```

### No Cost Data

The dataset does not provide sufficient cost information to calculate:

* Profit
* Profit margin

Therefore, high-revenue categories or sellers should **not automatically be interpreted as the most profitable**.

### Review Data

Review analysis only includes orders with available reviews.

Therefore, review results may not represent every order.

### Correlation vs. Causation

The relationship between delivery status and review score should be interpreted as an **association**, rather than proof that late delivery directly caused lower reviews.

### Category Mapping

A small portion of product revenue could not be mapped to an English product category and was classified as:

```text
Unknown / Untranslated
```

---

# 🛠️ Tools & Technologies

| Technology       | Purpose                                              |
| ---------------- | ---------------------------------------------------- |
| **PostgreSQL**   | Data storage, cleaning, validation, and SQL analysis |
| **SQL**          | Business analysis and data transformation            |
| **Power BI**     | Interactive dashboard and data visualization         |
| **DAX**          | Business metrics and calculated measures             |
| **Git & GitHub** | Version control and project documentation            |

---

# 📁 Project Structure

```text
olist-ecommerce-business-analytics/
│
├── README.md
│
├── sql/
│   ├── 01_data_validation.sql
│   ├── 02_data_cleaning.sql
│   ├── 03_business_analysis.sql
│   └── 04_advanced_analysis.sql
│
├── powerbi/
│   └── Olist_Ecommerce_Analytics.pbix
│
├── images/
│   ├── executive_overview.png
│   ├── customer_analytics.png
│   └── delivery_satisfaction.png
│
└── data/
    └── README.md
```

---

# 🚀 Future Improvements

Potential extensions for this project include:

* Customer RFM segmentation
* Customer cohort analysis
* Customer lifetime value analysis
* Seller performance segmentation
* Delivery time analysis
* Category-level customer segmentation
* Pareto analysis of revenue contribution
* Statistical analysis of delivery and review scores
* Predictive modeling for repeat purchases
* Predictive delivery delay analysis

---

# 👤 Author

**Fathur Rahman Rifaldi**

Information Systems Student

Interested in:

* Data Analytics
* Business Intelligence
* Machine Learning
* Information Systems

---

## 📌 Disclaimer

This project is intended for **educational and portfolio purposes**.

The business recommendations represent potential areas for further investigation based on the available dataset and should not be interpreted as confirmed causal conclusions.