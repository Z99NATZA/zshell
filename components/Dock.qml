import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Networking
import Quickshell.Bluetooth
import qs.services
import qs.state
import qs.theme

PanelWindow {
	id: root

	anchors {
		left: true
		right: true
		bottom: true
	}

	implicitHeight: 44
	margins.left: 12
	margins.right: 12
	margins.bottom: 54
	color: "transparent"
	exclusiveZone: 0
	aboveWindows: true
	readonly property int statusLabelLimit: 12

	function limitedStatusLabel(value, suffix) {
		const label = value || ""
		const ending = (suffix || "").slice(0, statusLabelLimit)
		const available = statusLabelLimit - ending.length

		if (available === 0) return ending
		if (label.length <= available) return label + ending
		if (available === 1) return "…" + ending
		return label.slice(0, available - 1) + "…" + ending
	}

	readonly property var wifiDevice: {
		const devices = Networking.devices.values
		for (let index = 0; index < devices.length; index++) {
			if (devices[index].type === DeviceType.Wifi) return devices[index]
		}
		return null
	}

	readonly property var connectedNetwork: {
		if (!wifiDevice) return null
		const networks = wifiDevice.networks.values
		for (let index = 0; index < networks.length; index++) {
			if (networks[index].connected) return networks[index]
		}
		return null
	}
	readonly property string wifiLabel: connectedNetwork
		? limitedStatusLabel(connectedNetwork.name, "")
		: ""

	readonly property var bluetoothAdapter: Bluetooth.defaultAdapter
	readonly property var connectedBluetoothDevices: {
		if (!bluetoothAdapter) return []

		const connected = []
		const devices = bluetoothAdapter.devices.values
		for (let index = 0; index < devices.length; index++) {
			if (devices[index].connected) connected.push(devices[index])
		}
		return connected
	}
	readonly property string bluetoothLabel: {
		if (connectedBluetoothDevices.length === 0) return ""

		const extra = connectedBluetoothDevices.length - 1
		const suffix = extra > 0 ? " +" + extra : ""
		return limitedStatusLabel(connectedBluetoothDevices[0].name, suffix)
	}

	SystemClock {
		id: clock
		precision: SystemClock.Seconds
	}

	mask: Region {
		Region { item: editIsland }
		Region { item: workspaceIsland }
		Region { item: statusIsland }
	}

	ShellSurface {
		id: editIsland
		anchors.left: parent.left
		anchors.verticalCenter: parent.verticalCenter
		width: editRow.width + Theme.spacingSm * 2
		height: parent.height
		raised: true

		Row {
			id: editRow
			anchors.centerIn: parent
			spacing: 2

			LanguageIndicator {
				code: KeyboardLayout.code
				shown: LayoutState.showLanguageLeft
			}

			ActionButton {
				id: editButton
				compact: !UiState.editMode
				icon: "󰆾"
				text: UiState.editMode ? "Done" : ""
				active: UiState.editMode
				onClicked: UiState.editMode = !UiState.editMode
			}
		}
	}

	Item {
		id: workspaceIsland
		anchors.horizontalCenter: parent.horizontalCenter
		anchors.verticalCenter: parent.verticalCenter
		width: workspaceRow.width
		height: parent.height

		Row {
			id: workspaceRow
			anchors.centerIn: parent
			spacing: Theme.spacingXs

			Text {
				width: 30
				height: 30
				text: Theme.workspaceIcon
				color: Theme.text
				horizontalAlignment: Text.AlignHCenter
				verticalAlignment: Text.AlignVCenter
				font.family: Theme.fontFamily
				font.pixelSize: 15
			}

			Repeater {
				model: 5

				Rectangle {
					id: workspaceButton

					required property int index
					readonly property bool active: Hyprland.focusedWorkspace
						&& Hyprland.focusedWorkspace.id === index + 1

					width: 30
					height: 30
					radius: height / 2
					color: active
						? Theme.text
						: (workspacePointer.containsMouse ? Theme.surfaceSoft : "transparent")

					Behavior on color {
						ColorAnimation { duration: Theme.motionDuration }
					}

					Text {
						anchors.centerIn: parent
						text: String(workspaceButton.index + 1)
						color: workspaceButton.active ? Theme.background : Theme.textMuted
						font.family: Theme.textFontFamily
						font.pixelSize: 12

						Behavior on color {
							ColorAnimation { duration: Theme.motionDuration }
						}
					}

					MouseArea {
						id: workspacePointer
						anchors.fill: parent
						hoverEnabled: true
						cursorShape: Qt.PointingHandCursor
						onClicked: Hyprland.dispatch("workspace " + (workspaceButton.index + 1))
					}
				}
			}
		}
	}

	ShellSurface {
		id: statusIsland
		anchors.right: parent.right
		anchors.verticalCenter: parent.verticalCenter
		width: statusRow.width + Theme.spacingSm * 2
		height: parent.height
		raised: true

		Row {
			id: statusRow
			anchors.centerIn: parent
			spacing: 2

			ActionButton {
				icon: AudioOutput.icon
				text: AudioOutput.label
				enabled: AudioOutput.available
				wheelEnabled: true
				onClicked: AudioOutput.toggleMute()
				onWheelUp: AudioOutput.changeVolume(5)
				onWheelDown: AudioOutput.changeVolume(-5)
			}

			ActionButton {
				compact: root.connectedNetwork === null
				icon: root.connectedNetwork ? "󰖩" : "󰖪"
				text: root.wifiLabel
				onClicked: {
					UiState.quickSettingsPage = "wifi"
					UiState.quickSettingsOpen = !UiState.quickSettingsOpen
				}
			}

			ActionButton {
				compact: root.connectedBluetoothDevices.length === 0
				icon: root.bluetoothAdapter && root.bluetoothAdapter.enabled ? "󰂯" : "󰂲"
				text: root.bluetoothLabel
				onClicked: {
					UiState.quickSettingsPage = "bluetooth"
					UiState.quickSettingsOpen = !UiState.quickSettingsOpen
				}
			}

			ActionButton {
				text: Qt.formatDateTime(clock.date, "HH:mm:ss")
				onClicked: UiState.quickSettingsOpen = !UiState.quickSettingsOpen
			}

			LanguageIndicator {
				code: KeyboardLayout.code
				shown: LayoutState.showLanguageRight
			}

			ActionButton {
				compact: true
				icon: "󰐥"
				onClicked: Quickshell.execDetached(["hypr-power-menu"])
			}
		}
	}
}
