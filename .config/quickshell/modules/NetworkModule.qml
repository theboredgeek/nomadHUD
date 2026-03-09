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
    
    implicitWidth: 450
    implicitHeight: 220
    color: "transparent"

    Item {
        anchors { fill: parent; margins: 40 }
        
        // --- DECORATIVE BRACKETS ---
        // Using Theme.amber and Theme.borderWidth
        Rectangle { 
            width: Theme.borderWidth + 1; height: 100 
            color: Theme.amber 
            anchors { left: parent.left; bottom: parent.bottom } 
        }
        Rectangle { 
            width: 100; height: Theme.borderWidth + 1 
            color: Theme.amber 
            anchors { left: parent.left; bottom: parent.bottom } 
        }
        
        Column {
            anchors { left: parent.left; bottom: parent.bottom; margins: 15 }
            spacing: 8
            
            Text { 
                text: "LINK_ESTABLISHED: " + (root ? root.activeIface.toUpperCase() : "SEARCHING...")
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.amber
                opacity: Theme.inactiveOpacity 
            }
            
            Column {
                spacing: 4
                
                // Downlink (RX)
                Row {
                    spacing: 12
                    Text { 
                        text: "RX >"
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeLarge
                        color: Theme.amber
                        width: 45 
                    }
                    Text { 
                        text: (root ? root.netDown : "0.0") + " KB/s"
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeLarge
                        color: Theme.amber
                        font.bold: true 
                    }
                }
                
                // Uplink (TX)
                Row {
                    spacing: 12
                    Text { 
                        text: "TX >"
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeMed
                        color: Theme.amber
                        width: 45
                        opacity: 0.7 
                    }
                    Text { 
                        text: (root ? root.netUp : "0.0") + " KB/s"
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeMed
                        color: Theme.amber
                        opacity: 0.7 
                    }
                }
            }
            
            // --- DYNAMIC ACTIVITY BAR ---
            Rectangle {
                width: 150; height: 2
                color: Theme.glassLight
                
                Rectangle {
                    id: activityFill
                    height: parent.height
                    // Scale width based on activity (capped at 1000 KB/s for scaling)
                    width: root ? Math.min(parent.width, (parseFloat(root.netDown) / 1000) * parent.width) : 0
                    color: Theme.amber
                    
                    // The Flicker Effect
                    opacity: 0.6
                    SequentialAnimation on opacity {
                        running: parseFloat(root ? root.netDown : 0) > 0.1
                        loops: Animation.Infinite
                        NumberAnimation { to: 1.0; duration: 50 }
                        NumberAnimation { to: 0.6; duration: 150 }
                        PauseAnimation { duration: 50 }
                    }
                    
                    Behavior on width { 
                        NumberAnimation { duration: Theme.animSpeed; easing.type: Theme.defaultEasing } 
                    }
                }
            }
        }
    }
}