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
    <#
    [string]$connectionstring=$(throw "Please pass connectionstring of the Provisoin Database")
    
    #>  
    [string]$Serviceaccount=$(throw "Please pass UserName"),
    [string]$SPWebAppName=$(throw "Please pass password"),
    [string]$SPWebAppPort=$(throw "Please pass True are False for IsHA"),
    [string]$SPSiteCollectionName=$(throw "Please pass True are False for IsHA")
    #[string]$SiteCollectionURL=$(throw "Please pass the input Json ProvisionData file" )

)

Function CreateSP-WebApplication
{

try
 {
          
        #Add-PsSnapin Microsoft.SharePoint.PowerShell
        # Set variables
        $SPWebApplicationName = [string]::Concat($SPWebAppName," - ",$SPWebAppPort);
        $SPWebApplicationPort = $SPWebAppPort;
        $SPWebApplicationAppPool = [string]::Concat($SPWebAppName,"-",$SPWebAppPort);
        $SPWebApplicationAccount =$Serviceaccount;
        $ssl = $false
        $Url=[string]::Concat("https://",$env:COMPUTERNAME)

        <#
#$WebAppDatabaseName = "Sharepoint1"
#$WebAppDatabaseServer = "SQLServer\InstanceName"
#$WebAppHostHeader = "sharepoint1.contoso.com"
#>


        $SPWebExists=Get-SPWebApplication -Identity $SPWebApplicationName

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

        #$SiteURL= New-SPWebApplication -Url $url -Name $SPWebApplicationName -Port $SPWebApplicationPort -ApplicationPool $SPWebApplicationAppPool -AuthenticationMethod NTLM -AuthenticationProvider $authencationprovider -AllowAnonymousAccess $true -SecureSocketsLayer $ssl -ApplicationPoolAccount $SPWebApplicationAccount  | select URL      
        $SiteURL= New-SPWebApplication -Name $SPWebApplicationName -Port $SPWebApplicationPort -ApplicationPool $SPWebApplicationAppPool -AuthenticationProvider $authencationprovider -AllowAnonymousAccess -SecureSocketsLayer -ApplicationPoolAccount (get-SPManagedAccount $SPWebApplicationAccount)  | select URL      
        }

        else
        {
        Write-host "SP Web Applcation $SPWebApplicationName already exists"
        }
        $SPWebURL=$SiteURL.Url

        Write-Host "SPWebapplication URL : "$SPWebURL -ForegroundColor Green

        $spsiteexists= Get-SPSite $SPWebURL -ErrorAction SilentlyContinue

        $SPSiteCollectionName = $SPSiteCollectionName;
        $SPSiteCollectionTemplate = "STS#1"
        $SSPiteCollectionLanguage = "1033"
        if ($spsiteexists -eq $null )
        {
            Write-host "Displaying SP Site Collection Properties" -ForegroundColor Yellow
            Write-Host "SPSiteCollectionName     : "$SPSiteCollectionName  -ForegroundColor Green
            Write-Host "SPSiteCollectionTemplate : "$SPSiteCollectionTemplate -ForegroundColor Green
            Write-Host "SSPiteCollectionLanguage : "$SSPiteCollectionLanguage -ForegroundColor Green
            Write-Host "SPWebApplicationAccount  : "$SPWebApplicationAccount -ForegroundColor Green

    
            # Create a new Sharepoint Site Collection

            #New-SPSite -Description -Url -Language -Template -Name -QuotaTemplate -OwnerEmail -OwnerAlias -SecondaryEmail -SecondaryOwnerAlias -HostHeaderWebApplication -ContentDatabase -SiteSubscription -AdministrationSiteType -AssignmentCollection -Verbose -Debug -ErrorAction -WarningAction -ErrorVariable -WarningVariable -OutVariable -OutBuffer
            #New-SPSite -Description "Root" -Url -Language -Template -Name -QuotaTemplate -OwnerEmail -OwnerAlias -SecondaryEmail -SecondaryOwnerAlias -HostHeaderWebApplication -ContentDatabase -SiteSubscription -AdministrationSiteType -AssignmentCollection -Verbose -Debug -ErrorAction -WarningAction -ErrorVariable -WarningVariable -OutVariable -OutBuffer
            Write-host "New-SPSite -URL $SPWebURL -OwnerAlias $SPWebApplicationAccount -Language $SSPiteCollectionLanguage -Template $SPSiteCollectionTemplate -Name $SPSiteCollectionName -SecondaryOwnerAlias "wse\ppeddigari" " -ForegroundColor Green
                        New-SPSite -URL $SPWebURL -OwnerAlias $SPWebApplicationAccount -Language $SSPiteCollectionLanguage -Template $SPSiteCollectionTemplate -Name $SPSiteCollectionName -SecondaryOwnerAlias "wse\ppeddigari"

        }

        else
        {
            Write-host "SP Sitecollection already exists"
         }


  }
Catch [System.Exception]
 {
    write-host "Exception Block"
    write-host $_.exception.message
      
}

}

CreateSP-WebApplication -Serviceaccount $Serviceaccount -SPWebAppName $SPWebAppName -SPWebAppPort $SPWebAppPort -SPSiteCollectionName $SPSiteCollectionName