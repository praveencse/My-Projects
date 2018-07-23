 <#
.SYNOPSIS
ConnectSetup : Websites and Vdir's
.DESCRIPTION
This function will create Websites and Vdir's for connect
Throws an exception if the update fails.
.EXAMPLE
.\Connect-SFRSetup -json $Json -environment $environment
	
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
    [string]$configuration=$(throw "Please pass cpnfiguration")
)

function Connect-SFRSetup
{
try
{

$centralbinariespath="\\10.26.1.19\Builds\TeamCity\winshuttle\products\Sentinel"
$file= Get-Content (Join-Path $json ([string]::Concat("\Json\Connect",$environment,".json")))
$serverfile= Get-Content (Join-Path $json ([string]::Concat("\Json\",$environment,"Servers.json")))

[System.Reflection.Assembly]::LoadWithPartialName("System.web.extensions")
$serializer=New-Object System.Web.Script.Serialization.JavaScriptSerializer
$global:jsoncontent= $serializer.DeserializeObject($file)
$global:servercntjson= $serializer.DeserializeObject($serverfile)
$global:ScriptPath=$PSCommandPath | Split-Path -Parent
$BinariesPath= [string]::Concat($centralbinariespath,"\",$Branch,"\",$configuration,"\",$Buildversion,"\bin\WSServices\Release");
 
$SFRFolder=$jsoncontent.Connect.SFR.Deploymentpath;

[xml]$configxml= Get-Content ((Join-Path $json "ConfigurableValues.xml") | Resolve-Path -ErrorAction Stop)


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
          
           
  
    CreateFolder $SFRFolder
    CopyBinaries $BinariesPath $SFRFolder
    SetupSFR  $LogparsarFolder
            
    #configUpdates $LogparsarFolder $ConnectSTSURL 
}


    catch [System.Exception]
    {
        write-host "Exception.."
        write-host $_.exception.message
    }
}


function SetupLogParserService([string]$LogparsarFolder)
{
$SiteName=$jsoncontent.Connect.SFR.WebsiteName;
$httpPort=$jsoncontent.Connect.SFR.HttpPort;
$AppPoolName=$jsoncontent.Connect.SFR.Apppool;
$winAuth=$WebsiteData.Connect.SFR.windowsAuthentication;
$anoyAuth=$WebsiteData.Connect.SFR.anonymousAuthentication;



$site = C:\Windows\System32\inetsrv\appcmd.exe list site /name:"$SiteName"
 if($site -eq $null)
          {
                Write-Host "Creating site: $SiteName"
               $binding=(@{protocol="http";bindingInformation="*:${httpPort}:"})
                new-item "iis:\sites\$SiteName" -type site -physicalPath "$InetPubRoot" -bindings $binding 
               
                
          }
        else
          {
	            Write-Host "WebSite" $SiteName "already exists. Skipping step"
          }

           C:\Windows\System32\inetsrv\appcmd.exe set apppool "$AppPoolName"
           C:\Windows\System32\inetsrv\appcmd.exe set config "$SiteName" /section:windowsAuthentication /enabled:"$winAuth" /commit:apphost
           C:\Windows\System32\inetsrv\appcmd.exe set config "$SiteName" /section:anonymousAuthentication /enabled:"$anoyAuth" /commit:apphost

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

function configUpdates([string]$LogparsarFolder,[string]$ConnectSTSURL)
{
   

$ServiceURL=[string]::Concat("http://",$ConnectSTSURL,":",$jsoncontent.Connect.IIS.Sentinel.HttpPort);
$exeConfigPath=[string]::Concat($LogparsarFolder,"\Winshuttle.Licensing.LogParserService.exe.config");

$logDBServerName=$servercntjson.ServersList.Database.Name;
$connectDBServerName=$servercntjson.ServersList.Database.Name;



$Ribhostname=[System.Net.Dns]::GetHostByName($servercntjson.ServersList.MirrorRabbitMQ.Name) | Select-Object HostName
$MirRibhostname=[System.Net.Dns]::GetHostByName($servercntjson.ServersList.RabbitMQ.Name) | Select-Object HostName

$ribservername=$Ribhostname.HostName
$Mirribservername=$MirRibhostname.HostName

$RMQEndpoints= [string]::Concat($ribservername,";",$Mirribservername)
$RMQQueueName= $jsoncontent.Connect.RabbitMQ.RMQQueueName;




    [xml]$logparserconfig= Get-Content "$exeConfigPath" -ErrorAction Stop

  
    

     $InstName= [System.Data.Sql.SqlDataSourceEnumerator]::Instance.GetDataSources() | ? {$a= $servercntjson.ServersList.Database.Name              
                    $_.servername -eq $a} | Select-Object InstanceName
      if($InstName.InstanceName -ne $null)
       {
#      $Cntconnarray[0]=[string]::Concat("server=", $jsoncontent.Connect.Database.DatabaseNames[0],"\sqlexpress");
       $datasource=[string]::Concat("Server=", $servercntjson.ServersList.Database.Name,"\sqlexpress");
       }
       else
       {
       #$Cntconnarray[0]=[string]::Concat("server=", $jsoncontent.Connect.Database.DatabaseNames[0]);
       $datasource=[string]::Concat("Server=", $servercntjson.ServersList.Database.Name);
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


}





 Connect-SFRSetup -Json $Json -environment $environment
