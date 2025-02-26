param (
    [string[]]$ComputersToRestart = @("GLOUCES-REG-02"), #List of computers to run the script on, can be more than one by adding ,"comp-name","comp-name2" etc.
    [string]$RestartMXatEnd = "yes", # Do you want to reboot the MX(s) listed at the end of the process?
    [string]$RestartMachines = "yes", # Do you want to reboot the machine?
    [string]$RestartXstoreIfNoReboot = "No", # Do you want to restart the xstore software if no reboot is requested?
    [string]$ComputerShutdown = "no" # If your not rebooting the machine do you want to shut it down?
)

# List of Script Variables
$neededModules = @("PSMeraki"); # Modules needed for the script.

# Quick way to obvescate sensitive info for github.
$environment = (get-content .\.env); $env = $null;
foreach($line in $environment){
    $env += @(
        [pscustomobject]@{itm=$line.split('=')[0];val=$line.split('=')[1] }
        )
}

function Invoke-Countdown {
    param(
        [Parameter(Mandatory=$true)][int]$Seconds
    )

    Write-Host "Counting down from $Seconds (in seconds)..."

    do {
        Write-Host $Seconds -ForegroundColor Black -BackgroundColor White;
        Start-Sleep 1
        $Seconds--
    } while ($Seconds -gt 0)

    Write-Host "$seconds countdown finished."

}
Function Invoke-ModuleCheck {
# Force TLS 1.2 for powershell get module retrieval
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

    # Check to see if required modules are installed.
    Write-Host "Checking for needed powerhsell modules." -ForegroundColor Cyan
    foreach($module in $neededModules){
        $PRMCheck = ((Get-InstalledModule | Where-Object {$_.Name -like "$module*"}).name).count
        If($PRMCheck -lt '1'){
            Write-Host "$module not found, attempting install now." -ForegroundColor DarkYellow
            Install-Module $module -AllowClobber -Force -confirm:$false
            Import-Module $module
        }
    }
}
Function Invoke-Restarts {
    foreach($machine in $computersToRestart){

        # Can the machine actually be reached?
        if(Test-WSMan -ComputerName $machine -ErrorAction SilentlyContinue){

            write-host "SUCCESS: $machine has been connected to via PSRemoting." -ForegroundColor White -BackgroundColor Green

            # Code to be executed on remote machine 
            invoke-command -ComputerName $machine -ScriptBlock {

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

                # get process list to see if xstore is still running. 
                if((get-process | Where-Object {$_.ProcessName -ilike "xstore*" -and $_.ProcessName -ilike "xenv*"}).count -lt '1'){
                    "Success Xstore appears to be closed"
                    if($using:restartMachines -ilike "y*"){
                        "Restart Computer has been set to $using:restartMachines, so this machine $env:computername will be restarted."
                        Restart-Computer -Force
                    }elseif($using:computerShutdown -ilike "y*"){
                        "Restart Computer has been set to $using:restartMachines, however a shutdown has been requested so this machine $env:computername will be SHUTDOWN."
                        Stop-Computer -ComputerName localhost -Force
                    }elseif($using:restartXstoreIfNoReboot -ilike "y*"){
                        Start-Sleep -Seconds 10
                        Start-ScheduledTask -TaskPath "\Denby\" "denbyLaunchXstoreAtLogon"
                        "xStore has been relaunced on $env:computername."
                    }else{
                        "Restart or Relaunch of software has not been requested on $env:computername."
                    }
                }

            } #End of remote code block

        }else{
            write-host "ERROR: $machine cannot be contacted via PSremoting." -ForegroundColor White -BackgroundColor Red
        }
    } #End of loop. 
}
Function Invoke-MerakiRestarts {

    if($restartMXatEnd -ilike "Y*"){

        $storeInfoPath = ($env | Where-Object {$_.itm -ieq "storeInfoPath"}).val;
        $merakiApiKeyPath = ($env | Where-Object {$_.itm -ieq "merakiApiKeyPath"}).val;
        $storeInfo = [xml]$datasource = Get-Content $storeInfoPath;
        $merakiApiKey = [xml]$datasource = Get-Content $merakiApiKeyPath;

        $mxSearchString = ($computersToRestart[0]).Split('-')[0];
        $mxSerials = ($storeInfo.stores.store | Where-Object {$_.name -ilike "*$mxSearchString*"}).MX.serial;

                Set-MrkRestApiKey $merakiApiKey.sitedata.meraki.api.key;
                if($null -eq $mxSerials -or '' -eq $mxSerials){
                    $mxSerials = Read-Host -Prompt "You have requested an MX reboot but we cannot match the store name in the datasource, please provide the MX serial in the format (XXX-XXX-XXX)";
                }

                Foreach($serial in $mxSerials){
                    Write-host "Waiting for 15 Seconds before rebooting the MX, so the restarted machines can get a DHCP lease before the MX is rebooted." -BackgroundColor DarkBlue -ForegroundColor White;
                    #Invoke-Countdown -Seconds 15;
                    $restartResult = Restart-MrkDevice -Serial $serial;
                    "Meraki Reports that success for the MX reboot with the serial ($serial) is: " + $restartResult.success
                }
    }else{
        Write-Host "No MX reboot requested";
    }
}

Invoke-ModuleCheck
Invoke-Restarts
Invoke-MerakiRestarts

Write-Host "DONE: Process has finished, you may now close the script, or start another session." -ForegroundColor White -BackgroundColor Blue;

#Clear all variables.
Get-Variable -Exclude PWD,*Preference | Remove-Variable -EA 0