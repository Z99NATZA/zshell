import QtQuick
import qs.theme

Item {
	id: root

	implicitWidth: 480
	implicitHeight: 480

	property var targets: []
	property bool active: false
	property bool motionEnabled: false
	property int entranceEpoch: 0
	property bool entranceReady: false
	property int playedEntranceEpoch: -1
	property int sweepRunEpoch: 0
	property int sweptTargetsEpoch: -1
	property var sweptTargets: ({})
	property real entranceScale: 1
	property real entranceOpacity: 1
	signal targetSwept(string key, int entranceEpoch)

	readonly property bool scanning: motionEnabled && active
	readonly property real sweepAngle: sweepLayer.rotation
	readonly property var targetSlotAngles: [-150, -90, -30, 30, 90, 150]
	scale: entranceScale
	opacity: entranceOpacity
	transformOrigin: Item.Center

	function playEntrance() {
		entranceAnimation.stop()
		entranceScale = 0.88
		entranceOpacity = 0
		entranceAnimation.start()
	}

	function syncEntrance() {
		if (!entranceReady || !motionEnabled || entranceEpoch <= 0
				|| playedEntranceEpoch === entranceEpoch) return

		playedEntranceEpoch = entranceEpoch
		playEntrance()
	}

	function cancelEntrance() {
		entranceAnimation.stop()
	}

	onEntranceEpochChanged: {
		resetTargetSweeps()
		syncEntrance()
	}
	onMotionEnabledChanged: {
		if (motionEnabled) syncEntrance()
		else cancelEntrance()
	}
	Component.onCompleted: {
		entranceReady = true
		if (sweptTargetsEpoch !== entranceEpoch) resetTargetSweeps()
		syncEntrance()
	}

	SequentialAnimation {
		id: entranceAnimation

		ParallelAnimation {
			NumberAnimation {
				target: root
				property: "entranceScale"
				from: 0.88
				to: 1.035
				duration: 240
				easing.type: Easing.OutCubic
			}
			NumberAnimation {
				target: root
				property: "entranceOpacity"
				from: 0
				to: 1
				duration: 170
				easing.type: Easing.OutCubic
			}
		}
		NumberAnimation {
			target: root
			property: "entranceScale"
			from: 1.035
			to: 0.985
			duration: 100
			easing.type: Easing.InOutQuad
		}
		NumberAnimation {
			target: root
			property: "entranceScale"
			from: 0.985
			to: 1
			duration: 100
			easing.type: Easing.OutCubic
		}

		onFinished: {
			root.entranceScale = 1
			root.entranceOpacity = 1
		}
	}

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
		const angle = targetAngle(key) * Math.PI / 180
		const downwardBias = Math.max(0, Math.sin(angle))
		const minimumRatio = 0.20 + downwardBias * 0.12
		const maximumRatio = 0.47

		return width * (minimumRatio + stableUnit(key, "radius")
			* (maximumRatio - minimumRatio))
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

	function sweepPhase(angle) {
		return (angle + 450) % 360
	}

	function resetTargetSweeps() {
		sweptTargetsEpoch = entranceEpoch
		sweptTargets = ({})
	}

	function targetWasSwept(key) {
		return sweptTargetsEpoch === entranceEpoch
			&& !!sweptTargets["$" + key]
	}

	function markTargetSwept(key) {
		if (entranceEpoch <= 0) return false
		if (sweptTargetsEpoch !== entranceEpoch) resetTargetSweeps()

		const token = "$" + key
		if (sweptTargets[token]) return false

		const nextSweptTargets = Object.assign({}, sweptTargets)
		nextSweptTargets[token] = true
		sweptTargets = nextSweptTargets
		targetSwept(key, entranceEpoch)
		return true
	}

	function targetIlluminated(key) {
		return scanning && angularDistance(targetAngle(key), sweepAngle) < 13
	}

	onScanningChanged: if (scanning) sweepRunEpoch++

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
				const sweepSpan = Math.PI * 7 / 18
				const sliceCount = 70
				context.reset()
				context.fillStyle = beamColor

				for (let index = 0; index < sliceCount; index++) {
					const startAngle = -sweepSpan + sweepSpan * index / sliceCount
					const endAngle = -sweepSpan
						+ sweepSpan * (index + 1) / sliceCount
					const progress = (index + 1) / sliceCount
					context.globalAlpha = progress * progress * (3 - 2 * progress)
					context.beginPath()
					context.moveTo(center, center)
					context.arc(center, center, radius, startAngle, endAngle)
					context.closePath()
					context.fill()
				}

				context.globalAlpha = 1
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
			duration: Theme.radarSweepDuration
			easing.type: Easing.Linear
			loops: Animation.Infinite
			running: root.scanning
		}
	}

	Repeater {
		model: root.targets

		Item {
			id: targetMarker

			required property var modelData
			readonly property string targetKey: modelData.key
			readonly property bool selected: !!modelData.selected
			readonly property bool illuminated: root.targetIlluminated(targetKey)
			readonly property bool discovered: root.targetWasSwept(targetKey)
			readonly property real targetSweepPhase:
				root.sweepPhase(root.targetAngle(targetKey))
			readonly property real currentSweepPhase: root.sweepPhase(root.sweepAngle)
			property real previousSweepPhase: currentSweepPhase
			property int trackedSweepRunEpoch: root.sweepRunEpoch

			function resetSweepTracking() {
				trackedSweepRunEpoch = root.sweepRunEpoch
				previousSweepPhase = currentSweepPhase
			}

			function observeSweep() {
				const current = currentSweepPhase
				if (!root.scanning || trackedSweepRunEpoch !== root.sweepRunEpoch) {
					resetSweepTracking()
					return
				}

				if (discovered) {
					previousSweepPhase = current
					return
				}

				const crossed = current >= previousSweepPhase
					? targetSweepPhase >= previousSweepPhase
						&& targetSweepPhase <= current
					: targetSweepPhase >= previousSweepPhase
						|| targetSweepPhase <= current
				previousSweepPhase = current

				if (crossed && root.markTargetSwept(targetKey)) triggerRipple()
			}

			function triggerRipple() {
				primaryRipple.restart()
				echoRipple.restart()
			}

			x: root.targetX(targetKey) - width / 2
			y: root.targetY(targetKey) - height / 2
			width: 14
			height: width
			onIlluminatedChanged: if (illuminated && discovered) triggerRipple()
			onSelectedChanged: if (selected && discovered) triggerRipple()
			onCurrentSweepPhaseChanged: observeSweep()

			Connections {
				target: root

				function onEntranceEpochChanged() {
					targetMarker.resetSweepTracking()
				}

				function onSweepRunEpochChanged() {
					targetMarker.resetSweepTracking()
				}
			}

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
				opacity: discovered
					? (selected ? 1 : (illuminated ? 0.72 : 0)) : 0
				scale: discovered
					? (selected ? 2 : (illuminated ? 1.7 : 0.5)) : 0.5

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
				opacity: discovered ? (root.active ? 0.9 : 0.48) : 0
				scale: discovered
					? (selected ? 1.6 : (illuminated ? 1.5 : 1)) : 0.5

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
