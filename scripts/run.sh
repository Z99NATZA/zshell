#!/usr/bin/env bash

set -euo pipefail

project_directory=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
shell_pid=""

stop_shell() {
	local exit_status="$1"

	trap - EXIT HUP INT TERM
	if [[ -n "$shell_pid" ]] && kill -0 "$shell_pid" 2>/dev/null; then
		kill -TERM "$shell_pid" 2>/dev/null || true
		wait "$shell_pid" 2>/dev/null || true
	fi

	exit "$exit_status"
}

if ! command -v qs >/dev/null 2>&1; then
	printf '%s\n' 'Quickshell is required. See docs/runtime-integration.md.' >&2
	exit 127
fi

trap 'stop_shell $?' EXIT
trap 'stop_shell 129' HUP
trap 'stop_shell 130' INT
trap 'stop_shell 143' TERM

qs -p "$project_directory" &
shell_pid=$!
wait "$shell_pid"
