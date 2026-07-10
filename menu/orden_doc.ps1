<#
.SYNOPSIS
    OrganizadorPro: Script de automatización para gestión masiva de archivos con módulo de Backup.
    
.DESCRIPTION
    Este script organiza, renombra y mueve archivos basándose en reglas estrictas.
    Incluye un sistema de auditoría (logs), manejo de excepciones y respaldos vía Robocopy.
#>

# Forzar codificación UTF-8 en la sesión de consola
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
[System.Console]::InputEncoding = [System.Text.Encoding]::UTF8

# --- CARGAR CONFIGURACIÓN DESDE XML EXTERNO ---
$RutaConfigXml = Join-Path $PSScriptRoot "config.xml"

if (Test-Path $RutaConfigXml) {
    [xml]$ConfigXml = Get-Content -Path $RutaConfigXml -Raw
    $RutaRaizCentralizada = $ConfigXml.Configuracion.RutaRaizCentralizada
    $Opcion3DestinoXml = $ConfigXml.Configuracion.Opcion3Destino
    $RutaBackupXml = $ConfigXml.Configuracion.RutaBackup
} else {
    Write-Host "ADVERTENCIA: No se encontro 'config.xml'. Usando valores por defecto." -ForegroundColor Yellow
    $RutaRaizCentralizada = "C:\DIRECTORIO_X"
    $Opcion3DestinoXml = "C:\DIRECTORIO_X\Proyectos"
    $RutaBackupXml = "C:\DIRECTORIO_X_BACKUP" # Respaldo por defecto
}

# --- CONFIGURACIÓN GLOBAL ---
$ArchivoLog = Join-Path $RutaRaizCentralizada "bitacora_organizacion.log"
$Conectores = @("de", "del", "la", "el", "y", "en", "los", "las", "un", "una")
$FechaActual = Get-Date -Format "yyyy-MM-dd"
$MesActual = (Get-Date).ToString("MMMM_yyyy", [System.Globalization.CultureInfo]::CreateSpecificCulture("es-ES")).ToLower()

# Asegurar carpeta de logs/raíz centralizada
if (!(Test-Path $RutaRaizCentralizada)) { New-Item -ItemType Directory -Path $RutaRaizCentralizada | Out-Null }

# --- FUNCIONES ---

function Write-Log {
    param([string]$Mensaje, [string]$Tipo = "INFO")
    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $LogEntry = "[$Timestamp] [$Tipo] $Mensaje"
    Add-Content -Path $ArchivoLog -Value $LogEntry
}

