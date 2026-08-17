// One row of a Picker: [avatar/icon] title + subtitle, ✓ when selected.
import QtQuick 2.15
import Qt5Compat.GraphicalEffects

Rectangle {
    id: row
    property string icon: ""
    property string picture: ""
    property string title: ""
    property string subtitle: ""
    property bool selected: false
    property bool footer: false        // footer rows live outside the ListView and handle keys themselves
    signal clicked()
    signal escapePressed()
    signal backToList()

    Keys.enabled: footer
    Keys.onReturnPressed: row.clicked()
    Keys.onEnterPressed:  row.clicked()
    Keys.onSpacePressed:  row.clicked()
    Keys.onEscapePressed: row.escapePressed()
    Keys.onUpPressed:     row.backToList()
    Keys.onDownPressed:   row.backToList()

    width: parent ? parent.width : 320
    height: 54
    radius: 12
    color: (area.containsMouse || row.activeFocus) ? alpha(cAccent, 0.12) : "transparent"

    Item {   // avatar
        id: avatar
        width: 36; height: 36
        anchors { left: parent.left; leftMargin: 10; verticalCenter: parent.verticalCenter }
        Rectangle {
            anchors.fill: parent; radius: width / 2
            color: row.selected ? alpha(cAccent, 0.18) : alpha(cInk, 0.07)
            border.width: row.selected ? 2 : 0; border.color: cAccent
        }
        Image {
            id: pic
            anchors.fill: parent; anchors.margins: 2
            source: row.picture; fillMode: Image.PreserveAspectCrop; smooth: true
            visible: false
        }
        Rectangle { id: mask; anchors.fill: pic; radius: width / 2; visible: false }
        OpacityMask { anchors.fill: pic; source: pic; maskSource: mask; visible: pic.status === Image.Ready }
        Text {
            anchors.centerIn: parent
            visible: pic.status !== Image.Ready
            text: row.icon; color: row.selected ? cAccent : alpha(cInk, 0.7)
            font { family: monoFont; pixelSize: 17 }
        }
    }
    Column {
        anchors { left: avatar.right; leftMargin: 12; right: check.left; rightMargin: 8; verticalCenter: parent.verticalCenter }
        spacing: 1
        Text { text: row.title; color: cInk; elide: Text.ElideRight; width: parent.width
               font { family: uiFont; pixelSize: 15; weight: row.selected ? Font.DemiBold : Font.Normal } }
        Text { text: row.subtitle; visible: text !== ""; color: alpha(cInk, 0.55); elide: Text.ElideRight; width: parent.width
               font { family: uiFont; pixelSize: 12 } }
    }
    Text {
        id: check
        anchors { right: parent.right; rightMargin: 14; verticalCenter: parent.verticalCenter }
        text: "\u{F012C}"; visible: row.selected; color: cAccent
        font { family: monoFont; pixelSize: 16 }
    }
    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: row.clicked()
    }
}
