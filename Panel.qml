import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui
import "Model.js" as Model

Panel {
  id: root
  moduleName: "io.github.hwpaige.grok-bar"
  ipcTarget: "io.github.hwpaige.grok-bar"
  manageIpc: false

  property var anchorItem: null
  property var hostWidget: null
  readonly property var barIdentity: hostWidget || root

  property var snapshot: Model.emptyState()
  property int cursorIndex: 0
  property bool cursorActive: false

  readonly property int runningSessions: snapshot.runningSessions || 0
  readonly property int runningAgents: snapshot.runningAgents || 0
  readonly property var sessions: snapshot.sessions || []
  readonly property var grokSessions: snapshot.grokSessions || []
  readonly property var cursorSessions: snapshot.cursorSessions || []
  readonly property string grokBadge: Model.badgeText(grokSessions.length)
  readonly property string cursorBadge: Model.badgeText(cursorSessions.length)
  readonly property string summary: Model.summaryLine(snapshot)
  readonly property int rowCount: grokSessions.length + cursorSessions.length + 1

  function refresh() {
    if (!listProc.running)
      listProc.running = true
  }

  function launchNew() {
    if (root.bar)
      root.bar.run("omarchy-launch-grok --new")
    root.close()
  }

  function focusSession(sessionId) {
    if (!sessionId)
      return
    if (root.bar)
      root.bar.run("omarchy-launch-grok --focus " + sessionId)
    root.close()
  }

  function trashSession(sessionId) {
    if (!sessionId || trashProc.running)
      return
    trashProc.command = ["omarchy-grok-sessions", "--trash", sessionId]
    trashProc.running = true
  }

  function trashSelected() {
    if (cursorIndex <= 0)
      return
    if (sessions[cursorIndex - 1])
      trashSession(sessions[cursorIndex - 1].id)
  }

  function activateCursor() {
    if (cursorIndex <= 0)
      launchNew()
    else if (sessions[cursorIndex - 1])
      focusSession(sessions[cursorIndex - 1].id)
  }

  function moveCursor(delta) {
    cursorActive = true
    var next = cursorIndex + delta
    if (next < 0)
      next = 0
    if (next >= rowCount)
      next = rowCount - 1
    cursorIndex = next
  }

  function switchPanel(direction) {
    if (root.bar && typeof root.bar.switchPanelFrom === "function")
      return root.bar.switchPanelFrom(root.barIdentity, direction)
    return false
  }

  Component.onCompleted: refresh()
  onOpenedChanged: if (opened) {
    cursorIndex = 0
    cursorActive = false
    refresh()
  }

  Process {
    id: listProc
    command: ["omarchy-grok-sessions"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.snapshot = Model.parseSessions(text)
    }
  }

  Process {
    id: trashProc
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.refresh()
    }
  }

  FileView {
    path: Quickshell.env("HOME") + "/.grok/active_sessions.json"
    watchChanges: true
    printErrors: false
    onFileChanged: root.refresh()
  }

  Timer {
    interval: 3000
    running: true
    repeat: true
    onTriggered: root.refresh()
  }

  KeyboardPanel {
    id: panel
    anchorItem: root.anchorItem
    owner: root.barIdentity
    bar: root.bar
    open: root.opened
    focusTarget: keyCatcher
    contentWidth: panel.fittedContentWidth(Style.space(360))
    contentHeight: panel.fittedContentHeight(column.implicitHeight)

    PanelKeyCatcher {
      id: keyCatcher
      anchors.fill: parent
      onMoveRequested: function(dx, dy) {
        if (dy !== 0)
          root.moveCursor(dy)
      }
      onActivateRequested: root.activateCursor()
      onCloseRequested: root.close()
      onDeleteRequested: root.trashSelected()
      onTabRequested: function(direction) { root.switchPanel(direction) }

      Column {
        id: column
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        spacing: Style.space(10)

        Row {
          width: parent.width
          spacing: Style.space(10)

          Text {
            text: "\ue904"
            font.family: "omarchy"
            font.pixelSize: Style.font.heading
            color: root.barForeground
            anchors.verticalCenter: parent.verticalCenter
          }

          Column {
            anchors.verticalCenter: parent.verticalCenter
            spacing: Style.space(2)
            width: parent.width - Style.space(40)

            Text {
              text: "Grok"
              color: root.barForeground
              font.family: root.bar ? root.bar.fontFamily : Style.font.family
              font.pixelSize: Style.font.title
              font.bold: true
            }

            Text {
              text: root.summary
              color: Qt.darker(root.barForeground, 1.4)
              font.family: root.bar ? root.bar.fontFamily : Style.font.family
              font.pixelSize: Style.font.caption
              font.bold: true
            }
          }
        }

        Button {
          width: parent.width
          text: "New session"
          iconText: "+"
          leftAlign: true
          foreground: root.barForeground
          fontFamily: root.bar ? root.bar.fontFamily : Style.font.family
          selected: root.cursorActive && root.cursorIndex === 0
          onClicked: root.launchNew()
          onHovered: function(h) {
            if (h) {
              root.cursorActive = true
              root.cursorIndex = 0
            }
          }
        }

        PanelSeparator {
          visible: root.grokSessions.length > 0 || root.cursorSessions.length > 0
          foreground: root.barForeground
        }

        PanelSectionHeader {
          visible: root.grokSessions.length > 0
          text: "GROK"
          foreground: root.barForeground
          fontFamily: root.bar ? root.bar.fontFamily : Style.font.family
        }

        Repeater {
          model: root.grokSessions

          SessionRow {
            required property var modelData
            required property int index
            width: column.width
            session: modelData
            selected: root.cursorActive && root.cursorIndex === index + 1
            onActivated: root.focusSession(modelData.id)
            onTrashed: root.trashSession(modelData.id)
            onHoveredChanged: if (hovered) {
              root.cursorActive = true
              root.cursorIndex = index + 1
            }
          }
        }

        PanelSeparator {
          visible: root.grokSessions.length > 0 && root.cursorSessions.length > 0
          foreground: root.barForeground
        }

        PanelSectionHeader {
          visible: root.cursorSessions.length > 0
          text: "CURSOR"
          foreground: root.barForeground
          fontFamily: root.bar ? root.bar.fontFamily : Style.font.family
        }

        Repeater {
          model: root.cursorSessions

          SessionRow {
            required property var modelData
            required property int index
            width: column.width
            session: modelData
            selected: root.cursorActive && root.cursorIndex === index + 1 + root.grokSessions.length
            onActivated: root.focusSession(modelData.id)
            onTrashed: root.trashSession(modelData.id)
            onHoveredChanged: if (hovered) {
              root.cursorActive = true
              root.cursorIndex = index + 1 + root.grokSessions.length
            }
          }
        }

        Text {
          visible: root.grokSessions.length === 0 && root.cursorSessions.length === 0
          width: parent.width
          text: "No Grok or Cursor sessions"
          color: Qt.darker(root.barForeground, 1.45)
          font.family: root.bar ? root.bar.fontFamily : Style.font.family
          font.pixelSize: Style.font.bodySmall
        }
      }
    }
  }

  component SessionRow: Item {
    id: rowRoot

    property var session: ({})
    property bool selected: false
    property bool hovered: mouse.containsMouse
    signal activated()
    signal trashed()

    implicitHeight: labels.implicitHeight + Style.space(14)

    Rectangle {
      anchors.fill: parent
      radius: Style.cornerRadius
      color: rowRoot.selected || rowRoot.hovered
        ? (root.bar ? Style.hoverFillFor(root.barForeground, Color.accent) : "#22ffffff")
        : "transparent"
    }

    Row {
      anchors.fill: parent
      anchors.leftMargin: Style.space(10)
      anchors.rightMargin: Style.space(10)
      spacing: Style.space(10)

      Rectangle {
        width: 10
        height: 10
        radius: 5
        anchors.verticalCenter: parent.verticalCenter
        color: Model.statusColor(
          rowRoot.session.status,
          root.barForeground,
          root.bar ? root.bar.urgent : "#e5534b"
        )
        border.width: 1
        border.color: Qt.rgba(root.barForeground.r, root.barForeground.g, root.barForeground.b, 0.35)
      }

      Column {
        id: labels
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width - Style.space(28) - trashBtn.size - Style.space(6)
        spacing: 2

        Item {
          width: parent.width
          height: titleLabel.implicitHeight

          Text {
            id: titleLabel
            anchors.left: parent.left
            anchors.right: percentLabel.visible ? percentLabel.left : parent.right
            anchors.rightMargin: percentLabel.visible ? Style.space(8) : 0
            text: rowRoot.session.title || rowRoot.session.id || ""
            elide: Text.ElideRight
            color: root.barForeground
            font.family: root.bar ? root.bar.fontFamily : Style.font.family
            font.pixelSize: Style.font.body
          }

          Text {
            id: percentLabel
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            visible: Model.contextPercentLabel(rowRoot.session) !== ""
            text: Model.contextPercentLabel(rowRoot.session)
            color: Model.contextColor(
              Model.contextPercent(rowRoot.session),
              root.barForeground,
              root.bar ? root.bar.urgent : "#e5534b"
            )
            font.family: root.bar ? root.bar.fontFamily : Style.font.family
            font.pixelSize: Style.font.caption
            font.bold: true
          }
        }

        Text {
          width: parent.width
          text: Model.sessionDetail(rowRoot.session)
          elide: Text.ElideRight
          color: Qt.darker(root.barForeground, 1.45)
          font.family: root.bar ? root.bar.fontFamily : Style.font.family
          font.pixelSize: Style.font.caption
        }

        Rectangle {
          visible: percentLabel.visible
          width: parent.width
          height: 3
          radius: 1.5
          color: Qt.rgba(root.barForeground.r, root.barForeground.g, root.barForeground.b, 0.16)

          Rectangle {
            width: Math.max(0, Math.min(parent.width, parent.width * Model.contextPercent(rowRoot.session) / 100))
            height: parent.height
            radius: parent.radius
            color: Model.contextColor(
              Model.contextPercent(rowRoot.session),
              root.barForeground,
              root.bar ? root.bar.urgent : "#e5534b"
            )
          }
        }
      }
    }

    MouseArea {
      id: mouse
      anchors.fill: parent
      anchors.rightMargin: trashBtn.width + Style.space(4)
      hoverEnabled: true
      cursorShape: Qt.PointingHandCursor
      onClicked: rowRoot.activated()
    }

    PanelActionButton {
      id: trashBtn
      anchors.right: parent.right
      anchors.rightMargin: Style.space(6)
      anchors.verticalCenter: parent.verticalCenter
      visible: rowRoot.hovered || rowRoot.selected
      iconText: "󰆴"
      tooltipText: "Trash session"
      foreground: root.barForeground
      hoverColor: root.bar ? root.bar.urgent : "#e5534b"
      fontFamily: root.bar ? root.bar.fontFamily : Style.font.family
      onClicked: rowRoot.trashed()
    }
  }
}
