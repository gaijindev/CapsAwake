#!/bin/zsh
set -euo pipefail

format_bin="$(xcrun --find swift-format)"
"$format_bin" lint --recursive Sources Tests
