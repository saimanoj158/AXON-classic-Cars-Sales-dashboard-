---------------------------------------------------- CAPSTONE PROJECT SQL AND POWER BI ---------------------------------------------
/*Problem Statement:
A small company Axon, which is a retailer selling classic cars, is facing issues in managing and analyzing their
sales data. The sales team is struggling to make sense of the data and they do not have a centralized system to
manage and analyze the data. The management is unable to get accurate and up-to-date sales reports, which
is affecting the decision-making process.
To address this issue, the company has decided to implement a Business Intelligence (BI) tool that can help
them manage and analyze their sales data effectively. They have shortlisted Microsoft PowerBI and SQL as the
BI tools for this project.
*/
-------------------------------------------------------------------------------------------------------------------------------
show databases;
use classicmodels;
show table status;

select * from customers;
select * from employees;
select * from offices;
select * from orderdetails;
select * from orders;
select * from payments;
select * from productlines;
select * from products;


-- Check if there are any missing records in the Customers table.
SELECT COUNT(*) AS MissingCustomerRecords
FROM Customers
WHERE customerNumber IS NULL OR customerName IS NULL ;

-- Verify the completeness of the Orders table.
SELECT COUNT(*) AS MissingOrderRecords
FROM Orders
WHERE orderNumber IS NULL OR orderDate IS NULL OR shippedDate IS NULL;

-- Ensure consistency of customer IDs between Customers and Orders.
SELECT DISTINCT c.customerNumber
FROM Customers c
LEFT JOIN Orders o ON c.customerNumber = o.customerNumber
WHERE o.customerNumber IS NULL ;

/*it means that there are customers in the Customers table for which there is no corresponding entry in the Orders table. 
This situation might occur for customers who have not placed any orders.

In a well-structured database, it's expected that not all customers have placed orders, 
so finding some c.customerNumber in this query result is normal. However, 
it's essential to understand the context and business logic to determine whether this is the expected behavior or 
if it indicates potential data issues. 
If some customers not placing orders is a valid scenario for your business, then you can disregard these results. 
Otherwise, you might want to investigate further or refine the query based on your specific requirements.*/

-- Identify any outliers in the order amounts in OrderDetails.
SELECT orderNumber, quantityOrdered, priceEach
FROM OrderDetails
WHERE quantityOrdered < 1 OR priceEach < 0;

-- Check for anomalies or incorrect entries in the Payments table.
SELECT customernumber, amount
FROM Payments
WHERE amount < 0 ;

-- Verify the integration of data between Orders and Customers.
SELECT o.orderNumber, o.orderDate, c.customerName
FROM Orders o
LEFT JOIN Customers c ON o.customerNumber = c.customerNumber
WHERE c.customerName IS NULL ;

-- Check if there are any missing or inconsistent records in the Employees table.
SELECT COUNT(*) AS MissingEmployeeRecords
FROM Employees
WHERE employeeNumber IS NULL ;

-- Validate the hierarchy in the Employees table.
SELECT e.employeeNumber, concat(e.lastname,e.firstname) as employeename , e.reportsTo, concat(m.lastname,m.firstname) AS ManagerName
FROM Employees e
LEFT JOIN Employees m ON e.reportsTo = m.employeeNumber
WHERE e.reportsTo IS NOT NULL AND m.employeeNumber IS NULL;



-- Check for any orders with missing or inconsistent data.
SELECT orderNumber, customerNumber, productCode, quantityOrdered, priceEach
FROM OrderDetails
WHERE orderNumber IS NULL OR customerNumber IS NULL OR productCode IS NULL OR quantityOrdered IS NULL OR priceEach IS NULL;

--------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------ KPI and insights ----------------------------------------------------
-- Total Sales Amount:
SELECT SUM(od.quantityOrdered * od.priceEach) AS TotalSalesAmount
FROM OrderDetails od;

-- Top Products by Sales:
SELECT p.productCode, p.productName, SUM(od.quantityOrdered * od.priceEach) AS TotalSales
FROM Products p
JOIN OrderDetails od ON p.productCode = od.productCode
GROUP BY p.productCode, p.productName
ORDER BY TotalSales DESC
LIMIT 5;

