 <#
.SYNOPSIS
Update the sql scripts on newly created database with updated version.
.DESCRIPTION
This function will update the database with new uodated sql scripts.
Throws an exception if the update fails.
.EXAMPLE
.\Provision-WebJob.ps1 -IsHA $IsHA -JsonFilePath $JsonFilePath
	
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



Function CreateIISWebSite
{

$jsonfile= Join-Path $json ([string]::Concat("Connect",$environment,".json")) -ErrorAction stop
$global:WebsiteData= ConvertFrom-Json -InputObject (gc $jsonfile -Raw) -ErrorAction Stop


write-host "Taking IIS Backup`n`n"
$date=get-date
$time='{0:yyyy-MM-dd---HH-mm-ss}' -f $date
#Backup-WebConfiguration -name "$time"
Write-Host "`n`n"


Import-Module WebAdministration

CreateWebsite-Sentinel 

#CreateWebsite-SentinelClient

#CreateWebsite-SentinelWebApi

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

Function CreateWebsite-Sentinel()
{

$SiteName=$WebsiteData.Connect.IIS.Sentinel.SiteName;
$InetpubRoot= Join-Path $WebsiteData.Connect.IIS.Sentinel.InetpubRoot $SiteName;
$SiteID= $WebsiteData.Connect.IIS.Sentinel.SiteID;
$AppPoolName=$WebsiteData.Connect.IIS.Sentinel.AppPoolName;
$dotnetVersion=$WebsiteData.Connect.IIS.Sentinel.DotNetVersion;
$httpPort=$WebsiteData.Connect.IIS.Sentinel.HttpPort;
$httpsPort=$WebsiteData.Connect.IIS.Sentinel.HttpsPort;
$nettcpport=$WebsiteData.Connect.IIS.Sentinel.NetTcpPort;
$Apppooluser=$WebsiteData.Connect.IIS.Sentinel.AppPoolAcctUser;
$Apppoolpwd=$WebsiteData.Connect.IIS.Sentinel.AppPoolAcctpwd;
$winAuth=$WebsiteData.Connect.IIS.Sentinel.windowsAuthentication;
$anoyAuth=$WebsiteData.Connect.IIS.Sentinel.anonymousAuthentication;

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
               
                           
                            #$binding=(@{protocol="http";bindingInformation="*:8081:"},@{protocol="https";bindingInformation="*:444:"},@{protocol="net.tcp";bindingInformation="*:808:"})
                            $binding=(@{protocol="http";bindingInformation="*:${httpPort}:"},@{protocol="https";bindingInformation="*:${httpsPort}:"},@{protocol="net.tcp";bindingInformation="*:${nettcpport}:"})
                            new-item "iis:\sites\$SiteName" -type site -physicalPath "$InetPubRoot" -bindings $binding -id $SiteID
              
                            Set-ItemProperty IIS:\Sites\$SiteName -Name EnabledProtocols -Value "http,net.tcp"

                # Appcmd cmds
                <#
                 #Write-Host "C:\Windows\System32\inetsrv\appcmd.exe add site /name:$SiteName /bindings:"http/*:8081:,https/*:444:" /physicalPath:"$InetPubRoot" "
                            #C:\Windows\System32\inetsrv\appcmd.exe add site /name:$SiteName /bindings:"http/*:8081:,https/*:444:" /physicalPath:"$InetPubRoot" 
                              #C:\Windows\System32\inetsrv\appcmd.exe set site "$SiteName" +bindings.[protocol='net.tcp',bindingInformation='808:*']
                #Set-ItemProperty IIS:\Sites\$SiteName -Name bindings -Value @{protocol="net.tcp"; bindingInformation="808:*"} 
                #C:\Windows\System32\inetsrv\appcmd.exe set config -section:system.applicationHost/sites /+"[name='$SiteName'].bindings.[protocol='net.tcp',bindingInformation='*:808:']" /commit:apphost
                #C:\Windows\System32\inetsrv\appcmd.exe set app "$SiteName/" /enabledProtocols:http,net.tcp
                #>
                
          }
        else
          {
	            Write-Host "WebSite" $SiteName "already exists. Skipping step"
          }


        Write-Host "Making changes to application pool: " $AppPoolName

        C:\Windows\System32\inetsrv\appcmd.exe set apppool "$AppPoolName" /managedRuntimeVersion:$dotnetVersion /recycling.periodicRestart.time:00:00:00

        C:\Windows\System32\inetsrv\appcmd.exe set config /section:applicationPools "/[name='$AppPoolName'].processModel.identityType:SpecificUser" "/[name='$AppPoolName'].processModel.userName:$Apppooluser" "/[name='$AppPoolName'].processModel.password:$Apppoolpwd"


        Write-Host "Making changes to site: " $SiteName
        C:\Windows\System32\inetsrv\appcmd.exe set app "$SiteName/" /applicationPool:$AppPoolName
        C:\Windows\System32\inetsrv\appcmd.exe set config "$SiteName" /section:windowsAuthentication /enabled:$winAuth /commit:apphost
        C:\Windows\System32\inetsrv\appcmd.exe set config "$SiteName" /section:anonymousAuthentication /enabled:$anoyAuth /commit:apphost
        



Write-Host "Assign permissions to InetpubRoot"

cmd.exe /c "icacls $InetpubRoot /grant ${Apppooluser}:(OI)(CI)(RX)"

}

