

-- Table Creation & load check table
CREATE TABLE amazon_sales (
    OrderID VARCHAR(20) PRIMARY KEY,
    OrderDate DATE,
    CustomerID VARCHAR(20),
    CustomerName VARCHAR(100),
    ProductID VARCHAR(20),
    ProductName VARCHAR(100),
    Category VARCHAR(50),
    Brand VARCHAR(50),
    Quantity INT,
    UnitPrice DECIMAL(10,2),
    Discount DECIMAL(4,2),
    Tax DECIMAL(10,2),
    ShippingCost DECIMAL(10,2),
    TotalAmount DECIMAL(10,2),
    PaymentMethod VARCHAR(30),
    OrderStatus VARCHAR(20),
    City VARCHAR(50),
    State VARCHAR(50),
    Country VARCHAR(50),
    SellerID VARCHAR(20)
);

-- PRE ANALYSIS /DATA PREPARATION QUERIES

-- ROW COUNT AND DUPLICATES
select COUNT(*) 
 from amazon_sales;
 
select OrderID,
      count(*) 
from amazon_sales
group by OrderID
having count(*)>1;

-- NULLS CHECK 
select
     sum(OrderDate is null) as null_date,
     sum(TotalAmount is null) as null_total_amount,
     sum(CustomerID is null) as null_customer_id
	from amazon_sales;

-- ============================================================
-- BUSINESS PERFORMANCE ANALYSIS
-- ============================================================

-- Calculate total revenue, total orders, total units sold, average order value (AOV), and average order quantity.
select 
    round(
           sum(TotalAmount),2) as Total_Revenue,
    count(distinct OrderID) as TotalOrders,
    sum(Quantity) as Total_Units_Sold,
    round(
           avg(TotalAmount),2) as Avg_Order_Value,
    round(
          avg(Quantity),2) as Avg_Order_Quantity
from amazon_sales;

-- Analyze monthly revenue, order volume, units sold, and AOV to identify monthly sales trends.
select month(OrderDate) as Month_Number, 
      monthname(OrderDate) as Month_Name,
      year(OrderDate) as Year,
      round(
      sum(TotalAmount),2) as Total_Revenue,
      count(distinct OrderID) as Order_Volume,
      sum(Quantity) as Total_Units_Solds,
      round(
      avg(TotalAmount),2) as Avg_Order_Value
 from amazon_sales
 group by Month_Name,Year,Month_Number
 order by Year,Month_Number;

-- Calculate year-over-year revenue growth percentage for each year.

with yearly_sales as (
    select 
        year(OrderDate) as Year,
        round(sum(TotalAmount), 2) as Total_Revenue
    from amazon_sales
    group by year(OrderDate)
)
select 
    Year,
    Total_Revenue,
    lag(Total_Revenue) over(order by Year) as Previous_Revenue,
    round(
        (Total_Revenue - lag(Total_Revenue) over(order by Year))
        * 100 / lag(Total_Revenue) over(order by Year),
        2
    ) as Percentage_Growth
from yearly_sales;



-- Identify the top 5 months with the highest revenue and compare their order volume and AOV.
with top_5_highest_revenue as 
(
select *,
         rank() over(order by Total_Revenue desc) as rnk
from
( 
         select month(OrderDate) as Month_Number, 
                 monthname(OrderDate) as Month_Name,
                 year(OrderDate) as Year,
                round(
                        sum(TotalAmount),2) as Total_Revenue,
               count(distinct OrderID) as Order_Volume,
               sum(Quantity) as Total_Units_Solds,
               round(
                    avg(TotalAmount),2) as Avg_Order_Value
 from amazon_sales
 group by Month_Name,Year,Month_Number
 order by Year,Month_Number)t
 )
 select *
  from top_5_highest_revenue
  where rnk<=5;
 
 

-- Calculate each category's percentage contribution to total revenue.
select Category,
       round(
       sum(TotalAmount),2) as Total_Revenue,
       round( 
       sum(TotalAmount)*100/(select sum(TotalAmount) from amazon_sales),2) as Percentage_Of_TotalRevenue
 from amazon_sales
 group by Category;


-- ============================================================
-- PRODUCT & CATEGORY ANALYSIS
-- ============================================================

-- Identify the top 10 products by total revenue and show their units sold, order count, and average selling price.
with top_products_ranking as 
(
select *,
        rank() over(order by Total_Revenue desc) Rank_
	from
(
select ProductName,
       round(
       sum(TotalAmount),2) as Total_Revenue,
       sum(Quantity) as Total_Units_Sold,
	   count(OrderID) as Total_Orders,
       round(
       avg(UnitPrice),2) as Avg_Unit_Price
 from amazon_sales
 group by ProductName)t)
 
