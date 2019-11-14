/*Here is the sample script to configure a job for SQL mirroring environment.*/

DECLARE @db_count int, @i int, @db_name varchar(100), @sql nvarchar(2000)
CREATE TABLE #temp_db(slno int identity(1,1), db_name varchar(100), db_id int, mirroring_role int)

INSERT INTO #temp_db(db_name, db_id, mirroring_role)
select db.name, dm.mirroring_role, db.database_id from sys.databases db inner join sys.database_mirroring dm on db.database_id = dm.database_id
where db.database_id > 4 and (dm.mirroring_role <> 2 OR dm.mirroring_role is null)
SET @db_count = @@ROWCOUNT
SET @i = 1
WHILE (@i <= @db_count)
BEGIN
	SELECT @db_name = db_name FROM #temp_db WHERE slno = @i
	SET @sql = 'EXECUTE [SQLLogging].[dbo].[DatabaseBackup]
		@Databases = '''+@db_name+''',
		@Directory = ''C:\SQLBackup'',
		@BackupType = ''FULL'',
		@Verify = ''Y'',
		@Compress = ''Y'',
		@CleanupTime = 168,
		@CheckSum = ''Y'',
		@LogToTable = ''Y'''
	--PRINT(@sql)
	EXEC (@sql)
	SET @i = @i +1
END


--select @db_count
--select * from  #temp_db
DROP TABLE #temp_db
