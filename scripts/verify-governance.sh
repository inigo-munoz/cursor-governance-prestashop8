#!/bin/bash
# verify-governance.sh
# Verificación ENTERPRISE (SIN symlink)
# Verifica: estructura, unicidad, integridad, rule activa = source, version file, SHA remoto (si hay acceso)
# Soporta: --quiet (sin output, solo exit code)

set -euo pipefail

QUIET=false
if [ "${1:-}" = "--quiet" ] || [ "${1:-}" = "-q" ]; then
  QUIET=true
fi

GOVERNANCE_DIR="governance"
CORE_DIR="$GOVERNANCE_DIR/core"
PRESTASHOP_DIR="$GOVERNANCE_DIR/prestashop"

CURSOR_RULES_DIR=".cursor/rules"
RULE_TARGET="$CURSOR_RULES_DIR/prestashop.md"
RULE_SOURCE="$PRESTASHOP_DIR/rules/prestashop-main-rule.md"

VERSION_FILE="governance.version"

RULE_IDENTIFIER="Seguridad > Estabilidad > Robustez"
EXIT_CODE=0

say() { $QUIET || echo "$@"; }

log_check() { say "[CHECK] $1"; }
log_pass()  { say "[PASS]  $1"; }
log_warn()  { say "[WARN]  $1"; }
log_fail()  { say "[FAIL]  $1"; EXIT_CODE=1; }

compute_hash() {
  local file="$1"
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$file" | awk '{print $1}'
  elif command -v shasum >/dev/null 2>&1; then
    shasum -a 256 "$file" | awk '{print $1}'
  else
    echo "no-hash-tool"
  fi
}

check_governance_exists() {
  log_check "Estructura base de governance..."
  [ -d "$CORE_DIR" ] || log_fail "Falta $CORE_DIR"
  [ -d "$PRESTASHOP_DIR" ] || log_fail "Falta $PRESTASHOP_DIR"
  [ $EXIT_CODE -eq 0 ] && log_pass "Estructura base OK"
}

check_contract_compliance() {
  log_check "Contrato estructural..."
  local required_files=(README.md CHANGELOG.md quickstart.md taxonomy.md CONTRIBUTING.md pr-checklist.md exceptions.md)
  local required_dirs=(rules commands scripts security patterns conventions architecture context standards workflow)

  for f in "${required_files[@]}"; do
    [ -f "$PRESTASHOP_DIR/$f" ] || log_fail "Falta archivo obligatorio: $PRESTASHOP_DIR/$f"
  done
  for d in "${required_dirs[@]}"; do
    [ -d "$PRESTASHOP_DIR/$d" ] || log_fail "Falta carpeta obligatoria: $PRESTASHOP_DIR/$d"
  done

  # Rule principal
  ls "$PRESTASHOP_DIR/rules/"*-main-rule.md >/dev/null 2>&1 || log_fail "No hay *-main-rule.md en $PRESTASHOP_DIR/rules/"

  # Scripts obligatorios
  for s in setup-governance.sh update-governance.sh verify-governance.sh; do
    [ -f "$PRESTASHOP_DIR/scripts/$s" ] || log_fail "Falta script: $PRESTASHOP_DIR/scripts/$s"
  done

  [ $EXIT_CODE -eq 0 ] && log_pass "Contrato estructural OK"
}

check_rule_uniqueness() {
  log_check "Unicidad de rule en .cursor/rules..."
  
  # Verificar que .cursor existe y es válido
  if [ ! -d ".cursor" ]; then
    log_fail "Falta directorio .cursor (Cursor no podrá indexar rules)"
    return
  fi
  
  [ -d "$CURSOR_RULES_DIR" ] || { log_fail "Falta $CURSOR_RULES_DIR"; return; }

  # Verificar que no está ignorado por .gitignore
  if git check-ignore -q "$CURSOR_RULES_DIR" 2>/dev/null; then
    log_warn "$CURSOR_RULES_DIR está en .gitignore (Cursor podría no indexarlo correctamente)"
  fi

  local count
  count=$(find "$CURSOR_RULES_DIR" -maxdepth 1 -name "*.md" 2>/dev/null | wc -l | tr -d ' ')
  if [ "$count" -ne 1 ]; then
    log_fail "Hay $count rules en $CURSOR_RULES_DIR (debe ser 1)"
    return
  fi
  [ -f "$RULE_TARGET" ] || log_fail "Debe existir $RULE_TARGET"
  [ $EXIT_CODE -eq 0 ] && log_pass "Unicidad OK"
}

check_rule_content() {
  log_check "Contenido de rule activa..."
  [ -f "$RULE_TARGET" ] || { log_fail "No existe $RULE_TARGET"; return; }
  [ -s "$RULE_TARGET" ] || { log_fail "Rule activa está vacía"; return; }

  if ! grep -q "$RULE_IDENTIFIER" "$RULE_TARGET" 2>/dev/null; then
    log_warn "Rule activa no contiene identificador esperado: '$RULE_IDENTIFIER'"
  else
    log_pass "Contenido mínimo OK"
  fi
}

