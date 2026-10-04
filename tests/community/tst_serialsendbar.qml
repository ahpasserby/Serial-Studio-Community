// SPDX-License-Identifier: GPL-3.0-only
import QtQuick
import QtTest
import "../../app/qml/Widgets" as Widgets

TestCase {
  name: "SerialSendBar"
  visible: true
  width: 640
  height: 160
  when: windowShown
  QtObject {
    id: connection
    property bool readWrite: true
  }
  QtObject {
    id: handler
    property bool multiDeviceMode: false
    property var deviceNames: ["Virtual UART"]
    property int dataMode: 0
    property int lineEnding: 0
    property int checksumMethod: 0
    property var lineEndings: ["No Line Ending", "LF"]
    property var checksumMethods: ["No Checksum", "CRC"]
    property string sent: ""
    function send(value) { sent = value }
    function validateUserHex(value) { return /^(?:[0-9a-fA-F]{2}\s*)*$/.test(value) }
  }
  Widgets.SerialSendBar {
    id: bar
    width: parent.width
    handler: handler
    connection: connection
  }
  function init() {
    connection.readWrite = true
    handler.dataMode = 0
    handler.lineEnding = 0
    handler.sent = ""
    findChild(bar, "sendInput").text = ""
  }
  function test_send_button() {
    var field = findChild(bar, "sendInput")
    var button = findChild(bar, "sendButton")
    verify(!button.enabled)
    field.text = "po=0.1#"
    mouseClick(button)
    compare(handler.sent, "po=0.1#")
    compare(field.text, "")
  }
  function test_enter_and_disconnected() {
    var field = findChild(bar, "sendInput")
    field.text = "io=0#"
    field.forceActiveFocus()
    keyClick(Qt.Key_Return)
    compare(handler.sent, "io=0#")
    handler.sent = ""
    field.text = "do=0#"
    connection.readWrite = false
    bar.sendData()
    compare(handler.sent, "")
  }
  function test_hex() {
    mouseClick(findChild(bar, "hexToggle"))
    compare(handler.dataMode, 1)
    findChild(bar, "sendInput").text = "GG"
    verify(!findChild(bar, "sendButton").enabled)
    findChild(bar, "sendInput").text = "41 42 00 FF"
    mouseClick(findChild(bar, "sendButton"))
    compare(handler.sent, "41 42 00 FF")
  }
  function test_settings() {
    findChild(bar, "lineEndingSelector").activated(1)
    compare(handler.lineEnding, 1)
    findChild(bar, "checksumSelector").activated(1)
    compare(handler.checksumMethod, 1)
  }
}
