<#
.SYNOPSIS
Deployes connect Customer and Admin WSPs
.DESCRIPTION
This function will Deploy connect Customer and Admin WSPs
Throws an exception if the update fails.
.EXAMPLE
.\Connect-DeployWSP -Buildversion $Buildversion -Branch $Branch -configuration $configuration
	
.NOTES
Author:		Padma P Peddigari
Version:    1.0
#>

param(
  
    
    [string]$Buildversion=$(throw "Please build version "),
    [string]$Branch=$(throw "Please pass branch"),
    [string]$configuration=$(throw "Please pass cpnfiguration"),
    [string]$centralbinariespath=$(throw "Please provide binaries location")  
   
   
)

Function Connect-DeployWSP
{
  try
      {
         #$centralbinariespath="\\10.26.1.19\Builds\TeamCity\winshuttle\products\Sentinel"
         $BinariesPath= [string]::Concat($centralbinariespath,"\",$Branch,"\",$configuration,"\",$Buildversion);
         $CustomerSiteWSP="Winshuttle.Licensing.CustomerSiteDefinition.wsp"
         $AdminSiteWSP="Winshuttle.Licensing.AdminSiteDefinition.wsp"
         $CustomerSiteWSPPath= Join-Path $BinariesPath "CustomerSiteDefinitionWSP"
         $AdminSiteWSPPath= Join-Path $BinariesPath "AdminSiteDefinitionWSP"

         DeployWSP $CustomerSiteWSP $CustomerSiteWSPPath
         DeployWSP $AdminSiteWSP $AdminSiteWSPPath
      }
  Catch [System.Exception]
      {
        write-host "Exception "
        write-host $_.exception.message
        exit 1

      
      }
}


Function DeployWSP([string]$wsp,[string]$path)
{

     $CurrentDir= Get-Location

     $temppath=[string]::Concat($CurrentDir.Drive,":\TempDir\",$Buildversion)

     Write-host "$temppath"

         if(Test-Path -Path $temppath)
         {
           Remove-Item -Path $temppath -Force -Recurse

           Copy-Item $path $temppath  -Recurse -Force  -ErrorAction Stop
         }
         else
         {
           Copy-Item $path $temppath  -Recurse -Force  -ErrorAction Stop
         }

         Write-host "Copied Files from shared $path to $temppath"

     Add-PsSnapin Microsoft.SharePoint.PowerShell  

     
     $wspfile = Get-ChildItem $temppath | Where-Object {$_.Name -like "*.wsp"} | Select-Object FullName

     
     $wspexists= Get-SPSolution -Identity $wsp -ErrorAction SilentlyContinue
     Write-host "$wspexists"
     if($wspexists -eq $null)
     {
     Install

     }

     else
     {

     Uninstall

     }


     Remove-Item -Path $temppath -Recurse -ErrorAction Stop


}
<#
function WaitForJobToFinish([string]$solutionName)
{
    $solution = Get-SPSolution -Identity $solutionName -ErrorAction SilentlyContinue
 
    if ($solution)
    {
        if ($solution.JobExists)
        {
            Write-Host -NoNewLine "Waiting for timer job to complete for solution '$solutionName'."
        }
         
        # Check if there is a timer job still associated with this solution and wait until it has finished
        while ($solution.JobExists)
        {
            $jobStatus = $solution.JobStatus
             
            # If the timer job succeeded then proceed
            if ($jobStatus -eq [Microsoft.SharePoint.Administration.SPRunningJobStatus]::Succeeded)
            {
                Write-Host "Solution '$solutionName' timer job suceeded"
                return $true
            }
             
            # If the timer job failed or was aborted then fail
            if ($jobStatus -eq [Microsoft.SharePoint.Administration.SPRunningJobStatus]::Aborted -or
                $jobStatus -eq [Microsoft.SharePoint.Administration.SPRunningJobStatus]::Failed)
            {
                Write-Host "Solution '$solutionName' has timer job status '$jobStatus'."
                return $false
            }
             
            # Otherwise wait for the timer job to finish
            Write-Host -NoNewLine "."
            Sleep 1
        }
         
        # Write a new line to the end of the '.....'
        Write-Host
    }
     
    return $true
}#>

function WaitForJobToFinish([string]$SolutionFileName)
{ 
    $JobName = "*solution-deployment*$SolutionFileName*"
    $job = Get-SPTimerJob | ?{ $_.Name -like $JobName }
    if ($job -eq $null) 
    {
        Write-Host 'Timer job not found'
    }
    else
    {
        $JobFullName = $job.Name
        Write-Host -NoNewLine "Waiting to finish job $JobFullName"
        
        while ((Get-SPTimerJob $JobFullName) -ne $null) 
        {
            Write-Host -NoNewLine .
            Start-Sleep -Seconds 2
        }
        Write-Host  "Finished waiting for job.."
    }
}

function Install
{
         Write-Host "Adding Solution $wsp to the farm"

            Add-SPSolution -LiteralPath $wspfile.FullName
            start-sleep -seconds 40

           

            if($wsp -like '*Customer*')
            {
             Write-Host "Installing Solution $wsp"
            Install-SPSolution -Identity $wsp -CASPolicies -GACDeployment -AllWebApplications -Force

            }

            if($wsp -like '*Admin*')
            {
             Write-Host "Installing Solution $wsp"
            Install-SPSolution –identity $wsp -CASPolicies -GACDeployment -Force
            }
            start-sleep -seconds 40
}

function Uninstall
{
 if ($wspexists.Deployed -eq $true)
     {


         Write-Host "$wsp already exists in farm. Hence Uninstalling "

             if($wsp -like '*Customer*')
             {

                Uninstall-SPSolution -Identity $wsp -confirm:$False -AllWebApplications
             }

             if($wsp -like '*Admin*')
             {
                Uninstall-SPSolution -identity $wsp -confirm:$false
             }
              start-sleep -seconds 40
             #WaitForJobToFinish $wsp

             Write-Host "Removing Solution $wsp from the farm."

             Remove-SPSolution -identity $wsp -Confirm:$false
              start-sleep -seconds 40
     }

     else
     {

         Write-Host "$wsp is present but not installed .Hence removing Solution from the farm"

         Remove-SPSolution -identity $wsp -Confirm:$false

     }

     Install
}


Connect-DeployWSP -Buildversion $Buildversion -Branch $Branch -configuration $configuration