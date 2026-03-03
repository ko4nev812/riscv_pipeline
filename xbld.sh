#!/bin/bash

VIVADO_PATH=${VIVADO_PATH:""}
if [ -z "${VIVADO_PATH}" ]; then
    echo "VIVADO_PATH var wasn't set!"
    exit
fi
# Имя Tcl‑скрипта сборки
BLD_SCRIPT="xbld.tcl"

# Каталог для логов
LOG_DIR="log"

# Удаляем старые директории Vivado и логов
rm -rf .Xil
rm -rf "$LOG_DIR"

# Создаём чистую папку для логов
mkdir -p "$LOG_DIR"

# Запуск Vivado в batch‑режиме
${VIVADO_PATH} -mode batch          \
       -journal "$LOG_DIR/bld.jou" \
       -log     "$LOG_DIR/bld.log" \
       -source  "$BLD_SCRIPT"      \
       -notrace

