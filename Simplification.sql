/*
Simplification Demo 
This uses the AdventureWorks2019 sample database available from:
https://docs.microsoft.com/en-us/sql/samples/adventureworks-install-configure?view=sql-server-ver15&tabs=ssms

These are demo scripts for presentation use ONLY and are not suitable for any 
systems running any production workloads whatsoever.
*/

USE AdventureWorks2019
GO

--JOIN ELIMINATION
--Simple query just on one table
SELECT e.BusinessEntityID, e.JobTitle 
FROM HumanResources.Employee e;

--Now join on tables with foreign key
SELECT e.BusinessEntityID, e.JobTitle 
FROM HumanResources.Employee e
INNER JOIN Person.Person p 
ON e.BusinessEntityID = p.BusinessEntityID;

--Now select on a column from person as well
SELECT e.BusinessEntityID, e.JobTitle, p.LastName -- person table
FROM HumanResources.Employee e
INNER JOIN Person.Person p 
ON e.BusinessEntityID = p.BusinessEntityID;

--drop the foreign key
EXEC sys.sp_dropextendedproperty @name=N'MS_Description' , @level0type=N'SCHEMA',@level0name=N'HumanResources', @level1type=N'TABLE',@level1name=N'Employee', @level2type=N'CONSTRAINT',@level2name=N'FK_Employee_Person_BusinessEntityID'
GO

ALTER TABLE [HumanResources].[Employee] DROP CONSTRAINT [FK_Employee_Person_BusinessEntityID]
GO

--re-run the query without the foreign key
SELECT e.BusinessEntityID, e.JobTitle
FROM HumanResources.Employee e
INNER JOIN Person.Person p ON e.BusinessEntityID = p.BusinessEntityID;

--add the key back again!
ALTER TABLE [HumanResources].[Employee]  WITH CHECK ADD  CONSTRAINT [FK_Employee_Person_BusinessEntityID] FOREIGN KEY([BusinessEntityID])
REFERENCES [Person].[Person] ([BusinessEntityID])
GO

ALTER TABLE [HumanResources].[Employee] CHECK CONSTRAINT [FK_Employee_Person_BusinessEntityID]
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Foreign key constraint referencing Person.BusinessEntityID.' , @level0type=N'SCHEMA',@level0name=N'HumanResources', @level1type=N'TABLE',@level1name=N'Employee', @level2type=N'CONSTRAINT',@level2name=N'FK_Employee_Person_BusinessEntityID'
GO


--CONTRADICTIONS
SELECT e.BusinessEntityID, e.JobTitle FROM HumanResources.Employee e
WHERE SickLeaveHours = 20;

SELECT e.BusinessEntityID, e.JobTitle FROM HumanResources.Employee e
WHERE SickLeaveHours = 20 AND SickLeaveHours = 10;

SELECT e.BusinessEntityID, e.JobTitle FROM HumanResources.Employee e
WHERE SickLeaveHours < 5 AND SickLeaveHours > 20;

--with a Primary Key
SELECT e.BusinessEntityID, e.JobTitle FROM HumanResources.Employee e
WHERE BusinessEntityID < 5 AND BusinessEntityID > 20;

--Contradiction with a Constraint 
--drop first
EXEC sys.sp_dropextendedproperty @name=N'MS_Description' , @level0type=N'SCHEMA',@level0name=N'HumanResources', @level1type=N'TABLE',@level1name=N'Employee', @level2type=N'CONSTRAINT',@level2name=N'CK_Employee_SickLeaveHours'
GO

ALTER TABLE [HumanResources].[Employee] DROP CONSTRAINT [CK_Employee_SickLeaveHours]
GO

--run the query
SELECT e.JobTitle FROM HumanResources.Employee e
WHERE SickLeaveHours = 140;

--recreate constraint forcing sickleave hours between 0 and 120
ALTER TABLE [HumanResources].[Employee]  WITH CHECK 
ADD  CONSTRAINT [CK_Employee_SickLeaveHours] 
CHECK  (([SickLeaveHours]>=(0) AND [SickLeaveHours]<=(120)))
GO

ALTER TABLE [HumanResources].[Employee] CHECK CONSTRAINT [CK_Employee_SickLeaveHours]
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Check constraint [SickLeaveHours] >= (0) AND [SickLeaveHours] <= (120)' , @level0type=N'SCHEMA',@level0name=N'HumanResources', @level1type=N'TABLE',@level1name=N'Employee', @level2type=N'CONSTRAINT',@level2name=N'CK_Employee_SickLeaveHours'
GO

--run the query again using a value outside of the allowed range of values
SELECT e.JobTitle FROM HumanResources.Employee e
WHERE SickLeaveHours = 140;

--in the range - just to confirm
SELECT e.JobTitle FROM HumanResources.Employee e
WHERE SickLeaveHours = 100;
