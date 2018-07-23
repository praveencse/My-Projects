 <#
.SYNOPSIS
ConnectSetup : Websites and Vdir's
.DESCRIPTION
This function will create Websites and Vdir's for connect
Throws an exception if the update fails.
.EXAMPLE
.\9.Connect-DBUpdateTables -json $Json -environment $environment
	
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
    [string]$environment=$(throw "Please provide Environment"),
    [string]$IDPName=$(throw "Please provide IDPName"),
    [string]$RPName=$(throw "Please provide Relying Party Name"),
    [string]$DBInstanceName=$(throw "Please pass Database Named Instance"),
    [string]$SQLUser=$(throw "Please pass SQL user login Name "),
    [string]$SQLUserpwd=$(throw "Please pass SQL User Password"),    
    [string]$DBServerName=$(throw "Please pass Database server name"),
    [string]$GBHttpHostServer=$(throw "Please pass SQL User Password")

)

function Connect-DBUpdateTables
{
    try
    {


        $file= Get-Content (Join-Path $json ([string]::Concat("\Json\Connect",$environment,".json")))
        #$serverfile= Get-Content (Join-Path $json ([string]::Concat("\Json\",$environment,"Servers.json")))

        [System.Reflection.Assembly]::LoadWithPartialName("System.web.extensions")
        $serializer=New-Object System.Web.Script.Serialization.JavaScriptSerializer
        $global:jsoncontent= $serializer.DeserializeObject($file)
        #$global:servercntjson= $serializer.DeserializeObject($serverfile)

 

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
                <#cd "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\MSSQL10_50.SQLEXPRESS\MSSQLServer\SuperSocketNetLib\Tcp"
                $port=Get-ItemProperty -Path .\IPAll | select TcpDynamicPorts

                $global:tcpport=$port.TcpDynamicPorts;#>
                $namespace = gwmi -computername $env:COMPUTERNAME -Namespace "root\microsoft\sqlserver" -Class "__Namespace" -Filter "name like 'ComputerManagement%'" | sort desc | select -ExpandProperty name -First 1

$port= Get-WmiObject -computername $env:COMPUTERNAME -Namespace "root\microsoft\SqlServer\$namespace" -Class ServerNetworkProtocolProperty | select instancename,propertystrval,PropertyName,IPAddressName,ProtocolName | where{$_.IPAddressName -eq 'IPAll' -and $_.propertystrval -ne ''} | Select-Object propertystrval

            #$global:tcpport=$port.TcpDynamicPorts;
            $global:tcpport=$port.propertystrval;

                $ip= Test-Connection $env:COMPUTERNAME -Count 1 | select Address,Ipv4Address
                $global:Comip=$ip.IPV4Address.IPAddressToString;

                UpdateTb $SPWebURL $ConnectSTSURL $SPConnectAdminSiteURL $RPName



    }
    catch [System.Exception]
    {
       Write-Host "Exception.."
       Write-Host $_.exception.message
       exit 1

    }

}

