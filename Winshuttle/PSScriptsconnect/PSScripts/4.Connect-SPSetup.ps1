<#
.SYNOPSIS
Update the sql scripts on newly created database with updated version.
.DESCRIPTION
This function will update the database with new uodated sql scripts.
Throws an exception if the update fails.
.EXAMPLE
.\CreateSP-WebApplication -Serviceaccount $Serviceaccount -SPWebAppName $SPWebAppName -SPWebAppPort $SPWebAppPort -SPSiteCollectionName $SPSiteCollectionName 
	
.NOTES
Author:		Padma P Peddigari
Version:    1.0
#>
param(
   
    [string]$Json=$(throw "please provide path to Json file"),
    [string]$environment=$(throw "Please provide Environment"),
    [string]$Buildversion=$(throw "Please build version "),
    [string]$Branch=$(throw "Please pass branch"),
    [string]$configuration=$(throw "Please pass cpnfiguration"),
    [String]$ACSLoginURL=$(throw "Please pass the ACS Login URL"),
    [string]$Srvusername=$(throw "Please pass Service account UserName"),
    [string]$Secondaryusername=$(throw "Please pass Secondary username"),
    [string]$CntDefaultAdmin=$(throw "Please pass ConnectDefaultAdmin"),
    [string]$CntDefaultAdminEmail=$(throw "Please pass ConnectDefaultAdminEmail"),
    [string]$centralbinariespath=$(throw "Please provide binaries location")  
   
 
  

)

