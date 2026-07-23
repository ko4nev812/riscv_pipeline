#!/bin/bash

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
/tools/Xilinx/Vivado/2019.2/bin/vivado -mode batch          \
       -journal "$LOG_DIR/bld.jou" \
       -log     "$LOG_DIR/bld.log" \
       -source  "$BLD_SCRIPT"      \
       -notrace