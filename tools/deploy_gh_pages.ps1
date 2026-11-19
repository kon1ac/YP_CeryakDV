$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$web = Join-Path $root 'build\web'
if (-not (Test-Path (Join-Path $web 'index.html'))) {
  throw "build/web missing — run flutter build web first"
}
Copy-Item (Join-Path $web 'index.html') (Join-Path $web '404.html') -Force

$tmp = Join-Path $env:TEMP ("yp_ceryak_gh_pages_" + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $tmp | Out-Null
try {
  Copy-Item -Path (Join-Path $web '*') -Destination $tmp -Recurse -Force
  Push-Location $tmp
  git init -q
  git checkout -b gh-pages
  git add -A
  git -c user.name='deploy' -c user.email='deploy@local' commit -q -m 'Deploy Flutter web (SPA fallback via 404.html)'
  git remote add origin https://github.com/kon1ac/YP_CeryakDV.git
  git push -f origin gh-pages
  Pop-Location
  Write-Host 'Published: https://kon1ac.github.io/YP_CeryakDV/'
} finally {
  if (Test-Path $tmp) { Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue }
}
