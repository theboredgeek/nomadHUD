import QtQuick
import Quickshell
import Quickshell.Wayland

ShellRoot {
    id: root
    
    readonly property color amber: "#E1B12C"
    readonly property color glass: "#E6000000"
    
    property real u_time: 0.0
    Timer { 
        interval: 16; running: true; repeat: true; 
        onTriggered: root.u_time += 0.01 
    }

    // --- 1. THE CENTRAL MATRIX ---
    PanelWindow {
        WlrLayershell.layer: WlrLayershell.Bottom
        WlrLayershell.exclusiveZone: 0
        
        // Correct way to fill the screen
        anchors { 
            top: true; bottom: true; left: true; right: true 
        }
        color: "transparent"

        Rectangle {
            width: Math.floor(screen.width * 0.6)
            height: Math.floor(screen.height * 0.5)
            anchors.centerIn: parent
            color: root.glass
            border.color: root.amber
            border.width: 1
            opacity: 0.2

            ShaderEffect {
                anchors.fill: parent; anchors.margins: 2
                property real u_time: root.u_time
                property real u_width: width
                property real u_height: height
                fragmentShader: "shaders/hexgrid.qsb"
            }
        }
    }

    // --- 2. TOP-LEFT DIAGNOSTIC ---
    PanelWindow {
        WlrLayershell.layer: WlrLayershell.Bottom
        anchors { top: true; left: true }
        width: 400; height: 150
        color: "transparent"

        Item {
            anchors.fill: parent
            anchors.margins: 40

            // The "L" Bracket
            Rectangle { 
                width: 2; height: 60; color: root.amber
                anchors.left: parent.left; anchors.top: parent.top
            }
            Rectangle { 
                width: 60; height: 2; color: root.amber
                anchors.left: parent.left; anchors.top: parent.top
            }

            Text {
                text: "NOMAD_OS // UNDERLAY_ACTIVE"
                font.family: "Monospace"; font.pixelSize: 14
                color: root.amber
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.leftMargin: 15
                anchors.topMargin: 15
            }
        }
    }

    // --- 3. BOTTOM-RIGHT STATUS ---
    PanelWindow {
        WlrLayershell.layer: WlrLayershell.Bottom
        anchors { bottom: true; right: true }
        width: 400; height: 100
        color: "transparent"

        Rectangle {
            width: 300; height: 40
            anchors.centerIn: parent
            color: root.glass
            border.color: root.amber
            border.width: 1
            
            Text {
                anchors.centerIn: parent
                text: "NODE // " + screen.name.toUpperCase()
                font.family: "Monospace"; font.bold: true
                font.pixelSize: 12; color: root.amber
            }
        }
    }
}