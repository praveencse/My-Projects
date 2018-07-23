CREATE DATABASE tngmgr ON  
  PRIMARY  
  (  
   NAME       = tngmgr_Data , 
   FILENAME   = 'c:\ss2008\MSSQL.SQLEXPRESS\MSSQL\DATA\tngmgr_Data.MDF' , 
   SIZE       = 10MB      , 
   MAXSIZE    = UNLIMITED , 
   FILEGROWTH = 10MB 
  ) 
  LOG ON  
  ( 
   NAME       = tngmgr_Log , 
   FILENAME   = 'c:\ss2008\MSSQL.SQLEXPRESS\MSSQL\LOG\tngmgr_Log.LDF'  ,
   SIZE       = 10MB      , 
   MAXSIZE    = UNLIMITED , 
   FILEGROWTH = 10MB   
  ) 


  CREATE DATABASE dbName
ON (
  NAME = dbName_dat,
  FILENAME = 'D:\path\to\dbName.mdf'
)
LOG ON (
  NAME = dbName_log,
  FILENAME = 'D:\path\to\dbName.ldf'
)

