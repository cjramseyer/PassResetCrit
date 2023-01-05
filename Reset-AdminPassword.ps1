
###########################################################################
#
# Reset-AdminPassword.ps1
# Created: 12/14/2021 by feppenst v1.0.0
# Modified:
#
# v1.0.0:
#   - Initial draft
#
###########################################################################

<#
.Synopsis
    Script to reset local administrator password(s)
.Description
    Script to reset local administrator password(s)
.Example
    .\Reset-AdminPassword.ps1
.Example
    .\Reset-AdminPassword.ps1 -ComputerName fmc128215 -Credential (Get-Credential)
.NOTES
    Script by default resets local admin (hford9, hfordgcp, or administrator) account password
#>

#Requires -Version 4.0

[CmdletBinding()]
param
(
    [parameter(Mandatory=$false)][string[]]$ComputerName = "$env:ComputerName",
    [ValidateNotNull()][System.Management.Automation.PSCredential][System.Management.Automation.Credential()]$Credential = [System.Management.Automation.PSCredential]::Empty
)

Function New-RandomPass
{
    [CmdletBinding()]
    param
    (
        [ValidateRange(12, 256)][int]$length = 25
    )

    $symbols = '!@#$%^&*'.ToCharArray()
    $characterList = [char[]]('a'[0]..'z'[0]) + [char[]]('A'[0]..'Z'[0]) + [char[]]('0'[0]..'9'[0]) + $symbols

    do {
        $password = -join (0..$length | ForEach-Object { $characterList | Get-Random })
        [int]$hasLowerChar = $password -cmatch '[a-z]'
        [int]$hasUpperChar = $password -cmatch '[A-Z]'
        [int]$hasDigit = $password -match '[0-9]'
        [int]$hasSymbol = $password.IndexOfAny($symbols) -ne -1
    }
    until (($hasLowerChar + $hasUpperChar + $hasDigit + $hasSymbol) -ge 3)

    return $password
}

$LocalUsers = "hford9","hfordgcp","Administrator"

$ScriptBlock = {
    $newPass = $args[0]
    $LocalUsers = $args[1]

    foreach($LocalUser in $LocalUsers)
    {
        $AutoUser = (Get-LocalUser -Name $LocalUser -ErrorAction SilentlyContinue).Name
        if(-not ([string]::IsNullorEmpty($AutoUser)))
        {
            $SecPass = ConvertTo-SecureString $($newPass) -AsPlainText -Force
            Set-LocalUser "$AutoUser" -Password $SecPass
            $Result = "New password for: $AutoUser is: $newpass"
            return $Result
        }
    }
}

if("$ComputerName" -ne "$env:computername")
{
    foreach($Computer in $ComputerName)
    {
        $Session = New-PSSession -ComputerName $ComputerName -Credential $Credential
        $newPass = New-RandomPass

        $Param = @{
            Session = $Session
            ScriptBlock = $ScriptBlock
            ArgumentList = "$newpass",$LocalUsers
        }

        Invoke-Command @Param
    }
}
else
{
    foreach($LocalUser in $LocalUsers)
    {
        $AutoUser = (Get-LocalUser -Name $LocalUser -ErrorAction SilentlyContinue).Name
        if(-not ([string]::IsNullorEmpty($AutoUser)))
        {
            $newPass = New-RandomPass
            $SecPass = ConvertTo-SecureString $($newPass) -AsPlainText -Force
            Set-LocalUser "$AutoUser" -Password $SecPass
            Write-Output "New password for: $AutoUser is: $newpass"
        }
    }
}
