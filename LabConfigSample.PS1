#Make you changes here to meet your lab's needs.

$LabConfig = @{
    #Main Info
    LabName  = "SampleLab" #Domain name will be SampleLab.lab
    TimeZone = "Egypt Standard Time" #See here for options: https://msdn.microsoft.com/en-us/library/ms912391
    LabsPath = "D:\VMs\Labs" #A folder with the lab name will be created under this path.
    
    #Sources
    CreateParentVHDX = $true
        #Use this only if Create Parents is set to true
    VHDXSize = 30GB
    ServerEdition = 'ServerDataCenterCore' #You should be learning to use Core already
    
    ServerISOPath = "D:\VMs\Lab\Sources\SW_DVD9_Win_Svr_STD_Core_and_DataCtr_Core_2016_64Bit_English_-3_MLF_X21-30350.ISO"

    ServerUpdatePackagePath = "D:\VMs\Lab\Sources\windows10.0-kb4041688-x64_a098c258a1d8f6b4bbfff87ee5ab687d629d3bd9.msu" #use $null to skip installing packages (not recommended)
        #Use this only if Create Parents is set to false
    ServerParentVHDXPath = $null


    #Credentials
    LabPassword = "P@ssw0rd" #Only one password is used lab wide.


    #VMs
    FirstDCComputerName = "DC01"
    FirstDCIPLastOctet  = "10"


    #Member Servers
    CreateMemberServers = $true
    MemberServerFirstIP = 20 #the last octet begin with this number, must be an integer
    MemberServerNames = "SRV01","SRV02","SRV03"


    #Network Configuration
    Subnet = "192.168.1.#" #Always assume /24
    Gateway = "1" #Replaces the last octet

    #Proxy settings for file downloads
        #Use $null for these parameters if they are not required.
    ProxyServer = $null #"HTTP://proxy:8080"
    ProxyUsername = $null #"Domain\username"
    ProxyPassword = $null #'P@ssw0rd'
}

#Calculated Values. Do not edit after this line.

$LabConfig += @{
        #Domain Info
    DomainName = $LabConfig.LabName + ".lab"
    LabPrefix = "Lab-$($LabConfig.LabName)"

    LabPwdScr = ConvertTo-SecureString -String $LabConfig.LabPassword -AsPlainText -Force
}

$DelRootPath    = "$($LabConfig.LabsPath)\$($LabConfig.LabName)"


$LabConfig += @{
    
    #Folders
    LabRootPath     = $DelRootPath 

    #Credentials
    BuiltinAdministratorCreds = New-Object System.Management.Automation.PSCredential("Administrator",$LabConfig.LabPwdScr)
    DomainAdministratorCreds = New-Object System.Management.Automation.PSCredential("$($LabConfig.DomainName)\Administrator",$LabConfig.LabPwdScr)

    
    #Hyper-V Configuration
    HyperVPrivateSwitchName = $LabConfig.LabPrefix

    #Network
    FirstDCIPAddress = $LabConfig.Subnet.Replace('#',10)

    #VMs
    FirstDCVMName = "$($LabConfig.LabPrefix)-$($LabConfig.FirstDCComputerName)"


    GatewayIPAddress = $LabConfig.Subnet.Replace('#',$LabConfig.Gateway)

    #Proxy
    ProxyCreds = New-Object System.Management.Automation.PSCredential($LabConfig.ProxyUsername,(ConvertTo-SecureString -String $labconfig.ProxyPassword -AsPlainText -Force))
}

Get-Variable -Name del* | Remove-Variable
