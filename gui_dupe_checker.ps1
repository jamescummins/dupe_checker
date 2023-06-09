Add-Type -AssemblyName PresentationFramework

$window = New-Object System.Windows.Window
$window.Title = "Find Duplicate Files"
$window.Width = 400
$window.Height = 200

$grid = New-Object System.Windows.Controls.Grid
$window.Content = $grid

$row1 = New-Object System.Windows.Controls.RowDefinition
$row1.Height = [System.Windows.GridLength]::Auto
$grid.RowDefinitions.Add($row1)

$row2 = New-Object System.Windows.Controls.RowDefinition
$row2.Height = [System.Windows.GridLength]::Auto
$grid.RowDefinitions.Add($row2)

$row3 = New-Object System.Windows.Controls.RowDefinition
$row3.Height = [System.Windows.GridLength]::Auto
$grid.RowDefinitions.Add($row3)

$label = New-Object System.Windows.Controls.Label
$label.Content = "Folder Path:"
$grid.Children.Add($label)
[System.Windows.Controls.Grid]::SetRow($label, 0)

$textBox = New-Object System.Windows.Controls.TextBox
$textBox.Margin = New-Object System.Windows.Thickness(5)
$grid.Children.Add($textBox)
[System.Windows.Controls.Grid]::SetRow($textBox, 1)

$button = New-Object System.Windows.Controls.Button
$button.Content = "Find Duplicates"
$button.Margin = New-Object System.Windows.Thickness(5)
$button.Add_Click({
    $folderPath = $textBox.Text
    $hashes = @{}

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
})
$grid.Children.Add($button)
[System.Windows.Controls.Grid]::SetRow($button, 2)

$window.ShowDialog()
