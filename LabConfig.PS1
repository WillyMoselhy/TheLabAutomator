
$LabConfig = @{
    #Main Info
    LabName  = "EV"
    TimeZone = "Egypt Standard Time" #https://msdn.microsoft.com/en-us/library/ms912391%28v=winembedded.11%29.aspx?f=255&MSPPError=-2147217396
    
    LabsPath = "D:\VMs\Labs" #A folder with the lab name will be created under this path.
    
    #Sources
    CreateParentVHDX = $false
        #Use this only if Create Parents is set to true
    VHDXSize = 30GB
    ServerEdition = 'ServerDataCenterCore' #You should be learning to use Core already
    
    ServerISOPath = "D:\VMs\Lab\Sources\SW_DVD9_Win_Svr_STD_Core_and_DataCtr_Core_2016_64Bit_English_-3_MLF_X21-30350.ISO"
    ClientISOPath = "" #only required if you enable client creation.

    ServerUpdatePackagePath = "D:\VMs\Lab\Sources\windows10.0-kb4039396-x64_bd1f9e1c7add02b8f3334f1aeaa07cae6632c3cf.msu" #use $null to skip installing packages (not recommended)
    ClientUpdatePackagePath = ""
        #Use this only if Create Parents is set to false
    ServerParentVHDXPath = "D:\VMs\Labs\Parent\WillyLabs_ServerParent.vhdx"
    ClientParentVHDXPath = "" #only required if you enable client creation.


    #Credentials
    LabPassword = "P@ssw0rd" #Only one password is used lab wide.

    #VMs
    FirstDCComputerName = "DC01"
    FirstDCIPLastOctet  = "10"

    #Member Servers
    CreateMemberServers = $true
    MemberServerFirstIP = 20 #the last octet begin with this number, must be an integer
    MemberServerNames = "Exchange","HyperV","SCCM"


    #Network Configuration
    Subnet = "192.168.1.#" #Always assume /24
    Gateway = "1" #Replaces the last octet

    #Proxy settings for file downloads
        #Use $null for these parameters if they are not required.
    ProxyServer = "HTTP://proxy:8080"
    ProxyUsername = "Domain\Username"
    ProxyPassword = 'P@ssW0rd'
}

#Calculated Values

$LabConfig += @{
        #Domain Info
    DomainName = $LabConfig.LabName + ".lab"
    LabPrefix = "Lab-$($LabConfig.LabName)"

    LabPwdScr = ConvertTo-SecureString -String $LabConfig.LabPassword -AsPlainText -Force
}


$LabConfig += @{
    
    #Folders
    LabRootPath     = "$($LabConfig.LabsPath)\$($LabConfig.LabName)"


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

