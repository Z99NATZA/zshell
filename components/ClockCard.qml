import QtQuick
import Quickshell
import qs.state
import qs.theme

FloatingPanel {
	id: root

	property real transitionX: 0
	property real transitionY: 0
	property real transitionWidth: 0
	property real transitionHeight: 0
	property real availableWidth: 0
	property real availableHeight: 0
	property bool geometryInitialized: false
	readonly property bool modeTransitionRunning: modeTransition.running

	title: "Clock"
	icon: "󰥔"
	active: UiState.activeComponent === "clock"
	boundsWidth: availableWidth
	boundsHeight: availableHeight
	minimumPanelWidth: expanded ? 420 : 240
	minimumPanelHeight: expanded ? 260 : 108
	transitioning: modeTransitionRunning
	z: UiState.clockStack
	focus: active && expanded

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
			LayoutState.clockExpandedX = Math.round(x)
			LayoutState.clockExpandedY = Math.round(y)
			LayoutState.clockExpandedWidth = Math.round(width)
			LayoutState.clockExpandedHeight = Math.round(height)
		} else {
			LayoutState.clockX = Math.round(x)
			LayoutState.clockY = Math.round(y)
			LayoutState.clockWidth = Math.round(width)
			LayoutState.clockHeight = Math.round(height)
		}
	}

	function setExpanded(nextExpanded) {
		if (expanded === nextExpanded || modeTransition.running) return

		storeGeometry()
		UiState.activateComponent("clock")

		const nextWidth = clampedWidth(nextExpanded
			? LayoutState.clockExpandedWidth : LayoutState.clockWidth,
			nextExpanded ? 420 : 240)
		const nextHeight = clampedHeight(nextExpanded
			? LayoutState.clockExpandedHeight : LayoutState.clockHeight,
			nextExpanded ? 260 : 108)
		const storedX = nextExpanded ? LayoutState.clockExpandedX : LayoutState.clockX
		const storedY = nextExpanded ? LayoutState.clockExpandedY : LayoutState.clockY
		const centeredX = x + (width - nextWidth) / 2
		const centeredY = y + (height - nextHeight) / 2

		transitionX = clampedX(storedX < 0 ? centeredX : storedX, nextWidth)
		transitionY = clampedY(storedY < 0 ? centeredY : storedY, nextHeight)
		transitionWidth = nextWidth
		transitionHeight = nextHeight
		expanded = nextExpanded
		modeTransition.restart()
		focusTimer.restart()
	}

	function restoreMinimalGeometry() {
		if (availableWidth < 320 || availableHeight < 240) return

		width = clampedWidth(LayoutState.clockWidth, 240)
		height = clampedHeight(LayoutState.clockHeight, 108)
		x = clampedX(LayoutState.clockX < 0
			? availableWidth - width - 48 : LayoutState.clockX, width)
		y = clampedY(LayoutState.clockY, height)
		geometryInitialized = true
		storeGeometry()
	}

	onActivated: {
		UiState.activateComponent("clock")
		if (expanded) focusTimer.restart()
	}
	onModeToggleRequested: root.setExpanded(!root.expanded)
	onGeometryCommitted: (panelX, panelY, panelWidth, panelHeight) => {
		root.storeGeometry()
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

	SystemClock {
		id: clock
		precision: SystemClock.Seconds
	}

	Item {
		anchors.fill: parent
		anchors.margins: root.expanded ? Theme.spacingLg : Theme.spacingSm

		Column {
			anchors.centerIn: parent
			spacing: root.expanded ? Theme.spacingSm : Theme.spacingXs

			Text {
				anchors.horizontalCenter: parent.horizontalCenter
				text: Qt.formatDateTime(clock.date, "HH:mm:ss")
				color: Theme.text
				font.family: Theme.textFontFamily
				font.pixelSize: root.expanded
					? Math.max(42, Math.min(68, root.width / 8))
					: Math.max(28, Math.min(38, root.width / 7))
				font.weight: Font.Medium
			}

			Text {
				anchors.horizontalCenter: parent.horizontalCenter
				text: Qt.formatDateTime(clock.date, root.expanded
					? "dddd, d MMMM yyyy" : "ddd, d MMM yyyy")
				color: Theme.textMuted
				font.family: Theme.textFontFamily
				font.pixelSize: root.expanded ? 14 : 12
			}

			Text {
				anchors.horizontalCenter: parent.horizontalCenter
				visible: root.expanded
				text: "LOCAL TIME"
				color: Theme.accent
				font.family: Theme.textFontFamily
				font.pixelSize: 10
				font.letterSpacing: 1.4
			}
		}
	}
}
