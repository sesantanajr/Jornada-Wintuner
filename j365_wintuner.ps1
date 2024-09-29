#####################################################
## Jornada365 | Wintuner                         ####
## jornada365.cloud                              ####
## Sua jornada começa aqui.                      ####
## "https://github.com/svrooij/wingetintune"     ####
#####################################################

# Configurações personalizáveis
$script:config = @{
    Email = "adminglobal@corporativo.com.br"
    PackageFolder = "C:\Wintuner\Apps"
    PackageIds = @(
        "7zip.7zip",
        "Microsoft.VisualStudioCode",
        "Mozilla.Firefox"
        "Microsoft.VCRedist.2015+.x86"
        "Microsoft.VCRedist.2015+.x64"
        "Microsoft.PowerBI"
        "Adobe.Acrobat.Reader.64-bit"
        "Google.Chrome"
        "AnyDeskSoftwareGmbH.AnyDesk"
        "Bitwarden.Bitwarden"
        "Notepad++.Notepad++" 
        
    )
    LogFile = "C:\Wintuner\deployment_log.txt"
}

# Função para logging
function Write-Log {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Message,
        [ValidateSet("INFO", "WARN", "ERROR", "DEBUG")]
        [string]$Level = "INFO"
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] [$Level] $Message"
    Add-Content -Path $script:config.LogFile -Value $logMessage -ErrorAction SilentlyContinue
    Write-Host $logMessage
}

# Função para verificar e instalar o módulo WinTuner
function Ensure-WinTunerModule {
    try {
        if (-not (Get-Module -ListAvailable -Name WinTuner)) {
            Write-Log "Módulo WinTuner não encontrado. Instalando..." "WARN"
            Install-Module -Name WinTuner -Force -Scope CurrentUser -ErrorAction Stop
        } else {
            Write-Log "Módulo WinTuner já está instalado."
        }

        Import-Module WinTuner -Force -ErrorAction Stop

        $currentVersion = (Get-Module WinTuner).Version
        $latestVersion = (Find-Module WinTuner).Version
        if ($currentVersion -lt $latestVersion) {
            Write-Log "Atualizando o módulo WinTuner..." "WARN"
            Update-Module -Name WinTuner -Force -ErrorAction Stop
            Import-Module WinTuner -Force -ErrorAction Stop
        } else {
            Write-Log "Módulo WinTuner está na versão mais recente."
        }
    } catch {
        Write-Log "Erro ao gerenciar o módulo WinTuner: $($_.Exception.Message)" "ERROR"
        throw
    }
}

# Função para conectar ao WinTuner
function Connect-ToWinTuner {
    param (
        [Parameter(Mandatory=$true)]
        [string]$Email
    )
    try {
        $connection = Connect-WtWinTuner -Username $Email -Test -ErrorAction Stop
        Write-Log "Conectado ao WinTuner com sucesso."
        return $connection
    } catch {
        Write-Log "Erro ao conectar ao WinTuner: $($_.Exception.Message)" "ERROR"
        throw
    }
}

# Função para criar e implantar pacotes
function Deploy-Packages {
    param (
        [Parameter(Mandatory=$true)]
        [string[]]$PackageIds,
        [Parameter(Mandatory=$true)]
        [string]$PackageFolder
    )
    foreach ($packageId in $PackageIds) {
        Write-Log "Processando pacote: $packageId"
        try {
            $package = New-WtWingetPackage -PackageId $packageId -PackageFolder $PackageFolder -ErrorAction Stop
            Write-Log "Pacote criado com sucesso: $($package.Path)"
            
            $deployResult = $package | Deploy-WtWin32App -Verbose -ErrorAction Stop
            Write-Log "Resultado do deploy: $($deployResult | ConvertTo-Json -Depth 3 -Compress)"
            
            Write-Log "Pacote $packageId implantado com sucesso."
        } catch {
            Write-Log "Erro ao implantar o pacote ${packageId}: $($_.Exception.Message)" "ERROR"
            Write-Log "Detalhes do erro: $($_ | ConvertTo-Json -Depth 3 -Compress)" "DEBUG"
        }
    }
}

# Script principal
try {
    Write-Log "Iniciando script de implantação..."
    Ensure-WinTunerModule
    $connection = Connect-ToWinTuner -Email $script:config.Email
    Write-Log "Detalhes da conexão: $($connection | ConvertTo-Json -Depth 3 -Compress)" "DEBUG"
    Deploy-Packages -PackageIds $script:config.PackageIds -PackageFolder $script:config.PackageFolder
} catch {
    Write-Log "Ocorreu um erro crítico: $($_.Exception.Message)" "ERROR"
    Write-Log "Stack trace: $($_.ScriptStackTrace)" "DEBUG"
} finally {
    # Desconectar ou realizar limpeza, se necessário
    # Se existir um comando de desconexão, use-o aqui
    # Disconnect-WtWinTuner -ErrorAction SilentlyContinue
    Write-Log "Script concluído."
