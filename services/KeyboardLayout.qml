pragma Singleton

import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import QtQuick

Singleton {
	id: root

	readonly property var layoutAliases: ({
		"english": "EN",
		"thai": "TH"
	})
	property string code: "--"
	property bool refreshPending: false

	function labelFor(keymap) {
		const normalized = keymap.trim().toLowerCase()
		const aliases = Object.keys(layoutAliases)

		for (let index = 0; index < aliases.length; index++) {
			const name = aliases[index]
			if (normalized.includes(name)) return layoutAliases[name]
		}

		return normalized.length > 0 ? normalized.slice(0, 2).toUpperCase() : "--"
	}

	function applyDevices(rawDevices) {
		try {
			const keyboards = JSON.parse(rawDevices).keyboards || []
			let keyboard = keyboards.length > 0 ? keyboards[0] : null

			for (let index = 0; index < keyboards.length; index++) {
				if (keyboards[index].main) {
					keyboard = keyboards[index]
					break
				}
			}

			code = keyboard ? labelFor(keyboard.active_keymap || "") : "--"
		} catch (error) {
			code = "--"
		}
	}

	function refresh() {
		if (deviceQuery.running) {
			refreshPending = true
			return
		}

		deviceQuery.running = true
	}

	Component.onCompleted: refresh()

	Connections {
		target: Hyprland

		function onRawEvent(event) {
			if (event.name === "activelayout") root.refresh()
		}
	}

	Process {
		id: deviceQuery
		command: ["hyprctl", "devices", "-j"]

		stdout: StdioCollector {
			onStreamFinished: root.applyDevices(text)
		}

		onRunningChanged: {
			if (!running && root.refreshPending) {
				root.refreshPending = false
				root.refresh()
			}
		}
	}
}
