import QtQuick
import Quickshell
import Quickshell.Wayland
import Qt5Compat.GraphicalEffects

PanelWindow {
    id: clockWindow
    required property var targetScreen
    required property var root

    screen: targetScreen
    WlrLayershell.layer: WlrLayershell.Bottom
    anchors { top: true; right: true }
    
    implicitWidth: 320
    implicitHeight: 350
    color: "transparent"

    Item {
        id: clockContainer
        anchors.fill: parent

        Column {
            anchors.top: parent.top
            anchors.topMargin: 40 
            anchors.right: parent.right
            anchors.rightMargin: 40
            spacing: 4

            // The Main Digital Readout
            Text {
                id: timeText
                text: {
                    let dummy = root ? root.u_time : 0; 
                    return Qt.formatDateTime(new Date(), "hh:mm:ss");
                }
                font.family: Theme.fontFamily
                font.pixelSize: 34
                font.bold: true
                color: Theme.amber
                
                layer.enabled: true
                layer.effect: DropShadow {
                    transparentBorder: true
                    color: Theme.mainGlow
                    radius: 10
                    samples: 16
                }
            }

            // Subtitle / Date Line
            Text {
                text: "// SYSTEM_SYNC_ACTIVE // " + Qt.formatDateTime(new Date(), "yyyy.MM.dd")
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.amber
                opacity: Theme.inactiveOpacity
            }

            // Animated Scanner Divider
            Rectangle {
                width: 200; height: Theme.borderWidth
                color: Theme.panelBorder
                
                Rectangle {
                    width: 30; height: 3
                    anchors.verticalCenter: parent.verticalCenter
                    color: Theme.amber
                    x: (parent.width - width) * (Math.sin(root ? root.u_time * 2 : 0) + 1) / 2
                    
                    layer.enabled: true
                    layer.effect: Glow {
                        color: Theme.amber
                        radius: 5
                        samples: 10
                    }
                }
            }
        }
    }
}