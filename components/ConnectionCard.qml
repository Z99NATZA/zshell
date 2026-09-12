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
	property int cloudVariant: 0
	signal clicked

	implicitWidth: 184
	implicitHeight: 80
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
			ambientStartTimer.restart()
		} else {
			ambientStartTimer.stop()
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
		entranceScale = 0.86
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
		id: ambientStartTimer
		interval: 0
		onTriggered: if (root.ambientAnimationRunning) root.chooseFloatTarget()
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

	ParallelAnimation {
		id: entranceAnimation

		NumberAnimation {
			target: root
			property: "entranceScale"
			from: 0.86
			to: 1
			duration: Theme.modalOpenDuration
			easing.type: Easing.OutCubic
		}
		NumberAnimation {
			target: root
			property: "entranceOpacity"
			from: 0
			to: 1
			duration: Theme.modalCloseDuration
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
		readonly property int variant: ((root.cloudVariant % 6) + 6) % 6
		readonly property var upperProfiles: [
			[
				[0.04, 0.58, 0.10, 0.51, 0.19, 0.50],
				[0.25, 0.49, 0.24, 0.33, 0.31, 0.29],
				[0.36, 0.10, 0.50, 0.02, 0.60, 0.13],
				[0.67, 0.20, 0.67, 0.32, 0.76, 0.29],
				[0.84, 0.27, 0.91, 0.37, 0.92, 0.49],
				[0.98, 0.53, 0.94, 0.67, 0.965, 0.72]
			],
			[
				[0.04, 0.59, 0.11, 0.53, 0.20, 0.51],
				[0.26, 0.50, 0.27, 0.35, 0.34, 0.31],
				[0.40, 0.14, 0.48, 0.06, 0.55, 0.08],
				[0.63, 0.09, 0.70, 0.22, 0.73, 0.31],
				[0.81, 0.27, 0.90, 0.36, 0.92, 0.49],
				[0.98, 0.53, 0.94, 0.67, 0.965, 0.72]
			],
			[
				[0.04, 0.57, 0.11, 0.50, 0.18, 0.49],
				[0.23, 0.47, 0.24, 0.31, 0.31, 0.29],
				[0.35, 0.11, 0.43, 0.05, 0.49, 0.14],
				[0.53, 0.01, 0.63, 0.03, 0.66, 0.18],
				[0.70, 0.30, 0.75, 0.32, 0.80, 0.30],
				[0.87, 0.27, 0.92, 0.39, 0.93, 0.50],
				[0.98, 0.54, 0.94, 0.67, 0.965, 0.72]
			],
			[
				[0.04, 0.56, 0.10, 0.52, 0.17, 0.51],
				[0.22, 0.50, 0.22, 0.38, 0.28, 0.36],
				[0.32, 0.22, 0.39, 0.20, 0.43, 0.27],
				[0.47, 0.09, 0.56, 0.06, 0.62, 0.17],
				[0.67, 0.29, 0.72, 0.32, 0.78, 0.30],
				[0.86, 0.27, 0.92, 0.39, 0.93, 0.50],
				[0.98, 0.54, 0.94, 0.67, 0.965, 0.72]
			],
			[
				[0.04, 0.57, 0.10, 0.50, 0.18, 0.48],
				[0.23, 0.31, 0.31, 0.28, 0.36, 0.33],
				[0.40, 0.12, 0.50, 0.04, 0.57, 0.12],
				[0.66, 0.14, 0.70, 0.31, 0.76, 0.31],
				[0.84, 0.28, 0.91, 0.38, 0.92, 0.49],
				[0.98, 0.53, 0.94, 0.67, 0.965, 0.72]
			],
			[
				[0.04, 0.59, 0.11, 0.52, 0.20, 0.51],
				[0.27, 0.50, 0.27, 0.36, 0.34, 0.32],
				[0.39, 0.13, 0.50, 0.03, 0.58, 0.12],
				[0.63, 0.18, 0.66, 0.31, 0.73, 0.29],
				[0.78, 0.20, 0.87, 0.24, 0.89, 0.36],
				[0.96, 0.38, 0.94, 0.66, 0.965, 0.72]
			]
		]
		readonly property var baseProfiles: [
			[
				[0.82, 0.93, 0.73, 0.94, 0.64, 0.92],
				[0.56, 0.90, 0.52, 0.96, 0.44, 0.95],
				[0.32, 0.99, 0.17, 0.98, 0.09, 0.92]
			],
			[
				[0.81, 0.95, 0.72, 0.92, 0.63, 0.93],
				[0.53, 0.95, 0.47, 0.96, 0.39, 0.94],
				[0.28, 0.98, 0.17, 0.97, 0.09, 0.92]
			],
			[
				[0.82, 0.93, 0.73, 0.94, 0.65, 0.92],
				[0.57, 0.90, 0.51, 0.95, 0.43, 0.95],
				[0.32, 0.98, 0.18, 0.99, 0.09, 0.92]
			],
			[
				[0.83, 0.95, 0.73, 0.93, 0.65, 0.92],
				[0.57, 0.91, 0.50, 0.96, 0.42, 0.94],
				[0.31, 0.97, 0.18, 0.98, 0.09, 0.92]
			],
			[
				[0.82, 0.94, 0.72, 0.95, 0.62, 0.93],
				[0.53, 0.91, 0.48, 0.96, 0.39, 0.95],
				[0.29, 0.98, 0.17, 0.97, 0.09, 0.92]
			],
			[
				[0.82, 0.94, 0.73, 0.92, 0.64, 0.93],
				[0.55, 0.95, 0.48, 0.96, 0.40, 0.94],
				[0.30, 0.98, 0.18, 0.98, 0.09, 0.92]
			]
		]
		readonly property var profileYRanges: [
			[0.02, 0.99],
			[0.06, 0.98],
			[0.01, 0.99],
			[0.06, 0.98],
			[0.04, 0.98],
			[0.03, 0.98]
		]

		function insetX(value) {
			return 0.015 + Math.max(0, Math.min(1, value)) * 0.97
		}

		function insetY(value) {
			const range = profileYRanges[variant]
			const clamped = Math.max(range[0], Math.min(range[1], value))
			const normalized = (clamped - range[0]) / (range[1] - range[0])
			return 0.025 + normalized * 0.95
		}

		function traceSegments(context, segments, cardWidth, cardHeight) {
			for (let index = 0; index < segments.length; index++) {
				const segment = segments[index]
				context.bezierCurveTo(cardWidth * insetX(segment[0]),
					cardHeight * insetY(segment[1]),
					cardWidth * insetX(segment[2]),
					cardHeight * insetY(segment[3]),
					cardWidth * insetX(segment[4]),
					cardHeight * insetY(segment[5]))
			}
		}

		function traceCloud(context) {
			const cardWidth = width
			const cardHeight = height
			context.beginPath()
			context.moveTo(cardWidth * insetX(0.09), cardHeight * insetY(0.92))
			context.bezierCurveTo(cardWidth * insetX(0.03),
				cardHeight * insetY(0.90), cardWidth * insetX(0.015),
				cardHeight * insetY(0.82), cardWidth * insetX(0.035),
				cardHeight * insetY(0.70))
			traceSegments(context, upperProfiles[variant], cardWidth, cardHeight)
			context.bezierCurveTo(cardWidth * insetX(0.99),
				cardHeight * insetY(0.77), cardWidth * insetX(0.98),
				cardHeight * insetY(0.87), cardWidth * insetX(0.91),
				cardHeight * insetY(0.90))
			traceSegments(context, baseProfiles[variant], cardWidth, cardHeight)
			context.closePath()
		}

		onFillColorChanged: requestPaint()
		onOutlineColorChanged: requestPaint()
		onSheenColorChanged: requestPaint()
		onShadeColorChanged: requestPaint()
		onVariantChanged: requestPaint()
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
			context.lineCap = "round"
			context.lineJoin = "round"
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
