// SPDX-License-Identifier: GPL-3.0-only
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Pane {
  id: root
  required property var handler
  required property var connection
  padding: 6

  function sendData() {
    if (!sendButton.enabled)
      return
    handler.send(input.text)
    input.clear()
  }

  contentItem: ColumnLayout {
    spacing: 4
    RowLayout {
      Layout.fillWidth: true
      ComboBox {
        objectName: "deviceSelector"
        visible: root.handler.multiDeviceMode
        model: root.handler.deviceNames
        onActivated: (index) => root.handler.setCurrentDeviceIndex(index)
        Layout.maximumWidth: 180
      }
      TextField {
        id: input
        objectName: "sendInput"
        Layout.fillWidth: true
        enabled: root.connection.readWrite
        placeholderText: qsTr("Send Data to Device") + "..."
        selectByMouse: true
        onAccepted: root.sendData()
        Keys.onUpPressed: {
          root.handler.historyUp()
          text = root.handler.currentHistoryString
        }
        Keys.onDownPressed: {
          root.handler.historyDown()
          text = root.handler.currentHistoryString
        }
      }
      Button {
        id: sendButton
        objectName: "sendButton"
        text: qsTr("Send")
        enabled: root.connection.readWrite
                 && (input.length > 0 || root.handler.lineEnding !== 0)
                 && (root.handler.dataMode !== 1 || root.handler.validateUserHex(input.text))
        onClicked: root.sendData()
      }
    }
    RowLayout {
      Layout.fillWidth: true
      enabled: root.connection.readWrite
      CheckBox {
        objectName: "hexToggle"
        text: "HEX"
        checked: root.handler.dataMode === 1
        onClicked: root.handler.dataMode = checked ? 1 : 0
      }
      ComboBox {
        objectName: "lineEndingSelector"
        model: root.handler.lineEndings
        currentIndex: root.handler.lineEnding
        onActivated: (index) => root.handler.lineEnding = index
        Layout.fillWidth: true
      }
      ComboBox {
        objectName: "checksumSelector"
        model: root.handler.checksumMethods
        currentIndex: root.handler.checksumMethod
        onActivated: (index) => root.handler.checksumMethod = index
        Layout.fillWidth: true
      }
    }
  }
}
