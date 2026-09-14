import QtQuick
import Quickshell
import qs.theme

Item {
	id: root

	required property var parentWindow
	property string code: "--"
	property var layouts: []
	property int activeLayoutIndex: -1
	property bool shown: true
	property bool menuOpen: false
	signal layoutSelected(int index)

	width: shown ? 30 : 0
	height: 34
	opacity: shown ? 1 : 0
	visible: shown || opacity > 0
	clip: true

	onShownChanged: if (!shown) menuOpen = false

	ActionButton {
		anchors.fill: parent
		compact: true
		text: root.code
		active: root.menuOpen
		enabled: root.layouts.length > 0
		onClicked: root.menuOpen = !root.menuOpen
	}

	PopupWindow {
		id: languageMenu

		anchor {
			window: root.parentWindow
			adjustment: PopupAdjustment.SlideX
			gravity: Edges.Bottom | Edges.Right

			onAnchoring: {
				if (!root.parentWindow) return
				const position = root.mapToItem(root.parentWindow.contentItem,
					root.width / 2 - languageMenu.width / 2,
					-languageMenu.height - Theme.spacingSm)
				languageMenu.anchor.rect.x = Math.round(position.x)
				languageMenu.anchor.rect.y = Math.round(position.y)
			}
		}

		implicitWidth: 132
		implicitHeight: languageOptions.height + Theme.spacingXs * 2
		color: "transparent"
		visible: root.shown && root.menuOpen && root.layouts.length > 0
		grabFocus: true

		onVisibleChanged: if (!visible) root.menuOpen = false
		onImplicitWidthChanged: if (visible) anchor.updateAnchor()
		onImplicitHeightChanged: if (visible) anchor.updateAnchor()

		Rectangle {
			anchors.fill: parent
			radius: Theme.radius
			color: Theme.surfaceRaised
			border.width: 1
			border.color: Theme.border

			Column {
				id: languageOptions
				anchors.centerIn: parent
				width: parent.width - Theme.spacingXs * 2

				Repeater {
					model: root.layouts

					Rectangle {
						id: languageOption

						required property var modelData
						required property int index
						readonly property bool selected:
							index === root.activeLayoutIndex

						width: languageOptions.width
						height: 34
						radius: Theme.radius
						color: selected || optionPointer.containsMouse
							? Theme.surfaceSoft : "transparent"

						Row {
							anchors.fill: parent
							anchors.leftMargin: Theme.spacingSm
							anchors.rightMargin: Theme.spacingSm
							spacing: Theme.spacingSm

							Text {
								width: 24
								height: parent.height
								text: languageOption.modelData.code
								color: languageOption.selected
									? Theme.accent : Theme.textMuted
								verticalAlignment: Text.AlignVCenter
								font.family: Theme.textFontFamily
								font.pixelSize: 11
								font.weight: Font.Medium
							}

							Text {
								width: parent.width - 24 - parent.spacing
								height: parent.height
								text: languageOption.modelData.label
								color: Theme.text
								verticalAlignment: Text.AlignVCenter
								font.family: Theme.textFontFamily
								font.pixelSize: 12
								elide: Text.ElideRight
							}
						}

						MouseArea {
							id: optionPointer
							anchors.fill: parent
							hoverEnabled: true
							cursorShape: Qt.PointingHandCursor
							onClicked: {
								root.menuOpen = false
								root.layoutSelected(languageOption.index)
							}
						}
					}
				}
			}
		}
	}

	Behavior on width {
		NumberAnimation { duration: Theme.motionDuration; easing.type: Easing.OutCubic }
	}

	Behavior on opacity {
		NumberAnimation { duration: Theme.motionDuration; easing.type: Easing.OutCubic }
	}
}
