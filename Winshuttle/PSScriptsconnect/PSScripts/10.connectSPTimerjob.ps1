 <#
.SYNOPSIS
Connect-SPTimerjob : 
.DESCRIPTION
This function will create Websites and Vdir's for connect
Throws an exception if the update fails.
.EXAMPLE
.\9.Connect-SPTimerjob -json $Json -environment $environment
	
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
   
    [string]$Json=$(throw "please provide path to Json file"),
    [string]$environment=$(throw "Please provide Environment")

)

function Connect-SPTimerjob
{
try
{


$file= Get-Content (Join-Path $json ([string]::Concat("\Json\Connect",$environment,".json")))
$serverfile= Get-Content (Join-Path $json ([string]::Concat("\Json\",$environment,"Servers.json")))

[System.Reflection.Assembly]::LoadWithPartialName("System.web.extensions")
$serializer=New-Object System.Web.Script.Serialization.JavaScriptSerializer
$global:jsoncontent= $serializer.DeserializeObject($file)
$global:servercntjson= $serializer.DeserializeObject($serverfile)



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
Add-PsSnapin Microsoft.SharePoint.PowerShell
#[string]$webAppUrl = "https://hyd-en-vstpp1:448/"
[string]$assemblyName = "Winshuttle.Licensing.SharePointUI.Common"

# Define here the Job Name
[string]$jobName = "Licensing Timer Job"

# Define the class name here. (assembly name + class name of timer job)
$className = "Winshuttle.Licensing.SharePointUI.Common.LicensingTimerJobDefinition"
[void][reflection.assembly]::LoadWithPartialName("Microsoft.SharePoint")
[void][reflection.assembly]::LoadwithPartialName("Microsoft.Office.Server")

[Reflection.Assembly]::LoadWithPartialName("Winshuttle.Licensing.SharePointUI.Common")
$app = get-spwebapplication $SPWebURL
$job= New-Object $className("Licensing Timer Job",$app)
$job.Schedule = [Microsoft.SharePoint.SPSchedule]::FromString("Every 5 minutes between 0 and 59")   
$job.update()
restart-service sptimerv4


    }
catch [System.Exception]
{
  Write-Host "Exception.."
  Write-Host $_.exception.message
  exit 1

}

}


Connect-SPTimerjob -Json $Json -environment $environment
