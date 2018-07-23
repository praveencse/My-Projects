use Master
go

CREATE LOGIN [wse\centraluser] from windows
go

EXEC sp_addsrvrolemember 'LoginName', 'sysadmin';
