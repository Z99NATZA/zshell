import QtQuick
import qs.theme

Item {
	id: root

	property real panelWidth: 0
	property real panelHeight: 0
	property real panelRadius: 0
	property real sourceOpacity: 1
	readonly property real padding: 16
	readonly property var layers: [
		{ spread: 10, offsetY: 4, opacity: 0.03 },
		{ spread: 5, offsetY: 4, opacity: 0.05 },
		{ spread: 1, offsetY: 3, opacity: 0.09 }
	]

	width: panelWidth + padding * 2
	height: panelHeight + padding * 2
	opacity: sourceOpacity * Theme.componentOpacity * Theme.componentOpacity

	Repeater {
		model: root.layers

		delegate: Rectangle {
			required property var modelData

			x: root.padding - modelData.spread
			y: root.padding - modelData.spread + modelData.offsetY
			width: root.panelWidth + modelData.spread * 2
			height: root.panelHeight + modelData.spread * 2
			radius: root.panelRadius + modelData.spread
			color: Theme.panelShadow
			opacity: modelData.opacity
			antialiasing: true
		}
	}
}
