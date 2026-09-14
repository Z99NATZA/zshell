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
	readonly property var layoutDefinitions: ({
		"us": { code: "EN", label: "English" },
		"th": { code: "TH", label: "ไทย" }
	})
	property string code: "--"
	property string keyboardName: ""
	property var layouts: []
	property int activeLayoutIndex: -1
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

	function layoutOption(layoutName) {
		const normalized = layoutName.trim().toLowerCase()
		const definition = layoutDefinitions[normalized]
		if (definition) {
			return {
				name: normalized,
				code: definition.code,
				label: definition.label
			}
		}

		return {
			name: normalized,
			code: normalized.length > 0
				? normalized.slice(0, 2).toUpperCase() : "--",
			label: normalized.length > 0 ? normalized.toUpperCase() : "Unknown"
		}
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

			if (!keyboard) {
				keyboardName = ""
				layouts = []
				activeLayoutIndex = -1
				code = "--"
				return
			}

			keyboardName = keyboard.name || ""
			const configuredLayouts = (keyboard.layout || "").split(",")
			const nextLayouts = []
			for (let index = 0; index < configuredLayouts.length; index++) {
				const layoutName = configuredLayouts[index].trim()
				if (layoutName.length > 0) nextLayouts.push(layoutOption(layoutName))
			}

			layouts = nextLayouts
			const nextIndex = Number(keyboard.active_layout_index)
			activeLayoutIndex = nextIndex >= 0 && nextIndex < nextLayouts.length
				? nextIndex : -1
			code = labelFor(keyboard.active_keymap || "")
		} catch (error) {
			keyboardName = ""
			layouts = []
			activeLayoutIndex = -1
			code = "--"
		}
	}

	function selectLayout(index) {
		if (!keyboardName || index < 0 || index >= layouts.length) return
		Quickshell.execDetached([
			"hyprctl", "switchxkblayout", keyboardName, String(index)
		])
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
