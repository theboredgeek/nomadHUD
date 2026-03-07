import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Io

PanelWindow {
    id: gpuWindow
    required property var targetScreen
    required property var root

    screen: targetScreen
    WlrLayershell.layer: WlrLayershell.Bottom
    anchors { top: true; right: true }
    implicitWidth: 450; implicitHeight: 200; color: "transparent"

    // Data parsing logic
    property var gpuList: []

    Process {
        id: gpuDiscovery
        command: ["/bin/sh", "-c", "for gpu in /sys/class/drm/card*-*; do [ -e \"$gpu/device/gpu_busy_percent\" ] || continue; NAME=$(cat \"$gpu/device/vendor\" 2>/dev/null | sed 's/0x1002/AMD/;s/0x10de/NVIDIA/;s/0x8086/INTEL/'); LOAD=$(cat \"$gpu/device/gpu_busy_percent\" 2>/dev/null || echo 0); printf \"$NAME|$LOAD \"; done"]
        stdout: SplitParser {
            onRead: data => {
                let items = data.trim().split(' ').filter(i => i.length > 0)
                if (root) root.gpuData = items 
                gpuDiscovery.running = false
            }
        }
    }

    Timer {
        interval: 2000; running: true; repeat: true
        onTriggered: if (!gpuDiscovery.running) gpuDiscovery.running = true
    }

    Item {
        anchors { fill: parent; margins: 40 }
        
        Column {
            anchors.right: parent.right
            spacing: 15

            Repeater {
                // Safeguard against root being undefined on first frame
                model: root ? root.gpuData : [] 
                delegate: Column {
                    anchors.right: parent.right
                    spacing: 4
                    
                    property var gpuInfo: modelData.split('|')
                    property string vendor: gpuInfo[0] || "UNK"
                    property string load: gpuInfo[1] || "0"
                    
                    // Safety check for function call
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

                    Rectangle {
                        width: 200; height: 4
                        color: Qt.rgba(gpuColor.r, gpuColor.g, gpuColor.b, 0.15)
                        anchors.right: parent.right
                        Rectangle {
                            anchors.right: parent.right
                            height: parent.height
                            // Safety check for math
                            width: parent.width * (Math.min(100, parseInt(load || 0)) / 100)
                            color: gpuColor
                            Behavior on width { NumberAnimation { duration: 800; easing.type: Easing.OutQuint } }
                        }
                    }
                }
            }
        }
    }
}