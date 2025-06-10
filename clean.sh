#!/bin/bash

echo -e "\033[1;34mCleaning up build artifacts...\033[0m"

CLEAN_PATHS=(
  "__pycache__"
  "bin"
  "include"
  "lib"
  "sim_build"
  "synth_out"
  "*.cfg"
  "*.fst"
  "*.xml"
  "*.stems"
  "tb/__pycache__"
)

for pattern in "${CLEAN_PATHS[@]}"; do
  found=false
  for match in $pattern; do
    if [ -e "$match" ]; then
      echo -e "  \033[0;32mRemoving:\033[0m $match"
      rm -rf "$match"
      found=true
    fi
  done
  if [ "$found" = false ]; then
    echo -e "  \033[0;33mSkipping (not found):\033[0m $pattern"
  fi
done

echo -e "\033[1;32mCleanup complete.\033[0m"


