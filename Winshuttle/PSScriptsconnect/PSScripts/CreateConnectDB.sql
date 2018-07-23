USE [master]
GO

--IF  EXISTS (SELECT name FROM sys.databases WHERE name = N'$(DataBase)')
--DROP DATABASE $(DataBase)
--GO

USE [master]
GO

/****** Creating Database $(DataBase)  ******/
PRINT 'Creating Database...'
CREATE DATABASE $(DataBase)
GO
PRINT 'Database created successfully...'
GO