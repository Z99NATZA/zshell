import QtQuick
import qs.theme

ShellSurface {
	id: root

	property string icon: ""
	property string title: ""
	property string description: ""
	property bool checked: true
	signal toggled

	implicitHeight: 78
	raised: false
	interactive: pointer.containsMouse

	Text {
		id: iconLabel
		anchors.left: parent.left
		anchors.leftMargin: Theme.spacingLg
		anchors.verticalCenter: parent.verticalCenter
		width: 34
		text: root.icon
		color: root.checked ? Theme.accent : Theme.textMuted
		horizontalAlignment: Text.AlignHCenter
		font.family: Theme.fontFamily
		font.pixelSize: 19
	}

	Column {
		anchors.left: iconLabel.right
		anchors.leftMargin: Theme.spacingMd
		anchors.right: visibilitySwitch.left
		anchors.rightMargin: Theme.spacingLg
		anchors.verticalCenter: parent.verticalCenter
		spacing: Theme.spacingXs

		Text {
			width: parent.width
			text: root.title
			color: Theme.text
			font.family: Theme.textFontFamily
			font.pixelSize: 14
			font.weight: Font.Medium
			elide: Text.ElideRight
		}

		Text {
			width: parent.width
			text: root.description
			color: Theme.textMuted
			font.family: Theme.textFontFamily
			font.pixelSize: 11
			elide: Text.ElideRight
		}
	}

	Rectangle {
		id: visibilitySwitch
		anchors.right: parent.right
		anchors.rightMargin: Theme.spacingLg
		anchors.verticalCenter: parent.verticalCenter
		width: 42
		height: 22
		radius: height / 2
		color: root.checked ? Theme.accent : Theme.surfaceSoft
		border.width: 1
		border.color: root.checked ? Theme.accent : Theme.borderStrong

		Rectangle {
			x: root.checked ? parent.width - width - 4 : 4
			anchors.verticalCenter: parent.verticalCenter
			width: 14
			height: 14
			radius: width / 2
			color: root.checked ? Theme.background : Theme.textMuted

			Behavior on x {
				NumberAnimation {
					duration: Theme.motionDuration
					easing.type: Easing.OutCubic
				}
			}
		}

		Behavior on color {
			ColorAnimation { duration: Theme.motionDuration }
		}
	}

	MouseArea {
		id: pointer
		anchors.fill: parent
		hoverEnabled: true
		cursorShape: Qt.PointingHandCursor
		onClicked: root.toggled()
	}
}
