import QtQuick
import QtQuick.Layouts 
import Quickshell
import Quickshell.Wayland

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
    // FIXED: Height now scales properly based on the number of GPUs detected
    implicitHeight: mainGpuLayout.contentHeight + 20
    color: "transparent"

    ListView {
        id: mainGpuLayout
        width: 280
        height: contentHeight
        anchors.right: parent.right
        anchors.rightMargin: 10
        anchors.bottom: parent.bottom
        spacing: 15 
        interactive: false 
        
        model: root ? root.gpuData : [] 
        
        delegate: Rectangle {
            width: 280
            height: 80
            color: root ? root.glass : "black"
            border.width: 1
            
            // Each modelData is now "NAME|LOAD|USED|TOTAL"
            property var gpuInfo: modelData.split('|')
            readonly property string vendor: gpuInfo[0] || "UNK"
            readonly property real loadVal: parseFloat(gpuInfo[1]) || 0
            readonly property real vramUsedVal: parseFloat(gpuInfo[2]) || 0
            readonly property real vramTotalVal: parseFloat(gpuInfo[3]) || 0
            
            property color gpuColor: root ? root.getAlertColor(loadVal) : "#E1B12C"
            border.color: gpuColor

            Column {
                anchors.centerIn: parent
                spacing: 6
                
                Row {
                    width: 250
                    layoutDirection: Qt.RightToLeft
                    spacing: 10
                    Text { 
                        text: "GPU_" + index + " [" + vendor + "]"
                        font.family: "Monospace"; font.pixelSize: 11; color: gpuColor; opacity: 0.7
                    }
                    Text { 
                        text: loadVal.toFixed(0) + "%"
                        font.family: "Monospace"; font.pixelSize: 12; color: gpuColor; font.bold: true 
                    }
                }

                Rectangle {
                    width: 250; height: 4
                    color: Qt.rgba(gpuColor.r, gpuColor.g, gpuColor.b, 0.1)
                    Rectangle {
                        anchors.right: parent.right; height: parent.height
                        width: Math.max(2, parent.width * (Math.min(100, loadVal) / 100))
                        color: gpuColor
                    }
                }

                Text {
                    width: 250
                    horizontalAlignment: Text.AlignRight
                    text: "VRAM: " + vramUsedVal.toFixed(2) + "G / " + vramTotalVal.toFixed(1) + "G"
                    font.family: "Monospace"; font.pixelSize: 10; color: gpuColor; opacity: 0.8
                }
            }
        }
    }
}