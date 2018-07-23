<#
.SYNOPSIS
ConnectSetup : Websites and Vdir's
.DESCRIPTION
This function will create Websites and Vdir's for connect
Throws an exception if the update fails.
.EXAMPLE
.\Connect-InstallCerts -json $Json -environment $environment
	
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

function Connect-InstallCerts
{
try
{



[String]$certRootStore = “localmachine”
[String]$certStore = “My”

$file= Get-Content (Join-Path $json ([string]::Concat("\Json\Connect",$environment,".json")))

[System.Reflection.Assembly]::LoadWithPartialName("System.web.extensions")
$serializer=New-Object System.Web.Script.Serialization.JavaScriptSerializer
$Certcontent= $serializer.DeserializeObject($file)

$DNSCert=$Certcontent.Connect.Certificates.DNSCertificateName;
$DNSPwd=$Certcontent.Connect.Certificates.DNSCertificatePwd;
$ACSCert=$Certcontent.Connect.Certificates.ACSCertificateName;
$ACSCertPwd=$Certcontent.Connect.Certificates.ACSCertificatepwd;

$DNScertPath= [string]::Concat($json,"\Certificates\",$DNSCert);
$ACScertPath= [string]::Concat($json,"\Certificates\",$ACSCert);

$CertsPath=Join-Path $json "Certificates"


# copy Certs to host Server script to run on remote server 
<#
     $CurrentDir= Get-Location

     $temppath=[string]::Concat($CurrentDir.Drive,":\TempDir\","Certificates")

     Write-host "$temppath"

         if(Test-Path -Path $temppath)
         {
           Remove-Item -Path $temppath -Force -Recurse

           Copy-Item $CertsPath $temppath  -Recurse -Force  -ErrorAction Stop
         }
         else
         {
           Copy-Item $CertsPath $temppath  -Recurse -Force  -ErrorAction Stop
         }

         Write-host "Copied Files from shared $path to $temppath"

     #>


Write-host " ***** Installing Domain and ACS Certificates ***** "
Write-host " $environment :: Domain Cert :: $DNSCert [$DNScertPath]"
Write-host " $environment :: Acs Cert :: $ACSCert [$ACScertPath]"


$DNSpfx = new-object System.Security.Cryptography.X509Certificates.X509Certificate2 
$DNSsecpasswd = ConvertTo-SecureString $DNSPwd -AsPlainText -Force

$ACSpfx = new-object System.Security.Cryptography.X509Certificates.X509Certificate2 
$ACSsecpasswd = ConvertTo-SecureString $ACSCertPwd -AsPlainText -Force

$DNSpfx.import($DNScertPath,$DNSsecpasswd,"Exportable,PersistKeySet") 
$ACSpfx.import($ACScertPath,$ACSsecpasswd,"Exportable,PersistKeySet") 

    $store = new-object System.Security.Cryptography.X509Certificates.X509Store($certStore,$certRootStore) 
    $store.open("MaxAllowed") 
    $store.add($DNSpfx) 
    $store.add($ACSpfx) 
    
    $store.close() 


    }
catch [System.Exception]
{
         write-host "Exception.."
        write-host $_.exception.message
}
}


Connect-InstallCerts -Json $Json -environment $environment


