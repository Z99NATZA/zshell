import QtQuick
import Quickshell
import Quickshell.Services.Mpris
import qs.state

PanelWindow {
	id: root

	anchors {
		top: true
		bottom: true
		left: true
		right: true
	}

	color: "transparent"
	aboveWindows: false
	exclusionMode: ExclusionMode.Ignore

	readonly property var player: Mpris.players.values.length > 0 ? Mpris.players.values[0] : null

	mask: Region {
		Region {
			x: clockCard.x
			y: clockCard.y
			width: UiState.editMode ? clockCard.width : 0
			height: UiState.editMode ? clockCard.height : 0
			radius: clockCard.radius
		}

		Region {
			x: musicCard.x
			y: musicCard.y
			width: musicCard.visible ? musicCard.width : 0
			height: musicCard.visible ? musicCard.height : 0
			radius: musicCard.radius
		}
	}

	ClockCard {
		id: clockCard
		x: Math.max(12, Math.min(root.width - width - 12,
			LayoutState.clockX < 0 ? root.width - width - 48 : LayoutState.clockX))
		y: Math.max(12, Math.min(root.height - height - 72, LayoutState.clockY))
		dragEnabled: UiState.editMode
		maximumX: root.width - width - 12
		maximumY: root.height - height - 72
		onPositionCommitted: (cardX, cardY) => {
			LayoutState.clockX = Math.round(cardX)
			LayoutState.clockY = Math.round(cardY)
		}
	}

	MusicCard {
		id: musicCard
		x: Math.max(12, Math.min(root.width - width - 12, LayoutState.musicX))
		y: Math.max(12, Math.min(root.height - height - 72, LayoutState.musicY))
		player: root.player
		dragEnabled: UiState.editMode
		maximumX: root.width - width - 12
		maximumY: root.height - height - 72
		onPositionCommitted: (cardX, cardY) => {
			LayoutState.musicX = Math.round(cardX)
			LayoutState.musicY = Math.round(cardY)
		}
	}
}
