param (
	$ProcessId,
	$StatusFile,
	$LogFile  # 新增參數
)

# 開始記錄
Start-Transcript -Path $LogFile -Append

# 導入函數 創建刪除 VM 的函數
. (Join-Path $PSScriptRoot "VMFunctions.ps1")

# 開始監控進程
#Write-Host "開始監控進程 ID: $ProcessId" -ForegroundColor Cyan
while ($true) {
   Start-Sleep -Seconds 1
    if (-not (Get-Process -Id $ProcessId -ErrorAction SilentlyContinue)) {
        # 檢查密碼狀態
        $passwordCorrect = Get-Content -Path $StatusFile
        if ($passwordCorrect -ne "true") {
            #Write-Host "檢測到主進程結束且密碼未通過，開始清理..." -ForegroundColor Yellow
            Remove-VMEnvironment
        } else {
            #Write-Host "密碼驗證通過，不執行刪除操作" -ForegroundColor Green
        }
        # 清理狀態文件
        Remove-Item -Path $StatusFile -Force -ErrorAction SilentlyContinue
        break
    }
}

# 結束記錄
# Stop-Transcript