select *
  from top_products_ranking 
   where Rank_<=10;
  

-- Identify the best-selling product by quantity and the best-performing product by revenue, and determine whether they are the same.

with product_sales as 
(
    select 
        ProductName,
        sum(Quantity) as Total_Quantity,
        round(sum(TotalAmount), 2) as Total_Revenue
    from amazon_sales
    group by ProductName
),
ranked_products as
 (
    select *,
        rank() over(order by Total_Quantity desc) as Quantity_Rank,
        rank() over(order by Total_Revenue desc) as Revenue_Rank
    from product_sales
)
select 
    ProductName,
    Total_Quantity,
    Total_Revenue,
    Quantity_Rank,
    Revenue_Rank,
    case
        when Quantity_Rank = 1 and Revenue_Rank = 1 then 'same product'
        when Quantity_Rank = 1 then 'highest quantity'
        when Revenue_Rank = 1 then 'highest revenue'
    end as Product_Performance
from ranked_products
where Quantity_Rank = 1
   or Revenue_Rank = 1;

-- Calculate category-wise revenue, units sold, order count, AOV, and average discount.
select Category,
       round(
       sum(TotalAmount),2) as Total_Revenue,
       sum(Quantity) as Total_Units_Sold,
	   count(OrderID) as Total_Orders,
       round(
       avg(UnitPrice),2) as Avg_Order_Value,
       round(
       avg(Discount)*100,2) as Avg_Discount
 from amazon_sales
 group by Category
 order by Total_Revenue;

-- Identify the top 3 products within each category based on revenue.
with top_product_by_category as 
(
select *,
       rank() over(partition by Category order by Total_Revenue desc) as Rnk
 from 
 (
select Category,
        ProductName,
       round(
       sum(TotalAmount),2) as Total_Revenue
 from amazon_sales
group by ProductName,Category)t
)
select *
  from top_product_by_category
   where rnk<=3;


-- Identify products whose revenue declined compared with the previous year and calculate the percentage decline.
select *,
       round(
       (Total_Revenue-Previous_Month_Revenue)*100/Total_Revenue,2) as Percetage_Of_Decline
from
(
select *,
       lag(Total_Revenue) over(partition by ProductName order by Year) as previous_Month_Revenue,
       round(
       Total_Revenue-lag(Total_Revenue) over(partition by ProductName order by Year),2) as Difference
from
(
select ProductName,
       year(OrderDate) as Year,
       monthname(OrderDate) as Month_Name,
       month(OrderDate) as Month_Number,
       round(
       sum(TotalAmount),2) as Total_Revenue
 from amazon_sales
 group by ProductName,Year,
          Month_Name,Month_Number
 order by Year,Month_Number)t
 )s
 where Difference<0;



-- Identify the brands with the highest average order value and compare their order volume.
select Brand,
	   round(
       avg(TotalAmount),2) as Avg_Order_Value,
       count(OrderID) as Order_Volume
 from amazon_sales
 group by Brand
 order by Avg_Order_Value desc;

-- ============================================================
-- CUSTOMER ANALYSIS
-- ============================================================

-- Identify the top 10 customers by total spending and show their order count, units purchased, and AOV.
select 
    CustomerID,
    CustomerName,
    round(sum(TotalAmount), 2) as Total_Spending,
    count(distinct OrderID) as Total_Orders,
    sum(Quantity) as Units_Purchased,
    round(avg(TotalAmount), 2) as Avg_Order_Value
from amazon_sales
group by CustomerID, CustomerName
order by Total_Spending desc
limit 10;

-- Calculate the number and percentage of one-time customers versus repeat customers.
with one_time_customer as (
select count(*) as one_time_customers 
from(
select CustomerID
from amazon_sales
group by CustomerID
having count(distinct OrderID)=1
    )t
),
total_customers as (
select count(distinct CustomerID) as Total_Customers
from amazon_sales
)
select 
      'One Time Customers' as Customer_Type,
      one_Time_Customers as Number_Of_Customers,
      round(
            one_Time_Customers*100/total_customers,
             2) as Percentage
	from one_time_customer,total_customers

union all
 
select 'Repeat Customers' as Customer_Type,
       Total_Customers-one_time_customers as Number_of_Customers,
       round(
               (Total_Customers-one_time_customers )*100/Total_Customers,
                    2) as Percentage
from one_time_customer,total_customers;


