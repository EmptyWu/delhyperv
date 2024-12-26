# �ЫاR�� VM �����
function Remove-VMEnvironment {
	
	# �p�G�w�g�b�O�����A������
    try { Stop-Transcript } catch { }
	
	# �}�l�O��
    Start-Transcript -Path $global:LogFile -Append
	
    #Write-Host "�}�l����������M�z�{��: $(Get-Date)" -ForegroundColor Yellow
    
    $VMNames = @("win10")
    foreach ($VMName in $VMNames) {
        $vm = Get-VM -Name $VMName -ErrorAction SilentlyContinue
        if ($vm -eq $null) {
            #Write-Host "������ '$VMName' ���s�b�I" -ForegroundColor Red
            continue
        }
        
        $vhdPaths = @()
		#Write-Host "�}�l�����w�и��|..." -ForegroundColor Yellow
        foreach ($controller in $vm.HardDrives) {
            if ($controller.Path -ne $null) {
                # �����t���Ϻ�
                #Write-Host "�������w�СG$($controller.Path)" -ForegroundColor Yellow
                $vhdPaths += $controller.Path
                
                # ���o VHD �������T
                $vhdInfo = Get-VHD -Path $controller.Path
                # ������¦�Ϻ�
                if ($vhdInfo.ParentPath -ne $null) {
                    #Write-Host "����¦�����w�СG$($vhdInfo.ParentPath)" -ForegroundColor Yellow
                    $vhdPaths += $vhdInfo.ParentPath
                }
            }
        }
		
		#Write-Host "�����쪺�w�и��|�ƶq: $($vhdPaths.Count)" -ForegroundColor Yellow
        #Write-Host "�w�и��|�C��:" -ForegroundColor Yellow
        #$vhdPaths | ForEach-Object { Write-Host $_ -ForegroundColor Cyan }
        
		# ������ VM
        if ($vm.State -eq "Running") {
            #Write-Host "������ '$VMName' ���b�B��A�{�b����..." -ForegroundColor Yellow
            Stop-VM -Name $VMName -Force -TurnOff
			Start-Sleep -Seconds 5 # �W�[���� ���� VM ��������
            #Write-Host "������ '$VMName' �w�����C" -ForegroundColor Green
        }
		
		# �����Ҧ��w�гs��
        #Write-Host "���b�����������w�гs��..." -ForegroundColor Yellow
        Get-VMHardDiskDrive -VMName $VMName | Remove-VMHardDiskDrive
        Start-Sleep -Seconds 2
        
		# �R�� VM
        #Write-Host "���b�R�������� '$VMName'..." -ForegroundColor Yellow
        Remove-VM -Name $VMName -Force
        #Write-Host "������ '$VMName' �w�q Hyper-V ���R���C" -ForegroundColor Green
        
        # ���� Hyper-V �A��
        #Write-Host "���� Hyper-V �A��..." -ForegroundColor Yellow
        Stop-Service -Name vmms -Force
        Stop-Service -Name vhdsvc -Force -ErrorAction SilentlyContinue
        Start-Sleep -Seconds 10
		
		Write-Host "�}�l�B�z�w���ɮ�..." -ForegroundColor Yellow
        # �R�� VHD �ɮ�
        foreach ($vhdPath in $vhdPaths) {
            if (Test-Path $vhdPath) {
                #Write-Host "���b�R�������w���ɮסG$vhdPath" -ForegroundColor Yellow
                
				# �����ոѰ�����
                try {
                    #Write-Host "���ոѰ����������w��..." -ForegroundColor Yellow
                    Dismount-DiskImage -ImagePath $vhdPath -ErrorAction SilentlyContinue
                    Start-Sleep -Seconds 2
                } catch {
                    Write-Host "�Ѱ������ɵo�Ϳ��~: $($_.Exception.Message)" -ForegroundColor Red
                }
				
				# �ϥ� CMD �j��R��
                #Write-Host "�ϥ� CMD �j��R��..." -ForegroundColor Yellow
                $result = cmd /c del /f /q "$vhdPath" 2>&1
                Start-Sleep -Seconds 2
				
				# �p�G�٦s�b�A�ϥΨ�L��k
                if (Test-Path $vhdPath) {
                    #Write-Host "CMD �R�����ѡA���ը�L��k..." -ForegroundColor Yellow
                    try {
                        [System.IO.File]::Delete($vhdPath)
                    } catch {
                        Write-Host "�ϥ� .NET �R������: $($_.Exception.Message)" -ForegroundColor Red
                        try {
                            Remove-Item -Path $vhdPath -Force -ErrorAction Stop
                        } catch {
                            Write-Host "Remove-Item �R������: $($_.Exception.Message)" -ForegroundColor Red
                        }
                    }
                }
				
				# �̲��ˬd
                if (Test-Path $vhdPath) {
                    Write-Host "ĵ�i�G�L�k�R���ɮ� $vhdPath" -ForegroundColor Red
                } else {
                    #Write-Host "���\�R���ɮ� $vhdPath" -ForegroundColor Green
                }
            }
        }
    }
	
	# ���s�Ұ� Hyper-V �A��
    #Write-Host "���s�Ұ� Hyper-V �A��..." -ForegroundColor Yellow
    Start-Service -Name vmms
	
    #Write-Host "�������M�z�{�ǧ���: $(Get-Date)" -ForegroundColor Green
	
	# �����O��
    # Stop-Transcript
}

# �ɥX��ƨϨ�i�Q��L�}���ϥ�
# Export-ModuleMember -Function Remove-VMEnvironment