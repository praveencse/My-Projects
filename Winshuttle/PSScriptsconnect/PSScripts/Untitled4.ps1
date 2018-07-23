#createdb.ps1
#Creates a new database using our specifications
[System.Reflection.Assembly]::LoadWithPartialName('Microsoft.SqlServer.SMO')  | out-null

$s = new-object ('Microsoft.SqlServer.Management.Smo.Server') 'hyd-en-vstpp1\sqlexpress'
$dbname = 'Delete'




# Instantiate the database object and add the filegroups
$db = new-object ('Microsoft.SqlServer.Management.Smo.Database') ($s, $dbname)
# Create the file for the system tables
$syslogname = $dbname + '_SysData'
$dbdsysfile = new-object ('Microsoft.SqlServer.Management.Smo.DataFile') ($sysfg, $syslogname)
$sysfg.Files.Add($dbdsysfile)
$dbdsysfile.FileName = $s.Information.MasterDBPath + '\' + $syslogname + '.mdf'
$dbdsysfile.Size = [double](5.0 * 1024.0)
$dbdsysfile.GrowthType = 'None'
$dbdsysfile.IsPrimaryFile = 'True'

# Create the file for the log
$loglogname = $dbname + '_Log'
$dblfile = new-object ('Microsoft.SqlServer.Management.Smo.LogFile') ($db, $loglogname)
$db.LogFiles.Add($dblfile)
$dblfile.FileName = $s.Information.MasterDBLogPath + '\' + $loglogname + '.ldf'
$dblfile.Size = [double](10.0 * 1024.0)
$dblfile.GrowthType = 'Percent'
$dblfile.Growth = 25.0