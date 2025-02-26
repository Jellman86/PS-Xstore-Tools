#Script to update the xstore email receipt configuration via psRemoting.

#Declare config file as array
$scriptConfiguration = @();

#Start Logging
Start-Transcript -Path ".\update-email-rcpt-threaded.log" -Append

#Create object of config file
$configFile = get-content -path ".\.env";
foreach($config in $configFile){
    $scriptConfiguration += New-Object psobject -Property @{
            Property= $config.Split("=")[0];
            Value= $config.Split("=")[1];
        }  
}

#Declare configuration variables from config psObject
$configFilePath = ($scriptConfiguration | Where-Object {$_.Property -eq "target.file.path"}).value
[xml]$xstoreConfigData = get-content -path ($scriptConfiguration | Where-Object {$_.Property -eq "retail.store.machine.list.path"}).value
#$listofStoreMachines = @($xstoreConfigData.stores.store.computer.name);

#temporary list of machines for testing
$listofStoreMachines = @("dev1-reg-02","dev1-srv-01");

#job Control Configuration.
$maxConcurrentJobs = 4;
$jobs = @();

foreach($machineDNSName in $listofStoreMachines){

    #Run Script directly on remote machine via PSRemoting as a job.
    $jobs += Start-Job -ScriptBlock {
        param($machineDNSName, $scriptConfiguration, $configFilePath)

        Invoke-Command -ComputerName $machineDNSName -ScriptBlock {
            param($scriptConfiguration, $configFilePath)

            function backup-ConfigFile{
                param(
                    [string]$configFilePath
                )
            
                #Get date string for backup file
                $dateStringForBackup = get-date -Format "yyyy-MM-dd-HH-mm-ss";
            
                #Create backup file
                $backupFile = $configFilePath + ".$dateStringForBackup.bak"
                Copy-Item -Path $configFilePath -Destination $backupFile
            
                #Get file hashes for comparison.
                $originalHash = (Get-FileHash -Path $configFilePath).Hash;
                $backupFileHash = (Get-FileHash -Path $backupFile).Hash;
            
                if($originalHash -eq $backupFileHash){
                    Write-Host "Backup file created successfully." -BackgroundColor White -ForegroundColor Green
                }else{
                    Write-Host "Backup file creation failed." -BackgroundColor White -ForegroundColor Red
                    exit 1;
                }
            }
            
            $basePropFile = get-content -Path $configFilePath;
            backup-ConfigFile -configFilePath $configFilePath;

            $ln = 0;
            foreach($bpfLine in $basePropFile){
                switch -regex ($bpfLine) {
                    "dtv.email.host*" { 
                        $bpfLine + " -- line number: "+ $ln
                        $bpfLine = "dtv.email.host=" + ($scriptConfiguration | Where-Object {$_.Property -eq "email.server.host"}).value;
                        $basePropFile[$ln] = $bpfLine;
                    }
                    "dtv.email.port*" { 
                        $bpfLine + " -- line number: "+ $ln
                        $bpfLine = "dtv.email.port=" + ($scriptConfiguration | Where-Object {$_.Property -eq "email.server.port"}).value;
                        $basePropFile[$ln] = $bpfLine;
                    }
                    "dtv.email.smtp.auth*" { 
                        $bpfLine + " -- line number: "+ $ln
                        $bpfLine = "dtv.email.smtp.auth=" + ($scriptConfiguration | Where-Object {$_.Property -eq "email.server.auth"}).value;
                        $basePropFile[$ln] = $bpfLine;
                    }
                    "dtv.email.smtp.debug*" { 
                        $bpfLine + " -- line number: "+ $ln
                        $bpfLine = "dtv.email.smtp.debug=" + ($scriptConfiguration | Where-Object {$_.Property -eq "email.server.debug"}).value;
                        $basePropFile[$ln] = $bpfLine;
                    }
                    "dtv.email.default.sender*" { 
                        $bpfLine + " -- line number: "+ $ln
                        $bpfLine = "dtv.email.default.sender=" + ($scriptConfiguration | Where-Object {$_.Property -eq "email.user.name"}).value;
                        $basePropFile[$ln] = $bpfLine; 
                    }
                    "dtv.email.receipt.from*" { 
                        $bpfLine + " -- line number: "+ $ln
                        $bpfLine = "dtv.email.receipt.from=" + ($scriptConfiguration | Where-Object {$_.Property -eq "email.user.name"}).value;
                        $basePropFile[$ln] = $bpfLine;
                    }
                    "dtv.email.user*" { 
                        $bpfLine + " -- line number: "+ $ln
                        $bpfLine = "dtv.email.user=" + ($scriptConfiguration | Where-Object {$_.Property -eq "email.user.name"}).value;
                        $basePropFile[$ln] = $bpfLine; 
                    }
                    "dtv.email.password*" { 
                        $bpfLine + " -- line number: "+ $ln
                        $bpfLine = "dtv.email.password=" + ($scriptConfiguration | Where-Object {$_.Property -eq "email.user.password"}).value;
                        $basePropFile[$ln] = $bpfLine;
                    }
                }
                $ln++;
            }
            $basePropFile | Set-Content -Path $configFilePath;
        } -ArgumentList $scriptConfiguration, $configFilePath
    } -ArgumentList $machineDNSName, $scriptConfiguration, $configFilePath

    # Wait if the number of concurrent jobs reaches the limit
    while ($jobs.Count -ge $maxConcurrentJobs) {
        $jobs = $jobs | Where-Object { $_.State -eq 'Running' }
        Start-Sleep -Seconds 1
    }
}

# Wait for all jobs to complete
Get-Job | Wait-Job

# Clean up jobs
$jobs | ForEach-Object { Receive-Job -Id $_.Id; Remove-Job -Id $_.Id }

#stop logging
Stop-Transcript;