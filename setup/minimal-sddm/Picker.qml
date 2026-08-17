// Modal list popup (users / sessions) on a light card. Click outside or Esc
// closes; ↑ ↓ Enter navigate; ↓ past the last row reaches the footer.
import QtQuick 2.15
import Qt5Compat.GraphicalEffects

Item {
    id: picker
    property string title: ""
    property alias model: list.model
    property alias delegate: list.delegate
    property alias footer: list.footer
    property int currentIndex: -1
    property Item backdrop
    signal closed()

    anchors.fill: parent
    visible: false
    z: 50

    function open() {
        visible = true
        list.currentIndex = Math.max(0, currentIndex)
        list.positionViewAtIndex(list.currentIndex, ListView.Contain)
        list.forceActiveFocus()
    }
    function close() {
        if (!visible) return
        visible = false
        closed()
    }

    Rectangle { anchors.fill: parent; color: alpha(cInk, 0.35) }                        // dim behind
    MouseArea { anchors.fill: parent; hoverEnabled: true; onClicked: picker.close() }   // click outside → close

    Item {
        id: box
        width: 400
        height: Math.min(header.height + list.contentHeight + 12 + 12, picker.height - 160)
        anchors.centerIn: parent
        layer.enabled: true
        layer.effect: DropShadow { transparentBorder: true; radius: 30; samples: 61; color: alpha(cInk, 0.45); verticalOffset: 10 }

        Rectangle { anchors.fill: parent; radius: 20; color: alpha("#ffffff", 0.94); border.width: 1; border.color: alpha("#ffffff", 0.9) }
        MouseArea { anchors.fill: parent }   // swallow clicks inside the box

        Text {
            id: header
            anchors { top: parent.top; left: parent.left; right: parent.right }
            height: 48
            leftPadding: 22
            verticalAlignment: Text.AlignVCenter
            text: picker.title
            color: alpha(cInk, 0.6)
            font { family: uiFont; pixelSize: 12; letterSpacing: 1.5; capitalization: Font.AllUppercase; weight: Font.DemiBold }
        }
        ListView {
            id: list
            anchors { top: header.bottom; left: parent.left; right: parent.right; bottom: parent.bottom
                      leftMargin: 10; rightMargin: 10; bottomMargin: 12 }
            clip: true
            spacing: 2
            boundsBehavior: Flickable.StopAtBounds
            keyNavigationWraps: true
            highlightMoveDuration: 0
            Keys.onEscapePressed: picker.close()
            Keys.onReturnPressed: if (currentItem) currentItem.clicked()
            Keys.onEnterPressed:  if (currentItem) currentItem.clicked()
            Keys.onDownPressed: {
                if (footerItem && currentIndex === count - 1) footerItem.forceActiveFocus()
                else incrementCurrentIndex()
            }
            Keys.onUpPressed: { if (currentIndex > 0) decrementCurrentIndex(); else if (footerItem) footerItem.forceActiveFocus(); else currentIndex = count - 1 }
            Connections {
                target: list.footerItem
                ignoreUnknownSignals: true
                function onEscapePressed() { picker.close() }
                function onBackToList() { list.forceActiveFocus() }
            }
        }
    }
}
