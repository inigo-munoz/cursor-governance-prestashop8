#!/bin/bash
# update-governance.sh
#
# ⚠️  OBSOLETO — Este script ya no se usa.
#
# La actualización de governance se gestiona con el CLI iagt-governance:
#
#   iagt-governance update                               # descarga nuevos tags
#   iagt-governance bump --core vX.X.X --stack vX.X.X   # actualiza el pin
#   iagt-governance apply                                # regenera el entrypoint
#   iagt-governance verify                               # verifica integridad
#
# Ver documentación completa en cursor-setup.md

echo "⚠️  Este script está obsoleto."
echo ""
echo "Usa el CLI de governance:"
echo "  iagt-governance update"
echo "  iagt-governance bump --core vX.X.X --stack vX.X.X"
echo "  iagt-governance apply"
echo "  iagt-governance verify"
echo ""
echo "Ver cursor-setup.md para instrucciones completas."
exit 1
