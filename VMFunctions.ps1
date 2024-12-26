# 創建刪除 VM 的函數
function Remove-VMEnvironment {
	
	# 如果已經在記錄中，先停止
    try { Stop-Transcript } catch { }
	
	# 開始記錄
    Start-Transcript -Path $global:LogFile -Append
	
    #Write-Host "開始執行虛擬機清理程序: $(Get-Date)" -ForegroundColor Yellow
    
    $VMNames = @("win10")
    foreach ($VMName in $VMNames) {
        $vm = Get-VM -Name $VMName -ErrorAction SilentlyContinue
        if ($vm -eq $null) {
            #Write-Host "虛擬機 '$VMName' 不存在！" -ForegroundColor Red
            continue
        }
        
        $vhdPaths = @()
		#Write-Host "開始收集硬碟路徑..." -ForegroundColor Yellow
        foreach ($controller in $vm.HardDrives) {
            if ($controller.Path -ne $null) {
                # 收集差異磁碟
                #Write-Host "找到虛擬硬碟：$($controller.Path)" -ForegroundColor Yellow
                $vhdPaths += $controller.Path
                
                # 取得 VHD 的完整資訊
                $vhdInfo = Get-VHD -Path $controller.Path
                # 收集基礎磁碟
                if ($vhdInfo.ParentPath -ne $null) {
                    #Write-Host "找到基礎虛擬硬碟：$($vhdInfo.ParentPath)" -ForegroundColor Yellow
                    $vhdPaths += $vhdInfo.ParentPath
                }
            }
        }
		
		#Write-Host "收集到的硬碟路徑數量: $($vhdPaths.Count)" -ForegroundColor Yellow
        #Write-Host "硬碟路徑列表:" -ForegroundColor Yellow
        #$vhdPaths | ForEach-Object { Write-Host $_ -ForegroundColor Cyan }
        
		# 先關閉 VM
        if ($vm.State -eq "Running") {
            #Write-Host "虛擬機 '$VMName' 正在運行，現在關閉..." -ForegroundColor Yellow
            Stop-VM -Name $VMName -Force -TurnOff
			Start-Sleep -Seconds 5 # 增加延時 等待 VM 完全關閉
            #Write-Host "虛擬機 '$VMName' 已關閉。" -ForegroundColor Green
        }
		
		# 移除所有硬碟連接
        #Write-Host "正在移除虛擬機硬碟連接..." -ForegroundColor Yellow
        Get-VMHardDiskDrive -VMName $VMName | Remove-VMHardDiskDrive
        Start-Sleep -Seconds 2
        
		# 刪除 VM
        #Write-Host "正在刪除虛擬機 '$VMName'..." -ForegroundColor Yellow
        Remove-VM -Name $VMName -Force
        #Write-Host "虛擬機 '$VMName' 已從 Hyper-V 中刪除。" -ForegroundColor Green
        
        # 停止 Hyper-V 服務
        #Write-Host "停止 Hyper-V 服務..." -ForegroundColor Yellow
        Stop-Service -Name vmms -Force
        Stop-Service -Name vhdsvc -Force -ErrorAction SilentlyContinue
        Start-Sleep -Seconds 10
		
		Write-Host "開始處理硬碟檔案..." -ForegroundColor Yellow
        # 刪除 VHD 檔案
        foreach ($vhdPath in $vhdPaths) {
            if (Test-Path $vhdPath) {
                #Write-Host "正在刪除虛擬硬碟檔案：$vhdPath" -ForegroundColor Yellow
                
				# 先嘗試解除掛載
                try {
                    #Write-Host "嘗試解除掛載虛擬硬碟..." -ForegroundColor Yellow
                    Dismount-DiskImage -ImagePath $vhdPath -ErrorAction SilentlyContinue
                    Start-Sleep -Seconds 2
                } catch {
                    Write-Host "解除掛載時發生錯誤: $($_.Exception.Message)" -ForegroundColor Red
                }
				
				# 使用 CMD 強制刪除
                #Write-Host "使用 CMD 強制刪除..." -ForegroundColor Yellow
                $result = cmd /c del /f /q "$vhdPath" 2>&1
                Start-Sleep -Seconds 2
				
				# 如果還存在，使用其他方法
                if (Test-Path $vhdPath) {
                    #Write-Host "CMD 刪除失敗，嘗試其他方法..." -ForegroundColor Yellow
                    try {
                        [System.IO.File]::Delete($vhdPath)
                    } catch {
                        Write-Host "使用 .NET 刪除失敗: $($_.Exception.Message)" -ForegroundColor Red
                        try {
                            Remove-Item -Path $vhdPath -Force -ErrorAction Stop
                        } catch {
                            Write-Host "Remove-Item 刪除失敗: $($_.Exception.Message)" -ForegroundColor Red
                        }
                    }
                }
				
				# 最終檢查
                if (Test-Path $vhdPath) {
                    Write-Host "警告：無法刪除檔案 $vhdPath" -ForegroundColor Red
                } else {
                    #Write-Host "成功刪除檔案 $vhdPath" -ForegroundColor Green
                }
            }
        }
    }
	
	# 重新啟動 Hyper-V 服務
    #Write-Host "重新啟動 Hyper-V 服務..." -ForegroundColor Yellow
    Start-Service -Name vmms
	
    #Write-Host "虛擬機清理程序完成: $(Get-Date)" -ForegroundColor Green
	
	# 結束記錄
    # Stop-Transcript
}

# 導出函數使其可被其他腳本使用
# Export-ModuleMember -Function Remove-VMEnvironment