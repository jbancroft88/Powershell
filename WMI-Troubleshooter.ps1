# A script to automatically identify running processes which have logged errors with the WMI Provider Host Service
# This reveals which client process(es) execution are potentially resulting in excessive CPU/Memory activity on the WmiPrvSE.exe process

# This is common issue on Windows systems, and is acknowledged and documented by Microsoft in the following article:
# https://learn.microsoft.com/en-us/troubleshoot/windows-server/system-management-components/high-cpu-usage-wmiprvse-process-regular-intervals
# The article states that the workaround is to "Identify the process using a large number of handles or a large amount of memory" and terminate it.
# However, the OS does not provide us with a method to quickly identify the number of potential candidates.
# As a result, troubleshooting this problem can be very time consuming when checking log files and system infomation manually.

$ErrorActionPreference = "Stop"
Write-Host("
__        ____  __ ___    _____                _     _           _                 _            
\ \      / /  \/  |_ _|  |_   _| __ ___  _   _| |__ | | ___  ___| |__   ___   ___ | |_ ___ _ __ 
 \ \ /\ / /| |\/| || |_____| || '__/ _ \| | | | '_ \| |/ _ \/ __| '_ \ / _ \ / _ \| __/ _ \ '__|
  \ V  V / | |  | || |_____| || | | (_) | |_| | |_) | |  __/\__ \ | | | (_) | (_) | ||  __/ |   
   \_/\_/  |_|  |_|___|    |_||_|  \___/ \__,_|_.__/|_|\___||___/_| |_|\___/ \___/ \__\___|_|  
                                                                    J Bancroft - May 2023 - 1.1     

================================================================================================")
$option = Read-Host("Select Mode
================================================================================================

[1]    Run Script on Local Machine
[2]    Run Script on Remote Machine

")

# Import Event logs for WMI-Activity and filter only errors (EventID: 5858). Check user input selection.

$wmilog = @()
if ($option -eq "1") {
        $hostname = "localhost"
        $wmilog = Get-WinEvent Microsoft-Windows-WMI-Activity/Operational | Where-Object {$_.Id -eq "5858"} 
    }
elseif ($option -eq "2") {
        $ErrorActionPreference = "Stop"
        $hostname = Read-Host("
================================================================================================
Enter Hostname
================================================================================================       

")
        Write-Host("
Collecting event data from $hostname - This might take a while... ")
        $collectlog = Get-WinEvent Microsoft-Windows-WMI-Activity/Operational -ComputerName $hostname
        $wmilog = $collectlog | Where-Object {$_.Id -eq "5858"} 
    }
else {
        Write-Host("Error: Input value not recognised. Exiting script...")
        exit
    }

# Filter only the "Message" column from results:

$msglog = $wmilog | Select-Object -Property Message

# Filter each "Message" string to extract the "Client Process ID" value, then put unique values into array
# The Message property is a multi-value, dynamic-length XML string in an existing table of results (ie. a Table within a Table)

$ear = @()
foreach ($event in $msglog) {
    $cpid = @($event -split ";")
    $cpnum = $cpid[3] -replace "ClientProcessId =", ""
        if ($ear -notcontains $cpnum)
        {
            $ear += $cpnum
        }
}                                                       

# Compare PID's in the filtered list with running processes to identify the executable process name(s). Print results in the terminal window:

Write-Host("
================================================================================================
Results
================================================================================================")

$prlist = Get-Process -ComputerName $hostname 
foreach ($code in $ear) {
    $prlist | Where-Object {$_.Id -eq $code}
}
Read-Host -Prompt ":"

#Any process using more than 30,000 handles and/or very high memory utilization is likely to be causing system performance issues.
#Handles:     The number of handles that the process has opened.
#NPM(K):      The amount of non-paged memory that the process is using, in kilobytes.
#PM(K):       The amount of pageable memory that the process is using, in kilobytes.
#WS(K):       The size of the working set of the process, in kilobytes. 
#VM(M):       The amount of virtual memory that the process is using, in megabytes.
#CPU(s):      The amount of processor time that the process has used on all processors, in seconds.
#ID:          The process ID (PID) of the process.
#ProcessName: The name of the process.
