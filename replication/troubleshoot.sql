#1 checking consistance errors in replication

Use Distribution
go

select * from dbo.MSrepl_errors
where error_code in ('2601','2627','25098') 

#2 browse undistributed commands
USE distribution;
EXEC sp_browsereplcmds '0x00002D34003F4164005100000000', '0x00002D34003F4164005100000000'
GO

