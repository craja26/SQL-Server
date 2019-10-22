/*#1. Run jobs/scripts on primary server

Create a auser defined function in master database to get whether current server is primary or not.
*/
-- fn_hadr_group_is_primary
USE master;
GO
IF OBJECT_ID('dbo.fn_hadr_group_is_primary', 'FN') IS NOT NULL
  DROP FUNCTION dbo.fn_hadr_group_is_primary;
GO
CREATE FUNCTION dbo.fn_hadr_group_is_primary (@AGName sysname)
RETURNS bit
AS
BEGIN;
  DECLARE @PrimaryReplica sysname; 

  SELECT
    @PrimaryReplica = hags.primary_replica
  FROM sys.dm_hadr_availability_group_states hags
  INNER JOIN sys.availability_groups ag ON ag.group_id = hags.group_id
  WHERE ag.name = @AGName;

  IF UPPER(@PrimaryReplica) =  UPPER(@@SERVERNAME)
    RETURN 1; -- primary

    RETURN 0; -- not primary
END; 

-- Example code to use this function.

DECLARE @rc int; 
EXEC @rc = master.dbo.fn_hadr_group_is_primary N'AG-Name';

IF @rc = 1
BEGIN
    PRINT 'This is primary. Write primary server code here.';
END
ELSE
BEGIN
	PRINT 'This is secondary. Write secondary server code here.';
END
