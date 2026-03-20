# bizuit-sdd install-skill.ps1 — Instalador para Windows PowerShell 7+
# Uso:
#   .\install-skill.ps1                     # Modo asistido (default)
#   .\install-skill.ps1 -Mode dev           # Solo validación (git clone ya hecho)
#   .\install-skill.ps1 -Mode assisted      # Paso a paso con credenciales
#   .\install-skill.ps1 -Check              # Health check (no modifica nada)
#
# Exit codes: 0=éxito, 1=error de instalación, 2=error de configuración
# Requiere: PowerShell 7+

param(
    [ValidateSet("dev", "assisted")]
    [string]$Mode = "assisted",
    [switch]$Check
)

$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$SkillSource = Split-Path -Parent $ScriptDir
$Target = Join-Path $env:USERPROFILE ".claude\skills\bizuit-sdd"

function Trim-Value([string]$value) {
    return $value.Trim()
}

function Set-EnvVar([string]$VarName, [string]$VarValue, [string]$ProfilePath) {
    # Crear profile si no existe
    if (-not (Test-Path $ProfilePath)) {
        New-Item -Path $ProfilePath -ItemType File -Force | Out-Null
    }

    $content = Get-Content $ProfilePath -ErrorAction SilentlyContinue
    $line = "`$env:$VarName = `"$VarValue`""
    $pattern = "^\`$env:$VarName\s*="

    if ($content -and ($content | Select-String -Pattern $pattern)) {
        # Sobreescribir línea existente
        $newContent = $content | ForEach-Object {
            if ($_ -match $pattern) { $line } else { $_ }
        }
        Set-Content -Path $ProfilePath -Value $newContent
    } else {
        # Agregar al final
        Add-Content -Path $ProfilePath -Value $line
    }
}

function Run-Validation([string]$TargetDir) {
    $exitCode = 0

    Write-Host ""
    Write-Host "🔍 Validación"
    Write-Host "────────────────"

    # Check 1: SKILL.md existe
    if (Test-Path (Join-Path $TargetDir "SKILL.md")) {
        Write-Host "✅ SKILL.md encontrado"
    } else {
        Write-Host "❌ SKILL.md no encontrado — Claude no puede detectar el skill"
        $exitCode = 1
    }

    # Check 2: VERSION existe
    $versionPath = Join-Path $TargetDir "VERSION"
    if (Test-Path $versionPath) {
        $version = (Get-Content $versionPath -Raw).Trim()
        Write-Host "✅ VERSION: $version"
    } else {
        Write-Host "⚠️  VERSION no encontrado"
    }

    # Check 3: Versión consistente
    $skillPath = Join-Path $TargetDir "SKILL.md"
    if ((Test-Path $versionPath) -and (Test-Path $skillPath)) {
        $fileVersion = (Get-Content $versionPath -Raw).Trim()
        $skillContent = Get-Content $skillPath -Raw
        if ($skillContent -match "Versión:\*\*\s+(\S+)") {
            $skillVersion = $Matches[1]
            if ($fileVersion -ne $skillVersion) {
                Write-Host "⚠️  Versión inconsistente: VERSION=$fileVersion, SKILL.md=$skillVersion"
            }
        }
    }

    # Check 4: MANIFEST existe
    $manifestPath = Join-Path $TargetDir "MANIFEST.md"
    if (Test-Path $manifestPath) {
        $fileCount = (Get-ChildItem -Path $TargetDir -Recurse -File | Where-Object {
            $_.FullName -notlike "*\.git\*" -and $_.FullName -notlike "*\dist\*" -and $_.FullName -notlike "*\processes\*"
        }).Count
        Write-Host "✅ MANIFEST.md presente ($fileCount archivos)"
    } else {
        Write-Host "⚠️  MANIFEST.md no encontrado — ejecutá build-package.sh para generarlo"
    }

    # Check 5: Env vars
    $envVars = @("BIZUIT_API_URL", "BIZUIT_BPMN_API_URL", "BIZUIT_USERNAME", "BIZUIT_PASSWORD", "BIZUIT_ORG_ID")
    $missing = @()
    $configured = @()

    foreach ($var in $envVars) {
        $val = [Environment]::GetEnvironmentVariable($var)
        if ($val) { $configured += $var } else { $missing += $var }
    }

    if ($missing.Count -eq 0) {
        Write-Host "✅ 5/5 env vars configuradas"
    } elseif ($missing.Count -eq 5) {
        Write-Host "⚠️  Ninguna env var configurada (el skill funciona en modo degradado)"
    } else {
        Write-Host "⚠️  Faltan env vars: $($missing -join ', ')"
        Write-Host "   (⚠️ = podés continuar, el skill funciona sin ellas)"
    }

    # Check 6 (solo con -Check): Conectividad
    if ($Check -and $configured.Count -gt 0) {
        Write-Host ""
        Write-Host "🌐 Conectividad"
        Write-Host "────────────────"
        $apiUrl = [Environment]::GetEnvironmentVariable("BIZUIT_API_URL")
        if ($apiUrl) {
            try {
                $null = Invoke-WebRequest -Uri $apiUrl -TimeoutSec 5 -ErrorAction Stop
                Write-Host "✅ Dashboard API: accesible"
            } catch {
                Write-Host "⚠️  Dashboard API: no accesible ($apiUrl)"
            }
        }
        $bpmnUrl = [Environment]::GetEnvironmentVariable("BIZUIT_BPMN_API_URL")
        if ($bpmnUrl) {
            try {
                $null = Invoke-WebRequest -Uri $bpmnUrl -TimeoutSec 5 -ErrorAction Stop
                Write-Host "✅ BPMN API: accesible"
            } catch {
                Write-Host "⚠️  BPMN API: no accesible ($bpmnUrl)"
            }
        }
    }

    Write-Host ""
    if ($exitCode -eq 0) {
        if ($missing.Count -gt 0) {
            Write-Host "Resultado: instalación OK (modo degradado — configurá las env vars para funcionalidad completa)"
        } else {
            Write-Host "Resultado: instalación OK ✅"
        }
        Write-Host ""
        Write-Host 'Próximo paso: abrí Claude Code y decí "hola".'
    } else {
        Write-Host "Resultado: ❌ hay que arreglar antes de poder usar el skill"
    }

    return $exitCode
}

# --- Health check mode ---
if ($Check) {
    Write-Host "🔍 bizuit-sdd — Health Check"
    Write-Host "============================="

    if (Test-Path $Target) {
        $result = Run-Validation $Target
    } elseif (Test-Path (Join-Path $SkillSource "SKILL.md")) {
        $result = Run-Validation $SkillSource
    } else {
        Write-Host "❌ No se encontró bizuit-sdd en $Target ni en el directorio actual"
        exit 1
    }
    exit $result
}

# --- Instalación ---
Write-Host "📦 bizuit-sdd — Instalación"
Write-Host "============================="
Write-Host ""

$inCorrectPath = ($SkillSource -eq $Target) -or ((Resolve-Path $SkillSource -ErrorAction SilentlyContinue).Path -eq (Resolve-Path $Target -ErrorAction SilentlyContinue).Path)

switch ($Mode) {
    "dev" {
        Write-Host "🔧 Modo dev — solo validación"
        Write-Host ""

        if ((Test-Path $Target) -and (Test-Path (Join-Path $Target "SKILL.md"))) {
            $result = Run-Validation $Target
        } elseif ($inCorrectPath) {
            $result = Run-Validation $SkillSource
        } else {
            Write-Host "❌ bizuit-sdd no encontrado en $Target"
            Write-Host "   Hacé git clone primero: git clone {repo} $Target"
            exit 1
        }
        exit $result
    }

    "assisted" {
        Write-Host "📋 Modo asistido — instalación paso a paso"
        Write-Host ""

        # Paso 1: Verificar/copiar archivos
        if ($inCorrectPath) {
            Write-Host "✅ El skill ya está en el path correcto ($Target)"
        } elseif (Test-Path $Target) {
            $versionFile = Join-Path $Target "VERSION"
            if (Test-Path $versionFile) {
                $existingVersion = (Get-Content $versionFile -Raw).Trim()
                Write-Host "⚠️  Ya existe bizuit-sdd v$existingVersion en $Target"
                $overwrite = Read-Host "   ¿Sobreescribir? [s/n]"
                if ($overwrite -ne "s" -and $overwrite -ne "S") {
                    Write-Host "   Cancelado."
                    exit 0
                }
            }
            # Preservar rules/custom/
            $customPath = Join-Path $Target "rules\custom"
            $customBackup = $null
            if (Test-Path $customPath) {
                $customBackup = Join-Path $env:TEMP "bizuit-sdd-custom-backup"
                Copy-Item -Path $customPath -Destination $customBackup -Recurse -Force
            }
            # Copiar archivos
            Copy-Item -Path "$SkillSource\*" -Destination $Target -Recurse -Force
            # Restaurar rules/custom/
            if ($customBackup -and (Test-Path $customBackup)) {
                Copy-Item -Path $customBackup -Destination (Join-Path $Target "rules\custom") -Recurse -Force
                Remove-Item -Path $customBackup -Recurse -Force
            }
            Write-Host "✅ Archivos copiados a $Target"
        } else {
            New-Item -Path (Split-Path $Target -Parent) -ItemType Directory -Force | Out-Null
            Copy-Item -Path $SkillSource -Destination $Target -Recurse -Force
            Write-Host "✅ Archivos copiados a $Target"
        }

        Write-Host ""

        # Paso 2: Credenciales (opcionales)
        $configureCreds = Read-Host "¿Querés configurar las credenciales BIZUIT ahora? [s/n]"

        if ($configureCreds -eq "s" -or $configureCreds -eq "S") {
            $profilePath = $PROFILE
            Write-Host ""
            Write-Host "Configurando credenciales (se escriben en $profilePath):"
            Write-Host ""

            $apiUrl = Read-Host "URL de Dashboard API (ej: https://test.bizuit.com/tenantBIZUITDashboardAPI/api)"
            $bpmnUrl = Read-Host "URL de BPMN API (ej: https://test.bizuit.com/tenantBIZUITBPMNEditorBackEnd/api)"
            $username = Read-Host "Usuario BIZUIT"
            $password = Read-Host "Password BIZUIT" -AsSecureString
            $passwordPlain = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($password))
            $orgId = Read-Host "Organization ID (ej: rdaff)"

            Set-EnvVar "BIZUIT_API_URL" (Trim-Value $apiUrl) $profilePath
            Set-EnvVar "BIZUIT_BPMN_API_URL" (Trim-Value $bpmnUrl) $profilePath
            Set-EnvVar "BIZUIT_USERNAME" (Trim-Value $username) $profilePath
            Set-EnvVar "BIZUIT_PASSWORD" (Trim-Value $passwordPlain) $profilePath
            Set-EnvVar "BIZUIT_ORG_ID" (Trim-Value $orgId) $profilePath

            Write-Host ""
            Write-Host "✅ Credenciales escritas en $profilePath"
            Write-Host "   Abrí una nueva terminal de PowerShell para que tomen efecto."

            # Exportar para validación actual
            $env:BIZUIT_API_URL = Trim-Value $apiUrl
            $env:BIZUIT_BPMN_API_URL = Trim-Value $bpmnUrl
            $env:BIZUIT_USERNAME = Trim-Value $username
            $env:BIZUIT_PASSWORD = Trim-Value $passwordPlain
            $env:BIZUIT_ORG_ID = Trim-Value $orgId
        } else {
            Write-Host ""
            Write-Host "ℹ️  Sin credenciales — el skill funciona en modo degradado."
            Write-Host "   Podés configurarlas después corriendo este script de nuevo."
        }

        # Paso 3: Validación
        if ($inCorrectPath) {
            $result = Run-Validation $SkillSource
        } else {
            $result = Run-Validation $Target
        }
        exit $result
    }
}
