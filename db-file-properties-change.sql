-- View auto growth of databas and generate script to change auto growth.

DECLARE @dbName varchar(100)
SET @dbName = '<db_name>'
-- Getting details of a database current 
SELECT
S.[name] AS [Logical Name]
,S.[file_id] AS [File ID]
, S.[physical_name] AS [File Name]
,CAST(CAST(G.name AS VARBINARY(256)) AS sysname) AS [FileGroup_Name]
,CONVERT (varchar(20),(convert(decimal(8,2),(S.[size]*8.0)/1024.0))) + ' MB' AS [Size]
,CASE WHEN S.[max_size]=-1 THEN 'Unlimited' ELSE CONVERT(VARCHAR(10),CONVERT(bigint,S.[max_size])*8) +' KB' END AS [Max Size]
,CASE s.is_percent_growth WHEN 1 THEN CONVERT(VARCHAR(10),S.growth) +'%' ELSE Convert(VARCHAR(10),(convert(decimal(8,2),(S.growth*8)/1024.0))) +' MB' END AS [Growth]
,Case WHEN S.[type]=0 THEN 'Data Only'
WHEN S.[type]=1 THEN 'Log Only'
WHEN S.[type]=2 THEN 'FILESTREAM Only'
WHEN S.[type]=3 THEN 'Informational purposes Only'
WHEN S.[type]=4 THEN 'Full-text '
END AS [usage]
,DB_name(S.database_id) AS [Database Name]
FROM sys.master_files AS S
LEFT JOIN sys.filegroups AS G ON ((S.type = 2 OR S.type = 0)
AND (S.drop_lsn IS NULL)) AND (S.data_space_id=G.data_space_id)
where s.database_id = DB_ID(@dbName)


CREATE TABLE #temp_db_info(slno int identity(1,1), DBName varchar(100), db_size varchar(50), db_owner varchar(100), id_db int, db_create_date date
, db_status varchar(2000), db_compatibility_level int)
CREATE TABLE #temp_db_files(slno int identity(1,1), logicalName varchar(100), file_type varchar(20), file_size int, file_max_size int, growth int )

DECLARE @change_option varchar(10) = 'yes'  -- If you don't want to genereate script, chage value to 'NO'
DECLARE @intital_size varchar(10) ='256MB'
DECLARE @growth varchar(20) = '256MB'
DECLARE @fileCount int
DECLARE @str varchar(2000)



INSERT INTO #temp_db_info(DBName , db_size , db_owner , id_db , db_create_date , db_status , db_compatibility_level )
exec sp_helpdb 

INSERT INTO #temp_db_files(logicalName , file_type , file_size , file_max_size , growth)
select name, type_desc, size, max_size, growth from sys.master_files where database_id = DB_ID(@dbName)
select @fileCount = @@ROWCOUNT

select * from #temp_db_info where DBName = @dbName
IF @change_option = 'YES'
BEGIN
		while @fileCount >=1
		BEGIN
			select @str = 'ALTER DATABASE '+@dbName+' MODIFY FILE ( NAME = N'''+logicalName+''' , MAXSIZE = UNLIMITED, FILEGROWTH = '+@growth+' )' from #temp_db_files where slno = @fileCount
			print(@str)
			set @fileCount = @fileCount - 1			
		END
END
DROP TABLE #temp_db_info
DROP TABLE #temp_db_files


