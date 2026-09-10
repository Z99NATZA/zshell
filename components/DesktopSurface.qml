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
	aboveWindows: (clockCard.expanded || musicCard.expanded)
		&& UiState.activeComponent !== "quickSettings"
	focusable: aboveWindows
	exclusionMode: ExclusionMode.Ignore

	readonly property var player: Mpris.players.values.length > 0 ? Mpris.players.values[0] : null

	mask: Region {
		Region {
			x: clockCard.x
			y: clockCard.y
			width: clockCard.width
			height: clockCard.height
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
		availableWidth: root.width
		availableHeight: root.height
	}

	MusicCard {
		id: musicCard
		player: root.player
		availableWidth: root.width
		availableHeight: root.height
	}
}
