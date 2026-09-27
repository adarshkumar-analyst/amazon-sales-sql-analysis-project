# Amazon Sales SQL Analysis Project

End-to-end SQL project analyzing a 100K-row Amazon sales dataset — covering business performance, product, customer, seller, payment, geography, and trend analysis using MySQL.

## 📂 Files

| File | Description |
|------|-------------|
| `Amazon.csv` | Raw dataset — 100,000 order records (2022–2024) |
| `amazon_sales_analysis.sql` | Full SQL script: table creation + 25+ analysis queries |

## 📊 Dataset Overview

20 columns per order, including:
`OrderID, OrderDate, CustomerID, CustomerName, ProductID, ProductName, Category, Brand, Quantity, UnitPrice, Discount, Tax, ShippingCost, TotalAmount, PaymentMethod, OrderStatus, City, State, Country, SellerID`

## 🛠️ Tech Stack
- MySQL (window functions, CTEs, aggregations)

## 🔍 Analysis Covered

**Data Preparation**
- Row count & duplicate check
- Null value check

**Business Performance**
- Total revenue, orders, units sold, AOV
- Monthly revenue trend
- Year-over-year revenue growth
- Top 5 revenue months
- Category revenue contribution %

**Product & Category**
- Top 10 products by revenue
- Best-selling product (qty vs revenue)
- Category-wise revenue, discount, AOV
- Top 3 products per category
- Products with revenue decline
- Brand-wise AOV comparison

**Customer Analysis**
- Top 10 customers by spending
- One-time vs repeat customer %
- Customer segmentation (High/Medium/Low spender)
- Average order frequency
- Repeat customers (2023 & 2024)
- RFM (Recency, Frequency, Monetary) metrics
- Top 10 customers per country

**Seller Analysis**
- Top 10 sellers by revenue
- Cancellation rate per seller
- Avg shipping cost per seller
- Product range per seller

**Order Status & Fulfillment**
- Order status distribution
- Cancellation rate by category & payment method
- Revenue lost to cancellations/returns

**Payment Method Analysis**
- Revenue share by payment method
- Highest AOV payment method
- COD vs Digital payment trend (year-wise)

**Geographical Analysis**
- Top 5 states per country by revenue
- City with highest customer count

**Advanced/Window Functions**
- Cumulative monthly revenue
- YoY category revenue growth

## 🚀 How to Use
1. Import `Amazon.csv` into MySQL (create the `amazon_sales` table using the script).
2. Run `amazon_sales_analysis.sql` section by section.
3. Each query is labeled with a comment describing its purpose.

## 👤 Author
Adarsh Kumar
