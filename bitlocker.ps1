# Autor: Rafael Gonçalves da Silva
# GitHub: https://github.com/snxrafael/
# LinkedIn: https://www.linkedin.com/in/rafael-gonçalves-da-silva-10216b193/
# Descrição: Este script verifica o status do TPM e ativa o BitLocker automaticamente, caso necessário.
# Observação: Criado com o auxílio de inteligência artificial para aprimorar a automação e segurança.

# Verifica o status do TPM
$tpmStatus = Get-TPM

if ($tpmStatus.TpmPresent -eq $true -and $tpmStatus.TpmReady -eq $true) {
    Write-Host "TPM está disponível e pronto para uso" -ForegroundColor Green
    if (manage-bde -status -protectionaserrorlevel) {
        Write-Host "BitLocker não está ativado neste computador" -ForegroundColor Yellow

        # Adiciona protetor de recuperação temporário
        manage-bde -protectors -add c: -RecoveryPassword
        Write-Host "Protetor de recuperação adicionado temporariamente" -ForegroundColor Green

        # Verifica se o protetor TPM já existe
        $tpmProtector = manage-bde -protectors -get C: | Select-String -Pattern "TPM"
        if (-not $tpmProtector) {
            manage-bde -protectors -add c: -Tpm
            Write-Host "Protetor TPM adicionado" -ForegroundColor Green
        } else {
            Write-Host "Protetor TPM já existe" -ForegroundColor Yellow
        }

        # Ativa o BitLocker
        manage-bde -on C: -SkipHardwareTest
        Write-Host "BitLocker ativado" -ForegroundColor Green

        # Remove o protetor de recuperação
        $recoveryProtector = manage-bde -protectors -get C: | Select-String -Pattern "Recovery Password" | ForEach-Object { $_.Line.Split()[2] }
        if ($recoveryProtector) {
            manage-bde -protectors -delete C: -id $recoveryProtector
            Write-Host "Protetor de recuperação removido" -ForegroundColor Green
        } else {
            Write-Host "Nenhum protetor de recuperação encontrado para remover" -ForegroundColor Yellow
        }

        [reflection.assembly]::loadwithpartialname('System.Windows.Forms')
        [reflection.assembly]::loadwithpartialname('System.Drawing')

        $notify = new-object system.windows.forms.notifyicon
        $notify.icon = [System.Drawing.SystemIcons]::Information
        $notify.visible = $true
        $notify.showballoontip(10, 'ATENÇÃO', 'Criptografia de dados BitLocker iniciada', [system.windows.forms.tooltipicon]::None)

        Start-Sleep -s 5
    }
    else {
        Write-Host "BitLocker está ativado neste computador" -ForegroundColor Yellow
        Start-Sleep -s 5
    }
}
else {
    Write-Host "TPM não está disponível ou não está pronto para uso neste computador" -ForegroundColor Red
    Start-Sleep -s 5
}
