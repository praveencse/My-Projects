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

    [string]$JsonFile=$(throw "Please provide Path to Json File")

)



Function CreateIISWebSite
{

write-host "Taking IIS Backup`n`n"
$date=get-date
$time='{0:yyyy-MM-dd---HH-mm-ss}' -f $date
Backup-WebConfiguration -name "$time"
Write-Host "`n`n"

#CreateWebsite-ConnectSTS

Import-Module WebAdministration

CreateWebsite-Sentinel

CreateWebsite-SentinelClient

CreateWebsite-SentinelWebApi

}



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

Function CreateWebsite-Sentinel
{

$SiteName = "Sentinel"
$InetpubRoot = Join-Path $Inetpub $SiteName
$AppPoolName = "Sentinel"
$anonymousAuthentication=$true
$windowsAuthentication=$false
$NETVERSION="v4.0"
$SITEID="2021"

Write-host "PROPERTIES FOR CREATING SENTINEL WEBSITE " -ForegroundColor Green
Write-host "SiteName : "$SiteName -ForegroundColor DarkYellow
Write-host "InetpubRoot : "$InetpubRoot -ForegroundColor DarkYellow
Write-host "AppPoolName : "$AppPoolName -ForegroundColor DarkYellow
Write-host "AnonymousAuthentication : "$anonymousAuthentication -ForegroundColor DarkYellow
Write-host "WindowsAuthentication : "$windowsAuthentication -ForegroundColor DarkYellow
Write-host "NETVERSION : "$NETVERSION -ForegroundColor DarkYellow
Write-host "SITEID : "$SITEID -ForegroundColor DarkYellow


        # CHECK AND CREATE PHYSICALPATH $InetpubRoot
        Write-Host "CHECK AND CREATE APPPOOL $InetpubRoot" -ForegroundColor Green
        if (!(Test-Path -Path $InetpubRoot))
        {
            New-Item -ItemType Directory -Force -Path $InetpubRoot
        }

        Else 
        { 
            Write-host "Folder Exists"
        }

        # CHECK AND CREATE APPPOOL "Sentinel"
        Write-Host "CHECK AND CREATE APPPOOL $AppPoolName" -ForegroundColor Green
        $pool = C:\Windows\System32\inetsrv\appcmd.exe list apppool /name:"$AppPoolName"
        if($pool -eq $null)
          {
                Write-Host "Creating app pool: $AppPoolName"
                #C:\Windows\System32\inetsrv\appcmd.exe add apppool /name:"$AppPoolName"
                
                New-Item "IIS:\AppPools\$AppPoolName" 
                Set-ItemProperty -Path IIS:\AppPools\$AppPoolName -Name managedRuntimeVersion -Value $NETVERSION
                
                
          }
        else
          {
	            Write-Host "Application pool" $AppPoolName "already exists. Skipping step"
          }


         # CHECK AND CREATE WEBSITE "Sentinel"
         Write-Host "CHECK AND CREATE APPPOOL $SiteName" -ForegroundColor Green
         $site = C:\Windows\System32\inetsrv\appcmd.exe list site /name:"$SiteName"
            if($site -eq $null)
              {
                Write-Host "Creating site: $SiteName"
          
                $binding=(@{protocol="http";bindingInformation="*:8081:"},@{protocol="https";bindingInformation="*:444:"},@{protocol="net.tcp";bindingInformation="*:808:"})
                new-item "iis:\sites\$SiteName" -type site -physicalPath "$InetPubRoot" -bindings $binding -id $SITEID
                
                Set-ItemProperty IIS:\Sites\$SiteName -Name EnabledProtocols -Value "http,net.tcp"
                Set-ItemProperty IIS:\Sites\$SiteName -name applicationPool -value $AppPoolName

                Set-WebConfigurationProperty -Filter "/system.webServer/security/authentication/anonymousAuthentication" -Name Enabled -Value $anonymousAuthentication -PSPath IIS:\ -Location "$SiteName"
                Set-WebConfigurationProperty -Filter "/system.webServer/security/authentication/windowsAuthentication" -Name Enabled -Value $windowsAuthentication -PSPath IIS:\ -Location "$SiteName"

                
             }
            else
              {
	                Write-Host "WebSite" $SiteName "already exists. Skipping step" -ForegroundColor Green
              }


        Write-Host "Making changes to application pool: " $AppPoolName

        C:\Windows\System32\inetsrv\appcmd.exe set config /section:applicationPools "/[name='$AppPoolName'].processModel.identityType:SpecificUser" "/[name='$AppPoolName'].processModel.userName:wse\centraluser" "/[name='$AppPoolName'].processModel.password:`$abcd1234"


        Write-Host "Assign permissions to InetpubRoot"

        cmd.exe /c "icacls $InetpubRoot /grant wse\centraluser:(OI)(CI)(RX)"

}

