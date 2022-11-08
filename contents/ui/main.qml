import QtQuick 2.0
import org.kde.plasma.core 2.0 as PlasmaCore;
import org.kde.plasma.components 2.0 as Plasma;
import org.kde.kwin 2.0;

Item {
    id: root

    readonly property var classmatch: (
        KWin.readConfig("classmatch", "wechat.exe")
            .split("\n")
            .map(function(rule) {
                return rule.trim().toLowerCase();
            })
    )

    readonly property var matchHint: (
        KWin.readConfig("matchHint", true)
    )

    PlasmaCore.DataSource {
        id: shell
        engine: 'executable'

        connectedSources: []

        function run(cmd) {
            shell.connectSource(cmd);
        }

        onNewData: {
            shell.disconnectSource(sourceName);
        }
    }

    PlasmaCore.DataSource {
        id: shellWithReturn
        engine: 'executable'

        connectedSources: []

        function run(cmd) {
            shellWithReturn.connectSource(cmd);
        }

        onNewData: {
			exited(data["stdout"]);
            shellWithReturn.disconnectSource(sourceName);
        }
        signal exited(string stdout)
    }

    function onClientAddedHandler(client) {
        if ((!shell) || (!shellWithReturn)) return;
        var resource_class = client.resourceClass.toString().toLowerCase();
        var resource_name = client.resourceName.toString().toLowerCase();
        var wm_name = client.caption.toString();
        var clsMatches = root.classmatch.indexOf(resource_class) >= 0 || root.classmatch.indexOf(resource_name) >= 0 ;
        if (clsMatches && (wm_name = "")) {
            if ((client.height > 180) && (client.width > 500)) {
                // 确保不会误伤菜单
                var widint = client.windowId.toString();
                if (root.matchHint) {
                    var wid16 = client.windowId.toString(16);
                    shellWithReturn.run('echo '+widint+';xprop WM_HINTS -id 0x'+wid16);
                } else {
                    shell.run('xdotool windowunmap '+widint);
                    console.log('fix-wine-wechat-shadow: matched window '+widint);
                }
            }
        }
    }

    Component.onCompleted: {
        console.log("fix-wine-wechat-shadow: started");

        var clients = workspace.clientList();
        for (var i = 0; i < clients.length; i++) {
            root.onClientAddedHandler(clients[i]);
        }

        workspace.onClientAdded.connect(root.onClientAddedHandler);
    }

    Connections {
        target: shellWithReturn // onClientAddedHandler 执行，之后这边处理输出，是input就屏蔽掉窗口
        function onExited(stdout) {
            try {
                var stdouts = stdout.split('\n');
                var widint = stdouts[0];
                var wm_hint_input = stdouts[2];
                if (wm_hint_input.indexOf('False') != -1) {
                    // 不接收input，是阴影窗口
                    shell.run('xdotool windowunmap '+widint);
                    console.log('fix-wine-wechat-shadow: matched window '+widint);
                }
            } catch (e) {
                console.log('fix-wine-wechat-shadow: error window '+e)
            }
        }

    }
}
