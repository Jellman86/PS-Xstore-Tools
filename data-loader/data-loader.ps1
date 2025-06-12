#Go to correct directory when run as admin
Set-Location $PSScriptRoot

# Quick way to obvescate the path for github
$environment = (get-content .\dataloader.env); $env = $null;
foreach($line in $environment){
    $env += @(
        [pscustomobject]@{itm= $line.split('=')[0];val=$line.split('=')[1] }
        )
}

$sourcePath = ($env | Where-Object {$_.itm -ieq "mntPath"}).val;
$storeFolders = ($env | Where-Object {$_.itm -ieq "storeFolders"}).val;

Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName PresentationCore
Add-Type -AssemblyName WindowsBase
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[System.Windows.Forms.Application]::EnableVisualStyles()

# Main form 
$form = New-Object System.Windows.Forms.Form
$form.Font = New-Object System.Drawing.Font("Century Gothic",10,[System.Drawing.FontStyle]::Regular)
$form.Text = 'xStore Server Data Loader Tool.'
$form.Size = New-Object System.Drawing.Size(475,200)
$form.StartPosition = 'CenterScreen'
$Form.FormBorderStyle = 'Fixed3D'
$Form.MaximizeBox = $false

# Titlebar Icon
$iconBase64      = 'iVBORw0KGgoAAAANSUhEUgAAAGAAAABgCAYAAADimHc4AAAACXBIWXMAAAsTAAALEwEAmpwYAAAEbklEQVR4nO1dz0tUQRx//0SHyqI/IwQhIQShoi52a3kdEn0z6kLH6uKxQ3SJouhQt24d0k51CK/KOuOvlIJIIvfN6q6W7ao7MU8hU/eNOuvOd77zPjAgK7ifj5/5zmfezINvEBwBAyV+nsac0pi/J4LPEsHXdsZs8lnMSZ9g5wJHMQBVXz6eOEti9ozGfJMKLtMGidkWFezN4PLMhcAR5CHrI8Wp61SwVR2xfUQFq0RFfi0ADgJZXxSzwW3Hj0Zu92wh8eRAABQRZH1qZpiQ200SYiUQyPpoXGg7Tlmml+vMmQAIKHR9VLCXzSL3b6bw5wEQUMj6drZi2t3AkYf6m3GhrSkkMetToaL7sgfLc3KiWpZ/6lvJKFQrcnhlXk+yyCNjgtj1kZiN6sj9qm/KvVCfqd+llyl7Z0wQuz4q2Hzal6iZ0Qjj1XI6QcFnjQli16fbHaiSbIT1+pamTNmqMUHs+kwI/q5vamYIKxsTxK6PCjaX9iUqkBqX6IouqGaMCWLXpwsptRs4KKTW6pvyPoIQHratTx25alxOdgMqkNSaqIaaGTpyySixvqb8FzHrU+fdJ/GgQmK+AeFBrM8FfVTwF80mSGP2NAACCl1fckEhWKVps0Ow8tDS9OkACPIu6CNiqrsZpZoc+ZbY1QAYiAv61LmJ6YWFumMNgIK4oE9dNhynXFVZRiV2JQCOyAV9tDJ+igr+OEn6Q8wKIvgrSGs+Gn1qm3VzZFHenlyQvV/mZPRzKhnq57CwIHtGFyWErSZqfV2PyjJtBI6jC7o+8ASx6wNPELs+8ASx6wNPELs+8ASx6wNPELs+8ARd03dxaEK2clx+KFIFdp3wuPWhKsOxWstG7tPGJVAGdA5/t2pAz9v1lhoQjlU/gjKg496CVQNuvF5rsQGaKmi1Ae13mVUDup9UWm5AahW02gAfcyBMqwIbBviXA7XGVWDDAB9zIGxUBTYM8DMHagdXgQ0DfM2B8KAqsGWAnzlQ218FtgzwNQfCvVVgywB/c6D2fxXo/lGmMM0BU5jmgCm0VWDTgM5D5IApTHPAFNoqsGlAxyFywBSmOWAKbRbYNKD9EDlgCtMcMIU2CzIDav4a0JEtQXaXoM4shLNtaAh9G5o9iNXsPoid1MiOIiwbkB3GWTYgO47eQbb+1+ys/TYN8HX9z0G5kvRz/a/CuZT3cf3PQXktxc+LmCqcF7N8XP9zkF5N9G/9r8J6Ode39T+nez3dNYQawbb5oUeYGZAZ4DXCrAIyA7xGmFVAZoDXCLMKsNt8oXd6SfZ/+yqjH58lKU4nQ/2sPrszvSRd7mMGFnnIfb6wg0Du84UdEeQ+X9hBIPf5wg4Kvc8XdlDIfb6wYwB6ny/sIND7fGEHgd7nCzso9D5f2EGh9/nCDgq9zxd2UOh9vrCDQO/zhR0Eep8v7Ohzoc8XdlDofb6wI+9Cny/sIC70+cIO4kKfL+yIXOjzhR3UlT5fXtyUFXlEYzainmq3jy2So4sZ9ZBFSqzfta3mX0PtNv2eKrjTAAAAAElFTkSuQmCC'
$iconBytes       = [Convert]::FromBase64String($iconBase64)
# initialize a Memory stream holding the bytes
$stream          = [System.IO.MemoryStream]::new($iconBytes, 0, $iconBytes.Length)
$Form.Icon       = [System.Drawing.Icon]::FromHandle(([System.Drawing.Bitmap]::new($stream).GetHIcon()))

