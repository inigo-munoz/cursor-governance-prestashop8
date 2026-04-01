#!/bin/bash
# learn-from-pr.sh
# Extrae patrones de aprendizaje de comentarios de PR y actualiza las governance rules.
# Basado en el patrón de Elementor Engineers (enero 2026).
#
# Uso:
#   ./scripts/learn-from-pr.sh <PR_NUMBER>          # desde un proyecto con governance instalada
#   ./scripts/learn-from-pr.sh --last-merged         # último PR mergeado
#   ./scripts/learn-from-pr.sh --dry-run <PR_NUMBER> # ver qué aprendería sin escribir nada
#
# Requisitos:
#   - gh CLI instalado y autenticado
#   - iagt-governance instalado
#   - IAGT_GOVERNANCE_STACK exportada o detectada por el CLI

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DRY_RUN=false
PR_NUMBER=""

# ── Args ──────────────────────────────────────────────────────────────────────
while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run) DRY_RUN=true; shift ;;
    --last-merged)
      PR_NUMBER=$(gh pr list --state merged --limit 1 --json number --jq '.[0].number' 2>/dev/null || echo "")
      [ -z "$PR_NUMBER" ] && { echo "[ERROR] No se encontró ningún PR mergeado reciente"; exit 1; }
      shift ;;
    [0-9]*) PR_NUMBER="$1"; shift ;;
    *) echo "Uso: $0 [--dry-run] [--last-merged] <PR_NUMBER>"; exit 1 ;;
  esac
done

[ -z "$PR_NUMBER" ] && { echo "[ERROR] Indica el número de PR o usa --last-merged"; exit 1; }

log_info()  { echo "[INFO]  $1"; }
log_ok()    { echo "[OK]    $1"; }
log_warn()  { echo "[WARN]  $1"; }
log_error() { echo "[ERROR] $1" >&2; }

# ── 1. Obtener comentarios del PR ─────────────────────────────────────────────
log_info "Obteniendo comentarios del PR #${PR_NUMBER}..."

if ! command -v gh >/dev/null 2>&1; then
  log_error "gh CLI no instalado. Instala: https://cli.github.com/"
  exit 1
fi

PR_DATA=$(gh pr view "$PR_NUMBER" --json title,body,comments,reviews 2>/dev/null) || {
  log_error "No se pudo obtener el PR #${PR_NUMBER}. ¿Está autenticado gh?"
  exit 1
}

PR_TITLE=$(echo "$PR_DATA" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('title',''))")
REVIEW_COMMENTS=$(gh api "repos/{owner}/{repo}/pulls/${PR_NUMBER}/comments" \
  --jq '.[].body' 2>/dev/null | grep -v "^$" | head -50 || echo "")
