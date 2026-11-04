$ErrorActionPreference = 'Stop'
$projectRoot = $PSScriptRoot
$stageRoot = Join-Path $projectRoot ('build/submission-' + [guid]::NewGuid().ToString('N'))
$sourceRoot = Join-Path $stageRoot 'TH3'
$outputRoot = Join-Path $projectRoot 'dist'
New-Item -ItemType Directory -Force $sourceRoot, $outputRoot | Out-Null
foreach ($name in @('lib', 'test', 'docs')) {
    Copy-Item -LiteralPath (Join-Path $projectRoot $name) -Destination $sourceRoot -Recurse
}
foreach ($name in @('pubspec.yaml', 'pubspec.lock', 'analysis_options.yaml', 'README.md', '.gitignore', 'package_submission.ps1')) {
    Copy-Item -LiteralPath (Join-Path $projectRoot $name) -Destination $sourceRoot
}
foreach ($relative in @('android/app/src/main/kotlin', 'android/app/src/main/res', 'android/gradle/wrapper')) {
    $destination = Join-Path $sourceRoot $relative
    New-Item -ItemType Directory -Force (Split-Path $destination -Parent) | Out-Null
    Copy-Item -LiteralPath (Join-Path $projectRoot $relative) -Destination $destination -Recurse
}
foreach ($relative in @('android/app/src/main/AndroidManifest.xml', 'android/app/build.gradle.kts', 'android/settings.gradle.kts', 'android/build.gradle.kts', 'android/gradle.properties', 'android/gradlew', 'android/gradlew.bat')) {
    $destination = Join-Path $sourceRoot $relative
    Copy-Item -LiteralPath (Join-Path $projectRoot $relative) -Destination $destination
}
Compress-Archive -LiteralPath $sourceRoot -DestinationPath (Join-Path $outputRoot 'TH3-source.zip') -Force
$apkPath = Join-Path $projectRoot 'build/app/outputs/apk/debug/app-debug.apk'
if (Test-Path -LiteralPath $apkPath) {
    Copy-Item -LiteralPath $apkPath -Destination (Join-Path $outputRoot 'EnglishFlow-TH3-debug.apk')
}
Get-ChildItem -LiteralPath $outputRoot | Select-Object Name, Length