-- 3. Customer Acquisition Rate:
SELECT COUNT(DISTINCT c.customerNumber) AS NewCustomers
FROM Customers c
LEFT JOIN Orders o ON c.customerNumber = o.customerNumber
WHERE o.customerNumber IS NULL;

-- 4. Customer Retention Rate:
SELECT COUNT(DISTINCT c.customerNumber) AS RetainedCustomers
FROM Customers c
JOIN Orders o ON c.customerNumber = o.customerNumber
LEFT JOIN Payments p ON c.customerNumber = p.customerNumber
WHERE p.customerNumber IS NULL;

-- 5. Average Order Value (AOV):
SELECT AVG(od.quantityOrdered * od.priceEach) AS AverageOrderValue
FROM OrderDetails od;


-- 6.sales growth rate

drop view if exists Quart;
CREATE VIEW Quart AS
SELECT
    orderNumber,year(orderdate) as year_,
    CASE
        WHEN EXTRACT(MONTH FROM orderDate) BETWEEN 1 AND 3 THEN 1  -- Q1
        WHEN EXTRACT(MONTH FROM orderDate) BETWEEN 4 AND 6 THEN 2  -- Q2
        WHEN EXTRACT(MONTH FROM orderDate) BETWEEN 7 AND 9 THEN 3  -- Q3
        WHEN EXTRACT(MONTH FROM orderDate) BETWEEN 10 AND 12 THEN 4 -- Q4
        ELSE NULL
    END AS Quart
FROM Orders;
-- Verify the changes
SELECT * FROM quart;

create view  ord as
(select * from orderdetails join orders using(ordernumber));

select * from ord;
SELECT
    EXTRACT(YEAR FROM orderDate) AS Year,
    MIN(orderDate) AS FirstDate,
    MAX(orderDate) AS LastDate
FROM ord
GROUP BY Year
ORDER BY Year;

-- sales growth by year
select ((sum(case when year(orderdate)=2004 then quantityOrdered * priceEach else 0 end)-
		sum(case when year(orderdate)=2003 then quantityOrdered * priceEach else 0 end))/
        sum(case when year(orderdate)=2003 then quantityOrdered * priceEach else 0 end)) * 100 as sales_growth
from ord;
		

-- sales growth rate quarter wise in particular year
select year_,
		quart,
        ((-lag(tot_sales ,1) over() + tot_sales)/lag(tot_sales ,1) over()) * 100 as sales_growthrateby_quarter
from 
(select year_,quart ,sum(quantityOrdered * priceEach) as tot_sales 
from ord join quart using(ordernumber)
group by 1,2
order by 1,2) a
where year_=2003; 

select year_,
		quart,
        ((-lag(tot_sales ,1) over() + tot_sales)/lag(tot_sales ,1) over()) * 100 as sales_growthrateby_quarter
from 
(select year_,quart ,sum(quantityOrdered * priceEach) as tot_sales 
from ord join quart using(ordernumber)
group by 1,2
order by 1,2) a
 where year_=2004; 

select year_,
		quart,
		((-lag(tot_sales ,1) over() + tot_sales)/lag(tot_sales ,1) over()) * 100 as sales_growthrateby_quarter
from 
(select year_,quart ,sum(quantityOrdered * priceEach) as tot_sales 
from ord join quart using(ordernumber)
group by 1,2
order by 1,2) a 
where year_=2005; 

-- 7. Top Customers by Revenue:
SELECT c.customerNumber, c.customerName, SUM(p.amount) AS TotalPaid
FROM Customers c
JOIN Payments p ON c.customerNumber = p.customerNumber
GROUP BY c.customerNumber, c.customerName
ORDER BY TotalPaid DESC
LIMIT 5;

-- 8. Product Line Performance:
SELECT pl.productLine, SUM(od.quantityOrdered * od.priceEach) AS TotalSales
FROM ProductLines pl
JOIN Products p ON pl.productLine = p.productLine
JOIN OrderDetails od ON p.productCode = od.productCode
GROUP BY pl.productLine
order by TotalSales desc;

-- 9. Average Payment Speed:
SELECT AVG(DATEDIFF(p.paymentDate, o.orderDate)) AS AveragePaymentSpeed
FROM Payments p
JOIN Orders o ON p.customerNumber = o.customerNumber;

