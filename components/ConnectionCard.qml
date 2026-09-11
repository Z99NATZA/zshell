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
	radius: Theme.radius * 2
	raised: active || selected || radarHighlight
	interactive: active || selected || radarHighlight || pointer.containsMouse
	opacity: enabled ? 1 : 0.42
	scale: selected ? 1.05
		: (radarHighlight ? 1.035 : (pointer.containsMouse ? 1.018 : 1))
	transform: Translate {
		x: root.floatOffsetX
		y: root.floatOffsetY
	}

	function chooseFloatTarget() {
		if (!ambientMotion) return

		const angle = Math.random() * Math.PI * 2
		const distance = Math.sqrt(Math.random()) * floatRadius
		floatTransitionDuration = Math.round(1800 + Math.random() * 1400)
		floatOffsetX = Math.cos(angle) * distance
		floatOffsetY = Math.sin(angle) * distance
		floatTimer.restart()
	}

	function syncAmbientMotion() {
		if (ambientMotion) {
			chooseFloatTarget()
		} else {
			floatTimer.stop()
			floatOffsetX = 0
			floatOffsetY = 0
		}
	}

	onAmbientMotionChanged: if (motionReady) syncAmbientMotion()
	Component.onCompleted: {
		motionReady = true
		syncAmbientMotion()
	}

	Timer {
		id: floatTimer
		interval: root.floatTransitionDuration
		onTriggered: root.chooseFloatTarget()
	}

	Behavior on floatOffsetX {
		enabled: root.ambientMotion
		NumberAnimation {
			duration: root.floatTransitionDuration
			easing.type: Easing.InOutSine
		}
	}

	Behavior on floatOffsetY {
		enabled: root.ambientMotion
		NumberAnimation {
			duration: root.floatTransitionDuration
			easing.type: Easing.InOutSine
		}
	}

	Behavior on opacity {
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
		NumberAnimation { duration: Theme.motionDuration; easing.type: Easing.OutCubic }
	}

	Rectangle {
		anchors.fill: parent
		anchors.margins: 1
		radius: Math.max(0, root.radius - 1)
		opacity: root.selected || root.active ? 0.22 : 0.12
		gradient: Gradient {
			GradientStop { position: 0; color: Theme.surfaceRaised }
			GradientStop { position: 1; color: Theme.surface }
		}

		Behavior on opacity {
			NumberAnimation { duration: Theme.motionDuration }
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
			const edgeRatio = Math.max(
				Math.abs(centerDeltaX) / (root.width / 2),
				Math.abs(centerDeltaY) / (root.height / 2))
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
			running: root.radarBubble && root.ambientMotion
		}
	}

	Rectangle {
		anchors.fill: parent
		radius: parent.radius
		color: "transparent"
		border.width: 1
		border.color: Theme.accent
		opacity: root.selected ? 1 : 0
		scale: root.selected ? 1 : 0.96

		Behavior on opacity {
			NumberAnimation { duration: Theme.motionDuration }
		}

		Behavior on scale {
			NumberAnimation { duration: Theme.motionDuration; easing.type: Easing.OutCubic }
		}
	}

	Row {
		anchors.fill: parent
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
		hoverEnabled: true
		cursorShape: root.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
		onClicked: if (root.enabled) root.clicked()
	}
}
