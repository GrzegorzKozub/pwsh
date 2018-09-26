function Install-VisualStudio {
    [CmdletBinding()]

    param (
        [Parameter(Position = 0)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Installer = "D:\Software\vs_community.exe"
    )

    . $Installer `
        --includeRecommended `
        --add "Microsoft.VisualStudio.Workload.Azure" `
            --remove "Microsoft.Component.Azure.DataLake.Tools" `
            --remove "Microsoft.VisualStudio.Component.Azure.MobileAppsSdk" `
        --add "Microsoft.VisualStudio.Workload.ManagedDesktop" `
            --remove "Microsoft.ComponentGroup.Blend" `
        --add "Microsoft.VisualStudio.Workload.NetCoreTools" `
        --add "Microsoft.VisualStudio.Workload.NetWeb" `
            --remove "Microsoft.VisualStudio.Component.Wcf.Tooling" `
        --add "Microsoft.Net.Component.4.7.2.SDK" `
        --add "Microsoft.Net.Component.4.7.2.TargetingPack"
}

