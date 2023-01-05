
###########################################################################
#
# Reset-CritPassword.ps1
# Created: 6/01/2020 by feppenst v1.0.0
# Modified: 11/10/2021 by cramse22 v1.2.1
#
# v1.2.1:
#   - Added script header
#   - Incorporated password generator
#   - Added validation that password change has replicated
#   - Added logic to complete 2 cycles for the KRBTGT password waiting for replication to complete
#   - Updated replication vliadation logic to check each domain
#   - Added recorded password file destruction automation
#   - Change Invoke-Command to Start-Job to avoid potential failure with WSMAN
#
###########################################################################

<#
.Synopsis
    Script to reset password for critical accounts
.Description
    Script to reset password for critical accounts
.Parameter Account
    Optional parameter to specify the account whose password should be reset
    If NOT specified, the script assumes the account is krbtgt
.Parameter Domain
    Optional parameter to specify a specific domain in the current forest to locate the specified account
    If NOT specified, the script will assume ALL domains in the current forest
.Example
    .\Reset-CritPassword.ps1
    NOTE: will reset krbtgt in ALL domains in the current environment
.Example
    .\Reset-CritPassword.ps1 -Account testtgt
    NOTE: Will reset the testtgt account in all domains
.Example
    .\Reset-CritPassword.ps1 -Account testtgt -Domain xna1.devad.ford.com
    NOTE: Will reset the testtgt account in the xna1.devad.ford.com
.NOTES
    - Script will look for the specified account in ALL domains in the current forest, unless a specific domain is specified
    - The script will only reset passwords for account in the current domain/forest, cross domain/forest functionality is not supported
#>

#Requires -Version 4.0

[CmdletBinding()]
param
(
    [parameter(Mandatory=$false)][string]$Account = 'testtgt'
)

DynamicParam
{
    $ParameterName = 'Domain'

    $RuntimeParameterDictionary = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary

    # Create the collection of attributes
    $AttributeCollection = New-Object System.Collections.ObjectModel.Collection[System.Attribute]

    # Create and set the parameters' attributes
    $ParameterAttribute = New-Object System.Management.Automation.ParameterAttribute
    $ParameterAttribute.Mandatory = $false
    $ParameterAttribute.Position = 6

    # Add the attributes to the attributes collection
    $AttributeCollection.Add($ParameterAttribute)

    # Generate and set the ValidateSet
    $arrSet = (Get-ADForest).Domains
    $ValidateSetAttribute = New-Object System.Management.Automation.ValidateSetAttribute($arrSet)

    # Add the ValidateSet to the attributes collection
    $AttributeCollection.Add($ValidateSetAttribute)

    # Create and return the dynamic parameter
    $RuntimeParameter = New-Object System.Management.Automation.RuntimeDefinedParameter($ParameterName, [string], $AttributeCollection)
    $RuntimeParameterDictionary.Add($ParameterName, $RuntimeParameter)
    return $RuntimeParameterDictionary
}

begin
{
    $Domain = $PsBoundParameters[$ParameterName]
    $CurDir = split-path -parent $MyInvocation.MyCommand.Definition
    $ModulesToRemove = @()
    $cDate = Get-Date -Format MMddyyyy-HHmm
    $LogFile = "C:\INSTAPPS\Reset-CritPasswordLog-$cDate.log"
    #$DataFile = "C:\INSTAPPS\Reset-CritPasswordData-$cDate.log"

    if(Test-Path $CurDir\PasswordResetCrit.psd1)
    {
        $ModulesToRemove += Import-Module $CurDir\PasswordResetCrit.psd1 -PassThru -Force
    }
    else
    {
        Write-Output "Critical Password reset module not available;exiting"
        Exit 1
    }

    Start-Transcript -Path $LogFile -Append -Force
}

