import QtQuick
import QtQuick.Layouts 
import Quickshell
import Quickshell.Wayland
import Qt5Compat.GraphicalEffects

PanelWindow {
    id: gpuWindow
    required property var targetScreen
    required property var root
    property var anchorTarget 

    screen: targetScreen
    WlrLayershell.layer: WlrLayershell.Bottom
    
    WlrLayershell.margins { right: 20 }

    Binding {
        target: gpuWindow.WlrLayershell
        property: "margins.bottom"
        value: anchorTarget ? Math.floor(anchorTarget.WlrLayershell.margins.bottom + anchorTarget.implicitHeight + 15) : 140
    }

    anchors { bottom: true; right: true }

    implicitWidth: 300 
    implicitHeight: mainGpuLayout.contentHeight + 20
    color: "transparent"

    ListView {
        id: mainGpuLayout
        width: 280
        height: contentHeight
        anchors.right: parent.right
        anchors.rightMargin: 10
        anchors.bottom: parent.bottom
        spacing: Theme.moduleSpacing 
        interactive: false 
        
        model: root ? root.gpuData : [] 
        
        delegate: Rectangle {
            width: 280
            height: 85 // Slightly taller for better spacing
            color: Theme.glass
            border.width: Theme.borderWidth
            radius: Theme.cornerRadius
            
            property var gpuInfo: modelData.split('|')
            readonly property string vendor: gpuInfo[0] || "UNK"
            readonly property real loadVal: parseFloat(gpuInfo[1]) || 0
            readonly property real vramUsedVal: parseFloat(gpuInfo[2]) || 0
            readonly property real vramTotalVal: parseFloat(gpuInfo[3]) || 0
            
            // Unified color logic
            readonly property color gpuColor: Theme.getLoadColor(loadVal)
            border.color: gpuColor

            Column {
                anchors.centerIn: parent
                spacing: 8
                
                // Header: Vendor and %
                Row {
                    width: 250
                    layoutDirection: Qt.RightToLeft
                    spacing: 10
                    Text { 
                        text: "GPU_" + index + " [" + vendor + "]"
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeSmall
                        color: gpuColor
                        opacity: Theme.inactiveOpacity
                    }
                    Text { 
                        text: loadVal.toFixed(0) + "%"
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeMed
                        color: gpuColor
                        font.bold: true 
                    }
                }

                // Load Bar
                Rectangle {
                    width: 250; height: Theme.barHeight
                    color: Theme.glassLight
                    border.color: Theme.panelBorder
                    border.width: 1

                    Rectangle {
                        id: loadFill
                        anchors.right: parent.right; height: parent.height
                        width: Math.max(2, parent.width * (Math.min(100, loadVal) / 100))
                        color: gpuColor

                        // Glow effect for active load
                        layer.enabled: loadVal > 10
                        layer.effect: Glow {
                            color: gpuColor
                            radius: 4
                            samples: 8
                            spread: 0.2
                        }

                        Behavior on width { 
                            NumberAnimation { duration: 500; easing.type: Theme.defaultEasing } 
                        }
                    }
                }

                // VRAM Text
                Text {
                    width: 250
                    horizontalAlignment: Text.AlignRight
                    text: "VRAM_ALLOC: " + vramUsedVal.toFixed(2) + "G / " + vramTotalVal.toFixed(1) + "G"
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeTiny
                    color: gpuColor
                    opacity: 0.8
                }
            }
        }
    }
}