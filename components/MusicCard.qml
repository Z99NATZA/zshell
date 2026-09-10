import QtQuick
import Quickshell.Services.Mpris
import qs.state
import qs.theme

FloatingPanel {
	id: root

	property var player: null
	property bool userVisible: true
	property real transitionX: 0
	property real transitionY: 0
	property real transitionWidth: 0
	property real transitionHeight: 0
	property real availableWidth: 0
	property real availableHeight: 0
	property bool geometryInitialized: false
	readonly property bool modeTransitionRunning: modeTransition.running

	title: "Now playing"
	icon: "󰎈"
	active: UiState.activeComponent === "music"
	boundsWidth: availableWidth
	boundsHeight: availableHeight
	minimumPanelWidth: expanded ? 540 : 320
	minimumPanelHeight: expanded ? 320 : 124
	transitioning: modeTransitionRunning
	z: UiState.musicStack
	focus: active && expanded
	opacity: player && geometryInitialized ? 1 : 0
	visible: userVisible && (player !== null || opacity > 0)

	function clampedWidth(value, minimum) {
		const available = Math.max(1, availableWidth - edgeMargin * 2)
		return Math.max(Math.min(minimum, available), Math.min(value, available))
	}

	function clampedHeight(value, minimum) {
		const available = Math.max(1,
			availableHeight - edgeMargin - bottomMargin)
		return Math.max(Math.min(minimum, available), Math.min(value, available))
	}

	function clampedX(value, panelWidth) {
		return Math.max(edgeMargin,
			Math.min(availableWidth - panelWidth - edgeMargin, value))
	}

	function clampedY(value, panelHeight) {
		return Math.max(edgeMargin,
			Math.min(availableHeight - panelHeight - bottomMargin, value))
	}

	function storeGeometry() {
		if (expanded) {
			LayoutState.musicExpandedX = Math.round(x)
			LayoutState.musicExpandedY = Math.round(y)
			LayoutState.musicExpandedWidth = Math.round(width)
			LayoutState.musicExpandedHeight = Math.round(height)
		} else {
			LayoutState.musicX = Math.round(x)
			LayoutState.musicY = Math.round(y)
			LayoutState.musicWidth = Math.round(width)
			LayoutState.musicHeight = Math.round(height)
		}
	}

	function setExpanded(nextExpanded, activatePanel) {
		if (expanded === nextExpanded || modeTransition.running) return
		if (activatePanel === undefined) activatePanel = true

		storeGeometry()
		if (activatePanel) UiState.activateComponent("music")

		const nextWidth = clampedWidth(nextExpanded
			? LayoutState.musicExpandedWidth : LayoutState.musicWidth,
			nextExpanded ? 540 : 320)
		const nextHeight = clampedHeight(nextExpanded
			? LayoutState.musicExpandedHeight : LayoutState.musicHeight,
			nextExpanded ? 320 : 124)
		const storedX = nextExpanded ? LayoutState.musicExpandedX : LayoutState.musicX
		const storedY = nextExpanded ? LayoutState.musicExpandedY : LayoutState.musicY
		const centeredX = x + (width - nextWidth) / 2
		const centeredY = y + (height - nextHeight) / 2

		transitionX = clampedX(storedX < 0 ? centeredX : storedX, nextWidth)
		transitionY = clampedY(storedY < 0 ? centeredY : storedY, nextHeight)
		transitionWidth = nextWidth
		transitionHeight = nextHeight
		expanded = nextExpanded
		modeTransition.restart()
		if (activatePanel) focusTimer.restart()
	}

	function restoreMinimalGeometry() {
		if (availableWidth < 400 || availableHeight < 240) return

		width = clampedWidth(LayoutState.musicWidth, 320)
		height = clampedHeight(LayoutState.musicHeight, 124)
		x = clampedX(LayoutState.musicX, width)
		y = clampedY(LayoutState.musicY, height)
		geometryInitialized = true
		storeGeometry()
	}

	function formatDuration(value) {
		if (!isFinite(value) || value < 0) return "0:00"

		const totalSeconds = Math.floor(value)
		const minutes = Math.floor(totalSeconds / 60)
		const seconds = totalSeconds % 60
		return minutes + ":" + String(seconds).padStart(2, "0")
	}

	onActivated: {
		UiState.activateComponent("music")
		if (expanded) focusTimer.restart()
	}
	onModeToggleRequested: root.setExpanded(!root.expanded)
	onGeometryCommitted: (panelX, panelY, panelWidth, panelHeight) => {
		root.storeGeometry()
	}
	onPlayerChanged: {
		if (player) return

		if (expanded) setExpanded(false)
		UiState.releaseComponent("music")
	}

	Keys.priority: Keys.BeforeItem
	Keys.onEscapePressed: event => {
		if (!root.expanded) return

		root.setExpanded(false)
		event.accepted = true
	}

	onAvailableWidthChanged: if (!geometryInitialized) geometryTimer.restart()
	onAvailableHeightChanged: if (!geometryInitialized) geometryTimer.restart()
	Component.onCompleted: geometryTimer.restart()

	Timer {
		id: geometryTimer
		interval: 0
		onTriggered: root.restoreMinimalGeometry()
	}

	Timer {
		id: focusTimer
		interval: 0
		onTriggered: if (root.expanded) root.forceActiveFocus()
	}

	Timer {
		interval: 1000
		repeat: true
		running: root.player && root.player.isPlaying
		onTriggered: if (root.player) root.player.positionChanged()
	}

	ParallelAnimation {
		id: modeTransition

		NumberAnimation {
			target: root
			property: "x"
			to: root.transitionX
			duration: Theme.modalOpenDuration
			easing.type: Easing.OutCubic
		}

		NumberAnimation {
			target: root
			property: "y"
			to: root.transitionY
			duration: Theme.modalOpenDuration
			easing.type: Easing.OutCubic
		}

		NumberAnimation {
			target: root
			property: "width"
			to: root.transitionWidth
			duration: Theme.modalOpenDuration
			easing.type: Easing.OutCubic
		}

		NumberAnimation {
			target: root
			property: "height"
			to: root.transitionHeight
			duration: Theme.modalOpenDuration
			easing.type: Easing.OutCubic
		}

		onFinished: root.storeGeometry()
	}

	Item {
		id: playerLayout
		anchors.fill: parent
		anchors.margins: root.expanded ? Theme.spacingLg : Theme.spacingMd
		readonly property real artSize: root.expanded
			? Math.min(height, Math.min(width * 0.38, 280))
			: Math.min(height, 108)

		Rectangle {
			id: artwork
			anchors.left: parent.left
			anchors.verticalCenter: parent.verticalCenter
			width: playerLayout.artSize
			height: width
			radius: Theme.radius
			color: Theme.surfaceSoft
			clip: true

			Image {
				anchors.fill: parent
				source: root.player ? root.player.trackArtUrl : ""
				fillMode: Image.PreserveAspectCrop
				asynchronous: true
			}

			Text {
				anchors.centerIn: parent
				visible: !root.player || root.player.trackArtUrl.length === 0
				text: "󰎈"
				color: Theme.textMuted
				font.family: Theme.fontFamily
				font.pixelSize: root.expanded ? 42 : 28
			}
		}

		Item {
			id: details
			anchors.left: artwork.right
			anchors.leftMargin: root.expanded ? Theme.spacingLg : Theme.spacingMd
			anchors.right: parent.right
			anchors.top: parent.top
			anchors.bottom: parent.bottom

			Text {
				id: titleLabel
				anchors.left: parent.left
				anchors.right: parent.right
				anchors.top: parent.top
				anchors.topMargin: root.expanded ? Theme.spacingLg : 0
				text: root.player ? (root.player.trackTitle || root.player.identity) : ""
				color: Theme.text
				font.family: Theme.textFontFamily
				font.pixelSize: root.expanded ? 22 : 14
				font.weight: Font.Medium
				elide: Text.ElideRight
			}

			Text {
				id: artistLabel
				anchors.left: parent.left
				anchors.right: parent.right
				anchors.top: titleLabel.bottom
				anchors.topMargin: Theme.spacingXs
				text: root.player ? root.player.trackArtist : ""
				color: Theme.textMuted
				font.family: Theme.textFontFamily
				font.pixelSize: root.expanded ? 13 : 11
				elide: Text.ElideRight
			}

			Rectangle {
				id: progressTrack
				anchors.left: parent.left
				anchors.right: parent.right
				anchors.verticalCenter: parent.verticalCenter
				height: root.expanded ? 4 : 3
				radius: height / 2
				color: Theme.surfaceSoft

				Rectangle {
					width: root.player && root.player.length > 0
						? parent.width * Math.min(1,
							root.player.position / root.player.length)
						: 0
					height: parent.height
					radius: parent.radius
					color: Theme.accent

					Behavior on width {
						NumberAnimation {
							duration: Theme.motionDuration
							easing.type: Easing.OutCubic
						}
					}
				}
			}

			Row {
				visible: root.expanded
				anchors.left: progressTrack.left
				anchors.right: progressTrack.right
				anchors.top: progressTrack.bottom
				anchors.topMargin: Theme.spacingXs

				Text {
					text: root.formatDuration(root.player ? root.player.position : 0)
					color: Theme.textMuted
					font.family: Theme.textFontFamily
					font.pixelSize: 10
				}

				Item { width: parent.width - parent.children[0].width - durationLabel.width }

				Text {
					id: durationLabel
					text: root.formatDuration(root.player ? root.player.length : 0)
					color: Theme.textMuted
					font.family: Theme.textFontFamily
					font.pixelSize: 10
				}
			}

			Row {
				anchors.horizontalCenter: parent.horizontalCenter
				anchors.bottom: parent.bottom
				anchors.bottomMargin: root.expanded ? Theme.spacingLg : 0
				spacing: root.expanded ? Theme.spacingMd : Theme.spacingSm

				ActionButton {
					compact: true
					icon: "󰒮"
					enabled: root.player && root.player.canGoPrevious
					onClicked: {
						root.activated()
						root.player.previous()
					}
				}

				ActionButton {
					compact: true
					icon: root.player && root.player.isPlaying ? "󰏤" : "󰐊"
					active: root.player && root.player.isPlaying
					enabled: root.player && root.player.canTogglePlaying
					onClicked: {
						root.activated()
						root.player.togglePlaying()
					}
				}

				ActionButton {
					compact: true
					icon: "󰒭"
					enabled: root.player && root.player.canGoNext
					onClicked: {
						root.activated()
						root.player.next()
					}
				}
			}
		}
	}

	Behavior on opacity {
		NumberAnimation { duration: Theme.motionDuration; easing.type: Easing.OutCubic }
	}
}
