# Verify Running as Admin
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
If (!( $isAdmin )) {
    Write-Host "-- Restarting as Administrator" -ForegroundColor Cyan ; Start-Sleep -Seconds 1
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs 
    exit
}

#This script creates builds the lab as per the labconfig.ps1 file.
$ErrorActionPreference = "stop" #stop on any errors unless instructed otherwise
$Trace = ""
$loglevel = 0

#region: Functions

####CHANGE THIS TO USE SCRIPT PATH###

. test-path "D:\OneDrive\OneDrive - almoselhy\PowerShell Scripts\GitHub\LabAutomator\Convert-WindowsImage.ps1"

function Create-UnattendXML ($ComputerName,$BuiltinAdminPassword,$TimeZone,$OutputPath){

$UnattendFile = New-Item "$OutputPath" -type File -Force

$FileContent = @"
<?xml version="1.0" encoding="utf-8"?>
<unattend xmlns="urn:schemas-microsoft-com:unattend">

    <settings pass="oobeSystem">
        <component name="Microsoft-Windows-Shell-Setup" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
            <UserAccounts>
                <AdministratorPassword>
                    <Value>$BuiltinAdminPassword</Value>
                    <PlainText>true</PlainText>
                </AdministratorPassword>
            </UserAccounts>
        </component>
    </settings>

    <settings pass="specialize">
        <component name="Microsoft-Windows-Shell-Setup" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
            <ComputerName>$ComputerName</ComputerName>
            <TimeZone>$TimeZone</TimeZone>
        </component>
    </settings>
</unattend>
"@

Set-Content -path $OutputPath -value $FileContent
}

function Copy-DSCModule {
#This function can copy a list of modules to a specific location. Module can be downloaded if not available.
    Param (
        [Parameter(Mandatory=$true,Position=1)]
        [ValidateNotNull()]
        [string[]]$DSCModuleName,

        [Parameter(Mandatory=$true,Position=1)]
        [ValidateNotNull()]
        [string]$Destination
    )

    $DSCModuleName | foreach {
        WriteInfo -message "Checking DSC mdoule '$_'"
        $Script:Loglevel++
        
        $DSCModule = Get-DscResource -Module $_ -WarningAction SilentlyContinue
        
        #DSC Module installed.
        if($DSCModule){
            WriteInfo -message "Found DSC module. Copying to Tools Folder" -WaitForResult
                $DSCModulePath = ($DSCModule[0].ParentPath -split $_)[0] + "$_"
                Copy-Item -Path $DSCModulePath -Destination $Destination -Recurse
            WriteResult -Success
        }
        
        
        #DSC Module not installed
        else {
            WriteInfo -message "DSC module not installed. Downloading from the Internet"
            #Install NuGet Package provider
            if((Get-PackageProvider -Name NuGet) -eq $null){
                WriteInfo -message "NuGet package provider not installed. Downloading from the Internet." -WaitForResult
                    Install-PackageProvider -Name NuGet -Confirm:$false -Force
                WriteResult -Success
            }
            
            #Install DSC module
            WriteInfo -message "Installing Module" -WaitForResult
                Install-Module -Name xActiveDirectory -Confirm:$false -Force
            WriteResult -Success

            #Copy to Tools
            WriteInfo -message "Copying module to tools" -WaitForResult
                $DSCModule = Get-DscResource -Module $_
                $DSCModulePath = ($DSCModule[0].ParentPath -split $_)[0] + "$_"
                Copy-Item -Path $DSCModulePath -Destination $Destination -Recurse
            WriteResult -Success                

            
        }

        $DSCModule = $null #reset the variable
    
        $Script:Loglevel--
    } #$DSCModuleName | foreach
}

