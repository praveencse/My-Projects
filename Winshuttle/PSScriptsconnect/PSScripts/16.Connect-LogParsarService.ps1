 <#
.SYNOPSIS
ConnectSetup : Websites and Vdir's
.DESCRIPTION
This function will create Websites and Vdir's for connect
Throws an exception if the update fails.
.EXAMPLE
.\Connect-LogParsarService -json $Json -environment $environment
	
.NOTES
Author:		Padma P Peddigari
Version:    1.0
#>




#
# Section 1
#
# --------------------------------------------------------------------
# Section 1.1 - Define variables
# --------------------------------------------------------------------
param(
    
    [string]$json=$(throw "Please pass path to json File "),
    [string]$Buildversion=$(throw "Please build version "),
    [string]$Branch=$(throw "Please pass branch"),
    [string]$environment=$(throw "Please provide Environment"),
    [string]$configuration=$(throw "Please pass configuration"),
    [string]$LogDBSever=$(throw "Please pass Database Server Name"),
    [string]$RabbitMQServer=$(throw "Please provide RabbitMQ  server name "),
    [string]$MirrorRatMQServer=$(throw "Please provide Mirror RabbitMQ  server name "),
    [string]$Srvusername=$(throw "Please pass Service account UserName"),
    [string]$Srvpassword=$(throw "Please pass Service account password"),
    [string]$DBInstanceName=$(throw "Please provide Database instance name"),
    [string]$centralbinariespath=$(throw "Please provide binaries location")  
)

