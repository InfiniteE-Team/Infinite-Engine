#!/bin/bash
# ------------------------------------------------------------------------------
# Infinite Engine - compilar y ejecutar en macOS
#
# Doble clic para compilar el motor (modo debug) y abrirlo.
# Requiere haber ejecutado antes install-mac.command.
#
# La primera compilacion tarda varios minutos; las siguientes son mas rapidas.
# Para compilar desde cero, borra la carpeta "export" y vuelve a abrir este archivo.
#
# Registro: ~/Library/Logs/InfiniteEngine-compilar.log
# ------------------------------------------------------------------------------

set -eo pipefail

# Busca la carpeta del proyecto (la que contiene Project.xml) subiendo desde donde
# esta este archivo. Asi funciona en cualquier subcarpeta (por ejemplo setup/macOS).
ROOT="$(cd "$(dirname "$0")" && pwd)"
while [ "$ROOT" != "/" ] && [ ! -f "$ROOT/Project.xml" ]; do
  ROOT="$(dirname "$ROOT")"
done
cd "$ROOT"

LOG="$HOME/Library/Logs/InfiniteEngine-compilar.log"
mkdir -p "$(dirname "$LOG")"
exec > >(tee -a "$LOG") 2>&1

paso()    { printf '\n\033[1;36m==> %s\033[0m\n' "$*"; }
aviso()   { printf '\033[1;33mAviso: %s\033[0m\n' "$*"; }
pausar()  { [ -n "$INFINITE_NO_PAUSE" ] && return 0; read -n 1 -s -r -p "Presiona una tecla para cerrar esta ventana..." || true; echo; }
fallo()   { printf '\n\033[1;31mError: %s\033[0m\n' "$*"; echo "Registro completo: $LOG"; pausar; exit 1; }

trap 'fallo "Algo fallo en la linea $LINENO. Copia el texto de esta ventana (o el registro) y envialo a quien te ayuda."' ERR

echo "Infinite Engine - compilar para Mac"
echo "Fecha: $(date)"

[ "$(uname -s)" = "Darwin" ] || fallo "Esto es solo para macOS."
{ [ -f Project.xml ] && [ -f hmm.json ]; } || fallo "No encuentro Project.xml. Este archivo debe estar dentro de la carpeta Infinite-Engine (en la carpeta setup/macOS)."

if [ "$(sysctl -n sysctl.proc_translated 2>/dev/null || echo 0)" = "1" ]; then
  fallo "Esta Terminal esta corriendo con Rosetta (modo Intel). Desmarca 'Abrir con Rosetta' en la app Terminal y vuelve a intentarlo."
fi

# --- Entorno: Homebrew, Neko y SDK de macOS -----------------------------------
if [ "$(uname -m)" = "arm64" ]; then
  BREW_BIN="/opt/homebrew/bin/brew"
else
  BREW_BIN="/usr/local/bin/brew"
fi
[ -x "$BREW_BIN" ] || fallo "No encuentro Homebrew. Abre primero install-mac.command."
eval "$("$BREW_BIN" shellenv)"
hash -r

command -v haxelib >/dev/null 2>&1 || fallo "No encuentro haxelib. Abre primero install-mac.command."
[ -d .haxelib ] || fallo "Faltan las librerias del proyecto (carpeta .haxelib). Abre primero install-mac.command."

export NEKOPATH="$(brew --prefix)/lib/neko"

# Arreglo del error 'SDK "macosx26" cannot be located': hxcpp elige mal el
# nombre del SDK, asi que le indicamos la version exacta que tiene Xcode.
MACOSX_VER="$(xcrun --sdk macosx --show-sdk-version 2>/dev/null || true)"
if [ -n "$MACOSX_VER" ]; then
  export MACOSX_VER
  echo "SDK de macOS: $MACOSX_VER"
else
  aviso "No pude detectar la version del SDK de macOS; se intentara compilar igualmente."
fi

# --- Compilar y ejecutar ------------------------------------------------------
paso "Compilando y ejecutando (modo debug)"
trap - ERR
if haxelib run lime test macos -debug; then
  paso "El juego se cerro"
else
  fallo "La compilacion o el juego terminaron con error. Copia las ultimas lineas de esta ventana y envialas a quien te ayuda."
fi
pausar