function Obtener-RutaReal {
    param([string]$entrada)
    if ([string]::IsNullOrWhiteSpace($entrada)) { return $entrada }
    
    $entradaNormalizada = $entrada.Replace('/', '\')
    if (Split-Path $entradaNormalizada -IsAbsolute) { return $entradaNormalizada }

    $partes = $entradaNormalizada.Split('\')
    $primeraParte = $partes[0].ToLower()

    $pathMap = @{
        "escritorio" = "Desktop"; "desktop"    = "Desktop"
        "documentos" = "Documents"; "documents"  = "Documents"
        "descargas"  = "Downloads"; "downloads"  = "Downloads"
        "imagenes"   = "Pictures";  "pictures"   = "Pictures"
        "musica"     = "Music";     "music"      = "Music"
    }

    if ($pathMap.ContainsKey($primeraParte)) {
        $partes[0] = $pathMap[$primeraParte]
        return Join-Path $HOME ($partes -join '\')
    }

    return Join-Path $HOME $entradaNormalizada
}

function Get-NombreTransformado {
    param([string]$NombreBase, [int]$Correlativo)
    
    $n = $NombreBase.Replace(" ", "_") -replace "__+", "_"
    
    if ($n.Length -le 20) {
        $Resultado = $n
    } else {
        $Palabras = $n.Split('_')
        if ($Palabras.Count -eq 1) {
            $Resultado = $n.Substring(0, 4)
        } else {
            $Filtradas = $Palabras.Where({ $_.Length -gt 3 -and $Conectores -notcontains $_.ToLower() })
            if ($Filtradas.Count -eq 0) { 
                $Resultado = $n.Substring(0, 4) 
            } else { 
                $Resultado = ($Filtradas | ForEach-Object { $_.Substring(0, [Math]::Min(4, $_.Length)) }) -join "_" 
            }
        }
    }
    return "$($Resultado)_$($FechaActual)_$($Correlativo.ToString('D3'))"
}

function Invoke-ProcesarArchivo {
    param([System.IO.FileInfo]$Archivo, [string]$CarpetaDestino)
    
    try {
        $Extension = $Archivo.Extension.ToLower()
        $SubDir = if ($Extension -match "\.(jpg|jpeg|png|gif)$") { 
            "img_$FechaActual" 
        } elseif ($Extension -match "\.(mp3|wav|flac|m4a)$") { 
            "audio_$FechaActual" 
        } else { 
            "doc_$FechaActual" 
        }

        $DestinoFinal = Join-Path $CarpetaDestino $SubDir
        if (!(Test-Path $DestinoFinal)) { New-Item -ItemType Directory -Path $DestinoFinal | Out-Null }
        
        $Correlativo = 1
        $NuevoNombreBase = Get-NombreTransformado $Archivo.BaseName $Correlativo
        $RutaFinal = Join-Path $DestinoFinal "$($NuevoNombreBase)$($Archivo.Extension)"
        
        while (Test-Path $RutaFinal) {
            $Correlativo++
            $NuevoNombreBase = Get-NombreTransformado $Archivo.BaseName $Correlativo
            $RutaFinal = Join-Path $DestinoFinal "$($NuevoNombreBase)$($Archivo.Extension)"
        }
        
        Move-Item $Archivo.FullName $RutaFinal -ErrorAction Stop
        $Msg = "EXITO: $($Archivo.Name) -> $($NuevoNombreBase)$($Archivo.Extension)"
        Write-Host $Msg -ForegroundColor Green
        Write-Log $Msg
    } catch {
        $ErrorMsg = "ERROR al procesar $($Archivo.Name): $($_.Exception.Message)"
        Write-Host $ErrorMsg -ForegroundColor Red
        Write-Log $ErrorMsg -Tipo "ERROR"
    }
}

function Test-EsArchivoValido {
    param([System.IO.FileInfo]$Archivo)
    $Permitidas = @(".jpg", ".jpeg", ".png", ".gif", ".pdf", ".docx", ".xlsx", ".txt", ".yml", ".json", ".doc", ".html", ".rtf", ".pptx", ".mp3", ".wav", ".flac", ".m4a")
    return ($Permitidas -contains $Archivo.Extension.ToLower()) -and !($Archivo.Attributes -match "Hidden")
}

# --- MENÚ INTERACTIVO ---
do {
    # LIMPIAR LA PANTALLA ANTES DE MOSTRAR EL MENÚ
    Clear-Host

    Write-Host "`n=== ORGANIZADOR DE ARCHIVOS (ConfigXml Activo) ===" -ForegroundColor Cyan
    Write-Host "1. Organizar archivos dentro de carpeta indicada"
    Write-Host "2. Escaneo masivo automatico (Hacia: $RutaRaizCentralizada\$MesActual)"
    Write-Host "3. Guardado Personalizado (Hacia XML Destino: $Opcion3DestinoXml)"
    Write-Host "4. Buscar/Listar dentro de $RutaRaizCentralizada"
    Write-Host "5. Realizar Backup de ($RutaRaizCentralizada) a ($RutaBackupXml)" -ForegroundColor Yellow
    Write-Host "6. Salir" -ForegroundColor Red
    
    $opcion = Read-Host "Seleccione una opcion (1-6)"
    
    switch ($opcion) {
        "1" {
            $inputPath = Read-Host "Ingrese la carpeta origen (ej: Escritorio/Proyectos o C:\Ruta\Especifica)"
            Write-Log "Iniciando Opción 1 - Origen manual: $inputPath"
            
            $ExtImagenes = @(".jpg", ".jpeg", ".png", ".gif")
            $ExtAudio    = @(".mp3", ".wav", ".flac", ".m4a", ".wma")
            $ExtDocumentos = @(".pdf", ".docx", ".xlsx", ".txt", ".yml", ".json", ".doc", ".html", ".rtf", ".pptx")
            
            $fullPath = Obtener-RutaReal $inputPath
            
            if (Test-Path $fullPath) {
                $archivos = (Get-ChildItem $fullPath -File).Where({
                    !($_.Attributes -match "Hidden") -and 
                    ($ExtImagenes -contains $_.Extension.ToLower() -or 
                     $ExtAudio -contains $_.Extension.ToLower() -or 
                     $ExtDocumentos -contains $_.Extension.ToLower())
                })
                
                if ($archivos) {
                    foreach ($archivo in $archivos) { Invoke-ProcesarArchivo $archivo $fullPath }
                    Write-Log "Opcion 1 completada con exito."
                } else {
                    $noFilesMsg = "No se encontraron archivos con las extensiones permitidas en: $fullPath"
                    Write-Host $noFilesMsg -ForegroundColor Yellow
                    Write-Log $noFilesMsg -Tipo "WARN"
                }
            } else { 
                $errorPathMsg = "Ruta no valida: $fullPath"
                Write-Host $errorPathMsg -ForegroundColor Red 
                Write-Log $errorPathMsg -Tipo "ERROR"
            }
        }
        "2" {
            $DestinoBase = Join-Path $RutaRaizCentralizada $MesActual
            Write-Log "Iniciando Opcion 2 - Escaneo Masivo Automatico hacia: $DestinoBase"
            Write-Log "Escaneando Carpetas: Desktop, Downloads, Documents, Pictures, Music..."
            Write-Host "Escaneando Carpetas: Desktop, Downloads, Documents, Pictures, Music..."
            
            $Carpetas = @("Desktop", "Downloads", "Documents", "Pictures", "Music")
            foreach ($c in $Carpetas) {
                $path = Join-Path $HOME $c
                if (Test-Path $path) {
                    Write-Log "Escaneando subcarpeta: $path"
                    $archivosValidos = (Get-ChildItem $path -File).Where({ Test-EsArchivoValido $_ })
                    foreach ($av in $archivosValidos) { Invoke-ProcesarArchivo $av $DestinoBase }
                }
            }
            Write-Log "Opcion 2 completada."
        }
        "3" {
            Write-Host "--- Configuracion de Origen (Presiona Enter para usar por defecto) ---" -ForegroundColor Cyan
            $entradaOrigen = Read-Host "Ruta de origen (Ej: Desktop, Documentos o C:\Ruta) [Por defecto: $HOME]"
            $origen = if ([string]::IsNullOrWhiteSpace($entradaOrigen)) { $HOME } else { Obtener-RutaReal $entradaOrigen }
            
            $destino = $Opcion3DestinoXml
            Write-Log "Iniciando Opcion 3 - Proyecto desde origen: $origen hacia XML-Destino: $destino"

            if (!(Test-Path $destino)) {
                try {
                    New-Item -ItemType Directory -Path $destino -Force | Out-Null
                    Write-Log "Carpeta de destino XML creada: $destino"
                } catch {
                    Write-Log "No se pudo crear de forma automatizada la ruta destino: $destino" -Tipo "ERROR"
                }
            }

            if ((Test-Path $origen) -and (Test-Path $destino)) {
                $archivosValidos = (Get-ChildItem $origen -File).Where({ Test-EsArchivoValido $_ })
                foreach ($av in $archivosValidos) { Invoke-ProcesarArchivo $av $destino }
                Write-Host "Proceso completado!" -ForegroundColor Green
                Write-Log "Opcion 3 completada con exito."
            } else { 
                $errMsg = "Error: La ruta de origen o de destino XML no es valida."
                Write-Host $errMsg -ForegroundColor Red 
                Write-Log $errMsg -Tipo "ERROR"
            }
        }
        "4" {
            Write-Host "Listando archivos organizados en: $RutaRaizCentralizada" -ForegroundColor Cyan
            Write-Log "Ejecutando Opcion 4 - Visualizacion de archivos en grid en: $RutaRaizCentralizada"
            
            $elementos = (Get-ChildItem $RutaRaizCentralizada -Recurse -File).Where({ $_.Name -match "_" })
            if ($elementos) {
                $elementos | 
                    Select-Object @{N='Nombre del Archivo';E={$_.Name}}, @{N='Ruta Absoluta Actual';E={$_.FullName}} | 
                    Out-GridView
            } else {
                Write-Host "No se encontraron archivos procesados para listar." -ForegroundColor Yellow
            }
        }
        "5" {
            Write-Host "`n=== INICIANDO RESPALDO DE SEGURIDAD (Robocopy) ===" -ForegroundColor Green
            Write-Log "Iniciando Opcion 5 - Respaldo desde $RutaRaizCentralizada hacia $RutaBackupXml"

            if (Test-Path $RutaRaizCentralizada) {
                # Parámetros recomendados de Robocopy:
                # /MIR  : Modo Espejo (opcional) (Sincroniza directorios, borra en destino si se borró en origen)
                # /Z    : Copia archivos en modo reanudable (por si se cae la red o conexión)
                # /R:3  : Reintenta 3 veces si un archivo está bloqueado
                # /W:5  : Espera 5 segundos entre reintentos
                # /V    : Muestra información detallada en consola
                # /NP   : No muestra el porcentaje de progreso (acelera la copia en consola)
                # /E       : Copia todos los subdirectorios, incluidos los VACÍOS.
                # /COPY:DAT: Copia Datos, Atributos y Marcas de tiempo de forma explícita.
                
                Write-Host "Sincronizando directorios... Por favor espere." -ForegroundColor Yellow
                
                # Ejecución nativa de Robocopy segura
                & robocopy $RutaRaizCentralizada $RutaBackupXml /E /COPY:DAT /Z /R:3 /W:5 /V /NP

                # Nota: Robocopy usa códigos de salida (ExitCodes) del 0 al 7 como éxito. 
                # Cualquier valor por encima de 7 indica fallas críticas de copia.
                if ($LASTEXITCODE -le 7) {
                    $bkpMsg = "RESPALDO COMPLETADO EXITOSAMENTE. Destino: $RutaBackupXml"
                    Write-Host $bkpMsg -ForegroundColor Green
                    Write-Log $bkpMsg
                } else {
                    $bkpError = "ADVERTENCIA/ERROR en el respaldo. Codigo de salida Robocopy: $LASTEXITCODE"
                    Write-Host $bkpError -ForegroundColor Red
                    Write-Log $bkpError -Tipo "ERROR"
                }
            } else {
                $errorRaiz = "Error: La ruta raiz origen ($RutaRaizCentralizada) no existe."
                Write-Host $errorRaiz -ForegroundColor Red
                Write-Log $errorRaiz -Tipo "ERROR"
            }
        }
    }

    # PAUSA ANTES DE VOLVER A EMPEZAR EL BUCLE (Excepto si eligió salir)
    if ($opcion -ne "6" -and ![string]::IsNullOrWhiteSpace($opcion)) {
        Write-Host "`n--------------------------------------------------" -ForegroundColor Red
        Read-Host "Presione ENTER para volver al menu principal"
    }
} while ($opcion -ne "6")
