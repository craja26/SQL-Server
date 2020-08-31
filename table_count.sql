/*Get all tables count*/
USE <database_name>
GO
DECLARE @i int, @cnt_tbl int, @tbl_name varchar(100), @cmd nvarchar(2000)
CREATE TABLE #temp_tbl_count(slno int identity(1,1), tbl_name varchar(100), row_count varchar(100), total_size varchar(100), actual_data_size varchar(100)
, index_size varchar(100), unused_size varchar(100))

CREATE TABLE #temp_table(slno int identity(1,1), tbl_name varchar(100))
INSERT INTO #temp_table(tbl_name)
select sc.name+'.'+tb.name AS tbl_name from sys.tables tb left join sys.schemas sc on tb.schema_id = sc.schema_id where sc.name = '<schema name>' order by tb.name
SET @cnt_tbl = @@ROWCOUNT
SET @i = 1
WHILE(@i <= @cnt_tbl)
BEGIN
	SELECT @tbl_name = tbl_name FROM #temp_table WHERE slno = @i
	SET @cmd = 'EXEC SP_SPACEUSED ''' + @tbl_name + ''''
	INSERT INTO #temp_tbl_count(tbl_name, row_count, total_size, actual_data_size, index_size, unused_size)
	EXEC (@cmd)
	SET @i = @i + 1
END
SELECT * FROM #temp_table
SELECT * FROM #temp_tbl_count
DROP TABLE #temp_table
DROP TABLE #temp_tbl_count
