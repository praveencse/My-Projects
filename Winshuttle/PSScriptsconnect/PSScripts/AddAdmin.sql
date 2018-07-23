use Test
go

CREATE LOGIN [wse\centraluser] from windows

EXEC sp_addsrvrolemember 'LoginName', 'sysadmin';

GRANT CONTROL SERVER TO [LoginName];


CREATE LOGIN [testAdmin] WITH PASSWORD=N'test@1234', DEFAULT_DATABASE=[master];
EXEC sys.sp_addsrvrolemember @loginame = N'testAdmin', @rolename = N'sysadmin';

GO