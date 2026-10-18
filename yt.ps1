$yt = "D:\\Music\\YouTube"
if (!(Test-Path $yt)) { mkdir $yt | Out-Null }
Remove-Item "$yt\*"
Push-Location $yt

$tmp = [System.IO.Path]::GetTempFileName()

yt-dlp `
  --format bestaudio `
  --extract-audio --audio-format flac --audio-quality 0 `
  --parse-metadata "title:%(artist)s - %(title)s" `
  --parse-metadata "%(album|YouTube)s:%(album)s" `
  --parse-metadata ":(?P<meta_synopsis>)" `
  --embed-metadata `
  --convert-thumbnail png --write-thumbnail `
  --no-write-playlist-metafiles `
  --paths $yt --output "%(artist)s - %(title)s.%(ext)s" --windows-filenames `
  --print-to-file filename $tmp `
  "https://music.youtube.com/browse/VLPLm6VwE4tgUkXEcczHuW9xiwGJwHvq69ri"
  # "https://music.youtube.com/playlist?list=LM"

(Get-Content $tmp) -replace "$yt\\", "" -replace "\.webm", "" | Set-Content $tmp

foreach ($title in (Get-Content $tmp)) {

  Move-Item "$title.png" original.png
  Move-Item "$title.flac" original.flac

  ffmpeg `
    -i original.png `
    -vf "crop='min(in_w\,in_h)':'min(in_w\,in_h)':(in_w-min(in_w\,in_h))/2:(in_h-min(in_w\,in_h))/2,scale=1280:1280" `
    square.png

  ffmpeg `
    -i original.flac -i square.png `
    -map 0 -map 1 -c copy -disposition:v attached_pic `
    "$title.flac"

  Remove-Item original.flac, original.png, square.png
}

Remove-Item $tmp

Pop-Location

