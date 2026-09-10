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
	aboveWindows: ((clockCard.visible && clockCard.expanded)
		|| (musicCard.visible && musicCard.expanded))
		&& UiState.activeComponent !== "quickSettings"
	focusable: aboveWindows
	exclusionMode: ExclusionMode.Ignore

	readonly property var player: Mpris.players.values.length > 0 ? Mpris.players.values[0] : null
	readonly property bool unpinnedModalOpen:
		(clockCard.visible && clockCard.expanded && !clockCard.pinned)
		|| (musicCard.visible && musicCard.expanded && !musicCard.pinned)

	function hidePanel(panel, component) {
		panel.pinned = false
		if (panel.expanded) panel.setExpanded(false, false)
		UiState.releaseComponent(component)
	}

	function collapseUnpinnedPanels(exceptComponent) {
		if (exceptComponent !== "clock" && clockCard.expanded
				&& !clockCard.pinned) {
			clockCard.setExpanded(false, false)
		}

		if (exceptComponent !== "music" && musicCard.expanded
				&& !musicCard.pinned) {
			musicCard.setExpanded(false, false)
		}
	}

	mask: Region {
		Region { item: modalBackdrop }

		Region {
			x: clockCard.x
			y: clockCard.y
			width: clockCard.visible ? clockCard.width : 0
			height: clockCard.visible ? clockCard.height : 0
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

	MouseArea {
		id: modalBackdrop
		x: 0
		y: 0
		width: root.unpinnedModalOpen ? root.width : 0
		height: root.unpinnedModalOpen ? root.height : 0
		z: 0
		enabled: root.unpinnedModalOpen
		onClicked: root.collapseUnpinnedPanels("")
	}

	Connections {
		target: UiState

		function onActiveComponentChanged() {
			root.collapseUnpinnedPanels(UiState.activeComponent)
		}
	}

	Connections {
		target: LayoutState

		function onShowClockChanged() {
			if (!LayoutState.showClock) root.hidePanel(clockCard, "clock")
		}

		function onShowMusicChanged() {
			if (!LayoutState.showMusic) root.hidePanel(musicCard, "music")
		}
	}

	ClockCard {
		id: clockCard
		visible: LayoutState.showClock
		availableWidth: root.width
		availableHeight: root.height
	}

	MusicCard {
		id: musicCard
		player: root.player
		userVisible: LayoutState.showMusic
		availableWidth: root.width
		availableHeight: root.height
	}
}
