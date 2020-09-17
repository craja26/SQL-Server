set nocount on
declare @dbname varchar(1000)
declare @location varchar(4000)
--Put your database here
set @dbname = 'RelMaint'
--Put your dump file location here
set @location = '\\W05P0007\d$\dump\W05D0045_MSSQL_RelMaint_DB_20150804002334.dmp'
declare @dbid int
select @dbid = DB_ID(@dbname)

 

PRINT '/******************************'
PRINT 'RESTORE DEFINATION STARTS HERE'
PRINT '*******************************/'
use master;

 

PRINT ''
print 'Use ' + db_name() 
print 'go'
PRINT ''
PRINT 'alter database '+@dbname+' set single_user with rollback immediate'
print 'go'
PRINT ''
PRINT 'alter database '+@dbname+' set multi_user with rollback immediate'
print 'go'

 

select 
case fileid
when 1 then 'restore database'+'['+db_name(dbid)+']'+' from disk='+''''+@location+''''+'with move '''+rtrim(name)+''' to '''+rtrim(filename)+'''' 
else  ' , move '''+rtrim(name)+''' to '''+rtrim(filename)+''''+','
end 
from master..sysaltfiles 
where dbid = @dbid
print 'stats=5, replace'

 

 

 

print ''
PRINT '/****************************'
PRINT 'PERMISSION SCRIPT STARTS HERE'
PRINT '****************************/'
PRINT ''

 

declare @cmd nvarchar(4000)
set @cmd ='
USE '+@dbname+';

 


SET NOCOUNT ON

 

print ''Use '' + db_name() 
print ''go''

 

--Grant DB Access---
print ''-->[   Grant DB Access   ]<--''

 

select ''if not exists (select * from dbo.sysusers where name = N'''''' + usu.name +'''''' )'' + Char(13) + Char(10) +
''         EXEC sp_grantdbaccess N'''''' + lo.loginname +  '''''''' + '', N'''''' + usu.name +  '''''''' + Char(13) + Char(10) +
''GO'' collate database_default
from sysusers usu , master.dbo.syslogins lo
where usu.sid = lo.sid and (usu.islogin = 1 and usu.isaliased = 0 and usu.hasdbaccess = 1)

 


--Add Roles---

 

print ''-->[    Adding Roles     ]<--''
select ''if not exists (select * from dbo.sysusers where name = N'''''' + name +'''''' )'' + Char(13) + Char(10) +
''         EXEC sp_addrole N'''''' + name +  '''''''' + Char(13) + Char(10) +
''GO''
from sysusers where uid > 0 and uid=gid and issqlrole=1

 

--Add RoleMember---
print ''-->[ Adding Role Members ]<--''
select ''exec sp_addrolemember N'''''' + user_name(groupuid) + '''''', N'''''' + user_name (memberuid) + '''''''' + Char(13) + Char(10) +
''GO''
from sysmembers where  user_name (memberuid) <> ''dbo'' order by groupuid

 


--Add Alias Login also---
print ''-->[   Add Alias  ]<--''
select ''if not exists (select * from dbo.sysusers where name = N'''''' + a.name +'''''' )'' + Char(13) + Char(10) +
''         EXEC sp_addalias N'''''' + substring(a.name , 2, len(a.name)) +  '''''''' + '', N'''''' + b.name +  '''''''' + Char(13) + Char(10) +
''GO''
from sysusers a , sysusers b where a.altuid = b.uid and a.isaliased=1
SET NOCOUNT OFF

 

'

 

exec sp_executesql @cmd

 

PRINT '/******************************'
PRINT 'CHANGE DATABASE STATE TO SIMPLE'
PRINT '******************************/'
PRINT ''
PRINT 'alter database '+@dbname+' set RECOVERY SIMPLE'
print 'go'
pRINT ''

 

PRINT '/******************************'
PRINT 'TO CROSS CHECK DATABASE REFRESH'
PRINT '*******************************/'
PRINT ''

 


PRINT 'Select top 1 restore_date,cast(destination_database_name as varchar(40)),physical_device_name 
from msdb..restorehistory r join msdb..backupset b 
on  r.backup_set_id=b.backup_set_id 
join msdb..backupmediafamily bf 
on bf.media_set_id=b.media_set_id 
where destination_database_name = '+''''+@dbname+''''+char(10)+
'order by restore_date desc 
'

 

PRINT ''
PRINT '/************'
PRINT 'ORPHANS FIX'
PRINT '*************/'

 

PRINT ''

 

PRINT 'SET NOCOUNT ON'
PRINT 'print ''USE ''+ db_name()'
PRINT 'print ''GO '''
PRINT 'select ''EXEC sp_change_users_login ''''update_one'''','''''' + name + '''''','''''' + name + '''''''' +char(13)  '
PRINT 'from sysusers '
PRINT 'where sid NOT IN '
PRINT '        (select sid from master..syslogins ) '
PRINT '        AND '
PRINT '        islogin = 1 '
PRINT '        AND '
PRINT '        name NOT LIKE ''guest'''
PRINT 'SET NOCOUNT OFF '

 


SET NOCOUNT OFF
