import QtQuick

MouseArea {
	id: root

	property Item targetItem
	property Item coordinateItem
	property bool resizeLeft: false
	property bool resizeRight: false
	property bool resizeTop: false
	property bool resizeBottom: false
	property bool resizeEnabled: true
	property real minimumWidth: 0
	property real minimumHeight: 0
	property real minimumX: 0
	property real minimumY: 0
	property real maximumRight: 0
	property real maximumBottom: 0

	property real pressPointerX: 0
	property real pressPointerY: 0
	property real pressTargetX: 0
	property real pressTargetY: 0
	property real pressTargetWidth: 0
	property real pressTargetHeight: 0

	signal resizeFinished

	enabled: resizeEnabled && targetItem !== null && coordinateItem !== null
	hoverEnabled: true
	acceptedButtons: Qt.LeftButton
	preventStealing: true

	function pointerPosition(mouse) {
		return mapToItem(coordinateItem, mouse.x, mouse.y)
	}

	onPressed: mouse => {
		const point = pointerPosition(mouse)
		pressPointerX = point.x
		pressPointerY = point.y
		pressTargetX = targetItem.x
		pressTargetY = targetItem.y
		pressTargetWidth = targetItem.width
		pressTargetHeight = targetItem.height
	}

	onPositionChanged: mouse => {
		if (!pressed) return

		const point = pointerPosition(mouse)
		const deltaX = point.x - pressPointerX
		const deltaY = point.y - pressPointerY
		const startRight = pressTargetX + pressTargetWidth
		const startBottom = pressTargetY + pressTargetHeight
		let nextLeft = pressTargetX
		let nextTop = pressTargetY
		let nextRight = startRight
		let nextBottom = startBottom

		if (resizeLeft) {
			nextLeft = Math.max(minimumX,
				Math.min(startRight - minimumWidth, pressTargetX + deltaX))
		} else if (resizeRight) {
			nextRight = Math.min(maximumRight,
				Math.max(pressTargetX + minimumWidth, startRight + deltaX))
		}

		if (resizeTop) {
			nextTop = Math.max(minimumY,
				Math.min(startBottom - minimumHeight, pressTargetY + deltaY))
		} else if (resizeBottom) {
			nextBottom = Math.min(maximumBottom,
				Math.max(pressTargetY + minimumHeight, startBottom + deltaY))
		}

		targetItem.x = nextLeft
		targetItem.y = nextTop
		targetItem.width = nextRight - nextLeft
		targetItem.height = nextBottom - nextTop
	}

	onReleased: resizeFinished()
	onCanceled: resizeFinished()
}
