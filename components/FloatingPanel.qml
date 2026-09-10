import QtQuick
import qs.theme

ShellSurface {
	id: root

	default property alias contentData: contentHost.data
	property alias headerActions: headerActionHost.data
	property Component inspectorComponent: null
	property string title: ""
	property string icon: ""
	property bool expanded: false
	property bool active: false
	property bool dragEnabled: true
	property bool resizeEnabled: true
	property bool transitioning: false
	property real boundsWidth: 0
	property real boundsHeight: 0
	property real minimumPanelWidth: 240
	property real minimumPanelHeight: 108
	property real edgeMargin: 12
	property real bottomMargin: 72
	property real inspectorWidth: 260
	readonly property real headerHeight: expanded ? 44 : 0
	readonly property bool inspectorVisible: expanded && inspectorComponent !== null
	readonly property real effectiveMinimumWidth: Math.min(minimumPanelWidth,
		Math.max(1, boundsWidth - edgeMargin * 2))
	readonly property real effectiveMinimumHeight: Math.min(minimumPanelHeight,
		Math.max(1, boundsHeight - edgeMargin - bottomMargin))
	readonly property real maximumPanelX: Math.max(edgeMargin,
		boundsWidth - width - edgeMargin)
	readonly property real maximumPanelY: Math.max(edgeMargin,
		boundsHeight - height - bottomMargin)
	readonly property bool resizing: resizeRepeater.resizeActive

	signal activated
	signal modeToggleRequested
	signal geometryCommitted(real panelX, real panelY, real panelWidth,
		real panelHeight)

	raised: true
	interactive: active || dragArea.containsMouse || resizing
	clip: true

	MouseArea {
		id: activationArea
		anchors.fill: parent
		z: 0
		hoverEnabled: true
		onPressed: root.activated()
		onDoubleClicked: root.modeToggleRequested()
	}

	MouseArea {
		id: dragArea
		x: 0
		y: 0
		width: parent.width
		height: root.expanded ? root.headerHeight : parent.height
		z: root.expanded ? 3 : 0
		enabled: root.dragEnabled && !root.transitioning && !root.resizing
		hoverEnabled: true
		cursorShape: pressed ? Qt.ClosedHandCursor : Qt.OpenHandCursor
		drag.target: root
		drag.minimumX: root.edgeMargin
		drag.maximumX: root.maximumPanelX
		drag.minimumY: root.edgeMargin
		drag.maximumY: root.maximumPanelY
		drag.smoothed: true
		onPressed: root.activated()
		onDoubleClicked: root.modeToggleRequested()
		onReleased: root.geometryCommitted(root.x, root.y, root.width, root.height)
	}

	Item {
		id: bodyRegion
		anchors.left: parent.left
		anchors.right: inspectorRegion.visible ? inspectorRegion.left : parent.right
		anchors.top: parent.top
		anchors.bottom: parent.bottom
		anchors.topMargin: root.headerHeight
		z: 1

		Item {
			id: contentHost
			anchors.fill: parent
		}
	}

	Item {
		id: inspectorRegion
		anchors.right: parent.right
		anchors.top: parent.top
		anchors.bottom: parent.bottom
		anchors.topMargin: root.headerHeight
		width: Math.min(root.inspectorWidth, root.width * 0.38)
		visible: root.inspectorVisible
		z: 1

		Rectangle {
			anchors.left: parent.left
			anchors.top: parent.top
			anchors.bottom: parent.bottom
			width: 1
			color: Theme.border
		}

		Loader {
			anchors.fill: parent
			anchors.margins: Theme.spacingMd
			sourceComponent: root.inspectorComponent
		}
	}

	Item {
		id: header
		anchors.left: parent.left
		anchors.right: parent.right
		anchors.top: parent.top
		height: root.headerHeight
		visible: root.expanded
		z: 4

		Row {
			anchors.left: parent.left
			anchors.leftMargin: Theme.spacingMd
			anchors.verticalCenter: parent.verticalCenter
			spacing: Theme.spacingSm

			Text {
				visible: root.icon.length > 0
				text: root.icon
				color: Theme.accent
				font.family: Theme.fontFamily
				font.pixelSize: 14
			}

			Text {
				text: root.title
				color: Theme.text
				font.family: Theme.textFontFamily
				font.pixelSize: 13
				font.weight: Font.Medium
			}
		}

		Row {
			id: headerActionHost
			anchors.right: compactButton.left
			anchors.rightMargin: Theme.spacingXs
			anchors.verticalCenter: parent.verticalCenter
			spacing: Theme.spacingXs
		}

		ActionButton {
			id: compactButton
			anchors.right: parent.right
			anchors.rightMargin: Theme.spacingSm
			anchors.verticalCenter: parent.verticalCenter
			compact: true
			icon: "󰅖"
			onClicked: {
				root.activated()
				root.modeToggleRequested()
			}
		}

		Rectangle {
			anchors.left: parent.left
			anchors.right: parent.right
			anchors.bottom: parent.bottom
			height: 1
			color: Theme.border
		}
	}

	Repeater {
		id: resizeRepeater

		property bool resizeActive: false
		model: [
			{ left: true, right: false, top: true, bottom: false,
				cursor: Qt.SizeFDiagCursor },
			{ left: false, right: false, top: true, bottom: false,
				cursor: Qt.SizeVerCursor },
			{ left: false, right: true, top: true, bottom: false,
				cursor: Qt.SizeBDiagCursor },
			{ left: true, right: false, top: false, bottom: false,
				cursor: Qt.SizeHorCursor },
			{ left: false, right: true, top: false, bottom: false,
				cursor: Qt.SizeHorCursor },
			{ left: true, right: false, top: false, bottom: true,
				cursor: Qt.SizeBDiagCursor },
			{ left: false, right: false, top: false, bottom: true,
				cursor: Qt.SizeVerCursor },
			{ left: false, right: true, top: false, bottom: true,
				cursor: Qt.SizeFDiagCursor }
		]

		delegate: MouseArea {
			id: resizeHandle

			required property var modelData
			readonly property bool corner: (modelData.left || modelData.right)
				&& (modelData.top || modelData.bottom)
			property real pressPointerX: 0
			property real pressPointerY: 0
			property real pressPanelX: 0
			property real pressPanelY: 0
			property real pressPanelWidth: 0
			property real pressPanelHeight: 0
			readonly property real handleEdge: 10
			readonly property real handleCorner: 16

			x: modelData.left ? 0 : (modelData.right ? root.width - width
				: handleCorner)
			y: modelData.top ? 0 : (modelData.bottom ? root.height - height
				: handleCorner)
			width: modelData.left || modelData.right
				? (corner ? handleCorner : handleEdge)
				: Math.max(0, root.width - handleCorner * 2)
			height: modelData.top || modelData.bottom
				? (corner ? handleCorner : handleEdge)
				: Math.max(0, root.height - handleCorner * 2)
			z: 10
			enabled: root.resizeEnabled && root.active && !root.transitioning
			hoverEnabled: true
			acceptedButtons: Qt.LeftButton
			preventStealing: true
			cursorShape: modelData.cursor

			function pointerPosition(mouse) {
				return mapToItem(root.parent, mouse.x, mouse.y)
			}

			onPressed: mouse => {
				root.activated()
				resizeRepeater.resizeActive = true
				const point = pointerPosition(mouse)
				pressPointerX = point.x
				pressPointerY = point.y
				pressPanelX = root.x
				pressPanelY = root.y
				pressPanelWidth = root.width
				pressPanelHeight = root.height
			}

			onPositionChanged: mouse => {
				if (!pressed) return

				const point = pointerPosition(mouse)
				const deltaX = point.x - pressPointerX
				const deltaY = point.y - pressPointerY
				const startRight = pressPanelX + pressPanelWidth
				const startBottom = pressPanelY + pressPanelHeight
				let nextLeft = pressPanelX
				let nextTop = pressPanelY
				let nextRight = startRight
				let nextBottom = startBottom

				if (modelData.left) {
					nextLeft = Math.max(root.edgeMargin,
						Math.min(startRight - root.effectiveMinimumWidth,
							pressPanelX + deltaX))
				} else if (modelData.right) {
					nextRight = Math.min(root.boundsWidth - root.edgeMargin,
						Math.max(pressPanelX + root.effectiveMinimumWidth,
							startRight + deltaX))
				}

				if (modelData.top) {
					nextTop = Math.max(root.edgeMargin,
						Math.min(startBottom - root.effectiveMinimumHeight,
							pressPanelY + deltaY))
				} else if (modelData.bottom) {
					nextBottom = Math.min(root.boundsHeight - root.bottomMargin,
						Math.max(pressPanelY + root.effectiveMinimumHeight,
							startBottom + deltaY))
				}

				root.x = nextLeft
				root.y = nextTop
				root.width = nextRight - nextLeft
				root.height = nextBottom - nextTop
			}

			onReleased: {
				resizeRepeater.resizeActive = false
				root.geometryCommitted(root.x, root.y, root.width, root.height)
			}
			onCanceled: {
				resizeRepeater.resizeActive = false
				root.geometryCommitted(root.x, root.y, root.width, root.height)
			}
		}
	}
}
