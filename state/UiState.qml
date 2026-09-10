pragma Singleton

import Quickshell

Singleton {
	property bool editMode: false
	property bool quickSettingsOpen: false
	property string quickSettingsPage: "bluetooth"
	property real quickSettingsTargetX: -1
	property real quickSettingsTargetY: -1
	property string activeComponent: ""
	property int stackSerial: 3
	property int clockStack: 1
	property int musicStack: 2
	property int quickSettingsStack: 3

	function activateComponent(component) {
		if (component.length === 0) return

		activeComponent = component
		stackSerial += 1

		if (component === "clock") clockStack = stackSerial
		else if (component === "music") musicStack = stackSerial
		else if (component === "quickSettings") quickSettingsStack = stackSerial
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
