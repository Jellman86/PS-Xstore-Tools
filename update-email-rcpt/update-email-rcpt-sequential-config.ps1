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
    }
}

# Stop logging
Stop-Transcript;