$usr = Read-Host ("Enter Username")
Get-ADUser $usr -Property LockedOut
$prompt = Read-Host ("Unlock User (y/n)?")
if ("y" -eq $prompt)
{
    Unlock-ADAccount $usr
    Get-ADUser $usr -Property LockedOut
}
