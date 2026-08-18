// Translucent round button that slides its label out on hover / focus.
import QtQuick 2.15

Item {
    id: btn
    property string icon: ""
    property string label: ""
    property bool danger: false
    signal clicked()

    readonly property bool hot: area.containsMouse || activeFocus
    activeFocusOnTab: visible
    Keys.onReturnPressed: btn.clicked()
    Keys.onEnterPressed:  btn.clicked()
    Keys.onSpacePressed:  btn.clicked()

    width: hot ? 46 + text.implicitWidth + 16 : 46
    height: 46
    Behavior on width { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }

    Rectangle {
        anchors.fill: parent
        radius: 23
        color: hot ? (danger ? alpha(cRed, 0.75) : alpha("#ffffff", 0.45)) : alpha("#ffffff", 0.22)
        border.width: 1
        border.color: hot ? alpha("#ffffff", 0.9) : alpha("#ffffff", 0.35)
        Behavior on color { ColorAnimation { duration: 140 } }
    }
    Item {   // fixed round slot; the glyph is centred in it whatever its advance width
        id: glyph
        width: 46; height: 46
        Text {
            anchors { centerIn: parent; verticalCenterOffset: -1 }
            text: btn.icon
            color: cText
            font { family: monoFont; pixelSize: 20 }
            layer.enabled: true
            layer.effect: Halo { size: 0.75 }
        }
    }
    Text {
        id: text
        anchors { left: glyph.right; leftMargin: 2; verticalCenter: parent.verticalCenter }
        text: btn.label
        color: cText
        opacity: hot ? 1 : 0
        visible: opacity > 0
        Behavior on opacity { NumberAnimation { duration: 140 } }
        font { family: uiFont; pixelSize: 14; weight: Font.Medium }
        layer.enabled: true
        layer.effect: Halo { size: 0.75 }
    }
    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: btn.clicked()
    }
}
