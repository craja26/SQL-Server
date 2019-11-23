/*
-- This monitoring script works on SQL Server 2008R2 and lower versions.
*/
USE [SQLLogging]
GO

/****** Object:  StoredProcedure [dbo].[usp_replication_monitor]    Script Date: 11/22/2019 23:15:47 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Raja Kumar Chikkala
-- Create date: 19.11.2019
-- Description:	Job stores replication undistributed commands, latency in a table then send an email alert if any one of these are crossed threshold value
-- =============================================
CREATE PROCEDURE [dbo].[usp_replication_monitor] 
@email CHAR(1) = 'Y',
@schedule_in_minutes INT = 10,  -- SQL Agent scheduled information. 
@maxCommands int = 50000,			-- change this to represent the max number of outstanding commands to be proceduresed before notification
@latency_minutes int = 30,    -- latency
@to VARCHAR(100) = 'raja.chikkala@domain.com' -- Add DBA group email id here.
AS
BEGIN
	SET NOCOUNT ON;

    DECLARE @db_count int, @db_i int, @db_name varchar(100), @pub_i int, @pub_count int
	DECLARE @cmd NVARCHAR(max)
	DECLARE @publisher SYSNAME, @publisher_db SYSNAME, @publication SYSNAME, @pubtype INT
	DECLARE @subscriber SYSNAME, @subscriber_db SYSNAME, @subtype INT
	DECLARE @cmdcount INT, @processtime INT
	DECLARE @ParmDefinition NVARCHAR(500)
	DECLARE @JobName SYSNAME
	DECLARE @threshold INT
	DECLARE @latency INT
	DECLARE @slno int  --> Update the ##SubscriptionInfo table using this slno in the cursor.
	--SET @minutes = 60 --> Define how many minutes latency before you would like to be notified
	--SET @maxCommands = 80000  --->  change this to represent the max number of outstanding commands to be proceduresed before notification
	--SET @maxCommands = 1000  
	--SET @threshold = @minutes * 60
	SET @threshold = @latency_minutes * 60


	IF OBJECT_ID('Tempdb.dbo.#temp_db') IS NOT NULL  
		DROP TABLE #temp_db
	IF OBJECT_ID('Tempdb.dbo.#PublisherInfo') IS NOT NULL  
		DROP TABLE #PublisherInfo
	IF OBJECT_ID('Tempdb.dbo.##PublicationInfo') IS NOT NULL  
		DROP TABLE ##PublicationInfo
	IF OBJECT_ID('Tempdb.dbo.##SubscriptionInfo') IS NOT NULL  
		DROP TABLE ##SubscriptionInfo
	IF OBJECT_ID('Tempdb.dbo.##jobinfo') IS NOT NULL  
		DROP TABLE ##jobinfo

	CREATE TABLE #temp_db(slno int identity(1,1), database_id int, database_name varchar(100))
	CREATE TABLE #PublisherInfo(slno int identity(1,1), publisher varchar(100), distribution_db varchar(100), status int, warning int, publication_count int, return_stamp bigint)

	CREATE TABLE ##PublicationInfo(slno int identity(1,1), publisher_db sysname, publication sysname, publication_id int, publication_type int, status int, warning int
		, worst_latency int, best_latency int, average_latency int, last_distsync datetime, retention int, latencythreshold int, expirationthreshold int, agentnotrunningthreshold int
		, subscriptioncount int, runningdistagentcount int, snapshot_agentname sysname, logreader_agentname sysname, qreader_agentname sysname NULL, worst_runspeedPerf int
		, best_runspeedPerf int, average_runspeedPerf int, retention_period_unit int, publisher sysname null)

	CREATE TABLE ##SubscriptionInfo(slno int identity(1,1), distribution_db varchar(100), status int, warning int, subscriber sysname, subscriber_db sysname, publisher_db sysname, publication sysname
		, publication_type int, subtype int, latency int, latencythreshold int, agentnotrunning int, agentnotrunningthreshold int, timetoexpiration int, expirationthreshold int
		, last_distsync datetime, distribution_agentname sysname, mergeagentname sysname null, mergesubscriptionfriendlyname sysname NULL, mergeagentlocation sysname NULL
		, mergeconnectiontype int, mergePerformance int, mergerunspeed float, mergerunduration int, monitorranking int, distributionagentjobid binary(16), mergeagentjobid binary(16)
		, distributionagentid int, distributionagentprofileid int, mergeagentid int, mergeagentprofileid int, logreaderagentname sysname NULL, publisher sysname null, PendingCmdCount INT NULL
		, EstimatedProcessTime INT NULL)
	CREATE TABLE ##jobinfo(slno int identity(1,1),job_id uniqueidentifier, originating_server nvarchar(30), name sysname, enabled tinyint, description nvarchar(512), start_step_id int
		, category sysname NULL, owner sysname, notify_level_eventlog int, notify_level_email int, notify_level_netsend int, notify_level_page int, notify_email_operator sysname NULL
		, notify_netsend_operator sysname NULL, notify_page_operator sysname NULL, delete_level int, date_created datetime, date_modified datetime, version_number int
		, last_run_date int null, last_run_time int null, last_run_outcome int, next_run_date int null, next_run_time int null, next_run_schedule_id int null, current_execution_status int
		, current_execution_step sysname null, current_retry_attempt int null, has_step int null, has_schedule int null, has_target int null, type int)


	INSERT INTO #temp_db(database_id, database_name)
	SELECT database_id, name from sys.databases where is_distributor = 1
	SET @db_count = @@ROWCOUNT
	SET @db_i = 1
	
	SET @cmd = 'SELECT * FROM OPENQUERY(localserver, 
				  ''SET FMTONLY OFF;EXEC dbo.sp_replmonitorhelppublisher'')'
	INSERT INTO #PublisherInfo(publisher, distribution_db, status, warning, publication_count, return_stamp)
	EXEC (@cmd)
	SELECT @pub_count = @@ROWCOUNT
	SET @pub_i = 1
	WHILE(@pub_i <= @pub_count)
	BEGIN
		--SET @db_name = (SELECT database_name FROM #temp_db WHERE slno = @db_i)
		SELECT @publisher = publisher, @db_name = distribution_db FROM #PublisherInfo WHERE slno = @pub_i   
			
		SET @cmd = 'INSERT INTO ##PublicationInfo (publisher_db, publication, publication_id, publication_type, status, warning, worst_latency, best_latency, average_latency
			, last_distsync, retention, latencythreshold, expirationthreshold, agentnotrunningthreshold, subscriptioncount, runningdistagentcount, snapshot_agentname
			, logreader_agentname, qreader_agentname, worst_runspeedPerf, best_runspeedPerf, average_runspeedPerf, retention_period_unit, publisher)
			SELECT *,'''+ @publisher +''' FROM OPENQUERY(localserver, 
					  ''SET FMTONLY OFF;EXEC '+ @db_name +'.dbo.sp_replmonitorhelppublication @publisher= ['+ @publisher +']'')'

		EXEC sp_executesql @cmd
		
		SELECT  @pubtype=publication_type  FROM ##PublicationInfo WHERE publisher = @publisher
		
		SET @cmd = 'INSERT INTO ##SubscriptionInfo(distribution_db, status, warning, subscriber, subscriber_db, publisher_db, publication, publication_type, subtype, latency, latencythreshold
			, agentnotrunning, agentnotrunningthreshold, timetoexpiration, expirationthreshold, last_distsync, distribution_agentname, mergeagentname, mergesubscriptionfriendlyname
			, mergeagentlocation, mergeconnectiontype, mergePerformance, mergerunspeed, mergerunduration, monitorranking, distributionagentjobid, mergeagentjobid, distributionagentid
			, distributionagentprofileid, mergeagentid, mergeagentprofileid, logreaderagentname, publisher)
			SELECT '''+ @db_name +''' ,*,'''+ @publisher +''' FROM OPENQUERY(localserver, 
					  ''SET FMTONLY OFF;EXEC '+ @db_name +'.dbo.sp_replmonitorhelpsubscription @publisher= ['+ @publisher +'],@publication_type=[' + CONVERT(CHAR(1),@pubtype) +']'')'
	--	PRINT(@cmd)
			
		EXEC sp_executesql @cmd		
		
		DECLARE cur_sub CURSOR READ_ONLY FOR 
			SELECT slno,@publisher, s.publisher_db, s.publication, s.subscriber, s.subscriber_db, s.subtype, s.distribution_agentname, s.publication_type, latency
			FROM ##SubscriptionInfo s WHERE s.distribution_db = @db_name and s.publisher = @publisher
		 
			OPEN cur_sub   
			FETCH NEXT FROM cur_sub INTO @slno ,@publisher, @publisher_db, @publication, @subscriber, @subscriber_db, @subtype, @JobName, @pubtype, @latency
		 
			WHILE @@FETCH_STATUS = 0   
			BEGIN   
					SET @cmd = 'SELECT  @cmdcount=pendingcmdcount, @processtime=estimatedprocesstime FROM OPENQUERY(localserver, 
					  ''SET FMTONLY OFF;EXEC '+ @db_name +'.dbo.sp_replmonitorsubscriptionpendingcmds @publisher=[' + @publisher
				   + '],@publisher_db=[' + @publisher_db + '],@publication=[' + @publication
				   + '],@subscriber=[' + @subscriber + '],@subscriber_db=[' + @subscriber_db
				   + '],@subscription_type=[' + CONVERT(CHAR(1),@subtype) + ']'')'

				   SET @ParmDefinition = N'@cmdcount INT OUTPUT,
									@processtime INT OUTPUT'
				   EXEC sp_executesql @cmd,@ParmDefinition,@cmdcount OUTPUT, @processtime OUTPUT
		  
				   UPDATE ##SubscriptionInfo
				   SET PendingCmdCount = @cmdcount
					, EstimatedProcessTime = @processtime
				   WHERE subscriber_db = @subscriber_db AND slno = @slno
		 
				INSERT INTO SQLLogging.dbo.Replication_Qu_History(subscriber_db, latency, records_in_que, catch_up_time, log_date, publisher, publication, publisher_db, distribution_db)
				VALUES(@subscriber_db, @latency, @cmdcount, @processtime, GETDATE(), @publisher, @publication, @publisher_db, @db_name)

				--Fetching job status
				SET @cmd = 'INSERT INTO ##jobinfo(job_id, originating_server, name, enabled, description, start_step_id, category, owner, notify_level_eventlog, notify_level_email, notify_level_netsend, notify_level_page, notify_email_operator, notify_netsend_operator, notify_page_operator, delete_level, date_created, date_modified, version_number, last_run_date, last_run_time, last_run_outcome, next_run_date, next_run_time, next_run_schedule_id, current_execution_status, current_execution_step, current_retry_attempt, has_step, has_schedule, has_target, type)
							SELECT * FROM OPENQUERY(localserver, 
							''SET FMTONLY OFF;EXEC msdb.dbo.sp_help_job @job_name = ['+@JobName+'], @job_aspect = ''''job''''
							'')'
				EXEC (@cmd)
	--			PRINT(@cmd)
				--PRINT(@jobName)
			   FETCH NEXT FROM cur_sub INTO @slno, @publisher, @publisher_db, @publication, @subscriber, @subscriber_db, @subtype, @JobName , @pubtype, @latency

			END   
		CLOSE cur_sub
		DEALLOCATE cur_sub
		
		SET @pub_i = @pub_i + 1
	END
	DECLARE @msg VARCHAR(MAX) = '<html><body><p style="color:red;">Replication on ' + @@SERVERNAME 
		   + ' may be experiencing some problems.</p>'
		   + 'If this is not the first message like this that you have received within the thirty minutes, please investigate.'
	DECLARE @body NVARCHAR(MAX)
	DECLARE @xml1 NVARCHAR(MAX)
	DECLARE @tab1 NVARCHAR(MAX)
	DECLARE @xml2 NVARCHAR(MAX) 
	DECLARE @tab2 NVARCHAR(MAX) 
	DECLARE @xml3 NVARCHAR(MAX) 
	DECLARE @tab3 NVARCHAR(MAX)
	DECLARE @alert_status int
	SET @xml1 = ''
	SET @tab1 = ''
	SET @xml2 = ''
	SET @tab2 = ''
	SET @xml3 = ''
	SET @tab3 = ''
	SET @alert_status = 0
	IF EXISTS(SELECT current_execution_status FROM ##jobinfo where current_execution_status <> 1)
	BEGIN
		SET @alert_status = 1  --> changing alert status to send an email
		SET @xml3 = CAST((SELECT originating_server AS 'td','', name AS 'td','', 
					CASE WHEN current_execution_status = 0 THEN 'not idle or suspended' 
						WHEN current_execution_status  = 1 THEN 'Executing'
						WHEN current_execution_status  = 2 THEN 'Waiting for thread'
						WHEN current_execution_status = 3 THEN 'Between retries' 
						WHEN current_execution_status = 4 THEN 'Idle' 
						WHEN current_execution_status = 5 THEN 'Suspended' 
						WHEN current_execution_status = 6 THEN 'Performing completion actions' 
					END AS 'td', '', category AS 'td', ''
		FROM ##jobinfo WHERE  current_execution_status <> 1
		FOR XML PATH('tr'), ELEMENTS ) AS NVARCHAR(max))
		--PRINT 'Job is not running'
		SET @tab3 ='<H4 style="color:red;">Below jobs may not running. Please check.</H4>
					<table border = 1> <tr>
					<th> Server </th> <th> Execution Status </th> <th> Category</th></tr>' 
	END
	IF EXISTS(select log_date from [dbo].[Replication_Qu_History] where log_date > DATEADD(MINUTE, -(@schedule_in_minutes - 1),GETDATE()) AND (catch_up_time > @threshold OR records_in_que > @maxCommands)) 
	BEGIN		   
		SET @alert_status = 1 --> changing alert status to send an email
		SET @xml1 = CAST(( SELECT subscriber AS 'td','',subscriber_db AS 'td','',
		latency AS 'td','', PendingCmdCount AS 'td','', EstimatedProcessTime AS 'td'
		FROM  ##SubscriptionInfo s  ORDER BY slno desc
		FOR XML PATH('tr'), ELEMENTS ) AS NVARCHAR(MAX))

		SET @tab1 ='<H4>Subscription Information </H4>
			<table border = 1> <tr>
			<th> Subscriber </th> <th> Subscriber Database </th> <th> Latency(seconds)</th> 
			<th> Undistributed Commands </th> <th> Estimated Catch Up Time</th></tr>'    
	
--  this command gives us the last 30 measurements of latency for each subscriber 
		SET @xml2 = CAST((SELECT subscriber_db AS 'td','', latency as 'td','', records_in_que AS 'td', '', catch_up_time AS 'td', '',CONVERT(CHAR(22),log_date, 100) AS 'td',''
			FROM SQLLogging.dbo.Replication_Qu_History WHERE log_date >= DATEADD(MINUTE, -30,GETDATE())  
			FOR XML PATH('tr'), ELEMENTS ) AS NVARCHAR(max))
		SET @tab2 ='<br><br><H4>Historical Latency Information </H4>
			<table border = 1> 
			<tr>
			<th>Subscriber</th> <th>Latency</th><th>Undistributed Commands</th> <th> Catch Up Time </th> <th> Date\Time </th></tr>' 		   
	END
	IF(@email ='Y' AND @alert_status = 1)
	BEGIN
		SET @body = @msg+ @tab3 + @xml3 + @tab1 + @xml1 + '</table>' + @tab2 + @xml2 + '</body></html>'
	   DECLARE @subject NVARCHAR(200)
		SET @subject ='Possible Replication Problem on '+ @@servername
		EXEC msdb.dbo.sp_send_dbmail
			@profile_name= 'DBA Alert',
			@body = @body,
			@body_format ='HTML',
			@recipients = @to, 
			@subject =  @subject;
	END
	INSERT INTO SQLLogging.dbo.repl_job_status_history(job_name, originiating_server, enabled, category, current_execution_status, current_execution_step, log_date)
	SELECT name, originating_server, enabled, category, CASE WHEN current_execution_status = 0 THEN 'not idle or suspended' 
						WHEN current_execution_status  = 1 THEN 'Executing'
						WHEN current_execution_status  = 2 THEN 'Waiting for thread'
						WHEN current_execution_status = 3 THEN 'Between retries' 
						WHEN current_execution_status = 4 THEN 'Idle' 
						WHEN current_execution_status = 5 THEN 'Suspended' 
						WHEN current_execution_status = 6 THEN 'Performing completion actions' 
					END, current_execution_step, GETDATE() FROM ##jobinfo
	--DELETE history table data which are older than 10 days.
	DELETE FROM SQLLogging.dbo.Replication_Qu_History WHERE log_date < DATEADD(DAY, -10, GETDATE())
	DELETE FROM SQLLogging.dbo.repl_job_status_history WHERE log_date < DATEADD(DAY, -10, GETDATE())
END


GO

