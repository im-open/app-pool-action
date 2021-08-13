Param(
    [parameter(Mandatory = $true)]
    [ValidateSet( 'app-pool-start', 'app-pool-stop', 'app-pool-restart')]
    [string]$action,
    [parameter(Mandatory = $true)]
    [string]$server,
    [parameter(Mandatory = $true)]
    [string]$app_pool_name,
    [parameter(Mandatory = $true)]
    [string]$user_id,
    [parameter(Mandatory = $true)]
    [SecureString]$password,
    [parameter(Mandatory = $true)]
    [string]$cert_path
)

$action_prefix = 'app\-pool\-(?<verb>.+)'
$display_action = 'App Pool'

$action -match $action_prefix
$verb = $Matches.verb
$title_verb = (Get-Culture).TextInfo.ToTitleCase($verb)

$display_action += " $title_verb"
$past_tense = "ed"
switch ($verb) {
    "start" {}
    "restart" { break; }
    "stop" { $past_tense = "ped"; break; }
}
$display_action_past_tense = "$display_action$past_tense"

Write-Output "IIS $display_action"
Write-Output "Server: $server - App Pool: $app_pool_name"

$credential = [PSCredential]::new($user_id, $password)
$so = New-PSSessionOption -SkipCACheck -SkipCNCheck -SkipRevocationCheck

Write-Output "Importing remote server cert..."
Import-Certificate -Filepath $cert_path -CertStoreLocation 'Cert:\LocalMachine\Root'

$script = {
    # Relies on WebAdministration Module being installed on the remote server
    # This should be pre-installed on Windows 2012 R2 and later
    # https://docs.microsoft.com/en-us/powershell/module/?term=webadministration

    if ($Using:action -eq 'stop' -or $Using:action -eq 'restart') {
        Stop-WebAppPool -Name $Using:app_pool_name
    }

    if ($Using:action -eq 'start' -or $Using:action -eq 'restart') {
        Start-Sleep 10
        Start-WebAppPool -Name $Using:app_pool_name
    }
}

Invoke-Command -ComputerName $server `
    -Credential $credential `
    -UseSSL `
    -SessionOption $so `
    -ScriptBlock $script

Write-Output "IIS $display_action_past_tense."
