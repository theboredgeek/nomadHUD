import QtQuick
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: clockWindow
    required property var targetScreen
    required property var root

    screen: targetScreen
    WlrLayershell.layer: WlrLayershell.Bottom
    anchors { top: true; right: true }
    
    implicitWidth: 300
    implicitHeight: 350
    color: "transparent"

    Item {
        id: clockContainer // Give this an ID
        anchors.fill: parent
        readonly property color theme: root ? root.amber : "#888888"

        Column {
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
                color: clockContainer.theme // Direct ID reference
            }

            Text {
                text: "// SYSTEM_SYNC_ACTIVE // " + Qt.formatDateTime(new Date(), "yyyy.MM.dd")
                font.family: "Monospace"; font.pixelSize: 10
                color: clockContainer.theme; opacity: 0.6
            }

            Rectangle {
                width: 180; height: 1; color: clockContainer.theme
                Rectangle {
                    width: 20; height: 3; color: clockContainer.theme // This line was causing the warning
                    x: (parent.width - 20) * (Math.sin(root ? root.u_time * 2 : 0) + 1) / 2
                }
            }
        }
    }
}