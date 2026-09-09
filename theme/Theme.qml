pragma Singleton

import Quickshell
import QtQuick
import qs.state

Singleton {
	id: root

	readonly property bool light: LayoutState.themeName === "one-half-light"
	readonly property real componentOpacity: Math.max(0,
		Math.min(1, LayoutState.componentOpacity))

	readonly property color background: light ? "#E7E9ED" : "#21252B"
	readonly property color surface: light
		? Qt.rgba(244 / 255, 245 / 255, 247 / 255, componentOpacity)
		: Qt.rgba(40 / 255, 44 / 255, 52 / 255, componentOpacity)
	readonly property color surfaceRaised: light
		? Qt.rgba(1, 1, 1, componentOpacity)
		: Qt.rgba(48 / 255, 54 / 255, 64 / 255, componentOpacity)
	readonly property color surfaceSoft: light
		? Qt.rgba(218 / 255, 221 / 255, 227 / 255, componentOpacity)
		: Qt.rgba(52 / 255, 58 / 255, 69 / 255, componentOpacity)
	readonly property color border: light
		? Qt.rgba(197 / 255, 202 / 255, 211 / 255, componentOpacity)
		: Qt.rgba(62 / 255, 68 / 255, 81 / 255, componentOpacity)
	readonly property color borderStrong: light
		? Qt.rgba(170 / 255, 177 / 255, 189 / 255, componentOpacity)
		: Qt.rgba(93 / 255, 103 / 255, 122 / 255, componentOpacity)
	readonly property color text: light ? "#282C34" : "#DCDFE4"
	readonly property color textMuted: light ? "#5D677A" : "#ABB2BF"
	readonly property color accent: "#61AFEF"
	readonly property color success: "#98C379"
	readonly property color warning: "#E5C07B"
	readonly property color danger: "#E06C75"
	readonly property color purple: "#C678DD"

	readonly property int radius: 6
	readonly property int motionDuration: 180
	readonly property int spacingXs: 4
	readonly property int spacingSm: 8
	readonly property int spacingMd: 12
	readonly property int spacingLg: 16
	readonly property string workspaceIcon: ""
	readonly property string fontFamily: "JetBrainsMono Nerd Font"
	readonly property string textFontFamily: "JetBrains Mono"
}