REVIEW_BODIES=$(echo "$PR_DATA" | python3 -c "
import sys,json
d=json.load(sys.stdin)
reviews = d.get('reviews',[])
for r in reviews:
    body = r.get('body','').strip()
    if body and r.get('state') in ['CHANGES_REQUESTED','COMMENTED']:
        print(body)
" 2>/dev/null || echo "")

ALL_COMMENTS="${REVIEW_COMMENTS}
${REVIEW_BODIES}"

if [ -z "$(echo "$ALL_COMMENTS" | tr -d '[:space:]')" ]; then
  log_warn "PR #${PR_NUMBER} no tiene comentarios de revisión. Nada que aprender."
  exit 0
fi

log_ok "$(echo "$ALL_COMMENTS" | wc -l | tr -d ' ') líneas de comentarios obtenidas"

# ── 2. Determinar ruta al archivo de lecciones aprendidas ─────────────────────
# Detectar stack desde el CLI si está disponible
STACK="prestashop"
if command -v iagt-governance >/dev/null 2>&1; then
  DETECTED=$(iagt-governance doctor 2>/dev/null | grep "Stack:" | head -1 | awk '{print $2}' || echo "")
  [ -n "$DETECTED" ] && STACK="$DETECTED"
fi

LESSONS_FILE="lessons/learned-patterns.md"

# ── 3. Extraer patrones con LLM via CLI (si disponible) o usar heurísticas ───
log_info "Analizando comentarios para extraer patrones de governance..."

# Heurísticas básicas que no requieren LLM:
# Detectar menciones de reglas de governance en los comentarios
PATTERNS_FOUND=""

# Patrón: comentarios que mencionan prácticas incorrectas
if echo "$ALL_COMMENTS" | grep -qiE "\\\$_(GET|POST|REQUEST)|raw.*input|sin.*cast|without.*(int)|pSQL"; then
  PATTERNS_FOUND="${PATTERNS_FOUND}
- **SQL/Input sin sanitizar**: El PR contenía inputs sin cast o pSQL(). Rule 1-2 de security."
fi

if echo "$ALL_COMMENTS" | grep -qiE "hook.*logic|lógica.*hook|business.*hook|negocio.*hook"; then
  PATTERNS_FOUND="${PATTERNS_FOUND}
- **Lógica en hooks**: Se detectó lógica de negocio en hooks. Debe ir en Service Layer."
fi

if echo "$ALL_COMMENTS" | grep -qiE "id_shop|multishop|shop.*filter|filtro.*tienda"; then
  PATTERNS_FOUND="${PATTERNS_FOUND}
- **Multishop**: Comentarios relacionados con id_shop o filtrado por tienda."
fi

if echo "$ALL_COMMENTS" | grep -qiE "override|sobrescrit|sobreescrit"; then
  PATTERNS_FOUND="${PATTERNS_FOUND}
- **Override**: Se discutió el uso de overrides. Verificar documentación de excepción."
fi

if echo "$ALL_COMMENTS" | grep -qiE "prefix.*Iagt|prefijo.*Iagt|clase.*sin.*prefijo|class.*without.*prefix"; then
  PATTERNS_FOUND="${PATTERNS_FOUND}
- **Prefijo Iagt ausente**: Clases custom sin prefijo Iagt detectadas en revisión."
fi

if [ -z "$PATTERNS_FOUND" ]; then
  # Guardar los comentarios raw para revisión manual
  PATTERNS_FOUND="
- **Revisar manualmente**: Los comentarios del PR no coincidieron con heurísticas automáticas.
  Comentarios raw guardados para análisis:
$(echo "$ALL_COMMENTS" | head -10 | sed 's/^/  > /')"
fi

# ── 4. Escribir en learned-patterns.md ───────────────────────────────────────
DATE=$(date +%Y-%m-%d)
REPO=$(gh repo view --json nameWithOwner --jq '.nameWithOwner' 2>/dev/null || echo "unknown/repo")

ENTRY="
## PR #${PR_NUMBER} — ${PR_TITLE}

**Fecha:** ${DATE}
**Repo:** ${REPO}
**URL:** https://github.com/${REPO}/pull/${PR_NUMBER}

### Patrones detectados
${PATTERNS_FOUND}

### Acción recomendada

Revisar si alguno de estos patrones requiere:
1. Añadir una regla al stack (editar \`rules/prestashop-main-rule.md\` o \`security/prestashop-security.md\`)
2. Añadir un detector a \`rulesets/prestashop/security_patterns.sh\`
3. Añadir un caso a \`tests/unit/\`

---
"

if $DRY_RUN; then
  log_info "DRY RUN — lo que se añadiría a ${LESSONS_FILE}:"
  echo "$ENTRY"
  exit 0
fi

# Crear el archivo si no existe
if [ ! -f "$LESSONS_FILE" ]; then
  cat > "$LESSONS_FILE" << 'HEADER'
# Learned Patterns — Governance

Patrones extraídos de revisiones de PR reales.
Actualizados automáticamente por `scripts/learn-from-pr.sh`.

Revisar periódicamente para:
- Añadir detectores automáticos en `rulesets/`
- Reforzar reglas en `rules/` o `security/`
- Añadir casos de test en `tests/unit/`

---
HEADER
fi

echo "$ENTRY" >> "$LESSONS_FILE"
log_ok "Patrón añadido a ${LESSONS_FILE}"
log_info "Revisa el archivo y decide si actualizar las rules de governance"

# ── 5. Ofrecer commit ─────────────────────────────────────────────────────────
echo ""
echo "Para commitear el aprendizaje:"
echo "  git add ${LESSONS_FILE}"
echo "  git commit -m \"governance: learned patterns from PR #${PR_NUMBER}\""
