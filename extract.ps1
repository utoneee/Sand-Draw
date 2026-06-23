$svgFiles = Get-ChildItem -Filter "*.svg"
if ($svgFiles.Count -eq 0) { Write-Host "No SVG files found."; Read-Host "Press Enter"; exit }
if ($svgFiles.Count -eq 1) {
    $file = $svgFiles[0]
} else {
    for ($i = 0; $i -lt $svgFiles.Count; $i++) { Write-Host "$($i+1). $($svgFiles[$i].Name)" }
    $choice = Read-Host "Select number"
    $file = $svgFiles[$choice - 1]
}
Write-Host "Processing: $($file.Name)"

$svg = [System.IO.File]::ReadAllText($file.FullName, [System.Text.Encoding]::UTF8)
$svg = $svg.Replace("`r`n"," ").Replace("`n"," ").Replace("`t"," ")

# 命名色對照表 -> hex
$namedColors = @{
    'black'='#000000'; 'white'='#FFFFFF'; 'red'='#FF0000'; 'green'='#008000';
    'blue'='#0000FF'; 'yellow'='#FFFF00'; 'orange'='#FFA500'; 'purple'='#800080';
    'gray'='#808080'; 'grey'='#808080'; 'pink'='#FFC0CB'; 'brown'='#A52A2A';
    'cyan'='#00FFFF'; 'magenta'='#FF00FF'; 'lime'='#00FF00'; 'navy'='#000080';
    'gold'='#FFD700'; 'silver'='#C0C0C0'; 'teal'='#008080'; 'maroon'='#800000'
}

# 同時抓 hex 和命名色
$pattern = 'fill="(#[A-Fa-f0-9]+|[a-zA-Z]+)"\s+d="([^"]+)"'
$ms = [regex]::Matches($svg, $pattern)
$groups = @{}
$order = @()
foreach ($m in $ms) {
    $raw = $m.Groups[1].Value
    # 命名色轉 hex，忽略 none/transparent
    if ($raw -match '^#') { $c = $raw.ToUpper() }
    elseif ($namedColors.ContainsKey($raw.ToLower())) { $c = $namedColors[$raw.ToLower()] }
    else { continue }
    $d = ($m.Groups[2].Value -replace '\s+', ' ').Trim()
    if ($groups[$c]) { $groups[$c] += " $d" } else { $groups[$c] = $d; $order += $c }
}
$out = ""
foreach ($c in $order) { $out += "svgRegion('$c', '$($groups[$c])'),`n" }

$outName = [System.IO.Path]::GetFileNameWithoutExtension($file.Name) + "_extracted.txt"
[System.IO.File]::WriteAllText("$PWD\$outName", $out, [System.Text.Encoding]::UTF8)
Write-Host "Done! $($order.Count) color groups -> $outName"
Invoke-Item "$PWD\$outName"
Read-Host "Press Enter to close"
