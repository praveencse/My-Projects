$subusername = "wsdevtempadmin@pramodjenawinshuttle.onmicrosoft.com"
            $subpassword = "`$abcd12345"
            $Serviceusername=$subusername;
            $Servicepassword=$subpassword;
            $secpasswd = ConvertTo-SecureString $Servicepassword -AsPlainText -Force
            $credential = New-Object -TypeName System.Management.Automation.PSCredential ($Serviceusername, $secpasswd)
            $cred = Get-Credential -cred $credential

            Write-Host "Authenticating to Azure" -ForegroundColor Green
            $account = Add-AzureAccount -Credential $cred -ErrorAction Stop
