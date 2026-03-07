import QtQuick
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: cpuWindow
    required property var targetScreen
    required property var root

    screen: targetScreen
    WlrLayershell.layer: WlrLayershell.Bottom
    anchors { top: true; left: true }
    implicitWidth: 450; implicitHeight: 180; color: "transparent"

    Item {
        id: cpuBox
        anchors { fill: parent; margins: 40 }
        
        // Safeguard the function call
        readonly property color alertColor: root ? root.getAlertColor(root.cpuLoad) : "#888888"

        // --- DECORATIVE CORNER ---
        Rectangle { width: 2; height: 80; color: cpuBox.alertColor; anchors { left: parent.left; top: parent.top } }
        Rectangle { width: 80; height: 2; color: cpuBox.alertColor; anchors { left: parent.left; top: parent.top } }
        
        Column {
            x: 15; y: 15; spacing: 6
            
            Text { 
                // Safeguard parseInt and string concatenation
                text: root ? (parseInt(root.cpuLoad) >= 90 ? "!! CPU_CRITICAL_LOAD !!" : "NOMAD_OS // CPU_LOAD: " + root.cpuLoad + "%") : "INITIALIZING..."
                font.family: "Monospace"; font.pixelSize: 14; color: cpuBox.alertColor 
            }
            
            // --- LOAD BAR ---
            Rectangle {
                width: 200; height: 4; 
                color: Qt.rgba(cpuBox.alertColor.r, cpuBox.alertColor.g, cpuBox.alertColor.b, 0.15)
                
                Rectangle {
                    height: parent.height
                    // Safeguard math logic
                    width: root ? parent.width * (Math.min(100, parseInt(root.cpuLoad)) / 100) : 0
                    color: cpuBox.alertColor
                    
                    Behavior on width { NumberAnimation { duration: 800; easing.type: Easing.OutQuint } }
                }
            }
        }
    }
}