select pl.productline,abs(avg(datediff(paymentdate,orderdate))) 
FROM ProductLines pl
JOIN Products p ON pl.productLine = p.productLine
JOIN OrderDetails od ON p.productCode = od.productCode
JOIN Orders o ON od.ordernumber = o.ordernumber
join Payments pa on o.customerNumber = pa.customerNumber
group by 1;

-- 10. Order Fulfillment Time:
SELECT AVG(DATEDIFF(o.shippedDate, o.orderDate)) AS AverageFulfillmentTime
FROM Orders o
WHERE o.shippedDate IS NOT NULL;

-- 11. Employee Performance:
SELECT e.employeeNumber, e.lastName, e.firstName, COUNT(o.orderNumber) AS TotalOrders, SUM(od.quantityOrdered * od.priceEach) AS TotalSales
FROM Employees e
left join customers c on e.employeenumber = c.salesrepemployeenumber
LEFT JOIN Orders o ON c.customernumber = o.customerNumber
LEFT JOIN OrderDetails od ON o.orderNumber = od.orderNumber
GROUP BY e.employeeNumber, e.lastName, e.firstName
order by TotalSales desc;

-- total volume of sales
select sum(quantityordered) as volume_of_sales from orderdetails;

-- countrywise  sales
select o.country,sum(odt.quantityOrdered * odt.priceEach) as TotalSales from offices o 
left join employees e on o.officecode = e.officeCode
left join customers c on e.employeeNumber = c.salesrepemployeenumber
left join orders od on c.customernumber = od.customernumber
left join orderdetails odt on od.ordernumber = odt.orderNumber
left join products p on odt.productCode = p.productCode
group by 1
order by 2 desc;

-- productline wise least order countries
select 	p.productLine,
		o.country,
		count(od.orderNumber) as tot ,
		first_value(o.country) over(partition by p.productLine order by count(od.orderNumber)) as least_orders_country from offices o 

left join employees e on o.officecode = e.officeCode
left join customers c on e.employeeNumber = c.salesrepemployeenumber
left join orders od on c.customernumber = od.customernumber
left join orderdetails odt on od.ordernumber = odt.orderNumber
left join products p on odt.productCode = p.productCode
where p.productLine is not null
group by 1,2
order by 1, tot ;


-- pending amount to received by axon

drop view if exists totsal;
create view totsal as
(SELECT SUM(od.quantityOrdered * od.priceEach) AS TotalSalesAmount , 1 as ind
FROM OrderDetails od);

drop view if exists totamountreceived;
create view totamountreceived as
(select sum(amount) as totamount , 1 as ind from payments);

select TotalSalesAmount-totamount from totsal join totamountreceived using(ind);


/*1. Find the top 10 customers who have placed the most orders. Display customer name and the count of orders placed.*/

with top10_cte as
(select 
	customername , count(*) total_orders ,row_number() over(order by count(*) desc) rankk
 from 
	customers join orders using (customernumber)
	group by 1)
select * from top10_cte where rankk <= 10 ;



/*2. Retrieve the list of customers who have placed orders but haven't made any payments yet.*/
/* creating view in order to get actual values of total orders.*/
drop view if exists orderwise_value_view;
create view orderwise_value_view as 
	(select 
		ordernumber, sum(quantityordered * priceeach) order_value  
	 from
		orderdetails 
        group by 1 
        order by 1);

select * from orderwise_value_view;

with order_cte as
		(select	 
		customernumber, sum(order_value) Total_ordervalue  
	 from  orders join orderwise_value_view using (ordernumber) 
     group by 1 
     order by 1),
paidamount_cte as
 (SELECT  
		customernumber,
        SUM(amount) AS paid_amount
    FROM
        payments
    GROUP BY 1
    ORDER BY 1)

select customername FROM CUSTOMERS 
    WHERE customername not in (select 
		 customername
	from order_cte 
		join paidamount_cte using (customernumber) 
		join customers using (customernumber) 
    );
    
    
/*3.Retrieve a product that has been ordered the least number of times. 
 Display the product code, product name, and the number of times it has been ordered.*/
 
 select 
		productcode, productname, count(ordernumber) over(partition by productcode) total_orders 
	from orders 
		join orderdetails using (ordernumber) 
        join products using (productcode) 
        order by 3 asc 
        limit 1; 