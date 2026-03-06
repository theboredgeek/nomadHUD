import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland

ShellRoot {
    // TRACKING LOGIC
    // We filter the global toplevels to only count those on the active workspace
    readonly property int activeWindowCount: Hyprland.toplevels.values.filter(
        w => w.workspace === Hyprland.focusedWorkspace
    ).length

    // NEW TRIGGER: HUD stays open for 0 or 1 window. Collapses for 2+.
    readonly property bool isMultiTasking: activeWindowCount >= 2

    VariantsWindow {
        name: "dxmd-logic-module"
        WlrLayershell.layer: WlrLayershell.Overlay
        
        // DIMENSIONS
        width: isMultiTasking ? 250 : 500
        height: isMultiTasking ? 60 : 350

        // POSITIONING
        // Collapses to Top-Right if 2+ windows; stays Large/Centered for 0-1
        x: isMultiTasking ? (screen.width - width - 20) : (screen.width / 2 - width / 2)
        y: isMultiTasking ? 20 : (screen.height / 2 - height / 2)

        // DXMD SNAP ANIMATIONS (Matching your 0.6s easing note)
        Behavior on x { NumberAnimation { duration: 600; easing.type: Easing.OutQuint } }
        Behavior on y { NumberAnimation { duration: 600; easing.type: Easing.OutQuint } }
        Behavior on width { NumberAnimation { duration: 600; easing.type: Easing.OutQuint } }
        Behavior on height { NumberAnimation { duration: 600; easing.type: Easing.OutQuint } }

        Rectangle {
            anchors.fill: parent
            color: "#CC000000"
            border.color: "#E1B12C"
            border.width: 2

            Column {
                anchors.centerIn: parent
                spacing: 5
                Text { 
                    text: isMultiTasking ? "STATUS: BAR (TILING)" : "STATUS: HUD (AUGMENTED)" 
                    color: "#E1B12C"
                    font.bold: true
                }
                Text { 
                    text: "Active Workspace Windows: " + activeWindowCount
                    color: "white"
                    font.pixelSize: 10
                }
            }
        }
    }
}