# Close xstore button
$LDButton = New-Object System.Windows.Forms.Button
$LDButton.Location = New-Object System.Drawing.Point(20,100)
$LDButton.Size = New-Object System.Drawing.Size(200,40)
$LDButton.Text = 'Load Data'
$LDButton.Add_Click({ Invoke-UIProcess })
$LDButton.TabIndex = 1

# Close the application button
$cancelButton = New-Object System.Windows.Forms.Button
$cancelButton.Location = New-Object System.Drawing.Point(240,100)
$cancelButton.Size = New-Object System.Drawing.Size(200,40)
$cancelButton.Text = 'Close'
$cancelButton.TabIndex = 2
$cancelButton.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
$form.CancelButton = $cancelButton

# Main information text
$label = New-Object System.Windows.Forms.Label
$label.Location = New-Object System.Drawing.Point(20,20)
$label.Size = New-Object System.Drawing.Size(230,20)
$label.Text = 'What is the current store number?'

# Information progress label
$warn = New-Object System.Windows.Forms.Label
$warn.Location = New-Object System.Drawing.Point(20, 70)
$warn.Width = 420
$warn.Height = 20
$warn.BackColor = "#FFFFFF"
$warn.Visible = $FALSE

# Store number user input
$textBox = New-Object System.Windows.Forms.TextBox
$textBox.Location = New-Object System.Drawing.Point(335,15)
$textbox.Width = 100
$textBox.TextAlign = 'center'
$textBox.AcceptsReturn = $true

# Location of Data
$textBoxSource = New-Object System.Windows.Forms.TextBox
$textBoxSource.Location = New-Object System.Drawing.Point(161,70)
$textboxSource.Width = 275
$textBoxSource.TextAlign = 'center'
$textBoxSource.AcceptsReturn = $true
$textBoxSource.text = $sourcePath

# label Source
$datasource = New-Object System.Windows.Forms.Label
$datasource.Location = New-Object System.Drawing.Point(20, 72)
$datasource.Width = 130
$datasource.Text = 'Data Source Path:'

# Checkbox for UAT Data Load
$objTypeCheckboxUATload = New-Object System.Windows.Forms.Checkbox 
$objTypeCheckboxUATload.Location = New-Object System.Drawing.Size(350,45) 
$objTypeCheckboxUATload.Size = New-Object System.Drawing.Size(200,20)
$objTypeCheckboxUATload.Text = "UAT Store?"
$objTypeCheckboxUATload.TabIndex = 5

# Load Store Data Checkbox
$objTypeCheckboxStoreData = New-Object System.Windows.Forms.Checkbox 
$objTypeCheckboxStoreData.Location = New-Object System.Drawing.Size(200,45) 
$objTypeCheckboxStoreData.Size = New-Object System.Drawing.Size(150,20)
$objTypeCheckboxStoreData.Text = "Load Store Data?"
$objTypeCheckboxStoreData.TabIndex = 5

# Add all controls to main form.
$form.Controls.Add($warn)
$form.Controls.Add($objTypeCheckboxStoreData)
$form.Controls.Add($objTypeCheckboxUATload)
$form.Controls.Add($LDButton)
$form.Controls.Add($label)
$form.Controls.Add($datasource)
$form.Controls.Add($cancelButton)
$form.Controls.Add($textBox)
$form.Controls.Add($textBoxSource)

# Make sure the form is top of z-index
$form.Topmost = $true

# Writes out the log to the file server for collation
Function Write-Log {
    param(
        [Parameter(Mandatory=$true)][String]$msg
    )
    $loggingpath = '.\Data-Loader-Log.log';
    $logtime = (get-date -Format "HH:mm:ss-ddMMyy")
    Add-Content -Path $loggingpath -Value $logtime" | "$env:Computername" | "$msg
}

