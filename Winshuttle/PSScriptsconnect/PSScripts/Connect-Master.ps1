 <#
.SYNOPSIS
ConnectSetup : Websites and Vdir's
.DESCRIPTION
This function will create Websites and Vdir's for connect
Throws an exception if the update fails.
.EXAMPLE
.\Connect-Master -json $Json -environment $environment
	
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
    [string]$ACSLoginurl=$(throw "Please provide ACSLoginurl"),
    [string]$RPName=$(throw "Please provide RPName"),
    [string]$IDPName=$(throw "Please provide IDPName"),
    [string]$configuration=$(throw "Please pass configuration"),
    [string]$Component=$(throw "Please pass component")
)

function Connect-Master
{
try
{

$centralbinariespath="\\10.26.1.19\Builds\TeamCity\winshuttle\products\Sentinel"
$serverfile= Get-Content (Join-Path $json ([string]::Concat("\Json\",$environment,"Servers.json")))

[System.Reflection.Assembly]::LoadWithPartialName("System.web.extensions")
$serializer=New-Object System.Web.Script.Serialization.JavaScriptSerializer
$global:jsoncontent= $serializer.DeserializeObject($file)
$global:servercntjson= $serializer.DeserializeObject($serverfile)
$global:ScriptPath=$PSCommandPath | Split-Path -Parent
$BinariesPath= [string]::Concat($centralbinariespath,"\",$Branch,"\",$configuration,"\",$Buildversion,"\PublishSR");


 $Server_Services=$servercntjson.ServersList.Services;
 $Server_Database=$servercntjson.ServersList.Database;
 $Server_Sharepoint=$servercntjson.ServersList.Sharepoint;
 $Server_GibraltarHttp=$servercntjson.ServersList.GibraltarHttp;
 $Server_GibraltarHttpDB=$servercntjson.ServersList.GibraltarHttpDB;
 $Server_GibraltarHttps=$servercntjson.ServersList.GibraltarHttps;
 $Server_GibraltarHttpsDB=$servercntjson.ServersList.GibraltarHttpsDB;
 $Server_RabbitMQ=$servercntjson.ServersList.RabbitMQ;
 $Server_MirrorRabbitMQ=$servercntjson.ServersList.MirrorRabbitMQ;
 $Server_LogParser=$servercntjson.ServersList.LogParser;
 $Server_SFR=$servercntjson.ServersList.SFR;


 
    CopyFiles $Server_Services $json $environment $Buildversion $Branch $configuration $Component
    DeployServices $Server_Services $json $environment $co
    <#
    DeploySharepoint
    DeployWSP
    DeployDatabase
    UpdateWebConfig
    UpdateSPConfig
    UpdateDBTables
    SetupTimerJob
    SetUpGibraltarHttp
    SetUpGibraltarHttps
    SetupRabbitMQ
    SetupLPS
    SetUpSFR
    #>
    
    
   
}


    catch [System.Exception]
    {
        write-host "Exception.."
        write-host $_.exception.message
    }
}


Function CopyFiles([string]$Server,[string]$json,[string]$environment,[string]$Buildversion,[string]$Branch,[string]$configuration,[String]$deploy)
{

if($deploy -eq "CopyFiles")
{

$pslocation=[string]::Concat($json,"\PSScripts")

Set-Location $pslocation
$Ps1path= Join-Path $pslocation "2.Connect-CopyBinaries.ps1"

#& C:\backup\PSTools\PsExec.exe \\$Server -h -u wse\centraluser -p "`$abcd1234" -d -i -s PowerShell -noninteractive -file "$pslocation\2.Connect-CopyBinaries.ps1" -json "$json" -Buildversion "$Buildversion" -Branch "$Branch" -environment "$environment" -configuration "$configuration"
#& C:\backup\PSTools\PsExec.exe \\$Server -u wse\centraluser -p "`$abcd1234" cmd.exe /c PowerShell -noninteractive -file "$pslocation\2.Connect-CopyBinaries.ps1" -json "$json" -Buildversion "$Buildversion" -Branch "$Branch" -environment "$environment" -configuration "$configuration"
Invoke-Command -ComputerName $Server -ScriptBlock { $pslocation\2.Connect-CopyBinaries.ps1" -json $args[0] -Buildversion $args[1] -Branch $args[2] -environment $args[3] -configuration $args[4] } -Args "$json","$Buildversion","$Branch","$environment" ,"$configuration"



}


}

Function DeployServices([string]$Server,[string]$json,[string]$environment)
{


if($deploy -eq "DeployServices")
{
$pslocation=[string]::Concat($json,"\PSScripts")
Set-Location $pslocation

#C:\backup\PSTools\PsExec.exe \\$Server -h -u wse\centraluser -p "`$abcd1234" cmd.exe /c PowerShell -noninteractive -file "$pslocation\3.Connect-IISWebSites.ps1" -json "$json" -environment "$environment" 
Invoke-Command -ComputerName "\\$Server" -ScriptBlock { C:\AutomationScripts\Connect\QA\PSScripts\dummy.ps1 -name $args[0] -path $args[1] } -Args "padma","c:\Padma" 
}
}







Connect-Master -Json $Json -Buildversion $Buildversion -Branch $Branch -environment $environment -ACSLoginurl $ACSLoginurl -RPName $RPName -IDPName $IDPName -configuration $configuration
