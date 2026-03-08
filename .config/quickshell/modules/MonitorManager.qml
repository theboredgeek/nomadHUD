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
    
    // MOVED: From Overlay to Bottom to sit with other modules
    WlrLayershell.layer: WlrLayershell.Bottom
    
    WlrLayershell.margins {
        top: 50
        right: 1000
    }
    
    anchors { bottom: true; right: true }
    
    // FIXED: Using implicit dimensions to stop the "deprecated" warnings
    implicitWidth: 70
    implicitHeight: 70
    color: "transparent"

    // --- TACTICAL HEX TRIGGER ---
    Rectangle {
        id: hexTrigger
        anchors.fill: parent
        color: layoutPopup.opened ? "#ffb000" : "#0d0d0d"
        border.color: "#ffb000"
        border.width: 2
        rotation: 45 
        opacity: 0.9

        Text {
            anchors.centerIn: parent
            text: "DISP"
            color: layoutPopup.opened ? "black" : "#ffb000"
            font.pixelSize: 12
            font.bold: true
            rotation: -45 
        }

        MouseArea {
            anchors.fill: parent
            onClicked: layoutPopup.opened ? layoutPopup.close() : layoutPopup.open()
        }
    }

    // --- AUGMENTED REALITY POPUP ---
    Popup {
        id: layoutPopup
        x: -460 
        y: -910 
        width: 500
        height: 900
        padding: 0
        
        background: Rectangle {
            color: "#050505"
            border.color: "#ffb000"
            border.width: 1
            opacity: 0.95
            
            Rectangle {
                anchors.fill: parent
                color: "transparent"
                border.color: "#33ffb000"
                border.width: 1
                anchors.margins: 4
            }
        }

        contentItem: ColumnLayout {
            anchors.fill: parent; anchors.margins: 20; spacing: 15

            Text { 
                text: "TOPOLOGY_CALIBRATION_V34"; 
                color: "#ffb000"; 
                font.bold: true;
                font.letterSpacing: 1
            }

            Rectangle {
                Layout.fillWidth: true; height: 250; color: "black"; border.color: "#222"; clip: true
                
                Repeater {
                    model: monModel
                    Rectangle {
                        width: getLogicalWidth(index) / 40
                        height: getLogicalHeight(index) / 40
                        x: 50 + (model.x / 40)
                        y: 80 + (model.y / 40)
                        
                        color: activeMon === name ? "#ffb000" : "#1a1a1a"
                        border.color: "white"; border.width: activeMon === name ? 2 : 1
                        
                        Text { 
                            anchors.centerIn: parent
                            color: activeMon === name ? "black" : "white"
                            font.pixelSize: 9
                            text: name + "\n" + model.x + "," + model.y
                            horizontalAlignment: Text.AlignHCenter
                        }

                        MouseArea {
                            anchors.fill: parent; drag.target: parent
                            onPressed: activeMon = name
                            onReleased: {
                                let tx = Math.round((parent.x - 50) * 40);
                                let ty = Math.round((parent.y - 80) * 40);
                                monModel.setProperty(index, "x", tx);
                                monModel.setProperty(index, "y", ty);
                                hasChanges = true;
                            }
                        }
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true; spacing: 10
                ComboBox {
                    Layout.fillWidth: true
                    model: ["normal", "90", "180", "270", "flipped", "flipped-90", "flipped-180", "flipped-270"]
                    onActivated: (idx) => {
                        for(let i=0; i<monModel.count; i++) {
                            if(monModel.get(i).name === activeMon) {
                                monModel.setProperty(i, "rotationType", textAt(idx));
                                hasChanges = true;
                            }
                        }
                    }
                }
                Button { 
                    text: "AUTO_STITCH"
                    onClicked: {
                        if (monModel.count < 2) return;
                        let anchorIdx = 0;
                        let minX = monModel.get(0).x;
                        for(let i=1; i<monModel.count; i++) {
                            if(monModel.get(i).x < minX) {
                                minX = monModel.get(i).x;
                                anchorIdx = i;
                            }
                        }
                        let secondaryIdx = (anchorIdx === 0) ? 1 : 0;
                        let anchorWidth = getLogicalWidth(anchorIdx);
                        monModel.setProperty(secondaryIdx, "x", monModel.get(anchorIdx).x + anchorWidth);
                        monModel.setProperty(secondaryIdx, "y", monModel.get(anchorIdx).y);
                        hasChanges = true;
                    }
                }
            }

            Button { 
                text: "APPLY TOPOLOGY"; Layout.fillWidth: true; highlighted: hasChanges
                onClicked: applyTopology() 
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
                                width: parent.width
                                text: modelData
                                font.pixelSize: 9
                                onClicked: {
                                    let res = modelData.split(/[\s,]+/)[0].replace("px", "");
                                    for(let i=0; i<monModel.count; i++) {
                                        if(monModel.get(i).name === activeMon) {
                                            monModel.setProperty(i, "currentRes", res);
                                            monModel.setProperty(i, "w", parseInt(res.split('x')[0]));
                                            monModel.setProperty(i, "h", parseInt(res.split('x')[1]));
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

    ListModel { id: monModel }
    property var rawResData: ({}) 
    property string activeMon: ""
    property bool hasChanges: false
    property string lastError: "IDLE"

    function getLogicalWidth(idx) {
        if (idx < 0 || idx >= monModel.count) return 0;
        let m = monModel.get(idx);
        let isPortrait = (m.rotationType.includes("90") || m.rotationType.includes("270"));
        return isPortrait ? m.h : m.w;
    }

    function getLogicalHeight(idx) {
        if (idx < 0 || idx >= monModel.count) return 0;
        let m = monModel.get(idx);
        let isPortrait = (m.rotationType.includes("90") || m.rotationType.includes("270"));
        return isPortrait ? m.w : m.h;
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
                    monModel.append({name: name, x: 0, y: 0, w: 1920, h: 1080, currentRes: "", rotationType: "normal"});
                } else if (activeMon !== "" && /^\d+x\d+/.test(t)) {
                    rawResData[activeMon].push(t);
                    for(let i=0; i<monModel.count; i++) {
                        let m = monModel.get(i);
                        if(m.name === activeMon && m.currentRes === "") {
                            let res = t.split(/[\s,]+/)[0].replace("px", "");
                            m.currentRes = res;
                            m.w = parseInt(res.split('x')[0]);
                            m.h = parseInt(res.split('x')[1]);
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
            cmdList.push(`--output "${m.name}" --mode "${m.currentRes}" --pos "${m.x},${m.y}" --transform "${m.rotationType}"`);
        }
        executor.command = ["/usr/bin/sh", "-c", "/usr/bin/wlr-randr " + cmdList.join(" ") + " 2>&1"];
        executor.running = true;
    }

    Process { 
        id: executor
        stdout: SplitParser { onRead: (line) => lastError = line }
        onExited: (code) => { if(code === 0) { lastError = "SUCCESS"; hasChanges = false; } }
    }

    Component.onCompleted: scanner.running = true;
}