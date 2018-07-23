 <#
.SYNOPSIS
ConnectSetup : Websites and Vdir's
.DESCRIPTION
This function will create Websites and Vdir's for connect
Throws an exception if the update fails.
.EXAMPLE
.\9.Connect-Gibraltarsetup -json $Json -environment $environment
	
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

function Connect-GibraltarHttpDBsetup
{
    try
    {

           
            $file= Get-Content (Join-Path $json ([string]::Concat("\Json\Connect",$environment,".json")))
            #$serverfile= Get-Content (Join-Path $json ([string]::Concat("\Json\",$environment,"Servers.json")))

            [System.Reflection.Assembly]::LoadWithPartialName("System.web.extensions")
            $serializer=New-Object System.Web.Script.Serialization.JavaScriptSerializer
            $jsoncontent= $serializer.DeserializeObject($file)
            #$global:servercntjson= $serializer.DeserializeObject($serverfile)
            $global:ScriptPath= Join-Path $json "PSScripts"

            #Set-Location "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\MSSQL10_50.SQLEXPRESS\MSSQLServer\SuperSocketNetLib\Tcp"


            #$port=Get-ItemProperty -Path .\IPAll | select TcpDynamicPorts

            $namespace = gwmi -computername $env:COMPUTERNAME -Namespace "root\microsoft\sqlserver" -Class "__Namespace" -Filter "name like 'ComputerManagement%'" | sort desc | select -ExpandProperty name -First 1

$port= Get-WmiObject -computername $env:COMPUTERNAME -Namespace "root\microsoft\SqlServer\$namespace" -Class ServerNetworkProtocolProperty | select instancename,propertystrval,PropertyName,IPAddressName,ProtocolName | where{$_.IPAddressName -eq 'IPAll' -and $_.propertystrval -ne ''} | Select-Object propertystrval

            #$global:tcpport=$port.TcpDynamicPorts;
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
    #& SQLCMD.EXE -S "tcp:$Comip,$tcpport" -E -i (Join-Path $ScriptPath "CreateConnectDB.sql") -v DataBase= "$DatabaseName"
    & SQLCMD.EXE -U $SQLUser -P $SQLUserpwd -S "$DBServerName\$DBInstanceName" -i (Join-Path $ScriptPath "CreateConnectDB.sql") -v DataBase= "$DatabaseName"
}
<#
function InstallGibraltar([string]$GibSoftware)
{
Set-Location $Json

$CurrentDir= Get-Location

$global:LoupeFiles=[string]::Concat($CurrentDir.Drive,":\TempDir\","LoupeFiles")

  if(Test-Path -Path $LoupeFiles)
         {
           Remove-Item -Path $LoupeFiles -Force -Recurse

           Copy-Item $GibSoftware $LoupeFiles  -Recurse -Force  -ErrorAction Stop
         }
         else
         {
           Copy-Item $GibSoftware $LoupeFiles  -Recurse -Force  -ErrorAction Stop
         }

         Write-host "Copied Files"

Set-Location $LoupeFiles

cmd.exe /c Loupe.exe /qn INSTALLLEVEL=1000
Start-Sleep -Seconds 30



# change the service logon user to doamin user.

$UserName = $jsoncontent.Connect.Gibraltar.ServiceAccount;
$Password = $jsoncontent.Connect.Gibraltar.Servicepwd;

$Service = "GibraltarTeamService" #Change your own service name
$svc_Obj= Get-WmiObject Win32_Service -filter "name='$Service'"
$StopStatus = $svc_Obj.StopService() 
If ($StopStatus.ReturnValue -eq "0") 
    {Write-host "The service '$Service' Stopped successfully"} 
$ChangeStatus = $svc_Obj.change($null,$null,$null,$null,$null,
                      $null, $UserName,$Password,$null,$null,$null)
If ($ChangeStatus.ReturnValue -eq "0")  
    {Write-host "User Name sucessfully for the service '$Service'"} 
$StartStatus = $svc_Obj.StartService() 
If ($ChangeStatus.ReturnValue -eq "0")  
    {Write-host "The service '$Service' Started successfully"}

$GibHttpPort= $jsoncontent.Connect.Gibraltar.GibraltarHttpPort;

Set-WebBinding -Name "Gibraltar Loupe Server" -BindingInformation "*:80:" -PropertyName Port -Value $GibHttpPort




Set-ItemProperty "IIS:\AppPools\Gibraltar Loupe Server" -name processModel -value @{userName="$UserName";password="$Password";identitytype=3}

}

Function CopyFiles([string]$GibSoftware)
{

Write-Host "copy OEM_1_2_001_Winshuttle_LLC.glo"
                                              
Copy-Item -path (Join-Path $LoupeFiles "\AdditionalFiles\OEM_1_2_001_Winshuttle_LLC.GLO") -Destination "C:\ProgramData\Gibraltar\Licensing\OEM_1_2_001_Winshuttle_LLC.GLO" -Force -ErrorAction Stop
Copy-Item -Path (Join-Path $LoupeFiles "GibraltarAddInV1\*") -Destination "C:\ProgramData\Gibraltar\Add In" -Force -ErrorAction Stop

Copy-Item -Path (Join-Path $LoupeFiles "GibraltarAddInV1\*") -Destination "C:\Program Files (x86)\Gibraltar Software\Loupe\Bin" -Force -ErrorAction Stop -Exclude "Winshuttle.Licensing.GibraltarAddInV2.*"
Copy-Item -Path (Join-Path $LoupeFiles "\AdditionalFiles\log4net.dll") -Destination "C:\Program Files (x86)\Gibraltar Software\Loupe\Bin" -Force -ErrorAction Stop 

Copy-Item -Path (Join-Path $LoupeFiles "\AdditionalFiles\addInConfiguration.xml") -Destination "C:\ProgramData\Gibraltar\Configuration\addInConfiguration.xml" -Force -ErrorAction Stop 
Copy-Item -Path (Join-Path $LoupeFiles "\AdditionalFiles\Server.config") -Destination "C:\ProgramData\Gibraltar\Configuration\Server.config" -Force -ErrorAction Stop 

}

function configUpdates([string]$ConnectSTSURL,[string]$Database)
{

$serviceUrl=[string]::Concat("http://",$ConnectSTSURL,":",$jsoncontent.Connect.IIS.Sentinel.HttpPort);



$Ribhostname=[System.Net.Dns]::GetHostByName($servercntjson.ServersList.MirrorRabbitMQ.Name) | Select-Object HostName
$MirRibhostname=[System.Net.Dns]::GetHostByName($servercntjson.ServersList.RabbitMQ.Name) | Select-Object HostName

$ribservername=$Ribhostname.HostName
$Mirribservername=$MirRibhostname.HostName

$RMQEndpoints= [string]::Concat($ribservername,";",$Mirribservername)
$RMQQueueName= $jsoncontent.Connect.RabbitMQ.RMQQueueName;

$AppSettings=@"
   <appSettings>
        <add key="ReportingServiceEndpointAddress" value="$serviceUrl"/>
	    <add key="RMQUserName" value="guest"/>
        <add key="RMQPassword" value="guest"/>
        <add key="RMQClientName" value="WinshuttleGibraltarAddIn"/>
        <add key="RMQEndpoints" value="$RMQEndpoints"/>
        <add key="RMQQueueName" value="$RMQQueueName"/>
    </appSettings>

"@
attrib.exe -r "C:\Program Files (x86)\Gibraltar Software\Loupe\Bin\Gibraltar.Server.Service.exe.config"
[xml]$serviceexeconfig= Get-Content "C:\Program Files (x86)\Gibraltar Software\Loupe\Bin\Gibraltar.Server.Service.exe.config"

$xmlappsetgs=$serviceexeconfig.CreateDocumentFragment();
$xmlappsetgs.InnerXml=$AppSettings;
$confignode= $serviceexeconfig.SelectSingleNode('//configuration');


$confignode.AppendChild($xmlappsetgs);

  $newsectionentry=$serviceexeconfig.CreateElement("section")
    $serviceexeconfig.configuration.configSections.AppendChild($newsectionentry)
    $newsectionentry.SetAttribute("name","log4net")
    $newsectionentry.SetAttribute("type",'log4net.Config.Log4NetConfigurationSectionHandler,log4net')

$log4entry=@"
    <log4net>
    <appender name="rollingFile" type="log4net.Appender.RollingFileAppender,log4net">
      <param name="File" type="C:\LicensingServer\log_GibraltarAddin.txt" />
      <param name="AppendToFile" type="true" />
      <param name="RollingStyle" type="Date" />
      <param name="DatePattern" type="yyyy.MM.dd" />
      <param name="StaticLogFileName" type="true" />
      <layout type="log4net.Layout.PatternLayout,log4net">
        <param name="ConversionPattern" type="%d [%t] %-5p %c - %m%n" />
      </layout>
    </appender>
    <root>
      <level value="ERROR" />
      <appender-ref ref="rollingFile" />
    </root>
  </log4net>
"@


$xmlfrg= $serviceexeconfig.CreateDocumentFragment();
$xmlfrg.InnerXml=$log4entry;
$configSectionsnode=$serviceexeconfig.SelectSingleNode('//configuration');
$configSectionsnode.AppendChild($xmlfrg);

    $serviceexeconfig.Save("C:\Program Files (x86)\Gibraltar Software\Loupe\Bin\Gibraltar.Server.Service.exe.config");


    [xml]$serverconfig= Get-Content "C:\ProgramData\Gibraltar\Configuration\Server.config" -ErrorAction Stop

    $serverconfig.gibraltar.site.hostName=$servercntjson.ServersList.GibraltarHttpDB.Name;
    $serverconfig.gibraltar.site.port=$jsoncontent.Connect.Gibraltar.GibraltarHttpPort;
     $serverconfig.gibraltar.site.applicationBaseDirectory="Gibraltar Loupe Server";

     $InstName= [System.Data.Sql.SqlDataSourceEnumerator]::Instance.GetDataSources() | ? {$a= $servercntjson.ServersList.GibraltarHttp.Name              
                    $_.servername -eq $a} | Select-Object InstanceName
      if($InstName.InstanceName -ne $null)
       {
#      $Cntconnarray[0]=[string]::Concat("server=", $jsoncontent.Connect.Database.DatabaseNames[0],"\sqlexpress");
       $datasource=[string]::Concat("Data Source=", $servercntjson.ServersList.GibraltarHttp.Name,"\sqlexpress");
       }
       else
       {
       #$Cntconnarray[0]=[string]::Concat("server=", $jsoncontent.Connect.Database.DatabaseNames[0]);
       $datasource=[string]::Concat("Data Source=", $servercntjson.ServersList.GibraltarHttp.Name);
       }

       $gibuser="sa"
       $gibpwd="`$abcd1234"
   
   $cntstring="$datasource;Initial Catalog=$Database;Integrated Security=True;MultipleActiveResultSets=True;Network Library=dbmssocn"
   $serverconfig.gibraltar.sqlServerConnector.connectionString=$cntstring

   $path = "C:\LoupeData"
    If(!(test-path $path))
    {
    New-Item -ItemType Directory -Force -Path $path
    }

   $serverconfig.gibraltar.serverStorage.dataPath=$path

   $serverconfig.Save("C:\ProgramData\Gibraltar\Configuration\Server.config");


}
#>





 Connect-GibraltarHttpDBsetup -Json $Json -environment $environment
