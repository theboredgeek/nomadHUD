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
    required property var root // Changed to required to match your shell.qml call
    
    screen: targetScreen
    WlrLayershell.layer: WlrLayershell.Bottom
    WlrLayershell.exclusiveZone: 0
    WlrLayershell.keyboardFocus: WlrLayershell.None
    
    // --- THEME DATA BINDING ---
    readonly property color accent: root ? root.amber : "#2c4de1"
    readonly property string monoFont: root ? root.fontFamily : "Monospace"

    WlrLayershell.mask: Region {
        item: trayBackground
    }

    anchors {
        top: true
        left: true
    }

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
        color: "#050505"
        border.color: trayWindow.accent // Theme Reliance
        border.width: 1
        opacity: 0.9
        radius: 2 

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
                        color: trayMouse.containsMouse ? "#1a1a1a" : "transparent"
                        border.color: trayMouse.containsMouse ? trayWindow.accent : "#222"
                        border.width: 1

                        RectangularGlow {
                            id: effect
                            anchors.fill: parent
                            glowRadius: 4
                            spread: 0.2
                            color: trayWindow.accent // Theme Reliance
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
                            opacity: (trayMouse.containsMouse || effect.visible) ? 1.0 : 0.6
                        }

                        MouseArea {
                            id: trayMouse
                            anchors.fill: parent
                            acceptedButtons: Qt.LeftButton | Qt.RightButton
                            hoverEnabled: true

                            Rectangle {
                                id: ripple
                                width: 0; height: 0
                                anchors.centerIn: parent
                                radius: width / 2
                                color: trayWindow.accent // Theme Reliance
                                opacity: 0

                                SequentialAnimation {
                                    id: rippleAnim
                                    ParallelAnimation {
                                        NumberAnimation { target: ripple; property: "width"; from: 0; to: trayMouse.width * 1.5; duration: 250; easing.type: Easing.OutQuart }
                                        NumberAnimation { target: ripple; property: "height"; from: 0; to: trayMouse.height * 1.5; duration: 250; easing.type: Easing.OutQuart }
                                        NumberAnimation { target: ripple; property: "opacity"; from: 0.6; to: 0; duration: 250 }
                                    }
                                }
                            }

                            onClicked: (mouse) => {
                                rippleAnim.restart();
                                let windowPos = trayMouse.mapToItem(null, mouse.x, mouse.y);
                                if (modelData.hasMenu) {
                                    modelData.display(trayWindow, windowPos.x, windowPos.y);
                                } else {
                                    if (mouse.button === Qt.LeftButton) {
                                        modelData.activate();
                                    }
                                }
                            }

                            ToolTip.visible: containsMouse
                            ToolTip.delay: 200
                            ToolTip.text: modelData.title || "PROCESS_ID: " + (modelData.id || "UNKNOWN")
                        }
                    }
                }
            }

            // --- ULTRA-SLIM DATA STRIP ---
            Rectangle {
                id: counterBar
                Layout.fillWidth: true
                height: 8 
                color: "transparent"
                clip: true 

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 4
                    anchors.rightMargin: 4
                    spacing: 2
                    
                    Rectangle {
                        width: 12; height: 2
                        color: trayWindow.accent // Theme Reliance
                        radius: 1
                    }

                    Rectangle {
                        width: 1; height: 4
                        color: "#33ffffff"
                    }

                    Item { Layout.fillWidth: true }

                    Text {
                        text: (SystemTray.items && SystemTray.items.count !== undefined) 
                              ? "0x" + SystemTray.items.count.toString(16).toUpperCase()
                              : "0x00"
                        color: trayWindow.accent // Theme Reliance
                        opacity: 0.6
                        font.pixelSize: 7
                        font.bold: true
                        font.family: trayWindow.monoFont // Theme Reliance
                    }
                }
            }
        }
    }

    Menu {
        id: contextMenu
        property var menuModel
        property var visualParent: null
        background: Rectangle { 
            color: "#0d0d0d"
            border.color: trayWindow.accent // Theme Reliance
            border.width: 1 
        }
        delegate: MenuItem {
            id: menuItem
            contentItem: Text {
                text: menuItem.text
                color: menuItem.highlighted ? "black" : trayWindow.accent // Theme Reliance
                font.family: trayWindow.monoFont // Theme Reliance
                font.pixelSize: 12
                font.bold: true
            }
            background: Rectangle { 
                color: menuItem.highlighted ? trayWindow.accent : "transparent" // Theme Reliance
            }
        }
    }
}