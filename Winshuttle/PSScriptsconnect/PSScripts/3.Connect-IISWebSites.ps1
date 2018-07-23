 <#
.SYNOPSIS
ConnectSetup : Websites and Vdir's
.DESCRIPTION
This function will create Websites and Vdir's for connect
Throws an exception if the update fails.
.EXAMPLE
.\CreateIISWebSite -json $Json -environment $environment
	
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
    [string]$Srvusername=$(throw "Please pass Service account UserName"),
    [string]$Srvpassword=$(throw "Please pass Service account password")

)



Function CreateIISWebSite
{

try
{
<#
    $jsonfile= Join-Path $json ([string]::Concat("Json\Connect",$environment,".json")) -ErrorAction stop
    $global:WebsiteData= ConvertFrom-Json -InputObject (gc $jsonfile -Raw) -ErrorAction Stop #>

    $file= Get-Content (Join-Path $json ([string]::Concat("\Json\Connect",$environment,".json")))

[System.Reflection.Assembly]::LoadWithPartialName("System.web.extensions")
$serializer=New-Object System.Web.Script.Serialization.JavaScriptSerializer
$global:WebsiteData= $serializer.DeserializeObject($file)

    write-host "Taking IIS Backup`n`n"
    $date=get-date
    $time='{0:yyyy-MM-dd---HH-mm-ss}' -f $date
    Backup-WebConfiguration -name "$time"
    Write-Host "`n`n"


    Import-Module WebAdministration

    CreateWebsite-Sentinel 
    CreateWebsite-SentinelClient

    CreateWebsite-SentinelWebApi
}

Catch [System.Exception]
{
    write-host "Exception "
    write-host $_.exception.message
    exit 1

      
}

}

#ConnectSTS is created as Vdir under sentinelClient
<#
Function CreateWebsite-ConnectSTS
{


$InetpubRoot = "C:\Connect\ConnectSTS"
$SiteName = "ConnectSTS"
$SiteID = "11"
#$SiteUrl = "mysite.deloitte.com"
$AppPoolName = "ConnectSTS"



if (!(Test-Path -Path $InetpubRoot))
    {
New-Item -ItemType Directory -Force -Path $InetpubRoot
}
Else { Write-host "Folder Exists"}

        # check and create Apppool
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


          # check and create website
        $site = C:\Windows\System32\inetsrv\appcmd.exe list site /name:"$SiteName"
        if($site -eq $null)
          {
                Write-Host "Creating site: $SiteName"
                C:\Windows\System32\inetsrv\appcmd.exe add site /name:$SiteName /bindings:"https/*:446" /physicalPath:"$InetPubRoot" /id:$SiteID
          }
        else
          {
	            Write-Host "WebSite" $SiteName "already exists. Skipping step"
          }


        Write-Host "Making changes to application pool: " $AppPoolName

        C:\Windows\System32\inetsrv\appcmd.exe set apppool "$AppPoolName" /managedRuntimeVersion:v4.0 /recycling.periodicRestart.time:00:00:00

        C:\Windows\System32\inetsrv\appcmd.exe set config /section:applicationPools "/[name='$AppPoolName'].processModel.identityType:SpecificUser" "/[name='$AppPoolName'].processModel.userName:wse\centraluser" "/[name='$AppPoolName'].processModel.password:`$abcd1234"


        Write-Host "Making changes to site: " $SiteName
        C:\Windows\System32\inetsrv\appcmd.exe set app "$SiteName/" /applicationPool:$AppPoolName
        C:\Windows\System32\inetsrv\appcmd.exe set config "$SiteName" /section:windowsAuthentication /enabled:false /commit:apphost
        C:\Windows\System32\inetsrv\appcmd.exe set config "$SiteName" /section:anonymousAuthentication /enabled:true /commit:apphost
        C:\Windows\System32\inetsrv\appcmd.exe set config "$SiteName" /section:system.web/authentication /mode:Forms


Write-Host "Assign permissions to InetpubRoot"


# Include if you will be using a service account as the app pool identity
cmd.exe /c "icacls $InetpubRoot /grant wse\centraluser:(OI)(CI)(RX)"
#cmd.exe /c "net localgroup IIS_IUSRS USDEV\<SomeServiceAcct> /add"


# Grant modify permissions for specific folder
# cmd.exe /c "icacls "$InetpubRoot\<SomeFolder>" /grant USDEV\<SomeSvcAcct>:(OI)(CI)(M)"


# Note: Accounts with spaces in the names should be surrounded with two sets of double quotes. 
# Additional commands for reference and are not normally required


#cmd.exe /c "icacls $InetpubRoot /grant ""Authenticated Users"":(OI)(CI)(RX)"
#cmd.exe /c "icacls $InetpubRoot /grant ""Network Service"":(OI)(CI)(RX)"
}
#>

