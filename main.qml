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
    property string files: ""
    property string meta: ""
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
    }

    function search(query) {
        snackbar.close();
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
                            snackbar.open();
                            root.results = "";
                        }
                        root.loading = false;
                    }
                }
        http.send(params);
    }
    function packageFiles(proj, pk) {
        var http = new XMLHttpRequest()
        var url = "https://api.opensuse.org/source/" + proj + "/" + pk;
        http.open("GET", url, true);

        // Send the proper header information along with the request
        http.setRequestHeader("Content-type", "application/x-www-form-urlencoded");
        http.setRequestHeader("Connection", "close");
        http.setRequestHeader("Authorization", "Basic " + Qt.btoa("zyp_user" + ":" + "zyp_pw_1"))

        http.onreadystatechange = function() { // Call a function when the state changes.
                    if (http.readyState == 4) {
                        if (http.status == 200) {
                            root.files = http.responseText
                        } else {

                        }
                        root.loading = false;
                    }
                }
        http.send();
    }
    function packageMeta(proj, pk) {
        var http = new XMLHttpRequest()
        var url = "https://api.opensuse.org/source/" + proj + "/" + pk + "/_meta";
        http.open("GET", url, true);

        // Send the proper header information along with the request
        http.setRequestHeader("Content-type", "application/x-www-form-urlencoded");
        http.setRequestHeader("Connection", "close");
        http.setRequestHeader("Authorization", "Basic " + Qt.btoa("zyp_user" + ":" + "zyp_pw_1"))

        http.onreadystatechange = function() { // Call a function when the state changes.
                    if (http.readyState == 4) {
                        if (http.status == 200) {
                            root.meta = http.responseText
                        } else {

                        }
                        root.loading = false;
                    }
                }
        http.send();
    }
    function moreInfo(proj, pk) {
        packageFiles(proj, pk);
        packageMeta(proj, pk);
        page.pkName = pk
        pageIn.running = true
    }

    XmlListModel {
        id: filesModel
        xml: root.files
        query: "/directory/entry"

        XmlRole {
            name: "fileName"
            query: "@name/string()"
        }
    }
    XmlListModel {
        id: metaModel
        xml: root.meta
        query: "/package"

        XmlRole {
            name: "desc"
            query: "description/string()"
        }
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



//        GridView {
//            id: mainGrid
//            cellWidth: width;
//            cellHeight: height / 4;
//            Layout.fillHeight: true
//            Layout.fillWidth: true
//            clip: true;
//            model: resultsModel
//            delegate: pk
//            ScrollBar.vertical: ScrollBar {}
//            populate: Transition {
//                NumberAnimation {
//                    property: "opacity"
//                    from: 0
//                    to: 1
//                    duration: 300
//                }
//            }
//            add: Transition {
//                NumberAnimation {
//                    property: "opacity"
//                    from: 0
//                    to: 1
//                    duration: 300
//                }
//            }
//        }
        ScrollView {
            Layout.fillHeight: true
            Layout.fillWidth: true
            clip: true
            contentHeight: flow.height
            contentWidth: width
            Flow {
                width: parent.width
                height: parent.height
                Repeater {
                    model: resultsModel
                    delegate: pk
                }
            }
        }
    }
    Component {
        id: pk

        Item {
            width: 600
            height: 200
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
                        id: info
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: 1

                        anchors.right: view.left
                        anchors.rightMargin: 10

                        text: "View Info"
                        onClicked: {
                            root.moreInfo(pkProject, pkName);
                        }
                    }

                    Button {
                        id: view
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: 1

                        anchors.right: install.left
                        anchors.rightMargin: 10

                        text: "View on OBS"
                        onClicked: {
                            dialog.openOBS(pkName, pkProject);
                        }
                    }

                    Button {
                        id: install
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
    Component {
        id: file

        Row {
            Rectangle {
                width: 25
                height: 1
                color: "#00000000"
            }
            Label {
                font.bold: true
                text: fileName
            }
        }
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
        anchors.fill: parent
        visible: true
        color: "#00000000"
        Rectangle {
            id: snackbar
            Material.elevation: 24
            visible: false
            opacity: 0
            anchors.bottom: parent.bottom
            anchors.horizontalCenter: parent.horizontalCenter
            color: "#CF6679"
            height: parent.height / 10;
            width: parent.width / 2;
            radius: 4;
            Row {
                anchors.centerIn: parent
                Label {
                    anchors.verticalCenter: parent.verticalCenter
                    font.bold: true
                    font.pointSize: 13
                    color: "white"
                    text: "Whoops! There was an error!"
                }
            }
            Button {
                width: height
                flat: true
                text: ""
                onClicked: {
                    snackbar.close();
                }
            }
            function close() {
                exitAni.restart();
            }
            function open() {
                enterAni.restart();
            }

            SequentialAnimation {
                id: enterAni

                ScriptAction {
                    script: {
                        snackbar.visible = true;
                    }
                }
                NumberAnimation {
                    target: snackbar
                    property: "opacity"
                    to: 1
                    duration: 300
                    easing.type: Easing.InOutQuad
                }
            }
            SequentialAnimation {
                id: exitAni

                NumberAnimation {
                    target: snackbar
                    property: "opacity"
                    to: 0
                    duration: 300
                    easing.type: Easing.InOutQuad
                }
                ScriptAction {
                    script: {
                        snackbar.visible = false;
                    }
                }
            }
        }
        id: errorSplash
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
    Rectangle {
        property string pkName: "Yeet"
        id: page
        width: root.width
        height: root.height
        x: width
        y: 0
        color: "#121212"

        MouseArea {
            anchors.fill: parent
        }
        SequentialAnimation {
            id: pageIn
            NumberAnimation {
                target: page
                property: "x"
                from: page.width
                to: 0
                duration: 300
                easing: Easing.InOutQuad
            }
            ScriptAction {
                script: {
                    page.x = 0
                }
            }
        }
        SequentialAnimation {
            id: pageOut
            NumberAnimation {
                target: page
                property: "x"
                from: 0
                to: page.width
                duration: 300
                easing: Easing.InOutQuad
            }
            ScriptAction {
                script: {
                    page.x = page.width
                }
            }
        }
        Column {
            anchors.fill: parent
            Button {
                id: pageBack
                text: ""
                flat: true
                onClicked: {
                    pageOut.restart();
                    root.files = "";
                    root.meta = "";
                }
            }
            Label {
                id: pageName
                font.bold: true
                font.pointSize: 14
                text: page.pkName
            }
            Repeater {
                model: metaModel
                delegate: Row {
                    Rectangle {
                        width: 25
                        height: 1
                        color: "#00000000"
                    }
                    Label {
                        font.pointSize: 10
                        wrapMode: Text.WordWrap
                        text: desc
                    }
                }
            }

            Label {
                font.bold: true
                font.pointSize: 13
                text: "Files"
            }
            Repeater {
                model: filesModel
                delegate: file
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
        }
        function show(pk, project, distro) {
            dialog.open()
            downloader.start(getYmpUrl(pk, project, distro));
        }
        function getYmpUrl(pk, project, distro) {
            return "https://software.opensuse.org/ymp/" + project + "/" + distro + "/" + pk + ".ymp";
        }
        function openOBS(pk, project) {
            Qt.openUrlExternally(encodeURI("https://build.opensuse.org/package/show/" + project + "/" + pk));
        }
    }
}
