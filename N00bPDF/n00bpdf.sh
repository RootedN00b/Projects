#!/usr/bin/env bash
# ─────────────────────────────────────────────
#  n00bPDF — PDF Compressor using Ghostscript
# ─────────────────────────────────────────────

set -euo pipefail

# ── Colors ──────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
DIM='\033[2m'
RESET='\033[0m'

# ── Helpers ──────────────────────────────────
print_banner() {
  echo ""
  echo -e "${CYAN}${BOLD}"
  echo "  ███╗   ██╗ ██████╗  ██████╗ ██████╗ ██████╗ ██████╗ ███████╗"
  echo "  ████╗  ██║██╔═████╗██╔═████╗██╔══██╗██╔══██╗██╔══██╗██╔════╝"
  echo "  ██╔██╗ ██║██║██╔██║██║██╔██║██████╔╝██████╔╝██║  ██║█████╗  "
  echo "  ██║╚██╗██║████╔╝██║████╔╝██║██╔══██╗██╔═══╝ ██║  ██║██╔══╝  "
  echo "  ██║ ╚████║╚██████╔╝╚██████╔╝██████╔╝██║     ██████╔╝██║     "
  echo "  ╚═╝  ╚═══╝ ╚═════╝  ╚═════╝ ╚═════╝ ╚═╝     ╚═════╝ ╚═╝     "
  echo -e "${RESET}"
  echo -e "  ${DIM}PDF Compressor · Powered by Ghostscript${RESET}"
  echo ""
}

info()    { echo -e "${CYAN}  ➤  $*${RESET}"; }
success() { echo -e "${GREEN}  ✔  $*${RESET}"; }
warn()    { echo -e "${YELLOW}  ⚠  $*${RESET}"; }
error()   { echo -e "${RED}  ✖  $*${RESET}"; }
ask()     { echo -e "${BOLD}  $*${RESET}"; }

format_bytes() {
  local bytes=$1
  if   (( bytes < 1024 ));             then echo "${bytes} B"
  elif (( bytes < 1048576 ));          then printf "%.1f KB" "$(echo "scale=1; $bytes/1024" | bc)"
  else                                      printf "%.2f MB" "$(echo "scale=2; $bytes/1048576" | bc)"
  fi
}

# ── Step 1: Banner ────────────────────────────
print_banner

# ── Step 2: Check Ghostscript ─────────────────
echo -e "${BOLD}  [ Step 1/4 ] Checking dependencies...${RESET}"
echo ""

if command -v gs &> /dev/null; then
  GS_VERSION=$(gs --version 2>/dev/null)
  success "Ghostscript is installed (version ${GS_VERSION})"
else
  warn "Ghostscript is not installed on this system."
  echo ""
  ask "  Would you like to install Ghostscript now? [y/N]"
  read -r -p "  → " INSTALL_CHOICE
  echo ""

  case "${INSTALL_CHOICE,,}" in
    y|yes)
      info "Installing Ghostscript..."
      if command -v apt &> /dev/null; then
        sudo apt update -qq && sudo apt install -y ghostscript
      elif command -v dnf &> /dev/null; then
        sudo dnf install -y ghostscript
      elif command -v pacman &> /dev/null; then
        sudo pacman -Sy --noconfirm ghostscript
      elif command -v brew &> /dev/null; then
        brew install ghostscript
      else
        error "Could not detect your package manager."
        error "Please install Ghostscript manually: https://www.ghostscript.com/download.html"
        exit 1
      fi

      if command -v gs &> /dev/null; then
        success "Ghostscript installed successfully!"
      else
        error "Installation failed. Please install Ghostscript manually."
        exit 1
      fi
      ;;
    *)
      error "Ghostscript is required to compress PDFs. Exiting."
      exit 1
      ;;
  esac
fi

echo ""

# ── Step 3: Input File ────────────────────────
echo -e "${BOLD}  [ Step 2/4 ] Select input PDF${RESET}"
echo ""

INPUT_FILE=""

# Ask the user how they want to select the file
HAS_GUI=false
if ( command -v zenity &> /dev/null || command -v kdialog &> /dev/null ) && \
   [[ -n "${DISPLAY:-}" || -n "${WAYLAND_DISPLAY:-}" ]]; then
  HAS_GUI=true
fi

