import QtQuick
import qs.theme

Item {
	id: root

	property var bands: []
	property real coverDiameter: 0
	property var peakFromAngles: [-Math.PI / 2, Math.PI / 6, Math.PI * 5 / 6]
	property var peakToAngles: [-Math.PI / 2, Math.PI / 6, Math.PI * 5 / 6]
	property var peakFromWeights: [1, 1, 1]
	property var peakToWeights: [1, 1, 1]
	property real peakMorph: 1
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

	function shortestAngleDelta(fromAngle, toAngle) {
		return Math.atan2(Math.sin(toAngle - fromAngle),
			Math.cos(toAngle - fromAngle))
	}

	function currentPeakAngle(index) {
		const fromAngle = peakFromAngles[index] || 0
		const toAngle = peakToAngles[index] || 0
		return fromAngle + shortestAngleDelta(fromAngle, toAngle) * peakMorph
	}

	function currentPeakWeight(index) {
		const fromWeight = peakFromWeights[index] || 0
		const toWeight = peakToWeights[index] || 0
		return fromWeight + (toWeight - fromWeight) * peakMorph
	}

	function angularDistance(left, right) {
		return Math.abs(shortestAngleDelta(left, right))
	}

	function randomPeakPattern() {
		const peakCount = Math.random() < 0.5 ? 2 : 3
		const minimumSeparation = peakCount === 2
			? Math.PI * 0.58 : Math.PI * 0.42
		const angles = []

		for (let peak = 0; peak < peakCount; peak++) {
			let accepted = false
			for (let attempt = 0; attempt < 48; attempt++) {
				const candidate = -Math.PI + Math.random() * Math.PI * 2
				if (angles.every(angle => angularDistance(angle, candidate)
						>= minimumSeparation)) {
					angles.push(candidate)
					accepted = true
					break
				}
			}

			if (!accepted) {
				const phase = -Math.PI + Math.random() * Math.PI * 2
				angles.length = 0
				for (let index = 0; index < peakCount; index++) {
					angles.push(phase + index * Math.PI * 2 / peakCount)
				}
				break
			}
		}

		while (angles.length < 3) {
			angles.push(-Math.PI + Math.random() * Math.PI * 2)
		}

		return {
			angles: angles,
			weights: [1, 1, peakCount === 3 ? 1 : 0]
		}
	}

	function randomizePeaks() {
		const currentAngles = []
		const currentWeights = []
		for (let index = 0; index < 3; index++) {
			currentAngles.push(currentPeakAngle(index))
			currentWeights.push(currentPeakWeight(index))
		}

		const next = randomPeakPattern()
		peakMorphAnimation.stop()
		peakFromAngles = currentAngles
		peakFromWeights = currentWeights
		peakToAngles = next.angles
		peakToWeights = next.weights
		peakMorph = 0
		peakMorphAnimation.restart()
	}

	function directionalGain(angle) {
		let strongestPeak = 0
		for (let index = 0; index < 3; index++) {
			const weight = currentPeakWeight(index)
			if (weight <= 0) continue

			const distance = angularDistance(angle, currentPeakAngle(index))
			const spread = 0.58
			const influence = Math.exp(-0.5 * Math.pow(distance / spread, 2))
			strongestPeak = Math.max(strongestPeak, influence * weight)
		}

		return 0.38 + strongestPeak * 0.62
	}

	onBandsChanged: spectrumCanvas.requestPaint()
	onCoverDiameterChanged: spectrumCanvas.requestPaint()
	onWidthChanged: spectrumCanvas.requestPaint()
	onHeightChanged: spectrumCanvas.requestPaint()
	onPeakMorphChanged: spectrumCanvas.requestPaint()

	Timer {
		id: peakPatternTimer
		interval: 2000
		repeat: true
		running: root.visible && root.opacity > 0 && root.barCount > 0
		onTriggered: {
			root.randomizePeaks()
			interval = 1600 + Math.round(Math.random() * 1000)
		}
	}

	NumberAnimation {
		id: peakMorphAnimation
		target: root
		property: "peakMorph"
		from: 0
		to: 1
		duration: 650
		easing.type: Easing.InOutCubic
	}

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
