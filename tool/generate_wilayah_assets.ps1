$ErrorActionPreference = 'Stop'

$pattern = "^\('[^']+','(?:''|[^'])*','(?:''|[^'])*',\s*[-0-9.]+,\s*[-0-9.]+"
$rows = & rg --only-matching --no-filename $pattern `
    'assets/data/cahyadsn_wilayah_level_1_2.sql'
$rows | Set-Content 'assets/data/cahyadsn_wilayah_map.txt' -Encoding utf8

Write-Output "Generated $($rows.Count) area peta."