Function CreateWebsite-SentinelClient
{

$SiteName=$WebsiteData.Connect.IIS.SentinelClient.SiteName;
$InetpubRoot= Join-Path $WebsiteData.Connect.IIS.SentinelClient.InetpubRoot $SiteName;
$SiteID= $WebsiteData.Connect.IIS.SentinelClient.SiteID;
$AppPoolName=$WebsiteData.Connect.IIS.SentinelClient.AppPoolName;
$dotnetVersion=$WebsiteData.Connect.IIS.SentinelWebApi.DotNetVersion;
$httpPort=$WebsiteData.Connect.IIS.SentinelClient.HttpPort;
$httpsPort=$WebsiteData.Connect.IIS.SentinelClient.HttpsPort;
$httpBinding=$WebsiteData.Connect.IIS.SentinelClient.HttpBinding;
$Apppooluser=$WebsiteData.Connect.IIS.SentinelClient.AppPoolAcctUser;
$Apppoolpwd=$WebsiteData.Connect.IIS.SentinelClient.AppPoolAcctpwd;
$winAuth=$WebsiteData.Connect.IIS.SentinelClient.windowsAuthentication;
$anoyAuth=$WebsiteData.Connect.IIS.SentinelClient.anonymousAuthentication;


$V1App=$WebsiteData.Connect.IIS.SentinelClient.VirtualDirectory.V1.Name;
$V1Root= Join-Path $WebsiteData.Connect.IIS.SentinelClient.VirtualDirectory.V1.InetpubRoot $V1App


$V2App=$WebsiteData.Connect.IIS.SentinelClient.VirtualDirectory.V2.Name;

$V2Root=Join-Path $WebsiteData.Connect.IIS.SentinelClient.VirtualDirectory.V2.InetpubRoot $V2App


$ConnectSTSApp= $WebsiteData.Connect.IIS.SentinelClient.VirtualDirectory.ConnectSTS.Name;
$ConnectSTSRoot= Join-Path $WebsiteData.Connect.IIS.SentinelClient.VirtualDirectory.ConnectSTS.InetpubRoot $ConnectSTSApp


$DataAPIApp=$WebsiteData.Connect.IIS.SentinelClient.VirtualDirectory.DataAPI.Name;
$DataAPIRoot=Join-Path $WebsiteData.Connect.IIS.SentinelClient.VirtualDirectory.DataAPI.InetpubRoot $DataAPIApp


Write-host " ***** SentinelClient website Properties ***** " 

Write-host "SiteName : "$SiteName
Write-host "SiteID : "$SiteID
Write-host "InetpubRoot : "$InetpubRoot
Write-host "AppPoolName : "$AppPoolName
Write-host ".NetVersion : "$dotnetVersion
Write-host "HttpPort : "$httpPort
Write-host "HttpsPort : "$httpsPort
Write-host "httpBinding : "$httpBinding
Write-host "Apppool UserAccount : "$Apppooluser
Write-host "Windows Authencation : "$winAuth
Write-host "Anonymous Authencation : "$anoyAuth

Write-host " ***** SentinelClient VDir Properties ***** " 

Write-Host "V1 : "$V1App
Write-Host "V1 PhysicalPath : "$V1Root
Write-Host "V2 : "$V2App
Write-Host "V2 PhysicalPath : "$V2Root
Write-Host "ConnectSTS : "$ConnectSTSApp
Write-Host "ConnectSTS PhysicalPath : "$ConnectSTSRoot
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

                $binding=(@{protocol="http";bindingInformation="*:${httpPort}:${httpBinding}"},@{protocol="https";bindingInformation="*:${httpsPort}:"})
                            new-item "iis:\sites\$SiteName" -type site -physicalPath "$InetPubRoot" -bindings $binding -id $SiteID
              

                #C:\Windows\System32\inetsrv\appcmd.exe add site /name:$SiteName /bindings:"http/*:8085:$httpBinding,https/*:443" /physicalPath:"$InetPubRoot" 
          }
            else
            {
	            Write-Host "WebSite" $SiteName "already exists. Skipping step"
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

        C:\Windows\System32\inetsrv\appcmd.exe set apppool "$AppPoolName" /managedRuntimeVersion:$dotnetVersion /recycling.periodicRestart.time:00:00:00
       

        C:\Windows\System32\inetsrv\appcmd.exe set config /section:applicationPools "/[name='$AppPoolName'].processModel.identityType:SpecificUser" "/[name='$AppPoolName'].processModel.userName:$Apppooluser" "/[name='$AppPoolName'].processModel.password:$Apppoolpwd"


        Write-Host "Making changes to site: " $SiteName
        C:\Windows\System32\inetsrv\appcmd.exe set app "$SiteName/$V1App" /applicationPool:$AppPoolName
        C:\Windows\System32\inetsrv\appcmd.exe set app "$SiteName/$V2App" /applicationPool:$AppPoolName
        C:\Windows\System32\inetsrv\appcmd.exe set app "$SiteName/$DataAPIApp" /applicationPool:$AppPoolName
        C:\Windows\System32\inetsrv\appcmd.exe set app "$SiteName/$ConnectSTSApp" /applicationPool:$AppPoolName

        C:\Windows\System32\inetsrv\appcmd.exe set config "$SiteName" /section:windowsAuthentication /enabled:$winAuth /commit:apphost
        C:\Windows\System32\inetsrv\appcmd.exe set config "$SiteName" /section:anonymousAuthentication /enabled:$anoyAuth /commit:apphost
       


Write-Host "Assign permissions to InetpubRoot"


# Include if you will be using a service account as the app pool identity
cmd.exe /c "icacls $InetpubRoot /grant ${Apppooluser}:(OI)(CI)(RX)"

}

