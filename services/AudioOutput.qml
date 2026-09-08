pragma Singleton

import Quickshell
import Quickshell.Services.Pipewire

Singleton {
	id: root

	readonly property var sink: Pipewire.defaultAudioSink
	readonly property bool available: sink !== null && sink.ready && sink.audio !== null
	readonly property var audio: available ? sink.audio : null
	readonly property int volume: available ? Math.round(audio.volume * 100) : 0
	readonly property bool muted: available && audio.muted
	readonly property string label: available ? (muted ? "muted" : volume + "%") : "--"
	readonly property string icon: {
		if (!available || muted || volume === 0) return "󰝟"
		if (volume < 34) return ""
		if (volume < 67) return ""
		return ""
	}

	function changeVolume(step) {
		if (!available) return
		audio.volume = Math.max(0, Math.min(1, audio.volume + step / 100))
	}

	function toggleMute() {
		if (available) audio.muted = !audio.muted
	}

	PwObjectTracker {
		objects: [root.sink]
	}
}
