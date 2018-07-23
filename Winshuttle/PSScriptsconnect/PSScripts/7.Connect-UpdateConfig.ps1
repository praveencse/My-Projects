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
    [string]$environment=$(throw "Please provide Environment"),
    [string]$DBServerName=$(throw "Please provide Database server name"),
    [string]$DBInstanceName=$(throw "Please provide Database instance name")


)

function Connect-UpdateConfig
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


        ConnectServices $SPWebURL $ConnectSTSURL $SPConnectAdminSiteURL $DBServerName



    }
catch [System.Exception]
{
         write-host "Exception.."
        write-host $_.exception.message
        exit 1

        }
}

 function ConnectServices([string]$SPWebURL,[string]$ConnectSTSURL,[string]$SPConnectAdminSiteURL,[string]$DBServerName)
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
        $dataservername=$env:COMPUTERNAME;
        }
        else
        {
        
        $domainname=$certName;
        $certs=@(Get-ChildItem -Path Cert:\LocalMachine\My -Recurse | Where-Object {$_.FriendlyName -match "$CertFriendlyName"} | Select -First 1 Thumbprint, Subject)
#        $dataservername=$servercntjson.ServersList.Database.Name;
        $dataservername=$DBServerName;
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
        #$connectionstring=[string]::Concat("server=(local)\sqlexpress",";database=WinshuttleLicensing;Trusted_Connection=true")
        
        
       


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
      

       
      <# $InstName= [System.Data.Sql.SqlDataSourceEnumerator]::Instance.GetDataSources() | ? {$a= $DBServerName               
       $_.servername -eq $a} | Select-Object InstanceName
       if($InstName.InstanceName -ne $null)
       {
#      $Cntconnarray[0]=[string]::Concat("server=", $jsoncontent.Connect.Database.DatabaseNames[0],"\sqlexpress");
       #$Cntconnarray[0]=[string]::Concat("server=", $servercntjson.ServersList.Database.Name,"\sqlexpress");
       $Cntconnarray[0]=[string]::Concat("server=", $DBServerName,"\sqlexpress");
       }
       else
       {
       #$Cntconnarray[0]=[string]::Concat("server=", $jsoncontent.Connect.Database.DatabaseNames[0]);
       #$Cntconnarray[0]=[string]::Concat("server=", $servercntjson.ServersList.Database.Name);
       $Cntconnarray[0]=[string]::Concat("server=", $DBServerName);
       }#>

       if($DBInstanceName -ne $null)
       {
       
       $Cntconnarray[0]=[string]::Concat("server=", $DBServerName,"\",$DBInstanceName);
       }
       else
       {
       #$Cntconnarray[0]=[string]::Concat("server=", $jsoncontent.Connect.Database.DatabaseNames[0]);
       #$Cntconnarray[0]=[string]::Concat("server=", $servercntjson.ServersList.Database.Name);
       $Cntconnarray[0]=[string]::Concat("server=", $DBServerName);
       }
       
       $CntsqlCntnstring.connectionString=[string]::Empty;
       $Cntconnarray[1]=[string]::Concat("database=",$jsoncontent.Connect.Database.DatabaseNames[0]);
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

       Write-Host "*************************************************************************************"
       Write-Host "Updating below values in ConnectSTS Config -start"
       Write-Host "*************************************************************************************"

        Write-Host "TrustedRelyingParties Identifier :"$TrustedRelyingParties2
        Write-Host "TrustedRelyingParties encryptingCert :"$TrustedRelyingParties2encryptingCert
        Write-Host "AuthService issuerName :"$AuthServiceissuerName
        Write-Host "AuthServicesig CertName :"$AuthServicesigCertName
        Write-Host "PassiveParams connectHostAddress:"$PassiveParams
        Write-Host "Service certificate thumbprint :"$signingCertName
       $connectConfigcontent.Save($ConnectSTSConfigFile)
       Write-Host "*************************************************************************************"
       Write-Host "Updating below values in ConnectSTS Config -complete"
       Write-Host "*************************************************************************************"
       
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
              <#  if($InstName.InstanceName -ne $null)
                   {
            #      $connarray[0]=[string]::Concat("server=", $databaseservername,"\sqlexpress");
                   #W$connarray[0]=[string]::Concat("server=", $servercntjson.ServersList.Database.Name,"\sqlexpress");
                   $connarray[0]=[string]::Concat("server=", $DBServerName,"\sqlexpress");
                   
                   }
                   else
                   {
                   #
                   #W$connarray[0]=[string]::Concat("server=", $servercntjson.ServersList.Database.Name);
                   $connarray[0]=[string]::Concat("server=", $DBServerName);
                   }#>
                   if($DBInstanceName -ne $null)
                   {
           
                   $connarray[0]=[string]::Concat("server=", $DBServerName,"\",$DBInstanceName);
                   
                   }
                   else
                   {
                  
                   $connarray[0]=[string]::Concat("server=", $DBServerName);
                   }

               
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

                  <# if($InstName.InstanceName -ne $null)
                       {
                         #$Lconnarray[0]=[string]::Concat("server=", $databaseservername,"\sqlexpress");
                         #W$Lconnarray[0]=[string]::Concat("server=", $servercntjson.ServersList.Database.Name,"\sqlexpress");
                         $Lconnarray[0]=[string]::Concat("server=", $DBServerName,"\sqlexpress");
                       }
                   else
                       {
                          #W$Lconnarray[0]=[string]::Concat("server=", $servercntjson.ServersList.Database.Name);
                          $Lconnarray[0]=[string]::Concat("server=", $DBServerName);
                       }#>
                        if($DBInstanceName -ne $null)
                       {
                         #$Lconnarray[0]=[string]::Concat("server=", $databaseservername,"\sqlexpress");
                         #W$Lconnarray[0]=[string]::Concat("server=", $servercntjson.ServersList.Database.Name,"\sqlexpress");
                         $Lconnarray[0]=[string]::Concat("server=", $DBServerName,"\",$DBInstanceName);
                       }
                   else
                       {
                          #W$Lconnarray[0]=[string]::Concat("server=", $servercntjson.ServersList.Database.Name);
                          $Lconnarray[0]=[string]::Concat("server=", $DBServerName);
                       }

              
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

       Write-Host "*************************************************************************************"
       Write-Host "Updating Sentinel web.config -start"
       Write-Host "*************************************************************************************"
       Write-Host "issuerValue:"$issuerValue
       Write-Host "issuerMetadataValue:"$issuerMetadataValue
       Write-Host "trustedIssuers thumbprint:"$certthumbprint
       Write-Host "trustedIssuers Name:" $value.issuerNameRegistry.trustedIssuers.add.name
       Write-Host "Connect Connectionstring:" $MySQLServerConnectionValue.connectionString
       Write-Host "Logs Connectionstring:" $LogsDBConnectionValue.connectionString


       $SentinelConfigcontent.Save($SentinelConfig)
       Write-Host "*************************************************************************************"
       Write-Host "Updating Sentinel web.config -Complete"
       Write-Host "*************************************************************************************"
        # Updating Sentinel web.Config  file -- Compelte
                

        # copying the Sentinel web.Config to bin folder
        Write-Host "*************************************************************************************"
         Write-Host "Copying the Sentinel web.config to bin\web.config - start"
        Write-Host "*************************************************************************************"
               Copy-Item -Path $SentinelConfig -Destination $SentinelbinConfig -Force 
         Write-Host "*************************************************************************************"
         Write-Host "Copying the Sentinel web.config to bin\web.config - Complete"
         Write-Host "*************************************************************************************"
        # Updating connectionstrings in hibernate.cng.xml file -- Start

                [xml]$hibernateConfigcontent= Get-Content $hibernatecngxml 
                $Dsvalue=$hibernateConfigcontent.'session-factory'.property | Where-Object {$_.name -eq "connection.connection_string"}
                $Dsarray=$Dsvalue.'#text'.Split(';')
                <# if($InstName.InstanceName -ne $null)
                   {
                     #$Dsarray[0]=[string]::Concat("Data Source=",$databaseservername,"\sqlexpress");
                     #W$Dsarray[0]=[string]::Concat("Data Source=",$servercntjson.ServersList.Database.Name,"\sqlexpress");
                     $Dsarray[0]=[string]::Concat("Data Source=",$DBServerName,"\sqlexpress");
                     
                   }
                   else
                   {
                   #W$Dsarray[0]=[string]::Concat("Data Source=",$servercntjson.ServersList.Database.Name);
                   $Dsarray[0]=[string]::Concat("Data Source=",$DBServerName);
                 
                   }#>
                    if($DBInstanceName -ne $null)
                   {
                    
                     $Dsarray[0]=[string]::Concat("Data Source=",$DBServerName,"\",$DBInstanceName);
                     
                   }
                   else
                   {
                  
                   $Dsarray[0]=[string]::Concat("Data Source=",$DBServerName);
                 
                   }

                #$Dsarray[0]=[string]::Concat("Data Source=",$databaseservername,"\sqlexpress");
                $Dsarray[1]=[string]::Concat("Initial Catalog=",$jsoncontent.Connect.Database.DatabaseNames[0]);
                $Dsvalue.'#text'=[string]::Empty;
                 foreach ($item in $Dsarray)
                   {
                   
                         $Dsvalue.'#text'+=[string]::Concat($item,";")
                    
                   }

                Write-Host "*************************************************************************************"
                Write-Host "Updating connectionstrings in hibernate.cng.xml file -- Complete- start"
                Write-Host "*************************************************************************************"
                Write-Host "connection.connection_string:"$Dsvalue.'#text'

                $hibernateConfigcontent.Save($hibernatecngxml)
                Write-Host "*************************************************************************************"
                Write-Host "Updating connectionstrings in hibernate.cng.xml file -- Complete"
                Write-Host "*************************************************************************************"

        # Updating connectionstrings in hibernate.cng.xml file -- Complete
             
             
        # Updating connectionstrings in SentinelWebApi we.config.xml file -- start
        

              [xml]$SentinelWebApicontent= Get-Content $SentinelWebApiconfig
               
                $swDsvalue=$SentinelWebApicontent.configuration.'hibernate-configuration'.'session-factory'.property | Where-Object {$_.name -eq "connection.connection_string"} 
                $swDsarray=$swDsvalue.'#text'.Split(';')
                $swDsarray[0]=$swDsarray[0].Replace(" ","");

                <# if($InstName.InstanceName -ne $null)
                   {
                     #$swDsarray[0]=[string]::Concat("Data Source=",$databaseservername,"\sqlexpress");
                     #W$swDsarray[0]=[string]::Concat("Data Source=",$servercntjson.ServersList.Database.Name,"\sqlexpress");
                     $swDsarray[0]=[string]::Concat("Data Source=",$DBServerName,"\sqlexpress");
                     
                   }
                   else
                   {
                   #W$swDsarray[0]=[string]::Concat("Data Source=",$servercntjson.ServersList.Database.Name);
                   $swDsarray[0]=[string]::Concat("Data Source=",$DBServerName);
                 
                   }#>

                    if($DBInstanceName -ne $null)
                   {
                     
                     $swDsarray[0]=[string]::Concat("Data Source=",$DBServerName,"\",$DBInstanceName);
                     
                   }
                   else
                   {
                   
                   $swDsarray[0]=[string]::Concat("Data Source=",$DBServerName);
                 
                   }

                #$swDsarray[0]=[string]::Concat("Data Source=",$databaseservername,"\sqlexpress");
                $swDsarray[1]=[string]::Concat("Initial Catalog=",$jsoncontent.Connect.Database.DatabaseNames[0]);
                $swDsvalue.'#text'=[string]::Empty;
                 foreach ($item in $swDsarray)
                   {                   
                         $swDsvalue.'#text'+=[string]::Concat($item,";")                    
                   }                 

                   Write-Host "*************************************************************************************"
                   Write-Host "Updating connectionstrings in SentinelWebApi web.config.xml file -- start"
                   Write-Host "*************************************************************************************"

                   Write-Host "connection.connection_string:" $swDsvalue.'#text'
                   $SentinelWebApicontent.Save($SentinelWebApiconfig)

                   Write-Host "*************************************************************************************"
                   Write-Host "Updating connectionstrings in SentinelWebApi web.config.xml file -- complete"
                   Write-Host "*************************************************************************************"
        # Updating connectionstrings in SentinelWebApi we.config.xml file -- complete


        # Updating connectionstrings in V2 Vdir web.config.xml file -- start

                  [xml]$V2configcontent= Get-Content $V2config
                  $lscAudurlValue=[string]::Concat("https://",$ConnectSTSURL,"/V2/LicensingServiceClaims.svc/connectsts");
                  $psAudurlValue=[string]::Concat("https://",$ConnectSTSURL,":",$jsoncontent.Connect.IIS.SentinelClient.HttpsPort,"/V2/ProxyService.svc/azureacs");
                  $lscAudurl=$V2configcontent.configuration.'microsoft.identityModel'.service | Where-Object {$_.Name -eq 'Winshuttle.Licensing.Services.LicensingServiceClaims'}
                  $lscAudurl.audienceUris.add.value=$lscAudurlValue;
                  $psAudurl=$V2configcontent.configuration.'microsoft.identityModel'.service | Where-Object {$_.Name -eq 'Winshuttle.Licensing.Services.ProxyService'}
                  $psAudurl.audienceUris.add.value=$psAudurlValue;

                  Write-Host "*************************************************************************************"
                  Write-Host "Updating connectionstrings in V2 Vdir web.config.xml file -- start"
                  Write-Host "*************************************************************************************"

                  Write-Host "audienceUris for LicensingServiceClaims:"$lscAudurlValue
                  Write-Host "audienceUris for ProxyService :"$psAudurlValue
                  $V2configcontent.Save($V2config);

                  Write-Host "*************************************************************************************"
                  Write-Host "Updating connectionstrings in V2 Vdir web.config.xml file -- complete"
                  Write-Host "*************************************************************************************"
        # Updating connectionstrings in V2 Vdir web.config.xml file -- complete





             # Updating connectionstrings in DataAPI Vdir web.config.xml file -- start             

                [xml]$DataAPIcontent= Get-Content $DataAPIConfig
                 $dapiDsvalue=$DataAPIcontent.configuration.'hibernate-configuration'.'session-factory'.property | Where-Object {$_.name -eq "connection.connection_string"} 
                        $dapiDsarray=$dapiDsvalue.'#text'.Split(';')
                        $dapiDsarray[0]=$dapiDsarray[0].Replace(" ","");
                        <#if($InstName.InstanceName -ne $null)
                   {
                     #$swDsarray[0]=[string]::Concat("Data Source=",$databaseservername,"\sqlexpress");
                     #W$dapiDsarray[0]=[string]::Concat("Data Source=",$servercntjson.ServersList.Database.Name,"\sqlexpress");
                     $dapiDsarray[0]=[string]::Concat("Data Source=",$DBServerName,"\sqlexpress");
                     
                   }
                   else
                   {
                   #W$dapiDsarray[0]=[string]::Concat("Data Source=",$servercntjson.ServersList.Database.Name);
                   $dapiDsarray[0]=[string]::Concat("Data Source=",$DBServerName);
                 
                   }#>

                   if($DBInstanceName -ne $null)
                   {
                     
                     $dapiDsarray[0]=[string]::Concat("Data Source=",$DBServerName,"\",$DBInstanceName);
                     
                   }
                   else
                   {
                  
                   $dapiDsarray[0]=[string]::Concat("Data Source=",$DBServerName);
                 
                   }
                        #$dapiDsarray[0]=[string]::Concat("Data Source=", $databaseservername,"\sqlexpress");
                        $dapiDsarray[1]=[string]::Concat("Initial Catalog=",$jsoncontent.Connect.Database.DatabaseNames[0]);
                        $dapiDsvalue.'#text'=[string]::Empty;
                         foreach ($item in $dapiDsarray)
                           {
                   
                                 $dapiDsvalue.'#text'+=[string]::Concat($item,";")
                    
                           }
                 $authvalue=$DataAPIcontent.configuration.appSettings.add | Where-Object {$_.key -eq 'AuthenticationRequired'}
                 $authvalue.value="false";
                 Write-Host "*************************************************************************************"
                 write-host "Updating connectionstrings in DataAPI Vdir web.config.xml file -- start"
                 Write-Host "*************************************************************************************"

                 Write-Host "connection.connection_string :" $dapiDsvalue.'#text'
                 Write-Host "AuthenticationRequired :" $authvalue.value
                 $DataAPIcontent.Save($DataAPIConfig);

                 Write-Host "*************************************************************************************"
                 write-host "Updating connectionstrings in DataAPI Vdir web.config.xml file -- complete"
                 Write-Host "*************************************************************************************"
            # Updating connectionstrings in DataAPI Vdir web.config.xml file -- complete
      
       
        }



 Connect-UpdateConfig -Json $Json -environment $environment -DBServerName $DBServerName -DBInstanceName $DBInstanceName
