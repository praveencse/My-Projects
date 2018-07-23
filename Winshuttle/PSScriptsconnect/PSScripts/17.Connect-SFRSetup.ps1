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
    [string]$configuration=$(throw "Please pass configuration"),
     [string]$Srvusername=$(throw "Please pass Service account UserName"),
    [string]$Srvpassword=$(throw "Please pass Service account password")
  
)

function Connect-SFRSetup
{
try
{

    $centralbinariespath="\\10.26.1.19\Builds\TeamCity\winshuttle\products\Sentinel"
    $file= Get-Content (Join-Path $json ([string]::Concat("\Json\Connect",$environment,".json")))
    #$serverfile= Get-Content (Join-Path $json ([string]::Concat("\Json\",$environment,"Servers.json")))

    [System.Reflection.Assembly]::LoadWithPartialName("System.web.extensions")
    $serializer=New-Object System.Web.Script.Serialization.JavaScriptSerializer
    $global:jsoncontent= $serializer.DeserializeObject($file)
    #$global:servercntjson= $serializer.DeserializeObject($serverfile)
    $global:ScriptPath=$PSCommandPath | Split-Path -Parent
    $BinariesPath= [string]::Concat($centralbinariespath,"\",$Branch,"\",$configuration,"\",$Buildversion,"\PublishSR");
 
    $SFRFolder=$jsoncontent.Connect.SFR.Deploymentpath;


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
          
           
  
        CreateFolder $SFRFolder
        CopyBinaries $BinariesPath $SFRFolder
        SetupSFR  $SFRFolder
            
        configUpdates $environment 
}


    catch [System.Exception]
    {
        write-host "Exception.."
        write-host $_.exception.message
        exit 1

    }
}


function SetupSFR([string]$SFRFolder)
{
$SiteName=$jsoncontent.Connect.SFR.WebsiteName;
$httpPort=$jsoncontent.Connect.SFR.HttpPort;
$AppPoolName=$jsoncontent.Connect.SFR.Apppool;
$winAuth=$jsoncontent.Connect.SFR.windowsAuthentication;
$anoyAuth=$jsoncontent.Connect.SFR.anonymousAuthentication;

Import-Module WebAdministration

 $pool = C:\Windows\System32\inetsrv\appcmd.exe list apppool /name:"$AppPoolName"
        if($pool -eq $null)
          {
                Write-Host "Creating app pool: $AppPoolName"
                C:\Windows\System32\inetsrv\appcmd.exe add apppool /name:"$AppPoolName"
          }
        else
          {
	            Write-Host "Application pool" $AppPoolName "already exists. Skipping step"
          }

$site = C:\Windows\System32\inetsrv\appcmd.exe list site /name:"$SiteName"
 if($site -eq $null)
          {
                Write-Host "Creating site: $SiteName"
               $binding=(@{protocol="http";bindingInformation="*:${httpPort}:"})
                new-item "iis:\sites\$SiteName" -type site -physicalPath "$SFRFolder" -bindings $binding -Force
               
                
          }
        else
          {
	            Write-Host "WebSite" $SiteName "already exists. Skipping step"
          }

           C:\Windows\System32\inetsrv\appcmd.exe set apppool "$AppPoolName" /managedRuntimeVersion:v4.0 /recycling.periodicRestart.time:00:00:00

                   C:\Windows\System32\inetsrv\appcmd.exe set config /section:applicationPools "/[name='$AppPoolName'].processModel.identityType:SpecificUser" "/[name='$AppPoolName'].processModel.userName:$Srvusername" "/[name='$AppPoolName'].processModel.password:$Srvpassword"

           C:\Windows\System32\inetsrv\appcmd.exe set app "$SiteName/" /applicationPool:$AppPoolName
           C:\Windows\System32\inetsrv\appcmd.exe set config "$SiteName" /section:windowsAuthentication /enabled:"$winAuth" /commit:apphost
           C:\Windows\System32\inetsrv\appcmd.exe set config "$SiteName" /section:anonymousAuthentication /enabled:"$anoyAuth" /commit:apphost

}

Function CreateFolder([string]$destpath)
{

       Write-Host "Check and Create $destpath folder -start"

       if (Test-Path -Path $destpath)
            {

                Remove-Item -Path $destpath -Force -ErrorAction Stop -Confirm:$false -Recurse
                New-Item -ItemType Directory -Force -Path $destpath -ErrorAction Stop

            }
       Else 
            { 
                New-Item -ItemType Directory -Force -Path $destpath -ErrorAction Stop
            }

 Write-Host "Check and Create $destpath folder -Complete"
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

function configUpdates([string]$environment, [string]$SFRFolder)
{

        if($environment -eq "Dev" -or $environment -eq "POD")
        {
   
           $configPath= Join-Path $json (Join-Path "Utilities\SFRConfigs" "Dev.Web.config")
         }
   
        if($environment -eq "Staging")
        {
        $configPath= Join-Path $json (Join-Path "Utilities\SFRConfigs" "Staging.Web.config")

        }
        if($environment -eq "QA")
        {
        $configPath= Join-Path $json (Join-Path "Utilities\SFRConfigs" "QA.Web.config")
        }
        if($environment -eq "Prod")
        {
        $configPath= Join-Path $json (Join-Path "Utilities\SFRConfigs" "Prod.Web.config")
        }


       Write-host "Copying  $configPath to $SFRFolder -- Start "
       Copy-Item -Path $configPath -Destination "$SFRFolder" -Force -ErrorAction Stop 
       Write-host "Copying  $configPath to $SFRFolder -- Complete "

}


Connect-SFRSetup -Json $Json -Buildversion $Buildversion -Branch $Branch -environment $environment -configuration $configuration -Srvusername $Srvusername -Srvpassword $Srvpassword
