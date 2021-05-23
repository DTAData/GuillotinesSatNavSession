/*
Trivial Plans Demo 
This uses the AdventureWorks2019 sample database available from:
https://docs.microsoft.com/en-us/sql/samples/adventureworks-install-configure?view=sql-server-ver15&tabs=ssms

These are demo scripts for presentation use ONLY and are not suitable for any 
systems running any production workloads whatsoever.
*/

USE AdventureWorks2019
GO

--Check in the estimated/actual plan properties under 
--OptimizationLevel to see if the optimiser chooses trivial plan
--or full optimisation

--simple SELECT *
SELECT * FROM Person.Person;

--using predicate witl columns
SELECT FirstName, LastName FROM Person.Person 
WHERE LastName = 'Myer';

--predicate with SELECT *
SELECT * FROM Person.Person 
WHERE LastName = 'Myer';

--LIKE
SELECT * FROM Person.Person 
WHERE LastName LIKE 'My%';

--LIKE double wildcard
SELECT * FROM Person.Person 
WHERE LastName LIKE '%My%';

--inequality predicate with SELECT *
SELECT * FROM Person.Person 
WHERE LastName <> 'Myer';

--inequality SELECT cols
SELECT FirstName, LastName FROM Person.Person 
WHERE LastName <> 'Myer';

--join
SELECT p.Name As ProductName
FROM Production.Product p
INNER JOIN Production.ProductModel pm 
ON p.ProductModelID = pm.ProductModelID;

--SELECT * with predicate, no covering index
SELECT FirstName, LastName FROM Person.Person 
WHERE FirstName = 'Ken';

--Introduce using hints, these override the optimisers decision
--making process and lets us determine the "best way" - generally
--speaking this is really not a good idea!

--force the non-clustered index 
SELECT FirstName, LastName 
FROM Person.Person WITH (INDEX(IX_Person_LastName_FirstName_MiddleName))
WHERE FirstName = 'Ken';

--force index on join query
SELECT FirstName, LastName 
FROM Person.Person p WITH (INDEX(PK_Person_BusinessEntityID))
INNER JOIN HumanResources.Employee e 
ON p.BusinessEntityID = e.BusinessEntityID
WHERE FirstName = 'Ken';

--force both indexes and a join
SELECT FirstName, LastName 
FROM Person.Person p WITH (INDEX(PK_Person_BusinessEntityID))
INNER LOOP JOIN HumanResources.Employee e -- force nested loop join
WITH (INDEX(PK_Employee_BusinessEntityID))
ON p.BusinessEntityID = e.BusinessEntityID
WHERE FirstName = 'Ken';

