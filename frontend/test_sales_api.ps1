# Test the sales API to see what data is being returned
$response = Invoke-RestMethod -Uri "http://localhost:8080/getsales" -Method Get
$response | ConvertTo-Json -Depth 5 | Write-Output
