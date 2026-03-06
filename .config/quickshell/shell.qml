import QtQuick
import Quickshell
import Quickshell.Wayland

ShellRoot {
    id: root

    // Simulation logic to get the HUD on screen and moving TODAY
    property int activeWindowCount: 0
    readonly property bool isMultiTasking: activeWindowCount >= 2

    // Temporary: Let's use a click-trigger to test the animations 
    // until we fix the system-level crash
    MouseArea {
        anchors.fill: parent
        onClicked: root.activeWindowCount = (root.activeWindowCount == 0 ? 2 : 0)
    }

    PanelWindow {
        WlrLayershell.layer: WlrLayershell.Overlay
        WlrLayershell.namespace: "nomadHUD"
        anchors { top: true; right: true }

        width: isMultiTasking ? 250 : 500
        height: isMultiTasking ? 60 : 350
        WlrLayershell.margins.top: isMultiTasking ? 20 : 250
        WlrLayershell.margins.right: isMultiTasking ? 20 : 350

        Behavior on width { NumberAnimation { duration: 600; easing.type: Easing.OutQuint } }
        Behavior on height { NumberAnimation { duration: 600; easing.type: Easing.OutQuint } }
        Behavior on WlrLayershell.margins.top { NumberAnimation { duration: 600; easing.type: Easing.OutQuint } }
        Behavior on WlrLayershell.margins.right { NumberAnimation { duration: 600; easing.type: Easing.OutQuint } }

        Rectangle {
            anchors.fill: parent
            color: "#CC000000"
            border.color: "#E1B12C"
            border.width: 2
            
            Column {
                anchors.centerIn: parent
                Text { 
                    text: isMultiTasking ? "BAR MODE" : "HUD MODE"
                    color: "#E1B12C"
                    font.bold: true
                }
                Text {
                    text: "CLICK SCREEN TO TOGGLE"
                    color: "white"
                    font.pixelSize: 10
                }
            }
        }
    }
}
