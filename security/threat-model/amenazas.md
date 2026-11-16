# Modelo de amenazas STRIDE de OWASP Juice Shop

El modelo está en [juice-shop.json](juice-shop.json) y se abre con OWASP Threat Dragon. Contiene el DFD de nivel 0 y 1 con las 20 amenazas asociadas a cada elemento. Impacto y probabilidad van de 1 a 3 y el riesgo es su producto. De 6 a 9 la prioridad es alta, de 3 a 4 media y de 1 a 2 baja.

## Amenazas

| ID | Elemento | STRIDE | Escenario | Imp. | Prob. | Riesgo | Prioridad |
|---|---|---|---|---|---|---|---|
| T01 | Catálogo, búsqueda, registro y login | Spoofing | El login arma la consulta SQL con el correo que escribe el usuario. Con un correo como admin@juice-sh.op'-- el atacante entra como administrador sin conocer la contraseña. | 3 | 3 | 9 | Alta |
| T02 | API REST | Spoofing | La llave privada RSA que firma los JWT está escrita en lib/insecurity.ts. Cualquiera que lea el repositorio puede firmar un token con el rol admin y la API lo acepta. | 3 | 3 | 9 | Alta |
| T03 | API REST | Tampering | La ruta PUT /api/Products/:id no tiene el control isAuthorized, que está comentado en server.ts. Cualquier usuario puede cambiar el precio o la descripción de un producto. | 2 | 3 | 6 | Alta |
| T04 | API REST | Tampering | La búsqueda de productos concatena el criterio en la consulta SQL. Con un UNION el atacante lee otras tablas, como los usuarios, o altera datos. | 3 | 3 | 9 | Alta |
| T05 | API REST | Tampering | La descripción de un producto se muestra con innerHTML en el frontend. Si el atacante la cambia con la ruta de T03, el script se ejecuta en el navegador de quien abra el producto. | 2 | 2 | 4 | Media |
| T06 | API REST | Repudiation | Al crear una reseña el servidor toma el autor del cuerpo de la petición y no del JWT. Un usuario publica a nombre de otro y la víctima no puede probar que no fue ella. | 2 | 3 | 6 | Alta |
| T07 | Sistema de archivos | Repudiation | El log de accesos de Morgan guarda IP y ruta, pero no el usuario del JWT ni el resultado del login. Tras un abuso no se puede demostrar quién hizo cada acción. | 2 | 2 | 4 | Media |
| T08 | Servidor de contenido | Information disclosure | El directorio /ftp se puede listar y descargar sin autenticación. Contiene un respaldo de dependencias, un archivo .kdbx y otros documentos internos. | 2 | 3 | 6 | Alta |
| T09 | Servidor de contenido | Information disclosure | El directorio /support/logs se lista sin autenticación y entrega los logs de acceso con IP y rutas consultadas, que sirven para preparar otros ataques. | 2 | 3 | 6 | Alta |
| T10 | Base SQLite | Information disclosure | Las contraseñas se guardan con MD5 sin sal y el número de tarjeta se guarda completo. Si el archivo juiceshop.sqlite se filtra, las contraseñas se descifran con tablas y las tarjetas quedan expuestas. | 3 | 2 | 6 | Alta |
| T11 | Descarga de imagen por URL | Information disclosure | La API descarga con fetch cualquier URL que el usuario indique como imagen de perfil. El atacante apunta a servicios internos o al localhost del contenedor y lee la respuesta. | 3 | 2 | 6 | Alta |
| T12 | API REST | Information disclosure | El analizador de XML de la subida de archivos tiene habilitadas las entidades externas. Un XML con una entidad file:///etc/passwd devuelve el contenido del archivo del servidor. | 3 | 3 | 9 | Alta |
| T13 | Catálogo, búsqueda, registro y login | Denial of service | Solo el reinicio de contraseña y el segundo factor tienen límite de peticiones. El login no lo tiene, por lo que un script prueba contraseñas sin freno y consume recursos del proceso. | 2 | 3 | 6 | Alta |
| T14 | API REST | Denial of service | La subida de archivos acepta XML y YAML que se procesan en el mismo hilo de Node. Un XML con entidades anidadas o un YAML con alias recursivos consume CPU y deja la aplicación sin responder. | 2 | 2 | 4 | Media |
| T15 | API REST | Elevation of privilege | El modelo de usuario acepta admin como valor del campo role al registrarse. Un visitante envía role admin en POST /api/Users y obtiene una cuenta de administrador. | 3 | 3 | 9 | Alta |
| T16 | Cesta, pedidos, pagos y perfil | Elevation of privilege | La ruta /rest/basket/:id solo exige estar autenticado y no comprueba que la cesta sea del usuario. Cambiando el id se ven y modifican cestas ajenas. | 2 | 3 | 6 | Alta |
| T17 | Pedidos B2B | Elevation of privilege | Los pedidos B2B evalúan el campo orderLinesData dentro de un vm con notevil. Una evasión del sandbox ejecuta código en el contenedor. | 3 | 2 | 6 | Alta |
| T18 | API REST | Tampering | Al descomprimir un zip la ruta se valida con includes en vez de comparar el directorio base. Un archivo con ../ en el nombre sobrescribe archivos fuera de uploads, como ftp/legal.md. | 3 | 2 | 6 | Alta |
| T19 | Datos personales y token JWT | Information disclosure | Toda la comunicación viaja por HTTP sin TLS. Un atacante en la misma red lee el token JWT y los datos personales de las respuestas y reutiliza la sesión. | 3 | 2 | 6 | Alta |
| T20 | API REST | Elevation of privilege | El package.json fija versiones muy antiguas como jsonwebtoken 0.4.0, express-jwt 0.1.3 y sanitize-html 1.4.2. Tienen vulnerabilidades públicas que se pueden explotar contra la API. | 3 | 2 | 6 | Alta |