check_rule_sync() {
  log_check "Rule activa = source..."

  [ -f "$RULE_SOURCE" ] || { log_fail "No existe rule source: $RULE_SOURCE"; return; }
  [ -f "$RULE_TARGET" ] || { log_fail "No existe rule activa: $RULE_TARGET"; return; }

  local tmp_source tmp_target
  tmp_source=$(mktemp)
  tmp_target=$(mktemp)
  
  # Normalizar SOLO trailing newlines (no whitespace interno)
  # printf '%s\n' "$(cat file)" elimina trailing newlines y añade exactamente uno
  printf '%s\n' "$(cat "$RULE_SOURCE")" > "$tmp_source"
  printf '%s\n' "$(tail -n +4 "$RULE_TARGET")" > "$tmp_target"
  
  # Comparación ESTRICTA (sin flags permisivos)
  if diff -q "$tmp_source" "$tmp_target" >/dev/null 2>&1; then
    log_pass "Rule activa sincronizada"
  else
    log_fail "Rule activa NO coincide con source (regenera con setup/update)"
  fi

  rm -f "$tmp_source" "$tmp_target"
}

check_version_file() {
  log_check "Archivo de versión..."
  [ -f "$VERSION_FILE" ] || { log_fail "No existe $VERSION_FILE"; return; }

  local required=(CORE_VERSION PRESTASHOP_VERSION CORE_COMMIT PRESTASHOP_COMMIT RULE_HASH LAST_SYNC CORE_REF PRESTASHOP_REF CORE_REPO PRESTASHOP_REPO)
  for k in "${required[@]}"; do
    grep -qE "^${k}=" "$VERSION_FILE" 2>/dev/null || log_fail "Falta campo en $VERSION_FILE: $k"
  done

  local rule_hash expected
  expected=$(grep "^RULE_HASH=" "$VERSION_FILE" | cut -d'=' -f2- || true)
  rule_hash=$(compute_hash "$RULE_SOURCE")
  if [ -n "$expected" ] && [ "$expected" != "pending" ] && [ "$expected" != "$rule_hash" ]; then
    log_fail "RULE_HASH mismatch (version file vs source)"
  else
    log_pass "Version file OK"
  fi
}

check_remote_sha_best_effort() {
  log_check "Verificación SHA remota (best effort)..."
  [ -f "$VERSION_FILE" ] || { log_warn "Sin $VERSION_FILE, no se verifica remoto"; return; }

  local core_repo core_ref core_commit ps_repo ps_ref ps_commit
  core_repo=$(grep "^CORE_REPO=" "$VERSION_FILE" | cut -d'=' -f2- || true)
  core_ref=$(grep "^CORE_REF=" "$VERSION_FILE" | cut -d'=' -f2- || true)
  core_commit=$(grep "^CORE_COMMIT=" "$VERSION_FILE" | cut -d'=' -f2- || true)

  ps_repo=$(grep "^PRESTASHOP_REPO=" "$VERSION_FILE" | cut -d'=' -f2- || true)
  ps_ref=$(grep "^PRESTASHOP_REF=" "$VERSION_FILE" | cut -d'=' -f2- || true)
  ps_commit=$(grep "^PRESTASHOP_COMMIT=" "$VERSION_FILE" | cut -d'=' -f2- || true)

  # Si no hay acceso, no bloqueamos: warn
  local remote_core remote_ps
  remote_core=$(git ls-remote "$core_repo" "refs/tags/${core_ref}^{}" 2>/dev/null | cut -f1 || true)
  remote_ps=$(git ls-remote "$ps_repo" "refs/tags/${ps_ref}^{}" 2>/dev/null | cut -f1 || true)

  if [ -z "$remote_core" ] || [ -z "$remote_ps" ]; then
    log_warn "No se pudo verificar remoto (sin acceso o ref no existe)."
    return
  fi

  if [ "$core_commit" != "unknown" ] && [ "$core_commit" != "$remote_core" ]; then
    log_fail "CORE_COMMIT NO coincide con remoto"
  fi
  if [ "$ps_commit" != "unknown" ] && [ "$ps_commit" != "$remote_ps" ]; then
    log_fail "PRESTASHOP_COMMIT NO coincide con remoto"
  fi

  [ $EXIT_CODE -eq 0 ] && log_pass "SHA remota OK"
}

print_summary() {
  say ""
  say "============================================================"
  if [ $EXIT_CODE -eq 0 ]; then
    say "  ✅ VERIFICACIÓN EXITOSA"
  else
    say "  ❌ VERIFICACIÓN FALLIDA"
  fi
  say "============================================================"
  say ""
}

main() {
  check_governance_exists
  check_contract_compliance
  check_rule_uniqueness
  check_rule_content
  check_rule_sync
  check_version_file
  check_remote_sha_best_effort
  print_summary
  exit $EXIT_CODE
}

main
