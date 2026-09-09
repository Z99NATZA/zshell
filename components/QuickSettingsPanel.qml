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

	implicitWidth: 760
	implicitHeight: 520
	margins.right: 24
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

	function connectionAngle(index, count) {
		if (count === 1) return -90
		if (count === 2) return -150 + index * 120
		if (count === 3) return -90 + index * 120
		if (count === 4) return -135 + index * 90
		if (count === 5) return -90 + index * 72

		const angles = [-140, -40, 0, 40, 140, 180]
		return angles[index]
	}

	function toggleBluetoothScan() {
		if (!bluetoothAdapter) return

		if (!bluetoothAdapter.enabled) {
			bluetoothAdapter.enabled = true
			return
		}

		bluetoothAdapter.discovering = !bluetoothAdapter.discovering
	}

	readonly property var wifiDevice: {
		const devices = Networking.devices.values
		for (let index = 0; index < devices.length; index++) {
			if (devices[index].type === DeviceType.Wifi) return devices[index]
		}
		return null
	}
	readonly property var wifiNetworks: wifiDevice
		? wifiDevice.networks.values.slice(0, 6)
		: []
	readonly property var bluetoothAdapter: Bluetooth.defaultAdapter
	readonly property var bluetoothDevices: bluetoothAdapter
		? bluetoothAdapter.devices.values.slice(0, 6)
		: []

	ShellSurface {
		id: panelSurface
		anchors.fill: parent
		raised: true
		radius: Theme.radius * 3
		opacity: UiState.quickSettingsOpen ? 1 : 0

		transform: Translate {
			y: UiState.quickSettingsOpen ? 0 : 12

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

		Item {
			id: content
			anchors.fill: parent
			anchors.margins: Theme.spacingLg

			Item {
				id: header
				anchors.left: parent.left
				anchors.right: parent.right
				anchors.top: parent.top
				height: 34

				Text {
					anchors.left: parent.left
					anchors.verticalCenter: parent.verticalCenter
					text: UiState.quickSettingsPage === "bluetooth"
						? "Bluetooth devices"
						: "Wi-Fi networks"
					color: Theme.text
					font.family: Theme.textFontFamily
					font.pixelSize: 14
					font.weight: Font.Medium
				}

				ActionButton {
					id: closeButton
					anchors.right: parent.right
					compact: true
					icon: "󰅖"
					onClicked: UiState.quickSettingsOpen = false
				}

				ActionButton {
					id: arrangeButton
					anchors.right: closeButton.left
					anchors.rightMargin: Theme.spacingXs
					compact: true
					icon: "󰆾"
					active: UiState.editMode
					onClicked: {
						UiState.editMode = !UiState.editMode
						UiState.quickSettingsOpen = false
					}
				}

				ActionButton {
					id: themeButton
					anchors.right: arrangeButton.left
					anchors.rightMargin: Theme.spacingXs
					compact: true
					icon: Theme.light ? "󰖔" : "󰖙"
					onClicked: LayoutState.themeName = Theme.light
						? "one-half-gray"
						: "one-half-light"
				}

				ShellSurface {
					id: opacityControl
					anchors.right: themeButton.left
					anchors.rightMargin: Theme.spacingSm
					width: 164
					height: 34

					Row {
						anchors.fill: parent

						ActionButton {
							compact: true
							text: "−"
							enabled: LayoutState.componentOpacity > 0
							onClicked: root.changeComponentOpacity(-0.1)
						}

						Text {
							width: opacityControl.width - 68
							height: parent.height
							text: "Opacity "
								+ Math.round(LayoutState.componentOpacity * 100) + "%"
							color: Theme.text
							horizontalAlignment: Text.AlignHCenter
							verticalAlignment: Text.AlignVCenter
							font.family: Theme.textFontFamily
							font.pixelSize: 11
						}

						ActionButton {
							compact: true
							text: "+"
							enabled: LayoutState.componentOpacity < 1
							onClicked: root.changeComponentOpacity(0.1)
						}
					}
				}
			}

			Item {
				id: connectionArea
				anchors.left: parent.left
				anchors.right: parent.right
				anchors.top: header.bottom
				anchors.topMargin: Theme.spacingSm
				anchors.bottom: footer.top
				anchors.bottomMargin: Theme.spacingSm

				Item {
					id: bluetoothPage
					anchors.fill: parent
					visible: UiState.quickSettingsPage === "bluetooth" || opacity > 0
					opacity: UiState.quickSettingsPage === "bluetooth" ? 1 : 0

					Behavior on opacity {
						NumberAnimation { duration: Theme.motionDuration }
					}

					Repeater {
						model: root.bluetoothDevices

						ConnectionCard {
							required property var modelData
							required property int index
							readonly property real angle: root.connectionAngle(index,
								root.bluetoothDevices.length) * Math.PI / 180

							x: bluetoothPage.width / 2 + Math.cos(angle) * 246 - width / 2
							y: bluetoothPage.height / 2 + Math.sin(angle) * 138 - height / 2
							icon: "󰂯"
							title: modelData.name || modelData.address
							subtitle: modelData.connected
								? "Connected" + (modelData.batteryAvailable
									? " · " + Math.round(modelData.battery * 100) + "%"
									: "")
								: (modelData.pairing ? "Pairing…"
									: (modelData.paired ? "Connect" : "Pair"))
							active: modelData.connected
							enabled: UiState.quickSettingsPage === "bluetooth"
								&& root.bluetoothAdapter && root.bluetoothAdapter.enabled
								&& !modelData.blocked
							onClicked: {
								if (modelData.connected) modelData.disconnect()
								else if (modelData.pairing) modelData.cancelPair()
								else if (modelData.paired) modelData.connect()
								else modelData.pair()
							}
						}
					}

					Item {
						anchors.centerIn: parent
						width: 156
						height: 156

						Rectangle {
							anchors.centerIn: parent
							width: 156
							height: width
							radius: width / 2
							color: "transparent"
							border.width: 1
							border.color: Theme.border
						}

						Rectangle {
							anchors.centerIn: parent
							width: 132
							height: width
							radius: width / 2
							color: "transparent"
							border.width: 1
							border.color: Theme.borderStrong
						}

						Rectangle {
							anchors.centerIn: parent
							width: 106
							height: width
							radius: width / 2
							color: Theme.surfaceSoft
							border.width: 1
							border.color: Theme.borderStrong

							Text {
								anchors.centerIn: parent
								text: root.bluetoothAdapter && root.bluetoothAdapter.enabled
									? "󰂯" : "󰂲"
								color: root.bluetoothAdapter && root.bluetoothAdapter.discovering
									? Theme.accent : Theme.text
								font.family: Theme.fontFamily
								font.pixelSize: 34
							}

							MouseArea {
								anchors.fill: parent
								hoverEnabled: true
								cursorShape: root.bluetoothAdapter
									? Qt.PointingHandCursor : Qt.ArrowCursor
								onClicked: root.toggleBluetoothScan()
							}
						}
					}

					Text {
						anchors.horizontalCenter: parent.horizontalCenter
						anchors.verticalCenter: parent.verticalCenter
						anchors.verticalCenterOffset: 96
						text: !root.bluetoothAdapter ? "No adapter"
							: (!root.bluetoothAdapter.enabled ? "Bluetooth off"
								: (root.bluetoothAdapter.discovering ? "Scanning…"
									: "Click to scan"))
						color: Theme.textMuted
						font.family: Theme.textFontFamily
						font.pixelSize: 10
					}
				}

				Item {
					id: wifiPage
					anchors.fill: parent
					visible: UiState.quickSettingsPage === "wifi" || opacity > 0
					opacity: UiState.quickSettingsPage === "wifi" ? 1 : 0

					Behavior on opacity {
						NumberAnimation { duration: Theme.motionDuration }
					}

					Repeater {
						model: root.wifiNetworks

						ConnectionCard {
							required property var modelData
							required property int index
							readonly property real angle: root.connectionAngle(index,
								root.wifiNetworks.length) * Math.PI / 180

							x: wifiPage.width / 2 + Math.cos(angle) * 246 - width / 2
							y: wifiPage.height / 2 + Math.sin(angle) * 138 - height / 2
							icon: modelData.connected ? "󰖩" : "󰖪"
							title: modelData.name
							subtitle: modelData.connected ? "Connected"
								: (modelData.stateChanging ? "Connecting…"
									: (modelData.known ? "Connect" : "Credentials required"))
							active: modelData.connected
							enabled: UiState.quickSettingsPage === "wifi"
								&& Networking.wifiEnabled
								&& (modelData.connected || modelData.known)
							onClicked: {
								if (modelData.connected) modelData.disconnect()
								else modelData.connect()
							}
						}
					}

					Item {
						anchors.centerIn: parent
						width: 156
						height: 156

						Rectangle {
							anchors.centerIn: parent
							width: 156
							height: width
							radius: width / 2
							color: "transparent"
							border.width: 1
							border.color: Theme.border
						}

						Rectangle {
							anchors.centerIn: parent
							width: 132
							height: width
							radius: width / 2
							color: "transparent"
							border.width: 1
							border.color: Theme.borderStrong
						}

						Rectangle {
							anchors.centerIn: parent
							width: 106
							height: width
							radius: width / 2
							color: Theme.surfaceSoft
							border.width: 1
							border.color: Theme.borderStrong

							Text {
								anchors.centerIn: parent
								text: Networking.wifiEnabled ? "󰖩" : "󰖪"
								color: Networking.wifiEnabled ? Theme.accent : Theme.text
								font.family: Theme.fontFamily
								font.pixelSize: 34
							}

							MouseArea {
								anchors.fill: parent
								hoverEnabled: true
								cursorShape: Qt.PointingHandCursor
								onClicked: Networking.wifiEnabled = !Networking.wifiEnabled
							}
						}
					}

					Text {
						anchors.horizontalCenter: parent.horizontalCenter
						anchors.verticalCenter: parent.verticalCenter
						anchors.verticalCenterOffset: 96
						text: Networking.wifiEnabled ? "Wi-Fi on" : "Wi-Fi off"
						color: Theme.textMuted
						font.family: Theme.textFontFamily
						font.pixelSize: 10
					}
				}
			}

			Item {
				id: footer
				anchors.left: parent.left
				anchors.right: parent.right
				anchors.bottom: parent.bottom
				height: 42

				Text {
					anchors.left: parent.left
					anchors.verticalCenter: parent.verticalCenter
					text: UiState.quickSettingsPage === "bluetooth"
						? root.bluetoothDevices.length + " devices"
						: root.wifiNetworks.length + " networks"
					color: Theme.textMuted
					font.family: Theme.textFontFamily
					font.pixelSize: 10
				}

				ShellSurface {
					id: modeSwitch
					anchors.horizontalCenter: parent.horizontalCenter
					width: 280
					height: 42

					Row {
						anchors.fill: parent
						anchors.margins: 4
						spacing: 4

						ActionButton {
							width: (parent.width - parent.spacing) / 2
							height: parent.height
							icon: "󰖩"
							text: "Wi-Fi"
							active: UiState.quickSettingsPage === "wifi"
							onClicked: UiState.quickSettingsPage = "wifi"
						}

						ActionButton {
							width: (parent.width - parent.spacing) / 2
							height: parent.height
							icon: "󰂯"
							text: "Bluetooth"
							active: UiState.quickSettingsPage === "bluetooth"
							onClicked: UiState.quickSettingsPage = "bluetooth"
						}
					}
				}

				ActionButton {
					anchors.right: parent.right
					anchors.verticalCenter: parent.verticalCenter
					compact: true
					icon: "󰐥"
					onClicked: Quickshell.execDetached(["hypr-power-menu"])
				}
			}
		}
	}
}
