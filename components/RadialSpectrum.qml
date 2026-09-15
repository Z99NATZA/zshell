import QtQuick
import qs.theme

Item {
	id: root

	property var bands: []
	property real coverDiameter: 0
	property bool expanded: false
	readonly property int barCount: bands ? bands.length * 2 : 0

	function bandForBar(index) {
		if (!bands || bands.length === 0) return 0
		return index < bands.length
			? bands[index] : bands[barCount - index - 1]
	}

	onBandsChanged: spectrumCanvas.requestPaint()
	onCoverDiameterChanged: spectrumCanvas.requestPaint()
	onExpandedChanged: spectrumCanvas.requestPaint()
	onWidthChanged: spectrumCanvas.requestPaint()
	onHeightChanged: spectrumCanvas.requestPaint()

	Canvas {
		id: spectrumCanvas
		anchors.fill: parent
		antialiasing: true

		onPaint: {
			const context = getContext("2d")
			context.clearRect(0, 0, width, height)
			if (root.barCount < 2 || width <= 0 || height <= 0) return

			const centerX = width / 2
			const centerY = height / 2
			const outerRadius = Math.max(1, Math.min(width, height) / 2
				- (root.expanded ? 2 : 1))
			const gap = root.expanded ? Theme.spacingSm : Theme.spacingXs
			const innerRadius = Math.min(outerRadius - 1,
				root.coverDiameter / 2 + gap)
			const availableLength = Math.max(1, outerRadius - innerRadius)

			context.beginPath()
			context.arc(centerX, centerY, innerRadius, 0, Math.PI * 2)
			context.strokeStyle = Theme.border
			context.lineWidth = 1
			context.globalAlpha = 0.55
			context.stroke()

			context.strokeStyle = Theme.accent
			context.lineWidth = root.expanded ? 2 : 1.25
			context.lineCap = "round"
			for (let index = 0; index < root.barCount; index++) {
				const level = Math.max(0, Math.min(1, root.bandForBar(index)))
				const angle = -Math.PI / 2
					+ index * Math.PI * 2 / root.barCount
				const length = (root.expanded ? 2 : 1) + level * availableLength
				const endRadius = Math.min(outerRadius, innerRadius + length)

				context.beginPath()
				context.moveTo(centerX + Math.cos(angle) * innerRadius,
					centerY + Math.sin(angle) * innerRadius)
				context.lineTo(centerX + Math.cos(angle) * endRadius,
					centerY + Math.sin(angle) * endRadius)
				context.globalAlpha = 0.32 + level * 0.68
				context.stroke()
			}

			context.globalAlpha = 1
		}
	}
}
