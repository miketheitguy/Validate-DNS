<#
.SYNOPSIS

Returns list of DNS name objects.

.DESCRIPTION

This script provides an outputted list of DNS Name objects and whether
their forward and reverse DNS lookups match.

This script operates on IPv4 only.

.EXAMPLE

<PS C:\> .\Validate-DNS.ps1 -FilePath "C:\users\admin\desktop\dnslist.txt"

Name                           IP            Match ReverseName
----                           --            ----- -----------
mail.contoso.com              192.168.1.2   True   mail.contoso.com
contoso.com                  10.0.0.2      False  host.fabrikam.com

#>

[CmdletBinding()]
param (
    [parameter(Mandatory = $true)]
    [string]
    $FilePath
)

if (-not(Test-Path -Path $FilePath)) {
    Write-Error -Message "File Does Not Exist!"
}
else {
    $DNSList = Get-Content -Path $FilePath
    $dnsResultObjectArray = @()
    $status = 0

    foreach ($dnsEntry in $DNSList) {
        $status++
        Write-Progress -Activity "Performing DNS lookups (Current Name: $dnsEntry)" -Status "Entry $status of $($DNSList.Count)"

        # I blank/recreate the array on each loop of DNS entries in the list.
        $forwardResultArray = @()

        # DNS results can return multiple answers. So Resolve-DNSName returns each one as its own object.
        # This way, we're going to act on each returned result.

        $forwardResult = Resolve-DNSName -Name $dnsEntry -DnsOnly -Type A -QuickTimeout -ErrorAction SilentlyContinue

        if (-not($forwardResult)) {
            $Error
        }

        else {
            #$forwardResult
            $forwardResultArray += $forwardResult
        }

        foreach ($fwResult in $forwardResultArray) {

            # I blank/recreate the array on each loop of forward results.
            $reverseResultArray = @()
            $reverseResult = ""
            # DNS results can return multiple answers. So Resolve-DNSName returns each one as its own object.
            # This way, we're going to act on each returned result.

            $reverseResult = Resolve-DNSName -Name $fwResult.IPAddress -Type PTR -QuickTimeout -ErrorAction SilentlyContinue

            # There might not be any reverse results, so we'll just treat this as a mismatch rather than an error.
            if (-not($reverseResult)) {
                $dnsResultObject = [PSCustomObject]@{
                    Name  = ""
                    IP    = $fwResult.IPAddress
                    Match = $false
                    ReverseName = ""
                }

                $dnsResultObjectArray += $dnsResultObject
            }
            else {
            
                $reverseResultArray += $reverseResult
                 
            }

            foreach ($rvResult in $reverseResultArray) {

                if ($rvResult.NameHost -eq $dnsEntry) {
                    $resultMatch = $true
                    $reverseName = $rvResult.NameHost
                }
                else {
                    $resultMatch = $false
                    $reverseName = $rvResult.NameHost
                }
    
                $dnsResultObject = [PSCustomObject]@{
                    Name  = $dnsEntry
                    IP    = $fwResult.IPAddress
                    Match = $resultMatch
                    ReverseName = $reverseName
                }
    
                $dnsResultObjectArray += $dnsResultObject
            }
        }
    }        
}

$dnsResultObjectArray