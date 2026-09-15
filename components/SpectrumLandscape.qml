import QtQuick
import qs.theme

Item {
	id: root

	property var bands: []
	property var trails: []
	readonly property int trailCount: 5

	function updateTrails() {
		if (!bands || bands.length < 2) {
			trails = []
			landscape.requestPaint()
			return
		}

		const next = [bands.slice()]
		for (let depth = 1; depth < trailCount; depth++) {
			const leader = next[depth - 1]
			const previous = trails[depth] || []
			const response = 0.18 - depth * 0.018
			const trail = []

			for (let index = 0; index < leader.length; index++) {
				const current = previous[index] || 0
				trail.push(current + (leader[index] - current) * response)
			}

			next.push(trail)
		}

		trails = next
		landscape.requestPaint()
	}

	function drawTrail(context, values, depth, panelWidth, panelHeight) {
		if (!values || values.length < 2) return

		const baseline = panelHeight * (0.84 - depth * 0.095)
		const amplitude = panelHeight * (0.62 - depth * 0.055)
		const step = panelWidth / (values.length - 1)
		let previousX = 0
		let previousY = baseline - values[0] * amplitude

		context.beginPath()
		context.moveTo(previousX, previousY)
		for (let index = 1; index < values.length; index++) {
			const x = index * step
			const y = baseline - values[index] * amplitude
			const midpointX = (previousX + x) / 2
			const midpointY = (previousY + y) / 2
			context.quadraticCurveTo(previousX, previousY, midpointX, midpointY)
			previousX = x
			previousY = y
		}
		context.quadraticCurveTo(previousX, previousY, panelWidth, previousY)

		context.strokeStyle = Theme.accent
		context.lineWidth = depth === 0 ? 1.7 : 1
		context.globalAlpha = depth === 0 ? 0.82 : 0.30 - depth * 0.045
		context.lineCap = "round"
		context.lineJoin = "round"
		context.stroke()

		if (depth === 0) {
			context.lineTo(panelWidth, panelHeight)
			context.lineTo(0, panelHeight)
			context.closePath()
			context.globalAlpha = 0.055
			context.fillStyle = Theme.accent
			context.fill()
		}
	}

	onBandsChanged: updateTrails()
	onWidthChanged: landscape.requestPaint()
	onHeightChanged: landscape.requestPaint()
	Component.onCompleted: updateTrails()

	Canvas {
		id: landscape
		anchors.fill: parent
		antialiasing: true

		onPaint: {
			const context = getContext("2d")
			context.clearRect(0, 0, width, height)

			context.beginPath()
			context.moveTo(0, height * 0.84)
			context.lineTo(width, height * 0.84)
			context.strokeStyle = Theme.border
			context.lineWidth = 1
			context.globalAlpha = 0.42
			context.stroke()

			for (let depth = root.trails.length - 1; depth >= 0; depth--) {
				root.drawTrail(context, root.trails[depth], depth, width, height)
			}

			context.globalAlpha = 1
		}
	}
}
