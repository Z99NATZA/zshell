import QtQuick
import QtQuick.Dialogs
import QtMultimedia
import Quickshell.Widgets
import qs.state
import qs.theme

FloatingPanel {
	id: root

	property real transitionX: 0
	property real transitionY: 0
	property real transitionWidth: 0
	property real transitionHeight: 0
	property real availableWidth: 0
	property real availableHeight: 0
	property bool geometryInitialized: false
	property string requestedSource: ""
	property string acceptedSource: ""
	property string validationMessage: ""
	property bool sourceValid: false
	property bool userPaused: false
	property bool muted: true
	property bool restoringAcceptedSource: false
	property bool rejectionPending: false
	property bool chromeRevealed: false
	readonly property int maximumDuration: 30 * 1000
	readonly property bool modeTransitionRunning: modeTransition.running
	readonly property bool playing: mediaPlayer.playbackState
		=== MediaPlayer.PlayingState
	readonly property bool loading: requestedSource.length > 0 && !sourceValid
		&& mediaPlayer.mediaStatus !== MediaPlayer.InvalidMedia

	title: "Video preview"
	icon: "󰕧"
	active: UiState.activeComponent === "video"
	boundsWidth: availableWidth
	boundsHeight: availableHeight
	minimumPanelWidth: expanded ? 560 : 320
	minimumPanelHeight: expanded ? 390 : 180
	transitioning: modeTransitionRunning
	contentUnderHeader: true
	headerControlsVisible: chromeRevealed
	z: UiState.videoStack
	focus: active && expanded

	function clampedWidth(value, minimum) {
		const available = Math.max(1, availableWidth - edgeMargin * 2)
		return Math.max(Math.min(minimum, available), Math.min(value, available))
	}

	function clampedHeight(value, minimum) {
		const available = Math.max(1,
			availableHeight - edgeMargin - bottomMargin)
		return Math.max(Math.min(minimum, available), Math.min(value, available))
	}

	function clampedX(value, panelWidth) {
		return Math.max(edgeMargin,
			Math.min(availableWidth - panelWidth - edgeMargin, value))
	}

	function clampedY(value, panelHeight) {
		return Math.max(edgeMargin,
			Math.min(availableHeight - panelHeight - bottomMargin, value))
	}

	function storeGeometry() {
		if (expanded) {
			LayoutState.videoExpandedX = Math.round(x)
			LayoutState.videoExpandedY = Math.round(y)
			LayoutState.videoExpandedWidth = Math.round(width)
			LayoutState.videoExpandedHeight = Math.round(height)
		} else {
			LayoutState.videoX = Math.round(x)
			LayoutState.videoY = Math.round(y)
			LayoutState.videoWidth = Math.round(width)
			LayoutState.videoHeight = Math.round(height)
		}
	}

	function setExpanded(nextExpanded, activatePanel) {
		if (expanded === nextExpanded || modeTransition.running) return
		if (activatePanel === undefined) activatePanel = true

		storeGeometry()
		if (activatePanel) UiState.activateComponent("video")

		const nextWidth = clampedWidth(nextExpanded
			? LayoutState.videoExpandedWidth : LayoutState.videoWidth,
			nextExpanded ? 560 : 320)
		const nextHeight = clampedHeight(nextExpanded
			? LayoutState.videoExpandedHeight : LayoutState.videoHeight,
			nextExpanded ? 390 : 180)

		if (nextExpanded) {
			const target = anchoredExpansionGeometry(nextWidth, nextHeight)
			transitionX = target.x
			transitionY = target.y
			transitionWidth = target.width
			transitionHeight = target.height
		} else {
			transitionX = clampedX(LayoutState.videoX, nextWidth)
			transitionY = clampedY(LayoutState.videoY, nextHeight)
			transitionWidth = nextWidth
			transitionHeight = nextHeight
		}
		expanded = nextExpanded
		modeTransition.restart()
		if (activatePanel) focusTimer.restart()
	}

	function restoreMinimalGeometry() {
		if (availableWidth < 400 || availableHeight < 260) return

		width = clampedWidth(LayoutState.videoWidth, 320)
		height = clampedHeight(LayoutState.videoHeight, 180)
		x = clampedX(LayoutState.videoX, width)
		y = clampedY(LayoutState.videoY, height)
		geometryInitialized = true
		storeGeometry()
	}

	function formatDuration(milliseconds) {
		if (!isFinite(milliseconds) || milliseconds < 0) return "0:00"

		const totalSeconds = Math.floor(milliseconds / 1000)
		const minutes = Math.floor(totalSeconds / 60)
		const seconds = totalSeconds % 60
		return minutes + ":" + String(seconds).padStart(2, "0")
	}

	function sourceName(source) {
		if (!source) return "No video selected"

		const value = decodeURIComponent(String(source))
		const separator = value.lastIndexOf("/")
		return separator >= 0 ? value.slice(separator + 1) : value
	}

	function loadSource(source, restoring) {
		const value = String(source || "")
		if (!value) return

		validationTimer.stop()
		rejectionTimer.stop()
		rejectionPending = false
		mediaPlayer.stop()
		sourceValid = false
		userPaused = false
		restoringAcceptedSource = restoring === true
		if (!restoringAcceptedSource) validationMessage = ""
		requestedSource = value
		mediaPlayer.source = value
	}

	function validateSource(finalCheck) {
		if (!requestedSource || rejectionPending) return

		if (mediaPlayer.mediaStatus === MediaPlayer.InvalidMedia) {
			rejectSource(mediaPlayer.errorString || "Unable to open this video")
			return
		}

		if (mediaPlayer.duration > maximumDuration) {
			rejectSource("Choose a video that is 30 seconds or shorter")
			return
		}

		if (mediaPlayer.duration <= 0) {
			if (finalCheck) rejectSource("Unable to determine the video duration")
			return
		}
		if (!mediaPlayer.hasVideo) {
			if (finalCheck) rejectSource("The selected file has no video track")
			return
		}

		acceptSource()
	}

	function acceptSource() {
		if (sourceValid || !requestedSource) return

		sourceValid = true
		acceptedSource = requestedSource
		if (!restoringAcceptedSource
				&& LayoutState.videoSource !== acceptedSource) {
			LayoutState.videoSource = acceptedSource
		}
		restoringAcceptedSource = false
		if (visible && !userPaused) mediaPlayer.play()
	}

	function rejectSource(message) {
		if (rejectionPending) return

		rejectionPending = true
		rejectionTimer.rejectionMessage = message
		rejectionTimer.fallbackSource = acceptedSource !== requestedSource
			? acceptedSource : ""
		rejectionTimer.restart()
	}

	function finishRejection(message, fallback) {
		validationTimer.stop()
		mediaPlayer.stop()
		mediaPlayer.source = ""
		requestedSource = ""
		sourceValid = false
		restoringAcceptedSource = false
		rejectionPending = false
		validationMessage = message
		messageTimer.restart()

		if (fallback) {
			fallbackTimer.fallbackSource = fallback
			fallbackTimer.restart()
		}
	}

	function togglePlayback() {
		if (!sourceValid) return

		if (playing) {
			userPaused = true
			mediaPlayer.pause()
		} else {
			userPaused = false
			mediaPlayer.play()
		}
	}

	function revealChrome() {
		if (!expanded) return

		chromeHideTimer.stop()
		chromeRevealed = true
	}

	function scheduleChromeHide() {
		if (!expanded || panelHover.hovered || dragging || resizing) return

		chromeHideTimer.restart()
	}

	onActivated: {
		UiState.activateComponent("video")
		if (expanded) focusTimer.restart()
	}
	onModeToggleRequested: root.setExpanded(!root.expanded)
	onGeometryCommitted: (panelX, panelY, panelWidth, panelHeight) => {
		root.storeGeometry()
	}
	onVisibleChanged: {
		if (visible && sourceValid && !userPaused) mediaPlayer.play()
		else if (!visible) mediaPlayer.pause()
	}
	onExpandedChanged: {
		chromeHideTimer.stop()
		chromeRevealed = expanded
		if (expanded && !panelHover.hovered) chromeHideTimer.restart()
	}
	onDraggingChanged: {
		if (dragging) revealChrome()
		else scheduleChromeHide()
	}
	onResizingChanged: {
		if (resizing) revealChrome()
		else scheduleChromeHide()
	}

	HoverHandler {
		id: panelHover

		onHoveredChanged: {
			if (hovered) root.revealChrome()
			else root.scheduleChromeHide()
		}
	}

	Connections {
		target: LayoutState

		function onVideoSourceChanged() {
			if (LayoutState.videoSource
					&& LayoutState.videoSource !== root.acceptedSource
					&& LayoutState.videoSource !== root.requestedSource) {
				root.loadSource(LayoutState.videoSource, false)
			}
		}
	}

	Keys.priority: Keys.BeforeItem
	Keys.onEscapePressed: event => {
		if (!root.expanded) return

		root.setExpanded(false)
		event.accepted = true
	}

	onAvailableWidthChanged: if (!geometryInitialized) geometryTimer.restart()
	onAvailableHeightChanged: if (!geometryInitialized) geometryTimer.restart()
	Component.onCompleted: {
		geometryTimer.restart()
		if (LayoutState.videoSource) loadSource(LayoutState.videoSource, false)
	}
	Component.onDestruction: {
		validationTimer.stop()
		rejectionTimer.stop()
		fallbackTimer.stop()
		mediaPlayer.videoOutput = null
		mediaPlayer.audioOutput = null
		mediaPlayer.stop()
		mediaPlayer.source = ""
	}

	Timer {
		id: geometryTimer
		interval: 0
		onTriggered: root.restoreMinimalGeometry()
	}

	Timer {
		id: focusTimer
		interval: 0
		onTriggered: if (root.expanded) root.forceActiveFocus()
	}

	Timer {
		id: validationTimer
		interval: 250
		onTriggered: root.validateSource(true)
	}

	Timer {
		id: rejectionTimer
		property string rejectionMessage: ""
		property string fallbackSource: ""
		interval: 0
		onTriggered: root.finishRejection(rejectionMessage, fallbackSource)
	}

	Timer {
		id: fallbackTimer
		property string fallbackSource: ""
		interval: 0
		onTriggered: root.loadSource(fallbackSource, true)
	}

	Timer {
		id: messageTimer
		interval: 5000
		onTriggered: root.validationMessage = ""
	}

	Timer {
		id: chromeHideTimer
		interval: 3000
		onTriggered: root.chromeRevealed = false
	}

	ParallelAnimation {
		id: modeTransition

		NumberAnimation {
			target: root
			property: "x"
			to: root.transitionX
			duration: Theme.modalOpenDuration
			easing.type: Easing.OutCubic
		}

		NumberAnimation {
			target: root
			property: "y"
			to: root.transitionY
			duration: Theme.modalOpenDuration
			easing.type: Easing.OutCubic
		}

		NumberAnimation {
			target: root
			property: "width"
			to: root.transitionWidth
			duration: Theme.modalOpenDuration
			easing.type: Easing.OutCubic
		}

		NumberAnimation {
			target: root
			property: "height"
			to: root.transitionHeight
			duration: Theme.modalOpenDuration
			easing.type: Easing.OutCubic
		}

		onFinished: root.storeGeometry()
	}

	FileDialog {
		id: videoPicker
		title: "Choose a wallpaper preview"
		fileMode: FileDialog.OpenFile
		nameFilters: [
			"Video files (*.mp4 *.m4v *.mov *.webm *.mkv)",
			"All files (*)"
		]
		onAccepted: root.loadSource(selectedFile, false)
	}

	AudioOutput {
		id: previewAudio
		muted: root.muted
	}

	MediaPlayer {
		id: mediaPlayer
		videoOutput: videoOutput
		audioOutput: previewAudio
		loops: MediaPlayer.Infinite

		onDurationChanged: root.validateSource(false)
		onHasVideoChanged: root.validateSource(false)
		onMediaStatusChanged: {
			if (mediaStatus === MediaPlayer.LoadedMedia
					|| mediaStatus === MediaPlayer.BufferedMedia) {
				validationTimer.restart()
			} else if (mediaStatus === MediaPlayer.InvalidMedia) {
				root.validateSource(true)
			}
		}
		onErrorOccurred: (error, errorString) => {
			if (error !== MediaPlayer.NoError) {
				root.rejectSource(errorString || "Unable to open this video")
			}
		}
	}

	Item {
		id: content
		anchors.fill: parent

		ClippingRectangle {
			id: videoFrame
			anchors.fill: parent
			radius: root.radius
			color: Theme.background

			VideoOutput {
				id: videoOutput
				anchors.fill: parent
				visible: root.sourceValid
				fillMode: VideoOutput.PreserveAspectCrop
			}

			MouseArea {
				z: 0
				anchors.fill: parent
				enabled: root.expanded && root.sourceValid
				cursorShape: Qt.PointingHandCursor
				onClicked: {
					root.activated()
					root.togglePlayback()
				}
			}

			Column {
				z: 1
				anchors.centerIn: parent
				width: Math.min(parent.width - Theme.spacingLg * 2, 320)
				spacing: Theme.spacingSm
				visible: !root.sourceValid

				Text {
					anchors.horizontalCenter: parent.horizontalCenter
					text: root.loading ? "󰑓" : "󰕧"
					color: Theme.accent
					font.family: Theme.fontFamily
					font.pixelSize: root.expanded ? 36 : 28
				}

				Text {
					width: parent.width
					text: root.loading ? "Checking video…"
						: (root.validationMessage || "Choose a video up to 30 seconds")
					color: root.validationMessage ? Theme.warning : Theme.textMuted
					horizontalAlignment: Text.AlignHCenter
					wrapMode: Text.WordWrap
					font.family: Theme.textFontFamily
					font.pixelSize: root.expanded ? 13 : 11
				}
			}

			Rectangle {
				z: 2
				anchors.left: parent.left
				anchors.right: parent.right
				anchors.top: parent.top
				height: root.headerHeight
				color: Theme.surface
				opacity: root.expanded && root.chromeRevealed ? 1 : 0
				visible: root.expanded && opacity > 0

				Behavior on opacity {
					NumberAnimation {
						duration: Theme.motionDuration
						easing.type: Easing.OutCubic
					}
				}
			}

			Rectangle {
				id: controls
				z: 2
				anchors.left: parent.left
				anchors.right: parent.right
				anchors.bottom: parent.bottom
				height: 104
				color: Theme.surface
				opacity: root.expanded && root.chromeRevealed ? 1 : 0
				visible: root.expanded && opacity > 0
				enabled: root.chromeRevealed

				Behavior on opacity {
					NumberAnimation {
						duration: Theme.motionDuration
						easing.type: Easing.OutCubic
					}
				}

				MouseArea {
					anchors.fill: parent
					onPressed: root.activated()
				}

				ActionButton {
					id: chooseButton
					anchors.left: parent.left
					anchors.leftMargin: Theme.spacingMd
					anchors.top: parent.top
					anchors.topMargin: Theme.spacingSm
					icon: "󰉋"
					text: root.acceptedSource ? "Change" : "Choose video"
					onClicked: {
						root.activated()
						videoPicker.open()
					}
				}

				ActionButton {
					id: muteButton
					anchors.right: parent.right
					anchors.rightMargin: Theme.spacingMd
					anchors.verticalCenter: chooseButton.verticalCenter
					compact: true
					icon: root.muted ? "󰖁" : "󰕾"
					active: !root.muted
					onClicked: {
						root.activated()
						root.muted = !root.muted
					}
				}

				ActionButton {
					id: playbackButton
					anchors.right: muteButton.left
					anchors.rightMargin: Theme.spacingXs
					anchors.verticalCenter: chooseButton.verticalCenter
					compact: true
					icon: root.playing ? "󰏤" : "󰐊"
					active: root.playing
					enabled: root.sourceValid
					onClicked: {
						root.activated()
						root.togglePlayback()
					}
				}

				Text {
					anchors.left: chooseButton.right
					anchors.leftMargin: Theme.spacingMd
					anchors.right: playbackButton.left
					anchors.rightMargin: Theme.spacingSm
					anchors.verticalCenter: chooseButton.verticalCenter
					text: root.validationMessage || root.sourceName(root.acceptedSource)
					color: root.validationMessage ? Theme.warning : Theme.textMuted
					font.family: Theme.textFontFamily
					font.pixelSize: 11
					elide: Text.ElideMiddle
				}

				Rectangle {
					id: progressTrack
					anchors.left: parent.left
					anchors.leftMargin: Theme.spacingMd
					anchors.right: parent.right
					anchors.rightMargin: Theme.spacingMd
					anchors.bottom: elapsedLabel.top
					anchors.bottomMargin: Theme.spacingXs
					height: 4
					radius: height / 2
					color: Theme.surfaceSoft

					Rectangle {
						width: mediaPlayer.duration > 0
							? parent.width * Math.min(1,
								mediaPlayer.position / mediaPlayer.duration) : 0
						height: parent.height
						radius: parent.radius
						color: Theme.accent
					}

					MouseArea {
						anchors.fill: parent
						anchors.topMargin: -Theme.spacingSm
						anchors.bottomMargin: -Theme.spacingSm
						enabled: root.sourceValid && mediaPlayer.seekable
						cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
						onClicked: mouse => {
							root.activated()
							mediaPlayer.position = mediaPlayer.duration
								* Math.max(0, Math.min(1, mouse.x / width))
						}
					}
				}

				Text {
					id: elapsedLabel
					anchors.left: progressTrack.left
					anchors.bottom: parent.bottom
					anchors.bottomMargin: Theme.spacingSm
					text: root.formatDuration(mediaPlayer.position)
					color: Theme.textMuted
					font.family: Theme.textFontFamily
					font.pixelSize: 10
				}

				Text {
					anchors.right: progressTrack.right
					anchors.bottom: parent.bottom
					anchors.bottomMargin: Theme.spacingSm
					text: root.formatDuration(mediaPlayer.duration)
					color: Theme.textMuted
					font.family: Theme.textFontFamily
					font.pixelSize: 10
				}
			}
		}
	}
}
