import QtQuick 2.9
import QtQuick.Window 2.2
import QtQuick.Controls 2.5
import QtQuick.XmlListModel 2.0
import QtQuick.Layouts 1.3
import QtQuick.Controls.Material 2.12
import QtQml.Models 2.1
import me.appadeia.SysInfo 1.0
import com.blackgrain.qml.quickdownload 1.0

Window {
    visible: true
    width: 640
    height: 480
    title: qsTr("OBS Browser")
    id: root

    property string results: ""
    property string distro: ""
    property bool leftHome: false
    property bool loading: false

    color: "#121212"

    Material.theme: Material.Dark
    Material.accent: "#35b9ab"

    SysInfo {
        id: sysinfo
    }

    Component.onCompleted: {
        var dist = sysinfo.getOS().toLowerCase();
        if (dist.includes("15.1")) {
            root.distro = "15.1";
        } else if (dist.includes("15.0")) {
            root.distro = "15.0";
        } else {
            root.distro = "Tumbleweed";
        }
        console.log(root.distro);
    }

    function search(query) {
        root.loading = true;
        if (!root.leftHome) {
            fade.running = true;
            root.leftHome = true;
        }

        var http = new XMLHttpRequest()
        var url = "https://api.opensuse.org/search/published/binary/id";
        var params = "match=contains%28%40name%2C+%27" + query + "%27%29";
        http.open("POST", url, true);

        // Send the proper header information along with the request
        http.setRequestHeader("Content-type", "application/x-www-form-urlencoded");
        http.setRequestHeader("Content-length", params.length);
        http.setRequestHeader("Connection", "close");
        http.setRequestHeader("Authorization", "Basic " + Qt.btoa("zyp_user" + ":" + "zyp_pw_1"))

        http.onreadystatechange = function() { // Call a function when the state changes.
                    if (http.readyState == 4) {
                        if (http.status == 200) {
                            root.results = http.responseText;
                        } else {
                            errorSplash.visible = true;
                        }
                        root.loading = false;
                    }
                }
        http.send(params);
    }

    XmlListModel {
        id: resultsModel
        xml: root.results
        query: "/collection/binary[contains(@repository," + "'" + root.distro + "'" + ")]"
        XmlRole {
            name: "pkName"
            query: "@name/string()"
        }
        XmlRole {
            name: "pkVersion"
            query: "@version/string()"
        }
        XmlRole {
            name: "pkDistro"
            query: "@repository/string()"
        }
        XmlRole {
            name: "pkProject"
            query: "@project/string()"
        }
    }
    ColumnLayout {
        anchors.fill: parent
        RowLayout {
            id: bar
            Layout.alignment: Layout.Center
            TextField {
                Layout.fillWidth: true
                id: searchField
                color: "white";
                onAccepted: {
                    root.search(searchField.text);
                }

            }

            Button {
                text: "<font color='#ffffff'> Search </font>"
                onClicked: {
                    root.search(searchField.text);
                }
            }
        }



        GridView {
            id: mainGrid
            cellWidth: width;
            cellHeight: height / 4;
            Layout.fillHeight: true
            Layout.fillWidth: true
            clip: true;
            model: resultsModel
            delegate: pk
            ScrollBar.vertical: ScrollBar {}
            populate: Transition {
                NumberAnimation {
                    property: "opacity"
                    from: 0
                    to: 1
                    duration: 300
                }
            }
            add: Transition {
                NumberAnimation {
                    property: "opacity"
                    from: 0
                    to: 1
                    duration: 300
                }
            }
        }
    }
    Component {
        id: pk

        Item {
            width: mainGrid.cellWidth
            height: mainGrid.cellHeight
            Item {
                width: parent.width * 0.9
                height: parent.height * 0.9
                anchors.centerIn: parent
                Material.elevation: 24

                Rectangle {
                    color: "white"
                    opacity: 0.11
                    anchors.fill: parent
                }

                Item {
                    width: parent.width * 0.9
                    height: parent.height * 0.9
                    anchors.centerIn: parent

                    Column {
                        Row {
                            Label {
                                color: "white"
                                font.bold: true
                                text: pkName
                            }
                            Label {
                                color: "white"
                                text: " - " + pkVersion
                            }
                        }
                        Row {
                            Label {
                                color: "white"
                                text: pkProject
                            }
                        }
                    }
                    Button {
                        anchors.bottom: parent.bottom
                        anchors.right: parent.right
                        anchors.rightMargin: 1
                        anchors.bottomMargin: 1
                        text: "Install"
                        onClicked: {
                            dialog.show(pkName, pkProject, pkDistro);
                        }
                    }
                }
            }
        }
    }

    Rectangle {
        color: "black"
        anchors.fill: parent
        visible: false
        Label {
            color: "white"
            anchors.centerIn: parent.center
            text: "Whoops! There's an error!"
        }
        id: errorSplash
    }
    Rectangle {
        id: home
        color: "#00000000"
        anchors.fill: parent
        Label {
            anchors.centerIn: parent
            color: "white"
            font.bold: true
            font.pointSize: 24
            text: "Welcome to the OBS browser."
            id: welcome
        }
        Label {
            color: "white"
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: welcome.bottom
            anchors.topMargin: 1
            font.pointSize: 12
            text: "To begin, use the search bar at the top."
        }
        NumberAnimation {
            id: fade
            target: home
            running: false
            property: "opacity"
            from: 1
            to: 0
        }
    }

    Rectangle {
        id: loadingbar
        anchors.bottom: parent.bottom
        width: parent.width
        height: parent.height * 0.01
        color: "#35b9ab"
        visible: root.loading ? true : false
        SequentialAnimation {
            running: true
            loops: Animation.Infinite
            NumberAnimation {
                target: loadingbar
                property: "opacity"
                from: 1
                to: 0
                duration: 500
            }
            PauseAnimation {
                duration: 200
            }
            NumberAnimation {
                target: loadingbar
                property: "opacity"
                from: 0
                to: 1
                duration: 500
            }
            PauseAnimation {
                duration: 200
            }
        }
    }
    Download {
        id: downloader

        url: "http://placehold.it/500x500"
        destination: "file:///tmp/pk.ymp"

        running: false

        overwrite: true

        followRedirects: true
        onRedirected: console.log('Redirected',url,'->',redirectUrl)

        onStarted: console.log('Started download',url)
        onError: console.error(errorString)
        onProgressChanged: console.log(url,'progress:',progress)
        onFinished: {
            console.info(url,'done')
            sysinfo.openFile("/tmp/pk.ymp");
        }
    }
    Dialog {
        id: dialog
        x: (parent.width - width) / 2
        y: (parent.height - height) / 2
        title: "Installation"
        standardButtons: Dialog.Ok
        modal: true
        contentItem: Column {
            Label {
                text: "Launching download in YaST..."
            }

            /*Label {
                text: "To install your software of choice, use these commands in a terminal:"
            }*/
            /*TextEdit {
                color: "white"
                selectedTextColor: "white"
                selectionColor: "#35b9ab"
                readOnly: true
                selectByMouse: true
                id: installCommands
                font.family: "Roboto Mono"
                text: "Yeet \nYeet"

            }*/
        }
        function show(pk, project, distro) {
            // var proj = project.replace(":", ":/") + "/" + distro
            // var projAlias = project.replace(":", "-")
            dialog.open()
            // installCommands.text = "zypper ar " + "obs://" + proj + " " + projAlias + "\n" + "zypper in " + pk;
            downloader.start(getYmpUrl(pk, project, distro));
        }
        function getYmpUrl(pk, project, distro) {
            return "https://software.opensuse.org/ymp/" + project + "/" + distro + "/" + pk + ".ymp";
        }
    }
}
