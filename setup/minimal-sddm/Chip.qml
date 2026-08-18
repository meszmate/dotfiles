// Small translucent pill: [icon] label [trailing]. Colours come from Main.qml.
import QtQuick 2.15

Rectangle {
    id: chip
    property string icon: ""
    property string label: ""
    property string trailing: ""
    property color fg: cText
    property color bg: alpha("#ffffff", 0.22)
    property color hoverBg: alpha("#ffffff", 0.40)
    property bool hoverable: true
    property int size: 14
    signal clicked()

    height: size + 15
    radius: height / 2
    width: content.implicitWidth + size + 9
    color: (hoverable && (area.containsMouse || activeFocus)) ? hoverBg : bg
    Behavior on color { ColorAnimation { duration: 100 } }
    border.width: 1
    border.color: activeFocus ? cText : alpha("#ffffff", 0.35)
    activeFocusOnTab: hoverable && visible
    Keys.onReturnPressed: chip.clicked()
    Keys.onEnterPressed:  chip.clicked()
    Keys.onSpacePressed:  chip.clicked()

    Row {
        id: content
        anchors.centerIn: parent
        spacing: 6
        layer.enabled: true
        layer.effect: Halo { size: 0.75 }
        Text { text: chip.icon; visible: chip.icon !== ""; color: chip.fg
               font { family: monoFont; pixelSize: chip.size + 1 } anchors.verticalCenter: parent.verticalCenter }
        Text { text: chip.label; color: chip.fg
               font { family: uiFont; pixelSize: chip.size; weight: Font.Medium } anchors.verticalCenter: parent.verticalCenter }
        Text { text: chip.trailing; visible: chip.trailing !== ""; color: chip.fg
               font { family: monoFont; pixelSize: chip.size } anchors.verticalCenter: parent.verticalCenter }
    }
    MouseArea {
        id: area
        anchors.fill: parent
        enabled: chip.hoverable
        hoverEnabled: chip.hoverable
        cursorShape: chip.hoverable ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: chip.clicked()
    }
}
