# Juice Shop con desarrollo seguro

Este repositorio es un fork de [OWASP Juice Shop](https://github.com/juice-shop/juice-shop) al que se le agregó un ciclo de desarrollo seguro completo para el proyecto final del curso de Ciberseguridad de la Universidad Galileo. El README original de Juice Shop está en [README-juice-shop.md](README-juice-shop.md).

Juice Shop es vulnerable a propósito. Por eso el pipeline no exige cero hallazgos, bloquea los hallazgos nuevos que introduce cada cambio. La regla completa está en [security/politica-de-bloqueo.md](security/politica-de-bloqueo.md).

## Estructura

| Ruta | Contenido |
|---|---|
| `.github/workflows/devsecops.yml` | Pipeline principal: secretos, SAST, SCA, build, imagen, DAST y publicación |
| `.github/workflows/iac-security.yml` | Escaneo de la infraestructura como código |
| `.github/workflows/dast-completo.yml` | Escaneo completo y autenticado de ZAP, semanal y a pedido |
| `.github/dependabot.yml` | Actualizaciones de npm, GitHub Actions y Docker |
| `.semgrep/juice-shop.yml` | Reglas propias de Semgrep ligadas al modelo de amenazas |
| `.zap/rules.tsv` y `.zap/plan.yaml` | Reglas de ZAP baseline y plan del Automation Framework |
| `infra/` | Terraform, Ansible, Dockerfile endurecido en `infra/docker/` y Dependency-Track |
| `security/diseño/` | Arquitectura, DFD y requisitos ASVS |
| `security/threat-model/` | Modelo de Threat Dragon y tabla de amenazas |
| `security/sbom/` y `security/vex/` | SBOM, líneas base y declaraciones VEX |
| `security/dast/` | Reportes de ZAP |
| `security/defectdojo/importar.sh` | Importación de los reportes en DefectDojo |
| `security/politica-de-bloqueo.md` | Qué bloquea y qué avisa |
| `docs/` | Informes en PDF |

## Pipeline en GitHub Actions

Se ejecuta en cada pull request hacia `main`, en cada push a `main` y de forma manual. Las etapas son:

1. Secretos con Gitleaks.
2. SAST con Semgrep, con salida SARIF a Code scanning.
3. SCA con Syft y Grype, SBOM en CycloneDX, VEX y licencias.
4. Build de la imagen de `infra/docker/Dockerfile`.
5. IaC con Checkov y ansible-lint, e imagen con Trivy.
6. DAST con ZAP baseline contra la imagen levantada en el runner.
7. Publicación de los reportes en DefectDojo y del SBOM en Dependency-Track.

La publicación solo actúa si existen los secretos `DEFECTDOJO_URL`, `DEFECTDOJO_TOKEN`, `DTRACK_URL` y `DTRACK_API_KEY`. Sin ellos el pipeline sigue sin error.

## Cómo ejecutar todo en local

Se necesita Docker. Todos los comandos se ejecutan desde la raíz del repositorio.

**SAST con Semgrep**

```bash
docker run --rm -v "$PWD:/src" -w /src semgrep/semgrep:1.185.0 semgrep scan \
  --config .semgrep/juice-shop.yml --config p/default --config p/owasp-top-ten --metrics=off
```

**Secretos con Gitleaks.** Revisa los commits que tu rama agrega respecto de `main`, igual que el pipeline:

```bash
docker run --rm -v "$PWD:/repo" zricethezav/gitleaks:v8.30.1 detect --source /repo --config /repo/.gitleaks.toml --log-opts "origin/main..HEAD"
```

**SBOM y vulnerabilidades**

```bash
docker run --rm -v "$PWD:/src" anchore/syft:v1.57.1 /src -o cyclonedx-json=/src/sbom.cdx.json
docker run --rm -v "$PWD:/src" anchore/grype:v0.121.3 sbom:/src/sbom.cdx.json --vex /src/security/vex/openvex.json
```

**Build y DAST**

```bash
docker build -f infra/docker/Dockerfile -t juice-shop:ci .
docker network create dast
docker run -d --name juice --network dast juice-shop:ci
mkdir zap-salida && cp .zap/rules.tsv zap-salida/ && chmod 777 zap-salida
docker run --rm --network dast -v "$PWD/zap-salida:/zap/wrk:rw" ghcr.io/zaproxy/zaproxy:stable \
  zap-baseline.py -t http://juice:3000 -c rules.tsv -J baseline.json -r baseline.html -x baseline.xml -m 3
```

El código de salida de ZAP es 0 sin alertas, 2 si solo hay avisos y 1 si alguna regla en FAIL se cumple.

**Escaneo completo y autenticado.** Crea un usuario de prueba en la aplicación, inicia sesión para obtener el JWT y lo pasa al plan:

```bash
docker run --rm --network dast -e OBJETIVO=http://juice:3000 -e ZAP_TOKEN="$TOKEN" \
  -v "$PWD/zap-salida:/zap/wrk:rw" ghcr.io/zaproxy/zaproxy:stable zap.sh -cmd -autorun /zap/wrk/plan.yaml
```

Antes hay que copiar `.zap/plan.yaml` y `swagger.yml` a `zap-salida/`. El workflow `dast-completo.yml` hace todo esto solo.

**DefectDojo.** Se levanta con el `docker compose` del [repositorio oficial](https://github.com/DefectDojo/django-DefectDojo). Con una URL y un token de la API se importan los reportes descargados del pipeline:

```bash
DEFECTDOJO_URL=http://localhost:8080 DEFECTDOJO_TOKEN=... security/defectdojo/importar.sh carpeta-con-reportes
```

**Dependency-Track.** `infra/dependency-track/docker-compose.yml` lo levanta en local. Las contraseñas van en un archivo `.env` que no se sube al repositorio.

## Protección de la rama main

`main` solo recibe cambios por pull request y los checks de seguridad son obligatorios también para los administradores. El detalle está en la política de bloqueo.
