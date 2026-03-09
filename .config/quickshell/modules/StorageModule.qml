import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import Quickshell.Io

PanelWindow {
    id: storageWindow
    required property var targetScreen
    required property var root
    property var anchorTarget

    screen: targetScreen
    WlrLayershell.layer: WlrLayershell.Bottom
    WlrLayershell.namespace: "storage_module"
    
    anchors { bottom: true; right: true }
    
    implicitWidth: storageMainBox.width
    implicitHeight: storageMainBox.height

    Binding {
        target: storageWindow.WlrLayershell
        property: "margins.bottom"
        value: anchorTarget ? Math.floor(anchorTarget.WlrLayershell.margins.bottom + anchorTarget.implicitHeight + Theme.moduleSpacing) : 20
    }
    WlrLayershell.margins.right: 20

    Rectangle {
        id: storageMainBox
        width: 300
        height: Math.max(storageList.contentHeight + (Theme.panelPadding * 2), 60)
        color: Theme.glass
        border.color: Theme.panelBorder
        border.width: Theme.borderWidth
        radius: Theme.cornerRadius

        ListView {
            id: storageList
            anchors.fill: parent
            anchors.margins: Theme.panelPadding
            spacing: Theme.moduleSpacing
            interactive: false 
            model: ListModel { id: storageModel }

            delegate: Item {
                width: 280; height: mounted ? 85 : 50
                
                Rectangle {
                    anchors.fill: parent
                    color: driveHover.containsMouse ? Theme.hoverTint : "transparent"
                    border.width: Theme.borderWidth
                    border.color: (driveHover.containsMouse || mounted) ? Theme.amber : Theme.panelBorder

                    MouseArea {
                        id: driveHover
                        anchors.fill: parent
                        hoverEnabled: true
                        acceptedButtons: Qt.NoButton
                    }

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: Theme.panelPadding
                        spacing: 6

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: Theme.panelPadding

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 0

                                Text { 
                                    Layout.fillWidth: true
                                    text: model.name.toUpperCase() + " // " + model.label.toUpperCase()
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fontSizeMed
                                    color: (driveHover.containsMouse || mounted) ? Theme.amber : Theme.textSecondary 
                                    elide: Text.ElideRight
                                }
                                Text { 
                                    Layout.fillWidth: true
                                    text: "SIZE: " + (model.size || "--") + " | " + (mounted ? "ACTIVE" : "OFFLINE")
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fontSizeSmall
                                    color: driveHover.containsMouse ? Theme.textSecondary : Theme.inactive 
                                    elide: Text.ElideRight
                                }
                            }

                            Row {
                                id: buttonRow
                                spacing: 8
                                
                                // MOUNT / UNMOUNT BUTTON
                                Rectangle {
                                    width: Theme.btnWidth; height: Theme.btnHeight
                                    color: Theme.getBtnBg(mntMouse.containsMouse)
                                    border.color: Theme.getBtnBorder(mntMouse.containsMouse)
                                    border.width: Theme.borderWidth
                                    radius: Theme.cornerRadius
                                    
                                    Text {
                                        anchors.centerIn: parent
                                        text: mounted ? "UMNT" : "MNT"
                                        font.family: Theme.fontFamily
                                        font.pixelSize: Theme.fontSizeMed
                                        font.bold: true
                                        color: Theme.getBtnText(mntMouse.containsMouse)
                                    }

                                    MouseArea {
                                        id: mntMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        onClicked: {
                                            actionProc.command = mounted 
                                                ? ["udisksctl", "unmount", "-b", "/dev/" + model.name] 
                                                : ["udisksctl", "mount", "-b", "/dev/" + model.name];
                                            actionProc.running = true;
                                        }
                                    }
                                }

                                // VIEW BUTTON
                                Rectangle {
                                    width: Theme.btnWidth; height: Theme.btnHeight
                                    visible: mounted && model.path !== ""
                                    color: Theme.getBtnBg(viewMouse.containsMouse)
                                    border.color: Theme.getBtnBorder(viewMouse.containsMouse)
                                    border.width: Theme.borderWidth
                                    radius: Theme.cornerRadius
                                    
                                    Text {
                                        anchors.centerIn: parent
                                        text: "VIEW"
                                        font.family: Theme.fontFamily
                                        font.pixelSize: Theme.fontSizeMed
                                        font.bold: true
                                        color: Theme.getBtnText(viewMouse.containsMouse)
                                    }

                                    MouseArea {
                                        id: viewMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        onClicked: {
                                            openProc.command = ["xdg-open", model.path];
                                            openProc.running = true;
                                        }
                                    }
                                }
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            visible: mounted
                            spacing: 3

                            RowLayout {
                                Layout.fillWidth: true
                                Text {
                                    text: model.avail + " FREE"
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fontSizeSmall
                                    color: Theme.textDim
                                }
                                Item { Layout.fillWidth: true }
                                Text {
                                    text: model.usePerc
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fontSizeSmall
                                    color: Theme.getStorageColor(model.usePerc)
                                }
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                height: Theme.barHeight
                                color: Theme.glassLight
                                Rectangle {
                                    width: parent.width * (Math.min(100, parseInt(model.usePerc.replace('%',''))) / 100)
                                    height: parent.height
                                    color: Theme.getStorageColor(model.usePerc)
                                    
                                    Behavior on width { 
                                        NumberAnimation { duration: Theme.animSpeed; easing.type: Theme.defaultEasing } 
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    Process { id: actionProc; onExited: lsblkProc.running = true }
    Process { id: openProc }
    Process {
        id: lsblkProc
        command: ["lsblk", "-J", "-o", "NAME,SIZE,MOUNTPOINTS,FSTYPE,LABEL,FSAVAIL,FSUSE%"]
        running: true
        property string buffer: ""
        stdout: SplitParser { onRead: data => { lsblkProc.buffer += data; } }
        onExited: (exitCode) => {
            let cleanData = lsblkProc.buffer.trim();
            lsblkProc.buffer = ""; 
            if (!cleanData.startsWith("{")) { lsblkProc.running = false; return; }
            try {
                const json = JSON.parse(cleanData);
                storageModel.clear();
                if (json.blockdevices) {
                    const processDev = (d) => {
                        let mnt = "";
                        if (Array.isArray(d.mountpoints)) { mnt = d.mountpoints.find(p => p !== null) || ""; }
                        if (d.fstype && d.fstype !== "swap" && !d.name.includes("loop")) {
                            storageModel.append({
                                name: d.name, 
                                label: d.label || "LOCAL DISK", 
                                size: d.size, 
                                mounted: mnt !== "", 
                                path: mnt,
                                avail: d.fsavail || "0B",
                                usePerc: d["fsuse%"] || "0%"
                            });
                        }
                        if (d.children) d.children.forEach(processDev);
                    };
                    json.blockdevices.forEach(processDev);
                }
            } catch (e) { console.log(e); }
            lsblkProc.running = false;
        }
    }
    Timer { interval: 5000; running: true; repeat: true; onTriggered: if(!lsblkProc.running) lsblkProc.running = true }
}