Function CreateWebsite-SentinelWebApi
{

$SiteName=$WebsiteData.Connect.IIS.SentinelWebApi.SiteName;
$InetpubRoot= Join-Path $WebsiteData.Connect.IIS.SentinelWebApi.InetpubRoot $SiteName;
$SiteID= $WebsiteData.Connect.IIS.SentinelWebApi.SiteID;
$AppPoolName=$WebsiteData.Connect.IIS.SentinelWebApi.AppPoolName;
$dotnetVersion=$WebsiteData.Connect.IIS.SentinelWebApi.DotNetVersion;
$httpPort=$WebsiteData.Connect.IIS.SentinelWebApi.HttpPort;
$Apppooluser=$WebsiteData.Connect.IIS.SentinelWebApi.AppPoolAcctUser;
$Apppoolpwd=$WebsiteData.Connect.IIS.SentinelWebApi.AppPoolAcctpwd;
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
                C:\Windows\System32\inetsrv\appcmd.exe add site /name:$SiteName /bindings:"http/*:$httpPort" /physicalPath:"$InetPubRoot" /id:$SiteID
          }
        else
          {
	            Write-Host "WebSite" $SiteName "already exists. Skipping step"
          }


        Write-Host "Making changes to application pool: " $AppPoolName

        C:\Windows\System32\inetsrv\appcmd.exe set apppool "$AppPoolName" /managedRuntimeVersion:$dotnetVersion /recycling.periodicRestart.time:00:00:00

        C:\Windows\System32\inetsrv\appcmd.exe set config /section:applicationPools "/[name='$AppPoolName'].processModel.identityType:SpecificUser" "/[name='$AppPoolName'].processModel.userName:$Apppooluser" "/[name='$AppPoolName'].processModel.password:$Apppoolpwd"


        Write-Host "Making changes to site: " $SiteName
        C:\Windows\System32\inetsrv\appcmd.exe set app "$SiteName/" /applicationPool:$AppPoolName
        C:\Windows\System32\inetsrv\appcmd.exe set config "$SiteName" /section:windowsAuthentication /enabled:$winAuth /commit:apphost
        C:\Windows\System32\inetsrv\appcmd.exe set config "$SiteName" /section:anonymousAuthentication /enabled:$anoyAuth /commit:apphost
        

Write-Host "Assign permissions to InetpubRoot"


# Include if you will be using a service account as the app pool identity
cmd.exe /c "icacls $InetpubRoot /grant ${Apppooluser}:(OI)(CI)(RX)"

}



CreateIISWebSite