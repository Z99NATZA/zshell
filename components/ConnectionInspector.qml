import QtQuick
import qs.theme

ShellSurface {
	id: root

	property bool open: false
	property string kind: ""
	property string icon: ""
	property string title: ""
	property string status: ""
	property string primaryLabel: ""
	property string primaryValue: ""
	property string secondaryLabel: ""
	property string secondaryValue: ""
	property string actionIcon: ""
	property string actionText: ""
	property bool actionEnabled: true
	property bool actionActive: false
	signal closeRequested
	signal actionRequested

	raised: true
	radius: Theme.radius * 2
	visible: open || opacity > 0
	enabled: open
	opacity: open ? 1 : 0

	Behavior on opacity {
		NumberAnimation { duration: Theme.motionDuration; easing.type: Easing.OutCubic }
	}

	transform: Translate {
		x: root.open ? 0 : Theme.spacingLg * 2

		Behavior on x {
			NumberAnimation { duration: Theme.modalOpenDuration; easing.type: Easing.OutCubic }
		}
	}

	MouseArea {
		anchors.fill: parent
		onClicked: mouse => mouse.accepted = true
	}

	Rectangle {
		anchors.left: parent.left
		anchors.top: parent.top
		anchors.bottom: parent.bottom
		anchors.topMargin: Theme.spacingMd
		anchors.bottomMargin: Theme.spacingMd
		width: 2
		radius: width / 2
		color: Theme.accent
	}

	Column {
		id: content
		anchors.fill: parent
		anchors.margins: Theme.spacingLg
		spacing: Theme.spacingMd

		Item {
			width: parent.width
			height: 48

			ShellSurface {
				id: iconSurface
				anchors.left: parent.left
				anchors.verticalCenter: parent.verticalCenter
				width: 42
				height: 42
				raised: true
				radius: width / 2

				Text {
					anchors.centerIn: parent
					text: root.icon
					color: Theme.accent
					font.family: Theme.fontFamily
					font.pixelSize: 19
				}
			}

			ActionButton {
				id: closeButton
				anchors.right: parent.right
				anchors.top: parent.top
				compact: true
				icon: "󰅖"
				onClicked: root.closeRequested()
			}

			Text {
				anchors.left: iconSurface.right
				anchors.leftMargin: Theme.spacingMd
				anchors.right: closeButton.left
				anchors.rightMargin: Theme.spacingSm
				anchors.top: parent.top
				text: root.kind
				color: Theme.textMuted
				font.family: Theme.textFontFamily
				font.pixelSize: 9
				font.letterSpacing: 1
				font.capitalization: Font.AllUppercase
				elide: Text.ElideRight
			}

			Text {
				anchors.left: iconSurface.right
				anchors.leftMargin: Theme.spacingMd
				anchors.right: closeButton.left
				anchors.rightMargin: Theme.spacingSm
				anchors.bottom: parent.bottom
				anchors.bottomMargin: 3
				text: root.title
				color: Theme.text
				font.family: Theme.textFontFamily
				font.pixelSize: 13
				font.weight: Font.Medium
				elide: Text.ElideRight
			}
		}

		Text {
			width: parent.width
			text: root.status
			color: root.actionActive ? Theme.accent : Theme.textMuted
			font.family: Theme.textFontFamily
			font.pixelSize: 11
			wrapMode: Text.WordWrap
		}

		Rectangle {
			width: parent.width
			height: 1
			color: Theme.border
		}

		Item {
			width: parent.width
			height: primaryLabel.visible ? 24 : 0

			Text {
				id: primaryLabel
				anchors.left: parent.left
				anchors.verticalCenter: parent.verticalCenter
				visible: root.primaryLabel.length > 0
				text: root.primaryLabel
				color: Theme.textMuted
				font.family: Theme.textFontFamily
				font.pixelSize: 10
			}

			Text {
				anchors.left: primaryLabel.right
				anchors.leftMargin: Theme.spacingSm
				anchors.right: parent.right
				anchors.verticalCenter: parent.verticalCenter
				text: root.primaryValue
				color: Theme.text
				horizontalAlignment: Text.AlignRight
				font.family: Theme.textFontFamily
				font.pixelSize: 10
				elide: Text.ElideMiddle
			}
		}

		Item {
			width: parent.width
			height: secondaryLabel.visible ? 24 : 0

			Text {
				id: secondaryLabel
				anchors.left: parent.left
				anchors.verticalCenter: parent.verticalCenter
				visible: root.secondaryLabel.length > 0
				text: root.secondaryLabel
				color: Theme.textMuted
				font.family: Theme.textFontFamily
				font.pixelSize: 10
			}

			Text {
				anchors.left: secondaryLabel.right
				anchors.leftMargin: Theme.spacingSm
				anchors.right: parent.right
				anchors.verticalCenter: parent.verticalCenter
				text: root.secondaryValue
				color: Theme.text
				horizontalAlignment: Text.AlignRight
				font.family: Theme.textFontFamily
				font.pixelSize: 10
				elide: Text.ElideMiddle
			}
		}

		Item {
			width: parent.width
			height: 1
		}

		ActionButton {
			width: parent.width
			height: 42
			icon: root.actionIcon
			text: root.actionText
			active: root.actionActive
			enabled: root.actionEnabled
			onClicked: root.actionRequested()
		}
	}
}
