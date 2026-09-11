import QtQuick
import qs.theme

Item {
	id: root

	implicitWidth: 480
	implicitHeight: 480

	property var targets: []
	property bool active: false
	property bool busy: false
	property bool motionEnabled: false

	readonly property bool scanning: motionEnabled && active
	readonly property real sweepAngle: sweepLayer.rotation
	readonly property var targetSlotAngles: [-150, -90, -30, 30, 90, 150]

	function stableHash(value) {
		let hash = 0
		const text = String(value)

		for (let index = 0; index < text.length; index++) {
			hash = ((hash << 5) - hash + text.charCodeAt(index)) | 0
		}

		return Math.abs(hash)
	}

	function stableUnit(key, salt) {
		return stableHash(String(key) + ":" + salt) / 2147483648
	}

	function targetAngle(key) {
		return targetSlotAngles[targetSlot(key)]
			+ (stableUnit(key, "angle-jitter") - 0.5) * 8
	}

	function targetRadius(key) {
		return width * (0.38 + stableUnit(key, "radius") * 0.025)
	}

	function targetSlot(key) {
		const occupied = []

		for (let index = 0; index < targets.length; index++) {
			const targetKey = targets[index].key
			let slot = Math.floor(stableUnit(targetKey, "slot")
				* targetSlotAngles.length)

			while (occupied[slot]) slot = (slot + 1) % targetSlotAngles.length
			occupied[slot] = true

			if (targetKey === key) return slot
		}

		return 0
	}

	function targetX(key) {
		const angle = targetAngle(key) * Math.PI / 180
		return width / 2 + Math.cos(angle) * targetRadius(key)
	}

	function targetY(key) {
		const angle = targetAngle(key) * Math.PI / 180
		return height / 2 + Math.sin(angle) * targetRadius(key)
	}

	function angularDistance(first, second) {
		return Math.abs(((first - second + 540) % 360) - 180)
	}

	function targetIlluminated(key) {
		return scanning && angularDistance(targetAngle(key), sweepAngle) < 13
	}

	Rectangle {
		anchors.fill: parent
		radius: width / 2
		color: Theme.surfaceSoft
		border.width: 1
		border.color: root.active ? Theme.accent : Theme.borderStrong
		opacity: root.active ? 0.2 : 0.12

		Behavior on border.color {
			ColorAnimation { duration: Theme.motionDuration }
		}

		Behavior on opacity {
			NumberAnimation { duration: Theme.motionDuration }
		}
	}

	Canvas {
		id: grid
		anchors.fill: parent
		opacity: root.active ? 0.34 : 0.2
		property color lineColor: root.active ? Theme.accent : Theme.borderStrong

		onLineColorChanged: requestPaint()
		onWidthChanged: requestPaint()
		onHeightChanged: requestPaint()

		onPaint: {
			const context = getContext("2d")
			const centerX = width / 2
			const centerY = height / 2
			const radius = Math.min(width, height) / 2 - 1
			context.reset()
			context.strokeStyle = lineColor
			context.lineWidth = 1

			for (let ring = 1; ring <= 5; ring++) {
				context.beginPath()
				context.arc(centerX, centerY, radius * ring / 5,
					0, Math.PI * 2)
				context.stroke()
			}

			for (let spoke = 0; spoke < 8; spoke++) {
				const angle = spoke * Math.PI / 4
				context.beginPath()
				context.moveTo(centerX, centerY)
				context.lineTo(centerX + Math.cos(angle) * radius,
					centerY + Math.sin(angle) * radius)
				context.stroke()
			}
		}

		Behavior on opacity {
			NumberAnimation { duration: Theme.motionDuration }
		}
	}

	Item {
		id: sweepLayer
		anchors.centerIn: parent
		width: parent.width
		height: width
		visible: root.active
		rotation: -90

		Canvas {
			id: sweepFill
			anchors.fill: parent
			opacity: root.scanning ? 0.16 : 0.08
			property color beamColor: Theme.accent

			onBeamColorChanged: requestPaint()
			onWidthChanged: requestPaint()
			onHeightChanged: requestPaint()

			onPaint: {
				const context = getContext("2d")
				const center = width / 2
				const radius = width / 2 - 2
				context.reset()
				context.fillStyle = beamColor
				context.beginPath()
				context.moveTo(center, center)
				context.arc(center, center, radius, -Math.PI / 7, 0)
				context.closePath()
				context.fill()
			}

			Behavior on opacity {
				NumberAnimation { duration: Theme.motionDuration }
			}
		}

		Rectangle {
			anchors.left: parent.horizontalCenter
			anchors.verticalCenter: parent.verticalCenter
			width: parent.width / 2 - 2
			height: 1
			color: Theme.accent
			opacity: root.scanning ? 0.9 : 0.4
		}

		RotationAnimation on rotation {
			from: -90
			to: 270
			duration: root.busy
				? Theme.radarBusySweepDuration : Theme.radarSweepDuration
			easing.type: Easing.Linear
			loops: Animation.Infinite
			running: root.scanning
		}
	}

	Repeater {
		model: root.targets

		Item {
			required property var modelData
			readonly property string targetKey: modelData.key
			readonly property bool selected: !!modelData.selected
			readonly property bool illuminated: root.targetIlluminated(targetKey)

			function triggerRipple() {
				primaryRipple.restart()
				echoRipple.restart()
			}

			x: root.targetX(targetKey) - width / 2
			y: root.targetY(targetKey) - height / 2
			width: 14
			height: width
			onIlluminatedChanged: if (illuminated) triggerRipple()
			onSelectedChanged: if (selected) triggerRipple()

			Rectangle {
				id: primaryRippleRing
				anchors.centerIn: parent
				width: parent.width
				height: width
				radius: width / 2
				color: "transparent"
				border.width: 1
				border.color: Theme.accent
				opacity: 0
			}

			ParallelAnimation {
				id: primaryRipple

				NumberAnimation {
					target: primaryRippleRing
					property: "scale"
					from: 0.7
					to: 3.8
					duration: 920
					easing.type: Easing.OutCubic
				}
				NumberAnimation {
					target: primaryRippleRing
					property: "opacity"
					from: 0.5
					to: 0
					duration: 920
					easing.type: Easing.OutCubic
				}
			}

			Rectangle {
				id: echoRippleRing
				anchors.centerIn: parent
				width: parent.width
				height: width
				radius: width / 2
				color: "transparent"
				border.width: 1
				border.color: Theme.accent
				opacity: 0
			}

			SequentialAnimation {
				id: echoRipple

				PauseAnimation { duration: 170 }
				ParallelAnimation {
					NumberAnimation {
						target: echoRippleRing
						property: "scale"
						from: 0.7
						to: 3.2
						duration: 780
						easing.type: Easing.OutCubic
					}
					NumberAnimation {
						target: echoRippleRing
						property: "opacity"
						from: 0.3
						to: 0
						duration: 780
						easing.type: Easing.OutCubic
					}
				}
			}

			Rectangle {
				anchors.centerIn: parent
				width: parent.width
				height: width
				radius: width / 2
				color: "transparent"
				border.width: 1
				border.color: Theme.accent
				opacity: selected ? 1 : (illuminated ? 0.72 : 0)
				scale: selected ? 2 : (illuminated ? 1.7 : 0.5)

				Behavior on opacity {
					NumberAnimation { duration: Theme.motionDuration }
				}

				Behavior on scale {
					NumberAnimation {
						duration: Theme.motionDuration
						easing.type: Easing.OutCubic
					}
				}
			}

			Rectangle {
				anchors.centerIn: parent
				width: selected ? 8 : (modelData.active ? 7 : 5)
				height: width
				radius: width / 2
				color: Theme.accent
				opacity: root.active ? 0.9 : 0.48
				scale: selected ? 1.6 : (illuminated ? 1.5 : 1)

				Behavior on opacity {
					NumberAnimation { duration: Theme.motionDuration }
				}

				Behavior on scale {
					NumberAnimation {
						duration: Theme.motionDuration
						easing.type: Easing.OutCubic
					}
				}
			}
		}
	}
}