while [[ -z "${INPUT_FILE}" ]]; do
  if $HAS_GUI; then
    ask "  How would you like to select the PDF?"
    echo -e "  ${DIM}1)${RESET} Open file browser"
    echo -e "  ${DIM}2)${RESET} Type the path manually"
    echo -e "  ${DIM}3)${RESET} Exit"
  else
    ask "  How would you like to select the PDF?"
    echo -e "  ${DIM}1)${RESET} Type the path manually"
    echo -e "  ${DIM}2)${RESET} Exit"
  fi
  echo ""
  read -r -p "  → " PICKER_CHOICE
  echo ""

  if $HAS_GUI; then
    case "${PICKER_CHOICE}" in
      1)
        info "Opening file browser..."
        if command -v zenity &> /dev/null; then
          INPUT_FILE=$(zenity --file-selection \
            --title="Select a PDF to compress" \
            --file-filter="PDF files | *.pdf" \
            2>/dev/null) || true
        elif command -v kdialog &> /dev/null; then
          INPUT_FILE=$(kdialog --getopenfilename "$HOME" "*.pdf" \
            --title "Select a PDF to compress" \
            2>/dev/null) || true
        fi
        if [[ -z "${INPUT_FILE}" ]]; then
          warn "No file selected. Please choose an option."
          echo ""
        fi
        ;;
      2)
        ask "  Enter the full path to your PDF file:"
        read -r -p "  → " INPUT_FILE
        INPUT_FILE="${INPUT_FILE/#\~/$HOME}"
        ;;
      3)
        error "Exiting. Goodbye."
        exit 0
        ;;
      *)
        warn "Invalid choice. Please enter 1, 2, or 3."
        echo ""
        ;;
    esac
  else
    case "${PICKER_CHOICE}" in
      1)
        ask "  Enter the full path to your PDF file:"
        read -r -p "  → " INPUT_FILE
        INPUT_FILE="${INPUT_FILE/#\~/$HOME}"
        ;;
      2)
        error "Exiting. Goodbye."
        exit 0
        ;;
      *)
        warn "Invalid choice. Please enter 1 or 2."
        echo ""
        ;;
    esac
  fi
done

echo ""

# Validate input file
if [[ -z "${INPUT_FILE}" ]]; then
  error "No file selected. Exiting."
  exit 1
fi

if [[ ! -f "${INPUT_FILE}" ]]; then
  error "File not found: ${INPUT_FILE}"
  exit 1
fi

if [[ "${INPUT_FILE,,}" != *.pdf ]]; then
  warn "File does not have a .pdf extension: ${INPUT_FILE}"
  ask "  Continue anyway? [y/N]"
  read -r -p "  → " CONTINUE
  [[ "${CONTINUE,,}" =~ ^(y|yes)$ ]] || { error "Aborted."; exit 1; }
fi

INPUT_SIZE=$(stat -c%s "${INPUT_FILE}" 2>/dev/null || stat -f%z "${INPUT_FILE}")
success "Input: ${INPUT_FILE}"
info    "Size:  $(format_bytes "${INPUT_SIZE}")"
echo ""

# ── Step 4: Quality ───────────────────────────
echo -e "${BOLD}  [ Step 3/4 ] Choose compression quality${RESET}"
echo ""
echo -e "  ${DIM}1)${RESET} Screen   — Smallest file · 72 DPI  · Best for email & web"
echo -e "  ${DIM}2)${RESET} eBook    — Balanced     · 150 DPI · Good for most uses ${GREEN}(recommended)${RESET}"
echo -e "  ${DIM}3)${RESET} Printer  — High quality · 300 DPI · Suitable for printing"
echo -e "  ${DIM}4)${RESET} Prepress — Max quality  · 300 DPI · Professional publishing"
echo ""
ask "  Choose quality [1-4, default: 2]:"
read -r -p "  → " QUALITY_CHOICE
echo ""

case "${QUALITY_CHOICE}" in
  1) QUALITY="/screen";   QUALITY_NAME="Screen"   ;;
  3) QUALITY="/printer";  QUALITY_NAME="Printer"  ;;
  4) QUALITY="/prepress"; QUALITY_NAME="Prepress" ;;
  *) QUALITY="/ebook";    QUALITY_NAME="eBook"    ;;  # default
esac

success "Quality: ${QUALITY_NAME}"
echo ""

# ── Step 5: Output Path ───────────────────────
echo -e "${BOLD}  [ Step 4/4 ] Set output file${RESET}"
echo ""

# Suggest a sensible default name
INPUT_BASENAME=$(basename "${INPUT_FILE}" .pdf)
INPUT_DIR=$(dirname "${INPUT_FILE}")
DEFAULT_OUTPUT="${INPUT_DIR}/${INPUT_BASENAME}_compressed.pdf"