# Bool response if supplied value numeric. 
FUNCTION Test-Numeric ($Value) {
    $value = $value.trim()
    return $Value -match "^[\d\.]+$"
}

# Get the Latest MNT Files
Function Get-LatestStoreData {

        $warn.Visible = $true
        $warn.ForeColor = 'Black'
        $warn.Text = "Downloading the latest Store data."

        If(Test-Path -Path "$env:TMP\source-mnt"){
            $warn.Text = "Deleting old MNT Source."
            Write-log "Removing old MNT source files that have been detected."
            Remove-Item -Path "$env:TMP\source-mnt" -Recurse -Force
        }
            #Creating Directory for the expansion to take place.
            $warn.Text = "Creating new source-mnt Folder."
            New-Item -ItemType Directory -Path $env:TMP -Name 'source-mnt' -Force

        if(Test-Path -Path "$sourcePath\setup"){
            
            foreach($mnt in (get-childitem -Path "$sourcePath\setup" -Recurse | where-object {$_.Extension -eq '.mnt'})){
                Write-log "Copying $mnt to $env:TMP\source-mnt."
                $warn.Text = "Copying $mnt to $env:TMP\source-mnt."
                Copy-Item -Path $mnt.FullName -Destination "$env:TMP\source-mnt";
            }

        }else{
            $warn.ForeColor = 'red'
            $warn.Text = "Data Source does not exist."
            Write-log "ERROR - $sourcePath\setup does not exist."
        }
            
            #is this a UAT Machine? if so copy over the UAT Data.
            if(($TRUE -eq $objTypeCheckboxUATload.Checked) -and (Test-Path -Path "$sourcePath\uat")){
                foreach($mnt in (get-childitem -Path "$sourcePath\uat" -Recurse | where-object {$_.Extension -eq '.mnt'})){
                    Write-log "Copying $mnt to $env:TMP\source-mnt."
                    $warn.Text = "Copying $mnt to $env:TMP\source-mnt."
                    Copy-Item -Path $mnt.FullName -Destination "$env:TMP\source-mnt";
                }
            }else{
                $warn.ForeColor = 'red'
                $warn.Text = "UAT Data Source does not exist."
                Write-log "ERROR - $sourcePath\UAT does not exist."   
            }
}

