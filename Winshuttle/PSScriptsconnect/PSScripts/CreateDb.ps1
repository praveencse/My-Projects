use Test
go

CREATE LOGIN [testuser] WITH PASSWORD = '$abcd1234';

EXEC sp_addsrvrolemember 'LoginName', 'sysadmin';

GRANT CONTROL SERVER TO [LoginName];