 <#
.SYNOPSIS
ConnectSetup : Websites and Vdir's
.DESCRIPTION
This function will create Websites and Vdir's for connect
Throws an exception if the update fails.
.EXAMPLE
.\Connect-UpdateConfig -json $Json -environment $environment
	
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

function Connect-UpdateConfig
{
try
{


$file= Get-Content (Join-Path $json ([string]::Concat("\Json\Connect",$environment,".json")))
$serverfile= Get-Content (Join-Path $json ([string]::Concat("\Json\",$environment,"Servers.json")))

[System.Reflection.Assembly]::LoadWithPartialName("System.web.extensions")
$serializer=New-Object System.Web.Script.Serialization.JavaScriptSerializer
$global:jsoncontent= $serializer.DeserializeObject($file)
$global:servercntjson= $serializer.DeserializeObject($serverfile)




[xml]$configxml= Get-Content ((Join-Path $json "ConfigurableValues.xml") | Resolve-Path -ErrorAction Stop)


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


        ConnectServices $SPWebURL $ConnectSTSURL $SPConnectAdminSiteURL



    }
catch [System.Exception]
{
         write-host "Exception.."
        write-host $_.exception.message
        }
}

 function ConnectServices([string]$SPWebURL,[string]$ConnectSTSURL,[string]$SPConnectAdminSiteURL)
 {
 
     $ConnectSTSConfigFile=Join-Path $jsoncontent.Connect.IIS.SentinelClient.VirtualDirectory.ConnectSTS.InetpubRoot "web.config" | Resolve-Path -ErrorAction Stop;

     
     $SentinelConfig=Join-Path $jsoncontent.Connect.IIS.Sentinel.InetpubRoot "web.config" | Resolve-Path -ErrorAction Stop;
     $hibernatecngxml=Join-Path $jsoncontent.Connect.IIS.Sentinel.InetpubRoot "hibernate.cfg.xml" | Resolve-Path -ErrorAction Stop;
     $SentinelbinConfig=Join-Path $jsoncontent.Connect.IIS.Sentinel.InetpubRoot "bin\web.config" | Resolve-Path -ErrorAction Stop;
     
     $V2config=Join-Path $jsoncontent.Connect.IIS.SentinelClient.VirtualDirectory.V2.InetpubRoot "web.config" | Resolve-Path -ErrorAction Stop;
     $DataAPIConfig=Join-Path $jsoncontent.Connect.IIS.SentinelClient.VirtualDirectory.DataAPI.InetpubRoot "web.config" | Resolve-Path -ErrorAction Stop;
     $SentinelWebApiconfig=Join-Path $jsoncontent.Connect.IIS.SentinelWebApi.InetpubRoot "web.config" | Resolve-Path -ErrorAction Stop;
     
    
     $CertFriendlyName=$jsoncontent.Connect.IIS.SentinelClient.Certicate;

     if($jsoncontent.Connect.IIS.Sentinel.Certicate -eq "Developer")
        {
        $domainname=$env:COMPUTERNAME
        $certs=@(Get-ChildItem -Path Cert:\LocalMachine\My -Recurse | Where-Object {$_.Subject -match "CN=$domainname"} | Select -First 1 Thumbprint,Subject)
        }
        else
        {
        
        $domainname=$certName;
        $certs=@(Get-ChildItem -Path Cert:\LocalMachine\My -Recurse | Where-Object {$_.FriendlyName -match "$CertFriendlyName"} | Select -First 1 Thumbprint, Subject)
        }

        # Check for expiration 
        if($certs -ne $null)
        {
        $curDate= Get-Date

        $CertHash= $certs | Where-Object {$_.notafter -le $curDate}


        $certsubject=$CertHash.subject;
        $certthumbprint=$CertHash.Thumbprint;
        }
        else
        {
         Write-Host "Certs not found";
         throw
        }

        $TrustedRelyingParties2= [string]::Concat("https://",$ConnectSTSURL,"/V2/LicensingServiceClaims.svc/connectsts");
       
        $TrustedRelyingParties2encryptingCert=$certsubject
        $signingCertName=$certsubject

        $AuthServiceissuerName= [string]::Concat("https://",$ConnectSTSURL,":",$jsoncontent.Connect.IIS.SentinelClient.HttpsPort,"/");
        $AuthServicesigCertName=$certsubject
        $PassiveParams=$SPWebURL
        $connectionstring=[string]::Concat("server=(local)\sqlexpress",";database=WinshuttleLicensing;Trusted_Connection=true")
        
        Write-Host "Updating below values in ConnecSTS Config"

        Write-Host "TrustedRelyingParties Identifier :"$TrustedRelyingParties2
        Write-Host "TrustedRelyingParties encryptingCert :"$TrustedRelyingParties2encryptingCert
        Write-Host "AuthService issuerName :"$AuthServiceissuerName
        Write-Host "AuthServicesig CertName :"$AuthServicesigCertName
        Write-Host "PassiveParams connectHostAddress:"$PassiveParams
        Write-Host "Service certificate thumbprint :"$signingCertName
        Write-Host ""


        # Updating ConnectSTS Config
       [xml]$connectConfigcontent= Get-Content $ConnectSTSConfigFile
       $connectConfigcontent.configuration.WinshuttleAuthConfig.TrustedRelyingParties.TrustedRelyingParty[1].identifier=$TrustedRelyingParties2;
       $connectConfigcontent.configuration.WinshuttleAuthConfig.TrustedRelyingParties.TrustedRelyingParty[1].encryptingCert=$TrustedRelyingParties2encryptingCert;
       $connectConfigcontent.configuration.WinshuttleAuthConfig.AuthService.issuerName=$AuthServiceissuerName;
       $connectConfigcontent.configuration.WinshuttleAuthConfig.AuthService.signingCertName=$AuthServicesigCertName;
       $connectConfigcontent.configuration.WinshuttleAuthConfig.PassiveParams.connectHostAddress=$SPWebURL;

       $CntsqlCntnstring=$connectConfigcontent.configuration.connectionStrings.add | Where-Object {$_.name -eq 'MySQLServerConnection'}
       $Cntconnarray=$CntsqlCntnstring.connectionString.Split(';')
       $Cntlastitem=$CntsqlCntnstring.connectionString.Split(';')[-1]

       $InstName= [System.Data.Sql.SqlDataSourceEnumerator]::Instance.GetDataSources() | ? { $_.servername -eq $a} | Select-Object InstanceName
       if($InstName.InstanceName -ne $null)
       {
       $Cntconnarray[0]=[string]::Concat("server=", $jsoncontent.Connect.Database.DatabaseNames[0],"\sqlexpress");
       }
       else
       {
       $Cntconnarray[0]=[string]::Concat("server=", $jsoncontent.Connect.Database.DatabaseNames[0],"\sqlexpress");
       }
       
       $CntsqlCntnstring.connectionString=[string]::Empty;
             foreach ($item in $Cntconnarray)
               {
                   if($item -eq $Cntlastitem)
                   {
                     $CntsqlCntnstring.connectionString+=[string]::Concat($Cntlastitem)
                   }
                    else
                    {
                     $CntsqlCntnstring.connectionString+=[string]::Concat($item,";")
                    }
               }


       
       $connectConfigcontent.configuration.'system.serviceModel'.behaviors.serviceBehaviors.behavior.serviceCredentials.serviceCertificate.findValue=$certthumbprint

       $appsettingsexist=$connectConfigcontent.configuration["appSettings"]
       if($appsettingsexist -eq $null)
       {
            $as = $xml.CreateElement("appSettings")
            $as.SetAttribute("add:ConnectAdminSiteURL", $SPConnectAdminSiteURL)
            $appsettingsexist.AppendChild($as)
       }

       else
       {
       $value=$connectConfigcontent.configuration.appSettings.add | Where-Object {$_.key -eq 'ConnectAdminSiteURL'}
       $value.value=$SPConnectAdminSiteURL;
       }

       $connectConfigcontent.Save($ConnectSTSConfigFile)
       
       # Updating Sentinel web.Config  file -- Start
       
               [xml]$SentinelConfigcontent= Get-Content $SentinelConfig
               $issuerValue=[string]::Concat("https://",$ConnectSTSURL,":",$jsoncontent.Connect.IIS.SentinelClient.HttpsPort,"/Auth/service.svc");
               $issuerMetadataValue=[string]::Concat("https://",$ConnectSTSURL,":",$jsoncontent.Connect.IIS.SentinelClient.HttpsPort,"/Auth/service.svc/mex");
               

               $SentinelConfigcontent.configuration.'system.serviceModel'.bindings.ws2007FederationHttpBinding.binding[0].security.message.issuer.address=$issuerValue
               $SentinelConfigcontent.configuration.'system.serviceModel'.bindings.ws2007FederationHttpBinding.binding[0].security.message.issuerMetadata.address=$issuerMetadataValue
             
               $value=$SentinelConfigcontent.configuration.'microsoft.identityModel'.service | Where-Object {$_.Name -eq 'Winshuttle.Licensing.Services.LicensingServiceClaims'}
               $value.issuerNameRegistry.trustedIssuers.add.thumbprint=$certthumbprint;
               $value.issuerNameRegistry.trustedIssuers.add.name=[string]::Concat("https://",$ConnectSTSURL,":",$jsoncontent.Connect.IIS.SentinelClient.HttpsPort,"/");

               $MySQLServerConnectionValue=$SentinelConfigcontent.configuration.connectionStrings.add | Where-Object {$_.name -eq 'MySQLServerConnection'}
               $connarray=$MySQLServerConnectionValue.connectionString.Split(';')
               $lastitem=$MySQLServerConnectionValue.connectionString.Split(';')[-1]
               $connarray[0]=[string]::Concat("server=", $databaseservername,"\sqlexpress");
               $connarray[1]=[string]::Concat("database=",$jsoncontent.Connect.Database.DatabaseNames[0]);
                   $MySQLServerConnectionValue.connectionString=[string]::Empty;
                     foreach ($item in $connarray)
                       {
                           if($item -eq $lastitem)
                           {
                             $MySQLServerConnectionValue.connectionString+=[string]::Concat($lastitem)
                           }
                            else
                            {
                             $MySQLServerConnectionValue.connectionString+=[string]::Concat($item,";")
                            }
                       }
      
       
               $LogsDBConnectionValue=$SentinelConfigcontent.configuration.connectionStrings.add | Where-Object {$_.name -eq 'LogsDBConnection'}
               $Lconnarray=$LogsDBConnectionValue.connectionString.Split(';');
               $Llastitem=$LogsDBConnectionValue.connectionString.Split(';')[-1]
               $Lconnarray[0]=[string]::Concat("server=", $databaseservername,"\sqlexpress");
               $Lconnarray[1]=[string]::Concat("database=",$jsoncontent.Connect.Database.DatabaseNames[1]);
                       $LogsDBConnectionValue.connectionString=[string]::Empty;
                     foreach ($item in $Lconnarray)
                                                                                               {
                   if($item -eq $Llastitem)
                   {
                     $LogsDBConnectionValue.connectionString+=[string]::Concat($Llastitem)
                   }
                    else
                    {
                     $LogsDBConnectionValue.connectionString+=[string]::Concat($item,";")
                    }
               }

                       $SentinelConfigcontent.Save($SentinelConfig)

        # Updating Sentinel web.Config  file -- Compelte
                

        # copying the Sentinel web.Config to bin folder

               Copy-Item -Path $SentinelConfig -Destination $SentinelbinConfig -Force 


        # Updating connectionstrings in hibernate.cng.xml file -- Start

                [xml]$hibernateConfigcontent= Get-Content $hibernatecngxml 
                $Dsvalue=$hibernateConfigcontent.'session-factory'.property | Where-Object {$_.name -eq "connection.connection_string"}
                $Dsarray=$Dsvalue.'#text'.Split(';')
                $Dsarray[0]=[string]::Concat("Data Source=",$databaseservername,"\sqlexpress");
                $Dsarray[1]=[string]::Concat("Initial Catalog=",$jsoncontent.Connect.Database.DatabaseNames[0]);
                $Dsvalue.'#text'=[string]::Empty;
                 foreach ($item in $Dsarray)
                   {
                   
                         $Dsvalue.'#text'+=[string]::Concat($item,";")
                    
                   }
                $hibernateConfigcontent.Save($hibernatecngxml)

        # Updating connectionstrings in hibernate.cng.xml file -- Complete
             
             
        # Updating connectionstrings in SentinelWebApi we.config.xml file -- start

              [xml]$SentinelWebApicontent= Get-Content $SentinelWebApiconfig
               
                $swDsvalue=$SentinelWebApicontent.configuration.'hibernate-configuration'.'session-factory'.property | Where-Object {$_.name -eq "connection.connection_string"} 
                $swDsarray=$swDsvalue.'#text'.Split(';')
                $swDsarray[0]=$swDsarray[0].Replace(" ","");

                $swDsarray[0]=[string]::Concat("Data Source=",$databaseservername,"\sqlexpress");
                $swDsarray[1]=[string]::Concat("Initial Catalog=",$jsoncontent.Connect.Database.DatabaseNames[0]);
                $swDsvalue.'#text'=[string]::Empty;
                 foreach ($item in $swDsarray)
                   {                   
                         $swDsvalue.'#text'+=[string]::Concat($item,";")                    
                   }                 

                $SentinelWebApicontent.Save($SentinelWebApiconfig)
                
        # Updating connectionstrings in SentinelWebApi we.config.xml file -- complete


        # Updating connectionstrings in V2 Vdir we.config.xml file -- start

                  [xml]$V2configcontent= Get-Content $V2config
                  $lscAudurlValue=[string]::Concat("https://",$ConnectSTSURL,"/V2/LicensingServiceClaims.svc/connectsts");
                  $psAudurlValue=[string]::Concat("https://",$ConnectSTSURL,":",$jsoncontent.Connect.IIS.SentinelClient.HttpsPort,"/V2/ProxyService.svc/azureacs");
                  $lscAudurl=$V2configcontent.configuration.'microsoft.identityModel'.service | Where-Object {$_.Name -eq 'Winshuttle.Licensing.Services.LicensingServiceClaims'}
                  $lscAudurl.audienceUris.add.value=$lscAudurlValue;
                  $psAudurl=$V2configcontent.configuration.'microsoft.identityModel'.service | Where-Object {$_.Name -eq 'Winshuttle.Licensing.Services.ProxyService'}
                  $psAudurl.audienceUris.add.value=$psAudurlValue;

                  $V2configcontent.Save($V2config);
        # Updating connectionstrings in V2 Vdir web.config.xml file -- complete


             # Updating connectionstrings in DataAPI Vdir web.config.xml file -- start
             

                [xml]$DataAPIcontent= Get-Content $DataAPIConfig
                 $dapiDsvalue=$DataAPIcontent.configuration.'hibernate-configuration'.'session-factory'.property | Where-Object {$_.name -eq "connection.connection_string"} 
                        $dapiDsarray=$dapiDsvalue.'#text'.Split(';')
                        $dapiDsarray[0]=$dapiDsarray[0].Replace(" ","");

                        $dapiDsarray[0]=[string]::Concat("Data Source=", $databaseservername,"\sqlexpress");
                        $dapiDsarray[1]=[string]::Concat("Initial Catalog=",$jsoncontent.Connect.Database.DatabaseNames[0]);
                        $dapiDsvalue.'#text'=[string]::Empty;
                         foreach ($item in $dapiDsarray)
                           {
                   
                                 $dapiDsvalue.'#text'+=[string]::Concat($item,";")
                    
                           }
                 $authvalue=$DataAPIcontent.configuration.appSettings.add | Where-Object {$_.key -eq 'AuthenticationRequired'}
                 $authvalue.value="false";

               $DataAPIcontent.Save($DataAPIConfig);
       # Updating connectionstrings in DataAPI Vdir web.config.xml file -- complete
      
       
        }

 Function ConnectSPWeb
 {
 }

 Connect-UpdateConfig -Json $Json -environment $environment
