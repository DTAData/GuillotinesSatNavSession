/*
Transformation Rules Plans Demo 
This uses the AdventureWorks2019 sample database available from:
https://docs.microsoft.com/en-us/sql/samples/adventureworks-install-configure?view=sql-server-ver15&tabs=ssms

These are demo scripts for presentation use ONLY and are not suitable for any 
systems running any production workloads whatsoever.
*/

USE AdventureWorks2019
GO

DBCC TRACEON (3604); -- switch on DBCC output to messages

--show transformation rules that are enabled
DBCC SHOWONRULES;

--but the DMV is much easier to show the rules
--but it doesnt show on or off.
--PROMISED = how useful
--SUCCEEDED = successfully used
 SELECT name, promised, succeeded 
 FROM sys.dm_exec_query_transformation_stats;
 
 --all rules containing 'JN' (joins)
 SELECT name, succeeded 
 FROM sys.dm_exec_query_transformation_stats
 WHERE name LIKE '%JN%';
  
--number of JNtoHS - Hash Match
SELECT name, succeeded 
FROM sys.dm_exec_query_transformation_stats
WHERE [name] = 'JNtoHS'; -- (hash match join rule)

--run again, check join type of the query 
SELECT p.Name As ProductName, ps.Name As ProductSubcategoryName
FROM Production.Product p
INNER JOIN Production.ProductSubcategory ps
ON p.ProductSubcategoryID = ps.ProductSubcategoryID
OPTION (RECOMPILE);

-- use QUERYRULEOFF hint to turn off the hash match join, 
-- now which join type is used by the optimiser?
SELECT p.Name As ProductName, ps.Name As ProductSubcategoryName
FROM Production.Product p
INNER JOIN Production.ProductSubcategory ps
ON p.ProductSubcategoryID = ps.ProductSubcategoryID
OPTION(QUERYRULEOFF JNtoHS);
 
 --same join type using a hint
 SELECT p.Name As ProductName, ps.Name As ProductSubcategoryName
FROM Production.Product p
INNER MERGE JOIN Production.ProductSubcategory ps
ON p.ProductSubcategoryID = ps.ProductSubcategoryID;

--disable hash and merge; now what?!
SELECT p.Name As ProductName, ps.Name As ProductSubcategoryName
FROM Production.Product p
INNER JOIN Production.ProductSubcategory ps
ON p.ProductSubcategoryID = ps.ProductSubcategoryID
OPTION( QUERYRULEOFF JNtoHS, QUERYRULEOFF JNtoSM, RECOMPILE);


--WHAT HAPPENS NEXT?!
--disable hash match, merge and nested loop
SELECT p.Name As ProductName, ps.Name As ProductSubcategoryName
FROM Production.Product p
INNER JOIN Production.ProductSubcategory ps
ON p.ProductSubcategoryID = ps.ProductSubcategoryID
OPTION( QUERYRULEOFF JNtoHS, QUERYRULEOFF JNtoSM, QUERYRULEOFF JNtoNL, RECOMPILE);

--DROP TABLE #JoinCountsBefore 
--DROP TABLE #JoinCountsAfter
--Query from Benjamin Neverez - Inside the Query Optimiser
--available from RedGate
-- use temp tables to record the before and after
SELECT * INTO #JoinCountsBefore FROM
(
 SELECT name, succeeded FROM sys.dm_exec_query_transformation_stats
 WHERE name LIKE 'JN%' 
 ) AS x
 SELECT TOP 1 p.Name As ProductName, ps.Name As ProductSubcategoryName
FROM Production.Product p
INNER JOIN Production.ProductSubcategory ps
ON p.ProductSubcategoryID = ps.ProductSubcategoryID
OPTION( QUERYRULEOFF JNtoHS, QUERYRULEOFF JNtoSM, QUERYRULEOFF JNtoNL, RECOMPILE)
SELECT * INTO #JoinCountsAfter FROM
(
 SELECT name, succeeded FROM sys.dm_exec_query_transformation_stats
 WHERE name LIKE 'JN%' 
 ) AS x
  SELECT bef.name, bef.succeeded, aft.succeeded FROM #JoinCountsBefore bef
 INNER JOIN #JoinCountsAfter aft ON bef.name = aft.name AND bef.succeeded <> aft.succeeded;
 --displays any transformation values that have changed before/after query execution
 
 --LET DISABLE THAT ONE TOO :-)
