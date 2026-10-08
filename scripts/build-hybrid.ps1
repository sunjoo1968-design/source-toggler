param(
    [Parameter(Mandatory=$true)][string]$ObsSourceDir,
    [Parameter(Mandatory=$true)][string]$ObsImportDir,
    [string]$ObsInstallDir = 'C:/Program Files/obs-studio',
    [switch]$PrepareTestRuntime
)
$ErrorActionPreference = 'Stop'
$hybridRoot = Split-Path $PSScriptRoot -Parent
$hybridLua = Join-Path $PSScriptRoot 'camera-mix-hybrid.lua'
$hybridText = Get-Content -LiteralPath $hybridLua -Raw
if ($hybridText -notmatch "local VERSION, AUTHOR = '([^']+)'") { throw 'Lua version not found' }
$hybridVersion = $Matches[1]
$hybridBuild = Join-Path $hybridRoot '.local/hybrid/build'
cmake -S (Join-Path $hybridRoot 'native/camera-mix-hybrid') -B $hybridBuild -G 'Visual Studio 17 2022' -A x64 "-DOBS_SOURCE_DIR=$ObsSourceDir" "-DOBS_IMPORT_DIR=$ObsImportDir"
if ($LASTEXITCODE -ne 0) { throw 'CMake configure failed' }
cmake --build $hybridBuild --config Release
if ($LASTEXITCODE -ne 0) { throw 'CMake build failed' }
$hybridPackage = Join-Path $hybridRoot "release/camera-mix-hybrid-$hybridVersion"
New-Item -ItemType Directory -Force "$hybridPackage/obs-plugins/64bit", "$hybridPackage/scripts", "$hybridPackage/native/camera-mix-hybrid", "$hybridPackage/vendor", "$hybridPackage/docs", "$hybridPackage/tests/fixtures" | Out-Null
Copy-Item -LiteralPath "$hybridBuild/Release/camera-mix-hybrid.dll" -Destination "$hybridPackage/obs-plugins/64bit" -Force
Copy-Item -LiteralPath $hybridLua -Destination "$hybridPackage/scripts" -Force
Copy-Item -LiteralPath (Join-Path $hybridRoot 'native/camera-mix-hybrid/output.cpp'), (Join-Path $hybridRoot 'native/camera-mix-hybrid/CMakeLists.txt'), (Join-Path $hybridRoot 'native/camera-mix-hybrid/LICENSE') -Destination "$hybridPackage/native/camera-mix-hybrid" -Force
Copy-Item -LiteralPath (Join-Path $hybridRoot 'docs/HYBRID_GUIDE.md') -Destination "$hybridPackage/README.md" -Force
Copy-Item -LiteralPath (Join-Path $hybridRoot 'docs/HYBRID_GUIDE.md') -Destination "$hybridPackage/docs/HYBRID_GUIDE.md" -Force
Copy-Item -LiteralPath (Join-Path $hybridRoot 'vendor/LICENSE-OBS'), (Join-Path $hybridRoot 'vendor/LICENSE-source-switcher') -Destination "$hybridPackage/vendor" -Force
foreach ($hybridTest in @('native-groups.py','native-hybrid.py','portable-hybrid.py','close-hybrid-obs.py')) {
    Copy-Item -LiteralPath (Join-Path $hybridRoot "tests/$hybridTest") -Destination "$hybridPackage/tests" -Force
}
Copy-Item -LiteralPath (Join-Path $hybridRoot 'tests/fixtures/hybrid-smoke.lua') -Destination "$hybridPackage/tests/fixtures" -Force
Copy-Item -LiteralPath $PSCommandPath -Destination "$hybridPackage/scripts" -Force
$hybridManifest = Get-ChildItem -LiteralPath $hybridPackage -File -Recurse | Where-Object Name -ne 'SHA256SUMS.txt' | ForEach-Object {
    $hybridRelative = $_.FullName.Substring($hybridPackage.Length + 1).Replace('\','/')
    "$( (Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash.ToLower() )  $hybridRelative"
}
$hybridManifest | Set-Content -LiteralPath "$hybridPackage/SHA256SUMS.txt" -Encoding utf8
Compress-Archive -Path "$hybridPackage/*" -DestinationPath "$hybridPackage.zip" -Force
if ($PrepareTestRuntime) {
    $hybridSandbox = Join-Path $hybridRoot '.local/hybrid/obs-shutdown-sandbox'
    New-Item -ItemType Directory -Force "$hybridSandbox/bin", "$hybridSandbox/obs-plugins/64bit", "$hybridSandbox/data/obs-plugins" | Out-Null
    Copy-Item -LiteralPath "$ObsInstallDir/bin/64bit" -Destination "$hybridSandbox/bin" -Recurse -Force
    Copy-Item -LiteralPath "$ObsInstallDir/data/obs-studio" -Destination "$hybridSandbox/data" -Recurse -Force
    Copy-Item -LiteralPath "$ObsInstallDir/data/libobs" -Destination "$hybridSandbox/data" -Recurse -Force
    Copy-Item -LiteralPath "$ObsInstallDir/data/obs-scripting" -Destination "$hybridSandbox/data" -Recurse -Force
    foreach ($hybridPlugin in @('obs-websocket','obs-transitions','rtmp-services','obs-x264','obs-ffmpeg','obs-outputs','frontend-tools','image-source','source-switcher','obs-filters','obs-text')) {
        Copy-Item -LiteralPath "$ObsInstallDir/obs-plugins/64bit/$hybridPlugin.dll" -Destination "$hybridSandbox/obs-plugins/64bit" -Force
        if (Test-Path -LiteralPath "$ObsInstallDir/data/obs-plugins/$hybridPlugin") {
            Copy-Item -LiteralPath "$ObsInstallDir/data/obs-plugins/$hybridPlugin" -Destination "$hybridSandbox/data/obs-plugins" -Recurse -Force
        }
    }
    Copy-Item -LiteralPath "$hybridBuild/Release/camera-mix-hybrid.dll" -Destination "$hybridSandbox/obs-plugins/64bit" -Force
    Set-Content -LiteralPath "$hybridSandbox/portable_mode.txt" -Value ''
}
Write-Output "Camera MIX Hybrid $hybridVersion / SunjooAn — $hybridPackage.zip"
if (Test-Path -LiteralPath "$PSScriptRoot/package-obs-link.ps1") {
    & "$PSScriptRoot/package-obs-link.ps1"
}
