-- I want to store replication current status and distribution agent status history into two tables. 
-- I am using SQLLogging database for database activities in my environment.
USE [SQLLogging]
GO

/****** Object:  Table [dbo].[repl_job_status_history]    Script Date: 11/22/2019 3:18:51 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[repl_job_status_history](
	[slno] [int] IDENTITY(1,1) NOT NULL,
	[job_name] [varchar](200) NULL,
	[originiating_server] [sysname] NOT NULL,
	[enabled] [int] NULL,
	[category] [varchar](100) NULL,
	[current_execution_status] [varchar](100) NULL,
	[current_execution_step] [varchar](100) NULL,
	[log_date] [datetime] NULL,
 CONSTRAINT [pk_repl_job_status_history_slno] PRIMARY KEY CLUSTERED 
(
	[slno] DESC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 75) ON [PRIMARY]
) ON [PRIMARY]
GO

ALTER TABLE [dbo].[repl_job_status_history] ADD  DEFAULT (getdate()) FOR [log_date]
GO

USE [SQLLogging]
GO

/****** Object:  Table [dbo].[Replication_Qu_History]    Script Date: 11/22/2019 3:19:19 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[Replication_Qu_History](
	[slno] [int] IDENTITY(1,1) NOT NULL,
	[subscriber_db] [varchar](50) NOT NULL,
	[latency] [int] NULL,
	[records_in_que] [numeric](18, 0) NULL,
	[catch_up_time] [numeric](18, 0) NULL,
	[log_date] [datetime] NOT NULL,
	[publisher] [varchar](100) NULL,
	[publication] [varchar](200) NULL,
	[publisher_db] [varchar](100) NULL,
	[distribution_db] [varchar](100) NULL,
 CONSTRAINT [pk_replication_qu_history_slno] PRIMARY KEY CLUSTERED 
(
	[slno] DESC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80) ON [PRIMARY]
) ON [PRIMARY]
GO

