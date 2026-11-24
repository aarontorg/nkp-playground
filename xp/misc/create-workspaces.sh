#!/usr/bin/env bash
set -euo pipefail

WORKSPACES=(
  "workspace-0"
  "workspace-1"
  "workspace-2"
)

for ws in "${WORKSPACES[@]}"; do
  nkp create workspace "$ws"
done
