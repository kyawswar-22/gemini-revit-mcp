$host.UI.RawUI.WindowTitle = 'Gemini-Revit proxy (keep open)'
$env:Path = [Environment]::GetEnvironmentVariable('Path','User') + ';' + [Environment]::GetEnvironmentVariable('Path','Machine')
while ($true) {
    Write-Host "Gemini-Revit proxy running -> http://localhost:3006/mcp   (close this window to stop)" -ForegroundColor Cyan
    npx -y @srbhptl39/mcp-superassistant-proxy@latest --config "C:\WinnerTools\superassistant\config.json" --outputTransport streamableHttp
    Write-Host "Proxy stopped - restarting in 3 seconds..." -ForegroundColor Yellow
    Start-Sleep -Seconds 3
}
