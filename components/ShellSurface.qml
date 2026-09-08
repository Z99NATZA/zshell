import QtQuick
import qs.theme

Rectangle {
	id: root

	property bool raised: false
	property bool interactive: false

	radius: Theme.radius
	color: raised ? Theme.surfaceRaised : Theme.surface
	border.width: 1
	border.color: interactive ? Theme.borderStrong : Theme.border

	Behavior on color {
		ColorAnimation { duration: Theme.motionDuration }
	}

	Behavior on border.color {
		ColorAnimation { duration: Theme.motionDuration }
	}
}
