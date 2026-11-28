#!/usr/bin/env bash
# Importa los reportes del pipeline en DefectDojo.
# Uso: DEFECTDOJO_URL=http://localhost:8082 DEFECTDOJO_TOKEN=... ./importar.sh <carpeta con los reportes>
# Las carpetas son las de los artefactos del workflow DevSecOps y Seguridad IaC.
set -euo pipefail

: "${DEFECTDOJO_URL:?Falta DEFECTDOJO_URL}"
: "${DEFECTDOJO_TOKEN:?Falta DEFECTDOJO_TOKEN}"
CARPETA="${1:?Indica la carpeta con los reportes}"
PRODUCTO="${DEFECTDOJO_PRODUCTO:-Juice Shop}"
ENGAGEMENT="${DEFECTDOJO_ENGAGEMENT:-Pipeline DevSecOps}"
TIPO_PRODUCTO="${DEFECTDOJO_TIPO_PRODUCTO:-Aplicaciones web}"

importar() {
  local archivo="$1" tipo="$2" titulo="$3"
  if [ ! -f "${CARPETA}/${archivo}" ]; then
    echo "No existe ${archivo}, se omite"
    return 0
  fi
  local codigo
  codigo=$(curl -s -o /tmp/dd-respuesta.json -w '%{http_code}' -X POST "${DEFECTDOJO_URL}/api/v2/reimport-scan/" \
    -H "Authorization: Token ${DEFECTDOJO_TOKEN}" \
    -F "scan_type=${tipo}" -F "test_title=${titulo}" \
    -F "product_name=${PRODUCTO}" -F "product_type_name=${TIPO_PRODUCTO}" -F "engagement_name=${ENGAGEMENT}" \
    -F "auto_create_context=true" -F "do_not_reactivate=false" -F "close_old_findings=true" \
    -F "file=@${CARPETA}/${archivo}")
  if [ "${codigo}" -ge 300 ]; then
    echo "Falló la importación de ${archivo}, código ${codigo}"; cat /tmp/dd-respuesta.json; echo
    return 1
  fi
  echo "Importado ${titulo}"
}

importar semgrep-sarif/semgrep.sarif       "SARIF"          "SAST Semgrep"
importar gitleaks-sarif/gitleaks.sarif     "SARIF"          "Secretos Gitleaks"
importar grype-json/grype.json             "Anchore Grype"  "SCA Grype"
importar trivy-sarif/trivy.sarif           "SARIF"          "Imagen Trivy"
importar reportes-iac/results_sarif.sarif  "SARIF"          "IaC Checkov"
importar reportes-iac/ansible-lint.sarif   "SARIF"          "IaC ansible-lint"
importar zap-baseline/baseline.xml         "ZAP Scan"       "DAST ZAP baseline"
importar sbom-cyclonedx/sbom.cdx.json     "CycloneDX Scan" "SBOM CycloneDX"
