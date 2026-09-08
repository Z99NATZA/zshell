import QtQuick
import qs.theme

Rectangle {
	id: root

	property string icon: ""
	property string text: ""
	property bool active: false
	property bool compact: false
	signal clicked

	implicitWidth: compact ? 34 : Math.max(72, content.implicitWidth + Theme.spacingMd * 2)
	implicitHeight: 34
	radius: Theme.radius
	color: active ? Theme.surfaceSoft : (pointer.containsMouse ? Theme.surfaceSoft : "transparent")
	opacity: enabled ? 1 : 0.42

	Behavior on color {
		ColorAnimation { duration: Theme.motionDuration }
	}

	Behavior on opacity {
		NumberAnimation { duration: Theme.motionDuration; easing.type: Easing.OutCubic }
	}

	Row {
		id: content
		anchors.centerIn: parent
		height: Math.max(iconLabel.implicitHeight, textLabel.implicitHeight)
		spacing: root.text.length > 0 ? Theme.spacingSm : 0

		Text {
			id: iconLabel
			visible: root.icon.length > 0
			height: content.height
			text: root.icon
			color: root.active ? Theme.accent : Theme.text
			verticalAlignment: Text.AlignVCenter
			font.family: Theme.fontFamily
			font.pixelSize: 15
		}

		Text {
			id: textLabel
			visible: root.text.length > 0
			height: content.height
			text: root.text
			color: Theme.text
			verticalAlignment: Text.AlignVCenter
			font.family: Theme.textFontFamily
			font.pixelSize: 12
			elide: Text.ElideRight
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
