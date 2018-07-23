#Import SQL Server Module called SQLPS
Import-Module "SQLPS" -DisableNameChecking
 
#Your SQL Server Instance Name
$Inst = "hyd-en-vstpp1"
$Srvr = New-Object -TypeName Microsoft.SqlServer.Management.Smo.Server -ArgumentList $Inst
 
#database PSDB with default settings
#by assuming that this database does not yet exist in current instance
$DBName = "PSDB"
$db = New-Object -TypeName Microsoft.SqlServer.Management.Smo.Database($Srvr, $DBName)
$db.Create()
 
#Confirm, list databases in your current instance
$Srvr.Databases |
Select Name, Status, Owner, CreateDate