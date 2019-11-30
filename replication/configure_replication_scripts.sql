
-------*** Add new article then generate snapshot for newly added article but not all articles ***-------------

1. Generate Snapshot only for newly updated articles.
  Run the below commands before adding article in the existing publication. This command will disables publication properties 
"allow_anonymous" and "immediate_sync".
SQL Script:
  exec sp_changepublication
          @publication=N'Publication_Name'
        , @property=N'allow_anonymous'
        , @value='false';
  go
  exec sp_changepublication
          @publication=N'Publication_Name'
        , @property=N'immediate_sync'
        , @value='false';
  go
Once you ran these command, add new articles then start Snapshot Agent. It should only takes Snapshot for newly added articles.

  
---------*************--------------
## Creating transactional replication using scripts.

1. Enabling the replication database
use master
exec sp_replicationdboption @dbname = N'<db_name>', @optname = N'publish', @value = N'true'
GO

exec [<db_name>].sys.sp_addlogreader_agent @job_login = null, @job_password = null, @publisher_security_mode = 1
GO
2. Adding the transactional publication  
	* Here I am adding post snapshot script, set allow_anonymous and immediate_sync to "false"
use [<DB_Name>]
exec sp_addpublication @publication = N'<db_name>_pub', @description = N'Transactional publication of database ''<db_name>_repl'' from Publisher ''<Server_name>''.', @sync_method = N'concurrent', @retention = 0
	, @allow_push = N'true', @allow_pull = N'true', @allow_anonymous = N'false', @enabled_for_internet = N'false', @snapshot_in_defaultfolder = N'true'
	, @post_snapshot_script = N'E:\MSSQL\Repl_snap\<db_name>_repl-<db_name>_pub.sql', @compress_snapshot = N'false', @ftp_port = 21, @ftp_login = N'anonymous'
	, @allow_subscription_copy = N'false', @add_to_active_directory = N'false', @repl_freq = N'continuous', @status = N'active', @independent_agent = N'true'
	, @immediate_sync = N'false', @allow_sync_tran = N'false', @autogen_sync_procs = N'false', @allow_queued_tran = N'false', @allow_dts = N'false', @replicate_ddl = 1
	, @allow_initialize_from_backup = N'false', @enabled_for_p2p = N'false', @enabled_for_het_sub = N'false'
GO

3. Create snapshot agent for publication.
exec sp_addpublication_snapshot @publication = N'<db_name>_pub', @frequency_type = 4, @frequency_interval = 1, @frequency_relative_interval = 1, @frequency_recurrence_factor = 0, @frequency_subday = 8
	, @frequency_subday_interval = 1, @active_start_time_of_day = 0, @active_end_time_of_day = 235959, @active_start_date = 0, @active_end_date = 0, @job_login = null, @job_password = null, @publisher_security_mode = 1
exec sp_grant_publication_access @publication = N'<db_name>_pub', @login = N'sa'
GO

4. Adds a login to the access list of the publication.

exec sp_grant_publication_access @publication = N'<db_name>_pub', @login = N'<Domain>\<service_accounts>'
GO
exec sp_grant_publication_access @publication = N'<db_name>_pub', @login = N'distributor_admin'
GO
exec sp_grant_publication_access @publication = N'<db_name>_pub', @login = N'Domain\user_name'
GO

5. Adding the transactional articles
* Here I am changing destination table, schema, and stored procedure names for insert, delete, and delete commands 
use [<db_name>]
exec sp_addarticle @publication = N'<db_name>_pub', @article = N'<table_name>', @source_owner = N'dbo', @source_object = N'<table_name>', @type = N'logbased', @description = N'', @creation_script = N''
, @pre_creation_cmd = N'drop', @schema_option = 0x0000000008000007, @identityrangemanagementoption = N'manual', @destination_table = N'<dest_table_name>', @destination_owner = N'<dest_schema>', @status = 16
, @vertical_partition = N'false', @ins_cmd = N'CALL [sp_MSins_<dbo_dest_table_name>]', @del_cmd = N'CALL [sp_MSdel_<dbo_dest_table_name>]'
, @upd_cmd = N'SCALL [sp_MSupd_ucus_<dbo_dest_table_name>]'
GO

6. Adding the transactional subscriptions
* Here need to specify subscriber database name, login name
use [<db_name>]
exec sp_addsubscription @publication = N'<db_name>_pub', @subscriber = N'<dest_server_name>', @destination_db = N'<dest_db_name>', @subscription_type = N'Push', @sync_type = N'automatic', @article = N'all'
, @update_mode = N'read only', @subscriber_type = 0
exec sp_addpushsubscription_agent @publication = N'<db_name>_pub', @subscriber = N'<dest_server_name>', @subscriber_db = N'<dest_db_name>', @job_login = null, @job_password = null, @subscriber_security_mode = 0
, @subscriber_login = N'<dest_server_login>', @subscriber_password = '<password- enter later>', @frequency_type = 64, @frequency_interval = 1, @frequency_relative_interval = 1, @frequency_recurrence_factor = 0
, @frequency_subday = 4, @frequency_subday_interval = 5, @active_start_time_of_day = 0, @active_end_time_of_day = 235959, @active_start_date = 0, @active_end_date = 0, @dts_package_location = N'Distributor'
GO

