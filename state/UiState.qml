pragma Singleton

import Quickshell

Singleton {
	property bool quickSettingsOpen: false
	property string quickSettingsPage: "bluetooth"
	property real quickSettingsTargetX: -1
	property real quickSettingsTargetY: -1
	property string activeComponent: ""
	property string raisedDesktopComponent: ""
	property int stackSerial: 3
	property int clockStack: 1
	property int musicStack: 2
	property int quickSettingsStack: 3

	function raiseComponent(component) {
		if (component.length === 0) return

		stackSerial += 1

		if (component === "clock") clockStack = stackSerial
		else if (component === "music") musicStack = stackSerial
		else if (component === "quickSettings") quickSettingsStack = stackSerial
	}

	function raiseDesktopComponent(component) {
		if (component !== "clock" && component !== "music") return

		raisedDesktopComponent = component
		raiseComponent(component)
	}

	function releaseRaisedDesktopComponent(component) {
		if (raisedDesktopComponent === component) raisedDesktopComponent = ""
	}

	function activateComponent(component) {
		if (component.length === 0) return

		if (component === "clock" || component === "music") {
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
			activeComponent = clockStack > musicStack ? "clock" : "music"
		} else if (component === "clock") {
			activeComponent = quickSettingsOpen ? "quickSettings" : "music"
		} else if (component === "music") {
			activeComponent = quickSettingsOpen ? "quickSettings" : "clock"
		}
	}
}
