import QtQuick
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: cpuWindow
    required property var targetScreen
    required property var root

    screen: targetScreen
    WlrLayershell.layer: WlrLayershell.Bottom
    
    // Mask ensures clicks pass through the transparent areas
    WlrLayershell.mask: Region {
        item: cpuBox
    }
    
    anchors { 
        top: true 
        left: true 
    }
    
    implicitWidth: 450
    implicitHeight: 180
    color: "transparent"

    Item {
        id: cpuBox
        anchors { 
            fill: parent 
            margins: 40 
        }
        
        // --- DYNAMIC THEME BINDING ---
        // Automatically fetches Red/Yellow/Amber based on mainShell.cpuLoad
        readonly property color statusColor: Theme.getLoadColor(root ? root.cpuLoad : 0)

        // --- DECORATIVE CORNER FRAME ---
        Rectangle { 
            width: 2; height: 80; color: cpuBox.statusColor
            anchors { left: parent.left; top: parent.top } 
        }
        Rectangle { 
            width: 80; height: 2; color: cpuBox.statusColor
            anchors { left: parent.left; top: parent.top } 
        }
        
        Column {
            x: 15; y: 15; spacing: 8
            
            // Header Text
            Text { 
                text: root ? (parseInt(root.cpuLoad) >= 90 ? "!! CPU_CRITICAL_LOAD !!" : "NOMAD_OS // CPU_LOAD: " + root.cpuLoad + "%") : "INITIALIZING..."
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeMed
                font.letterSpacing: Theme.fontLetterSpacing
                color: cpuBox.statusColor
                
                // Subtle opacity pulse when load is high
                opacity: (parseInt(root ? root.cpuLoad : 0) > 80) ? 
                         (0.7 + Math.sin(root.u_time * 5) * 0.3) : 1.0
            }
            
            // Usage Bar Container
            Rectangle {
                width: 200; height: Theme.barHeight
                color: Theme.glassLight // Uses the theme's 30% black glass
                border.color: Theme.panelBorder
                border.width: 1
                
                // The actual progress fill
                Rectangle {
                    id: usageFill
                    height: parent.height
                    width: root ? parent.width * (Math.min(100, parseInt(root.cpuLoad || 0)) / 100) : 0
                    color: cpuBox.statusColor
                    
                    // Smooth transition when load jumps
                    Behavior on width { 
                        NumberAnimation { 
                            duration: Theme.animSpeed * 4 // 800ms
                            easing.type: Theme.defaultEasing 
                        } 
                    }
                }
            }

            // Small "Technical" Footer
            Text {
                text: "CORE_PROCESS_MONITOR_v2.6"
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeTiny
                color: cpuBox.statusColor
                opacity: Theme.inactiveOpacity
            }
        }
    }
}