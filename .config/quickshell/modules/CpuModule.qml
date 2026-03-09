import QtQuick
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: cpuWindow
    required property var targetScreen
    required property var root

    screen: targetScreen
    WlrLayershell.layer: WlrLayershell.Bottom
    
    WlrLayershell.mask: Region { item: cpuBox }
    
    anchors { top: true; left: true }
    
    implicitWidth: 450
    implicitHeight: 260 // Increased to accommodate taller core bars
    color: "transparent"

    Item {
        id: cpuBox
        anchors { fill: parent; margins: 40 }
        
        readonly property color statusColor: Theme.getLoadColor(root ? root.cpuLoad : 0)

        // --- DECORATIVE CORNER FRAME ---
        Rectangle { width: 2; height: 80; color: cpuBox.statusColor; anchors { left: parent.left; top: parent.top } }
        Rectangle { width: 80; height: 2; color: cpuBox.statusColor; anchors { left: parent.left; top: parent.top } }
        
        Column {
            x: 15; y: 15; spacing: 15 
            
            // Header
            Text { 
                text: root ? (parseInt(root.cpuLoad) >= 90 ? "!! CPU_CRITICAL_LOAD !!" : "NOMAD_OS // CPU_TOTAL: " + root.cpuLoad + "%") : "INITIALIZING..."
                font.family: Theme.fontFamily; font.pixelSize: Theme.fontSizeMed; font.letterSpacing: Theme.fontLetterSpacing
                color: cpuBox.statusColor
                opacity: (parseInt(root ? root.cpuLoad : 0) > 80) ? (0.7 + Math.sin(root.u_time * 5) * 0.3) : 1.0
            }
            
            // Total Usage Bar - Reset to a more readable 260px
            Rectangle {
                width: 260; height: Theme.barHeight
                color: Theme.glassLight; border.color: Theme.panelBorder; border.width: 1
                
                Rectangle {
                    id: usageFill
                    height: parent.height
                    width: root ? parent.width * (Math.min(100, parseInt(root.cpuLoad || 0)) / 100) : 0
                    color: cpuBox.statusColor
                    Behavior on width { NumberAnimation { duration: 400; easing.type: Theme.defaultEasing } }
                }
            }

            // --- PER-CORE VISUALIZER ---
            // Scaled up for better visibility
            Flow {
                width: 320; spacing: 4 
                
                Repeater {
                    model: root ? root.cpuCores : 0
                    Rectangle {
                        width: 8; height: 30 // Much more substantial
                        color: Theme.glassLight
                        border.color: Theme.panelBorder; border.width: 1

                        Rectangle {
                            anchors.bottom: parent.bottom
                            width: parent.width
                            height: parent.height * (parseInt(modelData) / 100)
                            color: Theme.getLoadColor(modelData)
                            opacity: 0.8
                            Behavior on height { NumberAnimation { duration: 250; easing.type: Easing.OutQuad } }
                        }
                    }
                }
            }

            // Footer
            Text {
                text: "CORE_THREAD_MONITOR // " + (root ? root.cpuCores.length : 0) + "_THREADS_ACTIVE"
                font.family: Theme.fontFamily; font.pixelSize: Theme.fontSizeTiny
                color: cpuBox.statusColor; opacity: Theme.inactiveOpacity
            }
        }
    }
}