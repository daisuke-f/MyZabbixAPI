# SYNOPSIS

MyZabbixAPI.ps1 is a set of PowerShell commands for using [Zabbix API](https://www.zabbix.com/documentation/current/en/manual/api).

# Usage

## 1. Include MyZabbixAPI.ps1

```
PS> . ./MyZabbixAPI.ps1
```

## 2. Connect to your Zabbix Server

```
PS> Connect-Zabbix your-zabbix-server.example
```

This prompts you to input username and password for authentication.

Once being successfully connected, session informations including authentication token are saved as a global variable `$ZabbixContext`.

## 3. Execute a Zabbix API method

```
PS> Invoke-Zabbix host.get @{ output=@('hostid', 'name') }

hostid name
------ ----
10084  Zabbix server
10335  Raspberry Pi

```

This example executes [host.get](https://www.zabbix.com/documentation/current/en/manual/api/reference/host/get) API method to get all host information on the Zabbix server.

`Invoke-Zabbix` returns result as objects unless `-RawResponse` switch is set. So you can easily manipulate the outputs for later processing.

## 4. Disconnect

```
PS> Disconnect-Zabbix
```