function WriteInfo([string]$message,[switch]$WaitForResult){
    if($WaitForResult){
        Write-Host "[$(Get-Date -Format hh:mm:ss)] INFO:    $("`t" * $script:LogLevel)$message" -NoNewline
        $Script:Trace += "[$(Get-Date -Format hh:mm:ss)] INFO:    $("`t" * $script:LogLevel)$message" 
    }
    else{
        Write-Host "[$(Get-Date -Format hh:mm:ss)] INFO:    $("`t" * $script:LogLevel)$message"  
        $Script:Trace += "[$(Get-Date -Format hh:mm:ss)] INFO:    $("`t" * $script:LogLevel)$message`r`n" 
    }
}

function WriteResult([string]$message,[switch]$Pass,[switch]$Success){
    if($Pass){
        $Script:Trace += " - Pass`r`n"
        Write-Host " - Pass" -ForegroundColor Cyan
        if($message){
            $Script:Trace += "[$(Get-Date -Format hh:mm:ss)] INFO:    $("`t" * $script:LogLevel)`t$message`r`n" 
            Write-Host "[$(Get-Date -Format hh:mm:ss)] INFO:    $("`t" * $script:LogLevel)`t$message" -ForegroundColor Cyan
        }
    }
    if($Success){
        $Script:Trace += " - Success`r`n"
        Write-Host " - Success" -ForegroundColor Green
        if($message){
            $Script:Trace += "[$(Get-Date -Format hh:mm:ss)] INFO:    $("`t" * $script:LogLevel)`t$message`r`n" 
            Write-Host "[$(Get-Date -Format hh:mm:ss)] INFO:    $("`t" * $script:LogLevel)`t$message" -ForegroundColor Green
        }
    } 
}

function WriteSuccess([string]$message){
    $Script:Trace += "[$(Get-Date -Format hh:mm:ss)] Success: $("`t" * $script:LogLevel)$message`r`n" 
    Write-Host "[$(Get-Date -Format hh:mm:ss)] Success: $("`t" * $script:LogLevel)$message" -ForegroundColor Green
}

function WriteError([string]$message,[switch]$Terminate){
    ""
    $Script:Trace += "[$(Get-Date -Format hh:mm:ss)] ERROR:   $("`t" * $script:LogLevel)$message`r`n" 
    Write-Host "[$(Get-Date -Format hh:mm:ss)] ERROR:   $("`t" * $script:LogLevel)$message" -ForegroundColor Red
    if($terminate) {Throw}
}

#endregion: Functions

