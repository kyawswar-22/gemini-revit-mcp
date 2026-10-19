# Gemini ↔ Revit — PowerShell-Only Setup (step by step)

*For a laptop that has only Revit + pyRevit — everything else is installed by pasting into PowerShell. Prefer one command? Use `install.ps1` (see the [README](../README.md)).*


## How to use this page

1. Open Windows PowerShell: Start -> type PowerShell -> Enter. Use the same window for all steps.
2. Do the steps in order, STEP 1 -> STEP 12.
3. Each step has one grey code box. Copy the whole box (GitHub shows a copy button at its top-right).
4. In PowerShell: Right-click (pastes) -> press Enter.
5. Wait for the green STEP X OK line before going to the next step.
6. The ✅ *You should see* line is not a command — don't copy it.
7. Every box is safe to paste again if something failed.

Before you start, the laptop needs: Windows 10/11 · Revit · pyRevit · internet. Nothing else.


What these steps install / create:
| Step | Thing | Where |
|---|---|---|
| 2 | uv (runs Python - it downloads Python by itself, no Python install needed) | %USERPROFILE%\.local\bin |
| 3 | Node.js LTS (runs the proxy) | Program Files |
| 6 | pyRevit MCP extension | %APPDATA%\pyRevit\Extensions |
| 7-9 | Winner Tools files + Desktop shortcut | C:\WinnerTools, Desktop |
| 12 | Google Chrome (only if missing) | Program Files |

Nothing is deleted. Git, Python, Visual Studio etc. are not needed.


## STEP 1 — Prepare PowerShell + create the Winner Tools folder

Needed on a new laptop: turns on modern internet security (TLS 1.2) for downloads in this window.

**▶ COPY STEP 1**
```powershell
[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
$env:Path = [Environment]::GetEnvironmentVariable('Path','User') + ';' + [Environment]::GetEnvironmentVariable('Path','Machine')
New-Item -ItemType Directory -Force -Path 'C:\WinnerTools\superassistant' | Out-Null
Write-Host ("STEP 1 OK - folder ready, PowerShell " + $PSVersionTable.PSVersion) -ForegroundColor Green
```
> ✅ You should see: STEP 1 OK - folder ready, PowerShell 5.1...


## STEP 2 — Install uv (Python runner)

**▶ COPY STEP 2**
```powershell
$uv = "$env:USERPROFILE\.local\bin\uv.exe"
if (-not (Test-Path $uv)) { powershell -NoProfile -ExecutionPolicy ByPass -c "irm https://astral.sh/uv/install.ps1 | iex" }
if (Test-Path $uv) { Write-Host ("STEP 2 OK - " + (& $uv --version)) -ForegroundColor Green } else { Write-Host 'STEP 2 FAILED - paste this box again' -ForegroundColor Red }
```
> ✅ You should see: STEP 2 OK - uv 0.x.x


## STEP 3 — Install Node.js LTS

Windows asks "Do you want to allow this app to make changes?" -> click Yes. Uses winget; if the laptop has no winget, it downloads the official installer from nodejs.org instead.

