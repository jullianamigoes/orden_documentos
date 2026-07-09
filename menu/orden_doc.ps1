<#
.SYNOPSIS
    OrganizadorPro: Script de automatización para gestión masiva de archivos.
    
.DESCRIPTION
    Este script organiza, renombra y mueve archivos basándose en reglas estrictas
    de nomenclatura, filtrado de conectores y estructuración por fechas.
    Incluye un sistema de auditoría (logs) y manejo robusto de excepciones.
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
} else {
    # Valores de respaldo por si el archivo XML no existe en la ruta
    Write-Host "ADVERTENCIA: No se encontró 'config.xml'. Usando valores por defecto." -ForegroundColor Yellow
    $RutaRaizCentralizada = "C:\DIRECTORIO_X"
    $Opcion3DestinoXml = "C:\DIRECTORIO_X\Proyectos"
}

# --- CONFIGURACIÓN GLOBAL ---
$ArchivoLog = Join-Path $RutaRaizCentralizada "bitacora_organizacion.log"
$Conectores = @("de", "del", "la", "el", "y", "en", "los", "las", "un", "una")
$FechaActual = Get-Date -Format "yyyy-MM-dd"
$MesActual = (Get-Date).ToString("MMMM", [System.Globalization.CultureInfo]::CreateSpecificCulture("es-ES"))

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
    if ($entrada -ieq "escritorio" -or $entrada -ieq "desktop") { return Join-Path $HOME "Desktop" }
    if ($entrada -ieq "documentos" -or $entrada -ieq "documents") { return Join-Path $HOME "Documents" }
    if ($entrada -ieq "descargas" -or $entrada -ieq "downloads") { return Join-Path $HOME "Downloads" }
    if ($entrada -ieq "imagenes" -or $entrada -ieq "pictures") { return Join-Path $HOME "Pictures" }
    return $entrada
}

