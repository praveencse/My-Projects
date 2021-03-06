<#
.SYNOPSIS
copies binaries to Connect setup
.DESCRIPTION
This function will copies binaries to Connect setup
Throws an exception if the update fails.
.EXAMPLE
.\Connect-CopyBinaries -json $json -Buildversion $Buildversion -Branch $Branch -configuration $configuration -environment $environment 
	
.NOTES
Author:		Padma P Peddigari
Version:    1.0
#>
param(
    
    [string]$json=$(throw "Please pass path to json File "),
    [string]$Buildversion=$(throw "Please build version "),
    [string]$Branch=$(throw "Please pass branch"),
    [string]$environment=$(throw "Please provide Environment"),
    [string]$configuration=$(throw "Please pass configuration"),
     [string]$centralbinariespath=$(throw "Please provide binaries location")   
   

)

Function Connect-CopyBinaries
{

try
 { 

    #net use \\10.26.224.64\dummy /user:wse\centraluser "$abcd1234"
    #Start-Sleep -Seconds 10
    #Write-Host "Starting"
   
      $jsonfile= Join-Path $json ([string]::Concat("Json\Connect",$environment,".json")) -ErrorAction stop
      $WebsiteData= ConvertFrom-Json -InputObject (gc $jsonfile -Raw) -ErrorAction Stop

<# [System.Reflection.Assembly]::LoadWithPartialName("System.web.extensions")
$serializer=New-Object System.Web.Script.Serialization.JavaScriptSerializer
$global:WebsiteData= $serializer.DeserializeObject($jsonfile)#>
      #$centralbinariespath="\\10.26.1.19\Builds\TeamCity\winshuttle\products\Sentinel"
   
      $SentinelPath=$WebsiteData.Connect.IIS.Sentinel.InetpubRoot;
      $SentinelClientPath=$WebsiteData.Connect.IIS.SentinelClient.InetpubRoot;
      $V1path=$WebsiteData.Connect.IIS.SentinelClient.VirtualDirectory.V1.InetpubRoot;
      $V2Path=$WebsiteData.Connect.IIS.SentinelClient.VirtualDirectory.V2.InetpubRoot;
      $DataAPIPath=$WebsiteData.Connect.IIS.SentinelClient.VirtualDirectory.DataAPI.InetpubRoot;
      $ConnectSTSPath=$WebsiteData.Connect.IIS.SentinelClient.VirtualDirectory.ConnectSTS.InetpubRoot;
      $SentinelWebApiPath=$WebsiteData.Connect.IIS.SentinelWebApi.InetpubRoot;
     
      $global:BinariesPath= [string]::Concat($centralbinariespath,"\",$Branch,"\",$configuration,"\",$Buildversion);
      
      $Sentinelsrc=Join-Path $BinariesPath "PublishServices"
      $V1src=Join-Path $BinariesPath "PublishServices"
      $V2src=Join-Path $BinariesPath "PublishServices"
     
      $ConnectSTSsrc=Join-Path $BinariesPath "PublishAuthSTS"

      $DataAPIsrc=Join-Path $BinariesPath "PublishWeb"
      $SentinelWebApisrc=Join-Path $BinariesPath "PublishWeb"


      CreateFolder $SentinelPath      
      CreateFolder $SentinelClientPath
      CreateFolder $V1path
      CreateFolder $V2Path
      CreateFolder $DataAPIPath
      CreateFolder $ConnectSTSPath
      CreateFolder $SentinelWebApiPath

      CopyBinaries $Sentinelsrc $SentinelPath   
      CopyBinaries $V1src $V1path
      CopyBinaries $V2src $V2Path
      CopyBinaries $DataAPIsrc $DataAPIPath 
      CopyBinaries $ConnectSTSsrc $ConnectSTSPath 
      CopyBinaries $SentinelWebApisrc $SentinelWebApiPath 
 

   
 }
Catch [System.Exception]
 {
    write-host "Exception "
    write-host $_.exception.message
    exit 1

      
}

}

Function CreateFolder([string]$destpath)
{

       Write-Host "Check and Create $destpath folder"

       if (!(Test-Path -Path $destpath))
            {
                New-Item -ItemType Directory -Force -Path $destpath
            }
       Else 
            { 
                Write-host "Folder Exists"
            }
}

Function CopyBinaries([string]$sourcepath,[string]$destpath)
{

if (Test-Path -Path $sourcepath)
   {

             Write-Host "copying binaries from  $sourcepath to $destpath :: Start"

             Copy-Item -Path "$sourcepath\*" -Destination $destpath -Recurse -Force -ErrorAction Stop
 

             Write-Host "Copy Completed !!"


              if ($destpath.Contains("ConnectSTS"))
                { 

                    Write-Host "Copying Winshuttle.Licensing.Business.dll to ConnectSTS bin -Start"
                    $bisnusdll = Join-Path $BinariesPath "bin\Winshuttle.Licensing.Business\Release"

                    Copy-Item -path (Join-Path $BinariesPath "bin\Winshuttle.Licensing.Business\Release\Winshuttle.Licensing.Business.dll") -Destination "$destpath\bin\Winshuttle.Licensing.Business.dll" -Force -ErrorAction Stop
                    Write-Host "Copying Winshuttle.Licensing.Business.dll to ConnectSTS bin - Complete"
                }
    }

    Else 
    { 
                throw "$sourcepath does not exists"
    }


   
}


Connect-CopyBinaries -json $json -Buildversion $Buildversion -Branch $Branch -configuration $configuration -environment $environment