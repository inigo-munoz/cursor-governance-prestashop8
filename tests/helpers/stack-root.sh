#!/usr/bin/env bash
# stack-root.sh
#
# REQUIRED: All governance test scripts must source this file.
# Do not compute a local ROOT; use STACK_ROOT as the single source of truth.
#
# Resuelve la raíz del stack (repositorio) de forma portable.
# Evita rutas relativas frágiles (../../skills, etc.).
# Funciona cuando los tests se ejecutan desde CLI, CI o directamente desde el directorio de tests.

STACK_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
export STACK_ROOT