Function CreateSP-WebApplication
{

try
 {  Write-host "here"

        $jsonfile= Join-Path $json ([string]::Concat("Json\Connect",$environment,".json")) -ErrorAction stop
       
        $file= Get-Content -Path $jsonfile
#        $global:WebsiteData= ConvertFrom-Json -InputObject (gc $jsonfile -Raw) -ErrorAction Stop
          
        [System.Reflection.Assembly]::LoadWithPartialName("System.web.extensions")
        $serializer=New-Object System.Web.Script.Serialization.JavaScriptSerializer

        $WebsiteData= $serializer.DeserializeObject($file)
        
        Add-PsSnapin Microsoft.SharePoint.PowerShell
        # Set variables

        $SPWebApplicationName = [string]::Concat($WebsiteData.Connect.SharePoint.WebApplication.Name," - ",$WebsiteData.Connect.SharePoint.WebApplication.Port);
        $SPWebApplicationPort = $WebsiteData.Connect.SharePoint.WebApplication.Port;
     $SPWebApplicationAppPool = $SPWebApplicationName;
      #  $SPWebApplicationAccount =$WebsiteData.Connect.SharePoint.WebApplication.ServiceAccount;
        $SPWebApplicationAccount =$Srvusername;
        $ssl = $false
        $CertFriendlyName=$WebsiteData.Connect.SharePoint.WebApplication.Certificate;
        

        $SPWebExists=Get-SPWebApplication -Identity $SPWebApplicationName -ErrorAction SilentlyContinue

        if ($SPWebExists -eq $null)
        {
        Write-host "Displaying SP WebApplcation Properties" -ForegroundColor Blue
        Write-Host "SPWebApplicationName : "$SPWebApplicationName  -ForegroundColor Green
        Write-Host "SPWebApplicationPort : "$SPWebApplicationPort -ForegroundColor Green
        Write-Host "SPWebApplicationAppPool : "$SPWebApplicationAppPool -ForegroundColor Green
        Write-Host "SPWebApplicationAccount : "$SPWebApplicationAccount -ForegroundColor Green

        #$authencationprovider = New-SPAuthenticationProvider -UseWindowsIntegratedAuthentication -DisableKerberos
        $authencationprovider = New-SPAuthenticationProvider 

        Write-host "Checking Sharepoint WebApplication exists or not" -ForegroundColor Green
        Write-host "Create a new Sharepoint WebApplication" -ForegroundColor Green
        write-host "New-SPWebApplication -Name $SPWebApplicationName -Port $SPWebApplicationPort -ApplicationPool $SPWebApplicationAppPool -AuthenticationMethod NTLM -AuthenticationProvider $authencationprovider -AllowAnonymousAccess -SecureSocketsLayer -ApplicationPoolAccount $SPWebApplicationAccount" -ForegroundColor Green  
        $IISPath=[string]::Concat("C:\inetpub\wwwroot\wss\VirtualDirectories\",$SPWebApplicationPort);
        #$SiteURL= New-SPWebApplication -Url $url -Name $SPWebApplicationName -Port $SPWebApplicationPort -ApplicationPool $SPWebApplicationAppPool -AuthenticationMethod NTLM -AuthenticationProvider $authencationprovider -AllowAnonymousAccess $true -SecureSocketsLayer $ssl -ApplicationPoolAccount $SPWebApplicationAccount  | select URL      
        $SiteURL= New-SPWebApplication -Name $SPWebApplicationName -Port $SPWebApplicationPort -Path $IISPath -ApplicationPool $SPWebApplicationAppPool -AuthenticationProvider $authencationprovider -AllowAnonymousAccess -SecureSocketsLayer -ApplicationPoolAccount (get-SPManagedAccount $SPWebApplicationAccount)  | select URL      
        $SPWebURL=$SiteURL.Url

        <#
                 if($WebsiteData.Connect.SharePoint.WebApplication.Certificate -eq "Developer")
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
                 
            $appid=[guid]::NewGuid()

            # Mapping IPPort with Certhash
            & netsh http add sslcert ipport=0.0.0.0:$SPWebApplicationPort certhash=$thumbprint "appid={$appid}"

            #binding the Site with SSL port
            New-WebBinding -Name $SiteName -Protocol https -Port $httpsPort 
            #>
         
        }

        else
        {
        Write-host "SP Web Applcation $SPWebApplicationName already exists"
        $SPWebURL=$SPWebExists.Url
        }

        Write-Host "created SPWebapplication  : "$SPWebURL -ForegroundColor Green

        $spsiteexists= Get-SPSite $SPWebURL -ErrorAction SilentlyContinue

        $SPSiteCollectionName = $WebsiteData.Connect.SharePoint.RootSiteCollection.Name;
        $SPSiteCollectionTemplate = $WebsiteData.Connect.SharePoint.RootSiteCollection.SiteCollectionTemplate;
        $SPSiteCollectionLanguage = $WebsiteData.Connect.SharePoint.RootSiteCollection.SiteCollectionLang;
        #$SPSiteCollectionSEcAlias=$WebsiteData.Connect.SharePoint.RootSiteCollection.SecondaryAlias;
        $SPSiteCollectionSEcAlias=$Secondaryusername;
#        $OwnerAlias=$WebsiteData.Connect.SharePoint.RootSiteCollection.OwnerAlias;
        $OwnerAlias=$Srvusername;

        if ($spsiteexists -eq $null )
        {
            Write-host "Displaying SP Site Collection Properties" -ForegroundColor Yellow
            Write-Host "SPSiteCollectionName     : "$SPSiteCollectionName  -ForegroundColor Green
            Write-Host "SPSiteCollectionTemplate : "$SPSiteCollectionTemplate -ForegroundColor Green
            Write-Host "SPSiteCollectionLanguage : "$SPSiteCollectionLanguage -ForegroundColor Green
            Write-Host "SPWebApplicationAccount  : "$SPWebApplicationAccount -ForegroundColor Green

    
            # Create a new Sharepoint Site Collection

            #New-SPSite -Description -Url -Language -Template -Name -QuotaTemplate -OwnerEmail -OwnerAlias -SecondaryEmail -SecondaryOwnerAlias -HostHeaderWebApplication -ContentDatabase -SiteSubscription -AdministrationSiteType -AssignmentCollection -Verbose -Debug -ErrorAction -WarningAction -ErrorVariable -WarningVariable -OutVariable -OutBuffer
            #New-SPSite -Description "Root" -Url -Language -Template -Name -QuotaTemplate -OwnerEmail -OwnerAlias -SecondaryEmail -SecondaryOwnerAlias -HostHeaderWebApplication -ContentDatabase -SiteSubscription -AdministrationSiteType -AssignmentCollection -Verbose -Debug -ErrorAction -WarningAction -ErrorVariable -WarningVariable -OutVariable -OutBuffer
            Write-host "New-SPSite -URL $SPWebURL -OwnerAlias $OwnerAlias -Language $SPSiteCollectionLanguage -Template $SPSiteCollectionTemplate -Name $SPSiteCollectionName -SecondaryOwnerAlias "$SPSiteCollectionSEcAlias" " -ForegroundColor Green
                        New-SPSite -URL $SPWebURL -OwnerAlias $OwnerAlias -Language $SPSiteCollectionLanguage -Template $SPSiteCollectionTemplate -Name $SPSiteCollectionName -SecondaryOwnerAlias "$SPSiteCollectionSEcAlias"
        }

        else
        {
            Write-host "SP Sitecollection already exists"
         }
                                

        
        Write-Host "Deploying WSP Start"
        $pspath= Join-Path $json "PSScripts"

& "$pspath\5.Connect-DeployWSP.ps1" -Buildversion $Buildversion -Branch $Branch -configuration $configuration -centralbinariespath $centralbinariespath
      
Write-Host "Deploying WSP Complete"  

$SPCntAdminSite=[string]::Concat($SPWebURL,"sites/connectadmin");
#$SPOwnerAlias = $WebsiteData.Connect.SharePoint.AdminSiteCollection.OwnerAlias;
$SPOwnerAlias = $Srvusername;
$SPSiteCollectionLang = $WebsiteData.Connect.SharePoint.AdminSiteCollection.SiteCollectionLang;
$SPSiteCollectionTemplate = $WebsiteData.Connect.SharePoint.AdminSiteCollection.SiteCollectionTemplate;
$SPadminName = $WebsiteData.Connect.SharePoint.AdminSiteCollection.Name;
#$SPSecalias = $WebsiteData.Connect.SharePoint.AdminSiteCollection.SecondaryAlias;
$SPSecalias = $Secondaryusername;

Write-Host " ***** Properties for creating SP Connect Admin Site Collection ***** "
Write-Host " SPadmin site Name:"$SPadminName
Write-Host " SPadmin site URL:"$SPCntAdminSite
Write-Host " SPadmin site Owner:"$SPOwnerAlias
Write-Host " SPadmin site Language:"$SPSiteCollectionLang
Write-Host " SPadmin site Template:"$SPSiteCollectionTemplate
Write-Host " SPadmin site SEcondary Owner:"$SPSecalias

Write-host "New-SPSite -url $SPCntAdminSite -OwnerAlias $SPOwnerAlias -Language $SPSiteCollectionLang -Template $SPSiteCollectionTemplate -Name $SPadminName -SecondaryOwnerAlias $SPSecalias"
New-SPSite -url $SPCntAdminSite -OwnerAlias $SPOwnerAlias -Language $SPSiteCollectionLang -Template $SPSiteCollectionTemplate -Name $SPadminName -SecondaryOwnerAlias $SPSecalias

Write-host "SPAdmin is created"
 
 $TempCgxmlpath="\\cha-en-vstpp\TempConfig"
        
         [xml]$xmldoc= Get-Content -Path (Join-Path $TempCgxmlpath "ConfigurableValues.xml")
         if($xmldoc.ConfigData.SPWebURL -ne $null)
         {
             $Deleteelement = "SPWebURL"
                 ($xmldoc.ConfigData.ChildNodes | Where-Object { $Deleteelement -contains $_.Name }) | ForEach-Object {[void]$_.ParentNode.RemoveChild($_)}
                # Remove each node from its parent
                
          }
           if($xmldoc.ConfigData.SPConnectAdminSiteURL -ne $null)
         {
             $Deleteelement2 = "SPConnectAdminSiteURL"
                 ($xmldoc.ConfigData.ChildNodes |Where-Object { $Deleteelement2 -contains $_.Name }) | ForEach-Object {[void]$_.ParentNode.RemoveChild($_)}
                # Remove each node from its parent
                
          }

         $xmldoc.Save((Join-Path $TempCgxmlpath "ConfigurableValues.xml"))
         [xml]$xmldoc= Get-Content -Path (Join-Path $TempCgxmlpath "ConfigurableValues.xml")
         $secondelt=$xmldoc.CreateElement("SPWebURL")
         $secondtxt=$xmldoc.CreateTextNode($SPWebURL)
         $secondelt.AppendChild($secondtxt);

         $SPAdminsiteelt=$xmldoc.CreateElement("SPConnectAdminSiteURL")
         $SPAdminsitetxt=$xmldoc.CreateTextNode($SPCntAdminSite)
         $SPAdminsiteelt.AppendChild($SPAdminsitetxt);

         $xmldoc.ConfigData.AppendChild($secondelt);
         $xmldoc.ConfigData.AppendChild($SPAdminsiteelt);

         $xmldoc.Save((Join-Path $TempCgxmlpath "ConfigurableValues.xml"))

         $cs=Get-SPWebApplication -IncludeCentralAdministration | Where { $_.IsAdministrationWebApplication }
         $smtpserver="smtp.office365.com";
         $smtpport="587";
         $cs.UpdateMailSettings($smtpserver,"noreply@winshuttle.com","noreply@winshuttle.com",$smtpport)

         #Creating winshuttle Admin
         $ConnectSTSURL=$xmldoc.ConfigData.ConnectSTSURL;
         $ConnectServiceBaseURL=[string]::Concat("http://",$ConnectSTSURL,":",$WebsiteData.Connect.IIS.Sentinel.HttpPort,"/");
         #$ConnectAdminEmail=$WebsiteData.Connect.SharePoint.AdminSiteCollection.AdminEmail;
         $ConnectAdminEmail=$CntDefaultAdminEmail;
#         $ConnectDefaultAdmin=$WebsiteData.Connect.SharePoint.AdminSiteCollection.ConnectDefaultAdmin;
         $ConnectDefaultAdmin=$CntDefaultAdmin;

         $Prefix="i:05.t|winshuttle acs|"
         $settingsfilepath= Join-Path "$json" "Utilities\Admin creation Utility\Settings.ini"

         (Get-Content (Join-Path $json "Utilities\Admin creation Utility\Settingsdefault.ini")) -replace "SPConnectAdminSiteURL","$SPCntAdminSite" -replace "ConnectServiceBaseURL",$ConnectServiceBaseURL -replace "ConnectPrefix","$Prefix" -replace "ConnectAdminName",$SPOwnerAlias -replace "ConnectAdminEmail",$ConnectAdminEmail  | Set-Content "$settingsfilepath"

         # Executing the Admin Creation Utility
         $adminAutoexepath=Join-Path $json "Utilities\Admin creation Utility\Admin creation Utility.exe";
         Write-Host "Creating Admin and sending FirstLogin Email- Start"
        
         & $adminAutoexepath

         Write-Host "Creating Admin and sending FirstLogin Email- Complete"

        

         $Certname=$WebsiteData.Connect.Certificates.ACSCertificatecer;

         EstablishTrust $SPWebURL $ACSLoginURL $Certname $json

         

        



  }
Catch [System.Exception]
 {
    write-host "Exception Block"
    write-host $_.exception.message
    exit 1

      
}

}

function EstablishTrust([string]$SPWebURL,[string]$ACSLogin,[string]$CertName,[string]$json)
{

Write-Host "EstablishTrust- start"
$certpath= Join-Path $Json (Join-Path "certificates" $CertName)
$cert = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2("$certpath")
$map1 = New-SPClaimTypeMapping "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/emailaddress" -IncomingClaimTypeDisplayName "Email" –SameAsIncoming
$realm = $SPWebURL
$ACSSignInurl = $ACSLogin

New-SPTrustedIdentityTokenIssuer -Name "Winshuttle ACS" -Description "Winshuttle Azure ACS v2" -Realm $realm -ImportTrustCertificate $cert -ClaimsMappings $map1 -SignInUrl $ACSSignInurl -IdentifierClaim $map1.InputClaimType
New-SPTrustedRootAuthority -Name "Azure Token Signing" -Certificate $cert

$issuer = Get-SPTrustedIdentityTokenIssuer
$authority = Get-SPTrustedRootAuthority
$issuer.ProviderUri = $ACSSignInurl
$issuer.Update()

Write-Host "EstablishTrust- Complete"

$ap = New-SPAuthenticationProvider
Write-Host "Changing the Authentication Provider to Winshuttle ACS -Start"
Set-SPWebApplication -Identity $SPWebURL -AuthenticationProvider $issuer,$ap -Zone Default
Write-Host "Changing the Authentication Provider to Winshuttle ACS -Complete"


}





CreateSP-WebApplication -Json $Json -environment $environment -Buildversion $Buildversion -Branch $Branch -configuration $configuration -ACSLoginURL $ACSLoginURL -Srvusername $Srvusername -Secondaryusername $Secondaryusername -CntDefaultAdmin $CntDefaultAdmin -CntDefaultAdminEmail $CntDefaultAdminEmail