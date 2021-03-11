#This script collects relevant logs and saves them to a folder on the users desktop

Write-Output "----- SCRIPT STARTED -----"

#Check if script is running as Administrator
    $IsAdmin = [bool](([System.Security.Principal.WindowsIdentity]::GetCurrent()).groups -match "S-1-5-32-544")
    Write-Output "Script running as administrator: $IsAdmin"

# Assign relevant Paths to variables
    $DesktopPath = [Environment]::GetFolderPath("Desktop")
    $ComputerName = $env:COMPUTERNAME
    $ComputerDesktopPath = Join-Path -Path $DesktopPath -ChildPath $ComputerName"_Extracted_Logs_"$((Get-Date).ToString('yyyy-MM-dd_hh-mm-ss'))
    mkdir $ComputerDesktopPath | Out-Null

# Collect logs
    # Is admin?
        New-Item -Path $ComputerDesktopPath"\" -Name "RanAsAdmin.txt" -ItemType "file" -Value "$IsAdmin" | Out-Null

    #Information about machine
        (Get-WMIObject win32_operatingsystem).name | Out-File -FilePath $ComputerDesktopPath"\OS_name.txt"
        [environment]::OSVersion.Version | Out-File -FilePath $ComputerDesktopPath"\OS_version.txt"
    
    #Wineventlogs
        Write-Output "----- Collecting WinEventLogs -----"
        mkdir $ComputerDesktopPath"\Wineventlog" | Out-Null
        Get-EventLog -LogName Application > $ComputerDesktopPath"\Wineventlog\"$ComputerName"_Applicationlog.evtx"
        Get-EventLog -LogName System > $ComputerDesktopPath"\Wineventlog\"$ComputerName"_Systemlog.evtx"
        if ($IsAdmin) {
            Get-EventLog -LogName Security > $ComputerDesktopPath"\Wineventlog\"$ComputerName"_Securitylog.evtx"
            }

    #Registry extraction
        Write-Output "----- Collecting Registry information -----"
        mkdir $ComputerDesktopPath"\Registry" | Out-Null
        reg export HKLM\Software $ComputerDesktopPath"\Registry\SOFTWARE.reg"
        reg export HKLM\System $ComputerDesktopPath"\Registry\SYSTEM.reg"
    
    #Get running processes
        Write-Output "----- Collecting Running processes -----"
        mkdir $ComputerDesktopPath"\Running_processes" | Out-Null
        tasklist | Out-File -FilePath $ComputerDesktopPath"\Running_processes\tasklist.txt"
        tasklist /v | Out-File -FilePath $ComputerDesktopPath"\Running_processes\tasklist_with_runtime.txt"
        tasklist /m | Out-File -FilePath $ComputerDesktopPath"\Running_processes\tasklist_with_dlls.txt"
        Net start | Out-File -FilePath $ComputerDesktopPath"\Running_processes\started_services.txt"
        Schtasks | Out-File -FilePath $ComputerDesktopPath"\Running_processes\scheduled_tasks.txt"

    #Get network information
        Write-Output "----- Collecting Network information -----"
        mkdir $ComputerDesktopPath"\Network" | Out-Null
        netstat -nbao | Out-File -FilePath $ComputerDesktopPath"\Network\netstat_active_connections.txt"
        ipconfig /displaydns | Out-File -FilePath $ComputerDesktopPath"\Network\ipconfig-displaydns.txt"
        ipconfig /all | Out-File -FilePath $ComputerDesktopPath"\Network\ipconfig-all.txt"

Write-Output "----- SCRIPT FINISHED -----"
Read-Host -Prompt "Press Enter to exit"
