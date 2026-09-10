import QtQuick
import qs.theme

Item {
	id: root

	implicitWidth: 176
	implicitHeight: 156

	property string icon
	property string status
	property bool active: false
	property bool busy: false
	property bool motionEnabled: false
	property real pulseTargetDiameter: 176
	signal clicked

	readonly property bool lively: motionEnabled && active
	readonly property real coreDiameter: 106

	Rectangle {
		id: pulseRing
		anchors.centerIn: parent
		width: root.coreDiameter
		height: width
		radius: width / 2
		color: "transparent"
		border.width: 1
		border.color: Theme.accent
		visible: root.lively
		opacity: 0
		scale: 1

		NumberAnimation on scale {
			from: 1
			to: Math.max(1, root.pulseTargetDiameter / root.coreDiameter)
			duration: Theme.radioPulseDuration
			easing.type: Easing.OutCubic
			loops: Animation.Infinite
			running: root.lively
		}

		NumberAnimation on opacity {
			from: 0.36
			to: 0
			duration: Theme.radioPulseDuration
			easing.type: Easing.OutCubic
			loops: Animation.Infinite
			running: root.lively
		}
	}

	Item {
		id: busyOrbit
		anchors.centerIn: parent
		width: 150
		height: width
		visible: root.motionEnabled && root.busy

		Rectangle {
			anchors.horizontalCenter: parent.horizontalCenter
			anchors.top: parent.top
			width: 5
			height: width
			radius: width / 2
			color: Theme.accent
		}

		RotationAnimation on rotation {
			from: 0
			to: 360
			duration: 1400
			easing.type: Easing.Linear
			loops: Animation.Infinite
			running: busyOrbit.visible
		}
	}

	Rectangle {
		id: core
		anchors.centerIn: parent
		width: root.coreDiameter
		height: width
		radius: width / 2
		color: pointer.containsMouse ? Theme.surfaceRaised : Theme.surfaceSoft
		border.width: root.active ? 2 : 1
		border.color: root.active ? Theme.accent : Theme.borderStrong
		scale: pointer.pressed ? 0.94 : (pointer.containsMouse ? 1.06 : 1)

		Behavior on color {
			ColorAnimation { duration: Theme.motionDuration }
		}

		Behavior on border.color {
			ColorAnimation { duration: Theme.motionDuration }
		}

		Behavior on scale {
			NumberAnimation {
				duration: pointer.pressed ? 90 : Theme.motionDuration
				easing.type: Easing.OutCubic
			}
		}

		Text {
			anchors.centerIn: parent
			text: root.icon
			color: root.active ? Theme.accent : Theme.text
			font.family: Theme.fontFamily
			font.pixelSize: 34
			scale: pointer.containsMouse ? 1.08 : 1

			Behavior on color {
				ColorAnimation { duration: Theme.motionDuration }
			}

			Behavior on scale {
				NumberAnimation {
					duration: Theme.motionDuration
					easing.type: Easing.OutCubic
				}
			}
		}

		MouseArea {
			id: pointer
			anchors.fill: parent
			hoverEnabled: true
			cursorShape: root.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
			onClicked: root.clicked()
		}
	}

	Row {
		anchors.horizontalCenter: parent.horizontalCenter
		anchors.top: parent.bottom
		anchors.topMargin: 18
		spacing: Theme.spacingSm

		Rectangle {
			anchors.verticalCenter: parent.verticalCenter
			width: 5
			height: width
			radius: width / 2
			color: root.busy ? Theme.warning
				: (root.active ? Theme.accent : Theme.textMuted)

			Behavior on color {
				ColorAnimation { duration: Theme.motionDuration }
			}
		}

		Text {
			text: root.status
			color: root.busy ? Theme.text : Theme.textMuted
			font.family: Theme.textFontFamily
			font.pixelSize: 10

			Behavior on color {
				ColorAnimation { duration: Theme.motionDuration }
			}
		}
	}
}
