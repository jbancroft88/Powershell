### NOTE: In order for the script to work, you must define the first 3 variables:
# > Manually input the $ADSearchBase information of the domain controller (example placeholder below) 
# > Update the the $pwdExpireDate .AddDays value based on the organization password reset policy (with negative numbers representing maximum password age in Days)
# > Update the the $pwdThreshold to define date offset of soon-to-expire passwords (with positive numbers representing the offset in Days)

# Customise variables
$ADSearchBase = "OU=Users,OU=London,DC=company,DC=net"
$pwdExpireDate = (Get-Date).AddDays(-90)
$pwdThreshold = 7

# Collect user information from Domain Controller
$ErrorActionPreference = "Stop"
Write-Host("Querying Domain Controller...")
$adusers = get-aduser -Filter * -SearchBase $ADSearchBase -properties passwordlastset, LockedOut, Enabled | Select-Object Name, passwordlastset, LockedOut, Enabled

# Set Options
$ste = New-Object System.Management.Automation.Host.ChoiceDescription "&Soon-to-Expire PWDs","List accounts which password expires in < $pwdThreshold days"
$expired = New-Object System.Management.Automation.Host.ChoiceDescription "&Expired PWDs","List accounts whose password have expired"
$locked = New-Object System.Management.Automation.Host.ChoiceDescription "&Locked Accounts","List accounts which are currently locked"
$disabled = New-Object System.Management.Automation.Host.ChoiceDescription "&Disabled Accounts","List accounts which are currently disabled"
$cancel = New-Object System.Management.Automation.Host.ChoiceDescription "&Cancel","Cancel Operation / Exit Script"
$options = [System.Management.Automation.Host.ChoiceDescription[]]($ste,$expired,$locked,$disabled,$cancel)

# Filter data based on user choice
do {
$prompt = $Host.UI.PromptForChoice("Select Operation","----------------",$options,4)
Write-Host("")
    if (0 -eq $prompt) {
        foreach ($user in $adusers) {
            if ($true -eq $user.Enabled) {
                $d = ($user.passwordlastset - $pwdExpireDate).Days
                $h = ($user.passwordlastset - $pwdExpireDate).Hours
                $username = $user.Name
                if (($user.passwordlastset -le ($pwdExpireDate).AddDays($pwdThreshold)) -and ($user.passwordlastset -ge $pwdExpireDate)) {
                    Write-Host("$username : Password will expire in $d days $h hours.")
                }}}
    }
    elseif (1 -eq $prompt) {
        foreach ($user in $adusers) {
            if ($true -eq $user.Enabled) {
                $d = ($user.passwordlastset - $pwdExpireDate).Days
                $username = $user.Name
                if ($user.passwordlastset -lt $pwdExpireDate) {
                    Write-Host("$username : Password expired $d days ago.")
                }}}
    }
    elseif (2 -eq $prompt) {
        foreach ($user in $adusers) {
            if ($true -eq $user.LockedOut) {
                Write-Host($user.Name)
            }}
    }
    elseif (3 -eq $prompt) {
        foreach ($user in $adusers) {
            if ($false -eq $user.Enabled) {
                Write-Host($user.Name)
            }}
    }    
} until (4 -eq $prompt)
