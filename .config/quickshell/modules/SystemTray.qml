import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects 
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.SystemTray 

PanelWindow {
    id: trayWindow
    required property var targetScreen
    required property var root 
    
    screen: targetScreen
    WlrLayershell.layer: WlrLayershell.Bottom
    WlrLayershell.exclusiveZone: 0
    WlrLayershell.keyboardFocus: WlrLayershell.None
    
    // Mask ensures the window only intercepts input where the tray actually is
    WlrLayershell.mask: Region {
        item: trayBackground
    }

    anchors { top: true; left: true }

    implicitWidth: 500  
    implicitHeight: 600 
    color: "transparent"

    Rectangle {
        id: trayBackground
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.topMargin: 200 
        anchors.leftMargin: 35

        width: mainColumn.implicitWidth + 12
        height: mainColumn.implicitHeight + 12
        color: Theme.bgDark
        border.color: Theme.amber
        border.width: Theme.borderWidth
        opacity: 0.9
        radius: Theme.cornerRadius 

        ColumnLayout {
            id: mainColumn
            anchors.centerIn: parent
            spacing: 6

            Grid {
                id: trayGrid
                Layout.alignment: Qt.AlignLeft
                rows: 20 
                flow: Grid.TopToBottom
                spacing: 6

                Repeater {
                    model: SystemTray.items ? SystemTray.items : 0

                    Rectangle {
                        id: iconContainer
                        width: 24; height: 24
                        color: trayMouse.containsMouse ? Theme.hoverTint : "transparent"
                        border.color: trayMouse.containsMouse ? Theme.amber : Theme.panelBorder
                        border.width: Theme.borderWidth

                        // Status-based glow (e.g., notification or active state)
                        RectangularGlow {
                            id: effect
                            anchors.fill: parent
                            glowRadius: 4
                            spread: 0.2
                            color: Theme.amber
                            visible: modelData.status === 2
                            
                            SequentialAnimation on opacity {
                                running: effect.visible
                                loops: Animation.Infinite
                                NumberAnimation { from: 0.1; to: 0.7; duration: 1000; easing.type: Easing.OutQuad }
                                NumberAnimation { from: 0.7; to: 0.1; duration: 1000; easing.type: Easing.OutQuad }
                            }
                        }

                        Image {
                            anchors.fill: parent
                            anchors.margins: 4
                            source: modelData.icon !== "" ? (modelData.icon.startsWith("/") ? "file://" + modelData.icon : modelData.icon) : "image-missing"
                            fillMode: Image.PreserveAspectFit
                            asynchronous: true
                            // Dim non-active icons to maintain focus
                            opacity: (trayMouse.containsMouse || effect.visible) ? 1.0 : Theme.inactiveOpacity
                        }

                        MouseArea {
                            id: trayMouse
                            anchors.fill: parent
                            acceptedButtons: Qt.LeftButton | Qt.RightButton
                            hoverEnabled: true

                            // Tactical Ripple Feedback
                            Rectangle {
                                id: ripple
                                width: 0; height: 0
                                anchors.centerIn: parent
                                radius: width / 2
                                color: Theme.amber
                                opacity: 0

                                SequentialAnimation {
                                    id: rippleAnim
                                    ParallelAnimation {
                                        NumberAnimation { target: ripple; property: "width"; from: 0; to: trayMouse.width * 1.5; duration: Theme.animSpeed; easing.type: Theme.defaultEasing }
                                        NumberAnimation { target: ripple; property: "height"; from: 0; to: trayMouse.height * 1.5; duration: Theme.animSpeed; easing.type: Theme.defaultEasing }
                                        NumberAnimation { target: ripple; property: "opacity"; from: 0.6; to: 0; duration: Theme.animSpeed }
                                    }
                                }
                            }

                            onClicked: (mouse) => {
                                rippleAnim.restart();
                                let windowPos = trayMouse.mapToItem(null, mouse.x, mouse.y);
                                if (modelData.hasMenu) {
                                    modelData.display(trayWindow, windowPos.x, windowPos.y);
                                } else if (mouse.button === Qt.LeftButton) {
                                    modelData.activate();
                                }
                            }

                            ToolTip.visible: containsMouse
                            ToolTip.delay: 200
                            ToolTip.text: modelData.title || "PROC_ID: " + (modelData.id || "0x0")
                        }
                    }
                }
            }

            // --- HEX DATA STRIP ---
            Rectangle {
                id: counterBar
                Layout.fillWidth: true
                height: 10 
                color: "transparent"
                clip: true 

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 4
                    anchors.rightMargin: 4
                    spacing: 4
                    
                    Rectangle {
                        width: 12; height: 1
                        color: Theme.amber 
                        opacity: 0.8
                    }

                    Item { Layout.fillWidth: true }

                    Text {
                        // Displaying item count in Hex (0x01, 0x0A, etc.)
                        text: (SystemTray.items && SystemTray.items.count !== undefined) 
                              ? "0x" + SystemTray.items.count.toString(16).toUpperCase().padStart(2, '0')
                              : "0x00"
                        color: Theme.amber
                        opacity: 0.4
                        font.pixelSize: Theme.fontSizeTiny
                        font.family: Theme.fontFamily
                    }
                }
            }
        }
    }

    // Context Menu Styling
    Menu {
        id: contextMenu
        background: Rectangle { 
            color: Theme.bgDark
            border.color: Theme.amber
            border.width: Theme.borderWidth
        }
        delegate: MenuItem {
            id: menuItem
            contentItem: Text {
                text: menuItem.text
                color: menuItem.highlighted ? "black" : Theme.amber
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeMed
            }
            background: Rectangle { 
                color: menuItem.highlighted ? Theme.amber : "transparent"
            }
        }
    }
}