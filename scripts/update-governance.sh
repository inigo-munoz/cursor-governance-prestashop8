#!/bin/bash
# update-governance.sh
#
# ⚠️  OBSOLETO — Este script ya no se usa.
#
# La actualización de governance se gestiona con el CLI cursor-governance:
#
#   cursor-governance update                               # descarga nuevos tags
#   cursor-governance bump --core vX.X.X --stack vX.X.X   # actualiza el pin
#   cursor-governance apply                                # regenera el entrypoint
#   cursor-governance verify                               # verifica integridad
#
# Ver documentación completa en cursor-setup.md

echo "⚠️  Este script está obsoleto."
echo ""
echo "Usa el CLI de governance:"
echo "  cursor-governance update"
echo "  cursor-governance bump --core vX.X.X --stack vX.X.X"
echo "  cursor-governance apply"
echo "  cursor-governance verify"
echo ""
echo "Ver cursor-setup.md para instrucciones completas."
exit 1
