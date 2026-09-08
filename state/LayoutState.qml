pragma Singleton

import Quickshell
import Quickshell.Io

Singleton {
	id: root

	property alias clockX: adapter.clockX
	property alias clockY: adapter.clockY
	property alias musicX: adapter.musicX
	property alias musicY: adapter.musicY
	property alias themeName: adapter.themeName
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
			property int musicX: 48
			property int musicY: 720
			property string themeName: "one-half-gray"
			property bool showLanguageLeft: true
			property bool showLanguageRight: true
		}
	}
}
