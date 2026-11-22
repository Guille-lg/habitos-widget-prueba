# Hábitos — prueba de widget para iPhone

Prueba mínima de una app nativa de iPhone y un widget interactivo de agua. iOS 17 o posterior. Sin datos personales, cuentas de usuario, servidores ni credenciales en el proyecto.

## Qué comprobar en el teléfono

1. Instalar `Habitos.ipa` con SideStore, **conservando la extensión del widget** y sus App Groups.
2. Abrir Hábitos una vez y comprobar que no aparece un error de almacenamiento compartido.
3. Añadir el widget **Agua** de Hábitos a la pantalla de inicio.
4. Pulsar el botón del widget dos veces. Debe mostrar **1 / 3 L** sin abrir la app.
5. Abrir Hábitos: debe mostrar el mismo litro. Cerrar y volver a abrir para verificar persistencia.

Se necesita una cuenta gratuita de Apple para firmar la instalación en SideStore. La firma se renueva cada siete días. La configuración inicial de SideStore desde Windows requiere iloader, los controladores de Apple, un cable USB y la intervención del propietario para iniciar sesión y confirmar los ajustes del iPhone. No subir contraseñas, certificados, perfiles, UDID ni archivos de emparejamiento a este repositorio.

## Compilación

GitHub Actions ejecuta las pruebas de almacenamiento, compila la app y el widget para dispositivo y genera una IPA con firma ad hoc local. **Esa firma solo conserva los entitlements para el instalador; SideStore debe volver a firmarla con la cuenta del propietario antes de instalar.**

El proyecto Xcode se genera con `python3 scripts/generate_project.py` sin dependencias externas. La compilación se lanza manualmente. El artefacto se conserva dos días.

## Almacenamiento

App y widget leen y escriben el mismo App Group. Cada toque crea un archivo inmutable, evitando que dos procesos sobrescriban sus contadores. El día cambia a medianoche en la zona del dispositivo. El widget usa AppIntent con `openAppWhenRun = false`. La lectura del identificador real del grupo se hace desde los entitlements firmados, para admitir los cambios de identificador de SideStore.

Esta prueba todavía necesita validarse en un iPhone físico; un build correcto no demuestra que la firma y el widget funcionen juntos en el dispositivo.
