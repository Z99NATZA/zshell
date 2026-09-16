import QtQuick
import qs.theme

Item {
	id: root

	property var bands: []
	property real coverDiameter: 0
	readonly property int barCount: bands && bands.length > 0 ? 48 : 0

	function bandForBar(index) {
		if (!bands || bands.length === 0) return 0

		const halfCount = barCount / 2
		const mirroredIndex = index < halfCount
			? index : barCount - index - 1
		const sourcePosition = mirroredIndex * (bands.length - 1)
			/ Math.max(1, halfCount - 1)
		const lowerIndex = Math.floor(sourcePosition)
		const upperIndex = Math.min(bands.length - 1, lowerIndex + 1)
		const mix = sourcePosition - lowerIndex
		return (bands[lowerIndex] || 0) * (1 - mix)
			+ (bands[upperIndex] || 0) * mix
	}

	function directionalGain(angle) {
		const phaseFromTop = angle + Math.PI / 2
		const threePointWave = (Math.cos(phaseFromTop * 3) + 1) / 2
		const shapedPeak = Math.pow(Math.max(0, threePointWave), 1.4)
		return 0.38 + shapedPeak * 0.62
	}

	onBandsChanged: spectrumCanvas.requestPaint()
	onCoverDiameterChanged: spectrumCanvas.requestPaint()
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
			const outerRadius = Math.max(1, Math.min(width, height) / 2 - 4)
			const gap = Theme.spacingSm + 2
			const innerRadius = Math.min(outerRadius - 1,
				root.coverDiameter / 2 + gap)
			const availableLength = Math.max(1, outerRadius - innerRadius)

			context.beginPath()
			context.arc(centerX, centerY, innerRadius, 0, Math.PI * 2)
			context.strokeStyle = Theme.border
			context.lineWidth = 1
			context.globalAlpha = 0.28
			context.stroke()

			context.strokeStyle = Theme.accent
			context.lineWidth = 3.25
			context.lineCap = "round"
			for (let index = 0; index < root.barCount; index++) {
				const bandLevel = Math.max(0,
					Math.min(1, root.bandForBar(index)))
				const angle = -Math.PI / 2
					+ index * Math.PI * 2 / root.barCount
				const level = bandLevel * root.directionalGain(angle)
				const length = 2 + level * Math.max(0, availableLength - 2)
				const endRadius = Math.min(outerRadius, innerRadius + length)

				context.beginPath()
				context.moveTo(centerX + Math.cos(angle) * innerRadius,
					centerY + Math.sin(angle) * innerRadius)
				context.lineTo(centerX + Math.cos(angle) * endRadius,
					centerY + Math.sin(angle) * endRadius)
				context.globalAlpha = 0.12 + level * 0.88
				context.stroke()
			}

			context.globalAlpha = 1
		}
	}
}
