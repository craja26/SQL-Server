# Track create index query progress.
/*  Add below statement before "CREATE INDEX.." statement */
SET STATISTICS PROFILE ON
    
#  Run the following statement in new query window to track the create index progress
    SELECT session_id, request_id, physical_operator_name, node_id, 
           thread_id, row_count, estimate_row_count
    FROM sys.dm_exec_query_profiles
    where session_id =[]
    ORDER BY node_id DESC, thread_id
