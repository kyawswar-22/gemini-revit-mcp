# ==========================================================================
#  install.ps1  -  gemini-revit-mcp  (Winner Tools)
#  Connect Gemini web chat -> Revit (pyRevit MCP) via MCP SuperAssistant
#
#  Run from a downloaded copy of the repo:
#      powershell -ExecutionPolicy Bypass -File .\install.ps1
#  or in one line (downloads the files of the pinned release below):
#      irm https://raw.githubusercontent.com/kyawswar-22/gemini-revit-mcp/v1.0.0/install.ps1 | iex
#
#  Safe to run more than once. Creates only:
#    C:\WinnerTools\pyrevit_bridge.py          (old copy kept as .bak if it changed)
#    C:\WinnerTools\start-gemini-proxy.ps1
#    C:\WinnerTools\superassistant\config.json
#    Desktop shortcut "Start Gemini-Revit"
#    %APPDATA%\pyRevit\Extensions\mcp-server-for-revit-python.extension (only if missing)
#  It never deletes your other files.
# ==========================================================================
$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12

$Repo = 'kyawswar-22/gemini-revit-mcp'
$Ref  = 'v1.0.0'                                              # release the files are taken from
$Raw  = "https://raw.githubusercontent.com/$Repo/$Ref"

$enc  = New-Object System.Text.UTF8Encoding($false)          # UTF-8 without BOM
$root = 'C:\WinnerTools'
$sa   = Join-Path $root 'superassistant'
function Refresh-Path { $env:Path = [Environment]::GetEnvironmentVariable('Path','User') + ';' + [Environment]::GetEnvironmentVariable('Path','Machine') }
function Ok($m)   { Write-Host "  [OK]   $m" -ForegroundColor Green }
function Warn($m) { Write-Host "  [TODO] $m" -ForegroundColor Yellow }
function Step($m) { Write-Host "`n== $m ==" -ForegroundColor Cyan }

# Copy a file from the local repo when this script runs from a downloaded copy;
# download it from the pinned release when the script was piped in (irm | iex).
function Get-KitFile($rel, $dest) {
    $local = if ($PSScriptRoot) { Join-Path $PSScriptRoot $rel } else { $null }
    $tmp = "$dest.new"
    if ($local -and (Test-Path $local)) { Copy-Item $local $tmp -Force }
    else { Invoke-WebRequest -UseBasicParsing -Uri "$Raw/$($rel -replace '\\','/')" -OutFile $tmp }
    if ((Test-Path $dest) -and ((Get-FileHash $dest).Hash -ne (Get-FileHash $tmp).Hash)) {
        Copy-Item $dest "$dest.bak" -Force                     # keep the user's edits (READ_ONLY, own tools)
    }
    Move-Item $tmp $dest -Force
}

# --- 1. uv -----------------------------------------------------------------
Step '1/6  uv (Python runner)'
$uv = Join-Path $env:USERPROFILE '.local\bin\uv.exe'
if (-not (Test-Path $uv)) {
    Write-Host '  Installing uv...'
    powershell -NoProfile -ExecutionPolicy ByPass -c "irm https://astral.sh/uv/install.ps1 | iex"
    Refresh-Path
}
if (Test-Path $uv) { Ok ("uv " + (& $uv --version)) } else { Warn 'uv install failed - see docs/Full_Guide.md, Troubleshooting' }

# --- 2. Node.js ------------------------------------------------------------
Step '2/6  Node.js LTS'
Refresh-Path
if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
    if (Get-Command winget -ErrorAction SilentlyContinue) {
        Write-Host '  Installing Node.js LTS with winget...'
        winget install -e --id OpenJS.NodeJS.LTS --accept-source-agreements --accept-package-agreements
        Refresh-Path
    }
}
if (Get-Command node -ErrorAction SilentlyContinue) { Ok ("node " + (node --version)) }
else { Warn 'Node.js not found -> install LTS from https://nodejs.org, then run this script again' }

