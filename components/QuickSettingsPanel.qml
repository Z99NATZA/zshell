import QtQuick
import Quickshell
import Quickshell.Networking
import Quickshell.Bluetooth
import qs.state
import qs.theme

PanelWindow {
	id: root

	anchors {
		left: true
		right: true
		top: true
		bottom: true
	}

	implicitWidth: screen.width
	implicitHeight: screen.height
	color: "transparent"
	visible: modalVisible
	focusable: modalVisible
	aboveWindows: true
	exclusionMode: ExclusionMode.Ignore

	property bool modalVisible: false
	property bool closing: false
	property real settledX: 0
	property real settledY: 0

	function clampedX(value) {
		return Math.max(12, Math.min(screen.width - panelSurface.width - 12, value))
	}

	function clampedY(value) {
		return Math.max(12, Math.min(screen.height - panelSurface.height - 72, value))
	}

	function storedX() {
		return clampedX(LayoutState.quickSettingsX < 0
			? screen.width - panelSurface.width - 24
			: LayoutState.quickSettingsX)
	}

	function storedY() {
		return clampedY(LayoutState.quickSettingsY < 0
			? screen.height - panelSurface.height - 108
			: LayoutState.quickSettingsY)
	}

	function scheduleOpen() {
		modalVisible = true
		openTimer.restart()
	}

	function dockTargetX() {
		const centerX = UiState.quickSettingsTargetX < 0
			? screen.width - 160 : UiState.quickSettingsTargetX
		return centerX - panelSurface.width / 2
	}

	function dockTargetY() {
		const centerY = UiState.quickSettingsTargetY < 0
			? screen.height - 76 : UiState.quickSettingsTargetY
		return centerY - panelSurface.height / 2
	}

	function commitPosition(panelX, panelY) {
		settledX = clampedX(panelX)
		settledY = clampedY(panelY)
		panelSurface.x = settledX
		panelSurface.y = settledY
		LayoutState.quickSettingsX = Math.round(settledX)
		LayoutState.quickSettingsY = Math.round(settledY)
	}

	function openPanel() {
		closeAnimation.stop()
		closing = false
		modalVisible = true
		settledX = storedX()
		settledY = storedY()
		panelSurface.x = dockTargetX()
		panelSurface.y = dockTargetY()
		panelSurface.scale = 0.12
		panelSurface.opacity = 0
		openAnimation.restart()
		focusTimer.restart()
	}

	function beginClose() {
		if (!modalVisible || closing) return

		closing = true
		openAnimation.stop()
		LayoutState.quickSettingsX = Math.round(settledX)
		LayoutState.quickSettingsY = Math.round(settledY)
		closeAnimation.restart()
	}

	function requestClose() {
		if (!modalVisible || closing) return

		if (UiState.quickSettingsOpen) UiState.quickSettingsOpen = false
		else beginClose()
	}

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

	Component.onCompleted: {
		if (UiState.quickSettingsOpen) scheduleOpen()
	}

	onClosed: UiState.quickSettingsOpen = false

	Connections {
		target: UiState

		function onQuickSettingsOpenChanged() {
			if (UiState.quickSettingsOpen) root.scheduleOpen()
			else root.beginClose()
		}
	}

	Timer {
		id: openTimer
		interval: 0
		onTriggered: root.openPanel()
	}

	Timer {
		id: focusTimer
		interval: 0
		onTriggered: modalInput.forceActiveFocus()
	}

	ParallelAnimation {
		id: openAnimation

		NumberAnimation {
			target: panelSurface
			property: "x"
			to: root.settledX
			duration: Theme.modalOpenDuration
			easing.type: Easing.OutCubic
		}

		NumberAnimation {
			target: panelSurface
			property: "y"
			to: root.settledY
			duration: Theme.modalOpenDuration
			easing.type: Easing.OutCubic
		}

		NumberAnimation {
			target: panelSurface
			property: "scale"
			to: 1
			duration: Theme.modalOpenDuration
			easing.type: Easing.OutCubic
		}

		NumberAnimation {
			target: panelSurface
			property: "opacity"
			to: 1
			duration: Theme.modalCloseDuration
			easing.type: Easing.OutCubic
		}
	}

	ParallelAnimation {
		id: closeAnimation

		NumberAnimation {
			target: panelSurface
			property: "x"
			to: root.dockTargetX()
			duration: Theme.modalCloseDuration
			easing.type: Easing.InCubic
		}

		NumberAnimation {
			target: panelSurface
			property: "y"
			to: root.dockTargetY()
			duration: Theme.modalCloseDuration
			easing.type: Easing.InCubic
		}

		NumberAnimation {
			target: panelSurface
			property: "scale"
			to: 0.12
			duration: Theme.modalCloseDuration
			easing.type: Easing.InCubic
		}

		NumberAnimation {
			target: panelSurface
			property: "opacity"
			to: 0
			duration: Theme.motionDuration
			easing.type: Easing.InCubic
		}

		onFinished: {
			root.modalVisible = false
			root.closing = false
			panelSurface.x = root.settledX
			panelSurface.y = root.settledY
			panelSurface.scale = 1
			panelSurface.opacity = 1

			if (UiState.quickSettingsOpen) root.openPanel()
		}
	}

	Item {
		id: modalInput
		width: root.screen.width
		height: root.screen.height
		focus: root.modalVisible
		Keys.priority: Keys.BeforeItem
		Keys.onEscapePressed: event => {
			root.requestClose()
			event.accepted = true
		}

		MouseArea {
			anchors.fill: parent
			enabled: !root.closing
			onClicked: root.requestClose()
		}
	}

	ShellSurface {
		id: panelSurface
		width: 760
		height: 520
		raised: true
		radius: Theme.radius * 3
		transformOrigin: Item.Center

		MouseArea {
			anchors.fill: parent
			onClicked: mouse => mouse.accepted = true
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

				Item {
					id: dragArea
					anchors.left: parent.left
					anchors.right: opacityControl.left
					anchors.rightMargin: Theme.spacingMd
					anchors.top: parent.top
					anchors.bottom: parent.bottom

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

					DragHandler {
						id: panelDrag
						enabled: root.modalVisible && !root.closing
							&& !openAnimation.running
						target: panelSurface
						xAxis.minimum: 12
						xAxis.maximum: root.screen.width - panelSurface.width - 12
						yAxis.minimum: 12
						yAxis.maximum: root.screen.height - panelSurface.height - 72
						onActiveChanged: {
							if (!active) root.commitPosition(panelSurface.x, panelSurface.y)
						}
					}
				}

				ActionButton {
					id: arrangeButton
					anchors.right: parent.right
					compact: true
					icon: "󰆾"
					active: UiState.editMode
					onClicked: {
						UiState.editMode = !UiState.editMode
						root.requestClose()
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

			}
		}
	}
}
