#Script to update the xstore email receipt configuration via psRemoting.

#Declare config file as array
$scriptConfiguration = @();

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
$listofStoreMachines = @($xstoreConfigData.stores.store.computer.name);

#Run Script directly on remote machine via PSRemoting.
invoke-command -ComputerName "dev1-reg-02" -ScriptBlock {

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
            Write-Host "Backup file creation failed." - backgroundColor White -ForegroundColor Red
            exit 1;
        }
    }
    
    $basePropFile = get-content -Path $using:configFilePath;
    #backup-ConfigFile -configFilePath $using:configFilePath;

    foreach($bpfLine in $basePropFile){
        $ln++
        switch -regex ($bpfLine) {
            "dtv.email.host*" { 
                $bpfLine + " -- line number: "+ $ln
                $bpfLine = "dtv.email.host=" + ($using:scriptConfiguration | Where-Object {$_.Property -eq "email.server.host"}).value;
                $basePropFile[$ln] = $bpfLine;
            }
            "dtv.email.port*" { 
                $bpfLine + " -- line number: "+ $ln
                $bpfLine = "dtv.email.port=" + ($using:scriptConfiguration | Where-Object {$_.Property -eq "email.server.port"}).value;
                $basePropFile[$ln] = $bpfLine;
            }
            "dtv.email.smtp.auth*" { 
                $bpfLine + " -- line number: "+ $ln
                $bpfLine = "dtv.email.smtp.auth=" + ($using:scriptConfiguration | Where-Object {$_.Property -eq "email.server.auth"}).value;
                $basePropFile[$ln] = $bpfLine;
            }
            "dtv.email.smtp.debug*" { 
                $bpfLine + " -- line number: "+ $ln
                $bpfLine = "dtv.email.host=" + ($using:scriptConfiguration | Where-Object {$_.Property -eq "email.server.debug"}).value;
                $basePropFile[$ln] = $bpfLine;
            }
            "dtv.email.default.sender*" { 
                $bpfLine + " -- line number: "+ $ln
                $bpfLine = "dtv.email.default.sender=" + ($using:scriptConfiguration | Where-Object {$_.Property -eq "email.user.name"}).value;
                $basePropFile[$ln] = $bpfLine; 
            }
            "dtv.email.receipt.from*" { 
                $bpfLine + " -- line number: "+ $ln
                $bpfLine = "dtv.email.receipt.from=" + ($using:scriptConfiguration | Where-Object {$_.Property -eq "email.user.name"}).value;
                $basePropFile[$ln] = $bpfLine;
            }
            "dtv.email.user*" { 
                $bpfLine + " -- line number: "+ $ln
                $bpfLine = "dtv.email.user=" + ($using:scriptConfiguration | Where-Object {$_.Property -eq "email.user.name"}).value;
                $basePropFile[$ln] = $bpfLine; 
            }
            "dtv.email.password*" { 
                $bpfLine + " -- line number: "+ $ln
                $bpfLine = "dtv.email.password=" + ($using:scriptConfiguration | Where-Object {$_.Property -eq "email.user.password"}).value;
                $basePropFile[$ln] = $bpfLine;
            }
        }

        $basePropFile
    }
}
 