Function CreateWebsite-SentinelClient
{

$SiteName = "SentinelClient";
$InetpubRoot = Join-Path $Inetpub $SiteName
$AppPoolName = "SentinelClient"
$anonymousAuthentication=$true
$windowsAuthentication=$false
$NETVERSION="v4.0"

$V2App="V2"
$V2Root=Join-Path $InetpubRoot $V2App


$V1App="V1"
$V1Root=Join-Path $InetpubRoot $V1App

$ConnectSTSApp= "ConnectSTS"
$ConnectSTSRoot= Join-Path $InetpubRoot $ConnectSTSApp


$DataAPIApp="DataAPI"
$DataAPIRoot=Join-Path $InetpubRoot "DataAPI"



Write-host "PROPERTIES FOR CREATING SENTINELCLIENT WEBSITE AND VDIR'S [V1,V2,CONNECTSTS,DATAAPI]" -ForegroundColor Green

Write-host "SiteName : "$SiteName -ForegroundColor DarkYellow
Write-host "InetpubRoot : "$InetpubRoot -ForegroundColor DarkYellow
Write-host "AppPoolName : "$AppPoolName -ForegroundColor DarkYellow
Write-host "V2App : "$V2App -ForegroundColor DarkYellow
Write-host "V2Root : "$V2Root -ForegroundColor DarkYellow
Write-host "V1App : "$V1App -ForegroundColor DarkYellow
Write-host "V1Root : "$V1Root -ForegroundColor DarkYellow
Write-host "ConnectSTSApp : "$ConnectSTSApp -ForegroundColor DarkYellow
Write-host "ConnectSTSRoot : "$ConnectSTSRoot -ForegroundColor DarkYellow
Write-host "DataAPIApp : "$DataAPIApp -ForegroundColor DarkYellow
Write-host "DataAPIRoot : "$DataAPIRoot -ForegroundColor DarkYellow
Write-host "SentinelClienthostName : "$SentinelClienthostName -ForegroundColor DarkYellow
Write-host "AnonymousAuthentication : "$anonymousAuthentication -ForegroundColor DarkYellow
Write-host "WindowsAuthentication : "$windowsAuthentication -ForegroundColor DarkYellow
Write-host "NETVERSION : "$NETVERSION -ForegroundColor DarkYellow


            # CHECK AND CREATE PHYISICAL PATH
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

            # CHECK AND CREATE APPPOOL
            Write-Host "Check and create Apppool $AppPoolName" -ForegroundColor Green

                $pool = C:\Windows\System32\inetsrv\appcmd.exe list apppool /name:"$AppPoolName"
                if($pool -eq $null)
                  {
                        Write-Host "Creating app pool: $AppPoolName" -ForegroundColor Green
                        #C:\Windows\System32\inetsrv\appcmd.exe add apppool /name:"$AppPoolName"
                        New-Item "IIS:\AppPools\$AppPoolName" -ErrorAction Stop
                        Set-ItemProperty -Path IIS:\AppPools\$AppPoolName -Name managedRuntimeVersion -Value $NETVERSION -ErrorAction Stop
                  }
                else
                  {
	                    Write-Host "Application pool" $AppPoolName "already exists. Skipping step"
                  }


              # CHECK AND CREATE WEBSITE "SENTINELCLIENT"
              Write-Host "Check and create website $SiteName" -ForegroundColor Green

                $site = C:\Windows\System32\inetsrv\appcmd.exe list site /name:"$SiteName"
                if($site -eq $null)
                  {
                        Write-Host "Creating site: $SiteName"
                       # C:\Windows\System32\inetsrv\appcmd.exe add site /name:$SiteName /bindings:"http/*:8085,https/*:443:$SentinelClienthostName" /physicalPath:"$InetPubRoot" 

                       $binding=(@{protocol="http";bindingInformation="*:8085:$SentinelClienthostName"},@{protocol="https";bindingInformation="*:443:"})
                        new-item "iis:\sites\$SiteName" -type site -physicalPath "$InetPubRoot" -bindings $binding -id 2022
                
                        Set-ItemProperty IIS:\Sites\$SiteName -name applicationPool -value $AppPoolName

                        Set-WebConfigurationProperty -Filter "/system.webServer/security/authentication/anonymousAuthentication" -Name Enabled -Value $anonymousAuthentication -PSPath IIS:\ -Location "$SiteName"
                        Set-WebConfigurationProperty -Filter "/system.webServer/security/authentication/windowsAuthentication" -Name Enabled -Value $windowsAuthentication -PSPath IIS:\ -Location "$SiteName"

                  }
                else
                  {
	                    Write-Host "WebSite" $SiteName "already exists. Skipping step"
                  }


             # CHECK AND CREATE VDIR "V1"
              Write-Host "Check and create VDir $V1App under $SiteName" -ForegroundColor Green

              $app = C:\Windows\System32\inetsrv\appcmd.exe list app /path:/"$V1App" /site.name:"$SiteName"
                if($app -eq $null)
                {
                    Write-Host "Creating application: $V1App"
                    #C:\Windows\System32\inetsrv\appcmd.exe add app /site.name:$SiteName /path:/$V1App /physicalPath:"$V1Root"
                    New-Item IIS:\Sites\$SiteName\$V1App -Type Application -physicalPath $V1Root
                }
                else
                {
	                Write-Host "Application" $AppName "already exists. Skipping step"
                }



            # CHECK AND CREATE VDIR "V2"
            Write-Host "Check and create VDir $V2App under $SiteName" -ForegroundColor Green
             
              $app = C:\Windows\System32\inetsrv\appcmd.exe list app /path:/"$V2App" /site.name:"$SiteName"
                if($app -eq $null)
                {
                    Write-Host "Creating application: $V2App"
                #C:\Windows\System32\inetsrv\appcmd.exe add app /site.name:$SiteName /path:/$V2App /physicalPath:"$V2Root"
                New-Item IIS:\Sites\$SiteName\$V2App -Type Application -physicalPath $V2Root

                }
                else
                {
	                Write-Host "Application" $AppName "already exists. Skipping step"
                }

            # CHECK AND CREATE VDIR "DataAPIApp"
            Write-Host "Check and create VDir $DataAPIApp under $SiteName" -ForegroundColor Green

                $app = C:\Windows\System32\inetsrv\appcmd.exe list app /path:/"$DataAPIApp" /site.name:"$SiteName"
                if($app -eq $null)
                {
                    Write-Host "Creating application: $DataAPIApp"
                    
                    #C:\Windows\System32\inetsrv\appcmd.exe add app /site.name:$SiteName /path:/$DataAPIApp /physicalPath:"$DataAPIRoot"
                    New-Item IIS:\Sites\$SiteName\$DataAPIApp -Type Application -physicalPath $DataAPIRoot
                }
                else
                {
	                Write-Host "Application" $AppName "already exists. Skipping step"
                }

            # CHECK AND CREATE VDIR "ConnectSTS"
            Write-Host "Check and create VDir $ConnectSTSApp under $SiteName" -ForegroundColor Green
                
                $app = C:\Windows\System32\inetsrv\appcmd.exe list app /path:/"$ConnectSTSApp" /site.name:"$SiteName"
                if($app -eq $null)
                {
                    Write-Host "Creating application: $ConnectSTSApp"
                    #C:\Windows\System32\inetsrv\appcmd.exe add app /site.name:$SiteName /path:/$ConnectSTSApp /physicalPath:"$ConnectSTSRoot"
                    New-Item IIS:\Sites\$SiteName\$ConnectSTSApp -Type Application -physicalPath $ConnectSTSRoot
                }
                else
                {
	                Write-Host "Application" $AppName "already exists. Skipping step"
                }


        Write-Host "Making changes to application pool: " $AppPoolName

        #C:\Windows\System32\inetsrv\appcmd.exe set apppool "$AppPoolName" /managedRuntimeVersion:v4.0 /recycling.periodicRestart.time:00:00:00
       

        C:\Windows\System32\inetsrv\appcmd.exe set config /section:applicationPools "/[name='$AppPoolName'].processModel.identityType:SpecificUser" "/[name='$AppPoolName'].processModel.userName:wse\centraluser" "/[name='$AppPoolName'].processModel.password:`$abcd1234"


        Write-Host "Making changes to site: " $SiteName
        #C:\Windows\System32\inetsrv\appcmd.exe set app "$SiteName/" /applicationPool:$AppPoolName
        #C:\Windows\System32\inetsrv\appcmd.exe set config "$SiteName" /section:windowsAuthentication /enabled:false /commit:apphost
        #C:\Windows\System32\inetsrv\appcmd.exe set config "$SiteName" /section:anonymousAuthentication /enabled:true /commit:apphost
       


Write-Host "Assign permissions to InetpubRoot"


# Include if you will be using a service account as the app pool identity
cmd.exe /c "icacls $InetpubRoot /grant wse\centraluser:(OI)(CI)(RX)"

}

