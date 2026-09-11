import QtQuick
import qs.theme

ShellSurface {
	id: root

	property string icon: ""
	property string title: ""
	property string subtitle: ""
	property bool active: false
	property bool selected: false
	property bool radarHighlight: false
	property bool radarBubble: false
	signal clicked

	implicitWidth: 176
	implicitHeight: 58
	raised: active || selected || radarHighlight
	interactive: active || selected || radarHighlight || pointer.containsMouse
	opacity: enabled ? 1 : 0.42
	scale: selected ? 1.06 : (radarHighlight ? 1.04 : 1)

	Behavior on opacity {
		NumberAnimation { duration: Theme.motionDuration; easing.type: Easing.OutCubic }
	}

	Behavior on x {
		enabled: !root.radarBubble
		NumberAnimation { duration: Theme.modalOpenDuration; easing.type: Easing.OutCubic }
	}

	Behavior on y {
		enabled: !root.radarBubble
		NumberAnimation { duration: Theme.modalOpenDuration; easing.type: Easing.OutCubic }
	}

	Behavior on scale {
		NumberAnimation { duration: Theme.motionDuration; easing.type: Easing.OutCubic }
	}

	Rectangle {
		anchors.horizontalCenter: parent.horizontalCenter
		anchors.top: parent.bottom
		width: root.selected ? 2 : 1
		height: Theme.spacingLg
		color: Theme.accent
		opacity: root.radarBubble ? (root.selected ? 1 : 0.58) : 0

		Behavior on opacity {
			NumberAnimation { duration: Theme.motionDuration }
		}
	}

	Rectangle {
		anchors.fill: parent
		radius: parent.radius
		color: "transparent"
		border.width: 1
		border.color: Theme.accent
		opacity: root.selected ? 1 : 0
		scale: root.selected ? 1 : 0.96

		Behavior on opacity {
			NumberAnimation { duration: Theme.motionDuration }
		}

		Behavior on scale {
			NumberAnimation { duration: Theme.motionDuration; easing.type: Easing.OutCubic }
		}
	}

	Row {
		anchors.fill: parent
		anchors.leftMargin: Theme.spacingMd
		anchors.rightMargin: Theme.spacingMd
		spacing: Theme.spacingSm

		Text {
			width: 24
			height: parent.height
			text: root.icon
			color: root.active ? Theme.accent : Theme.text
			horizontalAlignment: Text.AlignHCenter
			verticalAlignment: Text.AlignVCenter
			font.family: Theme.fontFamily
			font.pixelSize: 16
		}

		Column {
			width: parent.width - 24 - parent.spacing
			anchors.verticalCenter: parent.verticalCenter
			spacing: 2

			Text {
				width: parent.width
				text: root.title
				color: Theme.text
				font.family: Theme.textFontFamily
				font.pixelSize: 12
				font.weight: Font.Medium
				elide: Text.ElideRight
			}

			Text {
				width: parent.width
				text: root.subtitle
				color: root.active ? Theme.accent : Theme.textMuted
				font.family: Theme.textFontFamily
				font.pixelSize: 10
				elide: Text.ElideRight
			}
		}
	}

	MouseArea {
		id: pointer
		anchors.fill: parent
		hoverEnabled: true
		cursorShape: root.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
		onClicked: if (root.enabled) root.clicked()
	}
}
