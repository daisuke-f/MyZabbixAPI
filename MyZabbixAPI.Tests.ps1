#requires -Version 5

$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace '\.Tests\.', '.'

. "$here\$sut"

Describe "Test Config" {
    . "$here\MyZabbixAPI.TestsConfig.ps1"

    It "defines ZabbixUri, ZabbixUser and ZabbixPassword" {
        $ZabbixUri | Should -Not -BeNullOrEmpty
        $ZabbixUserName | Should -Not -BeNullOrEmpty
        $ZabbixPassword | Should -Not -BeNullOrEmpty
    }
}

Describe "Invoke-Zabbix" {
    . "$here\MyZabbixAPI.TestsConfig.ps1"

    It "returns raw response object from Zabbix server using -RawResponse parameter" {
        $context = [ZabbixContext]::new()
        $context.Uri = $ZabbixUri

        $resp = Invoke-Zabbix apiinfo.version -Context $context -RawResponse

        $resp | Should -Not -BeNull
        $resp.PSObject.Properties.Name | Should -Contain 'jsonrpc'
        $resp.PSObject.Properties.Name | Should -Not -Contain 'error'
        $resp.PSObject.Properties.Name | Should -Contain 'result'
        $resp.result | Should -Match '^[0-9]+(\.[0-9]+)*$'
    }

    It "returns result object of method" {
        $context = [ZabbixContext]::new()
        $context.Uri = $ZabbixUri

        $resp = Invoke-Zabbix apiinfo.version -Context $context
        
        $resp | Should -Match '^[0-9]+(\.[0-9]+)*$'
    }
}

Describe "Connect-Zabbix" {
    . "$here\MyZabbixAPI.TestsConfig.ps1"

    It "logins on Zabbix server" {
        $credential = [PSCredential]::new($ZabbixUserName, (ConvertTo-SecureString $ZabbixPassword -AsPlainText))
        $resp = Connect-Zabbix $ZabbixUri $credential

        $resp.GetType().FullName | Should -BeExactly 'ZabbixContext'
        # $resp | Should -BeOfType [ZabbixContext]
    }
}