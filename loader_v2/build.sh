#!/bin/bash
# Builder LightBurn Loader FUD

# Compilar con flags agresivos de optimización y stripping
# -nostdlib para evitar CRT imports (usamos Entry manual)
# -e Entry para definir punto de entrada

x86_64-w64-mingw32-gcc -o LightBurn_Loader.exe loader.c \
    -s -O2 -nostdlib -e Entry -mwindows \
    -Wl,--enable-stdcall-fixup

ls -lh LightBurn_Loader.exe
