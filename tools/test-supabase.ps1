param([string]$FlutterRoot = 'C:\flutter_windows_3.41.9-stable\flutter')
$ErrorActionPreference = 'Stop'
Push-Location (Split-Path $PSScriptRoot -Parent)
$testUserId = $null
$adminHeaders = $null
$testResult = 1
try {
  $appSource = Get-Content 'lib/main.dart' -Raw
  $env:LAB7_URL = [regex]::Match($appSource, "url: '([^']+)'").Groups[1].Value
  $env:LAB7_PUBLIC_KEY = [regex]::Match($appSource, "publishableKey: '([^']+)'").Groups[1].Value
  $projectRef = ([uri]$env:LAB7_URL).Host.Split('.')[0]
  $keys = npx --no-install supabase projects api-keys "--remote=$projectRef" --output json | ConvertFrom-Json
  if ($LASTEXITCODE -ne 0) { throw 'No se pudieron consultar las claves del proyecto.' }
  $adminKey = ($keys | Where-Object { $_.id -eq 'service_role' }).api_key
  if (-not $adminKey) { throw 'Falta acceso administrativo para crear y limpiar la cuenta temporal.' }
  $adminHeaders = @{ apikey = $adminKey; Authorization = "Bearer $adminKey" }
  $env:LAB7_EMAIL = 'lab7-check-' + [guid]::NewGuid().ToString('N') + '@example.com'
  $env:LAB7_PASSWORD = [guid]::NewGuid().ToString('N') + 'Aa1!'
  $body = @{ email = $env:LAB7_EMAIL; password = $env:LAB7_PASSWORD; email_confirm = $true } | ConvertTo-Json
  $testUser = Invoke-RestMethod -Method Post -Uri "$env:LAB7_URL/auth/v1/admin/users" -Headers $adminHeaders -ContentType 'application/json' -Body $body
  $testUserId = $testUser.id
  if (-not $testUserId) { throw 'No se obtuvo el ID de la cuenta temporal.' }
  $env:LAB7_LIVE = '1'
  & "$FlutterRoot\bin\cache\dart-sdk\bin\dart.exe" "$FlutterRoot\bin\cache\flutter_tools.snapshot" test --no-pub test/supabase_live_test.dart
  $testResult = $LASTEXITCODE
} finally {
  if ($testUserId) {
    Invoke-RestMethod -Method Delete -Uri "$env:LAB7_URL/auth/v1/admin/users/$testUserId" -Headers $adminHeaders | Out-Null
    Write-Output 'Cuenta temporal eliminada; perfiles, posts y likes se limpian por cascada.'
  }
  foreach ($name in @('LAB7_URL','LAB7_PUBLIC_KEY','LAB7_EMAIL','LAB7_PASSWORD','LAB7_LIVE')) {
    Remove-Item -LiteralPath "Env:$name" -ErrorAction SilentlyContinue
  }
  Pop-Location
}
exit $testResult
