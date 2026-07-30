<#
.SYNOPSIS
  Pulls Play Store screenshots straight off a connected phone.

.DESCRIPTION
  Play wants 2-8 phone screenshots, PNG or JPEG, each side 320-3840px, and it
  rejects anything with a weird aspect. A raw screencap from a modern phone
  already satisfies all of that, so this does not resize or reframe - it just
  grabs the current screen, names it after the shot list in STORE_LISTING.md,
  and checks the dimensions before you find out from a rejected listing.

  Usage, one shot at a time: navigate the phone to the screen you want, then

      pwsh tool/capture_screenshots.ps1 -Shot 1

  Or run without -Shot to capture whatever is on screen right now into the
  next free slot.

      pwsh tool/capture_screenshots.ps1 -Install   # sideload the release APK first

  Output lands in store/screenshots/.
#>
[CmdletBinding()]
param(
  [ValidateRange(1, 8)]
  [int]$Shot = 0,
  [switch]$Install,
  [switch]$List
)

$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSScriptRoot
$adb = 'C:\Users\ADMIN\dev\android-sdk\platform-tools\adb.exe'
$outDir = Join-Path $root 'store\screenshots'
$apk = Join-Path $root 'build\app\outputs\flutter-apk\app-release.apk'

# Mirrors the capture list in STORE_LISTING.md. Order is the order Play shows
# them in, so shot 1 is the one that sells the app.
$shots = @(
  '01-map-home',
  '02-restaurant-details',
  '03-taster-profile',
  '04-biteswipe',
  '05-discover-feed',
  '06-list-with-map',
  '07-your-profile',
  '08-spare'
)

if ($List) {
  for ($i = 0; $i -lt $shots.Count; $i++) {
    Write-Output ("{0}  {1}" -f ($i + 1), $shots[$i])
  }
  return
}

if (-not (Test-Path $adb)) { throw "adb not found at $adb" }

$attached = & $adb devices | Select-Object -Skip 1 | Where-Object { $_ -match '\tdevice$' }
if (-not $attached) {
  throw 'No device. Plug the phone in, unlock it, and accept the USB debugging prompt.'
}

if ($Install) {
  if (-not (Test-Path $apk)) { throw "No APK at $apk. Run: flutter build apk --release" }
  Write-Output 'Installing release APK...'
  & $adb install -r $apk
}

New-Item -ItemType Directory -Force $outDir | Out-Null

if ($Shot -eq 0) {
  for ($i = 0; $i -lt $shots.Count; $i++) {
    if (-not (Test-Path (Join-Path $outDir "$($shots[$i]).png"))) { $Shot = $i + 1; break }
  }
  if ($Shot -eq 0) { throw 'All 8 slots are filled. Pass -Shot N to overwrite one.' }
}

$name = $shots[$Shot - 1]
$dest = Join-Path $outDir "$name.png"

# exec-out keeps the PNG bytes intact; a plain `adb shell screencap` mangles
# them on Windows by translating line endings.
& $adb exec-out screencap -p > $dest

if (-not (Test-Path $dest) -or (Get-Item $dest).Length -lt 1024) {
  throw 'Capture failed or came back empty. Is the screen on and unlocked?'
}

Add-Type -AssemblyName System.Drawing
$img = [System.Drawing.Image]::FromFile($dest)
$w = $img.Width; $h = $img.Height
$img.Dispose()

$sizeKb = [math]::Round((Get-Item $dest).Length / 1KB)
Write-Output "Saved $name.png  ${w}x${h}  ${sizeKb}KB"

$problems = @()
if ($w -lt 320 -or $h -lt 320) { $problems += 'a side is under Play''s 320px minimum' }
if ($w -gt 3840 -or $h -gt 3840) { $problems += 'a side is over Play''s 3840px maximum' }
if ((Get-Item $dest).Length -gt 8MB) { $problems += 'over Play''s 8MB limit' }
$ratio = [math]::Round([math]::Max($w, $h) / [math]::Min($w, $h), 2)
if ($ratio -gt 2.4) { $problems += "aspect ratio $ratio`:1 is taller than Play accepts" }

if ($problems) {
  Write-Warning ("Play will reject this: " + ($problems -join '; '))
} else {
  Write-Output 'Meets Play''s phone screenshot requirements.'
}

$done = (Get-ChildItem $outDir -Filter '*.png' -ErrorAction SilentlyContinue).Count
Write-Output "$done of 8 captured (Play needs at least 2)."
