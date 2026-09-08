pragma Singleton

import Quickshell
import QtQuick
import qs.state

Singleton {
	id: root

	readonly property bool light: LayoutState.themeName === "one-half-light"

	readonly property color background: light ? "#E7E9ED" : "#21252B"
	readonly property color surface: light ? "#F4F5F7" : "#282C34"
	readonly property color surfaceRaised: light ? "#FFFFFF" : "#303640"
	readonly property color surfaceSoft: light ? "#DADDE3" : "#343A45"
	readonly property color border: light ? "#C5CAD3" : "#3E4451"
	readonly property color borderStrong: light ? "#AAB1BD" : "#5D677A"
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
