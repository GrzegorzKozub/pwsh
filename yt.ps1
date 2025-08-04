$yt = "D:\\Music\\YouTube"
if (!(Test-Path -Path $yt)) { mkdir -Path $yt | Out-Null }
Remove-Item -Path "$yt\*"
Push-Location -Path $yt

$tmp = [System.IO.Path]::GetTempFileName()

yt-dlp `
  --format bestaudio `
  --extract-audio --audio-format flac --audio-quality 0 `
  --parse-metadata "title:%(artist)s - %(title)s" `
  --parse-metadata "%(album|YouTube)s:%(album)s" `
  --embed-metadata `
  --convert-thumbnail png --write-thumbnail `
  --no-write-playlist-metafiles `
  --paths $yt --output "%(artist)s - %(title)s.%(ext)s" --windows-filenames `
  --print-to-file filename $tmp `
  "https://music.youtube.com/browse/VLPLm6VwE4tgUkXEcczHuW9xiwGJwHvq69ri"

(Get-Content -Path $tmp) -replace "$yt\\", "" -replace "\.webm", "" | Set-Content -Path $tmp

foreach ($title in (Get-Content -Path $tmp)) {

  Move-Item -Path "$title.png" original.png
  Move-Item -Path "$title.flac" original.flac

  ffmpeg `
    -i original.png `
    -vf "crop='min(in_w\,in_h)':'min(in_w\,in_h)':(in_w-min(in_w\,in_h))/2:(in_h-min(in_w\,in_h))/2,scale=1280:1280" `
    square.png

  ffmpeg `
    -i original.flac -i square.png `
    -map 0 -map 1 -c copy -disposition:v attached_pic `
    "$title.flac"

  Remove-Item -Path original.flac, original.png, square.png
}

Remove-Item -Path $tmp

Pop-Location