Function CreateWebsite-Sentinel
{

$SiteName=$WebsiteData.Connect.IIS.Sentinel.SiteName;
$InetpubRoot= $WebsiteData.Connect.IIS.Sentinel.InetpubRoot;
$SiteID= $WebsiteData.Connect.IIS.Sentinel.SiteID;
$AppPoolName=$WebsiteData.Connect.IIS.Sentinel.AppPoolName;
$dotnetVersion=$WebsiteData.Connect.IIS.Sentinel.DotNetVersion;
$httpPort=$WebsiteData.Connect.IIS.Sentinel.HttpPort;
$httpsPort=$WebsiteData.Connect.IIS.Sentinel.HttpsPort;
$nettcpport=$WebsiteData.Connect.IIS.Sentinel.NetTcpPort;
#$Apppooluser=$WebsiteData.Connect.IIS.Sentinel.AppPoolAcctUser;
#$Apppoolpwd=$WebsiteData.Connect.IIS.Sentinel.AppPoolAcctpwd;
$Apppooluser=$Srvusername;

$Apppoolpwd=$Srvpassword;
$winAuth=$WebsiteData.Connect.IIS.Sentinel.windowsAuthentication;
$anoyAuth=$WebsiteData.Connect.IIS.Sentinel.anonymousAuthentication;
$CertFriendName=$WebsiteData.Connect.IIS.Sentinel.Certificate;

Write-host " ***** Sentinel website Properties ***** " 

Write-host "SiteName : "$SiteName
Write-host "SiteID : "$SiteID
Write-host "InetpubRoot : "$InetpubRoot
Write-host "AppPoolName : "$AppPoolName
Write-host ".NetVersion : "$dotnetVersion
Write-host "HttpPort : "$httpPort
Write-host "HttpsPort : "$httpsPort
Write-host "NetTcpPort : "$nettcpport
Write-host "Apppool UserAccount : "$Apppooluser
Write-host "Windows Authencation : "$winAuth
Write-host "Anonymous Authencation : "$anoyAuth
Write-host "Certificate : "$CertFriendName

 Import-Module WebAdministration
 Invoke-Command -ComputerName . -ScriptBlock { [Environment]::Is64BitProcess }

        if (!(Test-Path -Path $InetpubRoot))
            {
                New-Item -ItemType Directory -Force -Path $InetpubRoot
            }
        Else 
            { 
                Write-host "Folder Exists"
            }

        # check and create Apppool
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


          # check and create website
        $site = C:\Windows\System32\inetsrv\appcmd.exe list site /name:"$SiteName"
        if($site -eq $null)
          {
                Write-Host "Creating site: $SiteName"
               
                           
                            #$binding=(@{protocol="http";bindingInformation="*:8081:"},@{protocol="https";bindingInformation="*:444:"},@{protocol="net.tcp";bindingInformation=":808:"})
                            #$binding=(@{protocol="http";bindingInformation="*:${httpPort}:"},@{protocol="https";bindingInformation="*:${httpsPort}:"},@{protocol="net.tcp";bindingInformation="${nettcpport}:*"})
                            $binding=(@{protocol="http";bindingInformation="*:${httpPort}:"},@{protocol="net.tcp";bindingInformation="${nettcpport}:*"})
                            new-item "iis:\sites\$SiteName" -type site -physicalPath "$InetPubRoot" -bindings $binding 
               #C:\Windows\System32\inetsrv\appcmd.exe add site /name:$SiteName /bindings:"http/*:${httpPort}:,https/*:${httpsPort}:,net.tcp/*:${nettcpport}:" /physicalPath:"$InetPubRoot" 
               #C:\Windows\System32\inetsrv\appcmd.exe set app "$SiteName/" /enabledProtocols:http,net.tcp
                Set-ItemProperty IIS:\Sites\$SiteName -Name EnabledProtocols -Value "http,net.tcp"

             
                
          }
        else
          {
	            Write-Host "WebSite" $SiteName "already exists. Skipping step"
          }


        Write-Host "Making changes to application pool: " $AppPoolName

        C:\Windows\System32\inetsrv\appcmd.exe set apppool "$AppPoolName" /managedRuntimeVersion:v4.0 /recycling.periodicRestart.time:00:00:00

        C:\Windows\System32\inetsrv\appcmd.exe set config /section:applicationPools "/[name='$AppPoolName'].processModel.identityType:SpecificUser" "/[name='$AppPoolName'].processModel.userName:$Apppooluser" "/[name='$AppPoolName'].processModel.password:$Apppoolpwd"


        Write-Host "Making changes to site: " $SiteName
        C:\Windows\System32\inetsrv\appcmd.exe set app "$SiteName/" /applicationPool:$AppPoolName
        C:\Windows\System32\inetsrv\appcmd.exe set config "$SiteName" /section:windowsAuthentication /enabled:"$winAuth" /commit:apphost
        C:\Windows\System32\inetsrv\appcmd.exe set config "$SiteName" /section:anonymousAuthentication /enabled:"$anoyAuth" /commit:apphost



        Write-Host "Retrive certificates"

        
        if($WebsiteData.Connect.IIS.Sentinel.Certificate -eq "Developer")
        {
        $domainname=$env:COMPUTERNAME
        $certs=@(Get-ChildItem -Path Cert:\LocalMachine\My -Recurse | Where-Object {$_.Subject -match "CN=$domainname"} | Select Thumbprint)
        }
        else
        {
        
        #$domainname=$certName;
        $certs=@(Get-ChildItem -Path Cert:\LocalMachine\My -Recurse | Where-Object {$_.FriendlyName -match "$CertFriendName"} | Select Thumbprint)
        }

        # Check for expiration 

        $curDate= Get-Date

        $CertHash= $certs | Where-Object {$_.notafter -le $curDate}

        $thumbprint= $CertHash.Thumbprint

        $appid=[guid]::NewGuid()

        # Mapping IPPort with Certhash
        & netsh http add sslcert ipport=0.0.0.0:$httpsPort certhash=$thumbprint "appid={$appid}"

        #binding the Site with SSL port
        New-WebBinding -Name $SiteName -Protocol https -Port $httpsPort 
        
        

        



Write-Host "Assign permissions to InetpubRoot"

cmd.exe /c "icacls $InetpubRoot /grant ${Apppooluser}:(OI)(CI)(RX)"

}