# --- 3. pyRevit + Routes ---------------------------------------------------
Step '3/6  pyRevit'
if (Get-Command pyrevit -ErrorAction SilentlyContinue) {
    Ok 'pyRevit CLI found'
    try { pyrevit configs routes enable | Out-Null; if ($LASTEXITCODE -ne 0) { throw 'x' }; Ok 'pyRevit Routes enabled (restart Revit if it is open)' }
    catch { Warn 'Could not enable Routes automatically -> Revit > pyRevit > Settings > Routes > ON' }
} else {
    Warn 'pyRevit not found -> install pyRevit 7 from https://github.com/pyrevitlabs/pyRevit/releases (close Revit first), then run this script again'
}

# --- 4. pyRevit MCP extension ---------------------------------------------
Step '4/6  pyRevit MCP extension'
$extRoot = Join-Path $env:APPDATA 'pyRevit\Extensions'
$ext     = Join-Path $extRoot 'mcp-server-for-revit-python.extension'
if (Test-Path (Join-Path $ext 'main.py')) {
    Ok 'already installed'
} else {
    New-Item -ItemType Directory -Force -Path $extRoot | Out-Null
    $tmp = Join-Path $env:TEMP ('pyrevit-mcp-' + [guid]::NewGuid().ToString('N'))
    New-Item -ItemType Directory -Force -Path $tmp | Out-Null
    $zip = Join-Path $tmp 'ext.zip'
    $got = $false
    foreach ($br in 'main','master') {
        try {
            Invoke-WebRequest -UseBasicParsing -Uri "https://github.com/mcp-servers-for-revit/mcp-server-for-revit-python/archive/refs/heads/$br.zip" -OutFile $zip
            $got = $true; break
        } catch { }
    }
    if ($got) {
        Expand-Archive -Path $zip -DestinationPath $tmp -Force
        $src = Get-ChildItem $tmp -Directory | Select-Object -First 1
        if (-not (Test-Path $ext)) { Move-Item $src.FullName $ext }
        if (Test-Path (Join-Path $ext 'main.py')) { Ok "installed to $ext  (pyRevit > Reload in Revit)" }
        else { Warn "downloaded, but main.py not found in $ext" }
    } else {
        Warn 'download failed -> get it from https://github.com/mcp-servers-for-revit/mcp-server-for-revit-python and copy it to:'
        Write-Host "         $ext"
    }
}

# --- 5. Bridge files -------------------------------------------------------
Step '5/6  Bridge files'
New-Item -ItemType Directory -Force -Path $sa | Out-Null
try {
    Get-KitFile 'src\pyrevit_bridge.py'     (Join-Path $root 'pyrevit_bridge.py')
    Get-KitFile 'src\start-gemini-proxy.ps1' (Join-Path $root 'start-gemini-proxy.ps1')

    $cfg = [ordered]@{ mcpServers = [ordered]@{ 'pyrevit' = [ordered]@{
        command = $uv
        args    = @('run','--quiet','--with','mcp[cli]<2','python',(Join-Path $root 'pyrevit_bridge.py')) } } }
    [IO.File]::WriteAllText((Join-Path $sa 'config.json'), ($cfg | ConvertTo-Json -Depth 6), $enc)
    Ok "files created in $root"
} catch {
    Warn "could not get the bridge files ($($_.Exception.Message)) -> download the repo as ZIP and run install.ps1 from it"
}

# --- 6. Desktop shortcut ---------------------------------------------------
Step '6/6  Desktop shortcut'
try {
    $lnk = Join-Path ([Environment]::GetFolderPath('Desktop')) 'Start Gemini-Revit.lnk'
    $sh  = (New-Object -ComObject WScript.Shell).CreateShortcut($lnk)
    $sh.TargetPath = 'powershell.exe'
    $sh.Arguments  = '-NoExit -ExecutionPolicy Bypass -File "C:\WinnerTools\start-gemini-proxy.ps1"'
    $sh.WorkingDirectory = $root
    $sh.Save()
    Ok 'Desktop shortcut "Start Gemini-Revit" created'
} catch { Warn 'shortcut not created - start with: powershell -ExecutionPolicy Bypass -File C:\WinnerTools\start-gemini-proxy.ps1' }

Write-Host "`nDONE. Fix any [TODO] lines above, then:" -ForegroundColor Green
Write-Host "  1) Open Revit + a model    2) Double-click 'Start Gemini-Revit' on the Desktop" -ForegroundColor Green
Write-Host "  3) Chrome: install 'MCP SuperAssistant' -> gemini.google.com -> connect to http://localhost:3006/mcp" -ForegroundColor Green