Function UpdateTb([string]$SPWebURL,[string]$ConnectSTSURL,[string]$SPConnectAdminSiteURL)
{

$HostValue=$SPWebURL
$OwnerNameValue=$jsoncontent.Connect.SharePoint.AdminSiteCollection.OwnerAlias;
$OwnerLoginValue=[string]::Concat("i:05.t|winshuttle acs|",$OwnerNameValue);
$UserNamePrefixValue="i:05.t|winshuttle acs|"
$OwnerEmailValue=$jsoncontent.Connect.SharePoint.AdminSiteCollection.AdminEmail;
$CRMAdminEmailIdValue=$jsoncontent.Connect.SharePoint.AdminSiteCollection.AdminEmail;
$SentinelAdminUrlValue=$SPConnectAdminSiteURL

$HName=[system.net.dns]::GetHostByName($GBHttpHostServer) | Select-Object HostName
$GibraltarServerURLValue=[string]::Concat("http://",$HName.HostName,":",$jsoncontent.Connect.Gibraltar.GibraltarHttpPort);

$Database=$jsoncontent.Connect.Database.DatabaseNames[0];
Set-Location $json
 <#sqlcmd -S "tcp:$Comip,$tcpport" -E -d "$Database" -Q "update [WinshuttleLicensing].[dbo].[LicensingConfiguration ] SET ConfigValue='$HostValue' where ConfigKey='Host'"
 sqlcmd -S "tcp:$Comip,$tcpport" -E -d "$Database" -Q "update [WinshuttleLicensing].[dbo].[LicensingConfiguration ] SET ConfigValue='$OwnerNameValue' where ConfigKey='OwnerName'"
 sqlcmd -S "tcp:$Comip,$tcpport" -E -d "$Database" -Q "update [WinshuttleLicensing].[dbo].[LicensingConfiguration ] SET ConfigValue='$OwnerLoginValue' where ConfigKey='OwnerLogin'"
 sqlcmd -S "tcp:$Comip,$tcpport" -E -d "$Database" -Q "update [WinshuttleLicensing].[dbo].[LicensingConfiguration ] SET ConfigValue='$UserNamePrefixValue' where ConfigKey='UserNamePrefix'"
 sqlcmd -S "tcp:$Comip,$tcpport" -E -d "$Database" -Q "update [WinshuttleLicensing].[dbo].[LicensingConfiguration ] SET ConfigValue='$OwnerEmailValue' where ConfigKey='OwnerEmail'"
 sqlcmd -S "tcp:$Comip,$tcpport" -E -d "$Database" -Q "update [WinshuttleLicensing].[dbo].[LicensingConfiguration ] SET ConfigValue='$CRMAdminEmailIdValue' where ConfigKey='CRMAdminEmailId'"
 sqlcmd -S "tcp:$Comip,$tcpport" -E -d "$Database" -Q "update [WinshuttleLicensing].[dbo].[LicensingConfiguration ] SET ConfigValue='$SentinelAdminUrlValue' where ConfigKey='SentinelAdminUrl'"#>
 if($DBInstanceName -ne $null)
 {
 sqlcmd -U $SQLUser -P $SQLUserpwd -S "$DBServerName\$DBInstanceName" -d "$Database" -Q "update [WinshuttleLicensing].[dbo].[LicensingConfiguration ] SET ConfigValue='$HostValue' where ConfigKey='Host'"
 sqlcmd -U $SQLUser -P $SQLUserpwd -S "$DBServerName\$DBInstanceName" -d "$Database" -Q "update [WinshuttleLicensing].[dbo].[LicensingConfiguration ] SET ConfigValue='$OwnerNameValue' where ConfigKey='OwnerName'"
 sqlcmd -U $SQLUser -P $SQLUserpwd -S "$DBServerName\$DBInstanceName" -d "$Database" -Q "update [WinshuttleLicensing].[dbo].[LicensingConfiguration ] SET ConfigValue='$OwnerLoginValue' where ConfigKey='OwnerLogin'"
 sqlcmd -U $SQLUser -P $SQLUserpwd -S "$DBServerName\$DBInstanceName" -d "$Database" -Q "update [WinshuttleLicensing].[dbo].[LicensingConfiguration ] SET ConfigValue='$UserNamePrefixValue' where ConfigKey='UserNamePrefix'"
 sqlcmd -U $SQLUser -P $SQLUserpwd -S "$DBServerName\$DBInstanceName" -d "$Database" -Q "update [WinshuttleLicensing].[dbo].[LicensingConfiguration ] SET ConfigValue='$OwnerEmailValue' where ConfigKey='OwnerEmail'"
 sqlcmd -U $SQLUser -P $SQLUserpwd -S "$DBServerName\$DBInstanceName" -d "$Database" -Q "update [WinshuttleLicensing].[dbo].[LicensingConfiguration ] SET ConfigValue='$CRMAdminEmailIdValue' where ConfigKey='CRMAdminEmailId'"
 sqlcmd -U $SQLUser -P $SQLUserpwd -S "$DBServerName\$DBInstanceName" -d "$Database" -Q "update [WinshuttleLicensing].[dbo].[LicensingConfiguration ] SET ConfigValue='$SentinelAdminUrlValue' where ConfigKey='SentinelAdminUrl'"
 sqlcmd -U $SQLUser -P $SQLUserpwd -S "$DBServerName\$DBInstanceName" -d "$Database" -Q "update [WinshuttleLicensing].[dbo].[LicensingConfiguration ] SET ConfigValue='$GibraltarServerURLValue' where ConfigKey='GibraltarServerURL'"
 }

 else
 {
  sqlcmd -U $SQLUser -P $SQLUserpwd -S "$DBServerName" -d "$Database" -Q "update [WinshuttleLicensing].[dbo].[LicensingConfiguration ] SET ConfigValue='$HostValue' where ConfigKey='Host'"
 sqlcmd -U $SQLUser -P $SQLUserpwd -S "$DBServerName" -d "$Database" -Q "update [WinshuttleLicensing].[dbo].[LicensingConfiguration ] SET ConfigValue='$OwnerNameValue' where ConfigKey='OwnerName'"
 sqlcmd -U $SQLUser -P $SQLUserpwd -S "$DBServerName" -d "$Database" -Q "update [WinshuttleLicensing].[dbo].[LicensingConfiguration ] SET ConfigValue='$OwnerLoginValue' where ConfigKey='OwnerLogin'"
 sqlcmd -U $SQLUser -P $SQLUserpwd -S "$DBServerName" -d "$Database" -Q "update [WinshuttleLicensing].[dbo].[LicensingConfiguration ] SET ConfigValue='$UserNamePrefixValue' where ConfigKey='UserNamePrefix'"
 sqlcmd -U $SQLUser -P $SQLUserpwd -S "$DBServerName" -d "$Database" -Q "update [WinshuttleLicensing].[dbo].[LicensingConfiguration ] SET ConfigValue='$OwnerEmailValue' where ConfigKey='OwnerEmail'"
 sqlcmd -U $SQLUser -P $SQLUserpwd -S "$DBServerName" -d "$Database" -Q "update [WinshuttleLicensing].[dbo].[LicensingConfiguration ] SET ConfigValue='$CRMAdminEmailIdValue' where ConfigKey='CRMAdminEmailId'"
 sqlcmd -U $SQLUser -P $SQLUserpwd -S "$DBServerName" -d "$Database" -Q "update [WinshuttleLicensing].[dbo].[LicensingConfiguration ] SET ConfigValue='$SentinelAdminUrlValue' where ConfigKey='SentinelAdminUrl'"
 sqlcmd -U $SQLUser -P $SQLUserpwd -S "$DBServerName" -d "$Database" -Q "update [WinshuttleLicensing].[dbo].[LicensingConfiguration ] SET ConfigValue='$GibraltarServerURLValue' where ConfigKey='GibraltarServerURL'"
 }
 
 $ACSNamespace=$jsoncontent.Connect.ACSNamespace;
          
 (Get-Content (Join-Path $json "Utilities\ACS Admin URL creation utility\Settingsdefault.ini")) -replace "STS","$ACSNamespace" -replace "SPWebURL",$SPWebURL -replace "ConnectIDP","$IDPName" -replace "ConnectAdminURL","$SPConnectAdminSiteURL" | Set-Content (Join-Path $json "Utilities\ACS Admin URL creation utility\Settings.ini")

 
 $ACSAdminexe= Join-Path $json "Utilities\ACS Admin URL creation utility\ACSAdminURLcreation.exe";


 & $ACSAdminexe
 
 $LoginURLValue=Get-Content (Join-Path $json "Utilities\ACS Admin URL creation utility\URL.log")

 
 $LogoutURLValue=[string]::Concat("http://",$ConnectSTSURL,$json.Connect.IIS.Sentinel.HttpsPort)
 $RealmValue=$SPWebURL
 $WAdminLoginURLValue=$LoginURLValue
 $WAdminLogoutURLVAlue=[string]::Concat("http://",$ConnectSTSURL,$json.Connect.IIS.Sentinel.HttpsPort)
 $ConnectRPNameValue=$RPName
 
 <#sqlcmd -S "tcp:$Comip,$tcpport" -E -d "$Database" -Q "update [WinshuttleLicensing].[dbo].[ClaimsConfiguration ] SET ConfigValue='$LoginURLValue' where ConfigKey='LoginURL'"
 sqlcmd -S "tcp:$Comip,$tcpport" -E -d "$Database" -Q "update [WinshuttleLicensing].[dbo].[ClaimsConfiguration ] SET ConfigValue='$LogoutURLValue' where ConfigKey='LogoutURL'"
 sqlcmd -S "tcp:$Comip,$tcpport" -E -d "$Database" -Q "update [WinshuttleLicensing].[dbo].[ClaimsConfiguration ] SET ConfigValue='$RealmValue' where ConfigKey='Realm'"
 sqlcmd -S "tcp:$Comip,$tcpport" -E -d "$Database" -Q "update [WinshuttleLicensing].[dbo].[ClaimsConfiguration ] SET ConfigValue='$WAdminLoginURLValue' where ConfigKey='WinshuttleAdminLoginURL'"
 sqlcmd -S "tcp:$Comip,$tcpport" -E -d "$Database" -Q "update [WinshuttleLicensing].[dbo].[ClaimsConfiguration ] SET ConfigValue='$WAdminLogoutURLVAlue' where ConfigKey='WinshuttleAdminLogoutURL'"
 sqlcmd -S "tcp:$Comip,$tcpport" -E -d "$Database" -Q "update [WinshuttleLicensing].[dbo].[ClaimsConfiguration ] SET ConfigValue='$IDPName' where ConfigKey='ConnectIdPName'"
 sqlcmd -S "tcp:$Comip,$tcpport" -E -d "$Database" -Q "update [WinshuttleLicensing].[dbo].[ClaimsConfiguration ] SET ConfigValue='$ConnectRPNameValue' where ConfigKey='ConnectRelyingPartyName'"#>
 if($DBInstanceName -ne $null)
 {
 sqlcmd -U $SQLUser -P $SQLUserpwd -S "$DBServerName\$DBInstanceName" -d "$Database" -Q "update [WinshuttleLicensing].[dbo].[ClaimsConfiguration ] SET ConfigValue='$LoginURLValue' where ConfigKey='LoginURL'"
 sqlcmd -U $SQLUser -P $SQLUserpwd -S "$DBServerName\$DBInstanceName" -d "$Database" -Q "update [WinshuttleLicensing].[dbo].[ClaimsConfiguration ] SET ConfigValue='$LogoutURLValue' where ConfigKey='LogoutURL'"
 sqlcmd -U $SQLUser -P $SQLUserpwd -S "$DBServerName\$DBInstanceName" -d "$Database" -Q "update [WinshuttleLicensing].[dbo].[ClaimsConfiguration ] SET ConfigValue='$RealmValue' where ConfigKey='Realm'"
 sqlcmd -U $SQLUser -P $SQLUserpwd -S "$DBServerName\$DBInstanceName" -d "$Database" -Q "update [WinshuttleLicensing].[dbo].[ClaimsConfiguration ] SET ConfigValue='$WAdminLoginURLValue' where ConfigKey='WinshuttleAdminLoginURL'"
 sqlcmd -U $SQLUser -P $SQLUserpwd -S "$DBServerName\$DBInstanceName" -d "$Database" -Q "update [WinshuttleLicensing].[dbo].[ClaimsConfiguration ] SET ConfigValue='$WAdminLogoutURLVAlue' where ConfigKey='WinshuttleAdminLogoutURL'"
 sqlcmd -U $SQLUser -P $SQLUserpwd -S "$DBServerName\$DBInstanceName" -d "$Database" -Q "update [WinshuttleLicensing].[dbo].[ClaimsConfiguration ] SET ConfigValue='$IDPName' where ConfigKey='ConnectIdPName'"
 sqlcmd -U $SQLUser -P $SQLUserpwd -S "$DBServerName\$DBInstanceName" -d "$Database" -Q "update [WinshuttleLicensing].[dbo].[ClaimsConfiguration ] SET ConfigValue='$ConnectRPNameValue' where ConfigKey='ConnectRelyingPartyName'"
 }

 else
 {
  sqlcmd -U $SQLUser -P $SQLUserpwd -S "$DBServerName" -d "$Database" -Q "update [WinshuttleLicensing].[dbo].[ClaimsConfiguration ] SET ConfigValue='$LoginURLValue' where ConfigKey='LoginURL'"
 sqlcmd -U $SQLUser -P $SQLUserpwd -S "$DBServerName" -d "$Database" -Q "update [WinshuttleLicensing].[dbo].[ClaimsConfiguration ] SET ConfigValue='$LogoutURLValue' where ConfigKey='LogoutURL'"
 sqlcmd -U $SQLUser -P $SQLUserpwd -S "$DBServerName" -d "$Database" -Q "update [WinshuttleLicensing].[dbo].[ClaimsConfiguration ] SET ConfigValue='$RealmValue' where ConfigKey='Realm'"
 sqlcmd -U $SQLUser -P $SQLUserpwd -S "$DBServerName" -d "$Database" -Q "update [WinshuttleLicensing].[dbo].[ClaimsConfiguration ] SET ConfigValue='$WAdminLoginURLValue' where ConfigKey='WinshuttleAdminLoginURL'"
 sqlcmd -U $SQLUser -P $SQLUserpwd -S "$DBServerName" -d "$Database" -Q "update [WinshuttleLicensing].[dbo].[ClaimsConfiguration ] SET ConfigValue='$WAdminLogoutURLVAlue' where ConfigKey='WinshuttleAdminLogoutURL'"
 sqlcmd -U $SQLUser -P $SQLUserpwd -S "$DBServerName" -d "$Database" -Q "update [WinshuttleLicensing].[dbo].[ClaimsConfiguration ] SET ConfigValue='$IDPName' where ConfigKey='ConnectIdPName'"
 sqlcmd -U $SQLUser -P $SQLUserpwd -S "$DBServerName" -d "$Database" -Q "update [WinshuttleLicensing].[dbo].[ClaimsConfiguration ] SET ConfigValue='$ConnectRPNameValue' where ConfigKey='ConnectRelyingPartyName'"

 }

 
}



 Connect-DBUpdateTables -Json $Json -environment $environment -IDPName $IDPName -RPName $RPName
