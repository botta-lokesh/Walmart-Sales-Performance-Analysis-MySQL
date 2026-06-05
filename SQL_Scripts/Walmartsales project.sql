SELECT * FROM walmart_sales.sales_data;

## Missing Value Checks
SELECT *
FROM walmart_sales.sales_data
WHERE Branch IS NULL
   OR City IS NULL
   OR Customer_type IS NULL
   OR Gender IS NULL
   OR Product_line IS NULL
   OR Unit_price IS NULL
   OR Quantity IS NULL
   OR Total IS NULL
   OR Payment IS NULL
   OR Rating IS NULL;
   
 ## Duplicate Record Checks
SELECT Invoice_id,
       COUNT(*) AS Duplicate_Count
FROM walmart_sales.sales_data
GROUP BY Invoice_id
HAVING COUNT(*) > 1;

## Date Conversion

ALTER TABLE walmart_sales.sales_data MODIFY COLUMN Date DATE;
ALTER TABLE walmart_sales.sales_data MODIFY COLUMN Invoice_id varchar(20);
ALTER TABLE walmart_sales.sales_data MODIFY COLUMN Branch varchar(5),MODIFY COLUMN City varchar(50),MODIFY COLUMN Customer_type varchar(20),
MODIFY COLUMN Gender varchar(10),MODIFY COLUMN Product_line varchar(30),MODIFY COLUMN Payment varchar(30);
ALTER TABLE walmart_sales.sales_data MODIFY COLUMN Time TIME;

DESCRIBE walmart_sales.sales_data;



## Task 1: Top Branch by Sales Growth Rate
WITH monthly_sales AS (
    SELECT
        Branch,
        MONTH(Date) AS month_no,
        SUM(Total) AS monthly_sales
    FROM walmart_sales.sales_data
    GROUP BY Branch, MONTH(Date)
),
growth_rate AS (
    SELECT
        Branch,
        month_no,
        monthly_sales,
        LAG(monthly_sales) OVER(
            PARTITION BY Branch
            ORDER BY month_no
        ) AS prev_month_sales
    FROM monthly_sales
)
SELECT
    Branch,
    ROUND(
        AVG(
            ((monthly_sales - prev_month_sales)
            / prev_month_sales) * 100
        ),2
    ) AS avg_growth_rate
FROM growth_rate
WHERE prev_month_sales IS NOT NULL
GROUP BY Branch
ORDER BY avg_growth_rate DESC;


##Task 2: Most Profitable Product Line for Each Branch
WITH product_profit AS (
    SELECT
        Branch,
        Product_line,
        ROUND(SUM(gross_income),2) AS total_profit
    FROM walmart_sales.sales_data
    GROUP BY Branch, Product_line
),
ranked_products AS (
    SELECT *,
           RANK() OVER(
               PARTITION BY Branch
               ORDER BY total_profit DESC
           ) AS rnk
    FROM product_profit
)
SELECT *
FROM ranked_products
WHERE rnk = 1;


## Task 3: Customer Segmentation Based on Spending
WITH customer_spending AS (
    SELECT
        Customer_ID,
        SUM(Total) AS total_spent
    FROM walmart_sales.sales_data
    GROUP BY Customer_ID
)
SELECT
    Customer_ID,
    total_spent,
    CASE
        WHEN total_spent >= 23000 THEN 'High'
        WHEN total_spent >= 20000 THEN 'Medium'
        ELSE 'Low'
    END AS spending_segment
FROM customer_spending
ORDER BY total_spent DESC;


## Task 4: Detecting Anomalies in Sales Transactions
WITH stats AS (
    SELECT
        Product_line,
        AVG(Total) AS avg_sales,
        STDDEV(Total) AS std_sales
    FROM walmart_sales.sales_data
    GROUP BY Product_line
)
SELECT
    w.Invoice_ID,
    w.Product_line,
    w.Total,
    ROUND(
        (w.Total - s.avg_sales)
        / s.std_sales,
        2
    ) AS z_score
FROM walmart_sales.sales_data w
JOIN stats s
ON w.Product_line = s.Product_line
WHERE ABS(
      (w.Total - s.avg_sales)
      / s.std_sales
) > 2;



##Task 5: Most Popular Payment Method by City
WITH payment_count AS (
    SELECT
        City,
        Payment,
        COUNT(*) AS payment_frequency
    FROM walmart_sales.sales_data
    GROUP BY City, Payment
),
ranked_payments AS (
    SELECT *,
           RANK() OVER(
                PARTITION BY City
                ORDER BY payment_frequency DESC
           ) AS rnk
    FROM payment_count
)
SELECT
    City,
    Payment,
    payment_frequency
FROM ranked_payments
WHERE rnk = 1;

## Task 6: Monthly Sales Distribution by Gender
WITH gender_sales AS (
    SELECT
        MONTHNAME(Date) AS month_name,
        MONTH(Date) AS month_no,
        Gender,
        ROUND(SUM(Total),2) AS total_sales
    FROM walmart_sales.sales_data
    GROUP BY
        MONTH(Date),
        MONTHNAME(Date),
        Gender
)
SELECT
    month_name,
    Gender,
    total_sales,
    ROUND(
        total_sales * 100 /
        SUM(total_sales) OVER(PARTITION BY month_no),
        2
    ) AS contribution_percent
FROM gender_sales
ORDER BY month_no;


## Task 7: Best Product Line by Customer Type
WITH product_sales AS (
    SELECT
        Customer_type,
        Product_line,
        SUM(Total) AS revenue
    FROM walmart_sales.sales_data
    GROUP BY
        Customer_type,
        Product_line
),
ranked_products AS (
    SELECT *,
           RANK() OVER(
                PARTITION BY Customer_type
                ORDER BY revenue DESC
           ) AS rnk
    FROM product_sales
)
SELECT
    Customer_type,
    Product_line,
    revenue
FROM ranked_products
WHERE rnk = 1;

## Task 8: Identifying Repeat Customers
WITH purchase_history AS (
    SELECT
        Customer_ID,
        Date,
        LAG(Date) OVER(
            PARTITION BY Customer_ID
            ORDER BY Date
        ) AS previous_purchase
    FROM walmart_sales.sales_data
)
SELECT
    Customer_ID,
    Date,
    previous_purchase,
    DATEDIFF(Date, previous_purchase) AS days_gap
FROM purchase_history
WHERE DATEDIFF(Date, previous_purchase) <= 30;



## Task 9: Top 5 Customers by Sales Volume
WITH customer_sales AS (
    SELECT
        Customer_ID,
        SUM(Total) AS total_revenue
    FROM walmart_sales.sales_data
    GROUP BY Customer_ID
)
SELECT
    Customer_ID,
    total_revenue,
    RANK() OVER(
        ORDER BY total_revenue DESC
    ) AS customer_rank
FROM customer_sales
LIMIT 5;


## Task 10: Sales Trends by Day of Week
SELECT
    DAYNAME(Date) AS day_name,
    ROUND(SUM(Total),2) AS total_sales,
    COUNT(*) AS transactions
FROM walmart_sales.sales_data
GROUP BY DAYNAME(Date)
ORDER BY total_sales DESC;
