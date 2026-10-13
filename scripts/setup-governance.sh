#!/bin/bash
# setup-governance.sh
#
# ⚠️  OBSOLETO — Este script ya no se usa.
#
# El setup de governance se gestiona con el CLI cursor-governance:
#
#   # Instalar el CLI (una vez por máquina)
#   git clone git@github.com:inigo-munoz/cursor-governance-cli.git ~/cursor-governance-cli
#   cd ~/cursor-governance-cli && ./install.sh
#   cursor-governance install
#
#   # Inicializar governance en el proyecto
#   cursor-governance init --stack prestashop --core v2.1.1 --stack-version v2.2.0
#   cursor-governance apply
#
# Ver documentación completa en cursor-setup.md

echo "⚠️  Este script está obsoleto."
echo ""
echo "Usa el CLI de governance:"
echo "  cursor-governance init --stack prestashop --core v2.1.1 --stack-version v2.2.0"
echo "  cursor-governance apply"
echo ""
echo "Ver cursor-setup.md para instrucciones completas."
exit 1