**▶ COPY STEP 3**
```powershell
$env:Path = [Environment]::GetEnvironmentVariable('Path','User') + ';' + [Environment]::GetEnvironmentVariable('Path','Machine')
if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
  if (Get-Command winget -ErrorAction SilentlyContinue) {
    winget install -e --id OpenJS.NodeJS.LTS --accept-source-agreements --accept-package-agreements
  } else {
    $v   = (Invoke-RestMethod 'https://nodejs.org/dist/index.json' | Where-Object { $_.lts } | Select-Object -First 1).version
    $msi = Join-Path $env:TEMP "node-$v-x64.msi"
    Write-Host "Downloading Node.js $v ..."
    Invoke-WebRequest -UseBasicParsing "https://nodejs.org/dist/$v/node-$v-x64.msi" -OutFile $msi
    Start-Process msiexec.exe -ArgumentList '/i',"`"$msi`"",'/passive','/norestart' -Verb RunAs -Wait
  }
}
$env:Path = [Environment]::GetEnvironmentVariable('Path','User') + ';' + [Environment]::GetEnvironmentVariable('Path','Machine')
if (Get-Command node -ErrorAction SilentlyContinue) { Write-Host ("STEP 3 OK - node " + (node --version)) -ForegroundColor Green } else { Write-Host 'STEP 3 - close PowerShell, open it again, paste STEP 1, then this box again' -ForegroundColor Yellow }
```
> ✅ You should see: STEP 3 OK - node v22.x.x (any version number)


## STEP 4 — Check pyRevit (already installed)

Finds pyRevit's command-line tool and remembers where it is for STEP 5.

**▶ COPY STEP 4**
```powershell
$env:Path = [Environment]::GetEnvironmentVariable('Path','User') + ';' + [Environment]::GetEnvironmentVariable('Path','Machine')
$pr = (Get-Command pyrevit -ErrorAction SilentlyContinue).Source
if (-not $pr) { $pr = @("$env:APPDATA\pyRevit-Master\bin\pyrevit.exe", "$env:ProgramFiles\pyRevit-Master\bin\pyrevit.exe", "$env:ProgramFiles\pyRevit CLI\pyrevit.exe") | Where-Object { Test-Path $_ } | Select-Object -First 1 }
if ($pr) { Write-Host ("STEP 4 OK - pyRevit found: $pr  (" + (& $pr --version) + ")") -ForegroundColor Green } else { Write-Host 'STEP 4 - pyRevit command not found. That is OK: do STEP 5 by hand in Revit (see note).' -ForegroundColor Yellow }
```
> ✅ You should see: STEP 4 OK - pyRevit found: ...


## STEP 5 — Turn on pyRevit Routes (port 48884)

Uses the pyRevit found in STEP 4. Paste STEP 4 first if you opened a new window.

**▶ COPY STEP 5**
```powershell
if ($pr) { & $pr configs routes enable }
if ($pr -and $LASTEXITCODE -eq 0) { Write-Host 'STEP 5 OK - Routes enabled (restart Revit if it is open)' -ForegroundColor Green } else { Write-Host 'STEP 5 - do it in Revit: pyRevit tab > Settings > Routes > ON > Save Settings and Reload' -ForegroundColor Yellow }
```
> ✅ You should see: STEP 5 OK - or the yellow line telling you to switch Routes ON in Revit (takes 10 seconds)


## STEP 6 — Install the pyRevit MCP extension

**▶ COPY STEP 6**
```powershell
$ext = "$env:APPDATA\pyRevit\Extensions\mcp-server-for-revit-python.extension"
if (Test-Path "$ext\main.py") { Write-Host 'STEP 6 OK - already installed' -ForegroundColor Green } else {
  New-Item -ItemType Directory -Force "$env:APPDATA\pyRevit\Extensions" | Out-Null
  $tmp = Join-Path $env:TEMP ('pyrevit-mcp-' + [guid]::NewGuid().ToString('N')); New-Item -ItemType Directory -Force $tmp | Out-Null
  $ok = $false
  foreach ($br in 'main','master') { try { Invoke-WebRequest -UseBasicParsing "https://github.com/mcp-servers-for-revit/mcp-server-for-revit-python/archive/refs/heads/$br.zip" -OutFile "$tmp\ext.zip"; $ok = $true; break } catch {} }
  if ($ok) { Expand-Archive "$tmp\ext.zip" $tmp -Force; if (-not (Test-Path $ext)) { Move-Item (Get-ChildItem $tmp -Directory | Select-Object -First 1).FullName $ext } }
  if (Test-Path "$ext\main.py") { Write-Host 'STEP 6 OK - extension installed' -ForegroundColor Green } else { Write-Host 'STEP 6 FAILED - paste this box again' -ForegroundColor Red }
}
```
> ✅ You should see: STEP 6 OK


## STEP 7 — Download the bridge file

Downloads `src/pyrevit_bridge.py` from this repo (release v1.0.0).

**▶ COPY STEP 7**
```powershell
[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
Invoke-WebRequest -UseBasicParsing 'https://raw.githubusercontent.com/kyawswar-22/gemini-revit-mcp/v1.0.0/src/pyrevit_bridge.py' -OutFile 'C:\WinnerTools\pyrevit_bridge.py'
if (Test-Path 'C:\WinnerTools\pyrevit_bridge.py') { Write-Host 'STEP 7 OK - pyrevit_bridge.py created' -ForegroundColor Green }
```
> ✅ You should see: STEP 7 OK


## STEP 8 — Create the proxy config

**▶ COPY STEP 8**
```powershell
$uv  = "$env:USERPROFILE\.local\bin\uv.exe"
$cfg = [ordered]@{ mcpServers = [ordered]@{ 'pyrevit' = [ordered]@{ command = $uv; args = @('run','--quiet','--with','mcp[cli]<2','python','C:\WinnerTools\pyrevit_bridge.py') } } }
[IO.File]::WriteAllText('C:\WinnerTools\superassistant\config.json', ($cfg | ConvertTo-Json -Depth 6), (New-Object System.Text.UTF8Encoding($false)))
Get-Content 'C:\WinnerTools\superassistant\config.json'
Write-Host 'STEP 8 OK - config.json created' -ForegroundColor Green
```
> ✅ You should see: the config text, then STEP 8 OK


## STEP 9 — Create the start script + Desktop shortcut

**▶ COPY STEP 9**
```powershell
[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
Invoke-WebRequest -UseBasicParsing 'https://raw.githubusercontent.com/kyawswar-22/gemini-revit-mcp/v1.0.0/src/start-gemini-proxy.ps1' -OutFile 'C:\WinnerTools\start-gemini-proxy.ps1'
$sh = (New-Object -ComObject WScript.Shell).CreateShortcut((Join-Path ([Environment]::GetFolderPath('Desktop')) 'Start Gemini-Revit.lnk'))
$sh.TargetPath = 'powershell.exe'; $sh.Arguments = '-NoExit -ExecutionPolicy Bypass -File "C:\WinnerTools\start-gemini-proxy.ps1"'; $sh.WorkingDirectory = 'C:\WinnerTools'; $sh.Save()
Write-Host 'STEP 9 OK - start script + Desktop shortcut "Start Gemini-Revit" created' -ForegroundColor Green
```
> ✅ You should see: STEP 9 OK and a new Start Gemini-Revit icon on the Desktop


## STEP 10 — Final check (all parts)

Open Revit and a model first (so the Revit test can answer).

**▶ COPY STEP 10**
```powershell
$env:Path = [Environment]::GetEnvironmentVariable('Path','User') + ';' + [Environment]::GetEnvironmentVariable('Path','Machine')
function T($n,$c){ if ($c) { Write-Host "  [OK]   $n" -ForegroundColor Green } else { Write-Host "  [FAIL] $n" -ForegroundColor Red } }
T 'uv'                    (Test-Path "$env:USERPROFILE\.local\bin\uv.exe")
T 'Node.js'               ([bool](Get-Command node -ErrorAction SilentlyContinue))
T 'pyRevit'               ((Test-Path "$env:APPDATA\pyRevit-Master") -or (Test-Path "$env:ProgramFiles\pyRevit-Master") -or [bool](Get-Command pyrevit -ErrorAction SilentlyContinue))
T 'pyRevit MCP extension' (Test-Path "$env:APPDATA\pyRevit\Extensions\mcp-server-for-revit-python.extension\main.py")
T 'Bridge file'           (Test-Path 'C:\WinnerTools\pyrevit_bridge.py')
T 'Proxy config'          (Test-Path 'C:\WinnerTools\superassistant\config.json')
T 'Start script'          (Test-Path 'C:\WinnerTools\start-gemini-proxy.ps1')
$r = $false; try { Invoke-RestMethod 'http://localhost:48884/revit_mcp/status/' -TimeoutSec 5 | Out-Null; $r = $true } catch {}
T 'Revit answering on 48884 (Revit + model must be open)' $r
```
> ✅ You should see: 8 green [OK] lines. Red [FAIL] -> paste that step's box again. If only the last line fails -> open Revit + a model, check Routes is ON, restart Revit, paste STEP 10 again.


## STEP 11 — Start the proxy

From now on you can also just double-click Start Gemini-Revit on the Desktop.

**▶ COPY STEP 11**
```powershell
Start-Process powershell -ArgumentList '-NoExit','-ExecutionPolicy','Bypass','-File','C:\WinnerTools\start-gemini-proxy.ps1'
```
> ✅ You should see: A new window opens: Gemini-Revit proxy running -> http://localhost:3006/mcp. Keep that window open.


## STEP 12 — Open Chrome: extension page + Gemini

Installs Google Chrome first if the laptop doesn't have it.

**▶ COPY STEP 12**
```powershell
$chrome = @("$env:ProgramFiles\Google\Chrome\Application\chrome.exe", "${env:ProgramFiles(x86)}\Google\Chrome\Application\chrome.exe", "$env:LOCALAPPDATA\Google\Chrome\Application\chrome.exe") | Where-Object { Test-Path $_ } | Select-Object -First 1
if (-not $chrome -and (Get-Command winget -ErrorAction SilentlyContinue)) { winget install -e --id Google.Chrome --accept-source-agreements --accept-package-agreements
  $chrome = @("$env:ProgramFiles\Google\Chrome\Application\chrome.exe", "${env:ProgramFiles(x86)}\Google\Chrome\Application\chrome.exe", "$env:LOCALAPPDATA\Google\Chrome\Application\chrome.exe") | Where-Object { Test-Path $_ } | Select-Object -First 1 }
if ($chrome) { Start-Process $chrome 'https://chromewebstore.google.com/search/MCP%20SuperAssistant'; Start-Process $chrome 'https://gemini.google.com'; Write-Host 'STEP 12 OK - Chrome opened' -ForegroundColor Green } else { Write-Host 'STEP 12 - install Chrome from https://www.google.com/chrome then open gemini.google.com' -ForegroundColor Yellow }
```
> ✅ You should see: Chrome opens two tabs. Then follow In Chrome below.


## In Chrome (last part, one time)

1. On the Chrome Web Store tab: MCP SuperAssistant -> Add to Chrome -> pin it.
2. On the Gemini tab: click the MCP button (or the extension icon) -> sidebar opens.
3. Server settings -> Streamable HTTP -> http://localhost:3006/mcp -> Connect -> Server Connected.
4. Available Tools -> Enable All -> Save Changes (22 tools).
5. Settings -> keep Auto Execute OFF.

Test: Gemini -> New chat -> sidebar Instructions -> Insert -> at the end type
Use wt_count_by_category with category OST_MechanicalControlDevices. -> send -> Show Raw Info -> Run -> Insert the result -> Summarize as a table.


## Every day after this

1. Open Revit + model.
2. Double-click Start Gemini-Revit on the Desktop (keep the window open).
3. Gemini -> New chat -> Insert instructions -> ask -> Show Raw Info -> Run -> Insert result.


## Extra boxes (only when needed)

**▶ COPY - Safe mode ON (read-only: Gemini can't change the model)**
```powershell
(Get-Content C:\WinnerTools\pyrevit_bridge.py -Raw).Replace('READ_ONLY = False','READ_ONLY = True') | Set-Content C:\WinnerTools\pyrevit_bridge.py -NoNewline -Encoding ASCII; Write-Host 'Safe mode ON - restart the proxy window' -ForegroundColor Green
```

**▶ COPY - Safe mode OFF**
```powershell
(Get-Content C:\WinnerTools\pyrevit_bridge.py -Raw).Replace('READ_ONLY = True','READ_ONLY = False') | Set-Content C:\WinnerTools\pyrevit_bridge.py -NoNewline -Encoding ASCII; Write-Host 'Safe mode OFF - restart the proxy window' -ForegroundColor Green
```

**▶ COPY - Port 3006 busy / stop all proxies**
```powershell
Get-NetTCPConnection -LocalPort 3006 -State Listen -ErrorAction SilentlyContinue | ForEach-Object { Stop-Process -Id $_.OwningProcess -Force }; Write-Host 'All proxies stopped - start again with the Desktop icon' -ForegroundColor Green
```

**▶ COPY - Uninstall (removes only the Winner Tools files + shortcut)**
```powershell
Remove-Item 'C:\WinnerTools\pyrevit_bridge.py','C:\WinnerTools\pyrevit_bridge.py.bak','C:\WinnerTools\start-gemini-proxy.ps1' -ErrorAction SilentlyContinue; Remove-Item 'C:\WinnerTools\superassistant' -Recurse -ErrorAction SilentlyContinue; Remove-Item (Join-Path ([Environment]::GetFolderPath('Desktop')) 'Start Gemini-Revit.lnk') -ErrorAction SilentlyContinue; Write-Host 'Removed' -ForegroundColor Green
```


## Problems

| You see | Do this |
|---|---|
| running scripts is disabled on this system | Only happens with .ps1 files - the Desktop icon already uses -ExecutionPolicy Bypass. Use the icon. |
| Red/yellow text after STEP 2 or 3 | Close PowerShell -> open again -> paste STEP 1 -> paste the failed step again |
| STEP 3 still fails | Install Node.js LTS by hand from <https://nodejs.org> -> close and reopen PowerShell -> STEP 1 -> STEP 3 |
| Invoke-WebRequest : The request was aborted... SSL/TLS | Paste STEP 1 again (it turns on TLS 1.2) |
| Company proxy / firewall blocks downloads | Ask IT, or try on a home network |
| STEP 10: only Revit answering fails | Open Revit + model; pyRevit tab -> Settings -> Routes ON; restart Revit |
| Gemini Disconnected | Start Start Gemini-Revit, click reconnect in the sidebar |
| Gemini writes a script, no tool box | New chat -> Insert instructions -> ask again |

Company laptop? Ask IT before installing software.
