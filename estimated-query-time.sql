-- Estimated time for shrink file, backup and restore process:
-- #1:
SELECT SERVERPROPERTY('ServerName') AS [Instance],
   reqs.session_id,
   sess.login_name,
   reqs.command,
   CAST(reqs.percent_complete AS NUMERIC(10, 2)) AS [Percent Complete],
   CONVERT(VARCHAR(20), DATEADD(ms, reqs.estimated_completion_time, GETDATE()), 20) AS [Estimated Completion Time],
   CAST(reqs.total_elapsed_time / 60000.0 AS NUMERIC(10, 2)) AS [Elapsed Minutes],
   CAST(reqs.estimated_completion_time / 60000.0 AS NUMERIC(10, 2)) AS [Estimated Remaining Time in Minutes],
   CAST(reqs.estimated_completion_time / 3600000.0 AS NUMERIC(10, 2)) AS [Estimated Remaining Time in Hours],
   CAST((
     SELECT SUBSTRING(text, reqs.statement_start_offset/2,
                CASE
                WHEN reqs.statement_end_offset = -1
                THEN 1000
                ELSE(reqs.statement_end_offset-reqs.statement_start_offset)/2
                END)
     FROM sys.dm_exec_sql_text(sql_handle)) AS VARCHAR(1000)) AS [SQL]
FROM sys.dm_exec_requests AS reqs
 JOIN sys.dm_exec_sessions AS sess ON sess.session_id = reqs.session_id
WHERE command IN('RESTORE DATABASE', 'BACKUP DATABASE','RESTORE HEADERONLY','BACKUP LOG', 'DbccFilesCompact','DbccSpaceReclaim');

