import QtQuick
import Quickshell
import Quickshell.Networking
import Quickshell.Bluetooth
import qs.state
import qs.theme

PanelWindow {
	id: root

	anchors {
		right: true
		bottom: true
	}

	implicitWidth: 348
	implicitHeight: panelContent.implicitHeight + Theme.spacingLg * 2
	margins.right: 12
	margins.bottom: 108
	color: "transparent"
	visible: UiState.quickSettingsOpen || panelSurface.opacity > 0
	focusable: UiState.quickSettingsOpen
	aboveWindows: true
	exclusionMode: ExclusionMode.Ignore

	function changeComponentOpacity(delta) {
		const nextValue = Math.round((LayoutState.componentOpacity + delta) * 10) / 10
		LayoutState.componentOpacity = Math.max(0, Math.min(1, nextValue))
	}

	readonly property var wifiDevice: {
		const devices = Networking.devices.values
		for (let index = 0; index < devices.length; index++) {
			if (devices[index].type === DeviceType.Wifi) return devices[index]
		}
		return null
	}

	readonly property var wifiNetworks: wifiDevice
		? wifiDevice.networks.values.slice(0, 4)
		: []
	readonly property var bluetoothAdapter: Bluetooth.defaultAdapter
	readonly property var connectedBluetoothDevices: bluetoothAdapter
		? bluetoothAdapter.devices.values.slice(0, 3)
		: []

	ShellSurface {
		id: panelSurface
		anchors.fill: parent
		raised: true
		opacity: UiState.quickSettingsOpen ? 1 : 0

		transform: Translate {
			y: UiState.quickSettingsOpen ? 0 : 8

			Behavior on y {
				NumberAnimation {
					duration: Theme.motionDuration
					easing.type: Easing.OutCubic
				}
			}
		}

		Behavior on opacity {
			NumberAnimation {
				duration: Theme.motionDuration
				easing.type: Easing.OutCubic
			}
		}

		Column {
			id: panelContent
			anchors.fill: parent
			anchors.margins: Theme.spacingLg
			spacing: Theme.spacingSm

			Row {
				width: parent.width
				spacing: Theme.spacingSm

				ActionButton {
					width: (parent.width - closeButton.width - Theme.spacingSm * 2) / 2
					icon: Networking.wifiEnabled ? "󰖩" : "󰖪"
					text: root.wifiDevice && root.wifiDevice.connected ? "Connected" : "Wi-Fi"
					active: Networking.wifiEnabled
					onClicked: Networking.wifiEnabled = !Networking.wifiEnabled
				}

				ActionButton {
					width: (parent.width - closeButton.width - Theme.spacingSm * 2) / 2
					icon: root.bluetoothAdapter && root.bluetoothAdapter.enabled ? "󰂯" : "󰂲"
					text: "Bluetooth"
					active: root.bluetoothAdapter && root.bluetoothAdapter.enabled
					enabled: root.bluetoothAdapter !== null
					onClicked: root.bluetoothAdapter.enabled = !root.bluetoothAdapter.enabled
				}

				ActionButton {
					id: closeButton
					compact: true
					icon: "󰅖"
					onClicked: UiState.quickSettingsOpen = false
				}
			}

			Rectangle {
				width: parent.width
				height: 1
				color: Theme.border
			}

			Repeater {
				model: root.wifiNetworks

				ActionButton {
					required property var modelData
					width: panelContent.width
					icon: modelData.connected ? "󰖩" : "󰖪"
					text: modelData.name
					active: modelData.connected
					enabled: modelData.connected || modelData.known
					onClicked: {
						if (modelData.connected) modelData.disconnect()
						else modelData.connect()
					}
				}
			}

			Repeater {
				model: root.connectedBluetoothDevices

				ActionButton {
					required property var modelData
					width: panelContent.width
					icon: modelData.connected ? "󰂱" : "󰂯"
					text: modelData.name
					active: modelData.connected
					onClicked: modelData.disconnect()
				}
			}

			Rectangle {
				width: parent.width
				height: 1
				color: Theme.border
			}

			Row {
				width: parent.width
				spacing: Theme.spacingSm

				ActionButton {
					width: (parent.width - Theme.spacingSm) / 2
					icon: "󰏘"
					text: Theme.light ? "Light" : "Gray"
					onClicked: LayoutState.themeName = Theme.light
						? "one-half-gray"
						: "one-half-light"
				}

				ActionButton {
					width: (parent.width - Theme.spacingSm) / 2
					icon: "󰆾"
					text: UiState.editMode ? "Done" : "Arrange"
					active: UiState.editMode
					onClicked: {
						UiState.editMode = !UiState.editMode
						UiState.quickSettingsOpen = false
					}
				}
			}

			Rectangle {
				width: parent.width
				height: 1
				color: Theme.border
			}

			Row {
				id: opacityRow
				width: parent.width
				spacing: Theme.spacingSm

				Text {
					width: opacityRow.width - decreaseOpacity.width
						- increaseOpacity.width - opacityRow.spacing * 2
					height: 34
					text: "Opacity  " + Math.round(LayoutState.componentOpacity * 100) + "%"
					color: Theme.text
					verticalAlignment: Text.AlignVCenter
					font.family: Theme.textFontFamily
					font.pixelSize: 12
				}

				ActionButton {
					id: decreaseOpacity
					compact: true
					text: "−"
					enabled: LayoutState.componentOpacity > 0
					onClicked: root.changeComponentOpacity(-0.1)
				}

				ActionButton {
					id: increaseOpacity
					compact: true
					text: "+"
					enabled: LayoutState.componentOpacity < 1
					onClicked: root.changeComponentOpacity(0.1)
				}
			}
		}
	}
}
