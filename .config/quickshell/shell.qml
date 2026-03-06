import QtQuick
import Quickshell
import Quickshell.Wayland

ShellRoot {
    id: root
    
    // Logic: We will manually toggle this or use a simple file-read later.
    // For now, let's keep the functional UI visible.
    property bool isMultiTasking: false 

    PanelWindow {
        id: mainPanel
        WlrLayershell.namespace: "nomadHUD"
        WlrLayershell.layer: WlrLayershell.Overlay
        anchors { top: true; right: true }

        // The exact dimensions from your DXMD notes
        width: isMultiTasking ? 250 : 500
        height: isMultiTasking ? 60 : 350

        // Snappy 0.6s easing from your notes
        Behavior on width { NumberAnimation { duration: 600; easing.type: Easing.OutQuint } }
        Behavior on height { NumberAnimation { duration: 600; easing.type: Easing.OutQuint } }

        Rectangle {
            anchors.fill: parent
            color: "#CC000000" // DXMD Transparent Black
            border.color: "#E1B12C" // DXMD Gold
            border.width: 2

            Text {
                anchors.centerIn: parent
                text: isMultiTasking ? "BAR MODE" : "DXMD // AUGMENTED"
                color: "#E1B12C"
                font.bold: true
                font.pixelSize: isMultiTasking ? 14 : 24
            }
        }
    }
}
