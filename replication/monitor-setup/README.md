We have configured transactional replication in multiple SQL Server instance in our environment. It is difficult us to monitor all replication servers. I thought to write scripts and automate monitoring alerts if replication is experiencing a problem. It should notify DBAs if latency is more than 30 minutes, undistributed commands are more than 80k and if any distribution agent job execution status other than "executing". You can change parameters according your requirements.

These scripts should work any transactional replication environment. Tested on different scenarios (such as one publisher, one distributor and one subscriber servers(1:1:1) and multiple publishers, one distributor server(different distribution DBs), multiple subscribers(N:1:N) ).

Here, I am fetching data, Storing replication status and distribution agents status into two tables. Verifying our monitoring conditions and agents running status. If it any monitoring condition is fails, it will notify DBAs by sending an email. For this process, I created two tables to store log replication status and agent job information then created stored procedure to fetch data from replication, apply monitoring condition on it then send an email notification.

Note: There is some syntactical differences in t-sql SQL Server 2008R2 and 2016 versions. So, created two stored procedures. One for SQL Server 2008R2 and other for later versions.

