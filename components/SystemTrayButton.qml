import QtQuick
import qs.theme

Rectangle {
	id: root

	required property var trayItem
	required property var parentWindow

	implicitWidth: 30
	implicitHeight: 30
	radius: Theme.radius
	color: pointer.pressed || pointer.containsMouse
		? Theme.surfaceSoft
		: "transparent"

	function displayMenu() {
		if (!trayItem || !trayItem.hasMenu) return

		const anchor = root.mapToItem(parentWindow.contentItem,
			root.width / 2, 0)
		trayItem.display(parentWindow, Math.round(anchor.x), Math.round(anchor.y))
	}

	Behavior on color {
		ColorAnimation { duration: Theme.motionDuration }
	}

	Image {
		id: trayIcon
		anchors.centerIn: parent
		width: 18
		height: 18
		source: root.trayItem ? root.trayItem.icon : ""
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
		acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
		cursorShape: Qt.PointingHandCursor

		onClicked: mouse => {
			if (!root.trayItem) return

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
			if (!root.trayItem) {
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
