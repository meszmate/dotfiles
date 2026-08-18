// minimal-sddm — a light, frosted-glass login screen on the sunset-tree artwork
//
//   ┌                                                          clock + date ┐
//   │                              (  M  )       avatar / initial            │
//   │                          ‹  Full Name  ›   click → user picker         │
//   │                   [ Password                        󰈈 ]  glass pill    │
//   │                       󰍹 Hyprland ▾  ·  󰌌 hu       chips             │
//   └ 󰇅 host · F1 help                              󰤄 suspend 󰜉 reboot 󰐥 ┘
//
// Wrong password → the pill flashes red and shakes, the avatar ring turns red,
// the screen gets a short red flash and the chips are replaced by
// "Wrong password · attempt n" until failTimeout runs out (or you type again).
// While PAM checks, an arc spins around the avatar ("Signing in…").
//
// Keys: F1 help · F2/Shift+F2 (or ↑ ↓) user · F3/Shift+F3 session · F4 layout
//       F10 suspend · F11 power off · F12 reboot · Esc close popup / clear field
//       Tab moves between name · password · eye · chips · power buttons

import QtQuick 2.15
import QtQuick.Window 2.15
import Qt5Compat.GraphicalEffects

Rectangle {
    id: root
    width: 1280
    height: 800
    color: "#2b1a3a"

    // ── theme.conf helpers ───────────────────────────────────────────────────
    function cfgStr(k, d)  { var s = config.stringValue(k); return s === "" ? d : s }
    function cfgBool(k, d) { var s = config.stringValue(k); return s === "" ? d : (s === "true" || s === "1" || s === "yes") }
    function cfgNum(k, d)  { var n = parseFloat(config.stringValue(k)); return isNaN(n) ? d : n }
    function alpha(c, a)   { c = Qt.color(c); return Qt.rgba(c.r, c.g, c.b, a) }

    readonly property color cText:   cfgStr("basicTextColor", "#ffffff")
    readonly property color cInk:    cfgStr("colorInk",    "#3b2145")
    readonly property color cAccent: cfgStr("colorAccent", "#8a4fb3")
    readonly property color cRed:    cfgStr("colorRed",    "#d63a5a")
    readonly property color cYellow: cfgStr("colorYellow", "#f2c94c")
    readonly property color cGreen:  cfgStr("colorGreen",  "#3ea982")
    readonly property color cGlass:  cfgStr("passwordInputBackground", "#40ffffff")
    readonly property real  glassBlur: cfgNum("glassBlur", 48)
    readonly property real  textHalo:  cfgNum("textHalo", 0.6)
    readonly property real  cornerShade: cfgNum("cornerShade", 0.4)
    readonly property var   shadeCorners: cfgStr("cornerShadeCorners", "tr,bl,br").split(",").map(function (c) { return c.trim() })

    readonly property string uiFont:   cfgStr("font", "Inter")
    readonly property string monoFont: cfgStr("monoFont", "JetBrainsMono Nerd Font")
    readonly property bool   showRealName: cfgBool("showRealName", true)
    readonly property bool   allowEmpty:   cfgBool("allowEmptyPassword", false)
    readonly property int    failTimeout:  cfgNum("failTimeout", 2500)
    readonly property bool   testMode:     Qt.application.arguments.indexOf("--test-mode") >= 0

    // Nerd Font glyphs (Material Design set)
    readonly property string gCheck:    "\u{F012C}"
    readonly property string gEye:      "\u{F0208}"
    readonly property string gEyeOff:   "\u{F0209}"
    readonly property string gUser:     "\u{F0004}"
    readonly property string gMonitor:  "\u{F0379}"
    readonly property string gKeyboard: "\u{F030C}"
    readonly property string gCaps:     "\u{F0632}"
    readonly property string gHost:     "\u{F01C5}"
    readonly property string gDown:     "\u{F0140}"
    readonly property string gLeft:     "\u{F0141}"
    readonly property string gRight:    "\u{F0142}"
    readonly property string gSleep:    "\u{F0904}"
    readonly property string gReboot:   "\u{F0709}"
    readonly property string gPower:    "\u{F0425}"
    readonly property string gHelp:     "\u{F02D6}"
    readonly property string gAlert:    "\u{F0026}"

    // ── state ────────────────────────────────────────────────────────────────
    readonly property int roleUserName: Qt.UserRole + 1
    readonly property int roleRealName: Qt.UserRole + 2
    readonly property int roleUserIcon: Qt.UserRole + 4
    readonly property int roleSessName: Qt.UserRole + 4

    property int  userIndex:    Math.max(0, userModel.lastIndex)
    property int  sessionIndex: Math.max(0, sessionModel.lastIndex)
    property bool otherUser:    userModel.count === 0    // typing a login name by hand
    property int  attempts:     0
    property string phase:      "idle"                   // idle | busy | fail | ok
    property date now:          new Date()

    function userData(role) { return userModel.count > 0 ? userModel.data(userModel.index(userIndex, 0), role) : "" }
    readonly property string userName:  otherUser ? otherName.text.trim() : (userData(roleUserName) || "")
    readonly property string realName:  otherUser ? (userName || "Other user") : (showRealName ? (userData(roleRealName) || userName) : userName)
    // sddm hands out <FacesDir>/.face.icon when the account has no picture — treat that as "none"
    readonly property string userIcon:  { var i = otherUser ? "" : (userData(roleUserIcon) || ""); return /\/\.face\.icon$/.test(i) ? "" : i }
    readonly property string hostName:  sddm.hostName || ""
    readonly property string sessionName: sessionModel.rowCount() > 0
        ? sessionModel.data(sessionModel.index(sessionIndex, 0), roleSessName) : "no sessions"
    readonly property string layoutName: (keyboard.layouts && keyboard.layouts.length > 0 && keyboard.currentLayout >= 0)
        ? keyboard.layouts[keyboard.currentLayout].shortName : ""

    function cycle(i, n, d) { return n <= 0 ? 0 : (i + d + n) % n }
    function nextUser(d)    { if (userModel.count > 0) { otherUser = false; userIndex = cycle(userIndex, userModel.count, d) } }
    function nextSession(d) { sessionIndex = cycle(sessionIndex, sessionModel.rowCount(), d) }
    function nextLayout()   { if (keyboard.layouts && keyboard.layouts.length > 1) keyboard.currentLayout = cycle(keyboard.currentLayout, keyboard.layouts.length, 1) }
    function closePopups()  { userPicker.close(); sessionPicker.close(); help.visible = false; password.forceActiveFocus() }
    function toast(msg)     { toastText.text = msg; toastTimer.restart() }

    function tryLogin() {
        if (phase === "busy" || phase === "ok") return
        if (userName === "") { if (otherUser) otherName.forceActiveFocus(); else userPicker.open(); return }
        if (password.text === "" && !allowEmpty) { nudge.restart(); return }
        phase = "busy"
        sddm.login(userName, password.text, sessionIndex)
        if (testMode) fakeAuth.restart()   // sddm-greeter --test-mode never answers
    }
    function loginFailed() {
        phase = "fail"; attempts++
        password.text = ""
        failTimer.restart(); shake.restart(); flash.restart()
        password.forceActiveFocus()
    }

    Connections {
        target: sddm
        function onLoginFailed()    { loginFailed() }
        function onLoginSucceeded() { phase = "ok"; failTimer.stop() }
        function onInformationMessage(message) { toast(message) }
    }
    Timer { id: failTimer; interval: failTimeout; onTriggered: { phase = "idle"; password.forceActiveFocus() } }
    Timer { id: fakeAuth; interval: 1100; onTriggered: { if (password.text === "sddm") { phase = "ok" } else loginFailed() } }
    Timer { interval: 1000; running: true; repeat: true; triggeredOnStart: true; onTriggered: now = new Date() }
    Timer { id: toastTimer; interval: 4000 }
    Component.onCompleted: password.forceActiveFocus()

    // ── per-screen frame (UI on the primary screen, wallpaper everywhere) ─────
    Item {
        id: frame
        property variant geometry: screenModel.geometry(screenModel.primary)
        x: geometry.x; y: geometry.y; width: geometry.width; height: geometry.height

        // "Volume Mute" too: laptops whose F-row defaults to media keys send that for F1
        Shortcut { sequences: ["F1", "Ctrl+/", "Volume Mute"]; onActivated: help.visible = !help.visible }
        Shortcut { sequences: ["F2", "Alt+U"];              onActivated: nextUser(1) }
        Shortcut { sequences: ["Shift+F2", "Alt+Ctrl+U"];   onActivated: nextUser(-1) }
        Shortcut { sequences: ["F3", "Alt+S"];              onActivated: nextSession(1) }
        Shortcut { sequences: ["Shift+F3", "Alt+Ctrl+S"];   onActivated: nextSession(-1) }
        Shortcut { sequences: ["F4", "Alt+L"];              onActivated: nextLayout() }
        Shortcut { sequences: ["F10"];                      onActivated: if (sddm.canSuspend)  sddm.suspend() }
        Shortcut { sequences: ["F11"];                      onActivated: if (sddm.canPowerOff) sddm.powerOff() }
        Shortcut { sequences: ["F12"];                      onActivated: if (sddm.canReboot)   sddm.reboot() }

        // ── background ───────────────────────────────────────────────────────
        Item {
            id: background
            anchors.fill: parent
            Rectangle { anchors.fill: parent; color: root.color }
            Image {
                id: wall
                anchors.fill: parent
                source: config.stringValue("background")
                smooth: true
                visible: cfgNum("blurRadius", 0) <= 0
                fillMode: { switch (cfgStr("backgroundFillMode", "aspect")) {
                    case "fill": return Image.Stretch
                    case "tile": return Image.Tile
                    case "pad":  return Image.Pad
                    default:     return Image.PreserveAspectCrop } }
            }
            FastBlur { anchors.fill: wall; source: wall; radius: cfgNum("blurRadius", 0); visible: !wall.visible && wall.status === Image.Ready }
            Rectangle { anchors.fill: parent; color: "#000000"; opacity: cfgNum("dim", 0) }
            // soft ink shades in the corners that hold text (clock, chips, power)
            Repeater {
                model: cornerShade > 0 ? shadeCorners : []
                CornerShade {
                    corner: modelData; strength: cornerShade
                    width: background.width * 0.42; height: background.height * 0.5
                    x: onRight  ? background.width  - width  : 0
                    y: onBottom ? background.height - height : 0
                }
            }
        }
        Rectangle {   // short red flash on a wrong password
            id: flashRect
            anchors.fill: parent
            color: cRed; opacity: 0
            SequentialAnimation {
                id: flash
                NumberAnimation { target: flashRect; property: "opacity"; to: 0.28; duration: 90 }
                NumberAnimation { target: flashRect; property: "opacity"; to: 0;    duration: 700; easing.type: Easing.OutQuad }
            }
        }

        // ── clock (top-right, out of the tree's way) ─────────────────────────
        Column {
            anchors { right: parent.right; top: parent.top; rightMargin: 64; topMargin: 44 }
            spacing: 0
            Text {
                anchors.right: parent.right
                text: Qt.formatTime(now, cfgStr("clockFormat", "HH:mm"))
                color: cText
                font { family: uiFont; pixelSize: 96; weight: Font.Light; letterSpacing: -2 }
                layer.enabled: true
                layer.effect: Halo { size: 2 }
            }
            Text {
                anchors.right: parent.right
                text: Qt.formatDate(now, cfgStr("dateFormat", "dddd, d MMMM"))
                color: cText
                font { family: uiFont; pixelSize: 22; weight: Font.Medium }
                layer.enabled: true
                layer.effect: Halo { size: 1.25 }
            }
        }

        // ── information toast (top-centre) ───────────────────────────────────
        Rectangle {
            anchors { top: parent.top; topMargin: 44; horizontalCenter: parent.horizontalCenter }
            width: toastText.implicitWidth + 44; height: 42; radius: 21
            color: alpha("#ffffff", 0.92)
            visible: toastTimer.running
            Text { id: toastText; anchors.centerIn: parent; color: cInk; font { family: uiFont; pixelSize: 14; weight: Font.Medium } }
        }

        // ── centre: avatar · name · password · chips ─────────────────────────
        Item {
            id: hud
            readonly property real fieldW: Math.round(frame.width * cfgNum("passwordInputWidth", 0.25))
            readonly property real fieldH: cfgNum("passwordInputHeight", 64)
            width: Math.max(fieldW, 520)
            height: avatar.height + 18 + nameRow.height + 22 + fieldH + 16 + hintRow.height
            anchors { horizontalCenter: parent.horizontalCenter; verticalCenter: parent.verticalCenter; verticalCenterOffset: -30 }

            SequentialAnimation {   // wrong password shake
                id: shake
                NumberAnimation { target: field; property: "anchors.horizontalCenterOffset"; to: -16; duration: 50 }
                NumberAnimation { target: field; property: "anchors.horizontalCenterOffset"; to: 14;  duration: 60 }
                NumberAnimation { target: field; property: "anchors.horizontalCenterOffset"; to: -9;  duration: 60 }
                NumberAnimation { target: field; property: "anchors.horizontalCenterOffset"; to: 5;   duration: 50 }
                NumberAnimation { target: field; property: "anchors.horizontalCenterOffset"; to: 0;   duration: 50 }
            }
            SequentialAnimation {   // empty-field nudge
                id: nudge
                NumberAnimation { target: field; property: "anchors.horizontalCenterOffset"; to: -6; duration: 40 }
                NumberAnimation { target: field; property: "anchors.horizontalCenterOffset"; to: 6;  duration: 60 }
                NumberAnimation { target: field; property: "anchors.horizontalCenterOffset"; to: 0;  duration: 40 }
            }

            // avatar: picture or initial, ring shows the state, arc spins while signing in
            Item {
                id: avatar
                width: 104; height: 104
                anchors { top: parent.top; horizontalCenter: parent.horizontalCenter }
                Glass {
                    anchors.fill: parent; radius: width / 2
                    backdrop: background; tint: alpha("#ffffff", 0.30); blur: glassBlur; highlight: false
                    borderColor: alpha("#ffffff", 0.7)
                }
                Image {
                    id: pic
                    anchors.fill: parent; anchors.margins: 3
                    source: userIcon; fillMode: Image.PreserveAspectCrop; smooth: true; visible: false
                }
                Rectangle { id: picMask; anchors.fill: pic; radius: width / 2; visible: false }
                OpacityMask { anchors.fill: pic; source: pic; maskSource: picMask; visible: pic.status === Image.Ready }
                Text {   // initial / state glyph
                    anchors.centerIn: parent
                    visible: pic.status !== Image.Ready || phase === "ok" || phase === "fail"
                    text: phase === "ok" ? gCheck : phase === "fail" ? gAlert
                        : (otherUser && userName === "") ? gUser : (realName || "?").charAt(0).toUpperCase()
                    color: cText
                    font { family: (phase === "ok" || phase === "fail" || (otherUser && userName === "")) ? monoFont : uiFont
                           pixelSize: (phase === "ok" || phase === "fail") ? 48 : 46; weight: Font.DemiBold }
                    layer.enabled: true
                    layer.effect: Halo {}
                }
                Rectangle {   // state ring
                    anchors.fill: parent; radius: width / 2; color: "transparent"
                    border.width: 3
                    border.color: phase === "fail" ? cRed : phase === "ok" ? cGreen : "transparent"
                    Behavior on border.color { ColorAnimation { duration: 160 } }
                }
                Canvas {   // busy arc
                    id: arc
                    anchors.fill: parent; anchors.margins: -6
                    visible: phase === "busy"
                    onPaint: {
                        var ctx = getContext("2d"); ctx.reset()
                        ctx.lineWidth = 3; ctx.strokeStyle = cText; ctx.lineCap = "round"
                        ctx.beginPath(); ctx.arc(width / 2, height / 2, width / 2 - 2, 0, Math.PI * 0.6); ctx.stroke()
                    }
                    RotationAnimation on rotation { from: 0; to: 360; duration: 900; loops: Animation.Infinite; running: arc.visible }
                }
            }

            // ‹ Name ›  — click the name for the picker; Tab + Enter works too
            Item {
                id: nameRow
                anchors { top: avatar.bottom; topMargin: 18; left: parent.left; right: parent.right }
                height: 42
                Text {
                    id: nameText
                    anchors.centerIn: parent
                    text: realName
                    color: cText
                    font { family: uiFont; pixelSize: 30; weight: Font.DemiBold }
                    visible: !otherUser
                    opacity: nameArea.containsMouse ? 0.8 : 1
                    activeFocusOnTab: visible
                    Keys.onReturnPressed: userPicker.open()
                    Keys.onEnterPressed:  userPicker.open()
                    Keys.onSpacePressed:  userPicker.open()
                    Keys.onLeftPressed:   nextUser(-1)
                    Keys.onRightPressed:  nextUser(1)
                    layer.enabled: true
                    layer.effect: Halo { size: 1.25 }
                    MouseArea {
                        id: nameArea
                        anchors.fill: parent; anchors.margins: -8
                        cursorShape: Qt.PointingHandCursor
                        hoverEnabled: true
                        onClicked: userPicker.open()
                    }
                }
                Rectangle {   // keyboard-focus underline (outside the shadow layer)
                    anchors { horizontalCenter: nameText.horizontalCenter; top: nameText.bottom; topMargin: 2 }
                    width: nameText.width; height: 2; radius: 1; color: cText; visible: nameText.activeFocus
                }
                Glass {   // manual username entry ("Other user…")
                    anchors.centerIn: parent
                    width: 300; height: 42; radius: 21
                    visible: otherUser
                    backdrop: background; tint: cGlass; blur: glassBlur
                    borderColor: otherName.activeFocus ? alpha("#ffffff", 0.95) : alpha("#ffffff", 0.5)
                    TextInput {
                        id: otherName
                        anchors { fill: parent; leftMargin: 18; rightMargin: 40 }
                        verticalAlignment: TextInput.AlignVCenter
                        color: cText; font { family: uiFont; pixelSize: 16; weight: Font.Medium }
                        selectionColor: cAccent; selectedTextColor: cText
                        clip: true
                        layer.enabled: true
                        layer.effect: Halo { size: 0.75 }
                        activeFocusOnTab: otherUser
                        onAccepted: password.forceActiveFocus()
                        Keys.onEscapePressed: { if (userModel.count > 0) { otherUser = false; password.forceActiveFocus() } else text = "" }
                        Text { anchors.fill: parent; verticalAlignment: Text.AlignVCenter; text: "Username"; color: alpha(cText, 0.7)
                               font: otherName.font; visible: otherName.text === "" }
                    }
                    Text {   // back to the user list
                        anchors { right: parent.right; rightMargin: 14; verticalCenter: parent.verticalCenter }
                        text: gUser; color: cText; opacity: listBtn.containsMouse ? 1 : 0.7
                        font { family: monoFont; pixelSize: 16 }
                        visible: userModel.count > 0
                        layer.enabled: true
                        layer.effect: Halo { size: 0.75 }
                        MouseArea { id: listBtn; anchors.fill: parent; anchors.margins: -8; hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor; onClicked: userPicker.open() }
                    }
                }
                Text {   // ‹
                    anchors { right: nameText.left; rightMargin: 16; verticalCenter: parent.verticalCenter }
                    text: gLeft; color: cText; opacity: arrowL.containsMouse ? 1 : 0.6
                    font { family: monoFont; pixelSize: 28 }
                    visible: userModel.count > 1 && !otherUser
                    layer.enabled: true
                    layer.effect: Halo {}
                    MouseArea { id: arrowL; anchors.fill: parent; anchors.margins: -10; hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor; onClicked: nextUser(-1) }
                }
                Text {   // ›
                    anchors { left: nameText.right; leftMargin: 16; verticalCenter: parent.verticalCenter }
                    text: gRight; color: cText; opacity: arrowR.containsMouse ? 1 : 0.6
                    font { family: monoFont; pixelSize: 28 }
                    visible: userModel.count > 1 && !otherUser
                    layer.enabled: true
                    layer.effect: Halo {}
                    MouseArea { id: arrowR; anchors.fill: parent; anchors.margins: -10; hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor; onClicked: nextUser(1) }
                }
            }

            // password pill
            Glass {
                id: field
                width: hud.fieldW; height: hud.fieldH
                radius: cfgNum("passwordInputRadius", 32)
                anchors { top: nameRow.bottom; topMargin: 22; horizontalCenter: parent.horizontalCenter }
                backdrop: background; blur: glassBlur
                tint: phase === "fail" ? alpha(cRed, 0.72) : phase === "busy" ? alpha(cYellow, 0.35) : phase === "ok" ? alpha(cGreen, 0.5)
                    : keyboard.capsLock ? alpha(cYellow, 0.3) : cGlass
                borderColor: (password.activeFocus || phase !== "idle") ? alpha("#ffffff", 0.9) : alpha("#ffffff", 0.5)

                TextInput {
                    id: password
                    anchors { fill: parent; leftMargin: 26; rightMargin: 60 }
                    verticalAlignment: TextInput.AlignVCenter
                    echoMode: (cfgBool("passwordMask", true) && !reveal.on) ? TextInput.Password : TextInput.Normal
                    passwordCharacter: cfgStr("passwordCharacter", "●")
                    color: cText
                    font { family: uiFont; pixelSize: cfgNum("passwordFontSize", 17); weight: Font.Medium
                           letterSpacing: echoMode === TextInput.Password ? 3 : 0 }
                    selectionColor: cAccent; selectedTextColor: cText
                    cursorVisible: activeFocus && text !== ""
                    clip: true
                    opacity: phase === "idle" ? 1 : 0     // the state text takes over while busy / denied
                    readOnly: phase === "busy" || phase === "ok"   // (not `enabled`: that would drop keyboard focus)
                    activeFocusOnTab: true
                    onAccepted: tryLogin()
                    Keys.onEscapePressed: { if (userPicker.visible || sessionPicker.visible || help.visible) closePopups(); else text = "" }
                    Keys.onUpPressed:   nextUser(-1)
                    Keys.onDownPressed: nextUser(1)
                    onTextEdited: if (phase === "fail") { failTimer.stop(); phase = "idle" }
                    layer.enabled: true
                    layer.effect: Halo { size: 0.75 }
                }
                Text {   // placeholder / state text
                    anchors { fill: parent; leftMargin: 26; rightMargin: 60 }
                    verticalAlignment: Text.AlignVCenter
                    visible: password.text === "" || phase !== "idle"
                    layer.enabled: true
                    layer.effect: Halo { size: 0.75 }
                    font { family: uiFont; pixelSize: 16; weight: phase === "idle" ? Font.Normal : Font.DemiBold }
                    text: phase === "busy" ? "Signing in…"
                        : phase === "fail" ? "Wrong password"
                        : phase === "ok"   ? "Welcome!"
                        : "Password"
                    color: phase === "idle" ? alpha(cText, 0.85) : cText
                }
                Text {   // show / hide password
                    id: reveal
                    property bool on: false
                    anchors { right: parent.right; rightMargin: 22; verticalCenter: parent.verticalCenter }
                    text: on ? gEyeOff : gEye
                    color: cText
                    opacity: eyeArea.containsMouse || on || activeFocus ? 1 : 0.6
                    font { family: monoFont; pixelSize: 20 }
                    layer.enabled: true
                    layer.effect: Halo { size: 0.75 }
                    activeFocusOnTab: true
                    Keys.onReturnPressed: on = !on
                    Keys.onEnterPressed:  on = !on
                    Keys.onSpacePressed:  on = !on
                    MouseArea { id: eyeArea; anchors.fill: parent; anchors.margins: -8; hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor; onClicked: { reveal.on = !reveal.on; password.forceActiveFocus() } }
                }
            }

            // under the field: session · layout chips, or the state message
            Item {
                id: hintRow
                anchors { top: field.bottom; topMargin: 16; left: parent.left; right: parent.right }
                height: 30
                Row {
                    anchors.centerIn: parent
                    spacing: 10
                    visible: phase === "idle" && !keyboard.capsLock
                    Chip { icon: gMonitor; label: sessionName; trailing: sessionModel.rowCount() > 1 ? gDown : ""
                           onClicked: sessionPicker.open(); anchors.verticalCenter: parent.verticalCenter }
                    Chip { icon: gKeyboard; label: layoutName; visible: layoutName !== ""
                           hoverable: keyboard.layouts && keyboard.layouts.length > 1
                           onClicked: nextLayout(); anchors.verticalCenter: parent.verticalCenter }
                }
                Chip {   // state message
                    anchors.centerIn: parent
                    visible: !(phase === "idle" && !keyboard.capsLock)
                    hoverable: false
                    icon: phase === "fail" ? gAlert : phase === "ok" ? gCheck : phase === "busy" ? "" : gCaps
                    label: phase === "fail" ? "Wrong password · attempt " + attempts
                         : phase === "busy" ? "Checking your password…"
                         : phase === "ok"   ? "Signed in — starting " + sessionName
                         : "Caps Lock is on"
                    bg: phase === "fail" ? alpha(cRed, 0.85) : phase === "ok" ? alpha(cGreen, 0.85)
                      : phase === "busy" ? alpha("#ffffff", 0.22) : alpha(cYellow, 0.9)
                    fg: (phase === "idle" && keyboard.capsLock) ? cInk : cText
                }
            }
        }

        // ── bottom bar ───────────────────────────────────────────────────────
        Row {
            anchors { left: parent.left; bottom: parent.bottom; leftMargin: 40; bottomMargin: 34 }
            spacing: 10
            Chip { icon: gHost; label: hostName; visible: hostName !== ""; hoverable: false; anchors.verticalCenter: parent.verticalCenter }
            Chip { icon: gHelp; label: "F1 help"; onClicked: help.visible = !help.visible; anchors.verticalCenter: parent.verticalCenter }
        }
        Row {
            anchors { right: parent.right; bottom: parent.bottom; rightMargin: 40; bottomMargin: 26 }
            spacing: 12
            PowerButton { icon: gSleep;  label: "Suspend";   visible: sddm.canSuspend  || testMode; onClicked: sddm.suspend() }
            PowerButton { icon: gReboot; label: "Restart";   visible: sddm.canReboot   || testMode; onClicked: sddm.reboot() }
            PowerButton { icon: gPower;  label: "Power off"; visible: sddm.canPowerOff || testMode; danger: true; onClicked: sddm.powerOff() }
        }

        // ── popups ───────────────────────────────────────────────────────────
        Picker {
            id: userPicker
            title: "Switch user"
            model: userModel
            currentIndex: otherUser ? -1 : userIndex
            onClosed: password.forceActiveFocus()
            delegate: PickerRow {
                icon: gUser; picture: /\/\.face\.icon$/.test(model.icon || "") ? "" : model.icon   // skip sddm's stock face
                title: showRealName ? (model.realName || model.name) : model.name
                subtitle: showRealName ? model.name : (model.realName || "")
                selected: !otherUser && index === userIndex
                onClicked: { otherUser = false; userIndex = index; userPicker.close() }
            }
            footer: PickerRow {
                footer: true
                icon: gKeyboard; title: "Other user…"; subtitle: "type a login name"
                selected: otherUser
                onClicked: { otherUser = true; userPicker.close(); otherName.forceActiveFocus() }
            }
        }
        Picker {
            id: sessionPicker
            title: "Session"
            model: sessionModel
            currentIndex: sessionIndex
            onClosed: password.forceActiveFocus()
            delegate: PickerRow {
                icon: gMonitor
                title: model.name; subtitle: model.comment || model.file
                selected: index === sessionIndex
                onClicked: { sessionIndex = index; sessionPicker.close() }
            }
        }

        // ── help overlay ─────────────────────────────────────────────────────
        MouseArea {
            id: help
            anchors.fill: parent; visible: false; z: 60
            onClicked: visible = false
            Rectangle { anchors.fill: parent; color: alpha(cInk, 0.35) }
            Item {
                anchors.centerIn: parent
                width: helpText.implicitWidth + 72; height: helpText.implicitHeight + 64
                layer.enabled: true
                layer.effect: DropShadow { transparentBorder: true; radius: 30; samples: 61; color: alpha(cInk, 0.45); verticalOffset: 10 }
                Rectangle { anchors.fill: parent; radius: 20; color: alpha("#ffffff", 0.94) }
                Row {
                    id: helpText
                    anchors.centerIn: parent
                    spacing: 32
                    property var rows: [
                        ["Keys", ""],
                        ["F1 / Ctrl+/",       "this help   (Fn+F1 if the F-row is in media mode)"],
                        ["F2 / Shift+F2",     "next / previous user   (↑ ↓ in the password field)"],
                        ["F3 / Shift+F3",     "next / previous session"],
                        ["F4",                "next keyboard layout"],
                        ["Tab",               "move between name · password · eye · session · power buttons"],
                        ["Enter / Space",     "activate the focused control (name → user list)"],
                        ["F10 / F11 / F12",   "suspend / power off / restart"],
                        ["Esc",               "close popup · clear password"],
                        [" ", " "],
                        ["Mouse", ""],
                        ["name",              "click → pick a user, or type another login name"],
                        ["‹ ›",               "previous / next user"],
                        ["session · layout",  "click → pick a session · cycle the layout"],
                        ["eye",               "show / hide the password"]
                    ]
                    Repeater {   // two Columns so headers and blank rows keep their line
                        model: 2
                        Column {
                            readonly property int col: index
                            spacing: 7
                            Repeater {
                                model: helpText.rows.length
                                Text {
                                    readonly property bool head: helpText.rows[index][1] === ""
                                    height: 20
                                    text: helpText.rows[index][col] || " "     // never empty: positioners skip zero-size items
                                    color: col === 0 ? (head ? cAccent : cInk) : alpha(cInk, 0.65)
                                    font { family: col === 0 && !head ? monoFont : uiFont; pixelSize: 14; weight: head ? Font.Bold : Font.Normal }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    Loader {
        active: cfgBool("hideCursor", false)
        anchors.fill: parent
        sourceComponent: MouseArea { enabled: false; cursorShape: Qt.BlankCursor }
    }
}
