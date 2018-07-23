# ACS configuration information
$user = "ManagementClient"
$password = "hnas/RDlOatda2jTfMzbrzO4tivVmWMlLiFpSBX0Ky0=" # This is indeed not my real password
$namespace = "wstempdev"
$hostname = "accesscontrol.windows.net"
$relativeUrl = "v2/mgmt/service/"


Function GetTokenFromAcs
{
    $baseAddress = "https://$namespace.$hostname"
    $endpoint = "https://$namespace.$hostname/$relativeUrl"
 
    $client = New-Object -TypeName System.Net.Webclient
    $client.BaseAddress = $baseAddress
 
    $values = New-Object -TypeName Collections.Specialized.NameValueCollection
    $values.Add("grant_type", "client_credentials")
    $values.Add("client_id", $user)
    $values.Add("client_secret", $password)
    $values.Add("scope", $endpoint)
 
    $responseBytes = $client.UploadValues("/v2/OAuth2-13", "POST", $values)&nbsp;
    $response = [System.Text.Encoding]::UTF8.GetString($responseBytes)
 
    $serializer = New-Object -TypeName System.Web.Script.Serialization.JavaScriptSerializer
    $decodedDictionary = $serializer.DeserializeObject($response)
 
    if ($decodedDictionary -eq $null)
    {
        throw "An error occured while deserializing the access token: the response is null."
    }
    return $decodedDictionary["access_token"]
}