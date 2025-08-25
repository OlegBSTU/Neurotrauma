#!/bin/bash

# Script para instalar el Sistema de Fatiga Médica en Neurotrauma
# Uso: ./install_fatigue_system.sh [ruta_a_neurotrauma_steam]

echo "🩺 Instalador del Sistema de Fatiga Médica para Neurotrauma"
echo "=================================================="

# Detectar ruta de Neurotrauma automáticamente
STEAM_PATHS=(
"$HOME/.local/share/Steam/steamapps/workshop/content/602960/3190189044"
"$HOME/.steam/steam/steamapps/workshop/content/602960/3190189044"
"$HOME/Steam/steamapps/workshop/content/602960/3190189044"
)

NEUROTRAUMA_PATH=""

if [ $# -eq 1 ]; then
NEUROTRAUMA_PATH="$1"
echo "📁 Usando ruta proporcionada: $NEUROTRAUMA_PATH"
else
echo "🔍 Buscando Neurotrauma automáticamente..."
for path in "${STEAM_PATHS[@]}"; do
if [ -d "$path" ]; then
NEUROTRAUMA_PATH="$path"
echo "✅ Encontrado en: $NEUROTRAUMA_PATH"
break
fi
done
fi

if [ -z "$NEUROTRAUMA_PATH" ]; then
echo "❌ No se encontró Neurotrauma. Por favor proporciona la ruta:"
echo " ./install_fatigue_system.sh /ruta/a/neurotrauma"
exit 1
fi

if [ ! -d "$NEUROTRAUMA_PATH" ]; then
echo "❌ Error: La ruta $NEUROTRAUMA_PATH no existe"
exit 1
fi

echo "📋 Verificando archivos del sistema de fatiga..."

# Lista de archivos a copiar
declare -A FILES=(
["Neurotrauma/Localization/English/English.xml"]="Localization/English/English.xml"
["Neurotrauma/Xml/FatigueAfflictions.xml"]="Xml/FatigueAfflictions.xml"
["Neurotrauma/Xml/Items/FatigueItems.xml"]="Xml/Items/FatigueItems.xml"
["Neurotrauma/Lua/Scripts/Server/medicalfatigue.lua"]="Lua/Scripts/Server/medicalfatigue.lua"
["Neurotrauma/Lua/Scripts/Client/fatigueui.lua"]="Lua/Scripts/Client/fatigueui.lua"
["Neurotrauma/Lua/Scripts/Client/fatigueeffects.lua"]="Lua/Scripts/Client/fatigueeffects.lua"
["Neurotrauma/Lua/Scripts/fatigueconfig.lua"]="Lua/Scripts/fatigueconfig.lua"
["Neurotrauma/Xml/sounds.xml"]="Xml/sounds.xml"
["Neurotrauma/filelist.xml"]="filelist.xml"
)

# Hacer backup
echo "💾 Creando backup..."
BACKUP_DIR="${NEUROTRAUMA_PATH}_backup_$(date +%Y%m%d_%H%M%S)"
cp -r "$NEUROTRAUMA_PATH" "$BACKUP_DIR"
echo "✅ Backup creado en: $BACKUP_DIR"

# Copiar archivos
echo "📁 Instalando archivos del sistema de fatiga..."
for src in "${!FILES[@]}"; do
dest="${FILES[$src]}"
if [ -f "$src" ]; then
# Crear directorio si no existe
mkdir -p "$NEUROTRAUMA_PATH/$(dirname "$dest")"
cp "$src" "$NEUROTRAUMA_PATH/$dest"
echo "✅ Copiado: $dest"
else
echo "⚠️ No encontrado: $src"
fi
done

echo ""
echo "🎉 ¡Sistema de Fatiga Médica instalado correctamente!"
echo ""
echo "📖 Cómo probar:"
echo " 1. Iniciar Barotrauma"
echo " 2. Crear partida como Medical Doctor"
echo " 3. Usar instrumentos médicos"
echo " 4. Observar barras de fatiga en esquina superior derecha"
echo ""
echo "🔧 Para desinstalar:"
echo " rm -rf '$NEUROTRAUMA_PATH'"
echo " mv '$BACKUP_DIR' '$NEUROTRAUMA_PATH'"
echo ""
echo "📝 Reportar bugs en GitHub del proyecto Neurotrauma"