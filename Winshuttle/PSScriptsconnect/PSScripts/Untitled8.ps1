$name=$env:COMPUTERNAME
$certhash=Get-ChildItem -Path Cert:\LocalMachine\my -Recurse | Where-Object {$_.Subject -match "$name."} | Select Thumbprint
$appid=[guid]::NewGuid()
& netsh http add sslcert ipport=0.0.0.0:444 certhash=$print "appid={$appid}"
New-WebBinding -Name Sentinel -Protocol https -Port 444 


[xml]$xmlDoc = New-Object system.Xml.XmlDocument
$xmlElt = $xmlDoc.CreateElement("ConfigData")
$xmlDoc.AppendChild($xmlElt);

$xmlElt1 = $xmlDoc.CreateElement("SPURL")
$xmlSubText = $xmlDoc.CreateTextNode("Network")
$xmlElt1.AppendChild($xmlSubText)

$xmlElt.AppendChild($xmlElt1);

$xmlDoc.Save("c:\tempdir\Config.xml")



[xml]$appSettingsXml = @"
<Config>
    <add key="WebMachineIdentifier" value="$webIdentifier" />
</Config>
"@
$xml.AppendChild($appSettingsXml);