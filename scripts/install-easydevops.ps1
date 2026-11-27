# install-easydevops.ps1
# Installeert .NET SDK 8 en Git, clonet de EasyDevOps-repo en start de frontend.
# Gebruik (als Administrator): powershell -ExecutionPolicy Bypass -File install-easydevops.ps1

$ProgressPreference = 'SilentlyContinue'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$RepoUrl    = 'https://github.com/588734/EasyDevOps.git'
$InstallDir = 'C:\EasyDevOps'
$DotnetDir  = 'C:\Program Files\dotnet'
$GitDir     = 'C:\Program Files\Git\cmd'
$TempDir    = Join-Path $env:TEMP 'easydevops-install'
New-Item -ItemType Directory -Force -Path $TempDir | Out-Null

# 1. .NET SDK 8
Write-Host '[1/4] .NET SDK 8 installeren...'
if ((Test-Path "$DotnetDir\dotnet.exe") -and (& "$DotnetDir\dotnet.exe" --list-sdks | Select-String '^8\.')) {
    Write-Host '      .NET SDK 8 is al aanwezig.'
} else {
    $DotnetScript = Join-Path $TempDir 'dotnet-install.ps1'
    Invoke-WebRequest 'https://dot.net/v1/dotnet-install.ps1' -OutFile $DotnetScript -UseBasicParsing -ErrorAction Stop
    & $DotnetScript -Channel 8.0 -InstallDir $DotnetDir
}

# 2. Git
Write-Host '[2/4] Git installeren...'
if (Test-Path "$GitDir\git.exe") {
    Write-Host '      Git is al aanwezig.'
} else {
    $Release   = Invoke-RestMethod 'https://api.github.com/repos/git-for-windows/git/releases/latest' -UseBasicParsing -ErrorAction Stop
    $Asset     = $Release.assets | Where-Object { $_.name -match '^Git-.*-64-bit\.exe$' } | Select-Object -First 1
    $Installer = Join-Path $TempDir $Asset.name
    Invoke-WebRequest $Asset.browser_download_url -OutFile $Installer -UseBasicParsing -ErrorAction Stop
    Start-Process $Installer -ArgumentList '/VERYSILENT', '/NORESTART' -Wait
}

# PATH bijwerken (machine + huidige sessie), zodat dotnet en git direct werken
foreach ($Dir in @($DotnetDir, $GitDir)) {
    $MachinePath = [Environment]::GetEnvironmentVariable('Path', 'Machine')
    if ($MachinePath -notlike "*$Dir*") {
        [Environment]::SetEnvironmentVariable('Path', "$MachinePath;$Dir", 'Machine')
    }
    if ($env:Path -notlike "*$Dir*") { $env:Path += ";$Dir" }
}

# 3. Repository clonen (of bijwerken als hij er al staat)
Write-Host '[3/4] Repository clonen...'
if (Test-Path "$InstallDir\.git") {
    git -C $InstallDir pull
} else {
    git clone $RepoUrl $InstallDir
}

# 4. Frontend starten
Write-Host '[4/4] EasyDevOps starten...'
dotnet run --project "$InstallDir\frontend\EasyDevOps\EasyDevOps.csproj"
