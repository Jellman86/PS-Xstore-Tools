# Script to update the xstore email receipt configuration via PSRemoting.

# Start Logging
Start-Transcript -Path ".\update-email-rcpt-sequential.log" -Append

# Declare config file as array
$scriptConfiguration = @();

# Create object of config file
$configFile = Get-Content -Path ".\.env";
foreach ($config in $configFile) {
    $scriptConfiguration += New-Object psobject -Property @{
        Property = $config.Split("=")[0];
        Value = $config.Split("=")[1];
    }
}

# Declare configuration variables from config psObject
$configFilePath = ($scriptConfiguration | Where-Object {$_.Property -eq "target.file.path"}).value
[xml]$xstoreConfigData = Get-Content -Path ($scriptConfiguration | Where-Object {$_.Property -eq "retail.store.machine.list.path"}).value
#$listofStoreMachines = @($xstoreConfigData.stores.store.computer.name);

# Temporary list of machines for testing
$listofStoreMachines = @("dev1-reg-02", "dev1-srv-01");

foreach ($machineDNSName in $listofStoreMachines) {

    # Run Script directly on remote machine via PSRemoting.
    Invoke-Command -ComputerName $machineDNSName -ScriptBlock {
        param($using:scriptConfiguration, $using:configFilePath)

        write-host "===> Process Starting On $env:computername for $using:machineDNSName <===" -BackgroundColor White -ForegroundColor Black

        # Function to backup the configuration file
        function backup-ConfigFile {
            param(
                [string]$configFilePath
            )

            # Get date string for backup file
            $dateStringForBackup = Get-Date -Format "yyyy-MM-dd-HH-mm-ss";

            # Create backup file
            $backupFile = $configFilePath + ".$dateStringForBackup.bak"
            Copy-Item -Path $configFilePath -Destination $backupFile

            # Get file hashes for comparison
            $originalHash = (Get-FileHash -Path $configFilePath).Hash;
            $backupFileHash = (Get-FileHash -Path $backupFile).Hash;

            if ($originalHash -eq $backupFileHash) {
                Write-Host "Backup file created successfully." -BackgroundColor White -ForegroundColor Green
            } else {
                Write-Host "Backup file creation failed." -BackgroundColor White -ForegroundColor Red
                exit 1;
            }
        }

        # Function to backup the configuration file
        function backup-ConfigFile {
                param(
                    [string]$configFilePath
                )

                # Get date string for backup file
                $dateStringForBackup = Get-Date -Format "yyyy-MM-dd-HH-mm-ss";

                # Create backup file
                $backupFile = $configFilePath + ".$dateStringForBackup.bak"
                Copy-Item -Path $configFilePath -Destination $backupFile

                # Get file hashes for comparison
                $originalHash = (Get-FileHash -Path $configFilePath).Hash;
                $backupFileHash = (Get-FileHash -Path $backupFile).Hash;

                if ($originalHash -eq $backupFileHash) {
                    Write-Host "Backup file created successfully." -BackgroundColor White -ForegroundColor Green
                } else {
                    Write-Host "Backup file creation failed." -BackgroundColor White -ForegroundColor Red
                    exit 1;
                }
            }

        # Function to restart xStore
        function invoke-xstoreStackExit {
                #Get all the Anchors
                write-host "Finding Anchor Files";
                Try{
                    $xstoreAnchors = get-childitem -Path @("c:\xstore\tmp","c:\environment\tmp","c:\xstore-mobile\tmp","c:\eftlink\tmp") | Where-Object {$_.Extension -eq ".anchor"} -ea 0;
                }catch{
                    Write-Host "Warn: $_ Path not available, if this not a server and the path is mobile, this is fine!" -ForegroundColor White -BackgroundColor Red
                    return
                }

                #Delete xStore anchor files
                ForEach ($anchor in $xstoreAnchors){
                    if (Test-Path $anchor.FullName){
                        $anchorPath = $anchor.FullName
                        Remove-Item $anchor.FullName -Force
                        "$anchorPath has been deleted on $env:computername."
                    }else{
                        "$anchorPath doesn't exist."
                    }
                }
                
                "Xstore should close within 15 seconds"
                Start-Sleep -Seconds 15
            }

        # Function to start xStore using the task scheduler.
        function invoke-xstoreStartup {

                Start-ScheduledTask -TaskPath "\Denby\" "denbyLaunchXstoreAtLogon"
                "xStore has been relaunced on $env:computername."

            }

        # Function to check if the script operation prerequisites are met
        function invoke-prerequisiteCheck {

                $existanceCheckFiles = @("c:\xstore\configure.bat","c:\xstore\baseconfigure.bat","c:\environment\configure.bat")
                #Check if files exist
                foreach ($file in $existanceCheckFiles){
                    if(Test-Path -Path $file){
                        Write-Host "File $file exists."
                    }else{
                        Write-Host "File $file does not exist."
                        exit 1;
                    }
                }

                #check if scheduled task exists
                if(Get-ScheduledTask -TaskPath "\Denby\" "denbyLaunchXstoreAtLogon"){
                    Write-Host "Scheduled Task exists."
                }else{
                    Write-Host "Scheduled Task to launch xstore does not exist."
                    exit 1;
                }
            }
            
        # Function to run configuration scripts
        function invoke-configChangePropergation {
                "Running xenvironments configuration scripts."
                $configScripts = @("c:\xstore\configure.bat","c:\xstore\baseconfigure.bat","c:\environment\configure.bat")
                Foreach($script in $configScripts){
                    Start-Sleep -Seconds 15
                    if(test-path -Path $script){
                        "$script has been found, running."
                        Start-Process "cmd.exe" -ArgumentList "/c $script" -Wait
                    }else{
                        "WARN - $script cannot be found."
                    }
                }
            }

        # Invoke the prerequisite check
        invoke-prerequisiteCheck;

        # Read the base properties file
        $basePropFile = Get-Content -Path $using:configFilePath;
        backup-ConfigFile -configFilePath $using:configFilePath;

        # Update the properties in the file
        $ln = 0;
        foreach ($bpfLine in $basePropFile) {
            switch -regex ($bpfLine) {
                "dtv.email.host*" {
                    $bpfLine + " -- line number: " + $ln
                    $bpfLine = "dtv.email.host=" + ($using:scriptConfiguration | Where-Object {$_.Property -eq "email.server.host"}).value;
                    $basePropFile[$ln] = $bpfLine;
                }
                "dtv.email.port*" {
                    $bpfLine + " -- line number: " + $ln
                    $bpfLine = "dtv.email.port=" + ($using:scriptConfiguration | Where-Object {$_.Property -eq "email.server.port"}).value;
                    $basePropFile[$ln] = $bpfLine;
                }
                "dtv.email.smtp.auth*" {
                    $bpfLine + " -- line number: " + $ln
                    $bpfLine = "dtv.email.smtp.auth=" + ($using:scriptConfiguration | Where-Object {$_.Property -eq "email.server.auth"}).value;
                    $basePropFile[$ln] = $bpfLine;
                }
                "dtv.email.smtp.debug*" {
                    $bpfLine + " -- line number: " + $ln
                    $bpfLine = "dtv.email.smtp.debug=" + ($using:scriptConfiguration | Where-Object {$_.Property -eq "email.server.debug"}).value;
                    $basePropFile[$ln] = $bpfLine;
                }
                "dtv.email.default.sender*" {
                    $bpfLine + " -- line number: " + $ln
                    $bpfLine = "dtv.email.default.sender=" + ($using:scriptConfiguration | Where-Object {$_.Property -eq "email.user.name"}).value;
                    $basePropFile[$ln] = $bpfLine;
                }
                "dtv.email.receipt.from*" {
                    $bpfLine + " -- line number: " + $ln
                    $bpfLine = "dtv.email.receipt.from=" + ($using:scriptConfiguration | Where-Object {$_.Property -eq "email.user.name"}).value;
                    $basePropFile[$ln] = $bpfLine;
                }
                "dtv.email.user*" {
                    $bpfLine + " -- line number: " + $ln
                    $bpfLine = "dtv.email.user=" + ($using:scriptConfiguration | Where-Object {$_.Property -eq "email.user.name"}).value;
                    $basePropFile[$ln] = $bpfLine;
                }
                "dtv.email.password*" {
                    $bpfLine + " -- line number: " + $ln
                    $bpfLine = "dtv.email.password=" + ($using:scriptConfiguration | Where-Object {$_.Property -eq "email.user.password"}).value;
                    $basePropFile[$ln] = $bpfLine;
                }
            }
            $ln++;
        }
        # Write the updated properties back to the file
        $basePropFile | Set-Content -Path $using:configFilePath;

        #Propagate the changes using inbuilt xstore tools and then restart xstore.
        invoke-xstoreStackExit;
        invoke-configChangePropergation;
        invoke-xstoreStartup;
    }
}

# Stop logging
Stop-Transcript;