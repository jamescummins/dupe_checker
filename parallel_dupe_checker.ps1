$folderPath = "D:\Music\"
$hashes = [System.Collections.Concurrent.ConcurrentDictionary[string,string]]::new()

if (Test-Path "$folderPath\hashes.txt") {
    Write-Output "Loading existing hashes from hashes.txt..."
    Get-Content "$folderPath\hashes.txt" | ConvertFrom-Csv -Header Path,Hash | Where-Object { Test-Path $_.Path } | ForEach-Object {
        $hashes[$_.Path] = $_.Hash
    }
    $hashes.GetEnumerator() | ForEach-Object {
        [PSCustomObject]@{ Path = $_.Key; Hash = $_.Value } | ConvertTo-Csv -NoTypeInformation | Select-Object -Skip 1 | Set-Content "$folderPath\hashes.txt"
    }
}

Write-Output "Calculating hashes for new or unprocessed files..."
$files = Get-ChildItem $folderPath -Recurse -File
$totalFiles = $files.Count
$processedFiles = 0

$files | ForEach-Object {
    if (!$hashes.ContainsKey($_.FullName)) {
        $processedFiles++
        Write-Output "Calculating hash for file $processedFiles/$totalFiles..."
        $hash = (Get-FileHash $_.FullName -Algorithm SHA256).Hash
        $hashes[$_.FullName] = $hash
        [PSCustomObject]@{ Path = $_.FullName; Hash = $hash } | ConvertTo-Csv -NoTypeInformation | Select-Object -Skip 1 | Out-File "$folderPath\hashes.txt" -Append
    }
}

Write-Output "Finding duplicate files..."
Remove-Item "$folderPath\duplicates.txt" -ErrorAction Ignore
Get-Content "$folderPath\hashes.txt" | ConvertFrom-Csv -Header Path,Hash | Group-Object -Property Hash | Where-Object { $_.Count -gt 1 } | ForEach-Object {
    "Duplicate files:" | Out-File "$folderPath\duplicates.txt" -Append
    $_.Group | Sort-Object -Property Path | ForEach-Object {
        Write-Output "Found duplicate file: $($_.Path)"
        $_.Path | Out-File "$folderPath\duplicates.txt" -Append
    }
}