Function CreateWebsite-SentinelClient
{

$SiteName=$WebsiteData.Connect.IIS.SentinelClient.SiteName;
$InetpubRoot= $WebsiteData.Connect.IIS.SentinelClient.InetpubRoot;
$SiteID= $WebsiteData.Connect.IIS.SentinelClient.SiteID;
$AppPoolName=$WebsiteData.Connect.IIS.SentinelClient.AppPoolName;
$dotnetVersion=$WebsiteData.Connect.IIS.SentinelWebApi.DotNetVersion;
$httpPort=$WebsiteData.Connect.IIS.SentinelClient.HttpPort;
$httpsPort=$WebsiteData.Connect.IIS.SentinelClient.HttpsPort;
$CertFriendlyName=$WebsiteData.Connect.IIS.SentinelClient.Certificate;

<#
if ($WebsiteData.Connect.IIS.SentinelClient.HttpBinding -eq "Developer")
{
$httpBinding=[System.Net.Dns]::GetHostByName($env:COMPUTERNAME).HostName;
}
else
{
$httpBinding=$WebsiteData.Connect.IIS.SentinelClient.HttpBinding;
}#>

#$Apppooluser=$WebsiteData.Connect.IIS.SentinelClient.AppPoolAcctUser;
#$Apppoolpwd=$WebsiteData.Connect.IIS.SentinelClient.AppPoolAcctpwd;
$Apppooluser=$Srvusername;
$Apppoolpwd=$Srvpassword;
$winAuth=$WebsiteData.Connect.IIS.SentinelClient.windowsAuthentication;
$anoyAuth=$WebsiteData.Connect.IIS.SentinelClient.anonymousAuthentication;
$formsuth=$WebsiteData.Connect.IIS.SentinelClient.VirtualDirectory.ConnectSTS.FormsAuthentication;


$V1App=$WebsiteData.Connect.IIS.SentinelClient.VirtualDirectory.V1.Name;
$V1Root= $WebsiteData.Connect.IIS.SentinelClient.VirtualDirectory.V1.InetpubRoot


$V2App=$WebsiteData.Connect.IIS.SentinelClient.VirtualDirectory.V2.Name;

$V2Root= $WebsiteData.Connect.IIS.SentinelClient.VirtualDirectory.V2.InetpubRoot 


$ConnectSTSApp= $WebsiteData.Connect.IIS.SentinelClient.VirtualDirectory.ConnectSTS.Name;
$ConnectSTSRoot= $WebsiteData.Connect.IIS.SentinelClient.VirtualDirectory.ConnectSTS.InetpubRoot 


$DataAPIApp=$WebsiteData.Connect.IIS.SentinelClient.VirtualDirectory.DataAPI.Name;
$DataAPIRoot=$WebsiteData.Connect.IIS.SentinelClient.VirtualDirectory.DataAPI.InetpubRoot 




        
        if($WebsiteData.Connect.IIS.SentinelClient.Certificate -eq "Developer")
        {
        $domainname=$env:COMPUTERNAME
        $certs=@(Get-ChildItem -Path Cert:\LocalMachine\My -Recurse | Where-Object {$_.Subject -match "CN=$domainname"} | Select Thumbprint)
        $httphostname=[System.Net.Dns]::GetHostByName($env:COMPUTERNAME).HostName;
         $curDate= Get-Date
          $CertHash= $certs | Where-Object {$_.notafter -le $curDate}
          $thumbprint= $CertHash.Thumbprint
        }
        else
        {
        
        #$domainname=$certName;
        $certs=@(Get-ChildItem -Path Cert:\LocalMachine\My -Recurse | Where-Object {$_.FriendlyName -match "$CertFriendlyName"} | Select Thumbprint,Subject)
         $curDate= Get-Date
          $CertHash= $certs | Where-Object {$_.notafter -le $curDate}
          $thumbprint= $CertHash.Thumbprint
           $certdomain=$CertHash.Subject.Split(',')[0]
        $httphostname=$certdomain.Replace("CN=*",[string]::Concat("Connect-",$environment));
        }

    

Write-host " ***** SentinelClient website Properties ***** " 

Write-host "SiteName : "$SiteName
Write-host "SiteID : "$SiteID
Write-host "InetpubRoot : "$InetpubRoot
Write-host "AppPoolName : "$AppPoolName
Write-host ".NetVersion : "$dotnetVersion
Write-host "HttpPort : "$httpPort
Write-host "HttpsPort : "$httpsPort
#Write-host "httpBinding : "$httpBinding
Write-host "Apppool UserAccount : "$Apppooluser
Write-host "Windows Authencation : "$winAuth
Write-host "Anonymous Authencation : "$anoyAuth
Write-host "Certificate : "$CertFriendlyName
Write-host "Certificate Thumbprint : "$CertFriendlyName
Write-host "HttpHostname : "$httphostname

Write-host " ***** SentinelClient VDir Properties ***** " 

Write-Host "V1 : "$V1App
Write-Host "V1 PhysicalPath : "$V1Root
Write-Host "V2 : "$V2App
Write-Host "V2 PhysicalPath : "$V2Root
Write-Host "ConnectSTS : "$ConnectSTSApp
Write-Host "ConnectSTS PhysicalPath : "$ConnectSTSRoot
Write-Host "ConnectSTS Authentication : "$formsuth
Write-Host "DataAPI : "$DataAPIApp
Write-Host "DataAPIApp PhysicalPath : "$DataAPIRoot


        Write-Host "Check and create the $InetpubRoot" -ForegroundColor Green
        if (!(Test-Path -Path $InetpubRoot))
           {
            Write-Host "Creating Directory $InetpubRoot" -ForegroundColor Green
            New-Item -ItemType Directory -Force -Path $InetpubRoot
        }
        Else 
           { 
         Write-host "$InetpubRoot Exists"
        }

        # check and create Apppool
        Write-Host "Check and create Apppool $AppPoolName" -ForegroundColor Green
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


              # check and create website
            Write-Host "Check and create website $SiteName" -ForegroundColor Green

            $site = C:\Windows\System32\inetsrv\appcmd.exe list site /name:"$SiteName"
            if($site -eq $null)
            {
                Write-Host "Creating site: $SiteName"

                #$binding=(@{protocol="http";bindingInformation="*:${httpPort}:${httpBinding}"},@{protocol="https";bindingInformation="*:${httpsPort}:"})
                $binding=(@{protocol="http";bindingInformation="*:${httpPort}:$httphostname"})
                            new-item "iis:\sites\$SiteName" -type site -physicalPath "$InetPubRoot" -bindings $binding 
              

                #C:\Windows\System32\inetsrv\appcmd.exe add site /name:$SiteName /bindings:"http/*:8085:$httpBinding,https/*:443" /physicalPath:"$InetPubRoot" 
          }
            else
            {
	            Write-Host "WebSite" $SiteName "already exists. Skipping step"
          }


           # check and create V1 VDir path
        if (!(Test-Path -Path $V1Root))
           {
            Write-Host "Creating Directory $V1Root" -ForegroundColor Green
            New-Item -ItemType Directory -Force -Path $V1Root
        }
        Else 
           { 
         Write-host "$V1Root Exists"
          }

            # check and create V1 VDir
            Write-Host "Check and create VDir $V1App under $SiteName" -ForegroundColor Green

            $app = C:\Windows\System32\inetsrv\appcmd.exe list app /path:/"$V1App" /site.name:"$SiteName"
            if($app -eq $null)
            {
                Write-Host "Creating application: $V1App"
            C:\Windows\System32\inetsrv\appcmd.exe add app /site.name:$SiteName /path:/$V1App /physicalPath:"$V1Root"
            }
            else
            {
	            Write-Host "Application" $AppName "already exists. Skipping step"
            }



            # check and create V2 VDir path
        if (!(Test-Path -Path $V2Root))
           {
            Write-Host "Creating Directory $V2Root" -ForegroundColor Green
            New-Item -ItemType Directory -Force -Path $V2Root
        }
        Else 
           { 
         Write-host "$V2Root Exists"
          }

            # check and create v2 VDir
            Write-Host "Check and create VDir $V2App under $SiteName" -ForegroundColor Green
            $app = C:\Windows\System32\inetsrv\appcmd.exe list app /path:/"$V2App" /site.name:"$SiteName"
            if($app -eq $null)
            {
                Write-Host "Creating application: $V2App"
                C:\Windows\System32\inetsrv\appcmd.exe add app /site.name:$SiteName /path:/$V2App /physicalPath:"$V2Root"
            }
            else
            {
	            Write-Host "Application" $AppName "already exists. Skipping step"
            }


             # check and create DataAPI VDir path
        if (!(Test-Path -Path $DataAPIRoot))
           {
            Write-Host "Creating Directory $DataAPIRoot" -ForegroundColor Green
            New-Item -ItemType Directory -Force -Path $DataAPIRoot
        }
        Else 
           { 
         Write-host "$DataAPIRoot Exists"
          }
            # check and create DataAPI VDir
            Write-Host "Check and create VDir $DataAPIApp under $SiteName" -ForegroundColor Green
            $app = C:\Windows\System32\inetsrv\appcmd.exe list app /path:/"$DataAPIApp" /site.name:"$SiteName"
            if($app -eq $null)
            {
                Write-Host "Creating application: $DataAPIApp"
                C:\Windows\System32\inetsrv\appcmd.exe add app /site.name:$SiteName /path:/$DataAPIApp /physicalPath:"$DataAPIRoot"
            }
            else
            {
	            Write-Host "Application" $AppName "already exists. Skipping step"
            }


             # check and create DataAPI VDir path
        if (!(Test-Path -Path $ConnectSTSRoot))
           {
            Write-Host "Creating Directory $ConnectSTSRoot" -ForegroundColor Green
            New-Item -ItemType Directory -Force -Path $ConnectSTSRoot
        }
        Else 
           { 
         Write-host "$ConnectSTSRoot Exists"
          }
            # check and create ConnectSTS VDir
            Write-Host "Check and create VDir $ConnectSTSApp under $SiteName" -ForegroundColor Green
            $app = C:\Windows\System32\inetsrv\appcmd.exe list app /path:/"$ConnectSTSApp" /site.name:"$SiteName"
            if($app -eq $null)
            {
                Write-Host "Creating application: $ConnectSTSApp"
                C:\Windows\System32\inetsrv\appcmd.exe add app /site.name:$SiteName /path:/$ConnectSTSApp /physicalPath:"$ConnectSTSRoot"
            }
            else
            {
	            Write-Host "Application" $AppName "already exists. Skipping step"
            }


        Write-Host "Making changes to application pool: " $AppPoolName

        C:\Windows\System32\inetsrv\appcmd.exe set apppool "$AppPoolName" /managedRuntimeVersion:v4.0 /recycling.periodicRestart.time:00:00:00
       

        C:\Windows\System32\inetsrv\appcmd.exe set config /section:applicationPools "/[name='$AppPoolName'].processModel.identityType:SpecificUser" "/[name='$AppPoolName'].processModel.userName:$Apppooluser" "/[name='$AppPoolName'].processModel.password:$Apppoolpwd"


        Write-Host "Making changes to site: " $SiteName
        C:\Windows\System32\inetsrv\appcmd.exe set app "$SiteName/$V1App" /applicationPool:$AppPoolName
        C:\Windows\System32\inetsrv\appcmd.exe set app "$SiteName/$V2App" /applicationPool:$AppPoolName
        C:\Windows\System32\inetsrv\appcmd.exe set app "$SiteName/$DataAPIApp" /applicationPool:$AppPoolName
        C:\Windows\System32\inetsrv\appcmd.exe set app "$SiteName/$ConnectSTSApp" /applicationPool:$AppPoolName

        C:\Windows\System32\inetsrv\appcmd.exe set config "$SiteName" /section:windowsAuthentication /enabled:"$winAuth" /commit:apphost
        C:\Windows\System32\inetsrv\appcmd.exe set config "$SiteName" /section:anonymousAuthentication /enabled:"$anoyAuth" /commit:apphost

        Set-WebConfiguration system.web/authentication IIS:\Sites\$SiteName\$ConnectSTSApp -value @{mode=$formsuth}
       
       <#

        Write-Host "Retrive certificates"

        
        if($WebsiteData.Connect.IIS.Sentinel.Certificate -eq "Developer")
        {
        $domainname=$env:COMPUTERNAME
        $certs=@(Get-ChildItem -Path Cert:\LocalMachine\My -Recurse | Where-Object {$_.Subject -match "CN=$domainname"} | Select Thumbprint)
        }
        else
        {
        
        #$domainname=$certName;
        $certs=@(Get-ChildItem -Path Cert:\LocalMachine\My -Recurse | Where-Object {$_.FriendlyName -match "$CertFriendName"} | Select Thumbprint,Subject)
        }

        # Check for expiration 

        $curDate= Get-Date

        $CertHash= $certs | Where-Object {$_.notafter -le $curDate}

        $thumbprint= $CertHash.Thumbprint#>

        $appid=[guid]::NewGuid()

        # Mapping IPPort with Certhash
        & netsh http add sslcert ipport=0.0.0.0:$httpsPort certhash=$thumbprint "appid={$appid}"

        #binding the Site with SSL port
        New-WebBinding -Name $SiteName -Protocol https -Port $httpsPort 
        

Write-Host "Assign permissions to InetpubRoot"


# Include if you will be using a service account as the app pool identity
cmd.exe /c "icacls $InetpubRoot /grant ${Apppooluser}:(OI)(CI)(RX)"


[xml]$xmlDoc = New-Object system.Xml.XmlDocument
$xmlElt = $xmlDoc.CreateElement("ConfigData")
$xmlDoc.AppendChild($xmlElt);

$xmlElt1 = $xmlDoc.CreateElement("ConnectSTSURL")
#$ConnectSTSURL=[string]::Concat("https://",$httphostname,":",$httpsPort);
$xmlSubText = $xmlDoc.CreateTextNode($httphostname)
$xmlElt1.AppendChild($xmlSubText)

$xmlElt.AppendChild($xmlElt1);

$TempCgxmlpath="\\cha-en-vstpp\TempConfig"

if(Test-Path -Path (Join-Path $TempCgxmlpath "ConfigurableValues.xml") )
{
   Remove-Item -Path (Join-Path $TempCgxmlpath "ConfigurableValues.xml") -Force
}
$xmlDoc.Save((Join-Path $TempCgxmlpath "ConfigurableValues.xml"));

}

