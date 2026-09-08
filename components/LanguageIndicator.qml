import QtQuick
import qs.theme

Item {
	id: root

	property string code: "--"
	property bool shown: true

	width: shown ? 30 : 0
	height: 30
	opacity: shown ? 1 : 0
	visible: shown || opacity > 0
	clip: true

	Text {
		width: 30
		height: parent.height
		text: root.code
		color: Theme.textMuted
		horizontalAlignment: Text.AlignHCenter
		verticalAlignment: Text.AlignVCenter
		font.family: Theme.textFontFamily
		font.pixelSize: 11
		font.weight: Font.Medium
	}

	Behavior on width {
		NumberAnimation { duration: Theme.motionDuration; easing.type: Easing.OutCubic }
	}

	Behavior on opacity {
		NumberAnimation { duration: Theme.motionDuration; easing.type: Easing.OutCubic }
	}
}
