# Format all .asm files in the current directory in-place
Get-ChildItem -Filter "*.asm" | ForEach-Object {
    Write-Host "Formatting $($_.Name)..."
    & asmformat.exe $_.FullName $_.FullName
}