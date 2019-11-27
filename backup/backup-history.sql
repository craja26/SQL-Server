-- Get last FULL, DIFF and LOG backup history for all databases.

CREATE table #temp_report( slno int identity(1,1),instance_name varchar(100), database_id int, database_name varchar(100), recovery_model varchar(50), state_desc varchar(50), last_full_backup datetime
, last_differential_backup datetime, last_log_backup datetime)

INSERT INTO #temp_report(instance_name, database_id, database_name, recovery_model, state_desc, last_full_backup, last_differential_backup, last_log_backup)
SELECT  @@SERVERNAME,database_id, name ,
            recovery_model_desc ,
            state_desc ,
            d AS 'Last Full Backup' ,
            i AS 'Last Differential Backup' ,
            l AS 'Last log Backup'
    FROM    ( SELECT    db.database_id ,db.name ,
                        db.state_desc ,
                        db.recovery_model_desc ,
                        type ,
                        backup_finish_date
              FROM      master.sys.databases db
                        LEFT OUTER JOIN msdb.dbo.backupset a ON a.database_name = db.name 
						where database_id > 4 and db.is_distributor <> 1 and db.name NOT LIKE 'x2auc%_repl' 
						AND db.name NOT LIKE 'x2world%_repl' AND db.name NOT LIKE 'PS_UserLog_2019%' AND db.name NOT LIKE 'PS_ChatLog_2019%'  AND db.name NOT LIKE 'PS_GameData_2019%'
						AND db.name NOT LIKE 'PS_GameLog_2019%' AND db.name NOT LIKE 'bak_w%_Character' AND db.name NOT IN('maint','x2universe_repl','WATCHMAN','xl_dba','ReportServerTempDB','ReportServer','AG_Test','DBATools')
            ) AS Sourcetable 
        PIVOT 
            ( MAX(backup_finish_date) FOR type IN ( D, I, L ) ) AS MostRecentBackup

--Declare variables for email
	DECLARE @Body NVARCHAR(MAX),
		@TableHead VARCHAR(1000),
		@TableTail VARCHAR(1000),
		@Body2 NVARCHAR(MAX),
		@TableHead2 VARCHAR(1000),
		@TableTail2 VARCHAR(1000),
		@subject varchar(200)

	SET @TableTail = '</table></body></html>' ;
	SET @TableHead = '<html><head>'+'</head><body><h3>Latest Backup History</h3><table border="1"><tr><th>Database Name</th><th>Recovery Model</th><th>State Desc</th><th>Last Full Backup</th><th>Last Diff Backup</th><th>Last Log Backup</th></tr>'

SET @Body = (SELECT td = database_name,''
, td = recovery_model,''
, td = state_desc, ''
, td = last_full_backup, ''
, td = last_differential_backup, ''
, td = last_log_backup, ''
FROM #temp_report order by database_name FOR XML RAW('tr'), ELEMENTS)

/*
IF EXISTS( select * from #temp_report where last_full_backup < GETDATE()-7 OR last_differential_backup < dateadd(hour,-24,getdate()) OR last_log_backup < dateadd(hour,-4,getdate()) 
OR recovery_model <> 'FULL' and database_id > 5 and database_name <> 'maint')
BEGIN
	--select 1
	SET @TableHead2 = '</table><h3><span style="color:red;">Review below databases</span></h3><table border="1"><tr><th>Database Name</th><th>Recovery Model</th><th>State Desc</th><th>Last Full Backup</th><th>Last Diff Backup</th><th>Last Log Backup</th></tr>'
	SET @Body2 = (SELECT td = database_name,''
	, td = recovery_model,''
	, td = state_desc, ''
	, td = last_full_backup, ''
	, td = last_differential_backup, ''
	, td = last_log_backup, ''
	FROM #temp_report where last_full_backup < GETDATE()-7 OR last_differential_backup < dateadd(hour,-24,getdate()) OR last_log_backup < dateadd(hour,-4,getdate()) 
OR recovery_model <> 'FULL' and database_id > 5 and database_name <> 'maint' FOR XML RAW('tr'), ELEMENTS)
	SET @Body = @Body +@TableHead2 + @Body2
END
SELECT @Body = @TableHead + ISNULL(@Body, '') + @TableTail
SET @subject = 'Daily backup report '+ @@SERVERNAME
EXEC msdb.dbo.sp_send_dbmail 
	  @profile_name='DBA Alert',
	  @recipients='raja.chikkala@domain.com',
	  @subject= @subject,
	  @body=@Body ,
	  @body_format = 'HTML' ;
--select * from #temp_report where last_differential_backup < dateadd(hour,-24,getdate())
*/
SELECT * FROM #temp_report
DROP TABLE #temp_report