process
{
    $ResultData = "" | Select-Object "TestPassword","Status","PasswordLength"

    if(-not ([string]::IsNullorEmpty($Domain)))
    {
        $Domains = $Domain
    }
    else
    {
        $Domains = (Get-ADForest).domains | Sort-Object
    }

    Write-Output "The password will be reset for Account: $Account"
    Write-Output "Password reset will be applied to the following domain(s):"
    $Domains

    if($Account -eq 'krbtgt')
    {
        #Forced to a single cycle while validating how rapidly to perform krbtgt password change
        $Cycles = 1
    }
    else
    {
        $Cycles = 1
    }

    $Output = @()

    for ($i = 0; $i -lt $Cycles; $i++)
    {
        foreach ($Domain in $Domains)
        {
            $y = 0
            $DCs = @()
            $DCs += (Get-ADDomainController -Server $Domain -Filter *).hostname
            $y = $DCs.count

            Write-Output "Resetting $Account in $Domain"
            $ResultData.TestPassword = "$Account"

            try
            {
                $SecurePass = New-SecurePass2 -ErrorAction Stop
                $PasswordLength = $SecurePass.Length
                if($Account -ne "krbtgt")
                {
                    Write-Output "$Domain : $SecurePass"
                    $Output += "$Domain : $SecurePass"
                }

                $SecureString = ConvertTo-SecureString "$SecurePass" -AsPlainText -Force -ErrorAction Stop
                [datetime]$ValidateTime = Get-Date -Format "MM/dd/yyyy HH:mm:ss" -ErrorAction Stop
                Set-ADAccountPassword -Server $Domain -Identity $Account -Reset -NewPassword $SecureString -ErrorAction Stop
                $ResultData.TestPassword = "$Account"
                $ResultData.Status = "Pass"
                $ResultData.PasswordLength = $PasswordLength
            }
            catch
            {
                $error[0]
                $ResultData.Status = "Fail"
                $ResultData.PasswordLength = $PasswordLength
            }
            finally
            {
                if ($error[0] -like "*The password does not meet the length, complexity, or history requirement of the domain.*")
                {
                    $Result = [char]34 + $SecurePass + [char]34 + "," + [char]34 + "Fail" + [char]34 + "," + [char]34 + $PasswordLength + [char]34
                }
                else
                {
                    $Result = [char]34 + $SecurePass + [char]34 + "," + [char]34 + "Success" + [char]34 +  "," + [char]34 + $PasswordLength + [char]34
                }
                Write-Output $Result
                $Error.clear()
                #$ResultData | Out-File -FilePath $DataFile -Append
            }

            $continue=$true

            Write-Output "Validating replication of password change for account: $Account"
            Write-Output "Domain: $Domain - Validation Time: $ValidateTime"
            Do
            {
                $x=0

                foreach($DC in $DCs)
                {
                    try
                    {
                        $TimeChanged = (Get-ADObject -Server $DC -LDAPFilter "(&(objectcategory=user)(name=$Account))" -Properties whenchanged -ErrorAction Stop).whenchanged
                    }
                    catch
                    {
                        Write-Output "Unable to successfully validate $Account on $DC"
                        break
                    }

                    if($TimeChanged -ge $ValidateTime)
                    {
                        $x++
                    }
                }

                if($x -eq $y)
                {
                    $continue = $false
                }
            }
            While($continue -ne $false)

            Write-Output "Replication of the password change for $Account in $Domain has been completed."
        }

        #Do we need a wait before performing the second time

        if($Cycles -eq 2)
        {
            foreach($Domain in $Domains)
            {
                Write-Output "Resetting $Account in $Domain Cycle 2" | Out-File $LogFile -Append

                try
                {
                    $SecurePass = New-SecurePass2
                    $PasswordLength = $SecurePass.Length
                    $SecureString = ConvertTo-SecureString "$SecurePass" -AsPlainText -Force
                    Set-ADAccountPassword -Server $Domain -Identity $Account -Reset -NewPassword $SecureString
                }
                catch
                {
                    $error[0]
                }
                finally
                {
                    if ($error[0] -like "*The password does not meet the length, complexity, or history requirement of the domain.*")
                    {
                        $Result = [char]34 + $SecurePass +[char]34 + "," + [char]34 + "Fail" + [char]34 + "," + [char]34 + $PasswordLength + [char]34
                    }
                    else
                    {
                        $Result = [char]34 + $SecurePass + [char]34 + "," + [char]34 + "Success" + [char]34 +  "," + [char]34 + $PasswordLength + [char]34
                    }
                    $Error.clear()
                    Write-Output $Result
                }
            }
        }
    }

    $Output | Out-File -FilePath "C:\INSTAPPS\CritInfo.txt"
    Write-Output "Information has been written out to C:\INSTAPPS\CritInfo.txt"
    Write-Output "Record the information in this file in a secure location"
    Write-Warning "This file C:\INSTAPPS\CritInfo.txt WILL BE DELETED 2 minutes after script completes"
    Write-Warning "ALL INSTANCES OF NOTEPAD THAT ARE OPEN WILL BE FORCIBLY CLOSED"

    $ScriptBlock = {
        if(Test-Path C:\INSTAPPS\CritInfo.txt)
        {
            Start-Sleep 120
            #Check for instances of Notepad that are open and close them
            $procs = Get-Process -Name notepad -IncludeUserName
            foreach($proc in $procs)
            {
                $procID = $proc.id
                Stop-Process $procid -Force -Confirm:$false
            }
            Remove-Item C:\INSTAPPS\CritInfo.txt -Force -Confirm:$False
            Get-Job | Remove-Job
        }
    }

    Start-Job -ScriptBlock $ScriptBlock

    $ModulesToRemove | Remove-Module
}
