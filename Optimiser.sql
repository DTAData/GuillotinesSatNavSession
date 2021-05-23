/*
Optimisation Demo 
This uses the AdventureWorks2019 sample database available from:
https://docs.microsoft.com/en-us/sql/samples/adventureworks-install-configure?view=sql-server-ver15&tabs=ssms

These are demo scripts for presentation use ONLY and are not suitable for any 
systems running any production workloads whatsoever.
*/

USE AdventureWorks2019
GO

--DBCC TRACEOFF(8675, -1)
--DBCC TRACEON(3604, -1) -- output DBCC to client; -1 instance


--cumulative instance wide information
SELECT * FROM sys.dm_exec_query_optimizer_info;

--even to see the types of statements we're running
SELECT * FROM sys.dm_exec_query_optimizer_info 
WHERE counter IN ('insert stmt','delete stmt','update stmt','merge stmt')
ORDER BY occurrence DESC;

--does dropping the proc cache reset values?
DBCC FREEPROCCACHE

--see how many hints are being used instance wide
SELECT * FROM sys.dm_exec_query_optimizer_info 
WHERE counter LIKE '%hint%';

--re-run for index hint and check the value again
SELECT FirstName, LastName 
FROM Person.Person WITH (INDEX(IX_Person_LastName_FirstName_MiddleName))
WHERE FirstName = 'Ken'
OPTION (RECOMPILE) --using recompile to force the optimiser to think about it

--how many hints?
SELECT * FROM sys.dm_exec_query_optimizer_info 
WHERE counter LIKE '%hint%';

--how many instance-wide optimisations have occurred
SELECT * FROM sys.dm_exec_query_optimizer_info
WHERE counter = 'optimizations';

--break down of phases
SELECT * FROM sys.dm_exec_query_optimizer_info
WHERE counter IN ('trivial plan','search 0','search 1','search 2')
ORDER BY occurrence DESC;
	
--repeat trivial and rerun / check output
SELECT * FROM Person.Person
OPTION (RECOMPILE);

--check output
SELECT * FROM sys.dm_exec_query_optimizer_info
WHERE counter = 'trivial plan';


--QUERY LEVEL OPTIMISER INFORMATION
DBCC TRACEON(8675, -1) -- show optimisation phases 
DBCC TRACEON(3604, -1) -- switch on output to messages

--simple query to see trace flag 8675 optimiser output in messages
SELECT p.Name As ProductName
FROM Production.Product p
WHERE p.Name <> 'BB Ball Bearing'
OPTION (RECOMPILE);
-- what search phase was used? (Stage 0 requires 3 or more tables)

--timeout query, check the execution plan and the messages output
SELECT * FROM sys.dm_exec_query_optimizer_info
WHERE counter = 'timeout' --current count;

--ACTUAL exec plan
--timeout query - Grant Fritchey: 
--https://www.scarydba.com/2010/11/18/reason-for-early-termination-of-statement/
--Grants book on execution plans is super awesome...and a free PDF
SELECT *
FROM HumanResources.vEmployee AS ve
JOIN Sales.vSalesPerson AS vsp
ON ve.BusinessEntityID = vsp.BusinessEntityID
JOIN Sales.vSalesPersonSalesByFiscalYears AS vspsbfy
ON vspsbfy.SalesPersonID = vsp.BusinessEntityID
OPTION (RECOMPILE);

--Phases of optimisation & Optimisation Gain (3 tables query so will use Stage 0 but pass to Stage 1)
SELECT P.FirstName, P.LastName, o.Status, o.OrderDate, 
AVG(D.OrderQty) as AverageQtyOrdered, count(d.ProductId)  as ItemsCount
FROM Sales.Customer AS C
JOIN Sales.SalesOrderHeader AS O on C.CustomerID=O.CustomerID
JOIN Person.Person P on C.PersonId = P.BusinessEntityId
JOIN Sales.SalesOrderDetail D on O.SalesOrderID = D.SalesOrderID
GROUP BY P.FirstName, P.LastName, o.Status, o.OrderDate
OPTION (RECOMPILE);

--AVERAGE gain moving between phases
SELECT * FROM sys.dm_exec_query_optimizer_info
WHERE counter IN ('gain stage 0 to stage 1','gain stage 1 to stage 2');

--Demo benefits of cached plans for the optimiser
SELECT P.FirstName, P.LastName, o.Status, o.OrderDate, 
AVG(D.OrderQty) as AverageQtyOrdered, count(d.ProductId)  as ItemsCount
FROM Sales.Customer AS C
JOIN Sales.SalesOrderHeader AS O on C.CustomerID=O.CustomerID
JOIN Person.Person P on C.PersonId = P.BusinessEntityId
JOIN Sales.SalesOrderDetail D on O.SalesOrderID = D.SalesOrderID
GROUP BY P.FirstName, P.LastName, o.Status, o.OrderDate;
--OPTION (RECOMPILE) -- we switch off recomplile to retrieve from cache

--do optimiser timeouts still cache?
SELECT *
FROM HumanResources.vEmployee AS ve
JOIN Sales.vSalesPerson AS vsp
ON ve.BusinessEntityID = vsp.BusinessEntityID
JOIN Sales.vSalesPersonSalesByFiscalYears AS vspsbfy
ON vspsbfy.SalesPersonID = vsp.BusinessEntityID

--turn off the trace flags
DBCC TRACEOFF(8675, -1)
DBCC TRACEOFF(3604, -1) 
 
 
 
 
 
 

