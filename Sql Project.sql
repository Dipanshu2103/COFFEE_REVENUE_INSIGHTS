use project_1;

-- Q1. Coffee Consumers Count 
-- How many people in each city are estimated to consume coffee, given that 25% of the population does?

SELECT 
    city_name,
    ROUND((population * 0.25) / 1000000, 2) AS Coffe_Consumers_in_Millions
FROM
    city
ORDER BY 2;
    
-- Q2. Total Revenue from Coffee Sales
-- What is the total revenue generated from coffee sales across all cities in the last quarter of 2023?

SELECT 
    city_name, SUM(total) AS Total_Revenue
FROM
    city c
        JOIN
    customers cu ON c.city_id = cu.city_id
        JOIN
    sales s ON s.customer_id = cu.customer_id
WHERE
    YEAR(sale_date) = 2023
        AND QUARTER(sale_date) = 4
GROUP BY 1;

-- Q3. Sales Count for Each Product
-- How many units of each coffee product have been sold?

SELECT 
    product_name, COUNT(s.product_id) AS Total_Quantity
FROM
    products p
        LEFT JOIN
    sales s ON p.product_id = s.product_id
GROUP BY 1
ORDER BY 2 DESC;

-- Q.4 Average Sales Amount per Customer per City
-- What is the average sales amount per customer in each city?

SELECT 
    city_name,
    COUNT(DISTINCT cu.customer_id) AS Total_Customer,
    ROUND(SUM(total) / COUNT(DISTINCT cu.customer_id),
            2) AS Average_Sale_Per_Customer
FROM
    city c
        JOIN
    customers cu ON c.city_id = cu.city_id
        JOIN
    sales s ON s.customer_id = cu.customer_id
GROUP BY 1
ORDER BY 3 DESC;

-- Q.5 City Population and Coffee Consumers (25%)
-- Provide a list of cities along with their populations and estimated coffee consumers.
-- return city_name, total current cx, estimated coffee consumers (25%)

SELECT 
    city_name,
    ROUND((population * 0.25) / 1000000, 2) AS Coffe_Consumers_in_Millions,
    COUNT(DISTINCT cu.customer_id) AS Total_Customer
FROM
    city c
        JOIN
    customers cu ON c.city_id = cu.city_id
GROUP BY 1 , 2;

-- Q6 Top Selling Products by City
-- What are the top 3 selling products in each city based on sales volume?

with cte1 as (Select city_id, city_name from city),

cte2 as (select customer_id, city_id, customer_name from customers),

cte3 as (select product_id, product_name from products),

cte4 as (select customer_id, product_id, total from sales),

cte5 as (select city_name, product_name, sum(total) as Selling_products,
rank() over(partition by city_name order by sum(total) desc ) as rnk 
from cte1 join cte2 on cte1.city_id = cte2.city_id
join cte4 on cte4.customer_id = cte2.customer_id
join cte3 on cte3.product_id = cte4.product_id
group by 1,2 )

select city_name, product_name, Selling_products 
from cte5
where rnk <=3;

-- Q7. Customer Segmentation by City
-- How many unique customers are there in each city who have purchased coffee products?

SELECT 
    city_name, COUNT(DISTINCT s.customer_id) AS Unique_Customer
FROM
    city c
        JOIN
    customers cu ON c.city_id = cu.city_id
        JOIN
    sales s ON s.customer_id = cu.customer_id
GROUP BY 1;

-- Q8. Average Sale vs Rent
-- Find each city and their average sale per customer and avg rent per customer

SELECT 
    city_name,
    ROUND(SUM(total) / COUNT(DISTINCT s.customer_id),
            2) AS Average_Sale,
    ROUND(SUM(estimated_rent) / COUNT(DISTINCT s.customer_id),
            2) AS Average_Rent
FROM
    city c
        JOIN
    customers cu ON c.city_id = cu.city_id
        JOIN
    sales s ON s.customer_id = cu.customer_id
GROUP BY 1;

-- Q9. Monthly Sales Growth
-- Sales growth rate: Calculate the percentage growth (or decline) in sales over different time periods (monthly)
-- by each city

with cte1 as (Select city_name,
             year(sale_date) as Years, 
             month(sale_date) as Months, 
             sum(total) as Total_Sale
   from city c
         join customers cu on c.city_id = cu.city_id
         join sales s on s.customer_id = cu.customer_id
group by 1,2,3),

cte2 as (Select *, 
concat(round((Total_sale-lag(Total_Sale) over(partition by city_name order by Years, Months))/
lag(Total_Sale) over(partition by city_name order by Years, Months),2)*100,"%") as Monthly_Growth
from cte1)

SELECT 
    *
FROM
    cte2
WHERE
    monthly_growth IS NOT NULL;
    
-- Q10. Market Potential Analysis
-- Identify top 3 city based on highest sales, return city name, total sale, total rent, total customers, estimated coffee consumer.

SELECT 
    city_name,
    SUM(total) AS Total_Sales,
    SUM(estimated_rent) AS Total_Rent,
    COUNT(s.customer_id) AS Total_Customer,
    ROUND((population * 0.25) / 1000000, 2) AS Coffe_Consumers_in_Millions
FROM
    city c
        JOIN
    customers cu ON c.city_id = cu.city_id
        JOIN
    sales s ON s.customer_id = cu.customer_id
        JOIN
    products p ON p.product_id = s.product_id
GROUP BY 1 , 5
ORDER BY 2 DESC
LIMIT 3;

-- Q11. Find the percentage contribution of each product to the total revenue.

SELECT 
    product_name,
    CONCAT((ROUND((SUM(total) / (SELECT 
                            SUM(total)
                        FROM
                            sales)) * 100,
                    2)),
            '%') AS Product_Contribution
FROM
    products p
        JOIN
    sales s ON p.product_id = s.product_id
GROUP BY 1;

-- Q12. Identify customers who have purchased products from more than 3 different cities.

Select city_name, customer_name ,product_name, count(s.product_id)
from city c
        JOIN
    customers cu ON c.city_id = cu.city_id
        JOIN
    sales s ON s.customer_id = cu.customer_id
    join products p on p.product_id = s.product_id
    group by 1,2,3
    having city_name >=3;

-- Q13. Rank the cities based on total revenue generated.

SELECT 
    city_name, SUM(total) AS Total_Revenue
FROM
    city c
        JOIN
    customers cu ON c.city_id = cu.city_id
        JOIN
    sales s ON s.customer_id = cu.customer_id
        JOIN
    products p ON p.product_id = s.product_id
GROUP BY 1
ORDER BY Total_Revenue DESC;

-- Q14. Find the difference in total sales between the best and worst-performing products.

with cte1 as (Select product_name, sum(total) as Total
from products p join sales s 
on p.product_id = s.product_id
group by 1
order by 2 desc),

cte2 as (Select first_value(Total)over() -
last_value(Total) over(rows between unbounded preceding and unbounded following) as Difference
from cte1)

Select Difference 
from( select *,row_number() over() as Row1 from cte2 )t
where row1=1;

-- Q15. Retrieve a list of customers who have never made a purchase.

SELECT 
    customer_name
FROM
    customers c
        LEFT JOIN
    sales s ON c.customer_id = s.customer_id
WHERE
    sale_id IS NULL;