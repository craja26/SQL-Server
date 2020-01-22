/* Filter error log */
USE master
GO
xp_readerrorlog 0, 1, N'Logging SQL Server messages', N'', null,null, 'asc'
GO