Function CreateWebsite-SentinelWebApi
{

$SiteName = "SentinelWebAPI"
$InetpubRoot = Join-Path $Inetpub "DataAPI"
$AppPoolName = "SentinelWebAPI"
$anonymousAuthentication=$true
$windowsAuthentication=$false
$NETVERSION="v4.0"
$SITEID="2023"


Write-host "PROPERTIES FOR CREATING SentinelWebAPI WEBSITE " -ForegroundColor Green
Write-host "SiteName : "$SiteName -ForegroundColor DarkYellow
Write-host "InetpubRoot : "$InetpubRoot -ForegroundColor DarkYellow
Write-host "AppPoolName : "$AppPoolName -ForegroundColor DarkYellow
Write-host "AnonymousAuthentication : "$anonymousAuthentication -ForegroundColor DarkYellow
Write-host "WindowsAuthentication : "$windowsAuthentication -ForegroundColor DarkYellow
Write-host "NETVERSION : "$NETVERSION -ForegroundColor DarkYellow



        # CHECK AND CREATE PHYSICALPATH $InetpubRoot
        Write-Host "CHECK AND CREATE APPPOOL $InetpubRoot" -ForegroundColor Green
            if (!(Test-Path -Path $InetpubRoot))
                {
                    New-Item -ItemType Directory -Force -Path $InetpubRoot -ErrorAction Stop
                }
            Else 
                { 
                Write-host "Folder Exists"
                }

        # CHECK AND CREATE PHYSICALPATH SentinelWebAPI
        Write-Host "CHECK AND CREATE APPPOOL $AppPoolName" -ForegroundColor Green

            $pool = C:\Windows\System32\inetsrv\appcmd.exe list apppool /name:"$AppPoolName"
            if($pool -eq $null)
              {
                    Write-Host "Creating app pool: $AppPoolName"
                    #C:\Windows\System32\inetsrv\appcmd.exe add apppool /name:"$AppPoolName"

                    New-Item "IIS:\AppPools\$AppPoolName" -ErrorAction Stop

                    Set-ItemProperty -Path IIS:\AppPools\$AppPoolName -Name managedRuntimeVersion -Value $NETVERSION -ErrorAction Stop
                
              }
            else
              {
	                Write-Host "Application pool" $AppPoolName "already exists. Skipping step"
              }


        # CHECK AND CREATE WEBSITE "SentinelWebAPI"
         Write-Host "CHECK AND CREATE APPPOOL $SiteName" -ForegroundColor Green

            $site = C:\Windows\System32\inetsrv\appcmd.exe list site /name:"$SiteName"
            if($site -eq $null)
              {
                    Write-Host "Creating site: $SiteName"
                    #C:\Windows\System32\inetsrv\appcmd.exe add site /name:$SiteName /bindings:"http/*:8080:" /physicalPath:"$InetPubRoot" /id:$SiteID

                     $binding=(@{protocol="http";bindingInformation="*:8080:"})
                     new-item "iis:\sites\$SiteName" -type site -physicalPath "$InetPubRoot" -bindings $binding -id $SITEID -ErrorAction Stop
                
                     
                     Set-ItemProperty IIS:\Sites\$SiteName -name applicationPool -value $AppPoolName -ErrorAction Stop

                     Set-WebConfigurationProperty -Filter "/system.webServer/security/authentication/anonymousAuthentication" -Name Enabled -Value $anonymousAuthentication -PSPath IIS:\ -Location "$SiteName" -ErrorAction Stop
                     Set-WebConfigurationProperty -Filter "/system.webServer/security/authentication/windowsAuthentication" -Name Enabled -Value $windowsAuthentication -PSPath IIS:\ -Location "$SiteName" -ErrorAction Stop

              }
            else
              {
	                Write-Host "WebSite" $SiteName "already exists. Skipping step"
              }


        Write-Host "Making changes to application pool: " $AppPoolName

        C:\Windows\System32\inetsrv\appcmd.exe set config /section:applicationPools "/[name='$AppPoolName'].processModel.identityType:SpecificUser" "/[name='$AppPoolName'].processModel.userName:wse\centraluser" "/[name='$AppPoolName'].processModel.password:`$abcd1234"

     

        Write-Host "Assign permissions to InetpubRoot"


        cmd.exe /c "icacls $InetpubRoot /grant wse\centraluser:(OI)(CI)(RX)"

}





CreateIISWebSite