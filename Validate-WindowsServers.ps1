<# 
.NAME
    Windows Server Validator
.SYNOPSIS
    UI for sysadmins to quickly validate multiple Windows servers and services after a reboot or service outage.
    This version uses the GUI only to get parameters. The results are output to the console.
#>

# Load Windows Forms and enable visual styles
Add-Type -AssemblyName System.Windows.Forms
[System.Windows.Forms.Application]::EnableVisualStyles()

# Create the main form and controls
$Form                            = New-Object System.Windows.Forms.Form
$Form.ClientSize                 = New-Object System.Drawing.Point(400,400)
$Form.Text                       = "Windows Server Scanner"
$Form.TopMost                    = $false

$ServerList                      = New-Object System.Windows.Forms.TextBox
$ServerList.Multiline            = $true
$ServerList.Text                 = "<hostname(s)>"
$ServerList.Width                = 236
$ServerList.Height               = 352
$ServerList.Location             = New-Object System.Drawing.Point(16,29)
$ServerList.Font                 = New-Object System.Drawing.Font('Microsoft Sans Serif',10)

$ExecuteScan                     = New-Object System.Windows.Forms.Button
$ExecuteScan.Text                = "Scan"
$ExecuteScan.Width               = 122
$ExecuteScan.Height              = 30
$ExecuteScan.Location            = New-Object System.Drawing.Point(264,17)
$ExecuteScan.Font                = New-Object System.Drawing.Font('Microsoft Sans Serif',10)

$RdpChk                          = New-Object System.Windows.Forms.CheckBox
$RdpChk.Text                     = "RDP Service"
$RdpChk.AutoSize                 = $false
$RdpChk.Width                    = 95
$RdpChk.Height                   = 20
$RdpChk.Location                 = New-Object System.Drawing.Point(274,98)
$RdpChk.Font                     = New-Object System.Drawing.Font('Microsoft Sans Serif',10)

$WinRmChk                        = New-Object System.Windows.Forms.CheckBox
$WinRmChk.Text                   = "WinRM Service"
$WinRmChk.AutoSize               = $false
$WinRmChk.Width                  = 95
$WinRmChk.Height                 = 20
$WinRmChk.Location               = New-Object System.Drawing.Point(274,82)
$WinRmChk.Font                   = New-Object System.Drawing.Font('Microsoft Sans Serif',10)

$LastRebootChk                   = New-Object System.Windows.Forms.CheckBox
$LastRebootChk.Text              = "Last Reboot"
$LastRebootChk.AutoSize          = $false
$LastRebootChk.Width             = 95
$LastRebootChk.Height            = 20
$LastRebootChk.Location          = New-Object System.Drawing.Point(273,65)
$LastRebootChk.Font              = New-Object System.Drawing.Font('Microsoft Sans Serif',10)

$IntervalTxt                     = New-Object System.Windows.Forms.TextBox
$IntervalTxt.Multiline           = $false
$IntervalTxt.Text                = "5"
$IntervalTxt.Width               = 27
$IntervalTxt.Height              = 20
$IntervalTxt.Location            = New-Object System.Drawing.Point(304,375)
$IntervalTxt.Font                = New-Object System.Drawing.Font('Microsoft Sans Serif',10)

$RefreshLbl2                     = New-Object System.Windows.Forms.Label
$RefreshLbl2.Text                = "seconds"
$RefreshLbl2.AutoSize            = $true
$RefreshLbl2.Width               = 25
$RefreshLbl2.Height              = 10
$RefreshLbl2.Location            = New-Object System.Drawing.Point(343,378)
$RefreshLbl2.Font                = New-Object System.Drawing.Font('Microsoft Sans Serif',10)

$RefreshLbl1                     = New-Object System.Windows.Forms.Label
$RefreshLbl1.Text                = "refresh every"
$RefreshLbl1.AutoSize            = $true
$RefreshLbl1.Width               = 25
$RefreshLbl1.Height              = 10
$RefreshLbl1.Location            = New-Object System.Drawing.Point(304,357)
$RefreshLbl1.Font                = New-Object System.Drawing.Font('Microsoft Sans Serif',10)

$SvcChk                          = New-Object System.Windows.Forms.CheckBox
$SvcChk.Text                     = "Other Services"
$SvcChk.AutoSize                 = $false
$SvcChk.Width                    = 95
$SvcChk.Height                   = 20
$SvcChk.Location                 = New-Object System.Drawing.Point(273,136)
$SvcChk.Font                     = New-Object System.Drawing.Font('Microsoft Sans Serif',10)

$SvcListTxt                      = New-Object System.Windows.Forms.TextBox
$SvcListTxt.Multiline            = $true
$SvcListTxt.Text                 = "<serviceName(s)>"
$SvcListTxt.Width                = 118
$SvcListTxt.Height               = 193
$SvcListTxt.Location             = New-Object System.Drawing.Point(273,154)
$SvcListTxt.Font                 = New-Object System.Drawing.Font('Microsoft Sans Serif',10)

$serversLbl                      = New-Object System.Windows.Forms.Label
$serversLbl.Text                 = "Server List:"
$serversLbl.AutoSize             = $true
$serversLbl.Width                = 25
$serversLbl.Height               = 10
$serversLbl.Location             = New-Object System.Drawing.Point(16,11)
$serversLbl.Font                 = New-Object System.Drawing.Font('Microsoft Sans Serif',10)

