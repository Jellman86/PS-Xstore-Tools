function Get-JavaKeyStoreCerts {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [Alias('FullName')]  # This allows pipeline input from Get-ChildItem
        [String]$jksPath,
        
        [Parameter(Mandatory = $true)]
        [String]$jksPathPass,
        
        [Parameter()]
        [ValidateSet('Table', 'List', 'Object')]
        [String]$OutputFormat = 'Table'
    )

    process {
        Write-Verbose "Processing keystore: $jksPath"
        $jksParsed = @()
        $tempFile = $null

        try {
            # Create temp file
            $tempFile = [System.IO.Path]::GetTempFileName()

            # Run keytool and capture output
            $certBundle = & keytool -list -v -keystore $jksPath -storepass $jksPathPass
            if ($LASTEXITCODE -ne 0) {
                throw "Keytool execution failed with exit code $LASTEXITCODE"
            }

            $processedCertBundle = @()
            foreach ($line in $certBundle) {
                if ($line -match "\*{43}") {
                    $processedCertBundle += "----delimiter---"
                }
                elseif ($line -is [string] -and -not [string]::IsNullOrWhiteSpace($line)) {
                    $processedCertBundle += $line.Trim()
                }
            }

            # Process certificates
            $processedCertBundle = $processedCertBundle -join "`n" -replace "(----delimiter---\s*){2,}", "----delimiter---"
            $certificates = $processedCertBundle -split "----delimiter---" | Where-Object { $_.Trim() -ne "" }

            foreach ($certificate in $certificates) {
                $certInfo = @{
                    Alias = $null
                    ValidFrom = $null
                    Expires = $null
                }

                foreach ($line in ($certificate -split "`n")) {
                    if ($line -match "Alias\s+name:\s*(.+)") {
                        $certInfo.Alias = $matches[1].Trim()
                    }
                    elseif ($line -match "Valid from:\s+(.+?)\s+until:\s+(.+)$") {
                        try {
                            $validFrom = ($matches[1] -replace "\s+\d{2}:\d{2}:\d{2}\s+[A-Z]{3,4}", "")
                            $expiresOn = ($matches[2] -replace "\s+\d{2}:\d{2}:\d{2}\s+[A-Z]{3,4}", "")
                            
                            $certInfo.ValidFrom = Get-Date ([datetime]::Parse($validFrom)) -Format "dd/MM/yyyy"
                            $certInfo.Expires = Get-Date ([datetime]::Parse($expiresOn)) -Format "dd/MM/yyyy"
                        }
                        catch {
                            Write-Warning "Failed to parse dates for certificate $($certInfo.Alias): $_"
                            continue
                        }
                    }
                }

                if ($certInfo.Alias -and $certInfo.ValidFrom -and $certInfo.Expires) {
                    $jksParsed += [PSCustomObject]$certInfo
                }
            }

            # Output results based on format
            Write-Verbose "Found $($jksParsed.Count) certificates in $jksPath"
            
            switch ($OutputFormat) {
                'Table' { 
                    $jksParsed | Select-Object Alias, ValidFrom, Expires | Format-Table -AutoSize 
                }
                'List' { 
                    $jksParsed | Format-List 
                }
                'Object' { 
                    $jksParsed 
                }
            }
        }
        catch {
            Write-Error "Failed to process keystore $jksPath : $_"
        }
        finally {
            if ($tempFile -and (Test-Path $tempFile)) {
                Remove-Item $tempFile -Force -ErrorAction SilentlyContinue
            }
        }
    }
}

# Example usage:
 Get-ChildItem -Path "c:\Path" | Get-JavaKeyStoreCerts -jksPathPass "password" -OutputFormat Table