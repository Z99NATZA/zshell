import QtQuick
import Quickshell
import Quickshell.Services.Mpris
import Quickshell.Wayland
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
	readonly property bool expandedPanelVisible:
		(clockCard.visible && clockCard.expanded)
		|| (musicCard.visible && musicCard.expanded)
	readonly property bool desktopPanelActive:
		UiState.activeComponent === "clock" || UiState.activeComponent === "music"
	readonly property bool raisedDesktopPanelVisible:
		(UiState.raisedDesktopComponent === "clock" && clockCard.visible)
		|| (UiState.raisedDesktopComponent === "music" && musicCard.visible)
	WlrLayershell.layer: desktopPanelActive
		? WlrLayer.Overlay
		: ((expandedPanelVisible || raisedDesktopPanelVisible)
			? WlrLayer.Top : WlrLayer.Bottom)
	focusable: expandedPanelVisible && desktopPanelActive
	exclusionMode: ExclusionMode.Ignore

	readonly property var player: Mpris.players.values.length > 0 ? Mpris.players.values[0] : null
	readonly property bool panelDragActive: clockCard.dragging || musicCard.dragging

	function hidePanel(panel, component) {
		if (panel.expanded) panel.setExpanded(false, false)
		UiState.releaseRaisedDesktopComponent(component)
		UiState.releaseComponent(component)
	}

	mask: Region {
		Region {
			width: root.panelDragActive ? root.width : 0
			height: root.panelDragActive ? root.height : 0
		}

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

	Connections {
		target: LayoutState

		function onShowClockChanged() {
			if (!LayoutState.showClock) root.hidePanel(clockCard, "clock")
		}

		function onShowMusicChanged() {
			if (!LayoutState.showMusic) root.hidePanel(musicCard, "music")
		}
	}

	PanelShadow {
		x: clockCard.x - padding
		y: clockCard.y - padding
		z: clockCard.z - 0.5
		panelWidth: clockCard.width
		panelHeight: clockCard.height
		panelRadius: clockCard.radius
		sourceOpacity: clockCard.opacity
		visible: clockCard.visible
	}

	ClockCard {
		id: clockCard
		visible: LayoutState.showClock
		availableWidth: root.width
		availableHeight: root.height
		onHideRequested: LayoutState.showClock = false
	}

	PanelShadow {
		x: musicCard.x - padding
		y: musicCard.y - padding
		z: musicCard.z - 0.5
		panelWidth: musicCard.width
		panelHeight: musicCard.height
		panelRadius: musicCard.radius
		sourceOpacity: musicCard.opacity
		visible: musicCard.visible
	}

	MusicCard {
		id: musicCard
		player: root.player
		userVisible: LayoutState.showMusic
		availableWidth: root.width
		availableHeight: root.height
		onHideRequested: LayoutState.showMusic = false
	}
}
