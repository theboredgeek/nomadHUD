import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Io

PanelWindow {
    id: monitorManager
    required property var targetScreen
    required property var root

    screen: targetScreen
    WlrLayershell.layer: WlrLayershell.Overlay
    anchors { bottom: true; right: true }
    
    implicitWidth: 500 
    implicitHeight: 950
    color: "transparent"

    ListModel { id: monModel }
    property var rawResData: ({}) 
    property string activeMon: ""
    property bool hasChanges: false
    property string lastError: "NONE"

    function isResolutionLine(line) {
        return /^\d+x\d+/.test(line.trim());
    }

    Process {
        id: scanner
        command: ["/usr/bin/wlr-randr"]
        stdout: SplitParser {
            onRead: (line) => {
                let t = line.trim();
                if (t.length > 0 && !line.startsWith(" ")) {
                    let name = t.split(' ')[0];
                    activeMon = name;
                    rawResData[name] = [];
                    let found = false;
                    for(let i=0; i<monModel.count; i++) { if(monModel.get(i).name === name) found = true; }
                    if(!found) monModel.append({name: name, x: 0, y: 0, w: 1920, currentRes: ""});
                } else if (activeMon !== "" && isResolutionLine(t)) {
                    rawResData[activeMon].push(t);
                    for(let i=0; i<monModel.count; i++) {
                        let m = monModel.get(i);
                        if(m.name === activeMon && m.currentRes === "") {
                            let parts = t.split(/[\s,]+/);
                            m.currentRes = parts[0].replace("px", ""); 
                            m.w = parseInt(m.currentRes.split('x')[0]);
                        }
                    }
                }
            }
        }
    }

    function applyTopology() {
        let cmdList = [];
        for (let i = 0; i < monModel.count; i++) {
            let m = monModel.get(i);
            // Constructing an array of strings to avoid space issues
            cmdList.push(`--output "${m.name}" --mode "${m.currentRes}" --pos "${m.x},${m.y}"`);
        }
        
        let finalCmd = "/usr/bin/wlr-randr " + cmdList.join(" ");
        lastError = "RUNNING: " + finalCmd;
        
        executor.command = ["/usr/bin/sh", "-c", finalCmd + " 2>&1"];
        executor.running = true;
    }

    Process { 
        id: executor
        stdout: SplitParser { onRead: (line) => lastError = line }
        onExited: (code) => { 
            if(code === 0) { 
                lastError = "SUCCESS: TOPOLOGY SYNCED"; 
                hasChanges = false; 
            } else {
                lastError = "ERROR (" + code + "): " + lastError;
            }
        }
    }

    Rectangle {
        anchors.fill: parent; anchors.margins: 10
        color: "#0a0a0a"; border.color: "#333"; border.width: 1

        ColumnLayout {
            anchors.fill: parent; anchors.margins: 20; spacing: 15

            Text { text: "TOPOLOGY_SYNTAX_V29"; color: "white"; font.bold: true }
            
            Rectangle {
                Layout.fillWidth: true; height: 100; color: "#001a1a"; border.color: "#00ffff"
                ScrollView {
                    anchors.fill: parent; anchors.margins: 5
                    Text {
                        width: parent.width; color: "#88ffff"
                        text: "SHELL_OUTPUT: " + lastError; font.family: "Monospace"; font.pixelSize: 10; wrapMode: Text.Wrap
                    }
                }
            }

            Row {
                spacing: 8
                Repeater {
                    model: monModel
                    Button {
                        text: name; highlighted: activeMon === name
                        onClicked: activeMon = name
                    }
                }
            }

            
            Rectangle {
                Layout.fillWidth: true; height: 180; color: "black"; border.color: "#222"
                Repeater {
                    model: monModel
                    Rectangle {
                        width: 110; height: 50
                        x: (parent.width/2 - 130) + (model.x / 40)
                        y: (parent.height/2 - 25) + (model.y / 40)
                        color: activeMon === name ? "#00ffcc" : "#1a1a1a"
                        border.color: "white"
                        Text { anchors.centerIn: parent; text: name + "\n" + currentRes; color: "white"; font.pixelSize: 8; horizontalAlignment: Text.AlignHCenter }

                        MouseArea {
                            anchors.fill: parent; drag.target: parent
                            onReleased: {
                                model.x = Math.round((parent.x - (parent.parent.width/2 - 130)) * 40);
                                model.y = Math.round((parent.y - (parent.parent.height/2 - 25)) * 40);
                                hasChanges = true;
                            }
                        }
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true; height: 40; spacing: 10
                Button { 
                    text: "AUTO_STITCH"; Layout.fillWidth: true
                    onClicked: {
                        if (monModel.count < 2) return;
                        monModel.get(1).x = monModel.get(0).w;
                        monModel.get(1).y = 0;
                        hasChanges = true;
                    }
                }
                Button { text: "APPLY"; Layout.fillWidth: true; highlighted: hasChanges; onClicked: applyTopology() }
            }

            Rectangle {
                Layout.fillWidth: true; Layout.fillHeight: true; color: "#050505"; border.color: "#222"
                ScrollView {
                    anchors.fill: parent; clip: true
                    Column {
                        width: parent.width
                        Repeater {
                            model: (activeMon !== "" && rawResData[activeMon]) ? rawResData[activeMon] : []
                            Button {
                                width: parent.width; height: 35
                                text: modelData; font.pixelSize: 9
                                onClicked: {
                                    let parts = modelData.trim().split(/[\s,]+/);
                                    for(let i=0; i<monModel.count; i++) {
                                        if(monModel.get(i).name === activeMon) {
                                            monModel.get(i).currentRes = parts[0].replace("px", "");
                                            monModel.get(i).w = parseInt(monModel.get(i).currentRes.split('x')[0]);
                                            hasChanges = true;
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    Component.onCompleted: scanner.running = true;
}