## Matriz de trazabilidad

| ID | Mitigación | Requisito ASVS | Control del pipeline que lo verifica |
|---|---|---|---|
| T01 | Usar consultas parametrizadas con replacements de Sequelize y no concatenar datos del usuario. | R07 | SAST Semgrep y DAST ZAP |
| T02 | Sacar la llave del código, cargarla desde un secreto del entorno y rotarla. | R04, R11 | Gitleaks y SAST Semgrep |
| T03 | Activar la autenticación en la ruta y restringirla al rol administrador. | R05 | SAST Semgrep y DAST ZAP |
| T04 | Parametrizar la consulta de búsqueda y validar el largo y los caracteres del criterio. | R07, R08 | SAST Semgrep y DAST ZAP |
| T05 | Sanitizar la descripción al guardarla y mostrarla como texto, sin innerHTML. | R08 | SAST Semgrep y DAST ZAP |
| T06 | Tomar el autor del token verificado en el servidor e ignorar el campo del cliente. | R05, R13 | SAST Semgrep y revisión manual |
| T07 | Registrar el id del usuario, el resultado de cada autenticación y los cambios de administración. | R13 | Revisión manual |
| T08 | Quitar el listado de directorios y sacar de la imagen los archivos que no deben ser públicos. | R15 | DAST ZAP |
| T09 | Quitar la ruta pública o protegerla con autenticación y rol de administrador. | R15, R12 | DAST ZAP |
| T10 | Usar un hash adaptativo con sal como bcrypt o argon2 y no guardar el número completo de la tarjeta. | R02 | SAST Semgrep |
| T11 | Validar el destino con una lista de hosts permitidos y bloquear IP privadas y de loopback. | R09 | SAST Semgrep |
| T12 | Desactivar la resolución de entidades externas y de DTD en el analizador. | R10 | SAST Semgrep |
| T13 | Aplicar express-rate-limit al login y a las rutas de registro. | R03 | DAST ZAP |
| T14 | Desactivar entidades en el XML, limitar el tamaño y la profundidad y mantener el tiempo máximo de proceso. | R10, R08 | SAST Semgrep |
| T15 | Ignorar el campo role del cliente y asignar customer en el servidor. | R05 | SAST Semgrep y DAST ZAP |
| T16 | Comparar el id de la cesta con el usuario del JWT antes de responder. | R06 | DAST ZAP autenticado |
| T17 | No evaluar datos del usuario como código y validar el pedido contra un esquema JSON. | R08 | SAST Semgrep |
| T18 | Resolver la ruta final y comprobar que empieza por el directorio de destino antes de escribir. | R08, R05 | SAST Semgrep |
| T19 | Publicar la aplicación detrás de un proxy con TLS y activar la cabecera Strict-Transport-Security. | R14 | DAST ZAP e IaC con Checkov |
| T20 | Actualizar las dependencias a versiones sin vulnerabilidades críticas y vigilarlas con Dependabot. | R16 | SCA con Syft y Grype, y Dependabot |
