param (
	$ProcessId,
	$StatusFile,
	$LogFile  # �s�W�Ѽ�
)

# �}�l�O��
Start-Transcript -Path $LogFile -Append

# �ɤJ��� �ЫاR�� VM �����
. (Join-Path $PSScriptRoot "VMFunctions.ps1")

# �}�l�ʱ��i�{
#Write-Host "�}�l�ʱ��i�{ ID: $ProcessId" -ForegroundColor Cyan
while ($true) {
   Start-Sleep -Seconds 1
    if (-not (Get-Process -Id $ProcessId -ErrorAction SilentlyContinue)) {
        # �ˬd�K�X���A
        $passwordCorrect = Get-Content -Path $StatusFile
        if ($passwordCorrect -ne "true") {
            #Write-Host "�˴���D�i�{�����B�K�X���q�L�A�}�l�M�z..." -ForegroundColor Yellow
            Remove-VMEnvironment
        } else {
            #Write-Host "�K�X���ҳq�L�A������R���ާ@" -ForegroundColor Green
        }
        # �M�z���A���
        Remove-Item -Path $StatusFile -Force -ErrorAction SilentlyContinue
        break
    }
}

# �����O��
# Stop-Transcript