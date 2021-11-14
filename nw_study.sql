
--1a. What were Northwind’s top selling products? 

SELECT TOP (3) pro.ProductName, SUM(os.Subtotal) AS Total, SUM(ode.Quantity) AS Quantity
FROM     Northwind.dbo.Orders AS o INNER JOIN
                  Northwind.dbo.[Order Details Extended] AS ode ON o.OrderID = ode.OrderID INNER JOIN
                  Northwind.dbo.[Order Subtotals] AS os ON o.OrderID = os.OrderID INNER JOIN
                  Northwind.dbo.Products AS pro ON ode.ProductID = pro.ProductID
GROUP BY pro.ProductName
ORDER BY Quantity DESC;

--1b.What products make the most profit?

SELECT TOP (3) pro.ProductName, SUM(os.Subtotal) AS Total, SUM(ode.Quantity) AS Quantity
FROM     Northwind.dbo.Orders AS o INNER JOIN
                  Northwind.dbo.[Order Details Extended] AS ode ON o.OrderID = ode.OrderID INNER JOIN
                  Northwind.dbo.[Order Subtotals] AS os ON o.OrderID = os.OrderID INNER JOIN
                  Northwind.dbo.Products AS pro ON ode.ProductID = pro.ProductID
GROUP BY pro.ProductName
ORDER BY Total DESC;


--2. Who are the best customers in terms of sales? 

SELECT TOP (3) FirstName, LastName, ProductName, Sales
FROM     (SELECT e.FirstName, e.LastName, p.ProductName, SUM((od.UnitPrice * od.Quantity) * (1 - od.Discount)) AS Sales
                  FROM      Northwind.dbo.Orders AS oh INNER JOIN
                                    Northwind.dbo.[Order Details] AS od ON oh.OrderID = od.OrderID INNER JOIN
                                    Northwind.dbo.Products AS p ON p.ProductID = od.ProductID INNER JOIN
                                    Northwind.dbo.Employees AS e ON e.EmployeeID = oh.EmployeeID
                  GROUP BY e.FirstName, e.LastName, p.ProductName) AS a
ORDER BY Sales DESC

--3a. How many orders were shipped on time? 

SELECT COUNT(*) AS [Shipped on Time]
FROM     Northwind.dbo.Orders
WHERE  (RequiredDate = ShippedDate)


--3b. Late? How late? 
SELECT	TOP 3 RequiredDate, ShippedDate, DATEDIFF(day, RequiredDate, ShippedDate) AS Difference, 
		CASE 
			WHEN datediff(day, RequiredDate, ShippedDate) > 0 THEN 'Late' 
			ELSE 'Shipped on Time' 
		END AS Message
FROM	Northwind.dbo.Orders
ORDER BY Difference DESC;


--4. Who is the top performing shipping company?

SELECT COUNT(o.OrderID) AS [Total Number of Orders], s.CompanyName
FROM     Northwind.dbo.Orders AS o INNER JOIN
                  Northwind.dbo.Shippers AS s ON o.EmployeeID = s.ShipperID
GROUP BY s.CompanyName
ORDER BY [Total Number of Orders] DESC
--5. How much did Northwind sell by each product category?

CREATE VIEW [Product Categories] AS
SELECT top 1000 t.ProductName,t.category,  sales
FROM (
		SELECT  p.ProductName,
				MAX(p.CategoryID) category, 
				SUM(od.Quantity) sales,
				ROW_NUMBER() OVER (PARTITION BY MAX(p.CategoryID) ORDER BY SUM(od.Quantity) DESC) rn
		FROM Northwind.dbo.Products AS p INNER JOIN 
					Northwind.dbo.[Order Details] AS od  ON p.ProductID=od.ProductID Inner JOIN 
					Northwind.dbo.Orders AS o  ON o.OrderID=od.OrderID 
		GROUP BY p.ProductName,p.CategoryID
	) t
ORDER BY t.category;

GO
SELECT DISTINCT category, MAX(sales) AS [Max Sales], ProductName
FROM     [Product Categories]
GROUP BY category, ProductName
ORDER BY category, [Max Sales] DESC;

--DROP VIEW [Product Categories]


--6. Which employee made the highest sales based on the total amount in each time period? Yearly? Quarterly?

SELECT	CONCAT(FirstName, ' ' ,LastName) AS [Employee Name],
		[Yearly Ranking],[Quarter Rank],
		SUM (od.quantity) AS [Total Quantity] 
FROM  Northwind.dbo.Employees AS e Inner JOIN
		Northwind.dbo.Orders AS o  ON e.EmployeeID=o.EmployeeID Inner JOIN 
		Northwind.dbo.[Order Details] AS od  ON o.OrderID=od.OrderID Inner JOIN
	(
		SELECT  *,
		[Quarter Rank]=  dense_rank() OVER (ORDER BY year(OrderDate), datepart(quarter,OrderDate)
	)
		FROM Northwind.dbo.Orders) AS oo ON e.EmployeeID=oo.EmployeeID Inner JOIN
	(
		SELECT  *,
			[Yearly Ranking]=  dense_rank() OVER (ORDER BY year(OrderDate)
	)
		FROM Northwind.dbo.Orders) AS ooo ON e.EmployeeID=ooo.EmployeeID
GROUP BY [Quarter Rank],[Yearly Ranking],e.FirstName, e.LastName
ORDER BY [Quarter Rank],[Yearly Ranking],[Total Quantity]  DESC;
   

-- another way

SELECT	CONCAT(FirstName, ' ' ,LastName) AS [Employee Name],
		[Quarter Rank],
		SUM (od.quantity) AS [Total Quantity] 
FROM Northwind.dbo.Employees AS e Inner JOIN
		Northwind.dbo.Orders AS o  ON e.EmployeeID=o.EmployeeID Inner JOIN 
		Northwind.dbo.[Order Details] AS od  ON o.OrderID=od.OrderID Inner JOIN
	(
		SELECT  *,
			[Quarter Rank]=  NTILE(8) OVER (order by OrderDate)
		FROM Northwind.dbo.Orders
	) AS oo ON e.EmployeeID=oo.EmployeeID 
GROUP BY [Quarter Rank],e.FirstName, e.LastName
ORDER BY [Quarter Rank],[Total Quantity]  DESC;




  
--7.Create a query that will return a message if the order has more products ordered than the in-stock. 

SELECT o.OrderID, o.CustomerID, SUM(os.Subtotal) AS Total, SUM(ode.Quantity) AS Quantity, 
		Message = CASE
					WHEN COUNT(CASE	WHEN Quantity > pro.UnitsInStock OR Discontinued = 1 THEN 1 END) > 0 THEN 'Out of Stock'	
					ELSE 'In Stock'
				  END 
FROM   Northwind.dbo.Orders AS o LEFT OUTER JOIN
                  Northwind.dbo.[Order Details Extended] AS ode ON o.OrderID = ode.OrderID LEFT OUTER JOIN
                  Northwind.dbo.[Order Subtotals] AS os ON o.OrderID = os.OrderID LEFT OUTER JOIN
				  Northwind.dbo.Products AS pro ON ode.ProductID = pro.ProductID
GROUP BY o.OrderID, o.CustomerID;







