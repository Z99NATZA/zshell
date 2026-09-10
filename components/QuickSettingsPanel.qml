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
	aboveWindows: UiState.activeComponent === "quickSettings"
	exclusionMode: ExclusionMode.Ignore

	property bool modalVisible: false
	property bool closing: false
	property bool pinned: false
	property real settledX: 0
	property real settledY: 0
	property string selectedConnectionKind: ""
	property string selectedConnectionKey: ""
	readonly property var selectedConnection: connectionForKey(
		selectedConnectionKind === "bluetooth"
			? radarBluetoothDevices : radarWifiNetworks,
		selectedConnectionKind, selectedConnectionKey)
	readonly property bool connectionInspectorOpen: selectedConnection !== null
		&& selectedConnectionKind === UiState.quickSettingsPage

	mask: Region {
		item: root.pinned ? panelSurface : modalInput
		radius: root.pinned ? panelSurface.radius : 0
	}

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
		pinned = false
		UiState.activateComponent("quickSettings")
		clearConnectionSelection()
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
		pinned = false
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

	function setComponentOpacity(value) {
		const steppedValue = Math.round(value * 10) / 10
		LayoutState.componentOpacity = Math.max(0, Math.min(1, steppedValue))
	}

	function connectionForKey(items, kind, key) {
		if (!key) return null

		for (let index = 0; index < items.length; index++) {
			if (connectionKey(items[index], kind) === key) return items[index]
		}

		return null
	}

	function selectConnection(item, kind) {
		const key = connectionKey(item, kind)
		if (selectedConnectionKind === kind && selectedConnectionKey === key) {
			clearConnectionSelection()
			return
		}

		selectedConnectionKind = kind
		selectedConnectionKey = key
	}

	function clearConnectionSelection() {
		selectedConnectionKind = ""
		selectedConnectionKey = ""
	}

	function connectionSelected(item, kind) {
		return selectedConnectionKind === kind
			&& selectedConnectionKey === connectionKey(item, kind)
	}

	function wifiSecurityLabel(security) {
		switch (security) {
		case WifiSecurityType.Open: return "Open"
		case WifiSecurityType.WpaPsk: return "WPA Personal"
		case WifiSecurityType.Wpa2Psk: return "WPA2 Personal"
		case WifiSecurityType.Sae: return "WPA3 Personal"
		case WifiSecurityType.WpaEap: return "WPA Enterprise"
		case WifiSecurityType.Wpa2Eap: return "WPA2 Enterprise"
		case WifiSecurityType.Wpa3SuiteB192: return "WPA3 Enterprise"
		case WifiSecurityType.StaticWep:
		case WifiSecurityType.DynamicWep: return "WEP"
		case WifiSecurityType.Owe: return "Enhanced Open"
		default: return "Unknown"
		}
	}

	function selectedConnectionStatus() {
		const item = selectedConnection
		if (!item) return ""

		if (selectedConnectionKind === "wifi") {
			if (item.connected) return "Connected to this network"
			if (item.stateChanging) return "Connection in progress…"
			if (item.known) return "Saved network · Ready to connect"
			return "Credentials are required to connect"
		}

		if (item.blocked) return "Blocked by the Bluetooth service"
		if (item.connected) return "Connected to this device"
		if (item.pairing) return "Pairing in progress…"
		if (item.paired) return "Paired device · Ready to connect"
		return "Available to pair"
	}

	function selectedActionText() {
		const item = selectedConnection
		if (!item) return ""
		if (selectedConnectionKind === "bluetooth" && item.blocked) return "Blocked"
		if (item.connected) return "Disconnect"

		if (selectedConnectionKind === "wifi") {
			if (item.stateChanging) return "Working…"
			return item.known ? "Connect" : "Credentials required"
		}

		if (item.pairing) return "Cancel pairing"
		return item.paired ? "Connect" : "Pair device"
	}

	function selectedActionEnabled() {
		const item = selectedConnection
		if (!item) return false

		if (selectedConnectionKind === "wifi") {
			return Networking.wifiEnabled && !item.stateChanging
				&& (item.connected || item.known)
		}

		return bluetoothAdapter && bluetoothAdapter.enabled && !item.blocked
	}

	function performSelectedConnectionAction() {
		const item = selectedConnection
		if (!item || !selectedActionEnabled()) return

		if (item.connected) {
			item.disconnect()
			return
		}

		if (selectedConnectionKind === "wifi") item.connect()
		else if (item.pairing) item.cancelPair()
		else if (item.paired) item.connect()
		else item.pair()
	}

	function connectionKey(item, kind) {
		const identity = kind === "bluetooth"
			? (item.address || item.name)
			: item.name
		return kind + ":" + (identity || "unknown")
	}

	function stableHash(value) {
		let hash = 0
		const text = String(value)

		for (let index = 0; index < text.length; index++) {
			hash = ((hash << 5) - hash + text.charCodeAt(index)) | 0
		}

		return Math.abs(hash)
	}

	function radarItems(items, kind) {
		const copy = items.slice()
		copy.sort((first, second) => stableHash(connectionKey(first, kind))
			- stableHash(connectionKey(second, kind)))
		return copy
	}

	function radarTargets(items, kind) {
		return items.map(item => ({
			key: connectionKey(item, kind),
			active: !!item.connected,
			selected: connectionSelected(item, kind)
		}))
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
	readonly property var radarWifiNetworks: radarItems(wifiNetworks, "wifi")
	readonly property var bluetoothAdapter: Bluetooth.defaultAdapter
	readonly property var bluetoothDevices: bluetoothAdapter
		? bluetoothAdapter.devices.values.slice(0, 6)
		: []
	readonly property var radarBluetoothDevices: radarItems(bluetoothDevices,
		"bluetooth")

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

		function onQuickSettingsPageChanged() {
			root.clearConnectionSelection()
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
			else UiState.releaseComponent("quickSettings")
		}
	}

	Item {
		id: modalInput
		width: root.screen.width
		height: root.screen.height
		focus: root.modalVisible
		Keys.priority: Keys.BeforeItem
		Keys.onEscapePressed: event => {
			if (root.connectionInspectorOpen) root.clearConnectionSelection()
			else root.requestClose()
			event.accepted = true
		}

		MouseArea {
			anchors.fill: parent
			enabled: !root.closing && !root.pinned
			onClicked: root.requestClose()
		}
	}

	ShellSurface {
		id: panelSurface
		width: 960
		height: 680
		raised: true
		interactive: UiState.activeComponent === "quickSettings"
			|| panelDragArea.pressed
		radius: Theme.radius * 3
		transformOrigin: Item.Center

		MouseArea {
			anchors.fill: parent
			onPressed: UiState.activateComponent("quickSettings")
			onClicked: mouse => mouse.accepted = true
		}

		MouseArea {
			id: panelDragArea
			anchors.left: parent.left
			anchors.right: parent.right
			anchors.top: parent.top
			height: Theme.spacingLg + header.height
			enabled: root.modalVisible && !root.closing && !openAnimation.running
			hoverEnabled: true
			cursorShape: pressed ? Qt.ClosedHandCursor : Qt.OpenHandCursor
			drag.target: panelSurface
			drag.minimumX: 12
			drag.maximumX: root.screen.width - panelSurface.width - 12
			drag.minimumY: 12
			drag.maximumY: root.screen.height - panelSurface.height - 72
			drag.smoothed: true
			onPressed: UiState.activateComponent("quickSettings")
			onReleased: root.commitPosition(panelSurface.x, panelSurface.y)
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
					id: titleArea
					anchors.left: parent.left
					anchors.right: opacityControl.left
					anchors.rightMargin: Theme.spacingMd
					anchors.top: parent.top
					anchors.bottom: parent.bottom

					Text {
						anchors.left: parent.left
						anchors.leftMargin: Theme.spacingSm
						anchors.verticalCenter: parent.verticalCenter
						text: UiState.quickSettingsPage === "bluetooth"
							? "Bluetooth devices"
							: "Wi-Fi networks"
						color: Theme.text
						font.family: Theme.textFontFamily
						font.pixelSize: 14
						font.weight: Font.Medium
					}
				}

				ActionButton {
					id: closeButton
					anchors.right: parent.right
					compact: true
					icon: "󰅖"
					onClicked: root.requestClose()
				}

				ActionButton {
					id: pinButton
					anchors.right: closeButton.left
					anchors.rightMargin: Theme.spacingXs
					compact: true
					icon: "󰐃"
					active: root.pinned
					onClicked: root.pinned = !root.pinned
				}

				ActionButton {
					id: arrangeButton
					anchors.right: pinButton.left
					anchors.rightMargin: Theme.spacingXs
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

				Item {
					id: opacityControl
					anchors.right: themeButton.left
					anchors.rightMargin: Theme.spacingSm
					width: 164
					height: 34

					Text {
						id: opacityLabel
						anchors.left: parent.left
						anchors.leftMargin: Theme.spacingSm
						anchors.verticalCenter: parent.verticalCenter
						text: "Opacity"
						color: Theme.text
						font.family: Theme.textFontFamily
						font.pixelSize: 11
					}

					Item {
						id: opacityInput
						anchors.left: opacityLabel.right
						anchors.leftMargin: Theme.spacingXs
						anchors.right: opacityValue.left
						anchors.rightMargin: Theme.spacingXs
						anchors.top: parent.top
						anchors.bottom: parent.bottom

						Rectangle {
							id: opacityTrack
							anchors.left: parent.left
							anchors.right: parent.right
							anchors.verticalCenter: parent.verticalCenter
							height: 4
							radius: height / 2
							color: Theme.textMuted
							opacity: 0.45

							Rectangle {
								width: LayoutState.componentOpacity * parent.width
								height: parent.height
								radius: parent.radius
								color: Theme.accent
							}
						}

						Rectangle {
							id: opacityHandle
							x: LayoutState.componentOpacity * (opacityInput.width - width)
							anchors.verticalCenter: parent.verticalCenter
							width: 12
							height: 12
							radius: width / 2
							color: opacityPointer.pressed ? Theme.accent : Theme.text
							border.width: 1
							border.color: Theme.accent
						}

						MouseArea {
							id: opacityPointer
							anchors.fill: parent
							hoverEnabled: true
							cursorShape: Qt.PointingHandCursor
							onPressed: mouse => root.setComponentOpacity(mouse.x / width)
							onPositionChanged: mouse => {
								if (pressed) root.setComponentOpacity(mouse.x / width)
							}
							onWheel: wheel => {
								if (wheel.angleDelta.y === 0) return

								root.setComponentOpacity(LayoutState.componentOpacity
									+ (wheel.angleDelta.y > 0 ? 0.1 : -0.1))
								wheel.accepted = true
							}
						}
					}

					Text {
						id: opacityValue
						anchors.right: parent.right
						anchors.rightMargin: Theme.spacingSm
						anchors.verticalCenter: parent.verticalCenter
						width: 28
						text: Math.round(LayoutState.componentOpacity * 100) + "%"
						color: Theme.text
						horizontalAlignment: Text.AlignRight
						font.family: Theme.textFontFamily
						font.pixelSize: 11
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
				readonly property real inspectorWidth: 248
				readonly property real inspectorGap: Theme.spacingLg
				readonly property real radarCenterX: root.connectionInspectorOpen
					? (width - inspectorWidth - inspectorGap) / 2 : width / 2

				Item {
					id: bluetoothPage
					anchors.fill: parent
					visible: UiState.quickSettingsPage === "bluetooth" || opacity > 0
					opacity: UiState.quickSettingsPage === "bluetooth" ? 1 : 0

					Behavior on opacity {
						NumberAnimation { duration: Theme.motionDuration }
					}

					MouseArea {
						anchors.fill: parent
						onClicked: root.clearConnectionSelection()
					}

					RadarField {
						id: bluetoothRadar
						x: connectionArea.radarCenterX - width / 2
						anchors.verticalCenter: parent.verticalCenter
						targets: root.radarTargets(root.radarBluetoothDevices, "bluetooth")
						active: root.bluetoothAdapter && root.bluetoothAdapter.enabled
						busy: root.bluetoothAdapter && root.bluetoothAdapter.discovering
						motionEnabled: root.modalVisible && !root.closing
							&& UiState.quickSettingsPage === "bluetooth"

						Behavior on x {
							NumberAnimation {
								duration: Theme.modalOpenDuration
								easing.type: Easing.OutCubic
							}
						}
					}

					Repeater {
						model: root.radarBluetoothDevices

						ConnectionCard {
							required property var modelData
							readonly property string radarKey: root.connectionKey(modelData,
								"bluetooth")

							x: bluetoothRadar.x + bluetoothRadar.targetX(radarKey)
								- width / 2
							y: (bluetoothPage.height - bluetoothRadar.height) / 2
								+ bluetoothRadar.targetY(radarKey) - height
								- Theme.spacingLg
							z: selected ? 3 : 1
							icon: "󰂯"
							title: modelData.name || modelData.address
							subtitle: modelData.blocked ? "Blocked" : (modelData.connected
								? "Connected" + (modelData.batteryAvailable
									? " · " + Math.round(modelData.battery * 100) + "%"
									: "")
								: (modelData.pairing ? "Pairing…"
									: (modelData.paired ? "Paired" : "Not paired")))
							active: modelData.connected
							selected: root.connectionSelected(modelData, "bluetooth")
							radarHighlight: bluetoothRadar.targetIlluminated(radarKey)
							radarBubble: true
							enabled: UiState.quickSettingsPage === "bluetooth"
								&& root.bluetoothAdapter && root.bluetoothAdapter.enabled
							onClicked: root.selectConnection(modelData, "bluetooth")
						}
					}

					RadioOrb {
						x: bluetoothRadar.x + (bluetoothRadar.width - width) / 2
						anchors.verticalCenter: parent.verticalCenter
						z: 2
						icon: root.bluetoothAdapter && root.bluetoothAdapter.enabled
							? "󰂯" : "󰂲"
						status: !root.bluetoothAdapter ? "No adapter"
							: (!root.bluetoothAdapter.enabled ? "Bluetooth off"
								: (root.bluetoothAdapter.discovering ? "Scanning…"
									: "Click to scan"))
						active: root.bluetoothAdapter && root.bluetoothAdapter.enabled
						busy: root.bluetoothAdapter && root.bluetoothAdapter.discovering
						motionEnabled: root.modalVisible && !root.closing
							&& UiState.quickSettingsPage === "bluetooth"
						pulseTargetDiameter: bluetoothRadar.width * 0.4
						enabled: root.bluetoothAdapter !== null
						onClicked: root.toggleBluetoothScan()
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

					MouseArea {
						anchors.fill: parent
						onClicked: root.clearConnectionSelection()
					}

					RadarField {
						id: wifiRadar
						x: connectionArea.radarCenterX - width / 2
						anchors.verticalCenter: parent.verticalCenter
						targets: root.radarTargets(root.radarWifiNetworks, "wifi")
						active: Networking.wifiEnabled
						motionEnabled: root.modalVisible && !root.closing
							&& UiState.quickSettingsPage === "wifi"

						Behavior on x {
							NumberAnimation {
								duration: Theme.modalOpenDuration
								easing.type: Easing.OutCubic
							}
						}
					}

					Repeater {
						model: root.radarWifiNetworks

						ConnectionCard {
							required property var modelData
							readonly property string radarKey: root.connectionKey(modelData,
								"wifi")

							x: wifiRadar.x + wifiRadar.targetX(radarKey) - width / 2
							y: (wifiPage.height - wifiRadar.height) / 2
								+ wifiRadar.targetY(radarKey) - height
								- Theme.spacingLg
							z: selected ? 3 : 1
							icon: modelData.connected ? "󰖩" : "󰖪"
							title: modelData.name
							subtitle: modelData.connected ? "Connected"
								: (modelData.stateChanging ? "Connecting…"
									: (modelData.known ? "Saved" : "Credentials required"))
							active: modelData.connected
							selected: root.connectionSelected(modelData, "wifi")
							radarHighlight: wifiRadar.targetIlluminated(radarKey)
							radarBubble: true
							enabled: UiState.quickSettingsPage === "wifi"
								&& Networking.wifiEnabled
							onClicked: root.selectConnection(modelData, "wifi")
						}
					}

					RadioOrb {
						x: wifiRadar.x + (wifiRadar.width - width) / 2
						anchors.verticalCenter: parent.verticalCenter
						z: 2
						icon: Networking.wifiEnabled ? "󰖩" : "󰖪"
						status: Networking.wifiEnabled ? "Wi-Fi on" : "Wi-Fi off"
						active: Networking.wifiEnabled
						motionEnabled: root.modalVisible && !root.closing
							&& UiState.quickSettingsPage === "wifi"
						pulseTargetDiameter: wifiRadar.width * 0.4
						onClicked: Networking.wifiEnabled = !Networking.wifiEnabled
					}
				}

				ConnectionInspector {
					id: connectionInspector
					anchors.right: parent.right
					anchors.verticalCenter: parent.verticalCenter
					width: connectionArea.inspectorWidth
					height: Math.min(320, parent.height - Theme.spacingLg * 2)
					z: 5
					open: root.connectionInspectorOpen
					kind: root.selectedConnectionKind === "bluetooth"
						? "Bluetooth target" : "Wi-Fi target"
					icon: root.selectedConnectionKind === "bluetooth" ? "󰂯" : "󰖩"
					title: root.selectedConnection
						? (root.selectedConnection.name
							|| root.selectedConnection.address) : ""
					status: root.selectedConnectionStatus()
					primaryLabel: root.selectedConnectionKind === "bluetooth"
						? "Address" : "Signal"
					primaryValue: !root.selectedConnection ? ""
						: (root.selectedConnectionKind === "bluetooth"
							? root.selectedConnection.address
							: Math.round(root.selectedConnection.signalStrength * 100) + "%")
					secondaryLabel: root.selectedConnectionKind === "bluetooth"
						? (root.selectedConnection && root.selectedConnection.batteryAvailable
							? "Battery" : "Trust") : "Security"
					secondaryValue: !root.selectedConnection ? ""
						: (root.selectedConnectionKind === "bluetooth"
							? (root.selectedConnection.batteryAvailable
								? Math.round(root.selectedConnection.battery * 100) + "%"
								: (root.selectedConnection.trusted ? "Trusted" : "Standard"))
							: root.wifiSecurityLabel(root.selectedConnection.security))
					actionIcon: root.selectedConnection && root.selectedConnection.connected
						? "󰌙" : (root.selectedConnectionKind === "bluetooth" ? "󰂯" : "󰖩")
					actionText: root.selectedActionText()
					actionEnabled: root.selectedActionEnabled()
					actionActive: root.selectedConnection
						? root.selectedConnection.connected : false
					onCloseRequested: root.clearConnectionSelection()
					onActionRequested: root.performSelectedConnectionAction()
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
					anchors.leftMargin: Theme.spacingSm
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