# Change the data specific to store.
Function Invoke-DataCustomisation {

    $mntPath = Get-ChildItem -Path "$env:TMP\source-mnt" -Recurse | Where-Object {$_.Extension -ilike ".mnt"}
        
    if($null -ne $StoreNumber){
        $mntCnt = 0
        foreach($mnt in $mntPath){
            $warn.Text = "Modifying $mnt with $StoreNumber."
            
            $mntCnt += 1
            $objPath = (($mnt.FullName).Replace($mnt.Name,'')).trimEnd('\')
            $mntName = $mnt.Name
            
            Copy-Item -Path $mnt.fullName -Destination "$objPath\$mntName.Backup" -force

            $mnCont = Get-Content $mnt.FullName
            if($mnCont -ilike "*<ScottIsASuperCoolGuyYall>*"){
                $mnCont = $mnCont.Replace('<ScottIsASuperCoolGuyYall>',$StoreNumber)
                $mnCont | Set-Content $mnt.FullName -Force
                Write-Log "Editing $mnt with the store number of $storenumber."
            }
        }
    }else{
        Write-Log "ERROR - Store number is null."
    }
    Write-Log "There have been $mntCnt .mnt files edited."
}

# Load the data using the xstore process.
Function Invoke-DataLoad {
        if(Test-Path -Path "C:\xstore\download"){

                #Add Main MNTs
                foreach($mnt in (Get-ChildItem -Path "$env:TMP\source-mnt" -Recurse | Where-Object {$_.Extension -ilike ".mnt"})){
                    $mntsToLoad += @(
                    [pscustomobject]@{LoadOrder=($mnt.Name).split('-')[0];Name=$mnt.Name;Path=$mnt.Fullname}
                    )
                }

                if($TRUE -eq $objTypeCheckboxStoreData.Checked){
                    if(Test-Path -Path $storeFolders -and $null -ne $storeNumber){
                        $storeNumber = 62
                        $warn.ForeColor = 'Black'
                        $warn.Text = "Finding Store Data."
                        #Find Correct Store Folder
                        $storeFolder = (Get-ChildItem -Directory -Path $storeFolders | Where-Object {$_.Name -ilike "*$StoreNumber*"})
                        #Add content of store folder to load list.
                        foreach($mnt in (Get-ChildItem -Path $storeFolder.FullName -Recurse | Where-Object {$_.Extension -ilike ".mnt"})){
                            if(Test-Numeric (($mnt.name).split("-")[0])){
                                if([Int64](($mnt.name).split("-")[0]) -gt [int]'49'){
                                    $ldorder = Get-Random -Minimum 50 -Maximum 99
                                }else{
                                    $ldorder = [int](($mnt.name).split("-")[0]) + 25
                                }
                            }else{
                                $ldorder = Get-Random -Minimum 50 -Maximum 99
                            }
                            $mntsToLoad += @(
                            [pscustomobject]@{LoadOrder=$ldorder;Name=$mnt.Name;Path=$mnt.Fullname}
                            )
                        }
                    }else{
                        $warn.ForeColor = 'red'
                        $warn.Text = "Store Folder does not exist."
                        Write-Log "ERROR - Store folder does not exist at $($storeFolder.FullName)."
                        Start-Sleep -Seconds 2
                    }
                }

                $mntsToLoad = $mntsToLoad | Sort-Object LoadOrder
                foreach($mnt in $mntsToLoad){

                    $mntName = $mnt.Name
                    Copy-Item -Path $mnt.Path -Destination 'C:\xstore\download'

                    $warn.ForeColor = 'Black'
                    $warn.Text = "Copying $mntName to load folder."

                    Write-Log "Copying $mntName to C:\xstore\download."
                    Start-Sleep -Seconds 2

                    $warn.ForeColor = 'Black'
                    $warn.Text = "Launching Dataloader2."

                    $form.Topmost = $true
                    Start-Process -FilePath "$env:WINDIR\system32\cmd.exe" -ArgumentList "/c C:\xstore\dataloader2.bat" -Wait

                    $failures = Get-ChildItem -Path 'C:\xstore\download' | Where-Object {$_.Name -ilike "fail*"}
                    $success = Get-ChildItem -Path 'C:\xstore\download' | Where-Object {$_.Name -ilike "succ*"}

                    if(($success.name).count -gt '0'){

                        Write-Log "Success recorded for $mntName."
                        $warn.ForeColor = 'Green'
                        $warn.Text = "$mntName success."

                    }
                    
                    If(($failures.Name).count -gt '0'){
                        
                    $warn.ForeColor = 'red'
                    $warn.Text = "Failure has been detected."

                    Write-Log "Failure recorded for $mntName."

                        foreach($falure in $failures){

                        $failrational = Get-Content $falure.Fullname     
                            $Falurelist +=  @(
                            [pscustomobject]@{Name=$mnt.Name;FailureReason=[string]$failrational}
                            )
                        }
                    }
                }

                if($null -ne $failrational){
                    $Falurelist | ConvertTo-Html | Out-File ".\Failures.html"
                }

                $mntsToLoad = $null
                $Falurelist = $null

                $warn.ForeColor = 'black'
                $warn.Text = "Cleaning up."
                Remove-Item -Path "$env:TMP\source-mnt" -Recurse -Force

                $warn.ForeColor = 'green'
                $warn.Text = "Process Complete."

        }else{
            $warn.ForeColor = 'red'
            $warn.Text = "xStore Downloads Does not exist."
            Write-Log "ERROR - xStore download folder does not exist."
        }
}

# OnClick button process.
Function Invoke-UIProcess {
    $testing = $false
    
    if($null -eq $textBox.Text -or $textbox.Text -eq ""){
        [System.Windows.MessageBox]::Show('Error, Store Number is Empty.','Error')
    }elseif($textBox.Text -notmatch '^\d+$'){
        [System.Windows.MessageBox]::Show('Error, Store Number is not a number.','Error')
    }elseif($textBox.Text.Length -gt '3'){
        [System.Windows.MessageBox]::Show('Error, Store Number longer than expected.','Error')
    }elseif((Test-Path -Path "C:\xstore\download") -ne $true -and $testing -eq $false){
        [System.Windows.MessageBox]::Show('Error, C:\xstore\download does not exist.','Error')
    }else{
        $global:sourcePath = $textBoxSource.Text
        $StoreNumber = $textBox.Text
        $StoreNumber = $StoreNumber.Trim()
            Get-LatestStoreData
            Invoke-DataCustomisation
            Invoke-DataLoad
    }
}

# If not called from the command line, show UI.
$form.ShowDialog()

#Clear all variables.
Get-Variable -Exclude PWD,*Preference | Remove-Variable -EA 0

exit 0