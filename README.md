# PrintEase

Install print drivers on Windows devices using PowerShell. This script can also be used with the Win32 Prep Tool to deploy via Intune.

## Deployment
This guide outlines the steps to set up the script for installing the required print drivers.

### Setting up folders.

Create a new folder, within the folder create two addtional folders called `input` and `output`.

### Copy Scripts

Copy the `Install.ps1` and `Uninstall.ps1` files into the input folder.

### Download print driver

Download the required print driver and extract all files to the `input` folder.
Take note of the driver name, usually found in the INF file.

### Test Script

Execute the script to ensure the print driver installation works correctly:

```Powershell
install.ps1 -DriverName "YOUR PRINT DRIVER NAME" -INFFile "PRINT DRIVER INF FILE"
```
Verify the driver was installed using the ```Get-PrinterDriver``` cmdlet.
```Powershell
Get-PrinterDriver

#EXAMPLE OUTPUT

Name                       PrinterEnvironment    Manufacturer
----                       ------------------    ------------
Lexmark Universal v2 XL    Windows x64           Lexmark

```

## Deployment with Intune

Download the Intune Win32 Packaging Tool from here. - https://github.com/Microsoft/Microsoft-Win32-Content-Prep-Tool

Extract the IntuneWinAppUtil.exe file to the top-level folder and execute the ```IntuneWinAppUtil.exe``` file.

Configure Packaging:

```Powershell
Please specify the source folder: Input
Please specify the setup file: Input\Install.ps1
Please specify the output folder: Output
```
You can now deploy the install.intunewin package via Intune.

```Batch
Install command: powershell.exe -executionpolicy bypass -file install.ps1 -DriverName "YOUR PRINT DRIVER NAME" -INFFile "PRINT DRIVER INF FILE"
Uninstall command: powershell.exe -executionpolicy bypass -file uninstall.ps1 -DriverName "YOUR PRINT DRIVER NAME" -DriverLocation "C:\Windows\System32\DriverStore\FileRepository\YOUR PRINT DRIVER INSTALL LOCATION" -INFFile "PRINT DRIVER INF FILE"
```

Detection Rules

```
Type: File
Path/Code: C:\Windows\System32\DriverStore\FileRepository\YOUR PRINT DRIVER INSTALL LOCATION.
File or Folder Name: PRINT DRIVER INF FILE.
Detection Method: File or Folder Exist.
```

## Adding Printers

Now the print driver has been successfully deployed you can go ahead and connect to a network/shared printer without the need for administrator rights.

You can also use the ```Add-Printer``` cmdlet to connect to the shared printer.

```Powershell
Add-Printer -ConnectionName "\\printServer\printerName"
```

### Adding a none-shared printer. 

To add a none shared printer you can use the ```Add-PrinterPort``` and the ```Add-Printer``` cmdlet. 

```Powershell
Add-PrinterPort -Name "PORT NAME (USALLY PRINTER IP)" -PrinterHostAddress "PRINTER IP"
Add-Printer -Name "PRINTER NAME" -DriverName "PRINT DRIVER NAME" -PortName "YOUR PORT NAME"
```

If you're planning on creating a secondary script or using other software to connect to the printers, I would recommend adding the driver script as a dependency. This will ensure the drivers are installed prior to trying to connect to the printer.

## PaperCut

For those who are using PaperCut, I would recommend configuring PaperCut Print Deploy. This piece of software will allow your user to connect to network printers automatically, once the print drivers have been installed. 

The software can also be deployed via Intune, if you choose to deploy it this way, please ensure you have setup dependencies.

### Authentication

Some users may have trouble connecting to the print server if they use Windows Hello to login. I would recommend enforcing all managed devices to use a password, this will ensure your users can connect to the print server. 

For those who use BYOD, look into PaperCut Moblity Print.
