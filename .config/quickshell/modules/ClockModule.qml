import QtQuick
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: clockWindow
    required property var targetScreen
    required property var root

    screen: targetScreen
    WlrLayershell.layer: WlrLayershell.Bottom
    
    // Use boolean anchors for edges
    anchors { top: true; right: true }
    
    // Instead of topMargin, we define the height to include the "gap" 
    // or just rely on the internal Item to position itself.
    implicitWidth: 300
    implicitHeight: 350 // Increased to accommodate the vertical offset
    color: "transparent"

    Item {
        anchors.fill: parent
        readonly property color theme: root ? root.amber : "#888888"

        Column {
            // Position the clock 220px down from the top edge
            anchors.top: parent.top
            anchors.topMargin: 40 
            anchors.right: parent.right
            anchors.rightMargin: 40
            spacing: 2

            Text {
                text: {
                    let dummy = root ? root.u_time : 0; 
                    return Qt.formatDateTime(new Date(), "hh:mm:ss");
                }
                font.family: "Monospace"; font.pixelSize: 32; font.bold: true
                color: parent.parent.theme
            }

            Text {
                text: "// SYSTEM_SYNC_ACTIVE // " + Qt.formatDateTime(new Date(), "yyyy.MM.dd")
                font.family: "Monospace"; font.pixelSize: 10
                color: parent.parent.theme; opacity: 0.6
            }

            Rectangle {
                width: 180; height: 1; color: parent.parent.theme
                Rectangle {
                    width: 20; height: 3; color: parent.parent.theme
                    x: (parent.width - 20) * (Math.sin(root ? root.u_time * 2 : 0) + 1) / 2
                }
            }
        }
    }
}