function Get-NombreTransformado {
    param([string]$NombreBase, [int]$Correlativo)
    
    # Lógica de Limpieza: Reemplaza espacios por guiones y reduce dobles guiones
    $n = $NombreBase.Replace(" ", "_") -replace "__+", "_"
    
    # Regla de longitud y filtrado
    if ($n.Length -le 20) {
        $Resultado = $n
    } else {
        $Palabras = $n.Split('_')
        if ($Palabras.Count -eq 1) {
            $Resultado = $n.Substring(0, 4)
        } else {
            $Filtradas = $Palabras | Where-Object { $_.Length -gt 3 -and $Conectores -notcontains $_.ToLower() }
            
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
        # Nueva clasificación de tres vías: imágenes, audios o documentos
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
        
        # Bucle de Control de Duplicados
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
    $Permitidas = @(".jpg", ".jpeg", ".png", ".gif", ".pdf", ".docx", ".xlsx", ".txt", ".yml", ".json", ".doc", ".html", ".mp3", ".wav", ".flac", ".m4a")
    return ($Permitidas -contains $Archivo.Extension.ToLower()) -and !($Archivo.Attributes -match "Hidden")
}

# --- MENÚ INTERACTIVO ---
do {
    Write-Host "`n=== ORGANIZADOR DE ARCHIVOS (ConfigXml Activo) ===" -ForegroundColor Cyan
    Write-Host "1. Organizar archivos dentro de carpeta indicada"
    Write-Host "2. Escaneo masivo automatico (Hacia: $RutaRaizCentralizada\$MesActual)"
    Write-Host "3. Guardado Personalizado (Hacia XML Destino: $Opcion3DestinoXml)"
    Write-Host "4. Buscar/Listar dentro de carpeta centralizada"
    Write-Host "5. Salir" -ForegroundColor Yellow
    
    $opcion = Read-Host "Seleccione una opcion (1-5)"
    
    switch ($opcion) {
        "1" {
            $inputPath = Read-Host "Ingrese la carpeta origen (ej: Escritorio/Proyectos o Desktop/Proyectos)"
            Write-Log "Iniciando Opción 1 - Origen manual: $inputPath"
            
            # --- DEFINICIÓN DE EXTENSIONES PERMITIDAS ---
            $ExtImagenes = @(".jpg", ".jpeg", ".png", ".gif")
            $ExtAudio    = @(".mp3", ".wav", ".flac", ".m4a", ".wma")
            $ExtDocumentos = @(".pdf", ".docx", ".xlsx", ".txt", ".yml", ".json", ".doc", ".html")
            
            $pathMap = @{
                "escritorio" = "Desktop"
                "descargas"  = "Downloads"
                "documentos" = "Documents"
                "imagenes"   = "Pictures"
                "musica"     = "Music" # Opcional: añadida traducción por si escriben "musica"
            }
            
            $partes = $inputPath.Split('/')
            $primeraParte = $partes[0].ToLower()
            
            if ($pathMap.ContainsKey($primeraParte)) {
                $partes[0] = $pathMap[$primeraParte]
            }
            
            $fullPath = Join-Path $HOME ($partes -join '\')
            
            if (Test-Path $fullPath) {
                # Se añade el filtro para incluir las extensiones de audio ($ExtAudio)
                $archivos = Get-ChildItem $fullPath -File | Where-Object { 
                    !($_.Attributes -match "Hidden") -and 
                    ($ExtImagenes -contains $_.Extension.ToLower() -or 
                     $ExtAudio -contains $_.Extension.ToLower() -or 
                     $ExtDocumentos -contains $_.Extension.ToLower())
                }
                
                if ($archivos) {
                    foreach ($archivo in $archivos) {
                        Invoke-ProcesarArchivo $archivo $fullPath
                    }
                    Write-Log "Opción 1 completada con éxito."
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
            Write-Log "Iniciando Opción 2 - Escaneo Masivo Automático hacia: $DestinoBase"
            
            $Carpetas = @("Desktop", "Downloads", "Documents", "Pictures")
            
            foreach ($c in $Carpetas) {
                $path = Join-Path $HOME $c
                if (Test-Path $path) {
                    Write-Log "Escaneando subcarpeta: $path"
                    Get-ChildItem $path -File | Where-Object { Test-EsArchivoValido $_ } | ForEach-Object { 
                        Invoke-ProcesarArchivo $_ $DestinoBase 
                    }
                }
            }
            Write-Log "Opción 2 completada."
        }
        "3" {
            Write-Host "--- Configuración de Origen (Presiona Enter para usar por defecto) ---" -ForegroundColor Cyan
            
            # 1. Solicitar SOLO Origen
            $entradaOrigen = Read-Host "Ruta de origen (Ej: Desktop, Documentos o C:\Ruta) [Por defecto: $HOME]"
            
            if ([string]::IsNullOrWhiteSpace($entradaOrigen)) {
                $origen = $HOME
            } else {
                $entradaOrigen = Obtener-RutaReal $entradaOrigen
                if (Split-Path $entradaOrigen -IsAbsolute) {
                    $origen = $entradaOrigen
                } else {
                    $origen = Join-Path $HOME $entradaOrigen
                }
            }

            # 2. El Destino se lee directamente de la variable del XML
            $destino = $Opcion3DestinoXml
            Write-Log "Iniciando Opción 3 - Proyecto desde origen: $origen hacia XML-Destino: $destino"

            # Crear la carpeta de destino automáticamente si no existe
            if (!(Test-Path $destino)) {
                try {
                    New-Item -ItemType Directory -Path $destino -Force | Out-Null
                    Write-Log "Carpeta de destino XML creada: $destino"
                } catch {
                    Write-Log "No se pudo crear de forma automatizada la ruta destino: $destino" -Tipo "ERROR"
                }
            }

            # 3. Procesar
            Write-Host "`nProcesando desde: $origen" -ForegroundColor Yellow
            Write-Host "Destino XML establecido: $destino`n" -ForegroundColor Yellow

            if ((Test-Path $origen) -and (Test-Path $destino)) {
                Get-ChildItem $origen -File | Where-Object { Test-EsArchivoValido $_ } | ForEach-Object { 
                    Invoke-ProcesarArchivo $_ $destino 
                }
                Write-Host "Proceso completado!" -ForegroundColor Green
                Write-Log "Opción 3 completada con éxito."
            } else { 
                $errMsg = "Error: La ruta de origen o de destino XML no es válida."
                Write-Host $errMsg -ForegroundColor Red 
                Write-Log $errMsg -Tipo "ERROR"
            }
        }
        "4" {
            Write-Host "Listando archivos organizados en: $RutaRaizCentralizada" -ForegroundColor Cyan
            Write-Log "Ejecutando Opción 4 - Visualización de archivos en grid en: $RutaRaizCentralizada"
            
            $elementos = Get-ChildItem $RutaRaizCentralizada -Recurse -File | Where-Object { $_.Name -match "_" }
            
            if ($elementos) {
                $elementos | 
                    Select-Object @{N='Nombre del Archivo';E={$_.Name}}, @{N='Ruta Absoluta Actual';E={$_.FullName}} | 
                    Out-GridView
            } else {
                Write-Host "No se encontraron archivos procesados para listar." -ForegroundColor Yellow
            }
        }
    }
} while ($opcion -ne "5")