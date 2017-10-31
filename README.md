# The Lab Automator
A PowerShell lab automator to make your life easier.

Many parts of this script is inspired from this project https://github.com/Microsoft/ws2016lab

Use LabConfig.PS1 to configure the lab then run the LabAutomatorMain to create it.

## Usage
Create a copy the SampleLabConfig.PS1 file and edit it as desired then run the main script.

## Actions
The script will perform the following actions,
1. Prompt for the location of the LabConfig.PS1 file. So you can have many!
2. Download Convert-WindowsImage.ps1 if it is not available.
3. Create a folder structure for the lab at the defined location in LabConfig.PS1
4. Copy required DSC resources or download them if they are not available.
5. Create a VM Switch named: **Lab-LabName**
6. Create parent VHDX files. You configure the script to just use an existing one from LabConfig.PS1 which I recommend to save time and space.
7. Create the following VMs with the name: **Lab-LabName-ComputerName** e.g. Lab-Contoso-DC01
   1. Create a VM that will act as the first domain in the forest.Domain name will be **LabName.lab**
   2. Create VMs as per the member server part of the labconfig.ps1 script.
  
## What can break things
* You are not running as Admin. the script already checks for that.
* Hyper-V is not installed
* A folder already exists where the script should build the lab. Just delete it.
* A VM switch with the same name exists.
* A VM with the same name exists.

## How to clean
Well, I'm planning to create an automatic cleaning script for this, but for now you can do the following,
1. Turn off all lab VMs.
2. Delete all VMs from Hyper-V console.
3. Delete the VM switch.
4. Delete the lab folder.
