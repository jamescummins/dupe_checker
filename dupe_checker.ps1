$folderPath = "D:\Music\"
$hashes = New-Object System.Collections.Hashtable

if (Test-Path "$folderPath\hashes.txt") {
    Write-Output "Loading existing hashes from hashes.txt..."
    $hashes = Import-Csv "$folderPath\hashes.txt" -Header Path,Hash | Group-Object -Property Hash | Where-Object { $_.Count -gt 1 } | ForEach-Object { $_.Group } | Group-Object -Property Path | ForEach-Object { @{ $_.Name = $_.Group[0].Hash } }
}

Write-Output "Calculating hashes for new or unprocessed files..."
$files = Get-ChildItem $folderPath -Recurse -File
$totalFiles = $files.Count
$processedFiles = 0

$files | ForEach-Object {
    if (!$hashes.ContainsKey($_.FullName)) {
        Write-Output "Calculating hash for file ($processedFiles/$totalFiles)..."
        $hash = (Get-FileHash $_.FullName -Algorithm SHA256).Hash
        $hashes[$_.FullName] = $hash
        "$($_.FullName),$hash" | Out-File "$folderPath\hashes.txt" -Append
    }
    $processedFiles++
}

Write-Output "Finding duplicate files..."
Remove-Item "$folderPath\duplicates.txt" -ErrorAction Ignore
Import-Csv "$folderPath\hashes.txt" -Header Path,Hash | Group-Object -Property Hash | Where-Object { $_.Count -gt 1 } | ForEach-Object {
    "Duplicate files:" | Out-File "$folderPath\duplicates.txt" -Append
    $_.Group | Sort-Object -Property Path | ForEach-Object {
        Write-Output "Found duplicate file: $($_.Path)"
        $_.Path | Out-File "$folderPath\duplicates.txt" -Append
    }
}
