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
        (Get-WMIObject win32_operatingsystem).name | Out-File -FilePath $ComputerDesktopPath"\OS_name_$ComputerName.txt"
        [environment]::OSVersion.Version | Out-File -FilePath $ComputerDesktopPath"\OS_version_$ComputerName.txt"
    
    #Wineventlogs
        Write-Output "----- Collecting WinEventLogs -----"
        mkdir $ComputerDesktopPath"\Wineventlog" | Out-Null
        if ($IsAdmin){
            Copy-Item "C:\Windows\System32\winevt\Logs\Application.evtx" -Destination "$ComputerDesktopPath\Wineventlog\ApplicationLog_$ComputerName.evtx"
            Copy-Item "C:\Windows\System32\winevt\Logs\System.evtx" -Destination "$ComputerDesktopPath\Wineventlog\SystemLog_$ComputerName.evtx"
            Copy-Item "C:\Windows\System32\winevt\Logs\Security.evtx" -Destination "$ComputerDesktopPath\Wineventlog\SecurityLog_$ComputerName.evtx"
            }else {
                Get-EventLog -LogName Application > $ComputerDesktopPath"\Wineventlog\"$ComputerName"_Applicationlog.evtx"
                Get-EventLog -LogName System > $ComputerDesktopPath"\Wineventlog\"$ComputerName"_Systemlog.evtx"
            }

    #Registry extraction
        Write-Output "----- Collecting Registry information -----"
        mkdir $ComputerDesktopPath"\Registry" | Out-Null
        reg export HKLM\Software $ComputerDesktopPath"\Registry\SOFTWARE_$ComputerName.reg" | Out-Null
        reg export HKLM\System $ComputerDesktopPath"\Registry\SYSTEM_$ComputerName.reg" | Out-Null
    
    #Get running processes
        Write-Output "----- Collecting Running processes -----"
        mkdir $ComputerDesktopPath"\Running_processes" | Out-Null
        tasklist | Out-File -FilePath $ComputerDesktopPath"\Running_processes\tasklist_$ComputerName.txt"
        tasklist /v | Out-File -FilePath $ComputerDesktopPath"\Running_processes\tasklist_with_runtime_$ComputerName.txt"
        tasklist /m | Out-File -FilePath $ComputerDesktopPath"\Running_processes\tasklist_with_dlls_$ComputerName.txt"
        Net start | Out-File -FilePath $ComputerDesktopPath"\Running_processes\started_services_$ComputerName.txt"
        Schtasks | Out-File -FilePath $ComputerDesktopPath"\Running_processes\scheduled_tasks_$ComputerName.txt"

    #Get network information
        Write-Output "----- Collecting Network information -----"
        mkdir $ComputerDesktopPath"\Network" | Out-Null
        ipconfig /displaydns | Out-File -FilePath $ComputerDesktopPath"\Network\ipconfig-displaydns_$ComputerName.txt"
        ipconfig /all | Out-File -FilePath $ComputerDesktopPath"\Network\ipconfig-all_$ComputerName.txt"
        if($IsAdmin){
            netstat -nbao | Out-File -FilePath $ComputerDesktopPath"\Network\netstat_active_connections_$ComputerName.txt"
            }

Write-Output "----- SCRIPT FINISHED -----"
Read-Host -Prompt "Press Enter to exit"
