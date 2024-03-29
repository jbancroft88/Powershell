# ADIEU: Active DIrectory Express Utility
# Allows basic AD Administration (Querying AD user account information, Account Unlock / Password Peset) from the shell.
# Must be run as a user with appropriate admin privileges.

# Optionally use the [-s] switch to perform a wildcard search
# Ex: -s john
# Will return a list of usernames which contain "john"

Write-Host('
================================================
 $$$$$$\  $$$$$$$\  $$$$$$\ $$$$$$$$\ $$\   $$\ 
$$  __$$\ $$  __$$\ \_$$  _|$$  _____|$$ |  $$ |
$$$$$$$$ |$$ |  $$ |  $$ |  $$$$\     $$ |  $$ |
$$ |  $$ |$$$$$$$  |$$$$$$\ $$$$$$$$\ \$$$$$$  |
\__|  \__|\_______/ \______|\________| \______/           
===================== v0.4 =====================
')

$uinput = Read-Host("Enter Username")
$spin = @($uinput -split " ")
if (("-s" -eq $spin[0]) -and ($null -ne $spin[1])) {
    $sqry = $spin[1]
    $wqry = '"*' + $sqry + '*"'
    Get-ADUser -Filter "SamAccountName -like $wqry" | Format-Table SamAccountName
    $usr = Read-Host("Enter Username")
}
elseif (("-s" -eq $spin[0]) -and ($null -eq $spin[1])) {
    Write-Host("Can not query NULL value!")
    break
}
else {
    $usr = $uinput
}

$usrobj = Get-ADUser $usr -Property *
$usrlock = $usrobj.LockedOut
Write-Host("
AD Information
----------------")
Write-Host("FullName   : " + $usrobj.Name)
Write-Host("Enabled    : " + $usrobj.Enabled)
Write-Host("LockedOut  : " + $usrobj.LockedOut)
Write-Host("PwdLastSet : " + $usrobj.passwordlastset)

$unlock = New-Object System.Management.Automation.Host.ChoiceDescription "&Unlock Account","Unlock AD Account"
$reset = New-Object System.Management.Automation.Host.ChoiceDescription "&Reset Password","Reset AD Account Password"
$qgrp = New-Object System.Management.Automation.Host.ChoiceDescription "Query &Groups","List groups which this account is a Member-Of"
$cancel = New-Object System.Management.Automation.Host.ChoiceDescription "&Cancel","Cancel Operation"
$options = [System.Management.Automation.Host.ChoiceDescription[]]($unlock,$reset,$qgrp,$cancel)
$prompt = $Host.UI.PromptForChoice("Select Operation","----------------",$options,3)
Write-Host("")

if (0 -eq $prompt)
{   
    if ($usrlock -eq "True") {
        Unlock-ADAccount $usr
        Write-Host("Account Unlocked!")
    }
    else {
        Write-Host("Account is not Locked")
    }
}
elseif (1 -eq $prompt)
{
    $passwd = Read-Host("Enter Password") 
    Set-ADAccountPassword -Identity $usr -Reset -NewPassword (ConvertTo-SecureString -AsPlainText $passwd -Force)
    Write-Host("Password Reset!")
}
elseif (2 -eq $prompt)
{
    Write-Host("
Member Of
----------------")
    $glist = $usrobj.MemberOf
    foreach ($group in $glist) {
        $cgroup = @($group -split ",")
        Write-Host($cgroup[0] -replace "CN=", "")
    }
}