$Form.Controls.AddRange(@($ServerList,$ExecuteScan,$RdpChk,$WinRmChk,$LastRebootChk,$IntervalTxt,$RefreshLbl2,$RefreshLbl1,$SvcChk,$SvcListTxt,$serversLbl))

# Create a hashtable to hold the user parameters
$global:UserParams = @{}

# When Scan is clicked, capture settings and close the form.
$ExecuteScan.Add_Click({
    # Get server list (ignoring blank or placeholder lines)
    $servers = $ServerList.Text -split "\r\n" | ForEach-Object { $_.Trim() } |
               Where-Object { $_ -ne "" -and $_ -notmatch "^<" }
    if ($servers.Count -eq 0) {
        [System.Windows.Forms.MessageBox]::Show("Please enter at least one server name.","Error")
        return
    }
    $global:UserParams.Servers = $servers
    $global:UserParams.Interval = [int]$IntervalTxt.Text
    $global:UserParams.CheckLastReboot = $LastRebootChk.Checked
    $global:UserParams.CheckRDP = $RdpChk.Checked
    $global:UserParams.CheckWinRM = $WinRmChk.Checked
    $global:UserParams.CheckOtherSvc = $SvcChk.Checked
    if ($SvcChk.Checked) {
        $svcs = $SvcListTxt.Text -split "\r\n" | ForEach-Object { $_.Trim() } |
                Where-Object { $_ -ne "" -and $_ -notmatch "^<" }
        $global:UserParams.OtherSvcList = $svcs
    }
    # Close the GUI so we can run the scan loop in the console.
    $Form.Close()
})

# Show the form modally
[void]$Form.ShowDialog()

# Clear the console so our output is easy to read.
Clear-Host

# Define a helper function to scan a single server.
function Get-ServerStatus {
    param (
        [string]$Server,
        [bool]$CheckLastReboot,
        [bool]$CheckRDP,
        [bool]$CheckWinRM,
        [bool]$CheckOtherSvc,
        [string[]]$OtherSvcList
    )
    # Start with a ping test.
    if (Test-Connection -ComputerName $Server -Count 1 -Quiet -ErrorAction SilentlyContinue) {
        $status = "Up"
    }
    else {
        $status = "Down"
    }
    # Create a base object for output.
    $obj = [PSCustomObject]@{
        Server      = $Server
        Status      = $status
        LastReboot  = ""
        RDP         = ""
        WinRM       = ""
        OtherSvc    = ""
    }
    # If server is down, we won't try the extra checks.
    if ($status -eq "Up") {
        if ($CheckLastReboot) {
            try {
                $os = Get-WmiObject -Class Win32_OperatingSystem -ComputerName $Server -ErrorAction Stop
                $bootTime = [Management.ManagementDateTimeConverter]::ToDateTime($os.LastBootUpTime)
                $obj.LastReboot = $bootTime
            }
            catch {
                $obj.LastReboot = "Not Found"
            }
        }
        if ($CheckRDP) {
            try {
                $svc = Get-Service -ComputerName $Server -Name "TermService" -ErrorAction Stop
                $obj.RDP = $svc.Status
            }
            catch {
                $obj.RDP = "Not Found"
            }
        }
        if ($CheckWinRM) {
            try {
                $svc = Get-Service -ComputerName $Server -Name "WinRM" -ErrorAction Stop
                $obj.WinRM = $svc.Status
            }
            catch {
                $obj.WinRM = "Not Found"
            }
        }
        if ($CheckOtherSvc) {
            $otherResults = @()
            foreach ($svcName in $OtherSvcList) {
                try {
                    $svc = Get-Service -ComputerName $Server -Name $svcName -ErrorAction Stop
                    $otherResults += "$($svcName): $($svc.Status)"
                }
                catch {
                    $otherResults += "$($svcName): Not Found"
                }
            }
            $obj.OtherSvc = ($otherResults -join "; ")
        }
    }
    return $obj
}

# Begin scan loop.
$interval = $global:UserParams.Interval
$servers = $global:UserParams.Servers
$checkLastReboot = $global:UserParams.CheckLastReboot
$checkRDP = $global:UserParams.CheckRDP
$checkWinRM = $global:UserParams.CheckWinRM
$checkOtherSvc = $global:UserParams.CheckOtherSvc
$otherSvcList = if ($checkOtherSvc) { $global:UserParams.OtherSvcList } else { @() }

while ($true) {
    Clear-Host
    Write-Host "Scanning servers at $(Get-Date -Format 'HH:mm:ss')" -ForegroundColor Cyan
    $results = @()
    foreach ($server in $servers) {
        $results += Get-ServerStatus -Server $server -CheckLastReboot $checkLastReboot -CheckRDP $checkRDP -CheckWinRM $checkWinRM -CheckOtherSvc $checkOtherSvc -OtherSvcList $otherSvcList
    }
    # Display a simple table if no extra info was requested.
    if (-not ($checkLastReboot -or $checkRDP -or $checkWinRM -or $checkOtherSvc)) {
        $results | Select-Object Server, Status | Format-Table -AutoSize
    }
    else {
        $results | Format-Table -AutoSize
    }
    
    # Countdown to next refresh
    for ($i = $interval; $i -gt 0; $i--) {
        Write-Host "Refreshing in $i second(s)..." -NoNewline -ForegroundColor Yellow
        Start-Sleep -Seconds 1
        # Clear the countdown line by returning to beginning of line
        Write-Host "`r" -NoNewline
    }
}