Function CreateWebsite-SentinelWebApi
{

$SiteName=$WebsiteData.Connect.IIS.SentinelWebApi.SiteName;
$InetpubRoot= $WebsiteData.Connect.IIS.SentinelWebApi.InetpubRoot;
$SiteID= $WebsiteData.Connect.IIS.SentinelWebApi.SiteID;
$AppPoolName=$WebsiteData.Connect.IIS.SentinelWebApi.AppPoolName;
$dotnetVersion=$WebsiteData.Connect.IIS.SentinelWebApi.DotNetVersion;
$httpPort=$WebsiteData.Connect.IIS.SentinelWebApi.HttpPort;
#$Apppooluser=$WebsiteData.Connect.IIS.SentinelWebApi.AppPoolAcctUser;
#$Apppoolpwd=$WebsiteData.Connect.IIS.SentinelWebApi.AppPoolAcctpwd;
$Apppooluser=$Srvusername;
$Apppoolpwd=$Srvpassword;
$winAuth=$WebsiteData.Connect.IIS.SentinelWebApi.windowsAuthentication;
$anoyAuth=$WebsiteData.Connect.IIS.SentinelWebApi.anonymousAuthentication;




Write-host " ***** SentinelWebApi website Properties ***** " 

Write-host "SiteName : "$SiteName
Write-host "SiteID : "$SiteID
Write-host "InetpubRoot : "$InetpubRoot
Write-host "AppPoolName : "$AppPoolName
Write-host ".NetVersion : "$dotnetVersion
Write-host "HttpPort : "$httpPort
Write-host "Apppool UserAccount : "$Apppooluser
Write-host "Windows Authencation : "$winAuth
Write-host "Anonymous Authencation : "$anoyAuth



        if (!(Test-Path -Path $InetpubRoot))
        {
            New-Item -ItemType Directory -Force -Path $InetpubRoot
        }
        Else 
        { 
            Write-host "Folder Exists"
        }

        # check and create Apppool
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


          # check and create website
        $site = C:\Windows\System32\inetsrv\appcmd.exe list site /name:"$SiteName"
        if($site -eq $null)
          {
                Write-Host "Creating site: $SiteName"
                C:\Windows\System32\inetsrv\appcmd.exe add site /name:$SiteName /bindings:"http/*:${httpPort}:" /physicalPath:"$InetPubRoot" 
          }
        else
          {
	            Write-Host "WebSite" $SiteName "already exists. Skipping step"
          }


        Write-Host "Making changes to application pool: " $AppPoolName

        C:\Windows\System32\inetsrv\appcmd.exe set apppool "$AppPoolName" /managedRuntimeVersion:v4.0 /recycling.periodicRestart.time:00:00:00

        C:\Windows\System32\inetsrv\appcmd.exe set config /section:applicationPools "/[name='$AppPoolName'].processModel.identityType:SpecificUser" "/[name='$AppPoolName'].processModel.userName:$Apppooluser" "/[name='$AppPoolName'].processModel.password:$Apppoolpwd"


        Write-Host "Making changes to site: " $SiteName
        C:\Windows\System32\inetsrv\appcmd.exe set app "$SiteName/" /applicationPool:$AppPoolName
        C:\Windows\System32\inetsrv\appcmd.exe set config "$SiteName" /section:windowsAuthentication /enabled:$winAuth /commit:apphost
        C:\Windows\System32\inetsrv\appcmd.exe set config "$SiteName" /section:anonymousAuthentication /enabled:$anoyAuth /commit:apphost
        

Write-Host "Assign permissions to InetpubRoot"


# Include if you will be using a service account as the app pool identity
cmd.exe /c "icacls $InetpubRoot /grant ${Apppooluser}:(OI)(CI)(RX)"

}



CreateIISWebSite -json $Json -environment $environment