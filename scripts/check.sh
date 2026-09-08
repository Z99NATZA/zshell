#!/usr/bin/env bash

set -euo pipefail

project_directory=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)

bash -n "$project_directory/scripts/run.sh" "$project_directory/scripts/check.sh"

required_files=(
	AGENTS.md
	README.md
	shell.qml
	docs/agent-work-priority.md
	docs/architecture.md
	docs/design-system.md
)

for file in "${required_files[@]}"; do
	if [[ ! -s "$project_directory/$file" ]]; then
		printf 'Missing required file: %s\n' "$file" >&2
		exit 1
	fi
done

if rg -n --glob '*.qml' '#[0-9A-Fa-f]{6}' \
	"$project_directory/components" "$project_directory/state"; then
	printf '%s\n' 'Raw colors must stay in theme/Theme.qml.' >&2
	exit 1
fi

if command -v qmllint >/dev/null 2>&1; then
	mapfile -t qml_files < <(rg --files -g '*.qml' "$project_directory")
	qmllint "${qml_files[@]}"
else
	printf '%s\n' 'qmllint not found; skipped QML semantic checks.'
fi

printf '%s\n' 'Repository checks passed.'
