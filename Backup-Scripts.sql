-- Scripts for SQL Server database backup
--===========================
-- #1. Full backup:

USE SQLTestDB;  
GO  
BACKUP DATABASE SQLTestDB  
TO DISK = 'Z:\SQLServerBackups\SQLTestDB.Bak'  
   WITH FORMAT,  
      MEDIANAME = 'Z_SQLServerBackups',  
      NAME = 'Full Backup of SQLTestDB';  
GO 

-- #2. Differential backup:

BACKUP DATABASE AdventureWorks TO DISK = 'Z:\SQLServerBackups\SQLTestDB_DIFF_1.Bak' WITH DIFFERENTIAL, STATS = 5, compression
GO

-- #3. Log backup:
BACKUP LOG AdventureWorks TO DISK = 'C:\AdventureWorks_mmddyyy_hhmm.trn' WITH COMPRESSION, STATS = 5
GO

-- #4. Striped backup: 
-- A stripe set is a set of disk files on which data is divided into blocks and distributed in a fixed order.

BACKUP DATABASE AdventureWorks2012
TO DISK='X:\SQLServerBackups\AdventureWorks1.bak',
DISK='Y:\SQLServerBackups\AdventureWorks2.bak',
DISK='Z:\SQLServerBackups\AdventureWorks3.bak'
WITH FORMAT,
  MEDIANAME = 'AdventureWorksStripedSet0',
  MEDIADESCRIPTION = 'Striped media set for AdventureWorks2012 database;
GO

-- #5. Mirrored backup:

BACKUP DATABASE AdventureWorks
TO DISK = 'C:\Backup\SingleFile\AdventureWorks.bak'
MIRROR TO DISK = 'C:\Backup\MirrorFile\AdventureWorks.bak'
WITH FORMAT
GO

-- #6. 