SELECT p.Name As ProductName, ps.Name As ProductSubcategoryName
FROM Production.Product p
INNER JOIN Production.ProductSubcategory ps
ON p.ProductSubcategoryID = ps.ProductSubcategoryID
OPTION(QUERYRULEOFF JNtoHS, QUERYRULEOFF JNtoSM, QUERYRULEOFF JNtoNL, QUERYRULEOFF JNtoIdxLookup, RECOMPILE);


 -- but what happens if we use a hash hint but turn off hash join rule?
SELECT p.Name As ProductName, ps.Name As ProductSubcategoryName
FROM Production.Product p
INNER HASH JOIN Production.ProductSubcategory ps
ON p.ProductSubcategoryID = ps.ProductSubcategoryID
OPTION(RECOMPILE, QUERYRULEOFF JNtoHS);

--lets see all optimisations performed per query using the same
--temp table gather approach
DROP TABLE #JoinCountsBefore;
DROP TABLE #JoinCountsAfter;

--all transformations applied to the query
SELECT * INTO #JoinCountsBefore FROM
(
 SELECT name, succeeded FROM sys.dm_exec_query_transformation_stats
 ) AS x

 SELECT TOP 1 p.Name As ProductName, ps.Name As ProductSubcategoryName
FROM Production.Product p
INNER HASH JOIN Production.ProductSubcategory ps
ON p.ProductSubcategoryID = ps.ProductSubcategoryID
OPTION (RECOMPILE) --take out and run again

SELECT * INTO #JoinCountsAfter FROM
(
 SELECT name, succeeded FROM sys.dm_exec_query_transformation_stats
 ) AS x

 SELECT bef.name, bef.succeeded, aft.succeeded FROM #JoinCountsBefore bef
 INNER JOIN #JoinCountsAfter aft ON bef.name = aft.name AND bef.succeeded <> aft.succeeded;

 --BENEFITS OF TRANSOFRMATION RULES
 --aggregrate pushdown before join, cost benefit - PLAN!
  SELECT c.CustomerID, COUNT(*) FROM Sales.Customer c 
JOIN Sales.SalesOrderHeader o ON c.CustomerID = o.CustomerID 
GROUP BY c.CustomerID 
OPTION (QUERYRULEOFF GbAggBeforeJoin); --switch on and off to compare
--pushdown difference (predicate - aggregrate)

--instance wide query hinting! (PLEASE dont do this!)
--TURN OFF HASH MATCH JOIN ACROSS THE WHOLE INSTANCE
DBCC RULEOFF('JNtoHS');

--SHOW OFF RULES
DBCC SHOWOFFRULES;

--re-run query
SELECT p.Name As ProductName, ps.Name As ProductSubcategoryName
FROM Production.Product p
INNER JOIN Production.ProductSubcategory ps
ON p.ProductSubcategoryID = ps.ProductSubcategoryID;

DBCC RULEON('JNtoHS'); -- for the best, enable it again!

--turn off optimiser trace flag
DBCC TRACEOFF(8675, -1);
DBCC TRACEOFF(3604, -1);

--if we've got time!
--Initial Memo
SELECT p.Name As ProductName, ps.Name As ProductSubcategoryName
FROM Production.Product p
INNER JOIN Production.ProductSubcategory ps
ON p.ProductSubcategoryID = ps.ProductSubcategoryID
OPTION (QUERYTRACEON 8608, QUERYTRACEON 8675, QUERYTRACEON 3604, RECOMPILE);

--Final Memo
SELECT p.Name As ProductName, ps.Name As ProductSubcategoryName
FROM Production.Product p
INNER JOIN Production.ProductSubcategory ps
ON p.ProductSubcategoryID = ps.ProductSubcategoryID
OPTION (QUERYTRACEON 8615, QUERYTRACEON 8675, RECOMPILE);

--run the query without recompile/cached plan
SELECT p.Name As ProductName, ps.Name As ProductSubcategoryName
FROM Production.Product p
INNER JOIN Production.ProductSubcategory ps
ON p.ProductSubcategoryID = ps.ProductSubcategoryID
OPTION (QUERYTRACEON 8615, QUERYTRACEON 8675);

DBCC TRACEOFF(3604, -1);

