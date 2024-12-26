# �]�w������x�����|
$global:LogFile = "D:\vm_protection_log.txt"

# �}�l�O����x
Start-Transcript -Path $global:LogFile -Append

#Write-Host "�}���}�l����ɶ�: $(Get-Date)"
#Write-Host "�i�{ ID: $PID"

# �ɤJ��� �ЫاR�� VM �����
. (Join-Path $PSScriptRoot "VMFunctions.ps1")

# �ЫرK�X���A���
$statusFile = "D:\vm_status.txt"
"false" | Out-File -FilePath $statusFile -Force

# �Ұʺʱ��i�{
$monitorScript = Join-Path $PSScriptRoot "monitor.ps1"
# �b local01.ps1 ��
Start-Process powershell.exe -ArgumentList "-ExecutionPolicy Bypass -WindowStyle Hidden -File `"$monitorScript`" -ProcessId $PID -StatusFile `"$statusFile`" -LogFile `"$global:LogFile`"" -WindowStyle Hidden

# �Ыب�ƨӫʸ˲{�����}��
function Protect-VMEnvironment {
    # �]�w�K�X
    $CorrectPassword = "123456"
    $maxAttempts = 3
    $attempts = 0
    $PasswordCorrect = $false
    $TimeoutSeconds = 30
    $StartTime = Get-Date

    while ($attempts -lt $maxAttempts) {
        # �p��Ѿl�ɶ�
        $ElapsedSeconds = (Get-Date) - $StartTime
        $RemainingTime = $TimeoutSeconds - $ElapsedSeconds.TotalSeconds
        
        if ($RemainingTime -le 0) {
            Write-Host "�K�X��J�W�ɡI����R���ާ@..." -ForegroundColor Red
            break
        }
        
        # ��ܱK�X����
        $InputPassword = Read-Host "�п�J�K�X�H�~��"
        # ���ұK�X
        if ($InputPassword -eq $CorrectPassword) {
            Write-Host "�K�X���T�I�t�Τw�ҰʡC" -ForegroundColor Green
            $PasswordCorrect = $true
            return $true
        } else {
            $attempts++
            Write-Host "�K�X���~�I�٦� $(($maxAttempts - $attempts)) �����|�C" -ForegroundColor Red
        }
    }

    if (-not $PasswordCorrect) {
        Remove-VMEnvironment
    }
}


# �����l�O�@
$global:PasswordCorrect = Protect-VMEnvironment

if ($global:PasswordCorrect) {
    # �g�J�K�X���T���A
    "true" | Out-File -FilePath $statusFile -Force
    Write-Host "�����N�䵲���{��..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
} else {
    Remove-VMEnvironment
}


# ������x
Stop-Transcript