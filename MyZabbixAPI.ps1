# requires -Version 5

class ZabbixContext {
    $Uri
    $Created
    $UserName
    $LastRequestId
    $AuthToken
}

class ZabbixAPIError {
    [string] $Code
    [string] $Message
    [object] $Data

    [string] ToString() {
        return ('{0} {1}: {2}' -f $this.Code, $this.Message, ($this.Data | ConvertTo-Json -Depth 10))
    }

    ZabbixAPIError($apiError) {
        $this.Code = $apiError.code
        $this.Message = $apiError.message
        $this.Data = $apiError.data
    }
}

function Connect-Zabbix {
    [CmdletBinding()]
    param(
        [parameter(mandatory)][string] $ZabbixServer,
        [PSCredential] $Credential
    )

    if($null -eq $Credential) {
        $Credential = Get-Credential

        if($null -eq $Credential) {
            return
        }
    }

    $context = Get-ZabbixContext -CreateIfNotExists

    $context.Uri = $(
        if($ZabbixServer -match '^(https?:\/\/)?([^\/]+)(\/.*)?$') {
            $protocol = $matches[1]
            $hostname = $matches[2]
            $urlpath = $matches[3]

            if([string]::IsNullOrEmpty($protocol)) {
                $protocol = 'https://'
            }
            if([string]::IsNullOrEmpty($urlpath) -or ($urlpath -eq '/')) {
                $urlpath = '/zabbix/api_jsonrpc.php'
            }
            if($urlpath -notlike '*/api_jsonrpc.php') {
                $urlpath += '/api_jsonrpc.php'
                $urlpath = $urlpath -replace '\/\/', '/'
            }

            Write-Output ($protocol + $hostname + $urlpath)
        } else {
            throw [ArgumentException]::new('Parameter "ZabbixServer" should be a hostname or complete url.')
        }
    )

    $param = @{
        user = $Credential.UserName
        password = $Credential.GetNetworkCredential().Password
    }

    $login = Invoke-Zabbix -Method user.login -Parameter $param

    if($null -eq $login) {
        return
    }

    $context.UserName = $param.user
    $context.LastRequestId = 1
    $context.AuthToken = $login

    Write-Output $context
}

function Get-ZabbixContext {
    [CmdletBinding()]
    param(
        [switch] $CreateIfNotExists
    )

    $contextVar = Get-Variable -Scope Global -Name ZabbixContext -ErrorAction SilentlyContinue

    if($null -eq $contextVar) {
        if($CreateIfNotExists) {
            $context = [ZabbixContext]::new()
            $context.Created = Get-Date

            Set-Variable -Scope Global -Name ZabbixContext -Value $context
        } else {
            $context = $null
        }
    } else {
        $context = $contextVar.Value
    }

    return $context
}

function Invoke-Zabbix {
    [CmdletBinding()]
    param(
        [parameter(mandatory)][string] $Method,
        $Parameter = @{},
        $Context,
        [switch] $RawResponse
    )

    if($null -eq $Context) {
        $Context = Get-ZabbixContext

        if($null -eq $Context) {
            Write-Error 'No ZabbixContext. Execute "Connect-Zabbix" first.'
            return
        }
    }

    $requestBody = @{
        jsonrpc = '2.0'
        method = $Method
        params = $Parameter
        id = 1
        auth = $null
    }

    switch($Method) {
        'user.login' {}
        'apiinfo.version' {
            $requestBody.Remove('auth')
        }
        default {
            $requestBody.id = ++ $context.LastRequestId
            $requestBody.auth = $context.AuthToken
        }
    }

    $irmParam = @{
        Uri = $Context.Uri
        Method = 'Post'
        Headers = @{'Content-Type' = 'application/json-rpc'}
        Body = $requestBody | ConvertTo-Json -Depth 10
    }

    Write-Verbose ('URL: {0}' -f $irmParam.Uri)
    Write-Verbose ('Request Body: {0}' -f $irmParam.Body)

    $resp = Invoke-RestMethod @irmParam

    if($null -eq $resp) {
        # Error (HTTP)
        return $null
    } elseif($RawResponse) {

        return $resp
    } elseif($resp.PSObject.Properties.Name -contains 'error') {
        # Error (API)
        throw [ZabbixAPIError]::new($resp.error)
        return $null
    } else {
        # Success
        return $resp.result
    }
}

function Disconnect-Zabbix {
    [CmdletBinding()]
    param()

    $Context = Get-ZabbixContext

    $resp = Invoke-Zabbix user.logout

    Remove-Variable -Scope Global -Name ZabbixContext

    return $resp
}
