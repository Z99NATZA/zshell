//@ pragma ShellId zshell
//@ pragma AppId dev.zshell
//@ pragma StateDir $BASE/zshell
//@ pragma DropExpensiveFonts

import Quickshell
import qs.components

ShellRoot {
	Variants {
		model: Quickshell.screens

		DesktopSurface {
			required property var modelData
			screen: modelData
		}
	}

	Variants {
		model: Quickshell.screens

		Dock {
			required property var modelData
			screen: modelData
		}
	}

	Variants {
		model: Quickshell.screens

		QuickSettingsPanel {
			required property var modelData
			screen: modelData
		}
	}
}
