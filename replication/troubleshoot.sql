#1 checking consistance errors in replication

Use Distribution
go

select * from dbo.MSrepl_errors
where error_code in ('2601','2627','25098') 
