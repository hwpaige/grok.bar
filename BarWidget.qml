import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui

BarWidget {
  id: root
  moduleName: "io.github.hwpaige.grok-bar"

  readonly property color barForeground: bar ? bar.barForeground : Color.foreground
  readonly property bool opened: panelLoader.item ? panelLoader.item.opened === true : false
  readonly property bool popoutSwitchClosing: panelLoader.item ? panelLoader.item.popoutSwitchClosing === true : false
  readonly property int runningSessions: panelLoader.item ? (panelLoader.item.runningSessions || 0) : 0
  readonly property string grokBadge: panelLoader.item ? panelLoader.item.grokBadge : ""
  readonly property string cursorBadge: panelLoader.item ? panelLoader.item.cursorBadge : ""
  readonly property string summary: panelLoader.item ? panelLoader.item.summary : ""

  readonly property int iconBox: bar ? bar.barSize : Style.bar.sizeHorizontal
  readonly property int markFont: Math.max(Style.bar.iconFont, Math.min(Style.bar.iconFont + 2, iconBox - 6))
  readonly property int markCanvas: Math.max(Style.bar.iconCanvas, Math.min(Style.bar.iconCanvas + 2, iconBox - 2))
  readonly property int cursorMarkSize: Math.max(12, root.markCanvas - 4)

  function open() {
    if (panelLoader.item)
      panelLoader.item.open()
  }

  function close() {
    if (panelLoader.item)
      panelLoader.item.close()
  }

  function toggle() {
    if (panelLoader.item)
      panelLoader.item.toggle()
  }

  function closeForPopoutSwitch() {
    if (panelLoader.item)
      panelLoader.item.closeForPopoutSwitch()
  }

  function refresh() {
    if (panelLoader.item && panelLoader.item.refresh)
      panelLoader.item.refresh()
  }

  function launchNew() {
    if (panelLoader.item)
      panelLoader.item.launchNew()
  }

  function injectPanel() {
    var target = panelLoader.item
    if (!target)
      return
    if ("bar" in target)
      target.bar = root.bar
    if ("settings" in target)
      target.settings = root.settings
    if ("anchorItem" in target)
      target.anchorItem = button
    if ("hostWidget" in target)
      target.hostWidget = root
  }

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  onBarChanged: injectPanel()
  onSettingsChanged: injectPanel()

  Loader {
    id: panelLoader
    active: true
    source: Qt.resolvedUrl("Panel.qml")
    visible: false
    onLoaded: {
      root.injectPanel()
      Qt.callLater(root.injectPanel)
    }
  }

  IpcHandler {
    target: "io.github.hwpaige.grok-bar"

    function open() { root.open() }
    function close() { root.close() }
    function show() { root.open() }
    function hide() { root.close() }
    function toggle() { root.toggle() }
    function refresh() { root.broadcast("refresh") }
    function newSession() { root.launchNew() }
  }

  WidgetButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: "\ue904"
    fontFamily: "omarchy"
    labelVisible: false
    hasVisualContent: true
    horizontalMargin: 0
    fixedWidth: {
      var w = Math.max(16, Math.ceil(glyph.tightWidth) + 2)
      if (grokBadgeLabel.visible)
        w += grokBadgeLabel.implicitWidth + Style.space(2)
      w += Style.space(8) + cursorMark.width
      if (cursorBadgeLabel.visible)
        w += cursorBadgeLabel.implicitWidth + Style.space(2)
      return w
    }
    tooltipText: root.runningSessions > 0 ? root.summary : "New Grok session"
    onPressed: function(b) {
      if (b === Qt.RightButton)
        root.launchNew()
      else
        root.toggle()
    }

    OpticalGlyph {
      id: glyph
      anchors.left: parent.left
      anchors.verticalCenter: parent.verticalCenter
      width: tightWidth
      height: root.markCanvas
      text: "\ue904"
      fontFamily: "omarchy"
      fontSize: root.markFont
      color: button.foreground
    }

    Text {
      id: grokBadgeLabel
      visible: root.grokBadge !== ""
      anchors.left: glyph.right
      anchors.leftMargin: Style.space(2)
      anchors.verticalCenter: parent.verticalCenter
      text: root.grokBadge
      color: root.barForeground
      font.family: root.bar ? root.bar.fontFamily : Style.font.family
      font.pixelSize: Style.font.caption
      font.bold: true
    }

    Item {
      id: cursorMark
      anchors.left: grokBadgeLabel.visible ? grokBadgeLabel.right : glyph.right
      anchors.leftMargin: Style.space(8)
      anchors.verticalCenter: parent.verticalCenter
      width: root.cursorMarkSize
      height: root.cursorMarkSize

      Image {
        id: cursorImage
        anchors.fill: parent
        source: Qt.resolvedUrl("cursor.svg")
        fillMode: Image.PreserveAspectFit
        sourceSize.width: Math.round(width * 2)
        sourceSize.height: Math.round(height * 2)
        visible: false
        layer.enabled: true
      }

      MultiEffect {
        anchors.fill: cursorImage
        source: cursorImage
        colorization: 1.0
        colorizationColor: button.foreground
      }
    }

    Text {
      id: cursorBadgeLabel
      visible: root.cursorBadge !== ""
      anchors.left: cursorMark.right
      anchors.leftMargin: Style.space(2)
      anchors.verticalCenter: parent.verticalCenter
      text: root.cursorBadge
      color: root.barForeground
      font.family: root.bar ? root.bar.fontFamily : Style.font.family
      font.pixelSize: Style.font.caption
      font.bold: true
    }
  }
}
