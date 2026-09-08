import QtQuick
import Quickshell
import qs.theme

ShellSurface {
	id: root

	property bool dragEnabled: false
	property real maximumX: 0
	property real maximumY: 0
	signal positionCommitted(real cardX, real cardY)

	implicitWidth: 300
	implicitHeight: 132
	raised: true
	interactive: dragHandler.active || dragEnabled

	SystemClock {
		id: clock
		precision: SystemClock.Seconds
	}

	Column {
		anchors.centerIn: parent
		spacing: Theme.spacingXs

		Text {
			anchors.horizontalCenter: parent.horizontalCenter
			text: Qt.formatDateTime(clock.date, "HH:mm:ss")
			color: Theme.text
			font.family: Theme.textFontFamily
			font.pixelSize: 38
			font.weight: Font.Medium
		}

		Text {
			anchors.horizontalCenter: parent.horizontalCenter
			text: Qt.formatDateTime(clock.date, "ddd, d MMM yyyy")
			color: Theme.textMuted
			font.family: Theme.textFontFamily
			font.pixelSize: 12
		}
	}

	Text {
		visible: root.dragEnabled
		anchors.right: parent.right
		anchors.top: parent.top
		anchors.margins: Theme.spacingSm
		text: "󰆾"
		color: Theme.accent
		font.family: Theme.fontFamily
		font.pixelSize: 13
	}

	DragHandler {
		id: dragHandler
		enabled: root.dragEnabled
		target: root
		xAxis.minimum: 12
		xAxis.maximum: root.maximumX
		yAxis.minimum: 12
		yAxis.maximum: root.maximumY
		onActiveChanged: {
			if (!active) root.positionCommitted(root.x, root.y)
		}
	}

	Behavior on opacity {
		NumberAnimation { duration: Theme.motionDuration; easing.type: Easing.OutCubic }
	}
}
