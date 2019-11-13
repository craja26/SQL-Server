/*Add-Update SQL Agent notifications for all jobs.*/
SET NOCOUNT ON
CREATE TABLE #temp_jobs(slno INT IDENTITY(1,1), job_id UNIQUEIDENTIFIER, job_name VARCHAR(300))
DECLARE @j_count INT, @i INT, @j_id UNIQUEIDENTIFIER, @j_name VARCHAR(300),@sql NVARCHAR(2000)

INSERT INTO #temp_jobs(job_id, job_name)
SELECT job_id, name FROM msdb.dbo.sysjobs WHERE ENABLED = 1 ORDER BY name
SET @j_count= @@ROWCOUNT
SET @i = 1
WHILE (@i <= @j_count)
BEGIN
	--SET @sql = '''USE [msdb]
	--			GO
	--			EXEC msdb.dbo.sp_update_job @job_id
	--			@notify_level_eventlog=2,'
	SELECT @j_id= job_id, @j_name = job_name FROM #temp_jobs WHERE slno = @i
	SET @sql = '/*Changin operator for job '''+@j_name+'''*/
				USE [msdb]
				GO
				EXEC msdb.dbo.sp_update_job @job_id='''+CONVERT(VARCHAR(36), @j_id)+''', 
						@notify_level_eventlog=2, 
						@notify_level_email=2, 
						@notify_level_netsend=2, 
						@notify_level_page=2, 
						@notify_email_operator_name=N''DBA Team''
				GO'
	
	PRINT @sql
	--EXEC(@sql)
	--PRINT @i
	SET @i =@i + 1
END

--SELECT @j_count as 'job_count'

--SELECT * FROM #temp_jobs
DROP TABLE #temp_jobs
