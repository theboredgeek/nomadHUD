import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Io

PanelWindow {
    id: powerWindow
    required property var targetScreen
    required property var root

    screen: targetScreen
    WlrLayershell.layer: WlrLayershell.Bottom
    
    WlrLayershell.margins { bottom: 140; left: 40 }
    anchors { bottom: true; left: true }
    
    implicitWidth: 280
    implicitHeight: 120
    color: "transparent"

    // --- DYNAMIC THEMING ---
    readonly property int batVal: parseInt(root.batPercent)
    readonly property bool isLow: batVal < 15 && !root.isPlugged
    readonly property bool isCritical: batVal < 5 && !root.isPlugged
    readonly property color statusColor: isLow ? Theme.alert : Theme.amber

    // Pulse animation for critical battery
    Rectangle {
        anchors.fill: parent
        color: Theme.alert
        opacity: 0
        visible: isCritical
        
        SequentialAnimation on opacity {
            running: isCritical; loops: Animation.Infinite
            NumberAnimation { to: 0.15; duration: 800; easing.type: Easing.InOutQuad }
            NumberAnimation { to: 0; duration: 800; easing.type: Easing.InOutQuad }
        }
    }

    Process { id: executor }

    Item {
        id: container
        anchors.fill: parent

        Column {
            x: 5; y: 8 // Centered better
            spacing: 2
            
            Text {
                text: "SYS_ENERGY_FLUX // " + root.powerDrain + "W"
                font.family: Theme.fontFamily; font.pixelSize: Theme.fontSizeTiny
                color: statusColor; opacity: 0.8
            }

           Text {
                // Show the status or the lazy-updated time
                text: root.isPlugged ? "STATUS // AC_POWER_SYNC" : "EST_RUNTIME // " + root.batTime
                font.family: Theme.fontFamily; font.pixelSize: Theme.fontSizeSmall
                color: root.isPlugged ? Theme.circuitBlue : statusColor
                opacity: 0.6
            }
        }

        Row {
            x: 5; y: 38; spacing: 4
            Repeater {
                model: 10
                Rectangle {
                    width: 14; height: 24
                    color: (index * 10 < batVal) ? statusColor : Theme.glassLight
                    opacity: (root.isPlugged && (index * 10 >= batVal)) 
                             ? (0.3 + Math.sin(root.u_time * 5) * 0.4) : 1.0
                    border.color: Theme.panelBorder; border.width: Theme.borderWidth
                }
            }
        }

        Row {
            x: 5; y: 78; spacing: 8
            PowerButton {
                label: "STEALTH"; active: root.activeProfile.includes("power-saver")
                onClicked: { executor.command = ["powerprofilesctl", "set", "power-saver"]; executor.running = true; }
            }
            PowerButton {
                label: "BALANCED"; active: root.activeProfile.includes("balanced")
                onClicked: { executor.command = ["powerprofilesctl", "set", "balanced"]; executor.running = true; }
            }
            PowerButton {
                label: "OVERDRIVE"; active: root.activeProfile.includes("performance")
                onClicked: { executor.command = ["powerprofilesctl", "set", "performance"]; executor.running = true; }
            }
        }

        Rectangle {
            width: parent.width; height: 1; color: statusColor; opacity: 0.2
            anchors.bottom: parent.bottom
        }
    }
}