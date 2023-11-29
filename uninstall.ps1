[CmdletBinding()]
Param (
    [Parameter(Mandatory = $True)]
    [String]$DriverName,
    [Parameter(Mandatory = $True)]
    [String]$DriverLocation,
    [Parameter(Mandatory = $True)]
    [String]$INFFile
)


#Reset Error catching variable
$Throwbad = $Null

#Run script in 64bit PowerShell to enumerate correct path for pnputil
If ($ENV:PROCESSOR_ARCHITEW6432 -eq "AMD64") {
    Try {
        &"$ENV:WINDIR\SysNative\WindowsPowershell\v1.0\PowerShell.exe" -File $PSCOMMANDPATH -DriverName $DriverName -DriverLocation $DriverLocation -INFFile $INFFile
    }
    Catch {
        Write-Error "Failed to start $PSCOMMANDPATH"
        Write-Warning "$($_.Exception.Message)"
        $Throwbad = $True
    }
}

function Write-LogEntry {
    param (
        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Value,
        [parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [string]$FileName = "$("remove-print-driver").log",
        [switch]$Stamp
    )

    #Build Log File appending System Date/Time to output
    $LogFile = Join-Path -Path $env:SystemRoot -ChildPath $("Temp\$FileName")
    $Time = -join @((Get-Date -Format "HH:mm:ss.fff"), " ", (Get-WmiObject -Class Win32_TimeZone | Select-Object -ExpandProperty Bias))
    $Date = (Get-Date -Format "MM-dd-yyyy")

    If ($Stamp) {
        $LogText = "<$($Value)> <time=""$($Time)"" date=""$($Date)"">"
    }
    else {
        $LogText = "$($Value)"   
    }
	
    Try {
        Out-File -InputObject $LogText -Append -NoClobber -Encoding Default -FilePath $LogFile -ErrorAction Stop
    }
    Catch [System.Exception] {
        Write-Warning -Message "Unable to add log entry to $LogFile.log file. Error message at line $($_.InvocationInfo.ScriptLineNumber): $($_.Exception.Message)"
    }
}

Write-LogEntry -Value "##################################"
Write-LogEntry -Stamp -Value "Uninstallation started"
Write-LogEntry -Value "##################################"
Write-LogEntry -Value "Uninstalling print driver using the following values..."
Write-LogEntry -Value "Driver Name: $DriverName"
Write-LogEntry -Value "Driver Location: $DriverLocation"
Write-LogEntry -Value "INF File: $INFFile"

If (-not $ThrowBad) {
    Try {
    
        #Uninstall driver
        $DriverExist = Get-PrinterDriver -Name $DriverName -ErrorAction SilentlyContinue
        if (-not $DriverExist) {
            Write-LogEntry -Stamp -Value "Print Driver ""$($DriverName)"" already removed. Skipping driver uninstallation."
        }
        else {
            Write-LogEntry -Stamp -Value "Removing Printer Driver ""$($DriverName)"""
            Stop-Service -Name "Spooler" -Force
            sleep -Seconds 5
            Start-Service -Name "Spooler"
            sleep -Seconds 5
            Remove-PrinterDriver -Name $DriverName -Confirm:$false
        }
    }
    Catch {
        Write-Warning "Error installing Printer Driver"
        Write-Warning "$($_.Exception.Message)"
        Write-LogEntry -Stamp -Value "Error installing Printer Driver"
        Write-LogEntry -Stamp -Value "$($_.Exception)"
        $ThrowBad = $True
    }
}

$INFARGS = @(
    "/delete-driver"
    "$DriverLocation\$INFFile"
    "/force"
)

If (-not $ThrowBad) {

    Try {

        #Stage driver to driver store
        Write-LogEntry -Stamp -Value "Removing Driver from Windows Driver Store using INF ""$($INFFile)"""
        Write-LogEntry -Stamp -Value "Running command: Start-Process pnputil.exe -ArgumentList $($INFARGS) -wait -passthru"
        Start-Process pnputil.exe -ArgumentList $INFARGS -wait -passthru

    }
    Catch {
        Write-Warning "Error removing driver from Driver Store"
        Write-Warning "$($_.Exception.Message)"
        Write-LogEntry -Stamp -Value "Error removing driver from Driver Store"
        Write-LogEntry -Stamp -Value "$($_.Exception)"
        $ThrowBad = $True
    }
}

If ($ThrowBad) {
    Write-Error "An error was thrown during installation. Installation failed. Refer to the log file in %temp% for details"
    Write-LogEntry -Stamp -Value "Installation Failed"
}