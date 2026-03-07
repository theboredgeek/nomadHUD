import QtQuick
import Quickshell
import Quickshell.Wayland

PanelWindow {
    required property var targetScreen
    required property var root

    screen: targetScreen
    WlrLayershell.layer: WlrLayershell.Bottom
    anchors { bottom: true; left: true }
    implicitWidth: 450; implicitHeight: 220; color: "transparent"

    Item {
        anchors { fill: parent; margins: 40 }
        Rectangle { width: 2; height: 100; color: root.amber; anchors { left: parent.left; bottom: parent.bottom } }
        Rectangle { width: 100; height: 2; color: root.amber; anchors { left: parent.left; bottom: parent.bottom } }
        
        Column {
            anchors { left: parent.left; bottom: parent.bottom; margins: 15 }
            spacing: 8
            Text { text: "LINK: " + root.activeIface.toUpperCase(); font.family: "Monospace"; font.pixelSize: 10; color: root.amber; opacity: 0.5 }
            Column {
                spacing: 2
                Row {
                    spacing: 10
                    Text { text: "RX >"; font.family: "Monospace"; font.pixelSize: 16; color: root.amber; width: 40 }
                    Text { text: root.netDown + " KB/s"; font.family: "Monospace"; font.pixelSize: 16; color: root.amber; font.bold: true }
                }
                Row {
                    spacing: 10
                    Text { text: "TX >"; font.family: "Monospace"; font.pixelSize: 12; color: root.amber; width: 40; opacity: 0.7 }
                    Text { text: root.netUp + " KB/s"; font.family: "Monospace"; font.pixelSize: 12; color: root.amber; opacity: 0.7 }
                }
            }
            Rectangle {
                width: 120; height: 2; color: "#11E1B12C"
                Rectangle {
                    height: parent.height; width: Math.min(parent.width, parseFloat(root.netDown) / 10)
                    color: root.amber
                    opacity: 0.4 + (Math.random() * 0.6)
                }
            }
        }
    }
}