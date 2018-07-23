 <#
.SYNOPSIS
ConnectSetup : Websites and Vdir's
.DESCRIPTION
This function will create Websites and Vdir's for connect
Throws an exception if the update fails.
.EXAMPLE
.\8.Connect-SPConfigUpdate -json $Json -environment $environment
	
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

function Connect-SPWebConfigUpdate
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


        SPConfigUpdate $SPWebURL $ConnectSTSURL



    }
catch [System.Exception]
{
         write-host "Exception.."
        write-host $_.exception.message
        exit 1

        }
}

 function SPConfigUpdate([string]$SPWebURL,[string]$ConnectSTSURL)
 {

 $webconfigpath= Join-Path "C:\inetpub\wwwroot\wss\VirtualDirectories" (Join-Path $jsoncontent.Connect.SharePoint.WebApplication.Port "web.config")


 Write-Host "backing  up SP config to C:\inetpub\SPconfigbackup -- Start"
 Copy-Item -path $webconfigpath -Destination "C:\inetpub\SPconfigbackup" -Force -ErrorAction Stop
 Write-Host "backing  up SP config to C:\inetpub\SPconfigbackup -- Complete"


 [xml]$spconfig= Get-Content $webconfigpath -Force;
    $newsectionentry=$spconfig.CreateElement("Section")
    $spconfig.configuration.configSections.AppendChild($newsectionentry)
    $newsectionentry.SetAttribute("name","log4net")
    $newsectionentry.SetAttribute("type",'log4net.Config.Log4NetConfigurationSectionHandler,log4net, Version=1.2.10.0, Culture=neutral, PublicKeyToken=1b44e1d426115821')
   
   Write-Host "Adding Sections :: Log4net entry into configSections -- Complete"
  
    $log4netcofgentry=@"
    <log4net debug="true"><root><priority value="DEBUG" />     
    <appender-ref ref="rollingFile" />    </root>    
    <appender name="trace" type="log4net.Appender.TraceAppender, log4net">      
    <layout type="log4net.Layout.PatternLayout,log4net">       
     <param name="ConversionPattern" value="%d{ABSOLUTE} %-5p %c{1}:%L - %m%n" />
      </layout>
    </appender>
    <appender name="console" type="log4net.Appender.ConsoleAppender, log4net">
      <layout type="log4net.Layout.PatternLayout,log4net">
        <param name="ConversionPattern" value="%d{ABSOLUTE} %-5p %c{1}:%L - %m%n" />
      </layout>
    </appender>
    <appender name="rollingFile" type="log4net.Appender.RollingFileAppender">
      <param name="File" value="C:\LicensingServer\logSP.txt" />
      <param name="AppendToFile" value="true" />
      <param name="RollingStyle" value="Date" />
      <param name="DatePattern" value="yyyy.MM.dd" />
      <param name="StaticLogFileName" value="true" />
      <layout type="log4net.Layout.PatternLayout">
        <param name="ConversionPattern" value="%d [%t] %-5p %c - %m%n" />
      </layout>
    </appender>
</log4net>
"@

$xmlfrg= $spconfig.CreateDocumentFragment();
$xmlfrg.InnerXml=$log4netcofgentry;
$configSectionsnode=$spconfig.SelectSingleNode('//configSections');
$configSectionsnode.AppendChild($xmlfrg);

   Write-Host "Adding Log4net Node -- Complete"


$sfcontrolentry=@"
<SafeControl Assembly="Winshuttle.Licensing.SharePointUI.Common, Version=1.0.0.0, Culture=neutral, PublicKeyToken=9ebc6ede14ff7b28" Namespace="Winshuttle.Licensing.SharePointUI.Common" TypeName="*" Safe="True" SafeAgainstScript="False" />
<SafeControl Assembly="Winshuttle.Licensing.AdminSiteDefinition, Version=1.0.0.0, Culture=neutral, PublicKeyToken=9ebc6ede14ff7b28" Namespace="Winshuttle.Licensing.AdminSiteDefinition.AdminWebPart" TypeName="*" Safe="True" SafeAgainstScript="False" />
<SafeControl Assembly="Winshuttle.Licensing.CustomerSiteDefinition, Version=1.0.0.0, Culture=neutral, PublicKeyToken=9ebc6ede14ff7b28" Namespace="Winshuttle.Licensing.CustomerSiteDefinition.CustomerWebPart" TypeName="*" Safe="True" SafeAgainstScript="False" />
"@
$sfcontrolfrg= $spconfig.CreateDocumentFragment();
$sfcontrolfrg.InnerXml=$sfcontrolentry;
$safecntnode=$spconfig.SelectSingleNode('//SafeControls')
$safecntnode.AppendChild($sfcontrolfrg);


Write-Host "Adding SafeControl assemblies -- Complete"


$sysassbly1=$spconfig.CreateElement("add");
$spconfig.configuration.'system.web'.compilation.assemblies.AppendChild($sysassbly1);
$sysassbly1.SetAttribute("assembly","Winshuttle.Licensing.SharePointUI.Common, Version=1.0.0.0, Culture=neutral, PublicKeyToken=9ebc6ede14ff7b28");

$sysassbly2=$spconfig.CreateElement("add");
$spconfig.configuration.'system.web'.compilation.assemblies.AppendChild($sysassbly2);
$sysassbly2.SetAttribute("assembly","Winshuttle.Licensing.AdminSiteDefinition, Version=1.0.0.0, Culture=neutral, PublicKeyToken=9ebc6ede14ff7b28");

$sysassbly3=$spconfig.CreateElement("add");
$spconfig.configuration.'system.web'.compilation.assemblies.AppendChild($sysassbly3);
$sysassbly3.SetAttribute("assembly","Winshuttle.Licensing.CustomerSiteDefinition, Version=1.0.0.0, Culture=neutral, PublicKeyToken=9ebc6ede14ff7b28");

Write-Host "Adding compilation assemblies -- Complete"

$wsconnect_usewshttp=$spconfig.CreateElement("add")
$spconfig.configuration.appSettings.AppendChild($wsconnect_usewshttp);
$wsconnect_usewshttp.SetAttribute("key","wsconnect_usewshttp");
$wsconnect_usewshttp.SetAttribute("value","true")



$wsconnect_servicebaseurl=$spconfig.CreateElement("add")
$spconfig.configuration.appSettings.AppendChild($wsconnect_servicebaseurl);
$wsconnect_servicebaseurl.SetAttribute("key","wsconnect_servicebaseurl");
$servicebaseurlvalue=[string]::Concat("http://",$ConnectSTSURL,":",$jsoncontent.Connect.IIS.Sentinel.HttpPort);
$wsconnect_servicebaseurl.SetAttribute("value",$servicebaseurlvalue);

$DashboardApiEndpoint=$spconfig.CreateElement("add")
$spconfig.configuration.appSettings.AppendChild($DashboardApiEndpoint);
$DashboardApiEndpoint.SetAttribute("key","DashboardApiEndpoint");
$DdApiEndpointvalue=[string]::Concat("http://",$ConnectSTSURL,":",$jsoncontent.Connect.IIS.SentinelClient.HttpPort,"/dashboardapi");
$DashboardApiEndpoint.SetAttribute("value",$DdApiEndpointvalue);


$ServiceTimeout=$spconfig.CreateElement("add")
$spconfig.configuration.appSettings.AppendChild($ServiceTimeout);
$ServiceTimeout.SetAttribute("key","ServiceTimeout");
$ServiceTimeout.SetAttribute("value","180");



Write-Host "Adding Configuration AppSettings  -- Complete"


$spconfig.SelectNodes("//service")
$spconfig.SelectNodes("//service") | ForEach-Object {

        $nodeToComment = $_;
        $comment = $spconfig.CreateComment($nodeToComment.OuterXml);

        # Comment the node
        $nodeToComment.ParentNode.ReplaceChild($comment, $nodeToComment);
    }


Write-Host "Commenting service tag under microsoft.identityModel  -- Complete"


$servicecnt=@"
<service saveBootstrapTokens="true">
      <audienceUris mode="Never" />
      <issuerNameRegistry type="Microsoft.SharePoint.IdentityModel.SPPassiveIssuerNameRegistry, Microsoft.SharePoint, Version=14.0.0.0, Culture=neutral, PublicKeyToken=71e9bce111e9429c" />
      <securityTokenHandlers>
        <clear />
        <add type="Microsoft.IdentityModel.Tokens.X509SecurityTokenHandler, Microsoft.IdentityModel, Version=3.5.0.0, Culture=neutral, PublicKeyToken=31bf3856ad364e35" />
        <add type="Microsoft.SharePoint.IdentityModel.SPSaml11SecurityTokenHandler, Microsoft.SharePoint.IdentityModel, Version=14.0.0.0, Culture=neutral, PublicKeyToken=71e9bce111e9429c">
          <samlSecurityTokenRequirement>
            <nameClaimType value="http://schemas.microsoft.com/sharepoint/2009/08/claims/userid" />
          </samlSecurityTokenRequirement>
        </add>
        <add type="Microsoft.SharePoint.IdentityModel.SPTokenCache, Microsoft.SharePoint.IdentityModel, Version=14.0.0.0, Culture=neutral, PublicKeyToken=71e9bce111e9429c" />
        <add type="Microsoft.IdentityModel.Tokens.EncryptedSecurityTokenHandler, Microsoft.IdentityModel, Version=3.5.0.0, Culture=neutral, PublicKeyToken=31bf3856ad364e35" />
      </securityTokenHandlers>
      <federatedAuthentication>
        <wsFederation passiveRedirectEnabled="false" issuer="https://none" realm="https://none" />
        <cookieHandler mode="Custom" path="/">
          <customCookieHandler type="Microsoft.SharePoint.IdentityModel.SPChunkedCookieHandler, Microsoft.SharePoint.IdentityModel, Version=14.0.0.0, Culture=neutral, PublicKeyToken=71e9bce111e9429c" />
        </cookieHandler>
      </federatedAuthentication>
      <serviceCertificate>
        <certificateReference findValue="B73998B94312D719D35AC505B117BB6259F1B58E" storeLocation="LocalMachine" storeName="My" x509FindType="FindByThumbprint" />
      </serviceCertificate>
    </service>

"@
$servicefrgmt=$spconfig.CreateDocumentFragment();
$servicefrgmt.InnerXml=$servicecnt;

$servicenode=$spconfig.SelectSingleNode("//microsoft.identityModel")
$servicenode.AppendChild($servicefrgmt)

Write-Host "Adding  service tag under microsoft.identityModel  -- Complete"

$spconfig.Save($webconfigpath)

}



 Connect-SPWebConfigUpdate -Json $Json -environment $environment
