Configuration Config {
    param 
    ( 
        [Parameter(Mandatory)] 
        [string]$NodeName
    )

    Node $NodeName
    {
        Script CreateFolder
        {
            SetScript = {New-Item -Type Directory -Name ws2016lab -Path d:}
            TestScript = {Test-Path -Path d:\ws2016lab}
            GetScript = {   @{Ensure = if (Test-Path -Path d:\ws2016lab) {'Present'} else {'Absent'}}   }
        }
        Script DownloadScripts
        {
            SetScript = {
                [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
                Invoke-WebRequest -UseBasicParsing -Uri https://github.com/Microsoft/ws2016lab/blob/master/scripts.zip?raw=true -OutFile d:\scripts.zip
            }
            TestScript = {Test-Path -Path d:\scripts.zip}
            GetScript = { @{Ensure = if (Test-Path -Path d:\scripts.zip) {'Present'} else {'Absent'}} }
            DependsOn = "[Script]CreateFolder"
        }
        Script UnzipScripts
        {
            SetScript = {Expand-Archive d:\scripts.zip -DestinationPath d:\ws2016lab -Force}
            TestScript = {!("1_Prereq.ps1","2_CreateParentDisks.ps1","3_Deploy.ps1","Cleanup.ps1","LabConfig.ps1" | ForEach-Object {Test-Path -Path d:\ws2016lab\$_}).contains($false)}
            GetScript = {   @{Ensure = if (!("1_Prereq.ps1","2_CreateParentDisks.ps1","3_Deploy.ps1","Cleanup.ps1","LabConfig.ps1" | ForEach-Object {Test-Path -Path d:\ws2016lab\$_}).contains($false)) {'Present'} else {'Absent'}} }
            DependsOn = "[Script]DownloadScripts"
        }
        WindowsOptionalFeature HyperV
        {
            Name = "Microsoft-Hyper-V-All"
            Ensure = "Enable"
            DependsOn = "[Script]UnzipScripts"
        }

        LocalConfigurationManager 
        {
            RebootNodeIfNeeded = $true
        }
    }
}




