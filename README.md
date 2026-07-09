# 📂 Organizador de Archivos - `orden_doc.ps1`

Un script en **PowerShell** para ordenar y organizar archivos de manera rápida y flexible.  
Permite clasificar documentos, imágenes y audios en directorios definidos por el usuario o configurados en un archivo `config.xml`.

---

## 🚀 Características principales

- **Menú interactivo** con 5 opciones:
  1. **Organizar archivos dentro de carpeta indicada**
     - El usuario escribe la ruta del directorio y el script ordena los archivos automáticamente.

![opcion 1](https://github.com/jullianamigoes/assets_proj/blob/main/assets/ps1_orden/op_1.gif)
       
  2. **Escaneo masivo automático**  
     - Escanea directorios comunes del usuario (Documentos, Escritorio, Imágenes, etc.)  
     - Ordena y almacena en una ruta configurada en `config.xml`.

![opcion 2](https://github.com/jullianamigoes/assets_proj/blob/main/assets/ps1_orden/op_2.gif)
     
  3. **Guardado personalizado (XML destino)**  
     - Permite definir un directorio de origen y guarda los archivos en un destino personalizado definido en `config.xml`.

![ opcion 3 ](https://github.com/jullianamigoes/assets_proj/blob/main/assets/ps1_orden/op_3.gif)
     
  4. **Buscar/Listar archivos**  
     - Accede a la ubicación de los archivos listados en una tabla obtenida desde el log.
  5. **Salir**  
     - Cierra la terminal.
    
![ opcion 4_y_5 ](https://github.com/jullianamigoes/assets_proj/blob/main/assets/ps1_orden/4_5.gif)

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

## Y listo!
