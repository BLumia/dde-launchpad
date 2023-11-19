// SPDX-FileCopyrightText: 2023 UnionTech Software Technology Co., Ltd.
//
// SPDX-License-Identifier: GPL-3.0-or-later

//import QtCore
import QtQml.Models 2.15
import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15
import QtQuick.Window 2.15
import org.deepin.dtk 1.0
import org.deepin.vendored 1.0

import org.deepin.launchpad 1.0

Control {
    id: baseLayer
    visible: true
    anchors.fill: parent
    focus: true
    objectName: "FullscreenFrame-BaseLayer"

    leftPadding: (DesktopIntegration.dockPosition === Qt.LeftArrow ? DesktopIntegration.dockGeometry.width : 0) + 20
    rightPadding: (DesktopIntegration.dockPosition === Qt.RightArrow ? DesktopIntegration.dockGeometry.width : 0) + 20
    topPadding: (DesktopIntegration.dockPosition === Qt.UpArrow ? DesktopIntegration.dockGeometry.height : 0) + 20
    bottomPadding: (DesktopIntegration.dockPosition === Qt.DownArrow ? DesktopIntegration.dockGeometry.height : 0) + 20

    Timer {
        id: flipPageDelay
        interval: 400
        repeat: false
    }

    background: Image {
        source: DesktopIntegration.backgroundUrl

        Rectangle {
            anchors.fill: parent
            color: Qt.rgba(0, 0, 0, 0.25)

            MouseArea {
                anchors.fill: parent
                scrollGestureEnabled: false
                onClicked: {
                    if (!DebugHelper.avoidHideWindow) {
                        LauncherController.visible = false
                    }
                }
                // TODO: this might not be the correct way to handle wheel
                onWheel: {
                    if (flipPageDelay.running) return
                    let xDelta = wheel.angleDelta.x / 8
                    let yDelta = wheel.angleDelta.y / 8
                    let toPage = 0; // -1 prev, +1 next, 0 don't change
                    if (yDelta !== 0) {
                        toPage = (yDelta > 0) ? -1 : 1
                    } else if (xDelta !== 0) {
                        toPage = (xDelta > 0) ? 1 : -1
                    }
                    let curPage = indicator.currentIndex + toPage
                    if (curPage >= 0 && curPage < indicator.count) {
                        flipPageDelay.start()
                        indicator.currentIndex = curPage
                    }
                }
            }
        }
    }

    contentItem: ColumnLayout {

        Control {
            Layout.fillWidth: true
            Layout.fillHeight: false

            contentItem: Rectangle {
                id: fullscreenHeader
                implicitHeight: exitFullscreenBtn.height
                color: "transparent"

                ToolButton {
                    id: exitFullscreenBtn

                    Accessible.name: "Exit fullscreen"

                    anchors.right: fullscreenHeader.right

                    ColorSelector.family: Palette.CrystalColor

                    icon.name: "launcher_exit_fullscreen"
                    onClicked: {
                        LauncherController.currentFrame = "WindowedFrame"
                    }
                }

                PageIndicator {
                    id: indicator

                    anchors.centerIn: parent
        //            visible: pages.visible
                    count: searchResultGridViewContainer.visible ? 1 : pages.count
                    currentIndex: searchResultGridViewContainer.visible ? 1 : pages.currentIndex
                    interactive: true
                }
            }
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            SwipeView {
                id: pages

                anchors.fill: parent
                visible: searchEdit.text === ""

                currentIndex: indicator.currentIndex

                Repeater {
                    model: MultipageProxyModel.pageCount(0) // FIXME: should be a property?

                    Loader {
                        active: SwipeView.isCurrentItem || SwipeView.isNextItem || SwipeView.isPreviousItem
                        id: gridViewLoader
                        objectName: "Main GridView Loader"

                        sourceComponent: Rectangle {
                            color: "transparent"

                            property var grids: gridViewContainer

                            MultipageSortFilterProxyModel {
                                id: proxyModel
                                sourceModel: MultipageProxyModel
                                pageId: modelData
                                folderId: 0
                            }

                            GridViewContainer {
                                id: gridViewContainer
                                anchors.fill: parent
                                rows: 4
                                columns: 7
                                model: proxyModel
                                padding: 10
                                interactive: false
                                focus: true
                                activeGridViewFocusOnTab: gridViewLoader.SwipeView.isCurrentItem
                                delegate: IconItemDelegate {
                                    dndEnabled: true
                                    Drag.mimeData: {
                                        "application/x-dde-launcher-dnd-fullscreen": ("0," + modelData + "," + index), // "folder,page,index"
                                        "application/x-dde-launcher-dnd-desktopId": model.desktopId
                                    }
                                    visible: model.desktopId !== dropArea.currentDraggedDesktopId
                                    iconSource: "image://app-icon/" + iconName
                                    width: gridViewContainer.cellSize
                                    height: gridViewContainer.cellSize
                                    icons: folderIcons
                                    padding: 5
                                    onItemClicked: {
                                        launchApp(desktopId)
                                    }
                                    onFolderClicked: {
                                        let idStr = model.desktopId
                                        let idNum = Number(idStr.replace("internal/folders/", ""))
                                        folderLoader.currentFolderId = idNum
                                        folderGridViewPopup.open()
                                        folderLoader.folderName = model.display
                                        console.log("open folder id:" + idNum)
                                    }
                                    onMenuTriggered: {
                                        showContextMenu(this, model, folderIcons, false, true)
                                    }
                                }
                            }
                        }

                        // Since SwipeView will catch the mouse click event so we need to also do it here...
                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                if (!DebugHelper.avoidHideWindow) {
                                    LauncherController.visible = false
                                }
                            }
                        }
                    }
                }
            }

            DelegateModel {
                id: delegateSearchResultModel
                model: SearchFilterProxyModel
                delegate: IconItemDelegate {
                    iconSource: "image://app-icon/" + iconName
                    width: searchResultGridViewContainer.cellSize
                    height: searchResultGridViewContainer.cellSize
                    padding: 5
                    onItemClicked: {
                        launchApp(desktopId)
                    }
                    onMenuTriggered: {
                        showContextMenu(this, model, false, false, true)
                    }
                }
            }

            GridViewContainer {
                id: searchResultGridViewContainer

                anchors.fill: parent
                visible: searchEdit.text !== ""
                activeFocusOnTab: visible && gridViewFocus
                focus: true

                rows: 4
                columns: 7
                placeholderIcon: "search_no_result"
                placeholderText: qsTranslate("WindowedFrame", "No search results")
                placeholderIconSize: 256
                model: delegateSearchResultModel
                padding: 10
                interactive: false
            }
        }


        SearchEdit {
            id: searchEdit

            Layout.alignment: Qt.AlignHCenter
            width: (parent.width / 2) > 400 ? 400 : (parent.width / 2)

            placeholder: qsTranslate("WindowedFrame", "Search")
            onTextChanged: {
//            console.log(text)
                SearchFilterProxyModel.setFilterRegularExpression(text)
            }
        }
    }

    DropArea {
        id: dropArea
        anchors.fill: parent

        property string currentDraggedDesktopId: ""

        onPositionChanged: {
            currentDraggedDesktopId = drag.getDataAsString("application/x-dde-launcher-dnd-desktopId")
            dndDebug.text = drag.x + "," + drag.y + "." + drag.getDataAsString("application/x-dde-launcher-dnd-desktopId")
        }

        onDropped: {
            let curGridView = pages.currentItem.item.grids
            let curPoint = curGridView.mapFromItem(dropArea, drag.x, drag.y)
            let curItem = curGridView.itemAt(curPoint.x, curPoint.y)
            if (curItem) {
                // drop on the left, center or right?
                let itemX = curGridView.mapFromItem(curItem.parent, curItem.x, curItem.y).x
                let itemWidth = curItem.width
                let sideOpPadding = itemWidth / 4
                let op = 0
                if (curPoint.x < (itemX + sideOpPadding)) {
                    op = -1
                } else if (curPoint.x > (itemX + curItem.width - sideOpPadding)) {
                    op = 1
                }

                let targetItemInfo = curItem.Drag.mimeData["application/x-dde-launcher-dnd-desktopId"]
                dndDebug.text = "drag " + currentDraggedDesktopId + " onto " + targetItemInfo + " with " + op
                MultipageProxyModel.commitDndOperation(currentDraggedDesktopId, targetItemInfo, op)
            }
            currentDraggedDesktopId = ""
        }

        Label {
            id: dndDebug
            visible: DebugHelper.qtDebugEnabled
            text: "DnD DEBUG"
        }
    }

    Popup {
        id: folderGridViewPopup

        focus: true
//        visible: true

        property int cs: searchResultGridViewContainer.cellSize // * 5 / 4
//        anchors.centerIn: parent // seems dtkdeclarative's Popup doesn't have anchors.centerIn

        width: cs * 4 + 20 /* padding */
        height: cs * 3 + 130 /* title height*/
        x: (parent.width - width) / 2
        y: (parent.height - height) / 2

        modal: true

        Loader {
            id: folderLoader

            property string folderName: "Sample Text"
            property int currentFolderId: 0

            active: currentFolderId !== 0
            anchors.fill: parent

            sourceComponent: ColumnLayout {
                spacing: 5
                anchors.fill: parent

                Item {
                    Layout.preferredHeight: 5
                }

                Label {
                    Layout.fillWidth: true

                    font: DTK.fontManager.t3
                    horizontalAlignment: Text.AlignHCenter
                    text: folderLoader.folderName
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    color: "transparent"

                    SwipeView {
                        id: folderPagesView

                        anchors.fill: parent

                        currentIndex: folderPageIndicator.currentIndex

                        Repeater {
                            model: MultipageProxyModel.pageCount(folderLoader.currentFolderId) // FIXME: should be a property?

                            Loader {
                                active: SwipeView.isCurrentItem || SwipeView.isNextItem || SwipeView.isPreviousItem
                                id: folderGridViewLoader
                                objectName: "Folder GridView Loader"

                                sourceComponent: Rectangle {
                                    anchors.fill: parent
                                    color: "transparent"

                                    MultipageSortFilterProxyModel {
                                        id: folderProxyModel
                                        sourceModel: MultipageProxyModel
                                        pageId: modelData
                                        folderId: folderLoader.currentFolderId
                                    }

                                    GridViewContainer {
                                        id: folderGridViewContainer
                                        anchors.fill: parent
                                        rows: 3
                                        columns: 4
                                        model: folderProxyModel
                                        padding: 10
                                        interactive: false
                                        focus: true
                                        activeGridViewFocusOnTab: folderGridViewLoader.SwipeView.isCurrentItem
                                        delegate: IconItemDelegate {
                                            iconSource: "image://app-icon/" + iconName
                                            width: folderGridViewContainer.cellSize
                                            height: folderGridViewContainer.cellSize
                                            padding: 5
                                            onItemClicked: {
                                                launchApp(desktopId)
                                            }
                                            onMenuTriggered: {
                                                showContextMenu(this, model, false, false, true)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                PageIndicator {
                    Layout.alignment: Qt.AlignHCenter

                    id: folderPageIndicator

                    count: folderPagesView.count
                    currentIndex: folderPagesView.currentIndex
                    interactive: true
                }
            }
        }
    }

    Keys.onPressed: {
        if (searchEdit.focus === false && !searchEdit.text
                && event.modifiers === Qt.NoModifier
                && event.key >= Qt.Key_A && event.key <= Qt.Key_Z) {
            searchEdit.focus = true
            searchEdit.text = event.text
        }
    }

    Keys.onEscapePressed: {
        if (!DebugHelper.avoidHideWindow) {
            LauncherController.visible = false;
        }
    }

    Connections {
        target: LauncherController
        function onVisibleChanged() {
            // only do these clean-up steps on launcher get hide
            if (LauncherController.visible) return
            // clear searchEdit text
            searchEdit.text = ""
            // reset(remove) keyboard focus
            baseLayer.focus = true
        }
    }
}
