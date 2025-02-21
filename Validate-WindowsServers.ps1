
<# 
.NAME
    Windows Server Validator
.SYNOPSIS
    UI for sysadmins to quickly validate multiple windows servers and services after a reboot or service outage.
.INPUTS
    Fully-Qualified Domain Names, Hostnames, or IP Addresses of Windows Servers on the network that you want to scan.
(Optional) Name(s) of service(s) whose status to check on the remote systems.

#>

Add-Type -AssemblyName System.Windows.Forms
[System.Windows.Forms.Application]::EnableVisualStyles()

$ServerValidationForm            = New-Object system.Windows.Forms.Form
$ServerValidationForm.ClientSize  = New-Object System.Drawing.Point(558,501)
$ServerValidationForm.text       = "Windows Server Scanner"
$ServerValidationForm.TopMost    = $true

$ServerList                      = New-Object system.Windows.Forms.TextBox
$ServerList.multiline            = $true
$ServerList.text                 = "<hostname(s)>"
$ServerList.width                = 275
$ServerList.height               = 438
$ServerList.Anchor               = 'top,bottom,left'
$ServerList.location             = New-Object System.Drawing.Point(20,40)
$ServerList.Font                 = New-Object System.Drawing.Font('Microsoft Sans Serif',14)

$ExecuteScan                     = New-Object system.Windows.Forms.Button
$ExecuteScan.text                = "Scan"
$ExecuteScan.width               = 122
$ExecuteScan.height              = 30
$ExecuteScan.Anchor              = 'right,bottom'
$ExecuteScan.location            = New-Object System.Drawing.Point(421,456)
$ExecuteScan.Font                = New-Object System.Drawing.Font('Microsoft Sans Serif',10)

$IntervalTxt                     = New-Object system.Windows.Forms.TextBox
$IntervalTxt.multiline           = $false
$IntervalTxt.text                = "5"
$IntervalTxt.width               = 27
$IntervalTxt.height              = 20
$IntervalTxt.Anchor              = 'right,bottom'
$IntervalTxt.location            = New-Object System.Drawing.Point(440,431)
$IntervalTxt.Font                = New-Object System.Drawing.Font('Microsoft Sans Serif',10)

$RefreshLbl2                     = New-Object system.Windows.Forms.Label
$RefreshLbl2.text                = "seconds"
$RefreshLbl2.AutoSize            = $true
$RefreshLbl2.width               = 25
$RefreshLbl2.height              = 10
$RefreshLbl2.Anchor              = 'right,bottom'
$RefreshLbl2.location            = New-Object System.Drawing.Point(475,435)
$RefreshLbl2.Font                = New-Object System.Drawing.Font('Microsoft Sans Serif',10)

$RefreshLbl1                     = New-Object system.Windows.Forms.Label
$RefreshLbl1.text                = "refresh every"
$RefreshLbl1.AutoSize            = $true
$RefreshLbl1.width               = 25
$RefreshLbl1.height              = 10
$RefreshLbl1.Anchor              = 'right,bottom'
$RefreshLbl1.location            = New-Object System.Drawing.Point(442,414)
$RefreshLbl1.Font                = New-Object System.Drawing.Font('Microsoft Sans Serif',10)

$Services                        = New-Object system.Windows.Forms.TextBox
$Services.multiline              = $true
$Services.text                   = "<serviceName(s)>"
$Services.width                  = 238
$Services.height                 = 252
$Services.visible                = $true
$Services.enabled                = $true
$Services.Anchor                 = 'right,bottom'
$Services.location               = New-Object System.Drawing.Point(306,150)
$Services.Font                   = New-Object System.Drawing.Font('Microsoft Sans Serif',14)

$LastRebootChk                   = New-Object system.Windows.Forms.CheckBox
$LastRebootChk.text              = "Last Reboot"
$LastRebootChk.AutoSize          = $false
$LastRebootChk.width             = 238
$LastRebootChk.height            = 20
$LastRebootChk.Anchor            = 'top,right'
$LastRebootChk.location          = New-Object System.Drawing.Point(306,40)
$LastRebootChk.Font              = New-Object System.Drawing.Font('Microsoft Sans Serif',10)

$WinRmChk                        = New-Object system.Windows.Forms.CheckBox
$WinRmChk.text                   = "WinRM Service"
$WinRmChk.AutoSize               = $false
$WinRmChk.width                  = 238
$WinRmChk.height                 = 20
$WinRmChk.Anchor                 = 'top,right'
$WinRmChk.location               = New-Object System.Drawing.Point(306,70)
$WinRmChk.Font                   = New-Object System.Drawing.Font('Microsoft Sans Serif',10)

$RdpChk                          = New-Object system.Windows.Forms.CheckBox
$RdpChk.text                     = "RDP Service"
$RdpChk.AutoSize                 = $false
$RdpChk.width                    = 238
$RdpChk.height                   = 20
$RdpChk.Anchor                   = 'top,right'
$RdpChk.location                 = New-Object System.Drawing.Point(306,100)
$RdpChk.Font                     = New-Object System.Drawing.Font('Microsoft Sans Serif',10)

