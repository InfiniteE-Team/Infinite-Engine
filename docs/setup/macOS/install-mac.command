#!/bin/bash
# ------------------------------------------------------------------------------
# Infinite Engine - instalador para macOS (Intel y Apple Silicon)
#
# Doble clic para ejecutarlo. Instala Haxe, las librerias del proyecto y Lime.
# Solo hace falta ejecutarlo una vez (si lo repites, no pasa nada).
#
# Incluye arreglos para problemas conocidos de Mac:
#   - mezcla de Haxe de Intel con Mac Apple Silicon
#   - ruta de Neko (NEKOPATH)
#   - Terminal abierta con Rosetta
#
# Si algo falla, el registro completo queda en:
#   ~/Library/Logs/InfiniteEngine-instalar.log
# ------------------------------------------------------------------------------

set -eo pipefail

# Busca la carpeta del proyecto (la que contiene Project.xml) subiendo desde donde
# esta este archivo. Asi funciona en cualquier subcarpeta (por ejemplo setup/macOS).
ROOT="$(cd "$(dirname "$0")" && pwd)"
while [ "$ROOT" != "/" ] && [ ! -f "$ROOT/Project.xml" ]; do
  ROOT="$(dirname "$ROOT")"
done
cd "$ROOT"

LOG="$HOME/Library/Logs/InfiniteEngine-instalar.log"
mkdir -p "$(dirname "$LOG")"
exec > >(tee -a "$LOG") 2>&1

paso()    { printf '\n\033[1;36m==> %s\033[0m\n' "$*"; }
aviso()   { printf '\033[1;33mAviso: %s\033[0m\n' "$*"; }
pausar()  { [ -n "$INFINITE_NO_PAUSE" ] && return 0; read -n 1 -s -r -p "Presiona una tecla para cerrar esta ventana..." || true; echo; }
fallo()   { printf '\n\033[1;31mError: %s\033[0m\n' "$*"; echo "Registro completo: $LOG"; pausar; exit 1; }

trap 'fallo "Algo fallo en la linea $LINENO. Copia el texto de esta ventana (o el registro) y envialo a quien te ayuda."' ERR

echo "Infinite Engine - instalador para Mac"
echo "Fecha: $(date)"

# --- Comprobaciones iniciales -------------------------------------------------
[ "$(uname -s)" = "Darwin" ] || fallo "Este instalador es solo para macOS."
{ [ -f Project.xml ] && [ -f hmm.json ]; } || fallo "No encuentro Project.xml y hmm.json. Este archivo debe estar dentro de la carpeta Infinite-Engine (en la carpeta setup/macOS)."

ARCH="$(uname -m)"
if [ "$(sysctl -n sysctl.proc_translated 2>/dev/null || echo 0)" = "1" ]; then
  fallo "Esta Terminal esta corriendo con Rosetta (modo Intel) y mezclaria versiones. Cierra la Terminal, desmarca 'Abrir con Rosetta' en Informacion de la app Terminal y vuelve a abrir este archivo."
fi

if [ "$ARCH" = "arm64" ]; then
  BREW_BIN="/opt/homebrew/bin/brew"
else
  BREW_BIN="/usr/local/bin/brew"
fi
echo "Arquitectura: $ARCH"

# --- 1) Herramientas de Apple -------------------------------------------------
paso "1/6 Herramientas de compilacion de Apple"
if ! xcode-select -p >/dev/null 2>&1; then
  xcode-select --install || true
  fallo "Se abrio la instalacion de las herramientas de Apple. Cuando termine, vuelve a abrir este archivo."
fi
echo "OK: $(xcode-select -p)"

# --- 2) Homebrew --------------------------------------------------------------
paso "2/6 Homebrew"
if [ ! -x "$BREW_BIN" ]; then
  echo "Instalando Homebrew (te pedira la contrasena de tu Mac)..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi
[ -x "$BREW_BIN" ] || fallo "No se pudo instalar Homebrew en $BREW_BIN."
eval "$("$BREW_BIN" shellenv)"

ZPROFILE="$HOME/.zprofile"
touch "$ZPROFILE"
if ! grep -qF "$BREW_BIN shellenv" "$ZPROFILE"; then
  echo "eval \"\$($BREW_BIN shellenv)\"" >> "$ZPROFILE"
fi
echo "OK: $(brew --version | head -n 1)"

# --- 3) Haxe ------------------------------------------------------------------
paso "3/6 Haxe"
brew install haxe
hash -r

HAXE_BIN="$(command -v haxe || true)"
[ -n "$HAXE_BIN" ] || fallo "Haxe no quedo instalado."
case "$HAXE_BIN" in
  "$(brew --prefix)"/*) ;;
  *) aviso "Se esta usando $HAXE_BIN y no el de Homebrew. Si falla, es por ese Haxe antiguo." ;;
esac

if [ "$ARCH" = "arm64" ]; then
  NEKO_INFO="$(file -L "$(command -v neko)")"
  case "$NEKO_INFO" in
    *arm64*) ;;
    *) fallo "El programa neko ($(command -v neko)) no es nativo de Apple Silicon. Hay un Haxe de Intel mezclado; desinstalalo y vuelve a abrir este archivo." ;;
  esac
fi
echo "OK: Haxe $(haxe --version)"

# --- 4) Rutas -----------------------------------------------------------------
paso "4/6 Configurando rutas"
export NEKOPATH="$(brew --prefix)/lib/neko"
if ! grep -q "export NEKOPATH" "$ZPROFILE"; then
  echo "export NEKOPATH=\"$NEKOPATH\"" >> "$ZPROFILE"
fi
mkdir -p "$HOME/haxelib"
haxelib setup "$HOME/haxelib"
echo "OK: NEKOPATH=$NEKOPATH"

# --- 5) Librerias del proyecto ------------------------------------------------
paso "5/6 Librerias del proyecto (tarda varios minutos, no cierres la ventana)"
haxelib --global git hmm https://github.com/ALE-Psych-Crew/hmm
haxelib --global run hmm setup || aviso "hmm setup no termino; se continua igualmente."
haxelib --global run hmm install

# --- 6) Lime ------------------------------------------------------------------
paso "6/6 Lime"
haxelib run lime setup -y || aviso "lime setup no termino; se continua igualmente."

paso "Listo"
echo "Instalacion terminada. Ahora abre compile-mac.command para compilar y ejecutar el motor."
echo "La primera compilacion tarda varios minutos."
trap - ERR
pausar