-- Segment customers into High, Medium, and Low spenders based on their total spending.
select *,
       case
            when Total_Spending >10000 then 'High Spender'
            when Total_Spending between 5000 and 10000 then 'Medium Spender'
            else  'Low Spender'
		     end as Customer_Segment
 from
  (
select CustomerID,
       round(
       sum(TotalAmount),2) as Total_Spending
 from amazon_sales
 group by CustomerID
 order by Total_Spending desc)t;

-- Calculate the average number of orders placed per customer and compare it with the overall average order frequency.
with customer_orders as (
    select 
        CustomerID,
        count(distinct OrderID) as Total_Orders
    from amazon_sales
    group by CustomerID
),
overall_avg as (
    select avg(Total_Orders) as Overall_Avg_Orders
    from customer_orders
)
select 
    CustomerID,
    Total_Orders,
    round(
        (select Overall_Avg_Orders from overall_avg),
        2
    ) as Overall_Avg_Orders
from customer_orders;

-- Identify customers who placed orders in both 2023 and 2024.
select CustomerID
from amazon_sales
where year(OrderDate) in (2023, 2024)
group by CustomerID
having count(distinct year(OrderDate)) = 2;



-- Calculate Recency, Frequency, and Monetary (RFM) metrics for each customer.
select 
    CustomerID,

    datediff(
        (select max(OrderDate) from amazon_sales),
        max(OrderDate)
    ) as Recency,

    count(distinct OrderID) as Frequency,

    round(sum(TotalAmount), 2) as Monetary
from amazon_sales
group by CustomerID;

-- Identify the top 10 customers in each country based on total spending.
with customer_spending as (
    select 
        Country,
        CustomerID,
        round(sum(TotalAmount), 2) as Total_Spending
    from amazon_sales
    group by Country, CustomerID
),
customer_rank as (
    select *,
        rank() over( partition by Country order by Total_Spending desc) as rnk
    from customer_spending
)
select *
from customer_rank
where rnk <= 10;

-- ============================================================
-- SELLER ANALYSIS
-- ============================================================

-- Identify the top 10 sellers by total revenue and show their order count, units sold, AOV, and average discount.
select 
    SellerID,
    round(
          sum(TotalAmount), 2) as Total_Revenue,
    count(distinct OrderID) as Total_Orders,
    sum(Quantity) as Units_Sold,
    round(
          avg(TotalAmount), 2) as Avg_Order_Value,
    round(
          avg(Discount),2) as Avg_Discount
from amazon_sales
group by SellerID
order by Total_Revenue desc
limit 10;


-- Calculate the order cancellation rate for each seller and identify sellers with the highest cancellation rates.

select SellerID,
      count(OrderStatus) as Total_Order,
      count(distinct case
                       when OrderStatus='Cancelled' then OrderID end) as Cancelled_Orders,
	  round(
	  count(distinct case
                       when OrderStatus='Cancelled' then OrderID end)*100/ count(OrderStatus),2) as Cancellation_Rate
 from amazon_sales
 group by SellerID
 order by Cancellation_Rate desc
 limit 5;
 

-- Identify sellers with the highest average shipping cost per order.
with avg_shipping_cost as 
(
select SellerID,
       round(
       avg(ShippingCost),2) as avg_shipping_cost
 from amazon_sales
 group by SellerID
),
shipping_cost_rnk as
(
select *,
       rank() over(order by avg_shipping_cost desc) as rank_shipping_cost
 from avg_shipping_cost
)
select *
      from shipping_cost_rnk 
       where rank_shipping_cost<=10;

-- Calculate the number of unique products handled by each seller and identify sellers with the widest product range.
select  SellerID,
        count(ProductName) Total_Products,
        count( distinct ProductName) Unique_products_count,
        count(ProductName)-count( distinct ProductName) as Difference
 from amazon_sales
 group by SellerID
 order by Unique_products_count desc;

 
 -- ============================================================
-- ORDER STATUS & FULFILLMENT ANALYSIS
-- ============================================================

-- Calculate the distribution and percentage of orders across each order status.
select OrderStatus as Order_Status,
       count(OrderStatus) Distribution_Order_Status,
      round(
      count(OrderStatus)*100/(select count(OrderStatus) from amazon_sales),2) as percetage_of_orders
 from amazon_sales
group by Order_Status
order by Distribution_Order_Status;

-- Calculate the cancellation rate by product category and identify categories with the highest cancellation rates.
select 
    Category,
    count(distinct OrderID) as Total_Orders,
    count(distinct case 
        when OrderStatus = 'Cancelled' then OrderID 
    end) as Cancelled_Orders,
    round(
        count(distinct case 
            when OrderStatus = 'Cancelled' then OrderID 
        end) * 100.0
        / count(distinct OrderID),
        2
    ) as Cancellation_Rate
from amazon_sales
group by Category
order by Cancellation_Rate desc;


