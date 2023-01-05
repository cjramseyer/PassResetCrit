
[ValidateRange(12, 256)][int]$length = 25
$symbols = '!@#$%^&*'.ToCharArray()
$characterList = [char[]]('a'[0]..'z'[0]) + [char[]]('A'[0]..'Z'[0]) + [char[]]('0'[0]..'9'[0]) + $symbols

for($i=1;$i -le 100; $i++)
{
    $password = -join (0..$length | ForEach-Object { $characterList | Get-Random })
    [int]$hasLowerChar = $password -cmatch '[a-z]'
    [int]$hasUpperChar = $password -cmatch '[A-Z]'
    [int]$hasDigit = $password -match '[0-9]'
    [int]$hasSymbol = $password.IndexOfAny($symbols) -ne -1
    Write-Output $password
}
