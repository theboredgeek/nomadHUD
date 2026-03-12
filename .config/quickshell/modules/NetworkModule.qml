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
    
    implicitWidth: 360
    implicitHeight: 180
    color: "transparent"

    readonly property bool isDisconnected: !root || 
                                           root.activeIface === "..." || 
                                           root.activeIface === "" || 
                                           root.activeIface === "OFFLINE"

    readonly property color statusColor: isDisconnected ? Theme.alert : Theme.amber

    Item {
        anchors { fill: parent; margins: 40 }
        
        // --- EMERGENCY PULSE ---
        Rectangle {
            anchors.fill: parent
            color: Theme.alert
            opacity: 0
            visible: isDisconnected
            
            SequentialAnimation on opacity {
                running: isDisconnected; loops: Animation.Infinite
                NumberAnimation { to: 0.15; duration: 800; easing.type: Easing.InOutQuad }
                NumberAnimation { to: 0; duration: 800; easing.type: Easing.InOutQuad }
            }
        }

        // --- DECORATIVE BRACKETS ---
        Rectangle { 
            width: Theme.borderWidth + 1; height: 100 
            color: statusColor 
            anchors { left: parent.left; bottom: parent.bottom } 
        }
        Rectangle { 
            width: 100; height: Theme.borderWidth + 1 
            color: statusColor 
            anchors { left: parent.left; bottom: parent.bottom } 
        }
        
        Column {
            anchors { left: parent.left; bottom: parent.bottom; margins: 15 }
            spacing: 8
            
            // --- HEADER: Status ---
            Text { 
                text: isDisconnected ? "LINK_STATUS // SIGNAL_LOST" : "LINK_ESTABLISHED // " + root.activeIface.toUpperCase()
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeSmall
                color: statusColor
                opacity: isDisconnected ? 1.0 : Theme.inactiveOpacity 
            }
            
            Column {
                spacing: 4
                
                // Downlink (RX)
                Row {
                    spacing: 12
                    Text { 
                        text: "RX >"
                        font.family: Theme.fontFamily; font.pixelSize: Theme.fontSizeLarge
                        color: statusColor
                        width: 45 
                    }
                    Text { 
                        text: (isDisconnected ? "0.0" : root.netDown) + " KB/s"
                        font.family: Theme.fontFamily; font.pixelSize: Theme.fontSizeLarge
                        color: statusColor; font.bold: true 
                    }
                }
                
                // Uplink (TX)
                Row {
                    spacing: 12
                    Text { 
                        text: "TX >"
                        font.family: Theme.fontFamily; font.pixelSize: Theme.fontSizeMed
                        color: statusColor
                        width: 45; opacity: 0.7 
                    }
                    Text { 
                        text: (isDisconnected ? "0.0" : root.netUp) + " KB/s"
                        font.family: Theme.fontFamily; font.pixelSize: Theme.fontSizeMed
                        color: statusColor; opacity: 0.7 
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
                    width: isDisconnected ? 0 : Math.min(parent.width, (parseFloat(root.netDown) / 1000) * parent.width)
                    color: statusColor
                    opacity: 0.6
                    
                    SequentialAnimation on opacity {
                        running: !isDisconnected && parseFloat(root.netDown) > 0.1
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