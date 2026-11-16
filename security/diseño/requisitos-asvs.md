# Requisitos de seguridad basados en OWASP ASVS 4.0.3

Se eligieron 16 requisitos de los niveles 1 y 2 de ASVS. Cubren autenticación, sesión, control de acceso, validación, secretos, registro de eventos y componentes. Se eligieron los que corresponden a lo que Juice Shop expone según el diagrama de flujo de datos. La última columna indica con qué se verifica cada requisito en el pipeline o a mano.

| ID | ASVS | Nivel | Requisito para Juice Shop | Se verifica con |
|---|---|---|---|---|
| R01 | V2.1.1 | 1 | Las contraseñas deben tener al menos 12 caracteres | Revisión manual y prueba DAST |
| R02 | V2.4.1 | 2 | Las contraseñas se guardan con un hash adaptativo con sal, no con MD5 | SAST Semgrep |
| R03 | V2.2.1 | 1 | El login y el reinicio de contraseña limitan los intentos automáticos | DAST ZAP |
| R04 | V3.5.3 | 2 | Los tokens JWT se firman con una llave que no está en el código y con un algoritmo seguro | Gitleaks y SAST |
| R05 | V4.1.1 | 1 | El control de acceso se aplica en el servidor en cada ruta | SAST y DAST ZAP |
| R06 | V4.1.3 | 1 | Cada usuario solo accede a sus propias cestas, pedidos y tarjetas | Pruebas DAST autenticadas |
| R07 | V5.3.4 | 1 | Las consultas a la base de datos son parametrizadas | SAST Semgrep |
| R08 | V5.1.3 | 1 | Toda entrada del usuario se valida y las salidas se codifican | SAST Semgrep y DAST ZAP |
| R09 | V5.2.6 | 1 | La descarga de la imagen de perfil por URL valida el destino para evitar SSRF | SAST Semgrep |
| R10 | V5.5.2 | 1 | Los analizadores XML de la subida de archivos y de B2B no resuelven entidades externas | SAST Semgrep |
| R11 | V6.4.1 | 2 | Las llaves y secretos no se guardan en el repositorio y se gestionan fuera del código | Gitleaks |
| R12 | V7.1.1 | 1 | Los registros no incluyen credenciales ni datos de pago | Revisión manual |
| R13 | V7.2.1 | 2 | Se registran las decisiones de autenticación, tanto exitosas como fallidas | Revisión manual |
| R14 | V9.1.1 | 1 | Toda la conectividad del cliente usa TLS | DAST ZAP y revisión de IaC |
| R15 | V12.5.2 | 1 | Los archivos subidos y los directorios `/ftp` y `/support/logs` no se pueden listar ni descargar de forma directa | DAST ZAP |
| R16 | V14.2.1 | 1 | Todas las dependencias están actualizadas y sin vulnerabilidades críticas conocidas | SCA con Grype y Dependabot |

Cada requisito se enlaza más adelante a una amenaza del modelo STRIDE y a un control del pipeline en la matriz de trazabilidad de la fase 2.
