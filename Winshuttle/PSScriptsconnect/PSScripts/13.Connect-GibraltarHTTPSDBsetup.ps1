 <#
.SYNOPSIS
ConnectSetup : Websites and Vdir's
.DESCRIPTION
This function will create Websites and Vdir's for connect
Throws an exception if the update fails.
.EXAMPLE
.\Connect-GibraltarHttpssetup -json $Json -environment $environment
	
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
    [string]$DBInstanceName=$(throw "Please pass Database Named Instance"),
    [string]$SQLUser=$(throw "Please pass SQL user login Name "),
    [string]$SQLUserpwd=$(throw "Please pass SQL User Password"),
    [string]$DBServerName=$(throw "Please pass Database server name")

)

function Connect-GibraltarHttpssetup
{
    try
    {

       
        $file= Get-Content (Join-Path $json ([string]::Concat("\Json\Connect",$environment,".json")))
       
        [System.Reflection.Assembly]::LoadWithPartialName("System.web.extensions")
        $serializer=New-Object System.Web.Script.Serialization.JavaScriptSerializer
        $global:jsoncontent= $serializer.DeserializeObject($file)
       $global:ScriptPath= Join-Path $json "PSScripts"

        
         <#cd "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\MSSQL10_50.SQLEXPRESS\MSSQLServer\SuperSocketNetLib\Tcp"
         $port=Get-ItemProperty -Path .\IPAll | select TcpDynamicPorts

         $global:tcpport=$port.TcpDynamicPorts;#>

$namespace = gwmi -computername $env:COMPUTERNAME -Namespace "root\microsoft\sqlserver" -Class "__Namespace" -Filter "name like 'ComputerManagement%'" | sort desc | select -ExpandProperty name -First 1

$port= Get-WmiObject -computername $env:COMPUTERNAME -Namespace "root\microsoft\SqlServer\$namespace" -Class ServerNetworkProtocolProperty | select instancename,propertystrval,PropertyName,IPAddressName,ProtocolName | where{$_.IPAddressName -eq 'IPAll' -and $_.propertystrval -ne ''} | Select-Object propertystrval

            $global:tcpport=$port.propertystrval;

         $ip= Test-Connection $env:COMPUTERNAME -Count 1 | select Address,Ipv4Address
         $global:Comip=$ip.IPV4Address.IPAddressToString;
            
        $Database=$jsoncontent.Connect.Gibraltar.DatabaseName;
        CreateDB $Database
       
    }


    catch [System.Exception]
    {
        write-host "Exception.."
        write-host $_.exception.message
        exit 1

    }
}
Function CreateDB ([string]$DatabaseName)
{

       # & SQLCMD.EXE -S "tcp:$Comip,$tcpport" -E -i (Join-Path $ScriptPath "CreateConnectDB.sql") -v DataBase= "$DatabaseName"
        & SQLCMD.EXE -U $SQLUser -P $SQLUserpwd -S "$DBServerName\$DBInstanceName" -i (Join-Path $ScriptPath "CreateConnectDB.sql") -v DataBase= "$DatabaseName"
      
}



 Connect-GibraltarHttpssetup -Json $Json -environment $environment
