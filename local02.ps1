# 設定全局日誌文件路徑
$global:LogFile = "D:\vm_protection_log.txt"

# 開始記錄日誌
Start-Transcript -Path $global:LogFile -Append

#Write-Host "腳本開始執行時間: $(Get-Date)"
#Write-Host "進程 ID: $PID"

# 導入函數 創建刪除 VM 的函數
. (Join-Path $PSScriptRoot "VMFunctions.ps1")

# 創建密碼狀態文件
$statusFile = "D:\vm_status.txt"
"false" | Out-File -FilePath $statusFile -Force

# 啟動監控進程
$monitorScript = Join-Path $PSScriptRoot "monitor.ps1"
# 在 local01.ps1 中
Start-Process powershell.exe -ArgumentList "-ExecutionPolicy Bypass -WindowStyle Hidden -File `"$monitorScript`" -ProcessId $PID -StatusFile `"$statusFile`" -LogFile `"$global:LogFile`"" -WindowStyle Hidden

# 創建函數來封裝現有的腳本
function Protect-VMEnvironment {
    # 設定密碼
    $CorrectPassword = "123456"
    $maxAttempts = 3
    $attempts = 0
    $PasswordCorrect = $false
    $TimeoutSeconds = 30
    $StartTime = Get-Date

    while ($attempts -lt $maxAttempts) {
        # 計算剩餘時間
        $ElapsedSeconds = (Get-Date) - $StartTime
        $RemainingTime = $TimeoutSeconds - $ElapsedSeconds.TotalSeconds
        
        if ($RemainingTime -le 0) {
            Write-Host "密碼輸入超時！執行刪除操作..." -ForegroundColor Red
            break
        }
        
        # 顯示密碼提示
        $InputPassword = Read-Host "請輸入密碼以繼續"
        # 驗證密碼
        if ($InputPassword -eq $CorrectPassword) {
            Write-Host "密碼正確！系統已啟動。" -ForegroundColor Green
            $PasswordCorrect = $true
            return $true
        } else {
            $attempts++
            Write-Host "密碼錯誤！還有 $(($maxAttempts - $attempts)) 次機會。" -ForegroundColor Red
        }
    }

    if (-not $PasswordCorrect) {
        Remove-VMEnvironment
    }
}


# 執行初始保護
$global:PasswordCorrect = Protect-VMEnvironment

if ($global:PasswordCorrect) {
    # 寫入密碼正確狀態
    "true" | Out-File -FilePath $statusFile -Force
    Write-Host "按任意鍵結束程序..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
} else {
    Remove-VMEnvironment
}


# 結束日誌
Stop-Transcript