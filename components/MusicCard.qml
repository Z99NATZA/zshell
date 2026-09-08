import QtQuick
import Quickshell.Services.Mpris
import qs.theme

ShellSurface {
	id: root

	property var player: null
	property bool dragEnabled: false
	property real maximumX: 0
	property real maximumY: 0
	signal positionCommitted(real cardX, real cardY)

	implicitWidth: 390
	implicitHeight: 144
	raised: true
	interactive: dragHandler.active || dragEnabled
	opacity: player ? 1 : 0
	visible: player !== null || opacity > 0

	Timer {
		interval: 1000
		repeat: true
		running: root.player && root.player.isPlaying
		onTriggered: if (root.player) root.player.positionChanged()
	}

	Row {
		anchors.fill: parent
		anchors.margins: Theme.spacingMd
		spacing: Theme.spacingMd

		Rectangle {
			width: 108
			height: 108
			radius: Theme.radius
			color: Theme.surfaceSoft
			clip: true

			Image {
				anchors.fill: parent
				source: root.player ? root.player.trackArtUrl : ""
				fillMode: Image.PreserveAspectCrop
				asynchronous: true
			}

			Text {
				anchors.centerIn: parent
				visible: !root.player || root.player.trackArtUrl.length === 0
				text: "󰎈"
				color: Theme.textMuted
				font.family: Theme.fontFamily
				font.pixelSize: 28
			}
		}

		Item {
			width: parent.width - 120
			height: parent.height

			Text {
				id: title
				anchors.left: parent.left
				anchors.right: parent.right
				text: root.player ? (root.player.trackTitle || root.player.identity) : ""
				color: Theme.text
				font.family: Theme.textFontFamily
				font.pixelSize: 14
				font.weight: Font.Medium
				elide: Text.ElideRight
			}

			Text {
				id: artist
				anchors.left: parent.left
				anchors.right: parent.right
				anchors.top: title.bottom
				anchors.topMargin: Theme.spacingXs
				text: root.player ? root.player.trackArtist : ""
				color: Theme.textMuted
				font.family: Theme.textFontFamily
				font.pixelSize: 11
				elide: Text.ElideRight
			}

			Rectangle {
				id: progressTrack
				anchors.left: parent.left
				anchors.right: parent.right
				anchors.top: artist.bottom
				anchors.topMargin: Theme.spacingMd
				height: 3
				radius: 2
				color: Theme.surfaceSoft

				Rectangle {
					width: root.player && root.player.length > 0
						? parent.width * Math.min(1, root.player.position / root.player.length)
						: 0
					height: parent.height
					radius: parent.radius
					color: Theme.accent

					Behavior on width {
						NumberAnimation { duration: Theme.motionDuration; easing.type: Easing.OutCubic }
					}
				}
			}

			Row {
				anchors.horizontalCenter: parent.horizontalCenter
				anchors.bottom: parent.bottom
				spacing: Theme.spacingSm

				ActionButton {
					compact: true
					icon: "󰒮"
					enabled: root.player && root.player.canGoPrevious
					onClicked: root.player.previous()
				}

				ActionButton {
					compact: true
					icon: root.player && root.player.isPlaying ? "󰏤" : "󰐊"
					active: root.player && root.player.isPlaying
					enabled: root.player && root.player.canTogglePlaying
					onClicked: root.player.togglePlaying()
				}

				ActionButton {
					compact: true
					icon: "󰒭"
					enabled: root.player && root.player.canGoNext
					onClicked: root.player.next()
				}
			}
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
