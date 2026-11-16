# Clasificación de datos

Se usan tres niveles. **Crítico** es lo que permite suplantar a alguien o mover dinero. **Confidencial** son datos personales. **Interno** es información de la aplicación que no debería ser pública pero no identifica a nadie. Lo que se muestra a cualquier visitante es **Público**.

| Dato | Dónde se guarda | Campos | Nivel | Estado actual en Juice Shop |
|---|---|---|---|---|
| Credenciales | SQLite, tabla Users | email, password | Crítico | La contraseña se guarda con MD5 sin sal |
| Secreto de segundo factor | SQLite, tabla Users | totpSecret | Crítico | Se guarda en la misma tabla, sin cifrar |
| Llave de firma del JWT | `lib/insecurity.ts` | llave privada RSA | Crítico | Está escrita en el código fuente |
| Token de sesión JWT | Navegador y cabecera HTTP | token firmado RS256 | Crítico | Viaja por HTTP sin TLS |
| Datos de tarjeta | SQLite, tabla Cards | fullName, cardNum, expMonth, expYear | Crítico | El número de tarjeta se guarda completo |
| Saldo de billetera | SQLite, tabla Wallets | balance | Crítico | Se modifica desde la API |
| Datos personales | SQLite, tablas Users y Addresses | username, email, lastLoginIp, fullName, mobileNum, dirección | Confidencial | Se guardan sin cifrar |
| Pedidos | MarsDB | productos, total, correo | Confidencial | Se guardan en memoria |
| Quejas y archivos adjuntos | SQLite y `uploads/complaints` | message, file | Confidencial | El archivo se guarda con lo que sube el usuario |
| Llaves y archivos internos | `encryptionkeys`, `ftp`, `ctf.key` | llaves y documentos | Interno | Están en el repositorio y en el disco |
| Registros de la aplicación | `logs/` | accesos y errores | Interno | Se pueden listar desde `/support/logs` |
| Reseñas y comentarios | MarsDB y SQLite | texto, valoración | Público | Se guardan tal como llegan en la solicitud |
| Catálogo de productos | SQLite | nombre, precio, imagen | Público | Cualquiera puede consultarlo |

Juice Shop no maneja datos reales y todo se genera con datos de ejemplo. La clasificación sirve para decidir qué controles se exigen, por ejemplo los requisitos V2, V6, V8 y V9 de ASVS.