try{
."D:\OneDrive\OneDrive - almoselhy\PowerShell Scripts\GitHub\LabAutomator\LAbConfig2.ps1"

#region: DSC Configurations

configuration DSC-SetupFirstDC {

    Import-DscResource -ModuleName 'PSDesiredStateConfiguration'
    Import-DscResource -ModuleName 'xComputerManagement' 
    Import-DscResource -ModuleName 'xNetworking'
    Import-DscResource -ModuleName 'xActiveDirectory'
    
    Node $LabConfig.FirstDCComputerName {
       
        xIPAddress SetIPAddress {
            InterfaceAlias = 'Ethernet'
            IPAddress = $labconfig.FirstDCIPAddress
            PrefixLength = '24'
            AddressFamily = 'IPv4'

        } #xIPAddress SetIPAddress
        
              
        WindowsFeature ADDS {
            Name = "AD-Domain-Services"
            Ensure = 'Present'            
        } #WindowsFeature ADDS

        WindowsFeature ADRSAT {
            Name = "RSAT-AD-Tools"
            Ensure = 'Present'
            IncludeAllSubFeature = $true
        } #WindowsFeature ADRSAT

        xADDomain FirstDomain {
            DomainName = $labconfig.DomainName
            DomainAdministratorCredential = $labconfig.DomainAdministratorCreds
            SafemodeAdministratorPassword = $labconfig.DomainAdministratorCreds
            DependsOn = "[xIPAddress]SetIPAddress","[WindowsFeature]ADDS","[WindowsFeature]ADRSAT"
        }

        xWaitForADDomain DscForestWait {
            DomainName = $labconfig.DomainName
            DomainUserCredential = $labconfig.DomainAdministratorCreds
            RetryCount = 50
            RetryIntervalSec = 30
            DependsOn = "[xADDomain]FirstDomain"

        }

        <#
        xADUser FirstUser {
            DomainName = $labconfig.DomainName
            DomainAdministratorCredential = $labconfig.DomainAdministratorCreds
            UserName = $LabAdminUsername
            Password = $LabAdminCreds
            PasswordNeverExpires = $true
            DependsOn = "[xWaitForADDomain]DscForestWait"
        }

        xADGroup AddFirstUserToDomainAdmins {
            
            GroupName = "Domain Admins"
            MembersToInclude = $LabAdminUsername
            DependsOn = "[xADUser]FirstUser"
        }
        #>




    } #Node "Localhost"

} #configuration SetupFirstDC

configuration DSC-MemberServer {
    param 
    ( 
        [Parameter(Mandatory)] 
        [string]$ComputerName, 
        
        [Parameter(Mandatory)] 
        [string]$IPAddress
    )

    Import-DscResource -ModuleName xComputerManagement
    Import-DscResource -ModuleName xNetworking
    Import-DscResource -ModuleName xActiveDirectory

    Node $ComputerName {
        
        xIPAddress IPAddress {
            InterfaceAlias = "Ethernet"
            IPAddress = $IPAddress
            PrefixLength = 24
            AddressFamily = 'IPv4'
        }

        xDNSServerAddress DNSServer {
            AddressFamily = 'IPv4'
            InterfaceAlias = "Ethernet"
            Address = $labconfig.FirstDCIPAddress
            DependsOn = "[xIPAddress]IPAddress"            
        }

        xWaitForADDomain WaitForDomain { #A little wait to check the VM is able to contact a DC before DJoin.
            DomainName =  $labconfig.DomainName
            DomainUserCredential = $labconfig.DomainAdministratorCreds
            RetryIntervalSec = 10
            RetryCount = 10
            DependsOn = "[xDNSServerAddress]DNSServer" 
        }
        xComputer JoinDomain {
            Name = $ComputerName
            DomainName = $labconfig.DomainName
            Credential = $labconfig.DomainAdministratorCreds
            DependsOn  = "[xWaitForADDomain]WaitForDomain"
        }
        
    }
}


# ConfigurationName -configurationData <path to ConfigurationData (.psd1) file>

[DSCLocalConfigurationManager()]  configuration DSC-LCMConfig{
    Node localhost
    {
        Settings
        {
            ConfigurationModeFrequencyMins = 15
            ConfigurationMode = 'ApplyAndMonitor'
            RebootNodeIfNeeded = $true
            ActionAfterReboot = 'ContinueConfiguration'    
        }
    }
}

#endregion: DSC Configurations

#region: Prepare Environment

    #Import Modules
    Import-Module -Name Hyper-V

    #Prepare proxy if needed
    if ($labconfig.ProxyServer){
        $PSDefaultParameterValues = @{
            "*:Proxy" = $labconfig.ProxyServer
            "*:ProxyCredential" = $labconfig.ProxyCreds
                                    }
    }

#endregion: Prepare Environment

#region: Create lab folder structure
WriteInfo -message "Creating Folder structure for the lab under: $($labconfig.RootPath)"
$loglevel++
    
    WriteInfo -message "Creating root folder for lab" -WaitForResult
        if(!(Test-Path -Path $labconfig.LabRootPath)){
            $LabPath = New-Item -Path $labconfig.LabRootPath -ItemType Directory -Force
        }
        else
        {
            WriteError -message "Folder already exists. Please delete it or change lab name." -Terminate
        }    
    WriteResult -Success -message $LabPath.FullName

    WriteInfo -message "Creating Folder for VMs" -WaitForResult
        $LabVMsPath = New-Item -Path $LabPath\VMs -ItemType Directory
    WriteResult -Success -message $LabVMsPath.FullName 

    WriteInfo -message "Creating Folder for Tools" -WaitForResult
        $LabToolsPath = New-Item -Path $LabPath\Tools -ItemType Directory
    WriteResult -Success -message $LabToolsPath.FullName 
  
    WriteInfo -message "Adding DSC modules to Tools Folder"
        $DSCModulesPath = New-Item -Path "$LabToolsPath\DSC" -Type Directory
        $DSCModules = ("xActiveDirectory",
                       "xComputerManagement",
                       "xNetworking")

        Copy-DSCModule -DSCModuleName $DSCModules -Destination $DSCModulesPath
    WriteSuccess -message "DSC modules added."

    WriteInfo -message "Creating Folder for Temp files" -WaitForResult
        $LabTempPath = New-Item -Path $LabPath\Temp -ItemType Directory
    WriteResult -Success -message $LabTempPath.FullName

$loglevel--
WriteSuccess -message "Folder structure created successfully."
#endregion: Create lab folder structure

#region: Create VM switch for lab
    WriteInfo -message "Creating private switch: $($labconfig.HyperVPrivateSwitchName)" -WaitForResult
        $VMSwitch = New-VMSwitch -Name $labconfig.HyperVPrivateSwitchName -SwitchType Private
    WriteResult -Success
#endregion

#region: Parent VHDX
    #region: Create Parent VHDX = $true
    if($labconfig.CreateParentVHDX){
    WriteInfo -message "Creating Parent VHDX file for Server"
    $loglevel++

        WriteInfo -message "Creating folder for parent VHDX" -WaitForResult
            $LabParentFolder = New-Item -Path "$($labconfig.LabRootPath)\Parent" -ItemType Directory
        WriteResult -Success

        WriteInfo -message "Mounting Server ISO file" -WaitForResult
            $ISOServer = Mount-DiskImage -ImagePath $labconfig.ServerISOPath -PassThru #PassThru returns an object to the variable
            $MountPath = (Get-Volume -DiskImage $ISOServer).DriveLetter+':'
        WriteResult -Success -message "Mounted at $MountPath"

        WriteInfo -message "Creating VHDX file" -WaitForResult
            $ServerParentVHDXPath = "$LabParentFolder\$($labconfig.LabName)_ServerParent.vhdx"
            $Splatting = @{
                            SourcePath = "$MountPath\sources\install.wim"
                            Edition    = $labconfig.ServerEdition
                            VHDPath    = $ServerParentVHDXPath 
                            SizeBytes  = $labconfig.VHDXSize
                            VHDFormat  = "VHDX"
                            DiskLayout = "UEFI"
                          }
            if($labconfig.ServerUpdatePackagePath) { #only if the package path is specified.
                $Splatting+= @{ Package = $labconfig.ServerUpdatePackagePath}
            }
            Convert-WindowsImage @Splatting
        WriteResult -Success -message $ServerParentVHDXPath

        WriteInfo -message "Unmounting ISO file" -WaitForResult
            Dismount-DiskImage -ImagePath $labconfig.ServerISOPath
        WriteResult -Success      
    
    $loglevel--
    WriteSuccess -message "Server Parent VHDX create successfully."        
    }        
    #endregion: Create Parent VHDX = $true
    #region: Create Parent VHDX = $false
    if(!($labconfig.CreateParentVHDX)){
        $ServerParentVHDXPath = $labconfig.ServerParentVHDXPath
    }
    #endregion
#endregion: Parent VHDX

#region: Create First DC
WriteInfo -message "Creating First Domain Controller"
$loglevel++
    #Create VM
    WriteInfo -message "Creating VM" -WaitForResult
        $VM = New-VM -Name $labconfig.FirstDCVMName -MemoryStartupBytes 2GB -SwitchName $labconfig.HyperVPrivateSwitchName -Path $LabVMsPath -Generation 2 -NoVHD
        $VMFolder = $VM.Path
    WriteResult -Success -message $VM.Name

    #Create VHD
    WriteInfo -message "Creating differencing VHDX and add it to VM" -WaitForResult
        $VHD = New-VHD -Path "$VMFolder\$($labconfig.FirstDCVMName).vhdx" -ParentPath $ServerParentVHDXPath -Differencing
        Add-VMHardDiskDrive -VM $VM -ControllerType SCSI -Path $VHD.Path
        $VMHDD = Get-VMHardDiskDrive -VM $VM
        Set-VMFirmware -VM $VM -FirstBootDevice $VMHDD
    WriteResult -Success -message $VHD.Path

    #Mount VHD
    writeinfo -message "Mounting VHD to add configuration files" -WaitForResult
        $MountFolder = New-Item -Path "$LabTempPath\MountFolder" -Type Directory -Force
        Mount-WindowsImage -ImagePath $VHD.Path -Path $MountFolder.FullName -Index 1 | Out-Null
    WriteResult -Success -message $MountFolder
        
    #Create unattend.xml and place it in Panther
    WriteInfo -message "Creating Unattend.XML file" -WaitForResult    
        $Panther = New-item -type Directory -Path "$MountFolder\Windows\Panther" -force
        Create-UnattendXML `
            -ComputerName $labconfig.FirstDCComputerName `
            -BuiltinAdminPassword $labconfig.LabPassword `
            -TimeZone $labconfig.TimeZone `
            -OutputPath "$Panther\unattend.xml"
    WriteResult -Success

    #Copy DSC Resources
    WriteInfo -message "Copying DSC modules" -WaitForResult
        Copy-Item -Path "$DSCModulesPath\*" -Destination "$MountFolder\Program Files\WindowsPowerShell\Modules" -Recurse
    WriteResult -Success        

    #Create DSC MOF Files and copy them to VHD
    WriteInfo -message "Creating DSC MOF files" -WaitForResult
        $DSCConfigData = @{
            AllNodes = @(
                @{
                    NodeName = $labconfig.FirstDCComputerName
                    PSDscAllowPlainTextPassword = $true
                    PSDscAllowDomainUser = $true
                }
            )
        }
        $DSCConfig = DSC-SetupFirstDC -OutputPath "$LabTempPath\DSCconfig" -ConfigurationData $DSCConfigData
        $DSCLCM    = DSC-LCMConfig    -OutputPath "$LabTempPath\DSCconfig"
    
        Copy-Item -path $DSCConfig -Destination "$MountFolder\Windows\system32\Configuration\pending.mof"
        Copy-Item -path $DSCLCM    -Destination "$MountFolder\Windows\system32\Configuration\metaconfig.mof"
    WriteResult -Success
    
    #Dismount VHD
    WriteInfo -message "Dismounting VHD" -WaitForResult
        Dismount-WindowsImage -Path $MountFolder -Save | Out-Null
    WriteResult -Success
    
    #Clear Temp files
    WriteInfo -message "Deleting temp files" -WaitForResult
        Remove-Item $LabTempPath\* -Recurse -Force
    WriteResult -Success
    
    #Start VM and wait for configuration to be successfull
    WriteInfo -message "Starting VM and waiting for configuration to apply."
    $loglevel++
        Start-VM -VM $VM
        $creds = $labconfig.DomainAdministratorCreds
        $Job= Start-Job -Name "First Domain Controller" -ArgumentList $VM,$creds -ScriptBlock {          
            Param ($VM,$creds)
            Import-Module -Name Hyper-V
            $FailureCounter = 0
            do{
                $test=Invoke-Command -VMGuid $VM.id -ScriptBlock {Get-DscConfigurationStatus} -Credential $creds -ErrorAction SilentlyContinue
                if ($test -eq $null) {
                    Start-Sleep -Seconds 5
                }    
                elseif ($test.Status -eq "Failure") {
                    $FailureCounter++
                    Invoke-Command -VMGuid $VM.id -ScriptBlock {Start-DscConfiguration -UseExisting} -Credential $creds
                    Start-Sleep -Seconds 30
                }
                elseif ($test.Status -eq "Success" -and $test.rebootrequested -eq $false){
                    return "Success"                        
                }
                else {
                    Start-Sleep -Seconds 5
                }                    
            }until ($FailureCounter -gt 3)
                
            throw "Tried 3 times and failed"
        }#Job
        WriteInfo -message "Waiting for background job to complete"
            $Date = Get-Date
            while ($Job.State -eq "Running")
            {     
                $Count = ($Job|where-object {$_.State -eq "Completed"} | Measure-Object -Property State).Count
                $Percentage = $Count/$Jobs.count*100
                $WaitTime = "{0:hh}:{0:mm}:{0:ss}" -f (New-TimeSpan -Start $Date -End (Get-Date))
                Write-Progress -Activity "Waiting for DSC to finish its job" -Status "Wait time: $WaitTime" -PercentComplete $Percentage
                Start-Sleep 1  
            }
        WriteSuccess -message "Job finished finished. Waited for: $WaitTime"        
    
    $loglevel--
    WriteSuccess -message "First Domain Contoller is up and running!"

$loglevel--
WriteSuccess -message "First DC is now online!"
#endregion: Create First DC

#region: Create Member Servers
if($labconfig.CreateMemberServers){
WriteInfo -message "Creating Member servers"
$loglevel++
    
    $Jobs = @()
    foreach($MemberServer in $labconfig.MemberServerNames){
    WriteInfo -message "Creating '$MemberServer.$($labconfig.DomainName)'"
    $loglevel++
        
        #Create VM
        writeinfo -message "Creating VM" -WaitForResult
            $VMName = "$($labconfig.LabPrefix)-$MemberServer"
            $VM = New-VM -Name $VMName -MemoryStartupBytes 2GB -SwitchName $labconfig.HyperVPrivateSwitchName -Path $LabVMsPath -Generation 2 -NoVHD
            $VMFolder = $VM.Path
        WriteResult -Success

        #Create VHD
        WriteInfo -message "Creating differencing VHDX and add it to VM" -WaitForResult
            $VHD = New-VHD -Path "$VMFolder\$VMName.vhdx" -ParentPath $ServerParentVHDXPath -Differencing
            Add-VMHardDiskDrive -VM $VM -ControllerType SCSI -Path $VHD.Path
            $VMHDD = Get-VMHardDiskDrive -VM $VM
            Set-VMFirmware -VM $VM -FirstBootDevice $VMHDD
        WriteResult -Success -message $VHD.Path

        #Mount VHD
        writeinfo -message "Mounting VHD to add configuration files" -WaitForResult
            $MountFolder = New-Item -Path "$LabTempPath\MountFolder" -Type Directory -Force
            Mount-WindowsImage -ImagePath $VHD.Path -Path $MountFolder.FullName -Index 1 | Out-Null
        WriteResult -Success -message $MountFolder
        
        #Create unattend.xml and place it in Panther
        WriteInfo -message "Creating Unattend.XML file" -WaitForResult    
            $Panther = New-item -type Directory -Path "$MountFolder\Windows\Panther" -force
            Create-UnattendXML `
                -ComputerName $MemberServer `
                -BuiltinAdminPassword $labconfig.LabPassword `
                -TimeZone $labconfig.TimeZone `
                -OutputPath "$Panther\unattend.xml"
        WriteResult -Success

        #Copy DSC Resources
        WriteInfo -message "Copying DSC modules" -WaitForResult
            Copy-Item -Path "$DSCModulesPath\*" -Destination "$MountFolder\Program Files\WindowsPowerShell\Modules" -Recurse
        WriteResult -Success        

        #Generate IP Address
            $IPAddress = $labconfig.Subnet.Replace('#',($labconfig.MemberServerFirstIP + $labconfig.MemberServerNames.IndexOf($MemberServer)))
            WriteInfo -message "VM will use the IP Address: $IPAddress"
        #Create DSC MOF Files and copy them to VHD
        WriteInfo -message "Creating DSC MOF files" -WaitForResult
            $DSCConfigData = @{
                AllNodes = @(
                    @{
                        NodeName = $MemberServer
                        PSDscAllowPlainTextPassword = $true
                        PSDscAllowDomainUser = $true
                    }
                )
            }
            $DSCConfig = DSC-MemberServer -ComputerName $MemberServer -IPAddress $IPAddress -OutputPath "$LabTempPath\DSCconfig" -ConfigurationData $DSCConfigData
            $DSCLCM    = DSC-LCMConfig    -OutputPath "$LabTempPath\DSCconfig"
    
            Copy-Item -path $DSCConfig -Destination "$MountFolder\Windows\system32\Configuration\pending.mof"
            Copy-Item -path $DSCLCM    -Destination "$MountFolder\Windows\system32\Configuration\metaconfig.mof"
        WriteResult -Success
    
        #Dismount VHD
        WriteInfo -message "Dismounting VHD" -WaitForResult
            Dismount-WindowsImage -Path $MountFolder -Save | Out-Null
        WriteResult -Success
    
        #Clear Temp files
        WriteInfo -message "Deleting temp files" -WaitForResult
            Remove-Item $LabTempPath\* -Recurse -Force
        WriteResult -Success
    
        #Start VM and wait for configuration to be successfull
        WriteInfo -message "Starting VM and starting a job to monitor DSC progress in the background"
        
        $loglevel++
            Start-VM -VM $VM
            $creds = New-Object System.Management.Automation.PSCredential("$MemberServer\Administrator",$LabConfig.LabPwdScr)
            $jobs+= Start-Job -Name $MemberServer -ArgumentList $VM,$creds -ScriptBlock {
                Param ($VM,$creds)
                Import-Module -Name Hyper-V
                $FailureCounter = 0
                do{
                    $test=Invoke-Command -VMGuid $VM.id -ScriptBlock {Get-DscConfigurationStatus} -Credential $creds -ErrorAction SilentlyContinue
                    if ($test -eq $null) {
                        Start-Sleep -Seconds 5
                    }    
                    elseif ($test.Status -eq "Failure") {
                        $FailureCounter++
                        Invoke-Command -VMGuid $VM.id -ScriptBlock {Start-DscConfiguration -UseExisting} -Credential $creds
                        Start-Sleep -Seconds 30
                    }
                    elseif ($test.Status -eq "Success" -and $test.rebootrequested -eq $false){
                        return "Success"                        
                    }
                    else {
                        Start-Sleep -Seconds 5
                    }                    
                }until ($FailureCounter -gt 3)
                
                throw "Tried 3 times and failed"
            } #Jobs
        $loglevel--
        WriteSuccess -message "VM is ready!"
    $loglevel--
    WriteSuccess -message "$MemberServer.$($labconfig.DomainName) VM is up and job is running."
    }

    
    WriteInfo -message "Waiting for background jobs to complete"
        $Date = Get-Date
        while ($Jobs.State -contains "Running")
        {     
            $Count = ($Jobs|where-object {$_.State -eq "Completed"} | Measure-Object -Property State).Count
            $Percentage = $Count/$Jobs.count*100
            $WaitTime = "{0:hh}:{0:mm}:{0:ss}" -f (New-TimeSpan -Start $Date -End (Get-Date))
            Write-Progress -Activity "Waiting for Member VMs to join domain" -Status "$Count Complete - Wait time: $WaitTime" -PercentComplete $Percentage
            Start-Sleep 1  
        }
    WriteSuccess -message "All jobs finished. Waited for: $WaitTime"
    

$loglevel--
WriteSuccess -message "Member Servers created succesffully"
}
#endregion: Create Member Servers


} #try
catch{
    $loglevel = 0
    WriteError "An error occured and script terminated."
    writeError $Error[0]
} #catch
