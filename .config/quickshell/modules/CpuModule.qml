import QtQuick
import Quickshell
import Quickshell.Wayland

PanelWindow {
    required property var targetScreen
    required property var root

    screen: targetScreen
    WlrLayershell.layer: WlrLayershell.Bottom
    anchors { top: true; left: true }
    implicitWidth: 450; implicitHeight: 180; color: "transparent"

    Item {
        id: cpuBox
        anchors { fill: parent; margins: 40 }
        readonly property color alertColor: root.getAlertColor(root.cpuLoad)

        Rectangle { width: 2; height: 80; color: cpuBox.alertColor; anchors { left: parent.left; top: parent.top } }
        Rectangle { width: 80; height: 2; color: cpuBox.alertColor; anchors { left: parent.left; top: parent.top } }
        
        Column {
            x: 15; y: 15; spacing: 6
            Text { 
                text: (parseInt(root.cpuLoad) >= 90 ? "!! CPU_CRITICAL_LOAD !!" : "NOMAD_OS // CPU_LOAD: " + root.cpuLoad + "%")
                font.family: "Monospace"; font.pixelSize: 14; color: cpuBox.alertColor 
            }
            Rectangle {
                width: 200; height: 4; color: Qt.rgba(cpuBox.alertColor.r, cpuBox.alertColor.g, cpuBox.alertColor.b, 0.15)
                Rectangle {
                    height: parent.height; width: parent.width * (Math.min(100, parseInt(root.cpuLoad)) / 100)
                    color: cpuBox.alertColor
                    Behavior on width { NumberAnimation { duration: 800; easing.type: Easing.OutQuint } }
                }
            }
        }
    }
}