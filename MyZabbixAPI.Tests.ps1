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

    It "invokes Zabbix APIs with a parameter of Array type" {
        $credential = [PSCredential]::new($ZabbixUserName, (ConvertTo-SecureString $ZabbixPassword -AsPlainText))

        Connect-Zabbix $ZabbixUri $credential

        # Theses minus scriptids never exist. So we safely use them to test for executing delete APIs.
        # A parameter error might be returned from Zabbix but we don't care in this test case.
        { Invoke-Zabbix script.delete @( -1, -2 ) -RawResponse } | Should -Not -Throw

        Disconnect-Zabbix
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