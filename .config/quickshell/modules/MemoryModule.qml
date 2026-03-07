import QtQuick
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: memWindow
    required property var targetScreen
    required property var root // Marks this as mandatory

    screen: targetScreen
    WlrLayershell.layer: WlrLayershell.Bottom
    anchors { bottom: true; right: true }
    implicitWidth: 500; implicitHeight: 140; color: "transparent"

    Rectangle {
        id: memBox
        width: 380; height: 80
        anchors.centerIn: parent
        // Use a null check: if root exists, use glass, else use black
        color: root ? root.glass : "black" 
        border.width: 1
        
        // Null check for the function call
        property color alertColor: root ? root.getAlertColor(root.memLoad) : "grey"
        border.color: alertColor
        
        Column {
            anchors.centerIn: parent
            spacing: 10
            
            Text { 
                // Null check for the strings
                text: "MEM_POOL // " + (root ? root.memUsedGB : "0") + "GB / " + (root ? root.memTotalGB : "0") + "GB"
                font.family: "Monospace"; font.pixelSize: 12
                color: memBox.alertColor 
            }
            
            Rectangle {
                width: 300; height: 6
                color: Qt.rgba(memBox.alertColor.r, memBox.alertColor.g, memBox.alertColor.b, 0.15)
                
                Rectangle {
                    height: parent.height
                    // Null check for the math
                    width: root ? parent.width * (Math.min(100, parseInt(root.memLoad)) / 100) : 0
                    color: memBox.alertColor
                    Behavior on width { NumberAnimation { duration: 1500; easing.type: Easing.OutElastic } }
                }
            }
        }
    }
}