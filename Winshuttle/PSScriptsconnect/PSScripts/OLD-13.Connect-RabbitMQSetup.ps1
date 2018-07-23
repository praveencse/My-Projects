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
    [string]$environment=$(throw "Please provide Environment")

)

function Connect-GibraltarHttpssetup
{
try
{

[string]$Softwarepath="\\10.26.1.19\Common-Data\Andromeda\Raj\Loupe"
$file= Get-Content (Join-Path $json ([string]::Concat("\Json\Connect",$environment,".json")))
$serverfile= Get-Content (Join-Path $json ([string]::Concat("\Json\",$environment,"Servers.json")))

[System.Reflection.Assembly]::LoadWithPartialName("System.web.extensions")
$serializer=New-Object System.Web.Script.Serialization.JavaScriptSerializer
$global:jsoncontent= $serializer.DeserializeObject($file)
$global:servercntjson= $serializer.DeserializeObject($serverfile)
$global:ScriptPath=$PSCommandPath | Split-Path -Parent

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
     cd "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\MSSQL10_50.SQLEXPRESS\MSSQLServer\SuperSocketNetLib\Tcp"
            $port=Get-ItemProperty -Path .\IPAll | select TcpDynamicPorts

            $global:tcpport=$port.TcpDynamicPorts;

            $ip= Test-Connection $env:COMPUTERNAME -Count 1 | select Address,Ipv4Address
            $global:Comip=$ip.IPV4Address.IPAddressToString;
            $Database="WSReportingDB"
           
  
    InstallRabbitMQ $Softwarepath
    #copyFiles $Softwarepath
    #configUpdates $ConnectSTSURL $Database
}


    catch [System.Exception]
    {
        write-host "Exception.."
        write-host $_.exception.message
    }
}


function InstallRabbitMQ([string]$Softwarepath)
{
Set-Location $Json

$CurrentDir= Get-Location

$global:RabbitMQFiles=[string]::Concat($CurrentDir.Drive,":\TempDir\","RabbitMQFiles")

  if(Test-Path -Path $RabbitMQFiles)
         {
           Remove-Item -Path $RabbitMQFiles -Force -Recurse

           Copy-Item $Softwarepath $RabbitMQFiles  -Recurse -Force  -ErrorAction Stop
         }
         else
         {
           Copy-Item $Softwarepath $RabbitMQFiles  -Recurse -Force  -ErrorAction Stop
         }

         Write-host "Copied Files"

Set-Location $RabbitMQFiles

Write-Host "Installing Erlang -Start"

Start-Process -Wait .\otp_win32_R16B03-1.exe /S

Write-Host "Installing Erlang -Stop"



Write-Host "Installing RabbitMQ -Start"

Start-Process -Wait .\rabbitmq-server-3.2.3.exe /S

Write-Host "Installing RabbitMQ -Complete"


Write-Host "Copying Erlang cookie -start"

Copy-Item -Path "C:\Windows\.erlang.cookie" -Destination "C:\Users\$env:USERNAME\.erlang.cookie" -Force -ErrorAction Stop

Write-Host "Copying Erlang cookie -Complete"



$MirrorServer=$servercntjson.ServersList.MirrorRabbitMQ.Name;

 Write-Host "Check and Create $destpath folder -start"

       if ((Test-Path -Path "\\$MirrorServer\c$\TempDir\RabbitMQFiles"))
            {
                
                Remove-Item -Path "\\$MirrorServer\c$\TempDir\RabbitMQFiles" -Force -Recurse
                New-Item -ItemType Directory -Force -Path "\\$MirrorServer\c$\TempDir\RabbitMQFiles"
            }
       Else 
            { 
                Write-host "Folder Exists"
            }

 Write-Host "Copying Erlang and RabbitMQ Installtion Files - Start"

 Copy-Item -Path "C:\TempDir\RabbitMQFiles\otp_win32_R16B03-1.exe" -Destination "\\$MirrorServer\c$\TempDir\RabbitMQFiles\otp_win32_R16B03-1.exe" -Force -ErrorAction Stop
 Copy-Item -Path "C:\TempDir\RabbitMQFiles\rabbitmq-server-3.2.3.exe" -Destination "\\$MirrorServer\c$\TempDir\RabbitMQFiles\rabbitmq-server-3.2.3.exe" -Force -ErrorAction Stop
  Write-Host "Copying Erlang and RabbitMQ Installtion Files - Complete"



 Write-Host "Installing Erlang on Node server $MirrorServer -Start"

 Invoke-Command -ComputerName $MirrorServer -ScriptBlock { Start-Process -Wait  "c:\tempdir\RabbitMQFiles\otp_win32_R16B03-1.exe" /S}
 Write-Host "Installing Erlang on Node server $MirrorServer -Complete"


 Write-Host "Installing RabbitMQ on Node server $MirrorServer -Start"
 Invoke-Command -ComputerName $MirrorServer -ScriptBlock { Start-Process -Wait  "c:\tempdir\RabbitMQFiles\rabbitmq-server-3.2.3.exe" /S}
 Write-Host "Installing RabbitMQ on Node server $MirrorServer  -Complete"

 Write-Host "Copied Erlang Cookie to Node server $MirrorServe -Start"
 
Copy-Item -Path "C:\Windows\.erlang.cookie" -Destination "\\$MirrorServer\C$\Windows\.erlang.cookie" -Force -ErrorAction Stop
Copy-Item -Path "C:\Windows\.erlang.cookie" -Destination "\\$MirrorServer\C$\Users\$env:USERNAME\.erlang.cookie" -Force -ErrorAction Stop

Write-Host "Copied Erlang Cookie to Node server $MirrorServe -Complete"

Write-Host "Enabling Manamagemnt Plugin on Node server $MirrorServe -Start"
 Invoke-Command -ComputerName $MirrorServer -ScriptBlock { Set-Location "C:\Program Files (x86)\RabbitMQ Server\rabbitmq_server-3.2.3\sbin" 
cmd.exe /c .\rabbitmq-plugins.bat enable rabbitmq_management
} 

Write-Host "Enabling Manamagemnt Plugin on Node server $MirrorServe -Complete"

#Stop-Service -Name RabbitMQ -ErrorAction Stop
#Start-Service -Name RabbitMQ -ErrorAction Stop
Restart-Service -Name RabbitMQ -ErrorAction Stop -Force 

Write-Host "Enabling RabbitMQ Managment Plug  -Start"

$folderName = "RabbitMQ Server"
$dirPath=gci -path C:\ -filter $foldername -Recurse | Select-Object -Expand FullName
$rabbitSbinpath=Get-ChildItem $dirPath -Name -attributes D

$sbinPath=Join-Path $dirPath $rabbitSbinpath -ErrorAction Stop

Set-Location (Join-Path $sbinPath "sbin")

cmd.exe /c rabbitmq-plugins enable rabbitmq_management


Write-Host "Enabling RabbitMQ Managment Plug in -Complete"




Write-host "Clustering the node -Start"

cmd.exe /c rabbitmqctl stop_app

$node=$MirrorServer.ToUpper();
cmd.exe /c rabbitmqctl join_cluster rabbit@$node

cmd.exe /c rabbitmqctl start_app


Write-host "Creating the Queue -- start"

Set-Location (Join-Path $Json "Utilities\RabbitMQAdmin")

$QueueName=$jsoncontent.Connect.RabbitMQ.RMQQueueName;

& .\RabbitMQAdmin.exe $QueueName

Write-host "Creating the Queue -- complete"

#Set-Location (Join-Path $sbinPath "sbin")

$pluginpath = Join-Path $sbinPath "sbin"

#cmd.exe /c rabbitmqctl set_policy MirroringPolicyb "^$QueueName" '{"""ha-mode""":"""all""","""ha-sync-mode""":"""automatic"""}'  --apply-to queues
.\Policy.cmd "$pluginpath" $QueueName

Write-host "Clustering the node -Complete"

}






 Connect-GibraltarHttpssetup -Json $Json -environment $environment
