pragma Singleton

import Quickshell
import Quickshell.Io

Singleton {
	id: root

	property alias clockX: adapter.clockX
	property alias clockY: adapter.clockY
	property alias clockWidth: adapter.clockWidth
	property alias clockHeight: adapter.clockHeight
	property alias clockExpandedX: adapter.clockExpandedX
	property alias clockExpandedY: adapter.clockExpandedY
	property alias clockExpandedWidth: adapter.clockExpandedWidth
	property alias clockExpandedHeight: adapter.clockExpandedHeight
	property alias musicX: adapter.musicX
	property alias musicY: adapter.musicY
	property alias musicWidth: adapter.musicWidth
	property alias musicHeight: adapter.musicHeight
	property alias musicExpandedX: adapter.musicExpandedX
	property alias musicExpandedY: adapter.musicExpandedY
	property alias musicExpandedWidth: adapter.musicExpandedWidth
	property alias musicExpandedHeight: adapter.musicExpandedHeight
	property alias quickSettingsX: adapter.quickSettingsX
	property alias quickSettingsY: adapter.quickSettingsY
	property alias quickSettingsWidth: adapter.quickSettingsWidth
	property alias quickSettingsHeight: adapter.quickSettingsHeight
	property alias themeName: adapter.themeName
	property alias componentOpacity: adapter.componentOpacity
	property alias showClock: adapter.showClock
	property alias showMusic: adapter.showMusic
	property alias showLanguageLeft: adapter.showLanguageLeft
	property alias showLanguageRight: adapter.showLanguageRight

	FileView {
		path: Quickshell.statePath("layout.json")
		atomicWrites: true
		watchChanges: true
		onFileChanged: reload()
		onAdapterUpdated: writeAdapter()

		JsonAdapter {
			id: adapter
			property int clockX: -1
			property int clockY: 72
			property int clockWidth: 300
			property int clockHeight: 132
			property int clockExpandedX: -1
			property int clockExpandedY: -1
			property int clockExpandedWidth: 560
			property int clockExpandedHeight: 340
			property int musicX: 48
			property int musicY: 720
			property int musicWidth: 390
			property int musicHeight: 144
			property int musicExpandedX: -1
			property int musicExpandedY: -1
			property int musicExpandedWidth: 720
			property int musicExpandedHeight: 420
			property int quickSettingsX: -1
			property int quickSettingsY: -1
			property int quickSettingsWidth: 960
			property int quickSettingsHeight: 680
			property string themeName: "one-half-gray"
			property real componentOpacity: 1
			property bool showClock: true
			property bool showMusic: true
			property bool showLanguageLeft: true
			property bool showLanguageRight: true
		}
	}
}
