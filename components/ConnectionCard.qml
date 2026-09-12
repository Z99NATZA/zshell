import QtQuick
import qs.theme

ShellSurface {
	id: root

	property string icon: ""
	property string title: ""
	property string subtitle: ""
	property bool active: false
	property bool selected: false
	property bool radarHighlight: false
	property bool radarBubble: false
	property bool ambientMotion: false
	property bool motionReady: false
	property bool entranceActive: false
	readonly property bool ambientAnimationRunning: ambientMotion && !entranceActive
	property real entranceScale: 1
	property real entranceOpacity: 1
	property real floatRadius: 10
	property int floatTransitionDuration: 2400
	property real floatOffsetX: 0
	property real floatOffsetY: 0
	property real connectorBend: 10
	property real connectorTargetX: width / 2
	property real connectorTargetY: height + Theme.spacingLg
	property int connectorDuration: 2400
	signal clicked

	implicitWidth: 176
	implicitHeight: 58
	radius: height / 2
	raised: active || selected || radarHighlight
	interactive: active || selected || radarHighlight || pointer.containsMouse
	color: "transparent"
	border.width: 0
	opacity: (enabled ? 1 : 0.42) * entranceOpacity
	scale: (selected ? 1.05
		: (radarHighlight ? 1.035 : (pointer.containsMouse ? 1.018 : 1)))
		* entranceScale
	transform: Translate {
		x: root.floatOffsetX
		y: root.floatOffsetY
	}

	function chooseFloatTarget() {
		if (!ambientAnimationRunning) return

		const angle = Math.random() * Math.PI * 2
		const distance = Math.sqrt(Math.random()) * floatRadius
		floatTransitionDuration = Math.round(1800 + Math.random() * 1400)
		floatOffsetX = Math.cos(angle) * distance
		floatOffsetY = Math.sin(angle) * distance
		floatTimer.restart()
	}

	function syncAmbientMotion() {
		if (ambientAnimationRunning) {
			chooseFloatTarget()
		} else {
			floatTimer.stop()
			floatOffsetX = 0
			floatOffsetY = 0
		}
	}

	function playEntrance(delay) {
		prepareEntrance()
		entranceDelay.interval = Math.max(0, delay)

		if (entranceDelay.interval > 0) entranceDelay.start()
		else entranceAnimation.start()
	}

	function prepareEntrance() {
		entranceDelay.stop()
		entranceAnimation.stop()
		entranceActive = true
		entranceScale = 0.65
		entranceOpacity = 0
	}

	function completeEntrance() {
		entranceDelay.stop()
		entranceAnimation.stop()
		entranceScale = 1
		entranceOpacity = 1
		entranceActive = false
	}

	function cancelEntrance() {
		entranceDelay.stop()
		entranceAnimation.stop()
		entranceActive = false
	}

	onAmbientAnimationRunningChanged: {
		if (!motionReady) return

		syncAmbientMotion()
	}
	onAmbientMotionChanged: if (!ambientMotion) cancelEntrance()
	Component.onCompleted: {
		motionReady = true
		syncAmbientMotion()
	}

	Timer {
		id: floatTimer
		interval: root.floatTransitionDuration
		onTriggered: root.chooseFloatTarget()
	}

	Timer {
		id: entranceDelay
		onTriggered: entranceAnimation.start()
	}

	SequentialAnimation {
		id: entranceAnimation

		ParallelAnimation {
			NumberAnimation {
				target: root
				property: "entranceScale"
				from: 0.65
				to: 1.10
				duration: 220
				easing.type: Easing.OutCubic
			}
			NumberAnimation {
				target: root
				property: "entranceOpacity"
				from: 0
				to: 1
				duration: 160
				easing.type: Easing.OutCubic
			}
		}
		NumberAnimation {
			target: root
			property: "entranceScale"
			from: 1.10
			to: 0.96
			duration: 120
			easing.type: Easing.InOutQuad
		}
		NumberAnimation {
			target: root
			property: "entranceScale"
			from: 0.96
			to: 1
			duration: 130
			easing.type: Easing.OutCubic
		}

		onFinished: {
			root.entranceScale = 1
			root.entranceOpacity = 1
			root.entranceActive = false
		}
	}

	Behavior on floatOffsetX {
		enabled: root.ambientAnimationRunning
		NumberAnimation {
			duration: root.floatTransitionDuration
			easing.type: Easing.InOutSine
		}
	}

	Behavior on floatOffsetY {
		enabled: root.ambientAnimationRunning
		NumberAnimation {
			duration: root.floatTransitionDuration
			easing.type: Easing.InOutSine
		}
	}

	Behavior on opacity {
		enabled: !root.entranceActive
		NumberAnimation { duration: Theme.motionDuration; easing.type: Easing.OutCubic }
	}

	Behavior on x {
		enabled: !root.radarBubble
		NumberAnimation { duration: Theme.modalOpenDuration; easing.type: Easing.OutCubic }
	}

	Behavior on y {
		enabled: !root.radarBubble
		NumberAnimation { duration: Theme.modalOpenDuration; easing.type: Easing.OutCubic }
	}

	Behavior on scale {
		enabled: !root.entranceActive
		NumberAnimation { duration: Theme.motionDuration; easing.type: Easing.OutCubic }
	}

	Canvas {
		id: cloudSurface

		anchors.fill: parent
		property color fillColor: root.raised
			? Theme.connectionBubbleRaised : Theme.connectionBubble
		property color outlineColor: root.selected || root.radarHighlight
			? Theme.accent : Theme.connectionBubbleBorder
		property color sheenColor: Theme.connectionBubbleSheen
		property color shadeColor: Theme.connectionBubbleShade

		function traceCloud(context) {
			const cardWidth = width
			const cardHeight = height
			context.beginPath()
			context.moveTo(cardWidth * 0.08, cardHeight * 0.98)
			context.bezierCurveTo(cardWidth * 0.025, cardHeight * 0.98,
				0, cardHeight * 0.88, cardWidth * 0.018, cardHeight * 0.72)
			context.bezierCurveTo(cardWidth * 0.025, cardHeight * 0.59,
				cardWidth * 0.055, cardHeight * 0.36,
				cardWidth * 0.13, cardHeight * 0.32)
			context.bezierCurveTo(cardWidth * 0.12, cardHeight * 0.16,
				cardWidth * 0.20, cardHeight * 0.10,
				cardWidth * 0.26, cardHeight * 0.20)
			context.bezierCurveTo(cardWidth * 0.28, cardHeight * 0.05,
				cardWidth * 0.40, -cardHeight * 0.01,
				cardWidth * 0.47, cardHeight * 0.17)
			context.bezierCurveTo(cardWidth * 0.54, cardHeight * 0.04,
				cardWidth * 0.69, cardHeight * 0.06,
				cardWidth * 0.73, cardHeight * 0.28)
			context.bezierCurveTo(cardWidth * 0.79, cardHeight * 0.13,
				cardWidth * 0.91, cardHeight * 0.11,
				cardWidth * 0.94, cardHeight * 0.26)
			context.bezierCurveTo(cardWidth * 0.995, cardHeight * 0.34,
				cardWidth, cardHeight * 0.60,
				cardWidth * 0.975, cardHeight * 0.75)
			context.bezierCurveTo(cardWidth * 0.99, cardHeight * 0.89,
				cardWidth * 0.95, cardHeight * 0.98,
				cardWidth * 0.88, cardHeight * 0.98)
			context.bezierCurveTo(cardWidth * 0.83, cardHeight * 0.98,
				cardWidth * 0.79, cardHeight * 0.92,
				cardWidth * 0.76, cardHeight * 0.88)
			context.bezierCurveTo(cardWidth * 0.70, cardHeight * 1.01,
				cardWidth * 0.60, cardHeight,
				cardWidth * 0.55, cardHeight * 0.91)
			context.bezierCurveTo(cardWidth * 0.48, cardHeight,
				cardWidth * 0.36, cardHeight,
				cardWidth * 0.30, cardHeight * 0.91)
			context.bezierCurveTo(cardWidth * 0.24, cardHeight * 1.01,
				cardWidth * 0.15, cardHeight,
				cardWidth * 0.08, cardHeight * 0.98)
			context.closePath()
		}

		onFillColorChanged: requestPaint()
		onOutlineColorChanged: requestPaint()
		onSheenColorChanged: requestPaint()
		onShadeColorChanged: requestPaint()
		onWidthChanged: requestPaint()
		onHeightChanged: requestPaint()

		onPaint: {
			const context = getContext("2d")
			context.reset()
			traceCloud(context)
			context.fillStyle = fillColor
			context.fill()

			const glassLight = context.createLinearGradient(0, 0, 0, height)
			glassLight.addColorStop(0, sheenColor)
			glassLight.addColorStop(0.44, "transparent")
			glassLight.addColorStop(1, shadeColor)
			traceCloud(context)
			context.fillStyle = glassLight
			context.fill()

			traceCloud(context)
			context.strokeStyle = outlineColor
			context.lineWidth = root.selected ? 1.6 : 1
			context.stroke()
		}

		Behavior on fillColor {
			ColorAnimation { duration: Theme.motionDuration }
		}

		Behavior on outlineColor {
			ColorAnimation { duration: Theme.motionDuration }
		}
	}

	Canvas {
		id: connector
		readonly property real padding: root.floatRadius + 18
		readonly property real minimumX: Math.min(0, targetX) - padding
		readonly property real minimumY: Math.min(0, targetY) - padding
		readonly property real maximumX: Math.max(root.width, targetX) + padding
		readonly property real maximumY: Math.max(root.height, targetY) + padding
		property color lineColor: Theme.accent
		property real cardOffsetX: root.floatOffsetX
		property real cardOffsetY: root.floatOffsetY
		property real targetX: root.connectorTargetX
		property real targetY: root.connectorTargetY
		property real wavePhase: 0

		x: minimumX
		y: minimumY
		width: maximumX - minimumX
		height: maximumY - minimumY
		visible: root.radarBubble

		onLineColorChanged: requestPaint()
		onCardOffsetXChanged: requestPaint()
		onCardOffsetYChanged: requestPaint()
		onTargetXChanged: requestPaint()
		onTargetYChanged: requestPaint()
		onWavePhaseChanged: requestPaint()
		onWidthChanged: requestPaint()
		onHeightChanged: requestPaint()

		onPaint: {
			const context = getContext("2d")
			const centerX = root.width / 2 - x
			const centerY = root.height / 2 - y
			const endX = targetX - cardOffsetX - x
			const endY = targetY - cardOffsetY - y
			const centerDeltaX = endX - centerX
			const centerDeltaY = endY - centerY
			const horizontalRadius = root.width / 2 - 5
			const verticalRadius = root.height / 2 - 4
			const edgeRatio = Math.sqrt(
				Math.pow(centerDeltaX / horizontalRadius, 2)
				+ Math.pow(centerDeltaY / verticalRadius, 2))
			const edgeScale = Math.min(1, 1 / Math.max(0.0001, edgeRatio))
			const startX = centerX + centerDeltaX * edgeScale
			const startY = centerY + centerDeltaY * edgeScale
			const deltaX = endX - startX
			const deltaY = endY - startY
			const distance = Math.max(1, Math.sqrt(deltaX * deltaX
				+ deltaY * deltaY))
			const curve = root.connectorBend + Math.sin(wavePhase) * 4
			const controlX = (startX + endX) / 2 - deltaY / distance * curve
			const controlY = (startY + endY) / 2 + deltaX / distance * curve

			context.reset()
			context.strokeStyle = lineColor
			context.lineWidth = root.selected ? 1.8 : 1.2
			context.globalAlpha = root.selected ? 0.82 : 0.46
			context.beginPath()
			context.moveTo(startX, startY)
			context.quadraticCurveTo(controlX, controlY, endX, endY)
			context.stroke()

			context.fillStyle = lineColor
			for (let index = 0; index < 3; index++) {
				const t = (wavePhase / (Math.PI * 2) + index / 3) % 1
				const inverse = 1 - t
				const pointX = inverse * inverse * startX
					+ 2 * inverse * t * controlX + t * t * endX
				const pointY = inverse * inverse * startY
					+ 2 * inverse * t * controlY + t * t * endY
				context.globalAlpha = 0.28 + Math.sin(Math.PI * t) * 0.58
				context.beginPath()
				context.arc(pointX, pointY, root.selected ? 1.8 : 1.35,
					0, Math.PI * 2)
				context.fill()
			}
			context.globalAlpha = 1
		}

		NumberAnimation on wavePhase {
			from: 0
			to: Math.PI * 2
			duration: root.connectorDuration
			easing.type: Easing.Linear
			loops: Animation.Infinite
			running: root.radarBubble && root.ambientAnimationRunning
		}
	}

	Row {
		anchors.fill: parent
		anchors.topMargin: Theme.spacingXs
		anchors.leftMargin: Theme.spacingMd
		anchors.rightMargin: Theme.spacingMd
		spacing: Theme.spacingSm

		Text {
			width: 24
			height: parent.height
			text: root.icon
			color: root.active ? Theme.accent : Theme.text
			horizontalAlignment: Text.AlignHCenter
			verticalAlignment: Text.AlignVCenter
			font.family: Theme.fontFamily
			font.pixelSize: 16
		}

		Column {
			width: parent.width - 24 - parent.spacing
			anchors.verticalCenter: parent.verticalCenter
			spacing: 2

			Text {
				width: parent.width
				text: root.title
				color: Theme.text
				font.family: Theme.textFontFamily
				font.pixelSize: 12
				font.weight: Font.Medium
				elide: Text.ElideRight
			}

			Text {
				width: parent.width
				text: root.subtitle
				color: root.active ? Theme.accent : Theme.textMuted
				font.family: Theme.textFontFamily
				font.pixelSize: 10
				elide: Text.ElideRight
			}
		}
	}

	MouseArea {
		id: pointer
		anchors.fill: parent
		enabled: root.enabled && !root.entranceActive
		hoverEnabled: true
		cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
		onClicked: if (root.enabled) root.clicked()
	}
}
