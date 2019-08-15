Scripts for database backup
===========================
#1. Full backup:
USE SQLTestDB;  
GO  
BACKUP DATABASE SQLTestDB  
TO DISK = 'Z:\SQLServerBackups\SQLTestDB.Bak'  
   WITH FORMAT,  
      MEDIANAME = 'Z_SQLServerBackups',  
      NAME = 'Full Backup of SQLTestDB';  
GO 

#2. Differential backup:
BACKUP DATABASE AdventureWorks TO DISK = 'Z:\SQLServerBackups\SQLTestDB_DIFF_1.Bak' WITH DIFFERENTIAL
GO

