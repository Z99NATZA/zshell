pragma Singleton

import Quickshell

Singleton {
	property bool quickSettingsOpen: false
	property string quickSettingsPage: "bluetooth"
	property real quickSettingsTargetX: -1
	property real quickSettingsTargetY: -1
	property string activeComponent: ""
	property string raisedDesktopComponent: ""
	property int stackSerial: 4
	property int clockStack: 1
	property int musicStack: 2
	property int videoStack: 3
	property int quickSettingsStack: 4

	function raiseComponent(component) {
		if (component.length === 0) return

		stackSerial += 1

		if (component === "clock") clockStack = stackSerial
		else if (component === "music") musicStack = stackSerial
		else if (component === "video") videoStack = stackSerial
		else if (component === "quickSettings") quickSettingsStack = stackSerial
	}

	function raiseDesktopComponent(component) {
		if (component !== "clock" && component !== "music"
				&& component !== "video") return

		raisedDesktopComponent = component
		raiseComponent(component)
	}

	function releaseRaisedDesktopComponent(component) {
		if (raisedDesktopComponent === component) raisedDesktopComponent = ""
	}

	function activateComponent(component) {
		if (component.length === 0) return

		if (component === "clock" || component === "music"
				|| component === "video") {
			raisedDesktopComponent = component
		} else if (component === "quickSettings"
				&& activeComponent !== "quickSettings") {
			raisedDesktopComponent = ""
		}

		activeComponent = component
		raiseComponent(component)
	}

	function releaseComponent(component) {
		if (activeComponent !== component) return

		if (component === "quickSettings") {
			activeComponent = highestDesktopComponent("")
		} else if (component === "clock" || component === "music"
				|| component === "video") {
			activeComponent = quickSettingsOpen ? "quickSettings"
				: highestDesktopComponent(component)
		}
	}

	function highestDesktopComponent(excluded) {
		let selected = ""
		let selectedStack = -1

		if (excluded !== "clock" && LayoutState.showClock
				&& clockStack > selectedStack) {
			selected = "clock"
			selectedStack = clockStack
		}
		if (excluded !== "music" && LayoutState.showMusic
				&& musicStack > selectedStack) {
			selected = "music"
			selectedStack = musicStack
		}
		if (excluded !== "video" && LayoutState.showVideo
				&& videoStack > selectedStack) {
			selected = "video"
		}

		return selected
	}
}
