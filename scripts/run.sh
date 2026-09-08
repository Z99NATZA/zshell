#!/usr/bin/env bash

set -euo pipefail

project_directory=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)

if ! command -v qs >/dev/null 2>&1; then
	printf '%s\n' 'Quickshell is required. See docs/runtime-integration.md.' >&2
	exit 127
fi

exec qs -p "$project_directory"
