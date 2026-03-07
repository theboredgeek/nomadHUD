import QtQuick
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: netWindow
    required property var targetScreen
    required property var root

    screen: targetScreen
    WlrLayershell.layer: WlrLayershell.Bottom
    anchors { bottom: true; left: true }
    implicitWidth: 450; implicitHeight: 220; color: "transparent"

    Item {
        anchors { fill: parent; margins: 40 }
        
        // --- DECORATIVE BRACKETS ---
        // Safeguard color access with root ? root.amber : "transparent"
        Rectangle { 
            width: 2; height: 100; 
            color: root ? root.amber : "transparent"; 
            anchors { left: parent.left; bottom: parent.bottom } 
        }
        Rectangle { 
            width: 100; height: 2; 
            color: root ? root.amber : "transparent"; 
            anchors { left: parent.left; bottom: parent.bottom } 
        }
        
        Column {
            anchors { left: parent.left; bottom: parent.bottom; margins: 15 }
            spacing: 8
            
            Text { 
                text: "LINK: " + (root ? root.activeIface.toUpperCase() : "SEARCHING...")
                font.family: "Monospace"; font.pixelSize: 10
                color: root ? root.amber : "grey"; opacity: 0.5 
            }
            
            Column {
                spacing: 2
                Row {
                    spacing: 10
                    Text { text: "RX >"; font.family: "Monospace"; font.pixelSize: 16; color: root ? root.amber : "grey"; width: 40 }
                    Text { 
                        text: (root ? root.netDown : "0.0") + " KB/s"
                        font.family: "Monospace"; font.pixelSize: 16; color: root ? root.amber : "grey"; font.bold: true 
                    }
                }
                Row {
                    spacing: 10
                    Text { text: "TX >"; font.family: "Monospace"; font.pixelSize: 12; color: root ? root.amber : "grey"; width: 40; opacity: 0.7 }
                    Text { 
                        text: (root ? root.netUp : "0.0") + " KB/s"
                        font.family: "Monospace"; font.pixelSize: 12; color: root ? root.amber : "grey"; opacity: 0.7 
                    }
                }
            }
            
            // --- ACTIVITY BAR ---
            Rectangle {
                width: 120; height: 2; color: root ? Qt.rgba(root.amber.r, root.amber.g, root.amber.b, 0.1) : "transparent"
                Rectangle {
                    height: parent.height
                    // Safeguard parseFloat and math logic
                    width: root ? Math.min(parent.width, parseFloat(root.netDown) / 10) : 0
                    color: root ? root.amber : "transparent"
                    
                    // Simple flicker effect logic
                    opacity: root ? (0.4 + (Math.random() * 0.6)) : 0
                    
                    Behavior on width { NumberAnimation { duration: 500 } }
                }
            }
        }
    }
}