-- Calculate the cancellation rate by payment method and identify the payment methods with the highest cancellation rates.
select PaymentMethod,
       count(ProductName) as Total_Orders,
       count(distinct case
                          when OrderStatus='Cancelled' then OrderID end) as Cancellled_product_status,
		count(distinct case
                          when OrderStatus='Cancelled' then OrderID end)*100/ count(ProductName) as cancellation_rate
	   
 from amazon_sales
 group by PaymentMethod;

-- Calculate the revenue associated with cancelled and returned orders and determine their percentage of total revenue.
 
 select 'Cancelled' as Order_Status,
        sum(case
               when OrderStatus='Cancelled' then TotalAmount end) Revenue,
		round(
        sum(case
               when OrderStatus='Cancelled' then TotalAmount end)*100/
                                                                      (select sum(TotalAmount) from amazon_sales),2) as percetage_total_revenue
from amazon_sales

union all 
 select 'Returned',
        sum(case
               when OrderStatus='Returned' then TotalAmount end) Revenue,
		round(
        sum(case
               when OrderStatus='Returned' then TotalAmount end)*100/
                                                                      (select sum(TotalAmount) from amazon_sales),2) as percetage_total_revenue
from amazon_sales;

-- ============================================================
-- PAYMENT METHOD ANALYSIS
-- ============================================================

-- Calculate revenue, order count, and revenue share for each payment method.
select PaymentMethod,
       round(
       sum(TotalAmount),2) as Revenue,
       count(OrderID) as Total_Orders,
       round(
        sum(TotalAmount) * 100.0 /
        (select sum(TotalAmount) from amazon_sales),2) as Revenue_Share_Percentage
 from amazon_sales
 group by PaymentMethod;

-- Identify the payment method with the highest average order value.
with avg_order_value as 
(
select PaymentMethod,
       avg(TotalAmount) as Avg_Order_Value
 from amazon_sales
 group by PaymentMethod
),
Rank_avg_order_value as 
(
select *,
        rank() over(order by Avg_Order_Value desc) rnk
  from avg_order_value
  )
  select *
   from Rank_avg_order_value
    where rnk=1;

-- Compare COD and digital payment revenue trends across different years.

select 
    year(OrderDate) as Year,
    case 
        when PaymentMethod = 'Cash on Delivery' then 'Cash on Delivery'
        else 'Digital Payment'
    end as Payment_Type,
    round(sum(TotalAmount), 2) as Total_Revenue
from amazon_sales
group by 
    year(OrderDate),
    case 
        when PaymentMethod = 'Cash on Delivery' then 'Cash on Delivery'
        else 'Digital Payment'
    end
order by Year, Payment_Type;

-- ============================================================
-- GEOGRAPHICAL ANALYSIS
-- ============================================================

-- Analyze revenue by country and identify the top 5 states within each country based on revenue.
with rank_states as (
select *,
       rank() over(partition by Country order by revenue desc) rnk
 from(
select country,
	   state,
      round(
      sum(TotalAmount),2) as revenue
 from amazon_sales
 group by Country,State)t)
 
 select *
  from rank_states
   where rnk<=5;

-- Identify the city with the highest customer count and compare its revenue and average order value.
with city_analysis as 
(
select City,
	   count(distinct CustomerID) as Total_Customers,
       round(
       sum(TotalAmount),2) as Revenue,
       round(
       avg(TotalAmount),2) as Avg_Order_value
  from amazon_sales
  group by City
),
rank_city as 
(
select *,
         rank() over(order by Total_Customers desc) rnk
from city_analysis
)
select *
 from rank_city
  where rnk=1;
 

-- ============================================================
-- ADVANCED TREND & WINDOW FUNCTION ANALYSIS
-- ============================================================

-- Calculate the running cumulative revenue by month.
with revenue_year_month as 
(
select  year(OrderDate) as Year,
        month(OrderDate) as Month,
       round(
       sum(TotalAmount),2) as Revenue
 from amazon_sales
 group by Month,Year
 order by Year,Month
)
 select *,
        round(
        sum(Revenue) over(order by Year,Month),2) cumulative
	from revenue_year_month;

-- Calculate year-over-year revenue growth for each product category.
with category_product_analysis as (
select year(OrderDate) Year,
       Category,
       round(
       sum(TotalAmount),2) as Revenue
 from amazon_sales
 group by Year,Category
),
Previous_revenue as 
(
 select *,
        lag(Revenue) over(partition by Category order by Year) previous_revenue
	from category_product_analysis)
select *,
        round(
        (Revenue-previous_revenue)*100/previous_revenue,2) as Growth
 from Previous_revenue




