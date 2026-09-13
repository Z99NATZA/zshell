import QtQuick
import qs.theme

Canvas {
	id: root

	property real panelWidth: 0
	property real panelHeight: 0
	property real panelRadius: 0
	property bool active: false
	property real sourceOpacity: 1
	property color shadowColor: Theme.elevationShadow
	readonly property real padding: Theme.elevationShadowPadding
	property real strength: active
		? Theme.elevationShadowActiveOpacity
		: Theme.elevationShadowOpacity

	width: panelWidth + padding * 2
	height: panelHeight + padding * 2
	opacity: sourceOpacity * Theme.componentOpacity * strength
	renderStrategy: Canvas.Threaded

	function tracePanel(context) {
		context.beginPath()
		context.roundedRect(padding, padding, panelWidth, panelHeight,
			panelRadius, panelRadius)
		context.closePath()
	}

	onPanelWidthChanged: requestPaint()
	onPanelHeightChanged: requestPaint()
	onPanelRadiusChanged: requestPaint()
	onShadowColorChanged: requestPaint()

	onPaint: {
		const context = getContext("2d")
		context.reset()
		context.fillStyle = shadowColor
		context.shadowColor = shadowColor
		context.shadowBlur = Theme.elevationShadowBlur
		context.shadowOffsetY = Theme.elevationShadowYOffset
		tracePanel(context)
		context.fill()

		context.globalCompositeOperation = "destination-out"
		context.shadowColor = "transparent"
		context.shadowBlur = 0
		context.shadowOffsetY = 0
		tracePanel(context)
		context.fill()
		context.globalCompositeOperation = "source-over"
	}

	Behavior on strength {
		NumberAnimation {
			duration: Theme.motionDuration
			easing.type: Easing.OutCubic
		}
	}
}
