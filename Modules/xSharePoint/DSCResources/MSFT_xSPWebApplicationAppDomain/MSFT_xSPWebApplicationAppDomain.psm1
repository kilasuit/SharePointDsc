function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [parameter(Mandatory = $true)]  [System.String]  $AppDomain,
        [parameter(Mandatory = $true)]  [System.String]  $WebApplication,
        [parameter(Mandatory = $true)]  [System.String] [ValidateSet("Default","Internet","Intranet","Extranet","Custom")] $Zone,
        [parameter(Mandatory = $false)] [System.UInt32]  $Port,
        [parameter(Mandatory = $false)] [System.Boolean] $SSL,
        [parameter(Mandatory = $false)] [System.Management.Automation.PSCredential] $InstallAccount

    )

    Write-Verbose -Message "Checking app urls settings"

    $result = Invoke-xSharePointCommand -Credential $InstallAccount -Arguments $PSBoundParameters -ScriptBlock {
        $params = $args[0]
        $webAppAppDomain = Get-SPWebApplicationAppDomain -WebApplication $params.WebApplication -Zone $params.Zone

        if ($null -eq $webAppAppDomain) {
            return $null
        } else {
            return @{
                AppDomain = $webAppAppDomain.AppDomain 
                WebApplication = $params.WebApplication
                Zone = $webAppAppDomain.UrlZone
                Port = $webAppAppDomain.Port
                SSL = $webAppAppDomain.IsSchemeSSL
                InstallAccount = $params.InstallAccount
            }
        }
    }
    return $result
}

function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [parameter(Mandatory = $true)]  [System.String]  $AppDomain,
        [parameter(Mandatory = $true)]  [System.String]  $WebApplication,
        [parameter(Mandatory = $true)]  [System.String] [ValidateSet("Default","Internet","Intranet","Extranet","Custom")]  $Zone,
        [parameter(Mandatory = $false)] [System.UInt32]  $Port,
        [parameter(Mandatory = $false)] [System.Boolean] $SSL,
        [parameter(Mandatory = $false)] [System.Management.Automation.PSCredential] $InstallAccount
    )

    $CurrentValues = Get-TargetResource @PSBoundParameters
    Write-Verbose -Message "Updating app domain settings "

    Invoke-xSharePointCommand -Credential $InstallAccount -Arguments @($PSBoundParameters, $CurrentValues) -ScriptBlock {
        $params = $args[0]
        $CurrentValues = $args[1]

        if ($null -ne $CurrentValues) {
            Get-SPWebApplicationAppDomain -WebApplication $params.WebApplication -Zone $params.Zone | Remove-SPWebApplicationAppDomain
            Start-Sleep -Seconds 5
        }

        $newParams = @{
            AppDomain = $params.AppDomain
            WebApplication = $params.WebApplication 
            Zone = $params.Zone
        }
        if ($params.ContainsKey("Port") -eq $true) { $newParams.Add("Port", $params.Port) }
        if ($params.ContainsKey("SSL") -eq $true) { $newParams.Add("SecureSocketsLayer", $params.SSL) }

        New-SPWebApplicationAppDomain @newParams
    }
}

function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [parameter(Mandatory = $true)]  [System.String]  $AppDomain,
        [parameter(Mandatory = $true)]  [System.String]  $WebApplication,
        [parameter(Mandatory = $true)]  [System.String] [ValidateSet("Default","Internet","Intranet","Extranet","Custom")]  $Zone,
        [parameter(Mandatory = $false)] [System.UInt32]  $Port,
        [parameter(Mandatory = $false)] [System.Boolean] $SSL,
        [parameter(Mandatory = $false)] [System.Management.Automation.PSCredential] $InstallAccount
    )

    $CurrentValues = Get-TargetResource @PSBoundParameters
    Write-Verbose -Message "Testing app domain settings"
    if ($null -eq $CurrentValues) { return $false }
    return Test-xSharePointSpecificParameters -CurrentValues $CurrentValues -DesiredValues $PSBoundParameters -ValuesToCheck @("AppDomain", "Port", "SSL") 
}


Export-ModuleMember -Function *-TargetResource

