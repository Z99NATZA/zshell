pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris
import qs.state

Singleton {
	id: root

	readonly property int bandCount: 32
	readonly property var player: Mpris.players.values.length > 0
		? Mpris.players.values[0] : null
	property var consumers: []
	readonly property bool requested: consumers.length > 0
	readonly property bool active: requested && LayoutState.showMusic
		&& player !== null && player.isPlaying
	property var bands: zeroBands()
	property var bandFloors: []
	property var bandCeilings: []
	property bool ready: false

	function setRequested(consumer, requested) {
		const next = []
		for (let index = 0; index < consumers.length; index++) {
			if (consumers[index] !== consumer) next.push(consumers[index])
		}
		if (requested) next.push(consumer)
		consumers = next
	}

	function zeroBands() {
		const values = []
		for (let index = 0; index < bandCount; index++) values.push(0)
		return values
	}

	function applyFrame(frame) {
		const samples = frame.trim().split(";")
		if (samples.length !== bandCount) return

		const previous = bands
		const calibrated = bandFloors.length === bandCount
			&& bandCeilings.length === bandCount
		const next = []
		const nextFloors = []
		const nextCeilings = []
		for (let index = 0; index < bandCount; index++) {
			const parsed = Number(samples[index])
			const normalized = isFinite(parsed)
				? Math.max(0, Math.min(1, parsed / 1000)) : 0

			let floor = calibrated ? bandFloors[index] : normalized * 0.72
			let ceiling = calibrated ? bandCeilings[index]
				: Math.min(1, 0.18 + normalized * 0.82)
			if (calibrated) {
				floor += (normalized - floor)
					* (normalized < floor ? 1 : 0.0015)
				ceiling += (normalized - ceiling)
					* (normalized > ceiling ? 1 : 0.004)
			}
			if (ceiling - floor < 0.12) ceiling = floor + 0.12
			if (ceiling > 1) {
				ceiling = 1
				floor = Math.min(floor, 0.88)
			}

			const relative = Math.max(0, Math.min(1,
				(normalized - floor) / Math.max(0.12, ceiling - floor)))
			const target = Math.pow(relative, 1.05)
			const current = previous[index] || 0
			const response = target > current ? 0.8 : 0.52
			next.push(current + (target - current) * response)
			nextFloors.push(floor)
			nextCeilings.push(ceiling)
		}

		bandFloors = nextFloors
		bandCeilings = nextCeilings
		bands = next
		ready = true
		decayTimer.stop()
	}

	function beginDecay() {
		if (ready) decayTimer.restart()
	}

	onActiveChanged: {
		if (active) {
			bandFloors = []
			bandCeilings = []
			decayTimer.stop()
		} else {
			beginDecay()
		}
	}

	Process {
		id: spectrumProcess

		running: root.active
		command: [Quickshell.shellPath(".build/zshell-spectrum")]

		stdout: SplitParser {
			splitMarker: "\n"
			onRead: data => root.applyFrame(data)
		}

		onRunningChanged: {
			if (!running) root.beginDecay()
		}
	}

	Timer {
		id: decayTimer

		interval: 33
		repeat: true

		onTriggered: {
			const previous = root.bands
			const next = []
			let peak = 0

			for (let index = 0; index < root.bandCount; index++) {
				const value = (previous[index] || 0) * 0.72
				next.push(value)
				peak = Math.max(peak, value)
			}

			root.bands = next
			if (peak < 0.004) {
				stop()
				root.bands = root.zeroBands()
				root.ready = false
			}
		}
	}
}
