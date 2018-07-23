<#
.SYNOPSIS
Checks and creates Database.
.DESCRIPTION
This function will create connect Databases 
Throws an exception if fails.
.EXAMPLE
.\Connect-CreateDB -Database $Database
	
.NOTES
Author:		Padma P Peddigari
Version:    1.0
#>

param(    
    [string]$json=$(throw "Please pass path to json File "),
    [string]$Branch=$(throw "Please pass branch"),
    [string]$configuration=$(throw "Please pass cpnfiguration"),
    [string]$environment=$(throw "Please provide Environment"),
    [string]$Buildversion=$(throw "Please build version "),
    [string]$DBInstanceName=$(throw "Please pass Database Named Instance"),
    [string]$SQLUser=$(throw "Please pass SQL user login Name "),
    [string]$SQLUserpwd=$(throw "Please pass SQL User Password"),
    [string]$DBServerName=$(throw "Please pass Database server name"),
     [string]$centralbinariespath=$(throw "Please provide binaries location")  
)

Function Connect-CreateDB
{
  
  try
      {


          $global:ScriptPath=$PSCommandPath | Split-Path -Parent

          #$centralbinariespath="\\10.26.1.19\Builds\TeamCity\winshuttle\products\Sentinel"
          $SrcDBFilesPath= [string]::Concat($centralbinariespath,"\",$Branch,"\",$configuration,"\",$Buildversion,"\PublishSQLBuild");

          $CurrentDir= Get-Location

          $DestDBFilesPath=[string]::Concat($CurrentDir.Drive,":\TempDir\",$Buildversion)

          CopyDBFiles $SrcDBFilesPath $DestDBFilesPath

          $file= Get-Content (Join-Path $json ([string]::Concat("\Json\Connect",$environment,".json")))
          [System.Reflection.Assembly]::LoadWithPartialName("System.web.extensions")
          $serializer=New-Object System.Web.Script.Serialization.JavaScriptSerializer
          $global:jsoncontent= $serializer.DeserializeObject($file)

                  

            <# cd "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\MSSQL10_50.SQLEXPRESS\MSSQLServer\SuperSocketNetLib\Tcp"
            $port=Get-ItemProperty -Path .\IPAll | select TcpDynamicPorts

            $global:tcpport=$port.TcpDynamicPorts;#>

            $namespace = gwmi -computername $env:COMPUTERNAME -Namespace "root\microsoft\sqlserver" -Class "__Namespace" -Filter "name like 'ComputerManagement%'" | sort desc | select -ExpandProperty name -First 1

$port= Get-WmiObject -computername $env:COMPUTERNAME -Namespace "root\microsoft\SqlServer\$namespace" -Class ServerNetworkProtocolProperty | select instancename,propertystrval,PropertyName,IPAddressName,ProtocolName | where{$_.IPAddressName -eq 'IPAll' -and $_.propertystrval -ne ''} | Select-Object propertystrval

            #$global:tcpport=$port.TcpDynamicPorts;
            $global:tcpport=$port.propertystrval;

            $ip= Test-Connection $env:COMPUTERNAME -Count 1 | select Address,Ipv4Address
            $global:Comip=$ip.IPV4Address.IPAddressToString;

            foreach ($database in $jsoncontent.Connect.Database.DatabaseNames)
            {
            CreateDB $Database $DestDBFilesPath 
            }
             
         
      }
  Catch [System.Exception]
      {
        write-host "Exception "
        write-host $_.exception.message
        exit 1

      
      }

}


Function CreateDB ([string]$DatabaseName,[string]$DestDBFilesPath)

{
        

#        & SQLCMD.EXE -S "tcp:$Comip,$tcpport" -E -i (Join-Path $ScriptPath "CreateConnectDB.sql") -v DataBase= "$DatabaseName"

if($DBInstanceName -ne $null)
{
         & SQLCMD.EXE -U $SQLUser -P $SQLUserpwd -S "$DBServerName\$DBInstanceName" -i (Join-Path $ScriptPath "CreateConnectDB.sql") -v DataBase= "$DatabaseName"
         }
         else
         {
         & SQLCMD.EXE -U $SQLUser -P $SQLUserpwd -S "$DBServerName" -i (Join-Path $ScriptPath "CreateConnectDB.sql") -v DataBase= "$DatabaseName"
         }

        if($DatabaseName -eq "WinshuttleLicensing")
        {


          Write-Host "ASP.NET Registration -- Start"
          
          & C:\Windows\Microsoft.NET\Framework\v4.0.30319\aspnet_regsql.exe -S "tcp:$Comip,$tcpport" -E -A all -d $DatabaseName
          
          Write-Host "ASP.NET Registration -- Complete"

          DeployDacPAC $DatabaseName $DestDBFilesPath

          InsertTb $DatabaseName
        
        }

        else
        {

        DeployDacPAC $DatabaseName $DestDBFilesPath

        }
}


<#Function RegisterASPNET ([string]$DatabaseName)
{
& C:\Windows\Microsoft.NET\Framework\v4.0.30319\aspnet_regsql.exe -S "tcp:$Comip,$tcpport" -E -A all -d $DatabaseName

}#>

Function CopyDBFiles([string]$sourcepath,[string]$destpath)
{

         if(Test-Path -Path $destpath)
         {
           Remove-Item -Path $destpath -Force -Recurse

           Copy-Item $sourcepath $destpath  -Recurse -Force  -ErrorAction Stop
         }
         else
         {
           Copy-Item $sourcepath $destpath  -Recurse -Force  -ErrorAction Stop
         }

         Write-host "Copied Files"

        
}

Function DeployDacPAC([string]$DatabaseName,[string]$Dacpacfilepath)
{

  $sqlpackagepath=(Join-Path $ScriptPath "Dependency_Dlls\SqlPackage.exe")

  $dacpacfile=$null

  if($DatabaseName -eq "WinshuttleLogs")
  {

      
      $dacpacfile = Get-ChildItem $Dacpacfilepath -Filter "*.dacpac" -Force -Recurse | Where-Object {$_.Name -like '*Logs*'} | Select-Object -First 1 Name, Directory
     
  }

  if($DatabaseName -eq "WinshuttleLicensing")
  {
     
      $dacpacfile= Get-ChildItem $Dacpacfilepath -Filter "*.dacpac" -Force -Recurse | Where-Object {$_.Name -like '*Cloud*'} | Select-Object -First 1 Name, Directory
     

  }

  if($DatabaseName -eq "WSLicensingArchive")
  {
      
      $dacpacfile= Get-ChildItem $Dacpacfilepath -Filter "*.dacpac" -Force -Recurse | Where-Object {$_.Name -like '*Archive*'} | Select-Object -First 1 Name, Directory
      

  }

  Write-Host "Creating $DatabaseName DB schema -- start"
  $TargetCoonectionString ="Data Source=$Comip,$tcpport;Initial Catalog=$DatabaseName;Trusted_Connection=True"
  Set-Location $dacpacfile.Directory.FullName

  $file=$dacpacfile.Name

  Write-Host "SqlPackage.exe /Action:Publish /SourceFile:$file /TargetConnectionString:$TargetCoonectionString"
  & $sqlpackagepath /Action:Publish /SourceFile:$file /TargetConnectionString:$TargetCoonectionString 

  Write-Host "Creating $DatabaseName DB schema -- Complete"



}


Function InsertTb([string]$Database)
{

Write-host "Inserting into WinshuttleOrganizationalLevel -- Start"
if($DBInstanceName -ne $null)
{
 
# sqlcmd -S "tcp:$Comip,$tcpport" -E -d "$Database" -Q "INSERT INTO [WinshuttleLicensing].[dbo].[WinshuttleOrganizationalLevel]
 sqlcmd -U $SQLUser -P $SQLUserpwd -S "$DBServerName\$DBInstanceName" -d "$Database" -Q "INSERT INTO [WinshuttleLicensing].[dbo].[WinshuttleOrganizationalLevel]
       	([Name]
           ,[Description]
           ,[CreatedbyUser]
           ,[CreatedDateTime]
           ,[LastModifiedbyUser]
           ,[LastModifiedDateTime]
           ,[IsDeleted])
     VALUES
           ('None','None','CentralUser','2013-06-04 06:08:24.3293908 +00:00',
           'CentralSUer','2013-06-04 06:08:24.3293908 +00:00','False')"
Write-host "Inserting into WinshuttleOrganizationalLevel -- Complete"


Write-host "Inserting into WinshuttleFunctionalArea -- Start"

#sqlcmd -S "tcp:$Comip,$tcpport" -E -d "$Database" -Q "INSERT INTO [WinshuttleLicensing].[dbo].[WinshuttleFunctionalArea]
sqlcmd -U $SQLUser -P $SQLUserpwd -S "$DBServerName\$DBInstanceName" -E -d "$Database" -Q "INSERT INTO [WinshuttleLicensing].[dbo].[WinshuttleFunctionalArea]
       	([Name]
           ,[Description]
           ,[CreatedbyUser]
           ,[CreatedDateTime]	
           ,[LastModifiedbyUser]
           ,[LastModifiedDateTime]
           ,[IsDeleted])
     VALUES
           ('None','None','CentralUser','2013-06-04 06:08:24.3293908 +00:00',
           'CentralSUer','2013-06-04 06:08:24.3293908 +00:00','False')"

}

else
{
# sqlcmd -S "tcp:$Comip,$tcpport" -E -d "$Database" -Q "INSERT INTO [WinshuttleLicensing].[dbo].[WinshuttleOrganizationalLevel]
 sqlcmd -U $SQLUser -P $SQLUserpwd -S "$DBServerName" -d "$Database" -Q "INSERT INTO [WinshuttleLicensing].[dbo].[WinshuttleOrganizationalLevel]
       	([Name]
           ,[Description]
           ,[CreatedbyUser]
           ,[CreatedDateTime]
           ,[LastModifiedbyUser]
           ,[LastModifiedDateTime]
           ,[IsDeleted])
     VALUES
           ('None','None','CentralUser','2013-06-04 06:08:24.3293908 +00:00',
           'CentralSUer','2013-06-04 06:08:24.3293908 +00:00','False')"
Write-host "Inserting into WinshuttleOrganizationalLevel -- Complete"


Write-host "Inserting into WinshuttleFunctionalArea -- Start"

#sqlcmd -S "tcp:$Comip,$tcpport" -E -d "$Database" -Q "INSERT INTO [WinshuttleLicensing].[dbo].[WinshuttleFunctionalArea]
sqlcmd -U $SQLUser -P $SQLUserpwd -S "$DBServerName" -E -d "$Database" -Q "INSERT INTO [WinshuttleLicensing].[dbo].[WinshuttleFunctionalArea]
       	([Name]
           ,[Description]
           ,[CreatedbyUser]
           ,[CreatedDateTime]	
           ,[LastModifiedbyUser]
           ,[LastModifiedDateTime]
           ,[IsDeleted])
     VALUES
           ('None','None','CentralUser','2013-06-04 06:08:24.3293908 +00:00',
           'CentralSUer','2013-06-04 06:08:24.3293908 +00:00','False')"
}

Write-host "Inserting into WinshuttleFunctionalArea -- Complete"

}

Connect-CreateDB -Database $Database

#..\..\Dependency_Dlls\SqlPackage.exe  /Action:Publish /SourceFile:"Winshuttle.Licensing.Cloud.dacpac" /TargetConnectionString:"Data Source=hyd-en-vstpp1\sqlexpress;Initial Catalog=WinshuttleLicensing;Trusted_Connection=True;Pooling=False" 