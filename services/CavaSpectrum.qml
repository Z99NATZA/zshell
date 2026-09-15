import QtQuick
import Quickshell
import Quickshell.Io

Scope {
	id: root

	property bool active: false
	property var bands: zeroBands()
	property bool ready: false
	readonly property int bandCount: 32
	readonly property real bassLevel: averageBandRange(0, 6)

	function zeroBands() {
		const values = []
		for (let index = 0; index < bandCount; index++) values.push(0)
		return values
	}

	function averageBandRange(start, end) {
		if (!bands || bands.length === 0) return 0

		let total = 0
		const limit = Math.min(end, bands.length)
		for (let index = start; index < limit; index++) total += bands[index]
		return limit > start ? total / (limit - start) : 0
	}

	function applyFrame(frame) {
		const samples = frame.trim().split(";")
		if (samples.length < bandCount) return

		const previous = bands
		const next = []
		for (let index = 0; index < bandCount; index++) {
			const parsed = Number(samples[index])
			const normalized = isFinite(parsed)
				? Math.max(0, Math.min(1, parsed / 1000)) : 0
			const shaped = Math.pow(normalized, 0.72)
			const current = previous[index] || 0
			const response = shaped > current ? 0.72 : 0.34
			next.push(current + (shaped - current) * response)
		}

		bands = next
		ready = true
		decayTimer.stop()
	}

	function beginDecay() {
		if (!ready) return
		decayTimer.restart()
	}

	onActiveChanged: {
		if (active) {
			decayTimer.stop()
		} else {
			beginDecay()
		}
	}

	Process {
		id: cavaProcess

		running: root.active
		command: ["cava", "-p", Quickshell.shellPath("services/cava.conf")]

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
