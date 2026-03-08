import QtQuick
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: gpuWindow
    required property var targetScreen
    required property var root

    screen: targetScreen
    WlrLayershell.layer: WlrLayershell.Bottom
    anchors { top: true; right: true }
    implicitWidth: 450; implicitHeight: 200; color: "transparent"

    Item {
        id: gpuContainer
        anchors { fill: parent; margins: 50 }
        
        Column {
            anchors.right: parent.right
            spacing: 100

            Repeater {
                model: root ? root.gpuData : [] 
                delegate: Column {
                    anchors.right: parent.right
                    spacing: 4
                    
                    property var gpuInfo: modelData.split('|')
                    property string vendor: gpuInfo[0] || "UNK"
                    property string load: gpuInfo[1] || "0"
                    
                    // Safety check for alert color logic
                    readonly property color gpuColor: root ? root.getAlertColor(load) : "#888888"

                    Row {
                        layoutDirection: Qt.RightToLeft
                        spacing: 10
                        Text { 
                            text: "GPU_" + index + " [" + vendor + "]"
                            font.family: "Monospace"; font.pixelSize: 12; color: gpuColor 
                        }
                        Text { 
                            text: load + "%"
                            font.family: "Monospace"; font.pixelSize: 12; color: gpuColor; font.bold: true 
                        }
                    }

                    // --- LOAD BAR ---
                    Rectangle {
                        width: 200; height: 4
                        color: Qt.rgba(gpuColor.r, gpuColor.g, gpuColor.b, 0.15)
                        anchors.right: parent.right
                        
                        Rectangle {
                            anchors.right: parent.right
                            height: parent.height
                            
                            // Agnostic Width: Shows at least 2px pulse if the card is detected but load is 0
                            width: Math.max(2, parent.width * (Math.min(100, parseInt(load || 0)) / 100))
                            color: gpuColor
                            
                            // Visual Pulse: If load is 0, pulse the opacity to show the "Link" is alive
                            opacity: (parseInt(load) === 0) ? (0.3 + Math.abs(Math.sin(root ? root.u_time * 2 : 0)) * 0.4) : 1.0
                            
                            Behavior on width { NumberAnimation { duration: 800; easing.type: Easing.OutQuint } }
                        }
                    }
                }
            }
        }
    }
}