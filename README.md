# 📂 Organizador de Archivos - `orden_doc.ps1`

Un script en **PowerShell** para ordenar y organizar archivos de manera rápida y flexible.  
Permite clasificar documentos, imágenes y audios en directorios definidos por el usuario configurados en el archivo `config.xml`.

---

## 🚀 Características principales

- **Menú interactivo** con 5 opciones (más la opción salir):
  1. **Organizar archivos dentro de carpeta indicada**
     - Escribe la ruta del directorio que quieres ordenar y el script organizará los archivos automáticamente.

![opcion 1](https://github.com/jullianamigoes/assets_proj/blob/main/assets/ps1_orden/op_1.gif)
       
  2. **Escaneo masivo automático**  
     - Escanea directorios comunes del usuario (Documentos, Escritorio, Imágenes, Musica, Descarga.)  
     - Ordena y almacena en una ruta configurada en `config.xml`.

![opcion 2](https://github.com/jullianamigoes/assets_proj/blob/main/assets/ps1_orden/op_2.gif)
     
  3. **Guardado personalizado (XML destino)**  
     - Permite definir un directorio de origen y guarda los archivos en un destino personalizado definido en `config.xml`.

![ opcion 3 ](https://github.com/jullianamigoes/assets_proj/blob/main/assets/ps1_orden/op_3.gif)
     
  4. **Buscar/Listar archivos**  
     - Accede a la ubicación de los archivos listados en una tabla obtenida desde el log.

![ opcion 4 ](https://github.com/jullianamigoes/assets_proj/blob/main/assets/ps1_orden/op_4.gif)
       
  5. **Realizar Backup de (directorio base) a (ruta de directorio para respaldo)**  
     - Se generará un respaldo de todo el contenido del directorio base (RutaRaizCentralizada de config.xml) y lo copiará a la ruta de respaldo (RutaBackup de config.xml).
    
![ opcion 5 ](https://github.com/jullianamigoes/assets_proj/blob/main/assets/ps1_orden/op_5.gif)

  6. **Salir**  
     - Cierra la terminal.

---

## 📦 Requisitos

- Windows 10 o superior  
- PowerShell 5.1+  

---

## ⚙️ Instalación y uso

1. Clona este repositorio:
   ```bash
   git clone https://github.com/tuusuario/orden_doc.git

**O descargas el archivo comprimido y lo descomprimes**

2. Abre el archivo config.xml

![config.xml](https://github.com/jullianamigoes/assets_proj/blob/main/assets/ps1_orden/config.png)

3. Define las rutas raiz (para la opción 2) y ruta personalizada (para opción 3). Pon el nombre que quieras.

![personalizar rutas xml](https://github.com/jullianamigoes/assets_proj/blob/main/assets/ps1_orden/personalizar.png)

4. Selecciona el archivo orden_doc.ps1 y con clic derecho selecciona la opcion ***Ejecutar con PowerShell***

![Ejecutar script](https://github.com/jullianamigoes/assets_proj/blob/main/assets/ps1_orden/ejecutar_archivo.gif)

**Y listo!**

---

## Consideraciones:

    - No organiza archivos de Video.
    - Solo organiza los archivos con extensiones más comunes. Obviamente puedes modificar el código para agregar los archivos que más necesites.
    - Esta es la lista de archivos que SI organiza:
***".jpg", ".jpeg", ".png", ".gif", ".pdf", ".docx", ".xlsx", ".txt", ".yml", ".json", ".doc", ".html", ".rtf", ".pptx", ".mp3", ".wav", ".flac", ".m4a"***