ask "  Enter output file path (press Enter for default):"
echo -e "  ${DIM}Default: ${DEFAULT_OUTPUT}${RESET}"
read -r -p "  → " OUTPUT_FILE
echo ""

# Use default if blank
OUTPUT_FILE="${OUTPUT_FILE:-${DEFAULT_OUTPUT}}"
OUTPUT_FILE="${OUTPUT_FILE/#\~/$HOME}"

# Append .pdf if missing
[[ "${OUTPUT_FILE,,}" != *.pdf ]] && OUTPUT_FILE="${OUTPUT_FILE}.pdf"

# Ensure output directory exists
OUTPUT_DIR=$(dirname "${OUTPUT_FILE}")
if [[ ! -d "${OUTPUT_DIR}" ]]; then
  warn "Directory '${OUTPUT_DIR}' does not exist."
  ask "  Create it? [y/N]"
  read -r -p "  → " MKDIR_CHOICE
  if [[ "${MKDIR_CHOICE,,}" =~ ^(y|yes)$ ]]; then
    mkdir -p "${OUTPUT_DIR}"
    success "Created directory: ${OUTPUT_DIR}"
  else
    error "Output directory does not exist. Exiting."
    exit 1
  fi
fi

# Warn if output already exists
if [[ -f "${OUTPUT_FILE}" ]]; then
  warn "Output file already exists: ${OUTPUT_FILE}"
  ask "  Overwrite? [y/N]"
  read -r -p "  → " OVERWRITE
  [[ "${OVERWRITE,,}" =~ ^(y|yes)$ ]] || { error "Aborted."; exit 1; }
fi

# ── Run Ghostscript ───────────────────────────
echo ""
echo -e "  ${BOLD}────────────────────────────────────────${RESET}"
echo -e "  ${BOLD}  Compressing...${RESET}"
echo -e "  ${BOLD}────────────────────────────────────────${RESET}"
echo ""
info "Input:   ${INPUT_FILE}"
info "Output:  ${OUTPUT_FILE}"
info "Quality: ${QUALITY_NAME} (${QUALITY})"
echo ""

START_TIME=$(date +%s)

gs \
  -sDEVICE=pdfwrite \
  -dCompatibilityLevel=1.4 \
  -dPDFSETTINGS="${QUALITY}" \
  -dNOPAUSE \
  -dQUIET \
  -dBATCH \
  -sOutputFile="${OUTPUT_FILE}" \
  "${INPUT_FILE}"

GS_EXIT=$?
END_TIME=$(date +%s)
ELAPSED=$(( END_TIME - START_TIME ))

echo ""

if [[ ${GS_EXIT} -ne 0 ]] || [[ ! -f "${OUTPUT_FILE}" ]]; then
  error "Ghostscript failed (exit code ${GS_EXIT})."
  error "The input PDF may be encrypted or corrupted."
  exit 1
fi

# ── Results ───────────────────────────────────
OUTPUT_SIZE=$(stat -c%s "${OUTPUT_FILE}" 2>/dev/null || stat -f%z "${OUTPUT_FILE}")
SAVED=$(( INPUT_SIZE - OUTPUT_SIZE ))

# Calculate reduction % using awk (avoids bc float issues)
REDUCTION=$(awk "BEGIN { printf \"%.1f\", (1 - ${OUTPUT_SIZE}/${INPUT_SIZE}) * 100 }")

echo -e "  ${GREEN}${BOLD}────────────────────────────────────────${RESET}"
echo -e "  ${GREEN}${BOLD}  ✔  Done in ${ELAPSED}s!${RESET}"
echo -e "  ${GREEN}${BOLD}────────────────────────────────────────${RESET}"
echo ""
echo -e "  ${DIM}Original size :${RESET}  $(format_bytes "${INPUT_SIZE}")"
echo -e "  ${DIM}Compressed    :${RESET}  $(format_bytes "${OUTPUT_SIZE}")"
echo -e "  ${DIM}Saved         :${RESET}  $(format_bytes "${SAVED}") ${GREEN}(${REDUCTION}% smaller)${RESET}"
echo -e "  ${DIM}Output file   :${RESET}  ${OUTPUT_FILE}"
echo ""

if (( OUTPUT_SIZE >= INPUT_SIZE )); then
  warn "The output is not smaller than the input."
  warn "The file may already be optimized. Try a lower quality setting."
fi

echo ""
