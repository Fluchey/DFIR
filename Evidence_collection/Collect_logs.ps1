#This script collects relevant logs and saves them to a folder on C:\temp

Write-Output "----- SCRIPT STARTED -----"

#Check if script is running as Administrator
    $IsAdmin = [bool](([System.Security.Principal.WindowsIdentity]::GetCurrent()).groups -match "S-1-5-32-544")
    Write-Output "Script running as administrator: $IsAdmin"

# Assign relevant Paths to variables
    $ComputerName = $env:COMPUTERNAME
    $date = $((Get-Date).ToString('yyyy-MM-dd_hh-mm-ss'))
    $tempPath = Join-Path -Path "C:\temp" -ChildPath $ComputerName"_Extracted_Logs_"$((Get-Date).ToString('yyyy-MM-dd_hh-mm-ss'))
    mkdir $tempPath | Out-Null

# Collect logs
    # Is admin?
        New-Item -Path $tempPath"\" -Name "RanAsAdmin.txt" -ItemType "file" -Value "$IsAdmin" | Out-Null

    #Information about machine
        (Get-WMIObject win32_operatingsystem).name | Out-File -FilePath $tempPath"\OS_name_$ComputerName.txt"
        [environment]::OSVersion.Version | Out-File -FilePath $tempPath"\OS_version_$ComputerName.txt"
    
    #Wineventlogs
        Write-Output "----- Collecting WinEventLogs -----"
        mkdir $tempPath"\Wineventlog" | Out-Null
        if ($IsAdmin){
            Copy-Item "C:\Windows\System32\winevt\Logs\Application.evtx" -Destination "$tempPath\Wineventlog\ApplicationLog_$ComputerName.evtx"
            Copy-Item "C:\Windows\System32\winevt\Logs\System.evtx" -Destination "$tempPath\Wineventlog\SystemLog_$ComputerName.evtx"
            Copy-Item "C:\Windows\System32\winevt\Logs\Security.evtx" -Destination "$tempPath\Wineventlog\SecurityLog_$ComputerName.evtx"
            }else {
                Get-EventLog -LogName Application > $tempPath"\Wineventlog\"$ComputerName"_Applicationlog.evtx"
                Get-EventLog -LogName System > $tempPath"\Wineventlog\"$ComputerName"_Systemlog.evtx"
            }
	#ScheduledTasks
		mkdir $tempPath"\ScheduledTasks" | Out-Null
		Get-ScheduledTask | Out-File -FilePath $tempPath"\ScheduledTasks\ScheduledTasks.txt"

    #Registry extraction
        Write-Output "----- Collecting Registry information -----"
        mkdir $tempPath"\Registry" | Out-Null
        reg export HKLM\Software $tempPath"\Registry\SOFTWARE_$ComputerName.reg" | Out-Null
        reg export HKLM\System $tempPath"\Registry\SYSTEM_$ComputerName.reg" | Out-Null
    
    #Get running processes
        Write-Output "----- Collecting Running processes -----"
        mkdir $tempPath"\Running_processes" | Out-Null
        tasklist | Out-File -FilePath $tempPath"\Running_processes\tasklist_$ComputerName.txt"
        tasklist /v | Out-File -FilePath $tempPath"\Running_processes\tasklist_with_runtime_$ComputerName.txt"
        tasklist /m | Out-File -FilePath $tempPath"\Running_processes\tasklist_with_dlls_$ComputerName.txt"
        Net start | Out-File -FilePath $tempPath"\Running_processes\started_services_$ComputerName.txt"
        Schtasks | Out-File -FilePath $tempPath"\Running_processes\scheduled_tasks_$ComputerName.txt"

    #Get network information
        Write-Output "----- Collecting Network information -----"
        mkdir $tempPath"\Network" | Out-Null
        ipconfig /displaydns | Out-File -FilePath $tempPath"\Network\ipconfig-displaydns_$ComputerName.txt"
        ipconfig /all | Out-File -FilePath $tempPath"\Network\ipconfig-all_$ComputerName.txt"
        if($IsAdmin){
            netstat -nbao | Out-File -FilePath $tempPath"\Network\netstat_active_connections_$ComputerName.txt"
            }

    #Compress folder to archive
	  Compress-Archive -Path $tempPath -DestinationPath "$tempPath.zip"

Write-Output "----- SCRIPT FINISHED -----"