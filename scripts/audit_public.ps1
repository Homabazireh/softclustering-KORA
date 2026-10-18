$ErrorActionPreference = 'Stop'
$repo = (& git rev-parse --show-toplevel)
if ($LASTEXITCODE -ne 0) { throw 'Run from the public Git repository.' }
$repo = [IO.Path]::GetFullPath($repo)
function Assert-PublicPath([string]$path) {
    $allowed = $path -match '^(code/[^/]+/[^/]+\.Rmd|scripts/[^/]+\.(R|ps1)|docs/[^/]+\.md|manuscript/[^/]+\.md|\.github/workflows/[^/]+\.yml|README\.md|\.gitignore|\.gitattributes|softclustering-KORA\.Rproj)$'
    if (!$allowed) { throw ('Non-source path in Git history or index: ' + $path) }
}
foreach ($path in (& git ls-files)) { Assert-PublicPath $path }
$commits = @(& git rev-list --all)
if (!$commits.Count) { throw 'Commit the candidate snapshot before auditing its complete history.' }
foreach ($commit in $commits) {
    foreach ($path in (& git ls-tree -r --name-only $commit)) { Assert-PublicPath $path }
}
$reachable = @{}
foreach ($line in (& git rev-list --objects --all)) { $reachable[($line -split ' ')[0]] = $true }
$objects = @(& git cat-file --batch-all-objects '--batch-check=%(objectname) %(objecttype) %(objectsize)')
$blobs = 0
$patterns = @(
    'C:[\\/]+Users[\\/]',
    ('/' + 'Users/[^/]+/'),
    ('K0' + '3324'),
    'ghp_[A-Za-z0-9]{20,}',
    'github_pat_[A-Za-z0-9_]{20,}',
    'AKIA[A-Z0-9]{16}',
    '-----BEGIN (?:RSA |EC |OPENSSH )?PRIVATE KEY-----',
    '(?i)(?:password|api_key|access_token|client_secret)\s*(?:<-|=|:)\s*["''][^"''\s]{8,}["'']'
)
foreach ($line in $objects) {
    $parts = $line -split ' '
    if (!$reachable.ContainsKey($parts[0])) { throw 'Unreachable Git objects found; publish only a fresh, fully audited clone.' }
    if ($parts[1] -ne 'blob') { continue }
    if ([long]$parts[2] -gt 1MB) { throw 'Unexpected large source object.' }
    $text = (& git cat-file blob $parts[0]) -join "`n"
    if ($text.IndexOf([char]0) -ge 0) { throw 'Binary content in the proposed public history.' }
    foreach ($pattern in $patterns) {
        if ($text -match $pattern) { throw ('Sensitive-content pattern detected in Git object ' + $parts[0] + '; inspect privately.') }
    }
    $blobs++
}
Write-Output ('Privacy audit passed: ' + $commits.Count + ' commit(s), ' + $blobs + ' text blob(s); no data paths, binary objects, unreachable objects, or detected secrets/local source paths.')
