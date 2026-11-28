# Política de bloqueo

Este documento define qué bloquea el merge a `main` y qué solo avisa en cada etapa del pipeline. Todos los bloqueos son pasos reales de los workflows, sin `|| true` ni `continue-on-error`.

## Criterio general

Juice Shop es vulnerable a propósito, así que si el umbral se aplicara sobre todo el código ninguna pull request podría pasar. Por eso cada etapa bloquea solo lo que el cambio introduce, comparando contra un punto de partida:

- SAST y secretos comparan contra el commit base de la pull request.
- SCA e imagen comparan contra una línea base guardada en `security/sbom/`.
- DAST usa el archivo `.zap/rules.tsv`. Las reglas que hoy no generan alertas están en FAIL y las que ya generaban alertas están en WARN.

Lo que ya existía se reporta en el SARIF, en Code scanning y en DefectDojo y se corrige por pull request en la fase de remediación. Cuando un hallazgo se corrige, su línea base se actualiza en la misma pull request y, en DAST, su regla pasa de WARN a FAIL para que no vuelva.

## Qué bloquea y qué avisa

| Etapa | Herramienta | Bloquea el merge | Solo avisa |
|---|---|---|---|
| Secretos | Gitleaks | Un secreto nuevo en cualquier commit del pull request o del push | Rutas de pruebas y datos de ejemplo, que están en `.gitleaks.toml` |
| SAST | Semgrep | Un hallazgo nuevo de severidad ERROR respecto del commit base | Hallazgos WARNING e INFO y los que ya existían |
| SCA | Syft y Grype | Una vulnerabilidad High o Critical que no está en la línea base, o un componente con licencia GPL o AGPL | Vulnerabilidades Medium y Low y las de la línea base |
| IaC | Checkov y ansible-lint | Cualquier falla de Checkov en `infra`, `ansible` o `docker` y cualquier incumplimiento del perfil production de ansible-lint | Nada, el repositorio está en cero fallas |
| Build | Docker | La imagen no se construye o no queda healthy | No aplica |
| Imagen | Trivy | High o Critical con corrección en los paquetes del sistema, o una High o Critical nueva en las dependencias de Node | Las vulnerabilidades de la línea base y las sin corrección |
| DAST | ZAP baseline | Una alerta de cualquiera de las reglas en FAIL de `.zap/rules.tsv`, o un error de ZAP | Las reglas en WARN y las informativas |
| Publicación | DefectDojo y Dependency-Track | Nunca | Todo, la importación no decide el merge |

## Protección de la rama main

- Todo cambio entra por pull request, no se permite el push directo.
- La regla aplica también a los administradores.
- Son obligatorios los checks Secretos, SAST, SCA, Build de la imagen, Imagen, DAST y Escaneo IaC. Una pull request con alguno en rojo no se puede fusionar.

## Excepciones

Una excepción es un hallazgo que se acepta y no se corrige. Cada una debe quedar escrita y con dueño, y se maneja así según la herramienta:

| Caso | Dónde se documenta | Qué debe incluir |
|---|---|---|
| Vulnerabilidad de dependencia que no se puede explotar | `security/vex/openvex.json`, declaración `not_affected` con su justificación | Componente, CVE y por qué el código vulnerable no se ejecuta |
| Hallazgo de infraestructura que se acepta | Comentario `checkov:skip` o `ansible-lint` junto al código con el motivo | Regla, motivo y condición para revisarla |
| Falso positivo de secretos | `.gitleaks.toml`, lista permitida | Ruta o patrón y motivo |
| Hallazgo de DAST ya existente | Regla en WARN en `.zap/rules.tsv` | Se lista en el informe y se corrige después |
| Cualquier hallazgo en DefectDojo | Estado Risk Accepted o False Positive con nota | Motivo y fecha de revisión |

Las excepciones se revisan cuando cambia la versión del componente o al menos al cerrar cada fase del proyecto.

## Cómo se prioriza

1. Primero lo que aparece en el catálogo CISA KEV o tiene EPSS alto.
2. Después lo que tiene relación directa con una amenaza del modelo, como T04 en la búsqueda o T12 en la subida de XML.
3. Después la severidad del reporte y por último los hallazgos Low e informativos.
