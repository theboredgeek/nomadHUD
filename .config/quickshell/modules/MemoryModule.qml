import QtQuick
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: memWindow
    required property var targetScreen
    required property var root 

    screen: targetScreen
    WlrLayershell.layer: WlrLayershell.Bottom
    
    WlrLayershell.margins {
        bottom: 40 // Starting height from bottom of screen
        right: 20
    }
    
    anchors { bottom: true; right: true }
    
    implicitWidth: 300
    implicitHeight: 80 // Fixed height for reliable stacking math
    color: "transparent"

    Rectangle {
        id: memBox
        width: 280; height: 70
        anchors.right: parent.right
        anchors.rightMargin: 10
        anchors.bottom: parent.bottom // Snap to bottom of the window
        
        color: root ? root.glass : "black" 
        border.width: 1
        property color alertColor: root ? root.getAlertColor(root.memLoad) : "grey"
        border.color: alertColor
        
        Column {
            anchors.centerIn: parent
            spacing: 8
            
            Text { 
                text: "SYSTEM_MEM // " + (root ? root.memUsedGB : "0") + "GB / " + (root ? root.memTotalGB : "0") + "GB"
                font.family: "Monospace"; font.pixelSize: 11
                color: memBox.alertColor 
                opacity: 0.8
            }
            
            Rectangle {
                width: 250; height: 4
                color: Qt.rgba(memBox.alertColor.r, memBox.alertColor.g, memBox.alertColor.b, 0.1)
                
                Rectangle {
                    height: parent.height
                    anchors.right: parent.right
                    width: root ? parent.width * (Math.min(100, parseInt(root.memLoad)) / 100) : 0
                    color: memBox.alertColor
                    Behavior on width { NumberAnimation { duration: 1500; easing.type: Easing.OutQuint } }
                }
            }
        }
    }
}