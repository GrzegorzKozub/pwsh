function Convert-SvgToIco {
    [CmdletBinding()]

    param (
        [Parameter(Position = 0, Mandatory = $true)]
        [ValidateScript({ Test-Path $_ })]
        [string]
        $Svg,

        [Parameter(Position = 1, Mandatory = $true)]
        [ValidateScript({ Test-Path ([IO.Path]::GetDirectoryName($_)) })]
        [string]
        $Ico
    )

    $icoDir = [IO.Path]::GetDirectoryName($Ico)
    $icoFile = [IO.Path]::GetFileNameWithoutExtension($Ico)

    foreach ($size in 256, 128, 64, 48, 32, 24, 22, 16) {
        rsvg-convert `
            --width $size `
            --height $size `
            --output (Join-Path $icoDir "$icoFile-$size.png") `
            $Svg
    }

    $pngPattern = "$icoDir/$icoFile-*.png"
    D:\Apps\ImageMagick\convert $pngPattern $Ico
    Remove-Item -Path $pngPattern
}

Set-Alias svgtoico Convert-SvgToIco

