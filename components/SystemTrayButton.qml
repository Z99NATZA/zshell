import QtQuick
import Quickshell
import qs.theme

Rectangle {
	id: root

	required property var trayItem
	required property var parentWindow
	property bool componentReady: false
	property bool retiring: false
	readonly property bool itemAvailable: !retiring && trayItem !== null

	implicitWidth: 30
	implicitHeight: 30
	radius: height / 2
	color: pointer.pressed || pointer.containsMouse
		? Theme.surfaceSoft
		: "transparent"
	readonly property string tooltipTitle: {
		if (!itemAvailable) return ""
		return (trayItem.tooltipTitle || trayItem.title
			|| trayItem.id || "").replace(/\s+/g, " ").trim()
	}
	readonly property string tooltipDescription: itemAvailable
		? (trayItem.tooltipDescription || "").trim()
		: ""
	property bool tooltipRequested: false

	function dismissTransientUi() {
		tooltipTimer.stop()
		tooltipRequested = false
	}

	function retireTrayItem() {
		if (retiring) return
		retiring = true
		dismissTransientUi()
	}

	function displayMenu() {
		dismissTransientUi()
		if (!itemAvailable || !trayItem.hasMenu) return

		const anchor = root.mapToItem(parentWindow.contentItem,
			root.width / 2, 0)
		trayItem.display(parentWindow, Math.round(anchor.x), Math.round(anchor.y))
	}

	Behavior on color {
		ColorAnimation { duration: Theme.motionDuration }
	}

	Timer {
		id: tooltipTimer
		interval: 500
		onTriggered: root.tooltipRequested = root.itemAvailable
			&& root.tooltipTitle.length > 0
	}

	onTrayItemChanged: {
		if (!componentReady) return
		dismissTransientUi()
		retiring = trayItem === null
	}

	Component.onCompleted: componentReady = true
	Component.onDestruction: {
		componentReady = false
		retiring = true
		tooltipRequested = false
	}

	TextMetrics {
		id: tooltipTitleMetrics
		text: root.tooltipTitle
		font.family: Theme.textFontFamily
		font.pixelSize: 12
		font.weight: Font.Medium
	}

	TextMetrics {
		id: tooltipDescriptionMetrics
		text: root.tooltipDescription
		font.family: Theme.textFontFamily
		font.pixelSize: 11
	}

	PopupWindow {
		id: tooltip

		property real reveal: root.itemAvailable
			&& root.tooltipRequested ? 1 : 0

		anchor {
			window: root.parentWindow
			adjustment: PopupAdjustment.SlideX
			gravity: Edges.Bottom | Edges.Right

			onAnchoring: {
				if (!root.itemAvailable || !root.parentWindow) return
				const position = root.mapToItem(root.parentWindow.contentItem,
					root.width / 2 - tooltip.width / 2,
					-tooltip.height - Theme.spacingSm)
				tooltip.anchor.rect.x = Math.round(position.x)
				tooltip.anchor.rect.y = Math.round(position.y)
			}
		}

		implicitWidth: Math.min(300, Math.ceil(Math.max(
			tooltipTitleMetrics.advanceWidth,
			tooltipDescriptionLabel.visible
				? tooltipDescriptionMetrics.advanceWidth
				: 0)) + Theme.spacingMd * 2)
		implicitHeight: tooltipContent.implicitHeight + Theme.spacingSm * 2
		color: "transparent"
		visible: root.itemAvailable && reveal > 0
		grabFocus: false

		onImplicitWidthChanged: if (visible) anchor.updateAnchor()
		onImplicitHeightChanged: if (visible) anchor.updateAnchor()

		Behavior on reveal {
			NumberAnimation {
				duration: Theme.motionDuration
				easing.type: Easing.OutCubic
			}
		}

		Rectangle {
			anchors.fill: parent
			radius: Theme.radius
			color: Theme.surfaceRaised
			border.width: 1
			border.color: Theme.border
			opacity: tooltip.reveal

			Column {
				id: tooltipContent
				anchors.centerIn: parent
				width: parent.width - Theme.spacingMd * 2
				spacing: tooltipDescriptionLabel.visible ? Theme.spacingXs : 0

				Text {
					id: tooltipTitleLabel
					width: parent.width
					text: root.tooltipTitle
					color: Theme.text
					font.family: Theme.textFontFamily
					font.pixelSize: 12
					font.weight: Font.Medium
					elide: Text.ElideRight
					maximumLineCount: 1
					wrapMode: Text.NoWrap
				}

				Text {
					id: tooltipDescriptionLabel
					width: parent.width
					visible: root.tooltipDescription.length > 0
					text: root.tooltipDescription
					color: Theme.textMuted
					font.family: Theme.textFontFamily
					font.pixelSize: 11
					wrapMode: Text.Wrap
					maximumLineCount: 3
					elide: Text.ElideRight
				}
			}
		}
	}

	Image {
		id: trayIcon
		anchors.centerIn: parent
		width: 18
		height: 18
		source: root.itemAvailable ? root.trayItem.icon : ""
		sourceSize.width: width
		sourceSize.height: height
		fillMode: Image.PreserveAspectFit
		smooth: true
	}

	Text {
		anchors.centerIn: parent
		visible: trayIcon.status === Image.Error
		text: "󰀻"
		color: Theme.textMuted
		font.family: Theme.fontFamily
		font.pixelSize: 15
	}

	MouseArea {
		id: pointer
		anchors.fill: parent
		hoverEnabled: true
		enabled: root.itemAvailable
		acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
		cursorShape: Qt.PointingHandCursor
		onContainsMouseChanged: {
			if (containsMouse) {
				root.tooltipRequested = false
				tooltipTimer.restart()
			} else {
				tooltipTimer.stop()
				root.tooltipRequested = false
			}
		}

		onClicked: mouse => {
			root.dismissTransientUi()
			if (!root.itemAvailable) return

			if (mouse.button === Qt.RightButton) {
				root.displayMenu()
			} else if (mouse.button === Qt.MiddleButton) {
				root.trayItem.secondaryActivate()
			} else if (root.trayItem.onlyMenu) {
				root.displayMenu()
			} else {
				root.trayItem.activate()
			}
		}

		onWheel: wheel => {
			if (!root.itemAvailable) {
				wheel.accepted = false
				return
			}

			const horizontal = Math.abs(wheel.angleDelta.x)
				> Math.abs(wheel.angleDelta.y)
			const delta = horizontal
				? wheel.angleDelta.x
				: wheel.angleDelta.y
			if (delta === 0) {
				wheel.accepted = false
				return
			}

			root.trayItem.scroll(delta, horizontal)
			wheel.accepted = true
		}
	}
}