function Connect-LogParsarService
{
try
{

#$centralbinariespath="\\10.26.1.19\Builds\TeamCity\winshuttle\products\Sentinel"
$file= Get-Content (Join-Path $json ([string]::Concat("\Json\Connect",$environment,".json")))
$serverfile= Get-Content (Join-Path $json ([string]::Concat("\Json\",$environment,"Servers.json")))

[System.Reflection.Assembly]::LoadWithPartialName("System.web.extensions")
$serializer=New-Object System.Web.Script.Serialization.JavaScriptSerializer
$global:jsoncontent= $serializer.DeserializeObject($file)
#$global:servercntjson= $serializer.DeserializeObject($serverfile)
 $global:ScriptPath=$PSCommandPath | Split-Path -Parent
 $BinariesPath= [string]::Concat($centralbinariespath,"\",$Branch,"\",$configuration,"\",$Buildversion,"\bin\Winshuttle.Licensing.LogParserService\Release\Release");
 
$LogparsarFolder=$jsoncontent.Connect.LogParsarService.Deploymentpath;


$TempCgxmlpath="\\cha-en-vstpp\TempConfig"

[xml]$configxml= Get-Content ((Join-Path $TempCgxmlpath "ConfigurableValues.xml") | Resolve-Path -ErrorAction Stop)


    if($configxml.ConfigData.SPWebURL -ne $null)
    {
    $SPWebURL=$configxml.ConfigData.SPWebURL;
    }
    if($configxml.ConfigData.ConnectSTSURL -ne $null)
    {
    $ConnectSTSURL=$configxml.ConfigData.ConnectSTSURL;
    }
    if($configxml.ConfigData.SPConnectAdminSiteURL -ne $null)
    {
    $SPConnectAdminSiteURL=$configxml.ConfigData.SPConnectAdminSiteURL;
    }
    else
    {
    throw
    }
          
           
  
    CreateFolder $LogparsarFolder
    CopyBinaries $BinariesPath $LogparsarFolder
    SetupLogParserService  $LogparsarFolder

            
    configUpdates $LogparsarFolder $ConnectSTSURL $LogDBSever $RabbitMQServer $MirrorRatMQServer
}


    catch [System.Exception]
    {
        write-host "Exception.."
        write-host $_.exception.message
        exit 1

    }
}


function SetupLogParserService([string]$LogparsarFolder)
{
Set-Location $LogparsarFolder

Write-Host "Service Creation start"

$Serviceusername=$Srvusername;
#$Serviceusername=$jsoncontent.Connect.LogParsarService.ServiceAccount;
$Servicepassword=$Srvpassword;
#$Servicepassword=$jsoncontent.Connect.LogParsarService.Servicepwd;

$ServiceName=$jsoncontent.Connect.LogParsarService.Name;
$DisplayName=$jsoncontent.Connect.LogParsarService.DisplayName;
           
            $secpasswd = ConvertTo-SecureString $Servicepassword -AsPlainText -Force
            $credential = New-Object -TypeName System.Management.Automation.PSCredential ($Serviceusername, $secpasswd)
            $cred = Get-Credential -cred $credential
$Logparsarexe = Join-Path $LogparsarFolder "Winshuttle.Licensing.LogParserService.exe"
New-Service -Name $ServiceName -BinaryPathName $Logparsarexe -DisplayName $DisplayName -StartupType Automatic -Credential $credential -ErrorAction Stop

Write-Host "Service Creation complete"

Restart-Service -Force -Name $ServiceName

}

Function CreateFolder([string]$destpath)
{

       Write-Host "Check and Create $destpath folder -start"

       if (!(Test-Path -Path $destpath))
            {
                New-Item -ItemType Directory -Force -Path $destpath
            }
       Else 
            { 
                Write-host "Folder Exists"
            }

 Write-Host "Check and Create $destpath folder -Stop"
}

Function CopyBinaries([string]$sourcepath,[string]$destpath)
{


if(Test-Path -Path $sourcepath)
   {

             Write-Host "copying binaries from  $sourcepath to $destpath :: Start"

             Copy-Item -Path "$sourcepath\*" -Destination $destpath -Recurse -Force -ErrorAction Stop
 

             Write-Host "Copy Completed !!"
    }

    Else 
    { 
                throw "$sourcepath does not exists"
    }
}

function configUpdates([string]$LogparsarFolder,[string]$ConnectSTSURL,[string]$LogDBSever,[string]$RabbitMQServer,[string]$MirrorRatMQServer)
{
   
    Write-Host "Updating Winshuttle.Licensing.LogParserService.exe.config -- Start"
    $ServiceURL=[string]::Concat("http://",$ConnectSTSURL,":",$jsoncontent.Connect.IIS.Sentinel.HttpPort);
    $exeConfigPath=[string]::Concat($LogparsarFolder,"\Winshuttle.Licensing.LogParserService.exe.config");

    $logDBServerName=$LogDBSever;
    #$logDBServerName=$servercntjson.ServersList.Database.Name;
    $connectDBServerName=$LogDBSever;
    #$connectDBServerName=$servercntjson.ServersList.Database.Name;



    $Ribhostname=[System.Net.Dns]::GetHostByName($RabbitMQServer) | Select-Object HostName
    $MirRibhostname=[System.Net.Dns]::GetHostByName($MirrorRatMQServer) | Select-Object HostName

    $ribservername=$Ribhostname.HostName
    $Mirribservername=$MirRibhostname.HostName

    $RMQEndpoints= [string]::Concat($ribservername,";",$Mirribservername)
    $RMQQueueName= $jsoncontent.Connect.RabbitMQ.RMQQueueName;


    [xml]$logparserconfig= Get-Content "$exeConfigPath" -ErrorAction Stop

  
   <#  $Serviceusername=$Srvusername;
            $Servicepassword=$Srvpassword;
            $secpasswd = ConvertTo-SecureString $Servicepassword -AsPlainText -Force
            $credential = New-Object -TypeName System.Management.Automation.PSCredential ($Serviceusername, $secpasswd)
            $cred = Get-Credential -cred $credential



                     if($env:COMPUTERNAME -eq $GibDBServerename)      
                      {
                      $instances = Get-WmiObject -ComputerName $LogDBSever win32_service | where {$_.name -like "MSSQL*"}
                      }
                      else
                      {
                         $instances = Get-WmiObject -ComputerName $LogDBSever win32_service -Credential $cred | where {$_.name -like "MSSQL*"}
                      }

       $InstName=$instances | Where-Object {$_.Name -like "MSSQL$*" } | Select-Object Name
       if($InstName.Name.Contains("SQLEXPRESS"))
       #>

     <#  $InstName= [System.Data.Sql.SqlDataSourceEnumerator]::Instance.GetDataSources() | ? {$a= $LogDBSever              
                    $_.servername -eq $a} | Select-Object InstanceName 
       
       if($InstName.InstanceName -ne $null)
       {
       #$Cntconnarray[0]=[string]::Concat("server=", $jsoncontent.Connect.Database.DatabaseNames[0],"\sqlexpress");
       #W$datasource=[string]::Concat("Server=", $servercntjson.ServersList.Database.Name,"\sqlexpress");
       $datasource=[string]::Concat("Server=", $LogDBSever,"\sqlexpress");
       }
       else
       {
       #$Cntconnarray[0]=[string]::Concat("server=", $jsoncontent.Connect.Database.DatabaseNames[0]);
       #W$datasource=[string]::Concat("Server=", $servercntjson.ServersList.Database.Name);
       $datasource=[string]::Concat("Server=", $LogDBSever);
       }#>

       if($DBInstanceName -ne $null)
       {
     
       $datasource=[string]::Concat("Server=", $LogDBSever,"\",$DBInstanceName);
       }
       else
       {
      
       $datasource=[string]::Concat("Server=", $LogDBSever);
       }
       
       

       $gibuser="sa"
       $gibpwd="`$abcd1234"
   
   $cntdbname=$jsoncontent.Connect.Database.DatabaseNames[0];
   $logdbname=$jsoncontent.Connect.Database.DatabaseNames[1];

   $cntstring="$datasource;Database=$cntdbname;Integrated Security=True;"
   $logcntstring="$datasource;Database=$logdbname;Integrated Security=True;"

   $Logcntstr=$logparserconfig.configuration.connectionStrings.add |Where-Object {$_.name -eq "LMSReportsDb"}
   $Cntcntstr=$logparserconfig.configuration.connectionStrings.add |Where-Object {$_.name -eq "ConnectReportsDb"}

   $Logcntstr.connectionString=$logcntstring
   $Cntcntstr.connectionString=$cntstring

   $rmqendpointstring=$logparserconfig.configuration.appSettings.add |Where-Object {$_.key -eq "RMQEndpoints"}
   $RMQQueueNamestring=$logparserconfig.configuration.appSettings.add |Where-Object {$_.key -eq "RMQQueueName"}
   $serviceurlstring=$logparserconfig.configuration.appSettings.add |Where-Object {$_.key -eq "ReportingServiceEndpointAddress"}
   $rmqendpointstring.value=$RMQEndpoints
   $serviceurlstring.value=$ServiceURL
   $RMQQueueNamestring.value=$RMQQueueName

   

   $logparserconfig.Save($exeConfigPath);

   Write-Host "Updating Winshuttle.Licensing.LogParserService.exe.config -- complete"


}

Connect-LogParsarService -Json $Json -Buildversion $Buildversion -Branch $Branch -environment $environment -configuration $configuration -LogDBSever $LogDBSever -RabbitMQServer $RabbitMQServer -MirrorRatMQServer $MirrorRatMQServer -Srvusername $Srvusername -Srvpassword $Srvpassword
