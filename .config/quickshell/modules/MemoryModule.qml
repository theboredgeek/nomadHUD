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
        bottom: 40 // Anchor point for the rest of the stack
        right: 20
    }
    
    anchors { bottom: true; right: true }
    
    implicitWidth: 300
    implicitHeight: 80 
    color: "transparent"

    Rectangle {
        id: memBox
        width: 280; height: 75
        anchors.right: parent.right
        anchors.rightMargin: 10
        anchors.bottom: parent.bottom
        
        color: Theme.glass
        border.width: Theme.borderWidth
        radius: Theme.cornerRadius
        
        readonly property color statusColor: Theme.getLoadColor(root ? root.memLoad : 0)
        border.color: statusColor
        
        Column {
            anchors.centerIn: parent
            spacing: 8
            
            // Stats Label
            Text { 
                text: "SYSTEM_MEM // " + (root ? root.memUsedGB : "0.0") + "GB / " + (root ? root.memTotalGB : "0.0") + "GB"
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeSmall
                font.letterSpacing: Theme.fontLetterSpacing
                color: memBox.statusColor 
                opacity: Theme.inactiveOpacity
            }
            
            // Progress Bar Container
            Rectangle {
                width: 250; height: Theme.barHeight
                color: Theme.glassLight
                border.color: Theme.panelBorder
                border.width: 1
                
                // Actual usage fill (Anchored Right to match GPU alignment)
                Rectangle {
                    id: barFill
                    height: parent.height
                    anchors.right: parent.right
                    width: root ? parent.width * (Math.min(100, parseInt(root.memLoad)) / 100) : 0
                    color: memBox.statusColor
                    
                    Behavior on width { 
                        NumberAnimation { 
                            duration: 1500; 
                            easing.type: Easing.OutQuint 
                        } 
                    }

                    // Optional: Visual segments to look like memory modules
                    Repeater {
                        model: 5
                        Rectangle {
                            x: (parent.width / 5) * index
                            width: 1; height: parent.height
                            color: Theme.bgDark
                            opacity: 0.3
                        }
                    }
                }
            }

            // Load Percentage
            Text {
                width: 250
                horizontalAlignment: Text.AlignRight
                text: "LOAD_FACTOR: " + (root ? root.memLoad : "00") + "%"
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeTiny
                color: memBox.statusColor
                opacity: 0.6
            }
        }
    }
}