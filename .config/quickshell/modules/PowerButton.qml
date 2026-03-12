import QtQuick
import Quickshell

Item {
    id: control
    property string label: "UNKNOWN"
    property bool active: false
    signal clicked()

    implicitWidth: Theme.btnWidth + 28 // Adjusted for larger text
    implicitHeight: Theme.btnHeight

    Rectangle {
        anchors.fill: parent
        // Use theme logic for background
        color: control.active ? Theme.amber : (mouseArea.containsMouse ? Theme.hoverTint : "transparent")
        border.color: Theme.amber
        border.width: Theme.borderWidth
        
        Text {
            anchors.centerIn: parent
            text: control.label
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSizeSmall
            font.letterSpacing: Theme.fontLetterSpacing
            // Use theme logic for text color
            color: control.active ? Theme.bgDark : Theme.amber
            font.bold: control.active
        }

        // Notch
        Rectangle {
            width: 4; height: 4
            color: Theme.bgDark
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            visible: !control.active
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        onClicked: control.clicked()
    }
}