$SvcChk                          = New-Object system.Windows.Forms.CheckBox
$SvcChk.text                     = "Other Services"
$SvcChk.AutoSize                 = $false
$SvcChk.width                    = 238
$SvcChk.height                   = 20
$SvcChk.Anchor                   = 'right,bottom'
$SvcChk.location                 = New-Object System.Drawing.Point(306,130)
$SvcChk.Font                     = New-Object System.Drawing.Font('Microsoft Sans Serif',10)

$serversLbl                      = New-Object system.Windows.Forms.Label
$serversLbl.text                 = "Server List:"
$serversLbl.AutoSize             = $true
$serversLbl.width                = 25
$serversLbl.height               = 10
$serversLbl.location             = New-Object System.Drawing.Point(16,11)
$serversLbl.Font                 = New-Object System.Drawing.Font('Microsoft Sans Serif',14)

$ServerValidationForm.controls.AddRange(@($ServerList,$ExecuteScan,$IntervalTxt,$RefreshLbl2,$RefreshLbl1,$Services,$LastRebootChk,$WinRmChk,$RdpChk,$SvcChk,$serversLbl))

#--- Helper Functions ---

# Check the status of the RDP (Terminal) service
function Test-RDPService {
    param (
        [string]$Server
    )
    try {
        $service = Get-Service -Name "TermService" -ComputerName $Server -ErrorAction Stop
        return "RDP Service on $Server is $($service.Status)"
    }
    catch {
        return "RDP Service on $($Server): Error - $($_.Exception.Message)"
    }
}

# Check the status of the WinRM service
function Test-WinRMService {
    param (
        [string]$Server
    )
    try {
        $service = Get-Service -Name "WinRM" -ComputerName $Server -ErrorAction Stop
        return "WinRM Service on $Server is $($service.Status)"
    }
    catch {
        return "WinRM Service on $($Server): Error - $($_.Exception.Message)"
    }
}

# Retrieve the last reboot time of the server using CIM
function Get-LastReboot {
    param (
        [string]$Server
    )
    try {
        $os = Get-CimInstance -ClassName Win32_OperatingSystem -ComputerName $Server -ErrorAction Stop
        $lastBoot = $os.LastBootUpTime
        return "Last Reboot for $($Server): $lastBoot"
    }
    catch {
        return "Last Reboot for $($Server): Error - $($_.Exception.Message)"
    }
}

# Check the status of additional services provided in the Services textbox
function Check-OtherServices {
    param (
        [string]$Server,
        [string[]]$ServicesList
    )
    $results = @()
    foreach ($serviceName in $ServicesList) {
        try {
            $svc = Get-Service -Name $serviceName.Trim() -ComputerName $Server -ErrorAction Stop
            $results += "Service '$serviceName' on $Server is $($svc.Status)"
        }
        catch {
            $results += "Service '$serviceName' on $($Server): Error - $($_.Exception.Message)"
        }
    }
    return $results
}

#--- Scan Routine ---

# This function executes when the Scan button is clicked.
function Perform-Scan {
    # Split the ServerList textbox contents by newlines (ignoring empty lines)
    $servers = $ServerList.Text -split "`r?`n" | Where-Object { $_.Trim() -ne "" }
    # Optionally, split the Services textbox contents into an array (if "Other Services" is checked)
    if ($SvcChk.Checked) {
        $serviceNames = $Services.Text -split "`r?`n" | Where-Object { $_.Trim() -ne "" }
    }

    foreach ($server in $servers) {
        Write-Host "Server: $server"

        if ($RdpChk.Checked) {
            $rdpResult = Test-RDPService -Server $server
            Write-Host $rdpResult
        }

        if ($WinRmChk.Checked) {
            $winrmResult = Test-WinRMService -Server $server
            Write-Host $winrmResult
        }

        if ($LastRebootChk.Checked) {
            $rebootResult = Get-LastReboot -Server $server
            Write-Host $rebootResult
        }

        if ($SvcChk.Checked -and $serviceNames) {
            $otherResults = Check-OtherServices -Server $server -ServicesList $serviceNames
            foreach ($result in $otherResults) {
                Write-Host $result
            }
        }
        Write-Host "-----------------------------------"
    }

}

#--- Wire-up the Scan button event ---
$ExecuteScan.Add_Click({
    $ExecuteScan.Text = "Stop Scanning"
    try {
        while ($true) {
            if ($IntervalTxt.Text -match '^\d+$') {
                $interval = [int]$IntervalTxt.Text
            } else {
                $interval = 15
            }
            Perform-Scan
            Start-Sleep -Seconds $interval
        }
    }
    finally {
        $ExecuteScan.Text = "Scan"
    }
})

[void]$ServerValidationForm.ShowDialog()