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
    
    [string]$InputJsonFile=$(throw "Please pass path to json File ")
   
   

)

Function Connect-CopyBinaries
{

try
 { 
 
   
      

 }
Catch [System.Exception]
 {
    write-host "Exception Block"
    write-host $_.exception.message
      
}

}

Connect-CopyBinaries 