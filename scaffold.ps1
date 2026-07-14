# Run this from the root of your honeypot-siem-lab repo (where README.md already lives)
# Usage: .\scaffold.ps1

Write-Host "Creating directory structure..."
New-Item -ItemType Directory -Force -Path "docs" | Out-Null
New-Item -ItemType Directory -Force -Path "vagrant\provision" | Out-Null
New-Item -ItemType Directory -Force -Path "configs\wazuh-rules" | Out-Null
New-Item -ItemType Directory -Force -Path "attack-scripts" | Out-Null
New-Item -ItemType Directory -Force -Path "sample-logs" | Out-Null
New-Item -ItemType Directory -Force -Path "screenshots" | Out-Null

Write-Host "Creating docs/ files..."
New-Item -ItemType File -Force -Path "docs\architecture.md" | Out-Null
New-Item -ItemType File -Force -Path "docs\setup-guide.md" | Out-Null
New-Item -ItemType File -Force -Path "docs\attack-scenarios.md" | Out-Null
New-Item -ItemType File -Force -Path "docs\mitre-mapping.md" | Out-Null

Write-Host "Creating vagrant/ files..."
New-Item -ItemType File -Force -Path "vagrant\Vagrantfile" | Out-Null
New-Item -ItemType File -Force -Path "vagrant\provision\honeypot.sh" | Out-Null
New-Item -ItemType File -Force -Path "vagrant\provision\monitoring.sh" | Out-Null
New-Item -ItemType File -Force -Path "vagrant\provision\attacker.sh" | Out-Null

Write-Host "Creating configs/ files..."
New-Item -ItemType File -Force -Path "configs\cowrie.cfg" | Out-Null
New-Item -ItemType File -Force -Path "configs\suricata.yaml" | Out-Null
New-Item -ItemType File -Force -Path "configs\wazuh-rules\.gitkeep" | Out-Null

Write-Host "Creating attack-scripts/ files..."
New-Item -ItemType File -Force -Path "attack-scripts\brute_force.sh" | Out-Null
New-Item -ItemType File -Force -Path "attack-scripts\port_scan.sh" | Out-Null
New-Item -ItemType File -Force -Path "attack-scripts\sqli_test.py" | Out-Null

Write-Host "Creating placeholders for empty dirs..."
New-Item -ItemType File -Force -Path "sample-logs\.gitkeep" | Out-Null
New-Item -ItemType File -Force -Path "screenshots\.gitkeep" | Out-Null

Write-Host ""
Write-Host "Done. Structure created:"
Get-ChildItem -Recurse -File | Where-Object { $_.FullName -notmatch '\\\.git\\' } | ForEach-Object {
    $_.FullName.Replace((Get-Location).Path + "\", "")
} | Sort-Object
