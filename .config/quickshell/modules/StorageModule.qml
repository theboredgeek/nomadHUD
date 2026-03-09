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
    WlrLayershell.keyboardFocus: WlrLayershell.None
    
    anchors { bottom: true; right: true }
    
    implicitWidth: storageMainBox.width
    implicitHeight: storageMainBox.height

    // Theme integration from shell.qml
    property color accent: root.amber
    property string monoFont: root.fontFamily

    Binding {
        target: storageWindow.WlrLayershell
        property: "margins.bottom"
        value: anchorTarget ? Math.floor(anchorTarget.WlrLayershell.margins.bottom + anchorTarget.implicitHeight + 15) : 20
    }
    WlrLayershell.margins.right: 20

    Rectangle {
        id: storageMainBox
        width: 300
        height: Math.max(storageList.contentHeight + 20, 60)
        color: root.glass
        border.color: "#333"
        border.width: 1

        ListView {
            id: storageList
            anchors.fill: parent
            anchors.margins: 10
            spacing: 12
            interactive: false 
            model: ListModel { id: storageModel }

            delegate: Item {
                width: 280; height: mounted ? 85 : 50
                
                Rectangle {
                    anchors.fill: parent
                    color: "transparent"
                    border.width: 1
                    border.color: (driveHover.containsMouse || mounted) ? storageWindow.accent : "#333"

                    MouseArea {
                        id: driveHover
                        anchors.fill: parent
                        hoverEnabled: true
                        acceptedButtons: Qt.NoButton
                    }

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 6

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 10

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 0

                                Text { 
                                    Layout.fillWidth: true
                                    // NEW: Logic for "NAME // LABEL"
                                    text: model.name.toUpperCase() + " // " + model.label.toUpperCase()
                                    font.family: storageWindow.monoFont
                                    font.pixelSize: 10; 
                                    color: (driveHover.containsMouse || mounted) ? storageWindow.accent : "#888" 
                                    elide: Text.ElideRight
                                }
                                Text { 
                                    Layout.fillWidth: true
                                    text: "SIZE: " + (model.size || "--") + " | " + (mounted ? "MOUNTED" : "UNMOUNTED")
                                    font.family: storageWindow.monoFont
                                    font.pixelSize: 9; 
                                    color: driveHover.containsMouse ? "#aaa" : "#555" 
                                    elide: Text.ElideRight
                                }
                            }

                            Row {
                                id: buttonRow
                                spacing: 8
                                
                                Rectangle {
                                    width: 56; height: 24
                                    color: mntMouse.containsMouse ? storageWindow.accent : "#1a1a1a"
                                    border.color: storageWindow.accent
                                    border.width: 1
                                    
                                    Text {
                                        anchors.centerIn: parent
                                        text: mounted ? "UMNT" : "MNT"
                                        font.family: storageWindow.monoFont
                                        font.pixelSize: 10
                                        font.bold: true
                                        color: mntMouse.containsMouse ? "black" : storageWindow.accent
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

                                Rectangle {
                                    width: 56; height: 24
                                    visible: mounted && model.path !== ""
                                    color: viewMouse.containsMouse ? storageWindow.accent : "#1a1a1a"
                                    border.color: storageWindow.accent
                                    border.width: 1
                                    
                                    Text {
                                        anchors.centerIn: parent
                                        text: "VIEW"
                                        font.family: storageWindow.monoFont
                                        font.pixelSize: 10
                                        font.bold: true
                                        color: viewMouse.containsMouse ? "black" : storageWindow.accent
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
                                    font.family: storageWindow.monoFont
                                    font.pixelSize: 9; color: "#666"
                                }
                                Item { Layout.fillWidth: true }
                                Text {
                                    text: model.usePerc
                                    font.family: storageWindow.monoFont
                                    font.pixelSize: 9; color: storageWindow.accent
                                }
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                height: 4
                                color: "#222"
                                Rectangle {
                                    width: parent.width * (Math.min(100, parseInt(model.usePerc.replace('%',''))) / 100)
                                    height: parent.height
                                    color: storageWindow.accent
                                    opacity: 0.8
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