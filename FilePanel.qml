import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Controls
import "."

Item {
    id: root
    focus: true

    Keys.onPressed: function(event) {
        if (event.modifiers & Qt.ControlModifier) {
            switch (event.key) {
                case Qt.Key_C: doCopy(); event.accepted = true; break
                case Qt.Key_X: doCut(); event.accepted = true; break
                case Qt.Key_V: doPaste(); event.accepted = true; break
                case Qt.Key_Z: doUndo(); event.accepted = true; break
            }
        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            if (selectedEntries.length > 0) doOpenSelected()
            event.accepted = true
        } else if (event.key === Qt.Key_Delete) {
            doTrash(); event.accepted = true
        } else if (event.key === Qt.Key_Escape) {
            goBack(); event.accepted = true
        }
    }

    property string currentPath: ""
    property var entries: []
    property var selectedEntries: []
    property var lastSelectedEntry: null
    property bool rubberActive: false
    property real rubberStartX: 0
    property real rubberStartY: 0
    property real rubberEndX: 0
    property real rubberEndY: 0
    property int autoScrollDir: 0
    property string clipboardMode: ""
    property var clipboardPaths: []
    property string previewText: ""
    property string pdfPreviewSource: ""
    property bool isDragging: false
    property string dragFilePath: ""
    property string dragFileName: ""
    property real dragCursorX: 0
    property real dragCursorY: 0
    property string hoveredDropPath: ""
    property int hoveredDropIndex: -1
    property real dragPressX: 0
    property real dragPressY: 0

    property real emptyCtxX: 0
    property real emptyCtxY: 0
    property bool emptyCtxVisible: false
    property string emptyCtxSubmenu: ""
    property bool fileCreateVisible: false
    property string newFileType: "text"

    property var displayEntries: []
    property var undoStack: []
    property var redoStack: []
    property string searchQuery: ""
    property var searchResults: []
    property bool filterInputVisible: false

    property var detailedEntries: []
    property var expandedDirs: ({})
    property var expandedDirContents: ({})
    property var refreshQueue: []
    property bool refreshInProgress: false

    property var pathState: ({})
    property string stateFilePath: Quickshell.env("HOME") + "/.config/quickshell/filepanel-state.json"

    property var sidebarDirs: ({})
    property var recentFiles: []
    property var devices: ({})
    property int sidebarWidth: 170
    property real previewWidth: 180
    property string historyStack: "[]"
    property int historyIndex: -1
    property bool showHidden: false
    property string viewMode: "list"
    property string sortMode: "nombre"
    property real zoomLevel: 1.0
    property real colNameWidth: 160
    property real colSizeWidth: 60
    property real colDateWidth: 65
    property real colIconGap: 18
    property string filterText: ""
    property bool searchActive: false
    property string deviceError: ""
    property string deviceOpName: ""
    property var bookmarks: []
    property var menuOpen: ""
    property real menuTargetX: 4
    property var tabs: []
    property int currentTabIndex: 0
    property bool tabSwitchInProgress: false
    property bool prefPanelVisible: false
    property string pref_viewMode: "list"
    property string pref_sortMode: "nombre"
    property bool pref_showHiddenOnStart: false
    property bool pref_confirmDelete: true
    property bool pref_singleClickNav: false
    property bool confirmDelete: true
    property bool confirmDeleteVisible: false
    property bool singleClickNav: false
    property int pref_sidebarWidth: 170
    property int pref_previewWidth: 180

    property var openWithFile: null
    property var openWithApps: []
    property string openWithFilter: ""
    property bool openWithVisible: false

    Process {
        id: notifProcess
        running: false
        command: ["true"]
    }

    function sendNotification(summary, body) {
        notifProcess.command = ["notify-send", summary, body]
        notifProcess.running = true
    }

    Process {
        id: stateLoader
        running: false
        command: ["true"]
        stdout: SplitParser {
            onRead: function(data) {
                try {
                    var parsed = JSON.parse(data.trim())
                    root.pathState = parsed
                    var saved = root.pathState[root.currentPath]
                    if (saved) {
                        if (saved.viewMode && saved.viewMode !== root.viewMode) root.viewMode = saved.viewMode
                        if (saved.sortMode && saved.sortMode !== root.sortMode) root.sortMode = saved.sortMode
                    }
                } catch(e) {}
            }
        }
    }

    Process {
        id: stateWriter
        running: false
        command: ["true"]
        stdout: SplitParser {
            onRead: function(d) {}
        }
    }

    function fmtSize(bytes) {
        if (bytes === 0) return "0 B"
        var units = ["B", "KB", "MB", "GB", "TB"]
        var i = Math.floor(Math.log(bytes) / Math.log(1024))
        var s = (bytes / Math.pow(1024, i)).toFixed(i > 0 ? 1 : 0)
        return s + " " + units[i]
    }

    function fmtTime(ts) {
        var d = new Date(ts * 1000)
        return d.toLocaleDateString(Qt.locale(), "yyyy-MM-dd")
    }

    function fmtMtime(ts) {
        var d = new Date(ts * 1000)
        var now = new Date()
        var diff = (now.getTime() - d.getTime()) / 1000
        if (diff < 60) return "Hace unos segundos"
        if (diff < 3600) return "Hace " + Math.floor(diff / 60) + " min"
        if (diff < 86400) return "Hoy " + d.toLocaleTimeString(Qt.locale(), "HH:mm")
        if (diff < 172800) return "Ayer " + d.toLocaleTimeString(Qt.locale(), "HH:mm")
        return d.toLocaleDateString(Qt.locale(), "yyyy-MM-dd HH:mm")
    }

    function iconFor(entry) {
        if (entry.type === "dir") return "\uF07C"
        if (entry.type === "symlink") return "\uF87B"
        var ext = entry.name.split(".").pop().toLowerCase()
        if (["png","jpg","jpeg","gif","bmp","webp","svg"].indexOf(ext) >= 0) return "\uF1C5"
        if (["mp3","wav","flac","ogg","m4a","wma"].indexOf(ext) >= 0) return "\uF001"
        if (["mp4","avi","mkv","mov","webm","flv"].indexOf(ext) >= 0) return "\uF008"
        if (["zip","tar","gz","rar","7z","bz2","xz"].indexOf(ext) >= 0) return "\uF1C6"
        if (["py","js","ts","qml","cpp","c","h","rs","go","sh","bash"].indexOf(ext) >= 0) return "\uE795"
        if (["pdf"].indexOf(ext) >= 0) return "\uF1C1"
        if (["doc","docx","odt"].indexOf(ext) >= 0) return "\uF1C2"
        if (["xls","xlsx","ods","csv"].indexOf(ext) >= 0) return "\uF1C3"
        if (["deb","rpm","AppImage","flatpak","snap"].indexOf(ext) >= 0) return "\uF17C"
        return "\uF15B"
    }

    function isImage(entry) {
        if (!entry) return false
        var ext = entry.name.split(".").pop().toLowerCase()
        return ["png","jpg","jpeg","gif","bmp","webp","svg"].indexOf(ext) >= 0
    }

    function isText(entry) {
        if (!entry) return false
        var ext = entry.name.split(".").pop().toLowerCase()
        return ["txt","md","qml","py","js","ts","cpp","c","h","rs","go","sh","bash","conf","ini","json","xml","yaml","yml","toml","cfg","log","css","html","htm","java","kt","swift","env","gitignore","csv","diff","doc"].indexOf(ext) >= 0
    }

    function isPdf(entry) {
        if (!entry) return false
        return entry.name.toLowerCase().endsWith(".pdf")
    }

    function isSelected(entry) {
        if (!entry) return false
        for (var idx = 0; idx < selectedEntries.length; idx++) {
            if (selectedEntries[idx] && selectedEntries[idx].path === entry.path)
                return true
        }
        return false
    }

    function toggleSelected(entry) {
        var idx = selectedEntries.indexOf(entry)
        if (idx >= 0) {
            var a = selectedEntries.slice()
            a.splice(idx, 1)
            selectedEntries = a
        } else {
            selectedEntries = selectedEntries.concat([entry])
        }
    }

    function doOpenSelected() {
        var scr = Quickshell.env("HOME") + "/.config/quickshell/scripts/file-browse.py"
        for (var oi = 0; oi < selectedEntries.length; oi++) {
            var oe = selectedEntries[oi]
            if (oe.type === "dir")
                addTab(oe.path)
            else {
                Qt.openUrlExternally("file://" + oe.path)
                Quickshell.execDetached([scr, "append_recent", oe.path])
            }
        }
    }

    function navigateTo(path, skipPush) {
        selectedEntries = []
        lastSelectedEntry = null
        currentPath = path
        expandedDirs = ({})
        expandedDirContents = ({})
        var saved = root.pathState[path]
        if (saved) {
            if (saved.viewMode && saved.viewMode !== root.viewMode) {
                root.viewMode = saved.viewMode
            }
            if (saved.sortMode && saved.sortMode !== root.sortMode) {
                root.sortMode = saved.sortMode
            }
        }
        if (!skipPush) pushHistory(path)
        loadDir()
    }

    function loadDir(skipFetch) {
        if (skipFetch && entries.length > 0) return
        loader.running = true
    }

    function buildDetailedTree() {
        var result = []
        for (var i = 0; i < root.entries.length; i++) {
            result = result.concat(buildDetailedNode(root.entries[i], 0))
        }
        root.detailedEntries = result
    }

    function buildDetailedNode(entry, depth) {
        var node = {
            name: entry.name, path: entry.path, type: entry.type,
            size: entry.size, modified: entry.modified, mode: entry.mode,
            depth: depth
        }
        var arr = [node]
        if (entry.type === "dir" && root.expandedDirs[entry.path]) {
            var children = root.expandedDirContents[entry.path]
            if (children && children.length > 0) {
                for (var j = 0; j < children.length; j++) {
                    arr = arr.concat(buildDetailedNode(children[j], depth + 1))
                }
            } else if (children && children.length === 0) {
                arr.push({ name: "(carpeta vac\u00EDa)", path: "", type: "empty-placeholder", size: 0, modified: 0, mode: "", depth: depth + 1 })
            }
        }
        return arr
    }

    function toggleTreeFolder(path) {
        root.refreshInProgress = false
        root.refreshQueue = []
        if (root.expandedDirs[path]) {
            var newExpanded = {}
            for (var k in root.expandedDirs) {
                if (k !== path) newExpanded[k] = root.expandedDirs[k]
            }
            root.expandedDirs = newExpanded
            var newContents = {}
            for (var k2 in root.expandedDirContents) {
                if (k2 !== path) newContents[k2] = root.expandedDirContents[k2]
            }
            root.expandedDirContents = newContents
            root.buildDetailedTree()
        } else {
            root.expandedDirs[path] = true
            var scr = Quickshell.env("HOME") + "/.config/quickshell/scripts/file-browse.py"
            treeLoader.loadPath = path
            treeLoader.command = [scr, "list", path, root.sortMode]
            treeLoader.running = true
        }
    }

    function refreshExpandedDirs() {
        root.refreshQueue = []
        for (var p in root.expandedDirs) {
            root.refreshQueue.push(p)
        }
        if (root.refreshQueue.length > 0) {
            root.refreshInProgress = true
            root.processRefreshQueue()
        }
    }

    function processRefreshQueue() {
        if (!root.refreshInProgress || root.refreshQueue.length === 0) {
            root.refreshInProgress = false
            return
        }
        var path = root.refreshQueue.shift()
        var scr = Quickshell.env("HOME") + "/.config/quickshell/scripts/file-browse.py"
        treeLoader.loadPath = path
        treeLoader.command = [scr, "list", path, root.sortMode]
        treeLoader.running = true
    }

    function goUp() {
        var parts = currentPath.replace(/\/+$/, "").split("/")
        parts.pop()
        navigateTo(parts.join("/") || "/")
    }

    function goHome() {
        navigateTo(Quickshell.env("HOME"))
    }

    function saveCurrentTab() {
        if (currentTabIndex >= 0 && currentTabIndex < tabs.length) {
            var newTabs = tabs.slice()
            newTabs[currentTabIndex] = {
                path: currentPath,
                entries: entries,
                selectedEntries: selectedEntries,
                lastSelectedEntry: lastSelectedEntry,
                historyStack: historyStack,
                historyIndex: historyIndex
            }
            tabs = newTabs
        }
    }

    function switchTab(index) {
        if (index === currentTabIndex || index < 0 || index >= tabs.length) return
        saveCurrentTab()
        tabSwitchInProgress = true
        currentTabIndex = index
        var tab = tabs[index]
        currentPath = tab.path
        entries = tab.entries
        selectedEntries = tab.selectedEntries || []
        lastSelectedEntry = tab.lastSelectedEntry || null
        historyStack = tab.historyStack
        historyIndex = tab.historyIndex
        previewText = ""
        pdfPreviewSource = ""
        tabSwitchInProgress = false
        loadDir(true)
    }

    function addTab(path) {
        if (tabs.length >= 20) return
        saveCurrentTab()
        var newTab = { path: path, entries: [], selectedEntries: [], lastSelectedEntry: null, historyStack: "[]", historyIndex: -1 }
        tabs = tabs.concat([newTab])
        currentTabIndex = tabs.length - 1
        currentPath = path
        entries = []
        selectedEntries = []
        lastSelectedEntry = null
        previewText = ""
        pdfPreviewSource = ""
        loadDir()
    }

    function closeTab(index) {
        if (tabs.length <= 1) return
        tabSwitchInProgress = true
        var newTabs = []
        for (var ti = 0; ti < tabs.length; ti++) {
            if (ti !== index) newTabs.push(tabs[ti])
        }
        var newIdx = currentTabIndex
        if (newIdx >= newTabs.length) newIdx = newTabs.length - 1
        if (index <= newIdx && newIdx > 0) newIdx--
        tabs = newTabs
        currentTabIndex = newIdx
        var tab = tabs[currentTabIndex]
        currentPath = tab.path
        entries = tab.entries
        selectedEntries = tab.selectedEntries || []
        lastSelectedEntry = tab.lastSelectedEntry || null
        historyStack = tab.historyStack
        historyIndex = tab.historyIndex
        previewText = ""
        pdfPreviewSource = ""
        tabSwitchInProgress = false
    }

    function enterDir(name) {
        var path = currentPath.replace(/\/+$/, "") + "/" + name
        navigateTo(path)
    }

    function openEntry(entry) {
        if (entry.type === "dir") {
            enterDir(entry.name)
        } else {
            Qt.openUrlExternally("file://" + entry.path)
        }
    }

    function doTrash() {
        if (selectedEntries.length === 0) return
        var paths = selectedEntries.map(function(e) { return e.path })
        root.pushUndo({type: "trash", paths: paths})
        var cmd = [Quickshell.env("HOME") + "/.config/quickshell/scripts/file-browse.py", "trash"]
        for (var i = 0; i < paths.length; i++) cmd.push(paths[i])
        opRunner.command = cmd
        opRunner.running = true
        try {
            var names = selectedEntries.map(function(e) { return e.name || e.path.split("/").pop() })
            if (names.length === 1) {
                sendNotification("Papelera", "El archivo \"" + names[0] + "\" fue enviado a la papelera (30 d\u00EDas)")
            } else {
                sendNotification("Papelera", "El archivo \"" + names[0] + "\" y " + (names.length - 1) + " m\u00E1s fueron enviados a la papelera (30 d\u00EDas)")
            }
        } catch(e) {}
    }

    function promptDelete() {
        if (selectedEntries.length === 0) return
        if (root.confirmDelete) {
            root.confirmDeleteVisible = true
        } else {
            doDelete()
        }
    }

    function doDelete() {
        if (selectedEntries.length === 0) return
        root.confirmDeleteVisible = false
        var paths = selectedEntries.map(function(e) { return e.path })
        root.pushUndo({type: "delete", paths: paths})
        var cmd = [Quickshell.env("HOME") + "/.config/quickshell/scripts/file-browse.py", "delete"]
        for (var i = 0; i < paths.length; i++) cmd.push(paths[i])
        opRunner.command = cmd
        opRunner.running = true
        try {
            var names = selectedEntries.map(function(e) { return e.name || e.path.split("/").pop() })
            if (names.length === 1) {
                sendNotification("Eliminado permanente", "El archivo \"" + names[0] + "\" fue eliminado de manera permanente y ya no se puede recuperar")
            } else {
                sendNotification("Eliminado permanente", "El archivo \"" + names[0] + "\" y " + (names.length - 1) + " m\u00E1s fueron eliminados de manera permanente y ya no se pueden recuperar")
            }
        } catch(e) {}
    }

    function doRestore() {
        if (selectedEntries.length === 0) return
        var paths = selectedEntries.map(function(e) { return e.path })
        var cmd = [Quickshell.env("HOME") + "/.config/quickshell/scripts/file-browse.py", "restore"]
        for (var i = 0; i < paths.length; i++) cmd.push(paths[i])
        opRunner.command = cmd
        opRunner.running = true
    }

    function doCopy() {
        if (selectedEntries.length === 0) return
        clipboardMode = "copy"
        clipboardPaths = selectedEntries.map(function(e) { return e.path })
    }

    function doCut() {
        if (selectedEntries.length === 0) return
        clipboardMode = "cut"
        clipboardPaths = selectedEntries.map(function(e) { return e.path })
    }

    function doPaste() {
        if (clipboardPaths.length === 0) return
        var first = clipboardPaths[0].split("/").pop()
        var count = clipboardPaths.length
        var dst = currentPath.replace(/\/+$/, "") + "/"
        for (var i = 0; i < clipboardPaths.length; i++) {
            var src = clipboardPaths[i]
            var name = src.split("/").pop()
            if (clipboardMode === "copy") {
                root.pushUndo({type: "copy", oldPath: src, newPath: dst + name})
                opRunner.command = [Quickshell.env("HOME") + "/.config/quickshell/scripts/file-browse.py", "copy", src, dst + name]
            } else {
                root.pushUndo({type: "move", oldPath: src, newPath: dst + name})
                opRunner.command = [Quickshell.env("HOME") + "/.config/quickshell/scripts/file-browse.py", "move", src, dst + name]
            }
            opRunner.running = true
        }
        clipboardMode = ""
        clipboardPaths = []
        if (count === 1) {
            sendNotification("Modificado", "Se modific\u00F3 \"" + first + "\"")
        } else {
            sendNotification("Modificado", "Se modific\u00F3 \"" + first + "\" y " + (count - 1) + " archivo(s) m\u00E1s")
        }
    }

    function doRename() {
        if (selectedEntries.length !== 1) return
        var e = selectedEntries[0]
        renameTextInput.text = e.name

        var view = root.viewMode === "list" ? fileList : (root.viewMode === "icon" ? fileGrid : detailedList)
        var idx = -1
        for (var ri = 0; ri < root.displayEntries.length; ri++) {
            if (root.displayEntries[ri].path === e.path) { idx = ri; break }
        }
        if (idx >= 0) {
            view.positionViewAtIndex(idx, ListView.Contain)
            Qt.callLater(function() {
                var delItem = view.itemAtIndex(idx)
                if (delItem) {
                    var p = delItem.mapToItem(root, 0, 0)
                    renameInput.x = Math.max(4, p.x)
                    renameInput.y = p.y
                } else {
                    var vp = view.mapToItem(root, 0, 0)
                    if (root.viewMode === "icon") {
                        var cw = fileGrid.cellWidth
                        var ch = fileGrid.cellHeight
                        var cols = Math.max(1, Math.floor(view.width / cw))
                        var row = Math.floor(idx / cols)
                        var col = idx % cols
                        renameInput.x = Math.max(4, vp.x + col * cw - view.contentX + 4)
                        renameInput.y = Math.max(0, vp.y + row * ch - view.contentY)
                    } else {
                        var itemH = Math.round(24 * root.zoomLevel)
                        renameInput.x = Math.max(4, vp.x - view.contentX + 4)
                        renameInput.y = Math.max(0, vp.y + idx * itemH - view.contentY)
                    }
                }
                renameInput.width = Math.min(view.width - 8, 250)
                renameInput.visible = true
                renameTextInput.forceActiveFocus()
                renameTextInput.selectAll()
            })
        } else {
            renameInput.x = 60; renameInput.y = 42; renameInput.width = root.width - 80
            renameInput.visible = true
            renameTextInput.forceActiveFocus()
            renameTextInput.selectAll()
        }
    }

    function doNewFolder() {
        mkdirTextInput.text = ""
        mkdirInput.visible = true
        mkdirTextInput.forceActiveFocus()
    }

    function finishRename() {
        var newName = renameTextInput.text.trim()
        if (newName && selectedEntries.length === 1 && newName !== selectedEntries[0].name) {
            var oldPath = selectedEntries[0].path
            var dir = oldPath.substring(0, oldPath.lastIndexOf("/"))
            root.pushUndo({type: "rename", oldPath: oldPath, newPath: dir + "/" + newName})
            opRunner.command = [Quickshell.env("HOME") + "/.config/quickshell/scripts/file-browse.py", "rename", oldPath, dir + "/" + newName]
            opRunner.running = true
            try { sendNotification("Modificado", "Se modific\u00F3 \"" + newName + "\"") } catch(e) {}
        }
        renameInput.visible = false
    }

    function finishMkdir() {
        var name = mkdirTextInput.text.trim()
        if (name) {
            var path = currentPath.replace(/\/+$/, "") + "/" + name
            root.pushUndo({type: "mkdir", path: path})
            opRunner.command = [Quickshell.env("HOME") + "/.config/quickshell/scripts/file-browse.py", "mkdir", path]
            opRunner.running = true
        }
        mkdirInput.visible = false
    }

    function doNewFile() {
        newFileInput.visible = true
        newFileTextInput.text = "nuevo_archivo.txt"
        newFileTextInput.forceActiveFocus()
        newFileTextInput.selectAll()
    }

    function finishNewFile() {
        var name = newFileTextInput.text.trim()
        if (name) {
            var path = currentPath.replace(/\/+$/, "") + "/" + name
            root.pushUndo({type: "create", path: path, fileType: root.newFileType})
            opRunner.command = [Quickshell.env("HOME") + "/.config/quickshell/scripts/file-browse.py", "create", path, root.newFileType]
            opRunner.running = true
        }
        newFileInput.visible = false
    }

    function doNewTextFile() {
        root.newFileType = "text"
        newFileTextInput.text = "nuevo_archivo.txt"
        newFileInput.visible = true
        newFileTextInput.forceActiveFocus()
        newFileTextInput.selectAll()
    }

    function doNewHtmlFile() {
        root.newFileType = "html"
        newFileTextInput.text = "nuevo_archivo.html"
        newFileInput.visible = true
        newFileTextInput.forceActiveFocus()
        newFileTextInput.selectAll()
    }

    function doNewEmptyFile() {
        root.newFileType = "empty"
        newFileTextInput.text = "nuevo_archivo"
        newFileInput.visible = true
        newFileTextInput.forceActiveFocus()
        newFileTextInput.selectAll()
    }

    function doNewWebLink() {
        root.newFileType = "web-link"
        newFileTextInput.text = "mi_enlace.desktop"
        newFileInput.visible = true
        newFileTextInput.forceActiveFocus()
        newFileTextInput.selectAll()
    }

    function doNewFileLink() {
        root.newFileType = "file-link"
        newFileTextInput.text = "enlace.desktop"
        newFileInput.visible = true
        newFileTextInput.forceActiveFocus()
        newFileTextInput.selectAll()
    }

    function doNewAppLink() {
        root.newFileType = "app-link"
        newFileTextInput.text = "aplicacion.desktop"
        newFileInput.visible = true
        newFileTextInput.forceActiveFocus()
        newFileTextInput.selectAll()
    }

    function doNewOdtFile() {
        root.newFileType = "odt"
        newFileTextInput.text = "documento.odt"
        newFileInput.visible = true
        newFileTextInput.forceActiveFocus()
        newFileTextInput.selectAll()
    }

    function doNewOdsFile() {
        root.newFileType = "ods"
        newFileTextInput.text = "hoja_calculo.ods"
        newFileInput.visible = true
        newFileTextInput.forceActiveFocus()
        newFileTextInput.selectAll()
    }

    function doNewOdpFile() {
        root.newFileType = "odp"
        newFileTextInput.text = "presentacion.odp"
        newFileInput.visible = true
        newFileTextInput.forceActiveFocus()
        newFileTextInput.selectAll()
    }

    function doNewMdFile() {
        root.newFileType = "md"
        newFileTextInput.text = "documento.md"
        newFileInput.visible = true
        newFileTextInput.forceActiveFocus()
        newFileTextInput.selectAll()
    }

    function doNewPyFile() {
        root.newFileType = "py"
        newFileTextInput.text = "script.py"
        newFileInput.visible = true
        newFileTextInput.forceActiveFocus()
        newFileTextInput.selectAll()
    }

    function doNewShFile() {
        root.newFileType = "sh"
        newFileTextInput.text = "script.sh"
        newFileInput.visible = true
        newFileTextInput.forceActiveFocus()
        newFileTextInput.selectAll()
    }

    function doNewJsonFile() {
        root.newFileType = "json"
        newFileTextInput.text = "datos.json"
        newFileInput.visible = true
        newFileTextInput.forceActiveFocus()
        newFileTextInput.selectAll()
    }

    function doNewCssFile() {
        root.newFileType = "css"
        newFileTextInput.text = "estilos.css"
        newFileInput.visible = true
        newFileTextInput.forceActiveFocus()
        newFileTextInput.selectAll()
    }

    function doNewJsFile() {
        root.newFileType = "js"
        newFileTextInput.text = "script.js"
        newFileInput.visible = true
        newFileTextInput.forceActiveFocus()
        newFileTextInput.selectAll()
    }

    function isCompressedArchive(name) {
        if (!name) return false
        var n = name.toLowerCase()
        if (n.endsWith(".tar.gz") || n.endsWith(".tar.bz2") || n.endsWith(".tar.xz")) return true
        var ext = n.split(".").pop()
        return ["zip","tar","gz","rar","7z","bz2","xz"].indexOf(ext) >= 0
    }

    function finishRubberBand() {
        var x1 = Math.min(rubberStartX, rubberEndX)
        var y1 = Math.min(rubberStartY, rubberEndY)
        var x2 = Math.max(rubberStartX, rubberEndX)
        var y2 = Math.max(rubberStartY, rubberEndY)
        if (x2 - x1 < 5 && y2 - y1 < 5) return

        if (root.viewMode === "list" || root.viewMode === "detailed") {
            var lv = fileList.visible ? fileList : detailedList
            if (!lv.visible) return
            var vp = lv.mapToItem(root, 0, 0)
            var itemH = Math.round(24 * root.zoomLevel)
            for (var i = 0; i < root.displayEntries.length; i++) {
                var itemTop = vp.y + i * itemH - lv.contentY
                var itemBot = itemTop + itemH
                if (itemTop < y2 && itemBot > y1) {
                    if (!root.isSelected(root.displayEntries[i]))
                        root.selectedEntries = root.selectedEntries.concat([root.displayEntries[i]])
                }
            }
        } else if (root.viewMode === "icon") {
            var gv = fileGrid
            var gp = gv.mapToItem(root, 0, 0)
            var cw = gv.cellWidth; var ch = gv.cellHeight
            var cols = Math.floor(gv.width / cw)
            for (var j = 0; j < root.displayEntries.length; j++) {
                var col = j % cols
                var row = Math.floor(j / cols)
                var gx = gp.x + col * cw
                var gy = gp.y + row * ch - gv.contentY
                if (gx < x2 && gx + cw > x1 && gy < y2 && gy + ch > y1) {
                    if (!root.isSelected(root.displayEntries[j]))
                        root.selectedEntries = root.selectedEntries.concat([root.displayEntries[j]])
                }
            }
        }
    }

    function autoScrollStep() {
        if (!rubberActive) { autoScrollTimer.running = false; return }
        var view = viewMode === "list" ? fileList : (viewMode === "icon" ? fileGrid : null)
        if (!view || !view.visible) { autoScrollTimer.running = false; return }
        var d = autoScrollDir * 30
        view.contentY += d
        rubberStartY -= d
        if (view.contentY < 0) {
            rubberStartY += view.contentY; view.contentY = 0
            autoScrollTimer.running = false
        }
        var maxY = Math.max(0, view.contentHeight - view.height)
        if (view.contentY > maxY) {
            rubberStartY -= (view.contentY - maxY); view.contentY = maxY
            autoScrollTimer.running = false
        }
    }

    function doCompress() {
        if (root.selectedEntries.length === 0) return
        var sources = root.selectedEntries.map(function(e) { return e.path })
        var dir = root.currentPath
        var dst
        if (sources.length === 1) {
            dst = dir + "/" + root.selectedEntries[0].name + ".zip"
        } else {
            dst = dir + "/seleccion.zip"
        }
        root.pushUndo({type: "compress", oldPath: sources, newPath: dst})
        var cmd = [Quickshell.env("HOME") + "/.config/quickshell/scripts/file-browse.py", "compress", dst]
        for (var ci = 0; ci < sources.length; ci++) cmd.push(sources[ci])
        opRunner.command = cmd
        opRunner.running = true
    }

    function doDecompress() {
        if (root.selectedEntries.length !== 1 || !isCompressedArchive(root.selectedEntries[0].name)) return
        var src = root.selectedEntries[0].path
        opRunner.command = [Quickshell.env("HOME") + "/.config/quickshell/scripts/file-browse.py", "decompress", src]
        opRunner.running = true
    }

    function buildCtxModel() {
        var isArch = selectedEntries.length === 1 && isCompressedArchive(selectedEntries[0] && selectedEntries[0].name)
        var hasClip = clipboardPaths.length > 0
        var isTrash = root.currentPath && root.currentPath.indexOf("/.local/share/Trash/files") >= 0
        return [
            { label: "Abrir", action: function() { if (selectedEntries.length > 0) openEntry(selectedEntries[0]); hideCtx() } },
            { label: "Abrir con...", enabled: selectedEntries.length === 1 && selectedEntries[0].type !== "dir", action: function() { showOpenWith(selectedEntries[0]); hideCtx() } },
            { label: "Copiar", action: function() { doCopy(); hideCtx() } },
            { label: "Cortar", action: function() { doCut(); hideCtx() } },
            { label: "Renombrar", action: function() { if (selectedEntries.length === 1) doRename(); hideCtx() } },
            null,
            { label: "Comprimir", action: function() { doCompress(); hideCtx() } },
            { label: "Descomprimir", enabled: isArch, action: function() { doDecompress(); hideCtx() } },
            { label: "Pegar", enabled: hasClip, action: function() { doPaste(); hideCtx() } },
            null,
            { label: "Mover a papelera", action: function() { doTrash(); hideCtx() } },
            { label: "Restaurar", enabled: isTrash, action: function() { doRestore(); hideCtx() } },
            { label: "Eliminar permanentemente", action: function() { promptDelete(); hideCtx() }, sepColor: Theme.accentRed }
        ]
    }

    function buildEmptyCtxModel() {
        var hasSel = selectedEntries.length > 0
        var hasClip = clipboardPaths.length > 0
        var isTrash = root.currentPath && root.currentPath.indexOf("/.local/share/Trash/files") >= 0
        return [
            { label: "Abrir", enabled: hasSel, action: function() { if (hasSel) openEntry(selectedEntries[0]); hideEmptyCtx() } },
            { label: "Copiar", enabled: hasSel, action: function() { if (hasSel) doCopy(); hideEmptyCtx() } },
            { label: "Cortar", enabled: hasSel, action: function() { if (hasSel) doCut(); hideEmptyCtx() } },
            null,
            { label: "Pegar", enabled: hasClip, action: function() { if (hasClip) doPaste(); hideEmptyCtx() } },
            null,
            { label: "Mover a papelera", enabled: hasSel, action: function() { if (hasSel) doTrash(); hideEmptyCtx() } },
            { label: "Restaurar", enabled: isTrash && hasSel, action: function() { if (isTrash && hasSel) doRestore(); hideEmptyCtx() } },
            { label: "Eliminar permanentemente", enabled: hasSel, action: function() { if (hasSel) { promptDelete(); hideEmptyCtx() } }, sepColor: Theme.accentRed },
            null,
            { label: "+ Crear nuevo", submenu: "crear" },
            { label: "\u21C5 Ordenar por", submenu: "ordenar" },
            { label: "\u2630 Visualizaci\u00F3n", submenu: "visualizar" },
        ]
    }

    function doDuplicate() {
        if (selectedEntries.length === 0) return
        var e = selectedEntries[0]
        var src = e.path
        var dir = src.substring(0, src.lastIndexOf("/"))
        var name = e.name
        var ext = name.indexOf(".") >= 0 ? name.substring(name.lastIndexOf(".")) : ""
        var base = ext ? name.substring(0, name.lastIndexOf(".")) : name
        var dst = dir + "/" + base + " (copia)" + ext
        root.pushUndo({type: "duplicate", oldPath: src, newPath: dst})
        opRunner.command = [Quickshell.env("HOME") + "/.config/quickshell/scripts/file-browse.py", "copy", src, dst]
        opRunner.running = true
    }

    function copyLocation() {
        var scr = Quickshell.env("HOME") + "/.config/quickshell/scripts/file-browse.py"
        clipWriter.command = [scr, "clipboard", root.currentPath]
        clipWriter.running = true
    }

    function showOpenWith(entry) {
        openWithFile = entry
        openWithFilter = ""
        var scr = Quickshell.env("HOME") + "/.config/quickshell/scripts/open-with.py"
        openWithLister.command = [scr, "list", entry.path]
        openWithLister.running = true
        openWithVisible = true
    }

    function buildOpenWithModel() {
        var filter = root.openWithFilter.toLowerCase()
        var result = []
        for (var i = 0; i < root.openWithApps.length; i++) {
            var app = root.openWithApps[i]
            if (filter === "" || app.name.toLowerCase().indexOf(filter) >= 0) {
                result.push(app)
            }
        }
        return result
    }

    function launchWithApp(app) {
        var scr = Quickshell.env("HOME") + "/.config/quickshell/scripts/open-with.py"
        var bscr = Quickshell.env("HOME") + "/.config/quickshell/scripts/file-browse.py"
        Quickshell.execDetached([scr, "launch", root.openWithFile.path, app.exec])
        Quickshell.execDetached([bscr, "append_recent", root.openWithFile.path])
        root.openWithVisible = false
        root.forceActiveFocus()
    }

    function showProperties() {
        var entry = lastSelectedEntry || (selectedEntries.length > 0 ? selectedEntries[0] : null)
        if (!entry) return
        Qt.openUrlExternally("file://" + entry.path)
    }

    function goBack() {
        if (historyIndex > 0) {
            historyIndex--
            var hist = JSON.parse(historyStack)
            navigateTo(hist[historyIndex], true)
        }
    }

    function goForward() {
        if (historyIndex < JSON.parse(historyStack).length - 1) {
            historyIndex++
            navigateTo(JSON.parse(historyStack)[historyIndex], true)
        }
    }

    function pushHistory(path) {
        var hist = JSON.parse(historyStack)
        if (hist.length > 0 && hist[hist.length - 1] === path) return
        hist.push(path)
        if (hist.length > 50) hist.shift()
        historyIndex = hist.length - 1
        historyStack = JSON.stringify(hist)
    }

    FileView {
        id: bmFile
        path: ""
        blockLoading: true
    }

    FileView {
        id: prefDataFile
        path: ""
        blockLoading: true
    }

    function loadBookmarks() {
        bmFile.path = "file://" + Quickshell.env("HOME") + "/.config/quickshell/bookmarks.json"
        try { bookmarks = JSON.parse(bmFile.text()) } catch(e) { bookmarks = [] }
    }

    function saveBookmarks() {
        bmFile.path = "file://" + Quickshell.env("HOME") + "/.config/quickshell/bookmarks.json"
        bmFile.setText(JSON.stringify(bookmarks, null, 2))
    }

    function loadFilePreferences() {
        prefDataFile.path = "file://" + Quickshell.env("HOME") + "/.config/quickshell/file-preferences.json"
        try {
            var data = JSON.parse(prefDataFile.text())
            if (data.viewMode) root.pref_viewMode = data.viewMode
            if (data.sortMode) root.pref_sortMode = data.sortMode
            if (data.showHiddenOnStart !== undefined) root.pref_showHiddenOnStart = data.showHiddenOnStart
            if (data.confirmDelete !== undefined) root.pref_confirmDelete = data.confirmDelete
            if (data.singleClickNav !== undefined) root.pref_singleClickNav = data.singleClickNav
            if (data.sidebarWidth) root.pref_sidebarWidth = data.sidebarWidth
            if (data.previewWidth) root.pref_previewWidth = data.previewWidth
        } catch(e) {}
        applyFilePreferences()
    }

    function applyFilePreferences() {
        root.showHidden = root.pref_showHiddenOnStart
        root.confirmDelete = root.pref_confirmDelete
        root.singleClickNav = root.pref_singleClickNav
        root.sidebarWidth = root.pref_sidebarWidth
        root.previewWidth = root.pref_previewWidth
    }

    function saveFilePreferences() {
        var data = {
            viewMode: root.pref_viewMode,
            sortMode: root.pref_sortMode,
            showHiddenOnStart: root.pref_showHiddenOnStart,
            confirmDelete: root.pref_confirmDelete,
            singleClickNav: root.pref_singleClickNav,
            sidebarWidth: root.pref_sidebarWidth,
            previewWidth: root.pref_previewWidth
        }
        prefDataFile.path = "file://" + Quickshell.env("HOME") + "/.config/quickshell/file-preferences.json"
        prefDataFile.setText(JSON.stringify(data, null, 2))
        root.prefPanelVisible = false
    }

    function addBookmark(p) {
        if (bookmarks.indexOf(p) === -1) {
            bookmarks = bookmarks.concat([p])
            saveBookmarks()
        }
    }

    function removeBookmark(p) {
        var idx = bookmarks.indexOf(p)
        if (idx !== -1) {
            var newBm = bookmarks.slice()
            newBm.splice(idx, 1)
            bookmarks = newBm
            saveBookmarks()
        }
    }

    function buildBookmarkMenuItems() {
        var items = [
            { label: "< Volver a Ir", action: function() { menuOpen = "Ir" } }
        ]
        if (root.bookmarks.length === 0) {
            items.push({ label: "(sin marcadores)", action: function() { setMenu("") } })
        } else {
            for (var i = 0; i < root.bookmarks.length; i++) {
                var p = root.bookmarks[i]
                var parts = p.replace(/\/+$/, "").split("/")
                var name = parts[parts.length - 1] || p
                items.push({ label: "  " + name, action: function(path) {
                    return function() { navigateTo(path); setMenu("") }
                }(p) })
                items.push({ label: "    \u2716 Eliminar", action: function(path) {
                    return function() { removeBookmark(path); }
                }(p) })
                if (i < root.bookmarks.length - 1) items.push(null)
            }
        }
        return items
    }

    function zoomIn() {
        zoomLevel = Math.min(2.0, zoomLevel + 0.1)
    }

    function zoomOut() {
        zoomLevel = Math.max(0.5, zoomLevel - 0.1)
    }

    function zoomReset() {
        zoomLevel = 1.0
    }

    function setSortMode(mode) {
        sortMode = mode
        root.saveState()
    }

    function setViewMode(mode) {
        viewMode = mode
        if (mode === "detailed" && root.entries.length > 0) {
            root.buildDetailedTree()
        } else {
            loadDir()
        }
        root.saveState()
    }

    function saveState() {
        root.pathState[root.currentPath] = {
            viewMode: root.viewMode,
            sortMode: root.sortMode
        }
        stateWriter.command = [
            "python3", "-c",
            "import sys,json; open(sys.argv[1],'w').write(sys.argv[2])",
            root.stateFilePath,
            JSON.stringify(root.pathState)
        ]
        stateWriter.running = true
    }

    function loadState() {
        stateLoader.command = [
            "python3", "-c",
            "import sys,json,os; p=sys.argv[1]; print(json.dumps(json.load(open(p)) if os.path.exists(p) else {}))",
            root.stateFilePath
        ]
        stateLoader.running = true
    }

    function toggleHidden() {
        showHidden = !showHidden
        loadDir()
    }

    function toggleExtraInfo() {
        filterText = filterText ? "" : "extraInfo"
    }

    function toggleFilter() {
        if (searchActive) { searchActive = false; searchQuery = "" }
        filterInputVisible = !filterInputVisible
        if (!filterInputVisible) { filterText = ""; applyFilter() }
        if (filterInputVisible) Qt.callLater(function() { if (filterInput) filterInput.forceActiveFocus() })
    }

    function toggleSearch() {
        if (filterInputVisible) { filterInputVisible = false; filterText = ""; applyFilter() }
        searchActive = !searchActive
        if (!searchActive) { searchQuery = ""; root.searchResults = [] }
        if (searchActive) Qt.callLater(function() { if (searchField) searchField.forceActiveFocus() })
    }

    function applyFilter() {
        if (filterText === "") {
            root.displayEntries = root.entries
        } else {
            var q = filterText.toLowerCase()
            var filtered = []
            for (var i = 0; i < root.entries.length; i++) {
                if (root.entries[i].name.toLowerCase().indexOf(q) >= 0)
                    filtered.push(root.entries[i])
            }
            root.displayEntries = filtered
        }
    }

    function setMenu(m) {
        if (m !== menuOpen) contextMenu.visible = false
        root.fileCreateVisible = false
        menuOpen = menuOpen === m ? "" : m
    }

    function doUndo() {
        if (root.undoStack.length === 0) return
        var op = root.undoStack.pop()
        root.redoStack.push(op)
        if (root.redoStack.length > 50) root.redoStack.shift()
        var scr = Quickshell.env("HOME") + "/.config/quickshell/scripts/file-browse.py"
        opRunner.command = [scr, "revert", JSON.stringify(op)]
        opRunner.running = true
    }

    function doRedo() {
        if (root.redoStack.length === 0) return
        var op = root.redoStack.pop()
        root.undoStack.push(op)
        if (root.undoStack.length > 50) root.undoStack.shift()
        var scr = Quickshell.env("HOME") + "/.config/quickshell/scripts/file-browse.py"
        if (op.type === "rename") {
            opRunner.command = [scr, "rename", op.oldPath, op.newPath]
        } else if (op.type === "create" || op.type === "mkdir") {
            opRunner.command = [scr, "create", op.path, op.fileType || "empty"]
        } else if (op.type === "copy") {
            var copySrc = op.oldPath; var copyDst = op.newPath
            opRunner.command = [scr, "copy", op.oldPath, op.newPath]
        } else if (op.type === "move") {
            opRunner.command = [scr, "move", op.oldPath, op.newPath]
        } else if (op.type === "duplicate") {
            opRunner.command = [scr, "copy", op.oldPath, op.newPath]
        } else if (op.type === "compress") {
            var cmd2 = [scr, "compress", op.newPath]
            if (Array.isArray(op.oldPath)) {
                for (var ci = 0; ci < op.oldPath.length; ci++) cmd2.push(op.oldPath[ci])
            } else {
                cmd2.push(op.oldPath)
            }
            opRunner.command = cmd2
        } else {
            opRunner.command = [scr, "revert", JSON.stringify(op)]
        }
        opRunner.running = true
    }

    function pushUndo(op) {
        root.undoStack.push(op)
        if (root.undoStack.length > 50) root.undoStack.shift()
        root.redoStack = []
    }

    function doSearch(query) {
        if (!query || query.length < 2) return
        var scr = Quickshell.env("HOME") + "/.config/quickshell/scripts/file-browse.py"
        searchRunner.command = [scr, "search", root.currentPath, query, "100"]
        searchRunner.running = true
    }

    property bool extraInfo: false
    signal newWindowRequested(string path)
    signal requestClose()

    Component.onCompleted: {
        if (!currentPath) currentPath = Quickshell.env("HOME")
        tabs = [{ path: currentPath, entries: [], selectedEntries: [], lastSelectedEntry: null, historyStack: "[]", historyIndex: -1 }]
        currentTabIndex = 0
        pushHistory(currentPath)
        loadDir()
        loadSidebar()
        loadState()
        loadBookmarks()
        loadFilePreferences()
        loadDir()
    }

    function loadSidebar() {
        var scr = Quickshell.env("HOME") + "/.config/quickshell/scripts/file-browse.py"
        sidebarLoader.command = [scr, "xdg_dirs"]
        sidebarLoader.running = true
        recentLoader.command = [scr, "recent_files", "15"]
        recentLoader.running = true
        deviceLister.command = [scr, "list_devices"]
        deviceLister.running = true
    }

    function refreshRecent() {
        var scr = Quickshell.env("HOME") + "/.config/quickshell/scripts/file-browse.py"
        recentLoader.command = [scr, "recent_files", "15"]
        recentLoader.running = true
    }

    onSelectedEntriesChanged: {
        if (tabSwitchInProgress) return
        previewText = ""
        pdfPreviewSource = ""
        var entry = lastSelectedEntry || (selectedEntries.length > 0 ? selectedEntries[0] : null)
        if (!entry || entry.type === "dir") return
        var scr = Quickshell.env("HOME") + "/.config/quickshell/scripts/file-browse.py"

        if (isText(entry)) {
            if (entry.name.toLowerCase().endsWith(".doc")) {
                textReader.command = ["catdoc", entry.path]
            } else {
                textReader.command = [scr, "read", entry.path]
            }
            textReader.running = true
        } else if (isPdf(entry)) {
            pdfPreviewer.command = [scr, "pdfpreview", entry.path, "/tmp/qs_pdf_preview.jpg", "360"]
            pdfPreviewer.running = true
        }
    }

    Connections {
        target: root
        function onVisibleChanged() {
            if (root.visible) { loadDir(); loadSidebar(); Qt.callLater(root.forceActiveFocus) }
        }
    }

    Process {
        id: loader
        running: false
        command: [Quickshell.env("HOME") + "/.config/quickshell/scripts/file-browse.py", "list", currentPath, root.sortMode, root.showHidden ? "1" : "0"]
        stdout: SplitParser {
                onRead: function(data) {
                try {
                    var parsed = JSON.parse(data.trim())
                    if (parsed.entries) {
                        root.entries = parsed.entries
                        root.applyFilter()
                        root.saveCurrentTab()
                        root.buildDetailedTree()
                        root.refreshExpandedDirs()
                    }
                } catch(e) {}
            }
        }
    }

    Process {
        id: opRunner
        running: false
        stdout: SplitParser {
            onRead: function(data) {
                loadDir()
            }
        }
    }

    Timer {
        id: autoScrollTimer
        interval: 30
        repeat: true
        onTriggered: root.autoScrollStep()
    }

    Process {
        id: treeLoader
        running: false
        property string loadPath: ""
        stdout: SplitParser {
            onRead: function(data) {
                try {
                    var parsed = JSON.parse(data.trim())
                    if (parsed.entries) {
                        root.expandedDirContents[treeLoader.loadPath] = parsed.entries
                        root.buildDetailedTree()
                        root.processRefreshQueue()
                    }
                } catch(e) {}
            }
        }
    }

    Process {
        id: searchRunner
        running: false
        stdout: SplitParser {
            onRead: function(data) {
                try {
                    var parsed = JSON.parse(data.trim())
                    if (parsed.entries) {
                        root.searchResults = parsed.entries
                    }
                } catch(e) {}
            }
        }
    }

    Process {
        id: clipWriter
        running: false
    }

    Process {
        id: textReader
        running: false
        stdout: SplitParser {
            onRead: function(data) {
                try {
                    var parsed = JSON.parse(data.trim())
                    if (parsed.content) root.previewText = parsed.content
                } catch(e) {}
            }
        }
    }

    Process {
        id: pdfPreviewer
        running: false
        stdout: SplitParser {
            onRead: function(data) {
                try {
                    var parsed = JSON.parse(data.trim())
                    if (parsed.success) {
                        root.pdfPreviewSource = "file:///tmp/qs_pdf_preview.jpg?t=" + Date.now()
                    }
                } catch(e) {}
            }
        }
    }

    Process {
        id: sidebarLoader
        running: false
        stdout: SplitParser {
            onRead: function(data) {
                try {
                    var parsed = JSON.parse(data.trim())
                    if (parsed.success) root.sidebarDirs = parsed
                } catch(e) {}
            }
        }
    }

    Process {
        id: recentLoader
        running: false
        stdout: SplitParser {
            onRead: function(data) {
                try {
                    var parsed = JSON.parse(data.trim())
                    if (parsed.success) root.recentFiles = parsed.files || []
                } catch(e) {}
            }
        }
    }

    Process {
        id: deviceLister
        running: false
        stdout: SplitParser {
            onRead: function(data) {
                try {
                    var parsed = JSON.parse(data.trim())
                    if (parsed.success) root.devices = parsed.devices || {}
                } catch(e) {}
            }
        }
    }

    Process {
        id: clipboardWriter
        running: false
    }

    Process {
        id: openWithLister
        running: false
        stdout: SplitParser {
            onRead: function(data) {
                try {
                    root.openWithApps = JSON.parse(data.trim())
                } catch(e) {}
            }
        }
    }

    Process {
        id: devOperator
        running: false
        stdout: SplitParser {
            onRead: function(data) {
                try {
                    var parsed = JSON.parse(data.trim())
                    if (!parsed.success) {
                        var errorMsg = (root.deviceOpName ? root.deviceOpName + ": " : "") + (parsed.error || "Error desconocido")
                        root.deviceError = errorMsg + " (copiado)"
                        clearErrorTimer.restart()
                        var clipScr = Quickshell.env("HOME") + "/.config/quickshell/scripts/file-browse.py"
                        clipboardWriter.command = [clipScr, "clipboard", errorMsg]
                        clipboardWriter.running = true
                    }
                } catch(e) {}
                deviceLister.running = true
            }
        }
    }

    Timer {
        id: clearErrorTimer
        interval: 5000
        onTriggered: root.deviceError = ""
    }

    Timer {
        id: deviceRefreshTimer
        interval: 10000
        repeat: true
        running: true
        onTriggered: {
            var scr = Quickshell.env("HOME") + "/.config/quickshell/scripts/file-browse.py"
            deviceLister.command = [scr, "list_devices"]
            deviceLister.running = true
        }
    }

    Column {
        anchors.fill: parent
        spacing: 4

        Item {
            width: parent.width
            height: 28

            Row {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                spacing: 4

                Rectangle {
                    width: 24; height: 24; radius: Theme.radius4
                    color: upMa.containsMouse ? Theme.surfaceHover : Theme.surface; border.color: Theme.border; border.width: 1
                    Text { anchors.centerIn: parent; font.family: Theme.fontFamily; font.pixelSize: 11; color: Theme.textPrimary; text: "\uF060" }
                    MouseArea { id: upMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: goUp() }
                }

                Rectangle {
                    width: 24; height: 24; radius: Theme.radius4
                    color: homeMa.containsMouse ? Theme.surfaceHover : Theme.surface; border.color: Theme.border; border.width: 1
                    Text { anchors.centerIn: parent; font.family: Theme.fontFamily; font.pixelSize: 11; color: Theme.textPrimary; text: "\uF015" }
                    MouseArea { id: homeMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: goHome() }
                }
            }

            Rectangle {
                anchors.left: parent.left; anchors.leftMargin: 56
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                height: 22
                radius: Theme.radius4
                color: pathMa.containsMouse ? Theme.surfaceHover : Theme.surface
                border.color: Theme.border
                border.width: 1

                Text {
                    anchors.left: parent.left; anchors.leftMargin: 6
                    anchors.verticalCenter: parent.verticalCenter
                    font.family: Theme.fontFamily; font.pixelSize: 11
                    color: Theme.textPrimary
                    elide: Text.ElideLeft
                    text: currentPath
                    width: parent.width - 12
                }

                MouseArea {
                    id: pathMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.IBeamCursor
                    onDoubleClicked: {
                        pathInput.text = currentPath
                        pathInput.visible = true
                        pathInput.forceActiveFocus()
                        pathInput.selectAll()
                    }
                }

                TextInput {
                    id: pathInput
                    visible: false
                    anchors.fill: parent
                    anchors.leftMargin: 6
                    anchors.rightMargin: 6
                    font.family: Theme.fontFamily; font.pixelSize: 11
                    color: Theme.textPrimary
                    verticalAlignment: TextInput.AlignVCenter

                    onEditingFinished: {
                        if (text.trim()) navigateTo(text.trim())
                        visible = false
                    }

                    Keys.onEscapePressed: visible = false
                }
            }
        }

        Rectangle {
            width: parent.width; height: 1; color: Theme.border
        }

        Item {
            width: parent.width; height: 24
            Row {
                anchors.left: parent.left; anchors.leftMargin: 4
                anchors.verticalCenter: parent.verticalCenter
                spacing: 4
                Repeater {
                    model: ["Archivo", "Editar", "Ver", "Ir", "Herramientas", "Preferencias"]
                    delegate: Item {
                        height: 24; width: label.contentWidth + 16
                        Rectangle {
                            anchors.fill: parent; radius: Theme.radius4
                            color: menuOpen === modelData ? Theme.surfaceHover : (ma.containsMouse ? Theme.surfaceHover : "transparent")
                        }
                        Text {
                            id: label
                            anchors.centerIn: parent
                            font.family: Theme.fontFamily; font.pixelSize: 11
                            color: menuOpen === modelData ? Theme.accent : Theme.textPrimary
                            text: modelData
                        }
                        MouseArea {
                            id: ma; anchors.fill: parent; hoverEnabled: true
                            onClicked: {
                                root.menuTargetX = mapToItem(root, 0, 0).x
                                root.setMenu(menuOpen === modelData ? "" : modelData)
                            }
                        }
                    }
                }
            }
        }

        // ── Tab bar ──
        Item {
            width: parent.width; height: 24
            Row {
                anchors.left: parent.left; anchors.leftMargin: 4
                anchors.verticalCenter: parent.verticalCenter
                spacing: 2
                Repeater {
                    model: root.tabs
                    delegate: Item {
                        height: 22; width: 130
                        Rectangle {
                            anchors.fill: parent; radius: Theme.radius4
                            color: index === root.currentTabIndex ? Theme.surfaceHover : (ma.containsMouse ? Theme.surfaceHover : "transparent")
                        }
                        Text {
                            anchors.left: parent.left; anchors.leftMargin: 6
                            anchors.verticalCenter: parent.verticalCenter
                            font.family: Theme.fontFamily; font.pixelSize: 10
                            color: index === root.currentTabIndex ? Theme.accent : Theme.textPrimary
                            elide: Text.ElideRight; width: parent.width - 22
                            text: {
                                var p = modelData.path
                                var parts = p.replace(/\/+$/, "").split("/")
                                return parts.length > 1 ? parts[parts.length - 1] : p
                            }
                        }
                        MouseArea {
                            id: ma; anchors.fill: parent; hoverEnabled: true
                            onClicked: root.switchTab(index)
                        }
                        Text {
                            anchors.right: parent.right; anchors.rightMargin: 2
                            anchors.verticalCenter: parent.verticalCenter
                            font.family: Theme.fontFamily; font.pixelSize: 10
                            color: ma2.containsMouse ? Theme.accentRed : Theme.textSecondary
                            text: "\u2715"
                            visible: true
                            MouseArea {
                                id: ma2; anchors.fill: parent; hoverEnabled: true
                                onClicked: root.closeTab(index)
                            }
                        }
                    }
                }
                Item {
                    width: 20; height: 22
                    Text {
                        anchors.centerIn: parent
                        font.family: Theme.fontFamily; font.pixelSize: 14
                        color: plusMa.containsMouse ? Theme.accent : Theme.textSecondary
                        text: "+"
                    }
                    MouseArea {
                        id: plusMa; anchors.fill: parent; hoverEnabled: true
                        onClicked: root.addTab(root.currentPath)
                    }
                }
            }
        }

        // ── Filter bar ──
        Item {
            visible: root.filterInputVisible
            width: parent.width; height: 22
            anchors.left: parent.left; anchors.right: parent.right
            anchors.leftMargin: 4; anchors.rightMargin: 4

            Rectangle {
                anchors.fill: parent
                color: Theme.surface
                border.color: filterInput.activeFocus ? Theme.accent : Theme.border
                border.width: 1
                radius: Theme.radius4
            }

            TextInput {
                id: filterInput
                anchors.fill: parent; anchors.leftMargin: 6
                font.family: Theme.fontFamily; font.pixelSize: 11
                color: Theme.textPrimary
                verticalAlignment: TextInput.AlignVCenter
                text: root.filterText
                onTextChanged: {
                    root.filterText = text
                    root.applyFilter()
                }
                Keys.onEscapePressed: { root.toggleFilter() }
            }

            Text {
                anchors.right: parent.right; anchors.rightMargin: 6
                anchors.verticalCenter: parent.verticalCenter
                font.family: Theme.fontFamily; font.pixelSize: 9
                color: Theme.textSecondary
                text: "\u2715"
                visible: filterInput.text !== ""
                MouseArea {
                    anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                    onClicked: { filterInput.text = ""; root.filterText = ""; root.applyFilter() }
                }
            }

            Text {
                anchors.left: parent.left; anchors.leftMargin: 6
                anchors.verticalCenter: parent.verticalCenter
                font.family: Theme.fontFamily; font.pixelSize: 9
                color: Theme.textSecondary
                text: "Filtrar archivos..."
                visible: filterInput.text === "" && !filterInput.activeFocus
            }
        }

        // ── Search bar ──
        Item {
            visible: root.searchActive
            width: parent.width; height: 22
            anchors.left: parent.left; anchors.right: parent.right
            anchors.leftMargin: 4; anchors.rightMargin: 4

            Rectangle {
                anchors.fill: parent
                color: Theme.surface
                border.color: searchField.activeFocus ? Theme.accent : Theme.border
                border.width: 1
                radius: Theme.radius4
            }

            TextInput {
                id: searchField
                anchors.fill: parent; anchors.leftMargin: 6
                font.family: Theme.fontFamily; font.pixelSize: 11
                color: Theme.textPrimary
                verticalAlignment: TextInput.AlignVCenter
                text: root.searchQuery
                onTextChanged: {
                    root.searchQuery = text
                    if (text.length >= 2) doSearch(text)
                    else if (text.length === 0) root.searchResults = []
                }
                Keys.onEscapePressed: { root.toggleSearch() }
            }

            Text {
                anchors.left: parent.left; anchors.leftMargin: 6
                anchors.verticalCenter: parent.verticalCenter
                font.family: Theme.fontFamily; font.pixelSize: 9
                color: Theme.textSecondary
                text: "Buscar archivos..."
                visible: searchField.text === "" && !searchField.activeFocus
            }
        }

        Row { id: mainRow
            width: parent.width
            height: parent.height - 130
            spacing: 2
            clip: true

            Item {
                id: sidebar
                width: root.sidebarWidth
                height: parent.height
                clip: true

                Flickable {
                    anchors.fill: parent
                    anchors.margins: 4
                    contentHeight: sideCol.implicitHeight
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds
                    ScrollBar.vertical: ScrollBar {
                        policy: ScrollBar.AsNeeded
                        width: 4
                    }

                MouseArea {
                    anchors.fill: parent; z: -1
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    onClicked: { root.selectedEntries = []; root.lastSelectedEntry = null; hideAll() }
                }
                Column {
                    id: sideCol
                    width: parent.width
                    spacing: 2

                    Text {
                        font.family: Theme.fontFamily; font.pixelSize: 9; font.bold: true
                        color: Theme.textSecondary
                        text: "ACCESOS DIRECTOS"
                        leftPadding: 6; bottomPadding: 2
                    }

                    Repeater {
                        model: [
                            { label: "Carpeta personal", icon: "\uF015", path: root.sidebarDirs.home || "" },
                            { label: "Escritorio", icon: "\uF108", path: root.sidebarDirs.desktop_dir || "" },
                            { label: "Documentos", icon: "\uF1C2", path: root.sidebarDirs.documents_dir || "" },
                            { label: "Descargas", icon: "\uF019", path: root.sidebarDirs.download_dir || "" },
                            { label: "M\u00FAsica", icon: "\uF001", path: root.sidebarDirs.music_dir || "" },
                            { label: "Im\u00E1genes", icon: "\uF1C5", path: root.sidebarDirs.pictures_dir || "" },
                            { label: "Papelera", icon: "\uF1F8", path: "" }
                        ]

                        delegate: Item {
                            height: 22; width: sidebar.width - 8

                            Rectangle {
                                anchors.fill: parent; radius: Theme.radius4
                                color: ma.containsMouse ? Theme.surfaceHover : "transparent"
                            }

                            Row {
                                anchors.left: parent.left; anchors.leftMargin: 4
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 4
                                Text { font.family: Theme.fontFamily; font.pixelSize: 11; color: Theme.textPrimary; text: modelData.icon }
                                Text { font.family: Theme.fontFamily; font.pixelSize: 11; color: Theme.textPrimary; text: modelData.label; elide: Text.ElideRight; width: sidebar.width - 50 }
                            }

                            MouseArea {
                                id: ma; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (modelData.label === "Papelera") {
                                        var home = Quickshell.env("HOME")
                                        navigateTo(home + "/.local/share/Trash/files")
                                    } else if (modelData.path) {
                                        navigateTo(modelData.path)
                                    }
                                }
                            }
                        }
                    }

                    Rectangle { width: parent.width; height: 1; color: Theme.border; }

                    Text {
                        font.family: Theme.fontFamily; font.pixelSize: 9; font.bold: true
                        color: Theme.textSecondary
                        text: "RECIENTES"
                        leftPadding: 6; bottomPadding: 2; topPadding: 2
                    }

                    Rectangle {
                        width: parent.width; height: Math.min(root.recentFiles.length * 20, 100) + 8
                        radius: Theme.radius4; color: Theme.surface
                        border.color: Theme.border; border.width: 1

                        Item {
                            anchors.fill: parent; anchors.margins: 4

                            ListView {
                                anchors.fill: parent
                                model: root.recentFiles
                                clip: true
                                interactive: false

                                delegate: Item {
                                    height: 20; width: parent.width

                                    Rectangle {
                                        anchors.fill: parent; radius: Theme.radius3
                                        color: recMa.containsMouse ? Theme.surfaceHover : Theme.surface
                                        border.color: Theme.border; border.width: 1
                                    }

                                    Text {
                                        anchors.left: parent.left; anchors.leftMargin: 6
                                        anchors.verticalCenter: parent.verticalCenter
                                        font.family: Theme.fontFamily; font.pixelSize: 10
                                        color: Theme.textPrimary; opacity: 0.8
                                        elide: Text.ElideRight; width: parent.width - 12
                                        renderType: Text.QtRendering
                                        text: modelData.name
                                    }

                                    MouseArea {
                                        id: recMa
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            if (modelData.type === "dir")
                                                root.navigateTo(modelData.path)
                                            else
                                                Qt.openUrlExternally("file://" + modelData.path)
                                        }
                                    }
                                }
                            }
                        }
                    }
                    Rectangle { width: parent.width; height: 1; color: Theme.border; }

                    Text {
                        font.family: Theme.fontFamily; font.pixelSize: 9; font.bold: true
                        color: Theme.textSecondary
                        text: "DISPOSITIVOS"
                        leftPadding: 6; bottomPadding: 2; topPadding: 2
                    }

                    Text {
                        visible: root.deviceError !== ""
                        font.family: Theme.fontFamily; font.pixelSize: 8
                        color: Theme.accentRed
                        text: root.deviceError
                        leftPadding: 6; bottomPadding: 2; topPadding: 2
                        wrapMode: Text.WordWrap
                        width: parent.width - 12
                    }

                    Repeater {
                        id: devRepeater
                        model: {
                            var devs = root.devices.blockdevices || []
                            var parts = []
                            for (var i = 0; i < devs.length; i++) {
                                var dev = devs[i]
                                if (!dev.children) continue
                                for (var j = 0; j < dev.children.length; j++) {
                                    var child = dev.children[j]
                                    if (child.type !== "part") continue
                                    if (child.name === "nvme0n1p2" || child.name === "sda2" || child.rm == 1) {
                                        parts.push(child)
                                    }
                                }
                            }
                            parts.sort(function(a, b) { return (a.label || a.name).localeCompare(b.label || b.name) })
                            return parts
                        }

                        delegate: Item {
                            height: 38; width: sidebar.width - 8

                            Rectangle {
                                anchors.fill: parent; radius: Theme.radius4
                                color: ma.containsMouse ? Theme.surfaceHover : "transparent"
                            }

                            Column {
                                anchors.left: parent.left; anchors.leftMargin: 6
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 2

                                Text {
                                    font.family: Theme.fontFamily; font.pixelSize: 10; color: Theme.textPrimary
                                    text: modelData.label || modelData.name
                                    elide: Text.ElideRight
                                    width: sidebar.width - 80
                                }

                                Row {
                                    spacing: 4
                                    visible: modelData.mountpoint && modelData.mountpoint !== ""

                                    Rectangle {
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: Math.min(sidebar.width - 110, 70)
                                        height: 6; radius: 3
                                        color: Theme.border
                                        Rectangle {
                                            anchors.left: parent.left; anchors.top: parent.top; anchors.bottom: parent.bottom
                                            radius: 3
                                            width: parent.width * (Number(modelData.fsuse_perc || "0") / 100)
                                            color: Theme.accent
                                        }
                                    }

                                    Text {
                                        font.family: Theme.fontFamily; font.pixelSize: 8; color: Theme.textSecondary
                                        text: (modelData["fsused"] || "?") + " / " + (modelData.size || "?")
                                        anchors.verticalCenter: parent.verticalCenter
                                    }
                                }

                                Text {
                                    font.family: Theme.fontFamily; font.pixelSize: 8; color: Theme.textSecondary
                                    text: modelData.size + "  " + (modelData.fstype || "")
                                    visible: !modelData.mountpoint || modelData.mountpoint === ""
                                }
                            }

                            Text {
                                id: mountBtn
                                z: 1
                                anchors.right: parent.right; anchors.rightMargin: 4
                                anchors.top: parent.top; anchors.topMargin: 4
                                font.family: Theme.fontFamily; font.pixelSize: 9
                                color: modelData.mountpoint ? Theme.accent : Theme.textSecondary
                                text: modelData.mountpoint ? "Desmontar" : "Montar"

                                MouseArea {
                                    anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        var scr = Quickshell.env("HOME") + "/.config/quickshell/scripts/file-browse.py"
                                        var path = "/dev/" + modelData.name
                                        root.deviceOpName = (modelData.label || modelData.name)
                                        if (modelData.fstype === "ntfs") {
                                            var user = Quickshell.env("USER")
                                            var label = (modelData.label || modelData.name)
                                            var mountPoint = "/run/media/" + user + "/" + label
                                            if (modelData.mountpoint) {
                                                Quickshell.execDetached(["kitty", "-e", "bash", "-c", "sudo umount '" + path + "'; echo; echo 'Presiona Enter para cerrar...'; read"])
                                            } else {
                                                Quickshell.execDetached(["kitty", "-e", "bash", "-c", "sudo mkdir -p '" + mountPoint + "' && sudo mount -t ntfs-3g '" + path + "' '" + mountPoint + "'; echo; echo 'Presiona Enter para cerrar...'; read"])
                                            }
                                        } else {
                                            if (modelData.mountpoint) {
                                                devOperator.command = [scr, "unmount_device", path]
                                            } else {
                                                devOperator.command = [scr, "mount_device", path]
                                            }
                                            devOperator.running = true
                                        }
                                    }
                                }
                            }

                            MouseArea {
                                id: ma; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (modelData.mountpoint) {
                                        root.navigateTo(modelData.mountpoint)
                                    }
                                }
                            }
                    }
                }
            }
            }
        }

            Item {
                id: listContentWrapper
                width: Math.max(60, parent.width - root.sidebarWidth - 5 - (lastSelectedEntry && lastSelectedEntry.type !== "dir" ? root.previewWidth + 8 : 0))
                height: parent.height

                Item {
                    y: 0
                    width: parent.width
                    height: 18
                    z: 5
                    visible: (root.viewMode === "list" && root.displayEntries.length > 0) || (root.viewMode === "detailed" && root.detailedEntries.length > 0)

                    Rectangle {
                        anchors.fill: parent
                        color: Theme.surface
                        opacity: 0.5
                    }

                    Row {
                        anchors.left: parent.left; anchors.leftMargin: 4
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 0

                        Item { width: root.colIconGap; height: 1 }

                        Text {
                            text: "Nombre"
                            font.family: Theme.fontFamily
                            font.pixelSize: 9
                            font.bold: true
                            color: Theme.textSecondary
                            width: root.colNameWidth
                            elide: Text.ElideRight
                        }

                        Item {
                            width: 8; height: parent.height
                            Rectangle { anchors.centerIn: parent; width: 1; height: 10; color: Theme.border; opacity: 0.6 }
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.SizeHorCursor
                                property real startX: 0
                                property real startW: 0
                                onPressed: { startX = mouseX; startW = root.colNameWidth }
                                onPositionChanged: {
                                    if (pressed) {
                                        var minW = 60
                                        var maxW = listContentWrapper.width - root.colSizeWidth - root.colDateWidth - root.colIconGap - 16
                                        root.colNameWidth = Math.max(minW, Math.min(maxW, startW + mouseX - startX))
                                    }
                                }
                            }
                        }

                        Text {
                            text: "Tama\u00F1o"
                            font.family: Theme.fontFamily
                            font.pixelSize: 9
                            font.bold: true
                            color: Theme.textSecondary
                            width: root.colSizeWidth
                            horizontalAlignment: Text.AlignRight
                        }

                        Item {
                            width: 8; height: parent.height
                            Rectangle { anchors.centerIn: parent; width: 1; height: 10; color: Theme.border; opacity: 0.6 }
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.SizeHorCursor
                                property real startX: 0
                                property real startW: 0
                                onPressed: { startX = mouseX; startW = root.colSizeWidth }
                                onPositionChanged: {
                                    if (pressed) {
                                        var minS = 50
                                        var maxS = listContentWrapper.width - root.colNameWidth - root.colDateWidth - root.colIconGap - 16
                                        root.colSizeWidth = Math.max(minS, Math.min(maxS, startW + mouseX - startX))
                                    }
                                }
                            }
                        }

                        Text {
                            text: "Fecha"
                            font.family: Theme.fontFamily
                            font.pixelSize: 9
                            font.bold: true
                            color: Theme.textSecondary
                            width: root.colDateWidth
                            horizontalAlignment: Text.AlignRight
                        }

                        Item {
                            width: 6; height: parent.height
                            Rectangle { anchors.centerIn: parent; width: 1; height: 10; color: Theme.border; opacity: 0.6 }
                        }
                    }
                }

                ListView {
                id: fileList
                visible: root.viewMode === "list"
                y: 0
                width: parent.width
                height: parent.height
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                bottomMargin: 40
                topMargin: 18

                model: root.displayEntries

                delegate: Item {
                    required property var modelData
                    width: fileList.width
                    height: Math.round(24 * root.zoomLevel)

                    property bool isDragTarget: root.isDragging && modelData.type === "dir" && root.hoveredDropIndex >= 0 && root.hoveredDropIndex < root.entries.length && root.entries[root.hoveredDropIndex].path === modelData.path

                    Rectangle {
                        anchors.fill: parent
                        color: isDragTarget ? Theme.accent : (root.isSelected(modelData) ? Theme.surfaceHover : dragMa.containsMouse ? Theme.surfaceHover : "transparent")
                        radius: Theme.radius4
                    }

                    Row {
                        anchors.left: parent.left; anchors.leftMargin: 4
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 6

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            font.family: Theme.fontFamily
                            font.pixelSize: Math.round(12 * root.zoomLevel)
                            color: modelData.type === "dir" ? Theme.accentYellow : (modelData.type === "symlink" ? Theme.accentBlue : Theme.textPrimary)
                            text: iconFor(modelData)
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            font.family: Theme.fontFamily
                            font.pixelSize: Math.round(11 * root.zoomLevel)
                            color: Theme.textPrimary
                            width: root.colNameWidth
                            elide: Text.ElideRight
                            text: modelData.name
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            font.family: Theme.fontFamily
                            font.pixelSize: Math.round(10 * root.zoomLevel)
                            color: Theme.textPrimary
                            horizontalAlignment: Text.AlignRight
                            width: root.colSizeWidth
                            opacity: 0.7
                            text: modelData.type === "dir" ? "" : fmtSize(modelData.size)
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            font.family: Theme.fontFamily
                            font.pixelSize: 10
                            color: Theme.textPrimary
                            width: root.colDateWidth
                            horizontalAlignment: Text.AlignRight
                            opacity: 0.6
                            text: fmtTime(modelData.modified)
                        }
                    }

                        MouseArea {
                            id: dragMa
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            acceptedButtons: Qt.LeftButton | Qt.RightButton

                        onPressed: function(mouse) {
                            mouse.accepted = true
                            root.dragPressX = mouse.x
                            root.dragPressY = mouse.y
                            root.dragFilePath = modelData.path
                            root.dragFileName = modelData.name
                            root.isDragging = false
                            root.hoveredDropPath = ""
                            root.hoveredDropIndex = -1
                        }

                        onPositionChanged: function(mouse) {
                            if (!dragMa.pressed) return
                            if (!root.isDragging) {
                                var dx = mouse.x - root.dragPressX
                                var dy = mouse.y - root.dragPressY
                                if (Math.abs(dx) > 10 || Math.abs(dy) > 10) {
                                    root.isDragging = true
                                }
                            }
                            if (root.isDragging) {
                                var pos = mapToItem(root, mouse.x, mouse.y)
                                root.dragCursorX = pos.x
                                root.dragCursorY = pos.y
                                var listPos = mapToItem(fileList, mouse.x, mouse.y)
                                var idx = Math.floor((listPos.y + fileList.contentY) / 24)
                                if (idx >= 0 && idx < root.entries.length && root.entries[idx].type === "dir") {
                                    root.hoveredDropPath = root.entries[idx].path
                                    root.hoveredDropIndex = idx
                                } else {
                                    root.hoveredDropPath = ""
                                    root.hoveredDropIndex = -1
                                }
                            }
                        }

                        onReleased: function(mouse) {
                            if (root.isDragging) {
                                mouse.accepted = true
                                if (root.hoveredDropPath !== "") {
                                    var scr = Quickshell.env("HOME") + "/.config/quickshell/scripts/file-browse.py"
                                    opRunner.command = [scr, "move", root.dragFilePath, root.hoveredDropPath + "/" + root.dragFileName]
                                    opRunner.running = true
                                }
                                root.isDragging = false
                                root.dragFilePath = ""
                                root.dragFileName = ""
                                root.hoveredDropPath = ""
                                root.hoveredDropIndex = -1
                            } else {
                                hideCtx()
                                if (mouse.button === Qt.LeftButton) {
                                    if (mouse.modifiers & Qt.ControlModifier) {
                                        root.toggleSelected(modelData)
                                        root.lastSelectedEntry = modelData
                                    } else {
                                        root.selectedEntries = [modelData]
                                        root.lastSelectedEntry = modelData
                                    }
                                }
                                if (mouse.button === Qt.RightButton) {
                                    root.selectedEntries = [modelData]
                                    root.lastSelectedEntry = modelData
                                    var pos = mapToItem(root, mouse.x, mouse.y)
                                    contextMenu.x = Math.min(pos.x, root.width - contextMenu.width - 4)
                                    contextMenu.anchorY = pos.y
                                    contextMenu.z = 100
                                    contextMenu.visible = true
                                }
                            }
                        }

                        onDoubleClicked: {
                            root.selectedEntries = [modelData]
                            root.lastSelectedEntry = modelData
                            openEntry(modelData)
                        }
                    }
                }
            }

            GridView {
                id: fileGrid
                visible: root.viewMode === "icon"
                width: parent.width
                height: parent.height
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                bottomMargin: 40
                cellWidth: Math.round(80 * root.zoomLevel)
                cellHeight: Math.round(90 * root.zoomLevel)
                model: root.displayEntries

                delegate: Item {
                    required property var modelData
                    width: fileGrid.cellWidth
                    height: fileGrid.cellHeight

                    property bool isDragTarget: root.isDragging && modelData.type === "dir" && root.hoveredDropIndex >= 0 && root.hoveredDropIndex < root.entries.length && root.entries[root.hoveredDropIndex].path === modelData.path

                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: 2
                        radius: Theme.radius4
                        color: isDragTarget ? Theme.accent : (root.isSelected(modelData) ? Theme.surfaceHover : gridMa.containsMouse ? Theme.surfaceHover : "transparent")
                    }

                    Column {
                        anchors.centerIn: parent
                        spacing: 2

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            font.family: Theme.fontFamily
                            font.pixelSize: Math.round(28 * root.zoomLevel)
                            color: modelData.type === "dir" ? Theme.accentYellow : (modelData.type === "symlink" ? Theme.accentBlue : Theme.textPrimary)
                            text: iconFor(modelData)
                        }

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            font.family: Theme.fontFamily
                            font.pixelSize: Math.round(10 * root.zoomLevel)
                            color: Theme.textPrimary
                            width: fileGrid.cellWidth - 8
                            elide: Text.ElideRight
                            horizontalAlignment: Text.AlignHCenter
                            text: modelData.name
                        }
                    }

                        MouseArea {
                            id: gridMa
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            acceptedButtons: Qt.LeftButton | Qt.RightButton

                        onPressed: function(mouse) {
                            mouse.accepted = true
                            root.dragPressX = mouse.x
                            root.dragPressY = mouse.y
                            root.dragFilePath = modelData.path
                            root.dragFileName = modelData.name
                            root.isDragging = false
                            root.hoveredDropPath = ""
                            root.hoveredDropIndex = -1
                        }

                        onPositionChanged: function(mouse) {
                            if (!gridMa.pressed) return
                            if (!root.isDragging) {
                                var dx = mouse.x - root.dragPressX
                                var dy = mouse.y - root.dragPressY
                                if (Math.abs(dx) > 10 || Math.abs(dy) > 10) {
                                    root.isDragging = true
                                }
                            }
                            if (root.isDragging) {
                                var pos = mapToItem(root, mouse.x, mouse.y)
                                root.dragCursorX = pos.x
                                root.dragCursorY = pos.y
                                var gridPos = mapToItem(fileGrid, mouse.x, mouse.y)
                                var idx = fileGrid.indexAt(gridPos.x + fileGrid.contentX, gridPos.y + fileGrid.contentY)
                                if (idx >= 0 && idx < root.entries.length && root.entries[idx].type === "dir") {
                                    root.hoveredDropPath = root.entries[idx].path
                                    root.hoveredDropIndex = idx
                                } else {
                                    root.hoveredDropPath = ""
                                    root.hoveredDropIndex = -1
                                }
                            }
                        }

                        onReleased: function(mouse) {
                            if (root.isDragging) {
                                mouse.accepted = true
                                if (root.hoveredDropPath !== "") {
                                    var scr = Quickshell.env("HOME") + "/.config/quickshell/scripts/file-browse.py"
                                    opRunner.command = [scr, "move", root.dragFilePath, root.hoveredDropPath + "/" + root.dragFileName]
                                    opRunner.running = true
                                }
                                root.isDragging = false
                                root.dragFilePath = ""
                                root.dragFileName = ""
                                root.hoveredDropPath = ""
                                root.hoveredDropIndex = -1
                            } else {
                                hideCtx()
                                if (mouse.button === Qt.LeftButton) {
                                    if (mouse.modifiers & Qt.ControlModifier) {
                                        root.toggleSelected(modelData)
                                        root.lastSelectedEntry = modelData
                                    } else {
                                        root.selectedEntries = [modelData]
                                        root.lastSelectedEntry = modelData
                                    }
                                }
                                if (mouse.button === Qt.RightButton) {
                                    root.selectedEntries = [modelData]
                                    root.lastSelectedEntry = modelData
                                    var pos = mapToItem(root, mouse.x, mouse.y)
                                    contextMenu.x = Math.min(pos.x, root.width - contextMenu.width - 4)
                                    contextMenu.anchorY = pos.y
                                    contextMenu.z = 100
                                    contextMenu.visible = true
                                }
                            }
                        }

                        onDoubleClicked: {
                            root.selectedEntries = [modelData]
                            root.lastSelectedEntry = modelData
                            openEntry(modelData)
                        }
                    }
                }
            }

            ListView {
                id: detailedList
                visible: root.viewMode === "detailed"
                y: 0
                width: parent.width
                height: parent.height
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                bottomMargin: 40
                topMargin: 18

                model: root.detailedEntries

                MouseArea {
                    anchors.fill: parent
                    z: -1
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    onClicked: function(mouse) {
                        root.selectedEntries = []; root.lastSelectedEntry = null
                        hideAll()
                        var pos = mapToItem(root, mouse.x, mouse.y)
                        showEmptyCtxMenu(pos.x, pos.y)
                    }
                }

                delegate: Item {
                    required property var modelData
                    width: detailedList.width
                    height: Math.round(24 * root.zoomLevel)

                    property bool isEmptyPlaceholder: modelData.type === "empty-placeholder"
                    property bool isDragTarget: root.isDragging && modelData.type === "dir" && root.hoveredDropPath === modelData.path

                    Rectangle {
                        anchors.fill: parent
                        color: isEmptyPlaceholder ? "transparent" : (isDragTarget ? Theme.accent : (root.isSelected(modelData) ? Theme.surfaceHover : detMa.containsMouse ? Theme.surfaceHover : "transparent"))
                        radius: Theme.radius4
                    }

                    Row {
                        anchors.left: parent.left; anchors.leftMargin: 4 + modelData.depth * 16
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 4

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            font.family: Theme.fontFamily
                            font.pixelSize: Math.round(10 * root.zoomLevel)
                            color: Theme.textSecondary
                            width: 12
                            text: modelData.type === "dir" ? (root.expandedDirs[modelData.path] && root.expandedDirContents[modelData.path] ? "\u25BC" : "\u25B6") : ""
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            font.family: Theme.fontFamily
                            font.pixelSize: Math.round(12 * root.zoomLevel)
                            visible: !isEmptyPlaceholder
                            color: modelData.type === "dir" ? Theme.accentYellow : (modelData.type === "symlink" ? Theme.accentBlue : Theme.textPrimary)
                            text: iconFor(modelData)
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            font.family: Theme.fontFamily
                            font.pixelSize: isEmptyPlaceholder ? Math.round(10 * root.zoomLevel) : Math.round(11 * root.zoomLevel)
                            color: isEmptyPlaceholder ? Theme.textPrimary : Theme.textPrimary
                            width: isEmptyPlaceholder ? detailedList.width - root.colSizeWidth - root.colDateWidth - root.colIconGap - 24 - modelData.depth * 16 : detailedList.width - root.colSizeWidth - root.colDateWidth - root.colIconGap - 24 - modelData.depth * 16
                            elide: Text.ElideRight
                            opacity: isEmptyPlaceholder ? 0.4 : 1.0
                            text: modelData.name
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            font.family: Theme.fontFamily
                            font.pixelSize: Math.round(10 * root.zoomLevel)
                            color: Theme.textPrimary
                            horizontalAlignment: Text.AlignRight
                            width: root.colSizeWidth
                            opacity: isEmptyPlaceholder ? 0.0 : 0.7
                            text: modelData.type === "dir" ? "" : fmtSize(modelData.size)
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            font.family: Theme.fontFamily
                            font.pixelSize: Math.round(10 * root.zoomLevel)
                            color: Theme.textPrimary
                            width: root.colDateWidth
                            horizontalAlignment: Text.AlignRight
                            opacity: isEmptyPlaceholder ? 0.0 : 0.6
                            text: fmtTime(modelData.modified)
                        }
                    }

                    MouseArea {
                        id: detMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        acceptedButtons: Qt.LeftButton | Qt.RightButton

                        onPressed: function(mouse) {
                            mouse.accepted = true
                            root.dragPressX = mouse.x
                            root.dragPressY = mouse.y
                            root.dragFilePath = modelData.path
                            root.dragFileName = modelData.name
                            root.isDragging = false
                            root.hoveredDropPath = ""
                            root.hoveredDropIndex = -1
                        }

                        onPositionChanged: function(mouse) {
                            if (!detMa.pressed) return
                            if (!root.isDragging) {
                                var dx = mouse.x - root.dragPressX
                                var dy = mouse.y - root.dragPressY
                                if (Math.abs(dx) > 10 || Math.abs(dy) > 10) {
                                    root.isDragging = true
                                }
                            }
                            if (root.isDragging) {
                                var pos = mapToItem(root, mouse.x, mouse.y)
                                root.dragCursorX = pos.x
                                root.dragCursorY = pos.y
                                var listPos = mapToItem(detailedList, mouse.x, mouse.y)
                                var idx = Math.floor((listPos.y + detailedList.contentY) / Math.round(24 * root.zoomLevel))
                                if (idx >= 0 && idx < root.detailedEntries.length && root.detailedEntries[idx].type === "dir") {
                                    root.hoveredDropPath = root.detailedEntries[idx].path
                                    root.hoveredDropIndex = idx
                                } else {
                                    root.hoveredDropPath = ""
                                    root.hoveredDropIndex = -1
                                }
                            }
                        }

                        onReleased: function(mouse) {
                            if (root.isDragging) {
                                mouse.accepted = true
                                if (root.hoveredDropPath !== "") {
                                    var scr = Quickshell.env("HOME") + "/.config/quickshell/scripts/file-browse.py"
                                    opRunner.command = [scr, "move", root.dragFilePath, root.hoveredDropPath + "/" + root.dragFileName]
                                    opRunner.running = true
                                }
                                root.isDragging = false
                                root.dragFilePath = ""
                                root.dragFileName = ""
                                root.hoveredDropPath = ""
                                root.hoveredDropIndex = -1
                            } else {
                                if (modelData.type === "empty-placeholder") return
                                hideCtx()
                                if (mouse.button === Qt.LeftButton) {
                                    if (mouse.modifiers & Qt.ControlModifier) {
                                        root.toggleSelected(modelData)
                                        root.lastSelectedEntry = modelData
                                    } else {
                                        root.selectedEntries = [modelData]
                                        root.lastSelectedEntry = modelData
                                    }
                                }
                                if (mouse.button === Qt.RightButton) {
                                    root.selectedEntries = [modelData]
                                    root.lastSelectedEntry = modelData
                                    var pos = mapToItem(root, mouse.x, mouse.y)
                                    contextMenu.x = Math.min(pos.x, root.width - contextMenu.width - 4)
                                    contextMenu.anchorY = pos.y
                                    contextMenu.z = 100
                                    contextMenu.visible = true
                                } else if (modelData.type === "dir") {
                                    root.toggleTreeFolder(modelData.path)
                                }
                            }
                        }

                        onDoubleClicked: {
                            if (modelData.type === "empty-placeholder") return
                            root.selectedEntries = [modelData]
                            root.lastSelectedEntry = modelData
                            if (modelData.type !== "dir") {
                                openEntry(modelData)
                            }
                        }
                    }
                }
            }
            }

            Rectangle {
                    anchors.centerIn: parent
                    visible: root.entries.length === 0 && !loader.running
                    Text {
                        anchors.centerIn: parent
                        font.family: Theme.fontFamily; font.pixelSize: 11
                        color: Theme.textPrimary; opacity: 0.5
                        text: "Carpeta vac\u00EDa"
                    }
                    MouseArea { anchors.fill: parent; onClicked: function(mouse) { root.selectedEntries = []; root.lastSelectedEntry = null; hideAll(); var pos = mapToItem(root, mouse.x, mouse.y); showEmptyCtxMenu(pos.x, pos.y) } }
            }

            Rectangle {
                id: splitter
                visible: lastSelectedEntry && lastSelectedEntry.type !== "dir"
                width: 4
                height: parent.height
                color: Theme.border
                opacity: 0.5

                MouseArea {
                    id: splitMa
                    anchors.fill: parent
                    cursorShape: Qt.SizeHorCursor
                    property real startX: 0
                    property real startW: 0
                    property real maxPW: parent.parent.width - root.sidebarWidth - 5 - 8 - 60
                    onPressed: { startX = mouseX; startW = root.previewWidth }
                    onPositionChanged: {
                        if (pressed) root.previewWidth = Math.max(100, Math.min(maxPW, startW + (startX - mouseX)))
                    }
                }
            }

            Rectangle {
                id: previewPanel
                width: lastSelectedEntry && lastSelectedEntry.type !== "dir" ? root.previewWidth : 0
                visible: lastSelectedEntry && lastSelectedEntry.type !== "dir"
                height: parent.height
                radius: Theme.radius4
                color: Theme.surface
                clip: true
                MouseArea { anchors.fill: parent; z: -1; acceptedButtons: Qt.LeftButton; onClicked: { root.selectedEntries = []; root.lastSelectedEntry = null; hideAll() } }

                Column {
                    anchors.fill: parent
                    anchors.margins: 6
                    spacing: 4

                    Text {
                        font.family: Theme.fontFamily; font.pixelSize: 12
                        color: lastSelectedEntry && lastSelectedEntry.type === "dir" ? Theme.accentYellow : (isImage(lastSelectedEntry) ? "\uF1C5" : isText(lastSelectedEntry) ? "\uF15B" : isPdf(lastSelectedEntry) ? "\uF1C1" : Theme.textPrimary)
                        text: lastSelectedEntry ? iconFor(lastSelectedEntry) + " " + lastSelectedEntry.name : ""
                        elide: Text.ElideRight
                        width: parent.width
                    }

                    Text {
                        font.family: Theme.fontFamily; font.pixelSize: 9
                        color: Theme.textPrimary; opacity: 0.6
                        text: lastSelectedEntry ? fmtSize(lastSelectedEntry.size) + "  " + fmtTime(lastSelectedEntry.modified) : ""
                    }

                    Rectangle {
                        width: parent.width; height: 1; color: Theme.border
                    }

                    Flickable {
                        width: parent.width
                        height: parent.height - 50
                        contentHeight: previewContent.implicitHeight
                        clip: true
                        boundsBehavior: Flickable.StopAtBounds
                        ScrollBar.vertical: ScrollBar {
                            policy: ScrollBar.AsNeeded
                            width: 4
                        }

                    Column {
                        id: previewContent
                        width: parent.width

                        Image {
                            width: parent.width - 8
                            height: parent.width - 8
                            anchors.horizontalCenter: parent.horizontalCenter
                            fillMode: Image.PreserveAspectFit
                            visible: lastSelectedEntry && isImage(lastSelectedEntry)
                            source: lastSelectedEntry && isImage(lastSelectedEntry) ? "file://" + lastSelectedEntry.path : ""
                        }

                        Flickable {
                            width: parent.width - 8
                            height: Math.min(textDisplay.contentHeight, 400)
                            anchors.horizontalCenter: parent.horizontalCenter
                            visible: lastSelectedEntry && isText(lastSelectedEntry) && previewText !== ""
                            contentHeight: textDisplay.contentHeight
                            clip: true

                            TextEdit {
                                id: textDisplay
                                text: previewText
                                readOnly: true
                                wrapMode: Text.WordWrap
                                font.family: "monospace"
                                font.pixelSize: 9
                                color: Theme.textPrimary
                                width: parent.width
                            }
                        }

                        Image {
                            width: parent.width - 8
                            height: parent.width - 8
                            anchors.horizontalCenter: parent.horizontalCenter
                            fillMode: Image.PreserveAspectFit
                            visible: lastSelectedEntry && isPdf(lastSelectedEntry) && pdfPreviewSource !== ""
                            source: pdfPreviewSource
                        }

                        Column {
                            anchors.horizontalCenter: parent.horizontalCenter
                            visible: (lastSelectedEntry && !isImage(lastSelectedEntry) && !isText(lastSelectedEntry) && !isPdf(lastSelectedEntry) && lastSelectedEntry.type !== "dir") || (isText(lastSelectedEntry) && previewText === "" && !textReader.running)
                            spacing: 4

                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                font.family: Theme.fontFamily; font.pixelSize: 24
                                color: Theme.textPrimary; opacity: 0.4
                                text: lastSelectedEntry ? iconFor(lastSelectedEntry) : ""
                            }

                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                font.family: Theme.fontFamily; font.pixelSize: 9
                                color: Theme.textPrimary; opacity: 0.5
                                text: lastSelectedEntry && (lastSelectedEntry.name.toLowerCase().endsWith(".docx") || lastSelectedEntry.name.toLowerCase().endsWith(".odt")) ? "Abrir con doble clic" : "Sin previsualizaci\u00F3n"
                                horizontalAlignment: Text.AlignHCenter
                            }
                        }
                    }
                    }
                }
            }
        }

        Rectangle {
            width: parent.width; height: 1; color: Theme.border
        }

        Item {
            width: parent.width
            height: 42

            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.verticalCenter: parent.verticalCenter
                spacing: 8

                ActionButton { btnText: "\uF07B"; btnLabel: "Carpeta"; btnAction: doNewFolder }
                ActionButton { btnText: "\uF0C5"; btnLabel: "Copiar"; btnAction: doCopy; btnEnabled: selectedEntries.length > 0 }
                ActionButton { btnText: "\uF0C4"; btnLabel: "Cortar"; btnAction: doCut; btnEnabled: selectedEntries.length > 0 }
                ActionButton { btnText: "\uF0EA"; btnLabel: "Pegar"; btnAction: doPaste; btnEnabled: clipboardPaths.length > 0 }
                ActionButton { btnText: "\uF044"; btnLabel: "Renombrar"; btnAction: doRename; btnEnabled: selectedEntries.length === 1 }
                ActionButton { btnText: "\uF1F8"; btnLabel: "Papelera"; btnAction: doTrash; btnEnabled: selectedEntries.length > 0 }
                ActionButton { btnText: "\u2297"; btnLabel: "Eliminar"; btnAction: promptDelete; btnColor: Theme.accentRed; btnEnabled: selectedEntries.length > 0 }
            }
        }
    }

    Item {
        id: newFileInput
        visible: false
        x: 60; y: 42
        width: parent.width - 80; height: 22
        Rectangle {
            anchors.fill: parent
            color: Theme.surface
            border.color: Theme.accent; border.width: 1
            radius: Theme.radius4
        }
        TextInput {
            id: newFileTextInput
            anchors.fill: parent
            anchors.leftMargin: 6
            font.family: Theme.fontFamily; font.pixelSize: 11
            color: Theme.textPrimary
            verticalAlignment: TextInput.AlignVCenter
            onEditingFinished: finishNewFile()
            Keys.onEscapePressed: newFileInput.visible = false
        }
    }

    // ── Search results ──
    Item {
        visible: root.searchActive && root.searchResults.length > 0
        x: 8; y: 105
        width: parent.width - 16
        height: parent.height - 115
        z: 150
        clip: true

        Rectangle {
            anchors.fill: parent
            color: Theme.backgroundAlt
            border.color: Theme.border
            border.width: 1
            radius: Theme.radius4
        }

        ListView {
            anchors.fill: parent; anchors.margins: 4
            spacing: 2
            clip: true
            model: root.searchResults

            delegate: Item {
                height: 24
                width: parent.width

                Rectangle {
                    anchors.fill: parent
                    radius: Theme.radius4
                    color: ma.containsMouse ? Theme.surfaceHover : "transparent"
                }

                Text {
                    anchors.left: parent.left; anchors.leftMargin: 6
                    anchors.verticalCenter: parent.verticalCenter
                    font.family: Theme.fontFamily; font.pixelSize: 11
                    color: Theme.textPrimary
                    text: modelData.name
                    elide: Text.ElideRight
                }

                Text {
                    anchors.right: parent.right; anchors.rightMargin: 6
                    anchors.verticalCenter: parent.verticalCenter
                    font.family: Theme.fontFamily; font.pixelSize: 9
                    color: Theme.textSecondary
                    text: modelData.path.substring(0, modelData.path.lastIndexOf("/"))
                    elide: Text.ElideLeft
                }

                MouseArea {
                    id: ma
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        var p = modelData.path
                        if (modelData.type === "dir") {
                            root.currentPath = p
                            root.loadDir()
                        } else {
                            var dir = p.substring(0, p.lastIndexOf("/"))
                            root.currentPath = dir
                            root.loadDir()
                        }
                        root.toggleSearch()
                    }
                }
            }
        }
    }

    // ── Menu dropdowns ──
    Item {
        x: Math.min(root.menuTargetX, root.width - width - 4); y: 57
        width: 180
        height: menuCol.implicitHeight + 12
        visible: menuOpen !== ""
        z: 200

        Rectangle {
            anchors.fill: parent
            color: Theme.backgroundAlt
            border.color: Theme.border
            border.width: 1
            radius: Theme.radius4
        }

        Column {
            id: menuCol
            anchors.left: parent.left; anchors.right: parent.right
            anchors.top: parent.top; anchors.topMargin: 6
            anchors.bottomMargin: 6
            spacing: 2

            Repeater {
                model: menuOpen === "Archivo" ? [
                    { label: "Crear archivo", action: function() { root.fileCreateVisible = !root.fileCreateVisible; menuOpen = "" } },
                    { label: "Nueva pesta\u00F1a", action: function() { addTab(currentPath); setMenu("") } },
                    { label: "Nueva ventana", action: function() { root.newWindowRequested(root.currentPath); setMenu("") } },
                    null,
                    { label: "Cambiar nombre", action: function() { doRename(); setMenu("") } },
                    { label: "Duplicar aqu\u00ED", action: function() { doDuplicate(); setMenu("") } },
                    { label: "Mover a papelera", action: function() { doTrash(); setMenu("") } },
                    { label: "A\u00F1adir a marcadores", action: function() { addBookmark(currentPath); setMenu("") } },
                    { label: "Eliminar permanentemente", action: function() { promptDelete(); setMenu("") }, sepColor: Theme.accentRed },
                    { label: "Propiedades del archivo", action: function() { showProperties(); setMenu("") } },
                    null,
                    { label: "Salir", action: function() { root.requestClose(); setMenu("") } },
                ] : menuOpen === "Editar" ? [
                    { label: "Deshacer" + (undoStack.length > 0 ? " (" + undoStack.length + ")" : ""), action: function() { doUndo(); setMenu("") } },
                    { label: "Rehacer" + (redoStack.length > 0 ? " (" + redoStack.length + ")" : ""), action: function() { doRedo(); setMenu("") } },
                    null,
                    { label: "Cortar", action: function() { doCut(); setMenu("") } },
                    { label: "Copiar", action: function() { doCopy(); setMenu("") } },
                    { label: "Copiar ubicaci\u00F3n", action: function() { copyLocation(); setMenu("") } },
                    null,
                    { label: "Filtrar" + (filterInputVisible ? "  \u2713" : ""), action: function() { toggleFilter(); setMenu("") } },
                    { label: "Buscar" + (searchActive ? "  \u2713" : ""), action: function() { toggleSearch(); setMenu("") } },
                ] : menuOpen === "Ver" ? [
                    { label: "Refrescar", action: function() { loadDir(); setMenu("") } },
                    null,
                    { label: "Ampliar", action: function() { zoomIn(); setMenu("") } },
                    { label: "Reducir", action: function() { zoomOut(); setMenu("") } },
                    { label: "Reiniciar ampliaci\u00F3n", action: function() { zoomReset(); setMenu("") } },
                    null,
                    { label: "Mostrar archivos ocultos" + (showHidden ? "  \u2713" : ""), action: function() { toggleHidden(); setMenu("") } },
                    { label: "Abrir terminal como root", action: function() { Qt.openUrlExternally("pkexec kitty --working-directory " + currentPath); setMenu("") } },
                ] : menuOpen === "Ir" ? [
                    { label: "Arriba", action: function() { goUp(); setMenu("") } },
                    { label: "Atr\u00E1s", action: function() { goBack(); setMenu("") } },
                    { label: "Adelante", action: function() { goForward(); setMenu("") } },
                    { label: "Inicio", action: function() { goHome(); setMenu("") } },
                    null,
                    { label: "Marcadores", action: function() { menuOpen = "Marcadores" } },
                    null,
                    { label: "Abrir terminal kitty", action: function() { Quickshell.execDetached(["kitty", "--working-directory", currentPath]); setMenu("") } },
                    { label: "Administrar espacio (filelight)", action: function() { Quickshell.execDetached(["filelight", currentPath]); setMenu("") } },
                ] : menuOpen === "Herramientas" ? [
                    { label: "(sin implementar)", action: function() { setMenu("") } },
                ] : menuOpen === "Preferencias" ? [
                    { label: "Preferencias del explorador", action: function() { root.prefPanelVisible = true; setMenu("") } },
                ] : menuOpen === "Marcadores" ? root.buildBookmarkMenuItems() : []

                delegate: Item {
                    height: modelData ? 24 : 8
                    width: menuCol.width

                    Rectangle {
                        visible: modelData === null
                        anchors.left: parent.left; anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        height: 1; color: Theme.border
                    }

                    Rectangle {
                        visible: modelData !== null
                        anchors.fill: parent
                        radius: Theme.radius4
                        color: ma.containsMouse ? Theme.surfaceHover : "transparent"
                    }

                    Text {
                        visible: modelData !== null
                        anchors.left: parent.left; anchors.leftMargin: 8
                        anchors.verticalCenter: parent.verticalCenter
                        font.family: Theme.fontFamily; font.pixelSize: 11
                        color: modelData && modelData.sepColor ? modelData.sepColor : Theme.textPrimary
                        text: modelData ? modelData.label : ""
                    }

                    MouseArea {
                        id: ma
                        visible: modelData !== null
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: { if (modelData && modelData.action) modelData.action() }
                    }
                }
            }
        }
    }

    // ── Submenu: Crear archivo (panel lateral) ──
    Item {
        visible: root.fileCreateVisible
        x: Math.min(root.menuTargetX + 184, root.width - width - 4); y: 57
        width: 200
        height: fileCreateCol.implicitHeight + 12
        z: 201

        Rectangle {
            anchors.fill: parent
            color: Theme.backgroundAlt
            border.color: Theme.border
            border.width: 1
            radius: Theme.radius4
        }

        Column {
            id: fileCreateCol
            anchors.left: parent.left; anchors.right: parent.right
            anchors.top: parent.top; anchors.topMargin: 6
            anchors.bottomMargin: 6
            spacing: 2

            Repeater {
                model: [
                    { label: "\uF07B Carpeta", action: function() { doNewFolder(); root.fileCreateVisible = false; menuOpen = "" } },
                    { label: "\uF15B Archivo de texto", action: function() { doNewTextFile(); root.fileCreateVisible = false; menuOpen = "" } },
                    { label: "\uF1C5 Archivo HTML", action: function() { doNewHtmlFile(); root.fileCreateVisible = false; menuOpen = "" } },
                    { label: "\uF15B Archivo vac\u00EDo", action: function() { doNewEmptyFile(); root.fileCreateVisible = false; menuOpen = "" } },
                    null,
                    { label: "\uF1C5 Documento ODF (.odt)", action: function() { doNewOdtFile(); root.fileCreateVisible = false; menuOpen = "" } },
                    { label: "\uF1C5 Hoja de c\u00E1lculo (.ods)", action: function() { doNewOdsFile(); root.fileCreateVisible = false; menuOpen = "" } },
                    { label: "\uF1C5 Presentaci\u00F3n (.odp)", action: function() { doNewOdpFile(); root.fileCreateVisible = false; menuOpen = "" } },
                    null,
                    { label: "\uF1C5 Markdown (.md)", action: function() { doNewMdFile(); root.fileCreateVisible = false; menuOpen = "" } },
                    { label: "\uF1C5 Script Python (.py)", action: function() { doNewPyFile(); root.fileCreateVisible = false; menuOpen = "" } },
                    { label: "\uF1C5 Script Shell (.sh)", action: function() { doNewShFile(); root.fileCreateVisible = false; menuOpen = "" } },
                    { label: "\uF1C5 JSON (.json)", action: function() { doNewJsonFile(); root.fileCreateVisible = false; menuOpen = "" } },
                    { label: "\uF1C5 CSS (.css)", action: function() { doNewCssFile(); root.fileCreateVisible = false; menuOpen = "" } },
                    { label: "\uF1C5 JavaScript (.js)", action: function() { doNewJsFile(); root.fileCreateVisible = false; menuOpen = "" } },
                    null,
                    { label: "\uF0C1 Enlace a p\u00E1gina web", action: function() { doNewWebLink(); root.fileCreateVisible = false; menuOpen = "" } },
                    { label: "\uF0C1 Enlace a dir/archivo", action: function() { doNewFileLink(); root.fileCreateVisible = false; menuOpen = "" } },
                    { label: "\uF0C1 Enlace a aplicaci\u00F3n", action: function() { doNewAppLink(); root.fileCreateVisible = false; menuOpen = "" } },
                ]

                delegate: Item {
                    height: modelData ? 24 : 8
                    width: fileCreateCol.width

                    Rectangle {
                        visible: modelData === null
                        anchors.left: parent.left; anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        height: 1; color: Theme.border
                    }

                    Rectangle {
                        visible: modelData !== null
                        anchors.fill: parent
                        radius: Theme.radius4
                        color: maFC.containsMouse ? Theme.surfaceHover : "transparent"
                    }

                    Text {
                        visible: modelData !== null
                        anchors.left: parent.left; anchors.leftMargin: 8
                        anchors.verticalCenter: parent.verticalCenter
                        font.family: Theme.fontFamily; font.pixelSize: 11
                        color: Theme.textPrimary
                        text: modelData ? modelData.label : ""
                    }

                    MouseArea {
                        id: maFC
                        visible: modelData !== null
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: { if (modelData && modelData.action) modelData.action() }
                    }
                }
            }
        }
    }

    Item {
        id: renameInput
        visible: false
        x: 60; y: 42
        width: parent.width - 80; height: 22

        Rectangle {
            anchors.fill: parent
            color: Theme.surface
            border.color: Theme.accent; border.width: 1
            radius: Theme.radius4
        }

        TextInput {
            id: renameTextInput
            anchors.fill: parent
            anchors.leftMargin: 6
            font.family: Theme.fontFamily; font.pixelSize: 11
            color: Theme.textPrimary
            verticalAlignment: TextInput.AlignVCenter

            onEditingFinished: finishRename()
            Keys.onEscapePressed: renameInput.visible = false
        }
    }

    Item {
        id: mkdirInput
        visible: false
        x: 60; y: 42
        width: parent.width - 80; height: 22

        Rectangle {
            anchors.fill: parent
            color: Theme.surface
            border.color: Theme.accent; border.width: 1
            radius: Theme.radius4
        }

        TextInput {
            id: mkdirTextInput
            anchors.fill: parent
            anchors.leftMargin: 6
            font.family: Theme.fontFamily; font.pixelSize: 11
            color: Theme.textPrimary
            verticalAlignment: TextInput.AlignVCenter

            onEditingFinished: finishMkdir()
            Keys.onEscapePressed: mkdirInput.visible = false
        }
    }

    Item {
        id: contextMenu
        visible: false
        width: 180
        height: Math.min(ctxCol.implicitHeight + 12, Math.round(root.height * 0.7))
        property real anchorY: 0
        y: Math.min(anchorY, root.height - height - 4)

        Rectangle {
            anchors.fill: parent
            color: Theme.backgroundAlt
            border.color: Theme.border
            border.width: 1
            radius: Theme.radius4
        }

        Flickable {
            anchors.top: parent.top; anchors.topMargin: 6
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom; anchors.bottomMargin: 6
            clip: true
            contentHeight: ctxCol.height
            boundsBehavior: Flickable.StopAtBounds
            interactive: contentHeight > height

            ScrollBar.vertical: ScrollBar {
                policy: ScrollBar.AsNeeded
                width: 4
            }

            Column {
                id: ctxCol
                width: parent.width
                spacing: 2

                Repeater {
                    model: contextMenu.visible ? buildCtxModel() : []

                    delegate: Item {
                        height: modelData ? 24 : 8
                        width: ctxCol.width

                        Rectangle {
                            visible: modelData === null
                            anchors.left: parent.left; anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            height: 1; color: Theme.border
                        }

                        Rectangle {
                            visible: modelData !== null
                            anchors.fill: parent
                            radius: Theme.radius4
                            color: ma.containsMouse && modelData.enabled !== false ? Theme.surfaceHover : "transparent"
                        }

                        Text {
                            visible: modelData !== null
                            anchors.left: parent.left; anchors.leftMargin: 8
                            anchors.verticalCenter: parent.verticalCenter
                            font.family: Theme.fontFamily; font.pixelSize: 11
                            color: modelData && modelData.sepColor ? modelData.sepColor : (modelData && modelData.enabled === false ? Theme.textDisabled : Theme.textPrimary)
                            text: modelData ? modelData.label : ""
                        }

                        MouseArea {
                            id: ma
                            visible: modelData !== null
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: { if (modelData && modelData.action && modelData.enabled !== false) modelData.action() }
                        }
                    }
                }
            }
        }
    }

    function showCtx() {
        menuOpen = ""
        contextMenu.z = 100
        contextMenu.visible = true
    }

    function hideCtx() {
        contextMenu.visible = false
    }

    function showEmptyCtxMenu(mx, my) {
        hideAll()
        emptyCtxMenu.anchorX = mx
        emptyCtxMenu.anchorY = my
        root.emptyCtxVisible = true
        root.emptyCtxSubmenu = ""
    }

    function hideEmptyCtx() {
        root.emptyCtxVisible = false
        root.emptyCtxSubmenu = ""
    }

    function hideAll() {
        contextMenu.visible = false
        menuOpen = ""
        root.fileCreateVisible = false
        root.emptyCtxVisible = false
        root.emptyCtxSubmenu = ""
    }

    component ActionButton: Item {
        property string btnText: ""
        property string btnLabel: ""
        property var btnAction: null
        property color btnColor: Theme.textPrimary
        property bool btnEnabled: true

        width: 52; height: 38
        opacity: btnEnabled ? 1.0 : 0.4

        Rectangle {
            anchors.fill: parent
            radius: Theme.radius4
            color: ma.containsMouse ? Theme.surfaceHover : "transparent"
            border.color: ma.containsMouse ? Theme.border : "transparent"
            border.width: 1
        }

        Column {
            anchors.centerIn: parent
            spacing: 1

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                font.family: Theme.fontFamily; font.pixelSize: 12
                color: btnEnabled ? btnColor : Theme.textPrimary
                text: btnText
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                font.family: Theme.fontFamily; font.pixelSize: 8
                color: btnEnabled ? btnColor : Theme.textPrimary
                text: btnLabel
                visible: btnLabel !== ""
            }
        }

        MouseArea {
            id: ma
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: btnEnabled ? Qt.PointingHandCursor : Qt.ArrowCursor
            onClicked: if (btnEnabled && btnAction) btnAction()
        }
    }

    // ── Empty area context menu ──
    Item {
        id: emptyCtxMenu
        visible: root.emptyCtxVisible
        property real anchorX: 0
        property real anchorY: 0
        x: Math.min(anchorX, root.width - width - 4)
        y: Math.min(anchorY, root.height - height - 4)
        width: 180
        height: Math.min(emptyCtxCol.implicitHeight + 12, Math.round(root.height * 0.7))
        z: 100

        Rectangle {
            anchors.fill: parent
            color: Theme.backgroundAlt
            border.color: Theme.border
            border.width: 1
            radius: Theme.radius4
        }

        Flickable {
            anchors.top: parent.top; anchors.topMargin: 6
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom; anchors.bottomMargin: 6
            clip: true
            contentHeight: emptyCtxCol.height
            boundsBehavior: Flickable.StopAtBounds
            interactive: contentHeight > height

            ScrollBar.vertical: ScrollBar {
                policy: ScrollBar.AsNeeded
                width: 4
            }

            Column {
                id: emptyCtxCol
                width: parent.width
                spacing: 2

                Repeater {
                    model: emptyCtxMenu.visible ? buildEmptyCtxModel() : []

                    delegate: Item {
                        height: modelData ? 24 : 8
                        width: emptyCtxCol.width

                        Rectangle {
                            visible: modelData === null
                            anchors.left: parent.left; anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            height: 1; color: Theme.border
                        }

                        Rectangle {
                            visible: modelData !== null
                            anchors.fill: parent
                            radius: Theme.radius4
                            color: ma.containsMouse && modelData.enabled !== false ? Theme.surfaceHover : "transparent"
                        }

                        Row {
                            visible: modelData !== null
                            anchors.left: parent.left; anchors.leftMargin: 8
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 4

                            Text {
                                font.family: Theme.fontFamily; font.pixelSize: 11
                                color: modelData && modelData.sepColor ? modelData.sepColor : (modelData && modelData.enabled === false ? Theme.textDisabled : Theme.textPrimary)
                                text: modelData ? modelData.label : ""
                            }

                            Text {
                                visible: modelData && modelData.submenu !== undefined
                                font.family: Theme.fontFamily; font.pixelSize: 9
                                color: Theme.textSecondary
                                text: "\u25B6"
                            }
                        }

                        MouseArea {
                            id: ma
                            visible: modelData !== null
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: modelData && modelData.enabled !== false ? Qt.PointingHandCursor : Qt.ArrowCursor
                            onClicked: {
                                if (modelData && modelData.enabled === false) return
                                if (modelData && modelData.action) {
                                    modelData.action()
                                } else if (modelData && modelData.submenu) {
                                    root.emptyCtxSubmenu = root.emptyCtxSubmenu === modelData.submenu ? "" : modelData.submenu
                                }
                            }
                        }
                    }
                }

            }
        }
    }

    // ── Submenu: Crear nuevo ──
    Item {
        id: crearSubmenu
        visible: root.emptyCtxVisible && root.emptyCtxSubmenu === "crear"
        x: Math.min(root.emptyCtxX + 184, root.width - width - 4)
        y: Math.min(root.emptyCtxY, root.height - height - 4)
        width: 200
        height: Math.min(crearCol.implicitHeight + 12, Math.round(root.height * 0.7))
        z: 101

        Rectangle {
            anchors.fill: parent
            color: Theme.backgroundAlt
            border.color: Theme.border
            border.width: 1
            radius: Theme.radius4
        }

        Flickable {
            anchors.top: parent.top; anchors.topMargin: 6
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom; anchors.bottomMargin: 6
            clip: true
            contentHeight: crearCol.height
            boundsBehavior: Flickable.StopAtBounds
            interactive: contentHeight > height

            ScrollBar.vertical: ScrollBar {
                policy: ScrollBar.AsNeeded
                width: 4
            }

            Column {
                id: crearCol
                width: parent.width
                spacing: 2

                Repeater {
                    model: [
                        { label: "\uF07B Carpeta", action: function() { doNewFolder(); hideEmptyCtx() } },
                        { label: "\uF15B Archivo de texto", action: function() { doNewTextFile(); hideEmptyCtx() } },
                        { label: "\uF1C5 Archivo HTML", action: function() { doNewHtmlFile(); hideEmptyCtx() } },
                        { label: "\uF15B Archivo vac\u00EDo", action: function() { doNewEmptyFile(); hideEmptyCtx() } },
                        null,
                        { label: "\uF1C5 Documento ODF (.odt)", action: function() { doNewOdtFile(); hideEmptyCtx() } },
                        { label: "\uF1C5 Hoja de c\u00E1lculo (.ods)", action: function() { doNewOdsFile(); hideEmptyCtx() } },
                        { label: "\uF1C5 Presentaci\u00F3n (.odp)", action: function() { doNewOdpFile(); hideEmptyCtx() } },
                        null,
                        { label: "\uF1C5 Markdown (.md)", action: function() { doNewMdFile(); hideEmptyCtx() } },
                        { label: "\uF1C5 Script Python (.py)", action: function() { doNewPyFile(); hideEmptyCtx() } },
                        { label: "\uF1C5 Script Shell (.sh)", action: function() { doNewShFile(); hideEmptyCtx() } },
                        { label: "\uF1C5 JSON (.json)", action: function() { doNewJsonFile(); hideEmptyCtx() } },
                        { label: "\uF1C5 CSS (.css)", action: function() { doNewCssFile(); hideEmptyCtx() } },
                        { label: "\uF1C5 JavaScript (.js)", action: function() { doNewJsFile(); hideEmptyCtx() } },
                        null,
                        { label: "\uF0C1 Enlace a p\u00E1gina web", action: function() { doNewWebLink(); hideEmptyCtx() } },
                        { label: "\uF0C1 Enlace a dir/archivo", action: function() { doNewFileLink(); hideEmptyCtx() } },
                        { label: "\uF0C1 Enlace a aplicaci\u00F3n", action: function() { doNewAppLink(); hideEmptyCtx() } },
                    ]

                    delegate: Item {
                        height: modelData ? 24 : 8
                        width: crearCol.width

                        Rectangle {
                            visible: modelData === null
                            anchors.left: parent.left; anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            height: 1; color: Theme.border
                        }

                        Rectangle {
                            visible: modelData !== null
                            anchors.fill: parent
                            radius: Theme.radius4
                            color: ma3.containsMouse ? Theme.surfaceHover : "transparent"
                        }

                        Text {
                            visible: modelData !== null
                            anchors.left: parent.left; anchors.leftMargin: 8
                            anchors.verticalCenter: parent.verticalCenter
                            font.family: Theme.fontFamily; font.pixelSize: 11
                            color: Theme.textPrimary
                            text: modelData ? modelData.label : ""
                        }

                        MouseArea {
                            id: ma3
                            visible: modelData !== null
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: { if (modelData && modelData.action) modelData.action() }
                        }
                    }
                }
            }
        }
    }

    // ── Submenu: Ordenar por ──
    Item {
        id: ordenarSubmenu
        visible: root.emptyCtxVisible && root.emptyCtxSubmenu === "ordenar"
        x: Math.min(root.emptyCtxX + 184, root.width - width - 4)
        y: Math.min(root.emptyCtxY, root.height - height - 4)
        width: 180
        height: Math.min(ordenarCol.implicitHeight + 12, Math.round(root.height * 0.7))
        z: 101

        Rectangle {
            anchors.fill: parent
            color: Theme.backgroundAlt
            border.color: Theme.border
            border.width: 1
            radius: Theme.radius4
        }

        Flickable {
            anchors.top: parent.top; anchors.topMargin: 6
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom; anchors.bottomMargin: 6
            clip: true
            contentHeight: ordenarCol.height
            boundsBehavior: Flickable.StopAtBounds
            interactive: contentHeight > height

            ScrollBar.vertical: ScrollBar {
                policy: ScrollBar.AsNeeded
                width: 4
            }

            Column {
                id: ordenarCol
                width: parent.width
                spacing: 2

                Repeater {
                    model: [
                        { label: "Nombre", mode: "nombre" },
                        { label: "Tama\u00F1o", mode: "tamano" },
                        { label: "Fecha m\u00E1s actual", mode: "fecha" },
                        { label: "Orden alfab\u00E9tico", mode: "alfabetico" },
                    ]

                    delegate: Item {
                        height: 24
                        width: ordenarCol.width

                        Rectangle {
                            anchors.fill: parent
                            radius: Theme.radius4
                            color: ma4.containsMouse ? Theme.surfaceHover : "transparent"
                        }

                        Text {
                            anchors.left: parent.left; anchors.leftMargin: 8
                            anchors.verticalCenter: parent.verticalCenter
                            font.family: Theme.fontFamily; font.pixelSize: 11
                            color: root.sortMode === modelData.mode ? Theme.accent : Theme.textPrimary
                            text: modelData.label
                        }

                        MouseArea {
                            id: ma4
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                setSortMode(modelData.mode)
                                hideEmptyCtx()
                                loadDir()
                            }
                        }
                    }
                }
            }
        }
    }

    // ── Submenu: Visualizaci\u00F3n ──
    Item {
        id: visualSubmenu
        visible: root.emptyCtxVisible && root.emptyCtxSubmenu === "visualizar"
        x: Math.min(root.emptyCtxX + 184, root.width - width - 4)
        y: Math.min(root.emptyCtxY, root.height - height - 4)
        width: 180
        height: Math.min(visualCol.implicitHeight + 12, Math.round(root.height * 0.7))
        z: 101

        Rectangle {
            anchors.fill: parent
            color: Theme.backgroundAlt
            border.color: Theme.border
            border.width: 1
            radius: Theme.radius4
        }

        Flickable {
            anchors.top: parent.top; anchors.topMargin: 6
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom; anchors.bottomMargin: 6
            clip: true
            contentHeight: visualCol.height
            boundsBehavior: Flickable.StopAtBounds
            interactive: contentHeight > height

            ScrollBar.vertical: ScrollBar {
                policy: ScrollBar.AsNeeded
                width: 4
            }

            Column {
                id: visualCol
                width: parent.width
                spacing: 2

                Repeater {
                    model: [
                        { label: "\u25A6 Iconos", mode: "icon" },
                        { label: "\u2261 Compacta", mode: "list" },
                        { label: "\u25B8 Detallada", mode: "detailed" },
                    ]

                    delegate: Item {
                        height: 24
                        width: visualCol.width

                        Rectangle {
                            anchors.fill: parent
                            radius: Theme.radius4
                            color: ma5.containsMouse ? Theme.surfaceHover : "transparent"
                        }

                        Text {
                            anchors.left: parent.left; anchors.leftMargin: 8
                            anchors.verticalCenter: parent.verticalCenter
                            font.family: Theme.fontFamily; font.pixelSize: 11
                            color: root.viewMode === modelData.mode ? Theme.accent : Theme.textPrimary
                            text: modelData.label
                        }

                        MouseArea {
                            id: ma5
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                setViewMode(modelData.mode)
                                hideEmptyCtx()
                            }
                        }
                    }
                }
            }
        }
    }

    Rectangle {
        id: dragOverlay
        visible: root.isDragging
        x: root.dragCursorX - 8
        y: root.dragCursorY - 8
        width: 136
        height: 24
        radius: Theme.radius4
        color: Theme.surfaceHover
        opacity: 0.85
        z: 9999

        Row {
            anchors.left: parent.left; anchors.leftMargin: 6
            anchors.verticalCenter: parent.verticalCenter
            spacing: 4

            Text {
                font.family: Theme.fontFamily
                font.pixelSize: 12
                color: Theme.textPrimary
                text: "\uF15B"
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                font.family: Theme.fontFamily
                font.pixelSize: 11
                color: Theme.textPrimary
                text: root.dragFileName
                elide: Text.ElideRight
                width: 100
            }
        }
    }


    // ── Rubber band selection rectangle ──
    Rectangle {
        visible: root.rubberActive
        x: Math.min(root.rubberStartX, root.rubberEndX)
        y: Math.min(root.rubberStartY, root.rubberEndY)
        width: Math.abs(root.rubberEndX - root.rubberStartX)
        height: Math.abs(root.rubberEndY - root.rubberStartY)
        color: Theme.accent; opacity: 0.12
        border.color: Theme.accent; border.width: 1
        z: 55
    }

    MouseArea {
        anchors.fill: parent
        z: 50
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        enabled: contextMenu.visible || menuOpen !== "" || root.emptyCtxVisible
        propagateComposedEvents: true
        onClicked: { root.selectedEntries = []; root.lastSelectedEntry = null; hideAll() }
    }

    // ── View overlay (rubber band + empty click) ──
    Item {
        id: viewOverlay
        property var activeView: root.viewMode === "list" ? fileList : (root.viewMode === "icon" ? fileGrid : null)
        visible: (root.viewMode === "list" || root.viewMode === "icon") && activeView && activeView.visible
        z: 55

        x: root.sidebarWidth + 5
        y: mainRow.y
        width: activeView ? activeView.width : 0
        height: activeView ? activeView.height : 0

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton | Qt.RightButton

            onPressed: function(mouse) {
                if (mouse.button === Qt.LeftButton) {
                    var target = root.viewMode === "list" ? fileList : fileGrid
                    var p = mapToItem(target, mouse.x, mouse.y)
                    var idx = target.indexAt(p.x + target.contentX, p.y + target.contentY)

                    if (idx >= 0) {
                        mouse.accepted = false
                        return
                    }

                    mouse.accepted = true
                    root.rubberActive = false
                    var pos = mapToItem(root, mouse.x, mouse.y)
                    root.rubberStartX = pos.x
                    root.rubberStartY = pos.y
                    root.rubberEndX = pos.x
                    root.rubberEndY = pos.y
                    root.rubberActive = true
                } else {
                    var target = root.viewMode === "list" ? fileList : fileGrid
                    var p = mapToItem(target, mouse.x, mouse.y)
                    var idx = target.indexAt(p.x + target.contentX, p.y + target.contentY)

                    if (idx >= 0) {
                        mouse.accepted = false
                    }
                }
            }

            onPositionChanged: function(mouse) {
                if ((mouse.buttons & Qt.LeftButton) && root.rubberActive) {
                    var pos = mapToItem(root, mouse.x, mouse.y)
                    root.rubberEndX = pos.x
                    root.rubberEndY = pos.y
                    var edge = 20
                    if (mouse.y < edge) {
                        root.autoScrollDir = -1
                        autoScrollTimer.start()
                    } else if (mouse.y > viewOverlay.height - edge) {
                        root.autoScrollDir = 1
                        autoScrollTimer.start()
                    } else {
                        autoScrollTimer.stop()
                    }
                }
            }

            onReleased: function(mouse) {
                if (root.rubberActive) {
                    var dx = root.rubberEndX - root.rubberStartX
                    var dy = root.rubberEndY - root.rubberStartY
                    if (Math.abs(dx) > 5 || Math.abs(dy) > 5) {
                        root.finishRubberBand()
                        contextMenu.visible = false
                        menuOpen = ""
                        root.fileCreateVisible = false
                        root.emptyCtxVisible = false
                        root.emptyCtxSubmenu = ""
                    } else if (mouse.button === Qt.LeftButton) {
                        root.selectedEntries = []; root.lastSelectedEntry = null; hideAll()
                    }
                    root.rubberActive = false
                }
            }

            onClicked: function(mouse) {
                if (mouse.button !== Qt.RightButton) return
                root.selectedEntries = []
                root.lastSelectedEntry = null
                hideAll()
                var pos = mapToItem(root, mouse.x, mouse.y)
                showEmptyCtxMenu(pos.x, pos.y)
            }
        }
    }

    // ── Preferencias del explorador ──
    Item {
        id: prefOverlay
        visible: root.prefPanelVisible
        anchors.fill: parent
        z: 300

        Rectangle {
            anchors.fill: parent
            color: "#80000000"

            MouseArea {
                anchors.fill: parent
                onClicked: root.prefPanelVisible = false
            }
        }

        Rectangle {
            anchors.centerIn: parent
            width: Math.min(parent.width - 40, 380)
            height: Math.min(parent.height - 40, 480)
            radius: Theme.radius8
            color: Theme.backgroundAlt
            border.color: Theme.border
            border.width: 1

            Column {
                anchors.fill: parent
                anchors.margins: 12
                spacing: 8

                Text {
                    font.family: Theme.fontFamily; font.pixelSize: 13; font.bold: true
                    color: Theme.textPrimary
                    text: "Preferencias del explorador"
                }

                Rectangle { width: parent.width; height: 1; color: Theme.border }

                Flickable {
                    width: parent.width
                    height: parent.height - 80
                    contentHeight: prefCol.implicitHeight
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds
                    ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded; width: 4 }

                    Column {
                        id: prefCol
                        width: parent.width - 8
                        spacing: 8

                        Text {
                            font.family: Theme.fontFamily; font.pixelSize: 10; font.bold: true
                            color: Theme.accent; text: "Vista predeterminada"
                            leftPadding: 2
                        }

                        Row {
                            spacing: 4
                            Repeater {
                                model: [
                                    { label: "\u25A6 Iconos", mode: "icon" },
                                    { label: "\u2261 Compacta", mode: "list" },
                                    { label: "\u25B8 Detallada", mode: "detailed" }
                                ]

                                delegate: Rectangle {
                                    height: 24; width: 90
                                    radius: Theme.radius4
                                    color: root.pref_viewMode === modelData.mode ? Theme.accent : (vmMa.containsMouse ? Theme.surfaceHover : Theme.surface)
                                    border.color: Theme.border; border.width: 1

                                    Text {
                                        anchors.centerIn: parent
                                        font.family: Theme.fontFamily; font.pixelSize: 10
                                        color: root.pref_viewMode === modelData.mode ? "#000000" : Theme.textPrimary
                                        text: modelData.label
                                    }

                                    MouseArea {
                                        id: vmMa
                                        anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                        onClicked: { root.pref_viewMode = modelData.mode; root.setViewMode(modelData.mode) }
                                    }
                                }
                            }
                        }

                        Text {
                            font.family: Theme.fontFamily; font.pixelSize: 10; font.bold: true
                            color: Theme.accent; text: "Orden predeterminado"
                            leftPadding: 2
                        }

                        Row {
                            spacing: 4
                            Repeater {
                                model: [
                                    { label: "Nombre", mode: "nombre" },
                                    { label: "Tama\u00F1o", mode: "tamano" },
                                    { label: "Fecha", mode: "fecha" },
                                    { label: "Alfab\u00E9tico", mode: "alfabetico" }
                                ]

                                delegate: Rectangle {
                                    height: 24; width: 75
                                    radius: Theme.radius4
                                    color: root.pref_sortMode === modelData.mode ? Theme.accent : (smMa.containsMouse ? Theme.surfaceHover : Theme.surface)
                                    border.color: Theme.border; border.width: 1

                                    Text {
                                        anchors.centerIn: parent
                                        font.family: Theme.fontFamily; font.pixelSize: 10
                                        color: root.pref_sortMode === modelData.mode ? "#000000" : Theme.textPrimary
                                        text: modelData.label
                                    }

                                    MouseArea {
                                        id: smMa
                                        anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                        onClicked: { root.pref_sortMode = modelData.mode; root.setSortMode(modelData.mode); root.loadDir() }
                                    }
                                }
                            }
                        }

                        Rectangle { width: parent.width; height: 1; color: Theme.border }

                        Item {
                            height: 24; width: parent.width
                            Row { spacing: 6
                                Text { anchors.verticalCenter: parent.verticalCenter; font.family: Theme.fontFamily; font.pixelSize: 10; color: Theme.textPrimary; text: "Mostrar ocultos al inicio" }
                                Item { width: 30; height: 16; anchors.verticalCenter: parent.verticalCenter
                                    Rectangle { anchors.fill: parent; radius: 8; color: root.pref_showHiddenOnStart ? Theme.accent : Theme.surface; border.color: Theme.border; border.width: 1 }
                                    Rectangle { width: 12; height: 12; radius: 6; color: Theme.textPrimary; x: root.pref_showHiddenOnStart ? parent.width - width - 2 : 2; anchors.verticalCenter: parent.verticalCenter; Behavior on x { NumberAnimation { duration: 100 } } }
                                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { root.pref_showHiddenOnStart = !root.pref_showHiddenOnStart; root.showHidden = root.pref_showHiddenOnStart; root.loadDir() } }
                                }
                            }
                        }

                        Item {
                            height: 24; width: parent.width
                            Row { spacing: 6
                                Text { anchors.verticalCenter: parent.verticalCenter; font.family: Theme.fontFamily; font.pixelSize: 10; color: Theme.textPrimary; text: "Confirmar antes de eliminar" }
                                Item { width: 30; height: 16; anchors.verticalCenter: parent.verticalCenter
                                    Rectangle { anchors.fill: parent; radius: 8; color: root.pref_confirmDelete ? Theme.accent : Theme.surface; border.color: Theme.border; border.width: 1 }
                                    Rectangle { width: 12; height: 12; radius: 6; color: Theme.textPrimary; x: root.pref_confirmDelete ? parent.width - width - 2 : 2; anchors.verticalCenter: parent.verticalCenter; Behavior on x { NumberAnimation { duration: 100 } } }
                                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { root.pref_confirmDelete = !root.pref_confirmDelete; root.confirmDelete = root.pref_confirmDelete } }
                                }
                            }
                        }

                        Item {
                            height: 24; width: parent.width
                            Row { spacing: 6
                                Text { anchors.verticalCenter: parent.verticalCenter; font.family: Theme.fontFamily; font.pixelSize: 10; color: Theme.textPrimary; text: "Navegaci\u00F3n con un clic" }
                                Item { width: 30; height: 16; anchors.verticalCenter: parent.verticalCenter
                                    Rectangle { anchors.fill: parent; radius: 8; color: root.pref_singleClickNav ? Theme.accent : Theme.surface; border.color: Theme.border; border.width: 1 }
                                    Rectangle { width: 12; height: 12; radius: 6; color: Theme.textPrimary; x: root.pref_singleClickNav ? parent.width - width - 2 : 2; anchors.verticalCenter: parent.verticalCenter; Behavior on x { NumberAnimation { duration: 100 } } }
                                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { root.pref_singleClickNav = !root.pref_singleClickNav; root.singleClickNav = root.pref_singleClickNav } }
                                }
                            }
                        }

                        Rectangle { width: parent.width; height: 1; color: Theme.border }

                        Text {
                            font.family: Theme.fontFamily; font.pixelSize: 10; font.bold: true
                            color: Theme.accent; text: "Ancho del panel lateral"
                            leftPadding: 2
                        }

                        Row { spacing: 6; width: parent.width
                            Text { anchors.verticalCenter: parent.verticalCenter; font.family: Theme.fontFamily; font.pixelSize: 10; color: Theme.textSecondary; text: root.pref_sidebarWidth + "px"; width: 40 }
                            Slider {
                                width: parent.width - 50; from: 100; to: 300; stepSize: 5
                                value: root.pref_sidebarWidth
                                onValueChanged: {
                                    root.pref_sidebarWidth = value
                                    root.sidebarWidth = value
                                }
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }

                        Text {
                            font.family: Theme.fontFamily; font.pixelSize: 10; font.bold: true
                            color: Theme.accent; text: "Ancho de previsualizaci\u00F3n"
                            leftPadding: 2
                        }

                        Row { spacing: 6; width: parent.width
                            Text { anchors.verticalCenter: parent.verticalCenter; font.family: Theme.fontFamily; font.pixelSize: 10; color: Theme.textSecondary; text: root.pref_previewWidth + "px"; width: 40 }
                            Slider {
                                width: parent.width - 50; from: 100; to: 400; stepSize: 5
                                value: root.pref_previewWidth
                                onValueChanged: {
                                    root.pref_previewWidth = value
                                    root.previewWidth = value
                                }
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }
                    }
                }

                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 8

                    Rectangle {
                        width: 100; height: 26; radius: Theme.radius4
                        color: gdPrefMa.containsMouse ? Theme.surfaceHover : Theme.surface
                        border.color: Theme.border; border.width: 1

                        Text {
                            anchors.centerIn: parent
                            font.family: Theme.fontFamily; font.pixelSize: 11
                            color: Theme.accent; text: "Guardar"
                        }

                        MouseArea {
                            id: gdPrefMa
                            anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.saveFilePreferences()
                            }
                        }
                    }

                    Rectangle {
                        width: 60; height: 26; radius: Theme.radius4
                        color: clsPrefMa.containsMouse ? Theme.surfaceHover : Theme.surface
                        border.color: Theme.border; border.width: 1

                        Text {
                            anchors.centerIn: parent
                            font.family: Theme.fontFamily; font.pixelSize: 11
                            color: Theme.textPrimary; text: "Cerrar"
                        }

                        MouseArea {
                            id: clsPrefMa
                            anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                            onClicked: root.prefPanelVisible = false
                        }
                    }
                }
            }
        }
    }

    Item {
        id: openWithPanel
        visible: root.openWithVisible
        anchors.fill: parent
        z: 200
        focus: visible
        onVisibleChanged: { if (visible) Qt.callLater(openWithSearch.forceActiveFocus); else root.forceActiveFocus() }

        Keys.onEscapePressed: root.openWithVisible = false

        Rectangle {
            anchors.fill: parent
            color: "#80000000"
            MouseArea { anchors.fill: parent; onClicked: root.openWithVisible = false }
        }

        Item {
            id: openWithContent
            width: 340
            height: Math.min(440, root.height - 40)
            x: Math.round((parent.width - width) / 2)
            y: Math.round((parent.height - height) / 2)

            Rectangle {
                anchors.fill: parent
                color: Theme.backgroundAlt
                border.color: Theme.border; border.width: 1
                radius: Theme.radius4
            }

            Column {
                anchors.fill: parent; anchors.margins: 8
                spacing: 6

                Row {
                    width: parent.width
                    spacing: 4

                    Text {
                        font.family: Theme.fontFamily; font.pixelSize: 11
                        color: Theme.textPrimary
                        text: "Abrir con:"
                    }

                    Text {
                        font.family: Theme.fontFamily; font.pixelSize: 11
                        color: Theme.accent; font.bold: true
                        elide: Text.ElideRight
                        width: parent.width - 80
                        text: root.openWithFile ? root.openWithFile.name : ""
                    }

                    Text {
                        font.family: Theme.fontFamily; font.pixelSize: 11
                        color: Theme.textSecondary
                        text: "\u2715"
                        MouseArea {
                            anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                            onClicked: root.openWithVisible = false
                        }
                    }
                }

                Rectangle {
                    width: parent.width; height: 22
                    color: Theme.surface
                    border.color: openWithSearch.activeFocus ? Theme.accent : Theme.border
                    border.width: 1; radius: Theme.radius3

                    TextInput {
                        id: openWithSearch
                        anchors.fill: parent; anchors.leftMargin: 6
                        font.family: Theme.fontFamily; font.pixelSize: 10
                        color: Theme.textPrimary
                        verticalAlignment: TextInput.AlignVCenter
                        onTextChanged: root.openWithFilter = text
                        Keys.onEscapePressed: root.openWithVisible = false
                    }

                    Text {
                        anchors.left: parent.left; anchors.leftMargin: 6
                        anchors.verticalCenter: parent.verticalCenter
                        font.family: Theme.fontFamily; font.pixelSize: 10
                        color: Theme.textSecondary
                        text: "Buscar aplicaci\u00F3n..."
                        visible: openWithSearch.text === "" && !openWithSearch.activeFocus
                    }
                }

                Flickable {
                    width: parent.width
                    height: parent.height - 56
                    contentHeight: appListCol.implicitHeight
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds
                    ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded; width: 4 }

                    Column {
                        id: appListCol
                        width: parent.width
                        spacing: 2

                        Repeater {
                            model: root.openWithVisible ? root.buildOpenWithModel() : []

                            delegate: Item {
                                height: 28
                                width: parent.width

                                Rectangle {
                                    anchors.fill: parent; radius: Theme.radius3
                                    color: appMa.containsMouse ? Theme.surfaceHover : "transparent"
                                }

                                Row {
                                    anchors.left: parent.left; anchors.leftMargin: 4
                                    anchors.verticalCenter: parent.verticalCenter
                                    spacing: 6

                                    Text {
                                        font.family: Theme.fontFamily; font.pixelSize: 11
                                        color: Theme.textPrimary
                                        text: "\uF15B"
                                    }

                                    Text {
                                        font.family: Theme.fontFamily; font.pixelSize: 10
                                        color: Theme.textPrimary
                                        text: modelData.name
                                    }
                                }

                                MouseArea {
                                    id: appMa
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.launchWithApp(modelData)
                                }
                            }
                        }

                        Text {
                            width: parent.width
                            visible: root.openWithApps.length === 0 || root.buildOpenWithModel().length === 0
                            font.family: Theme.fontFamily; font.pixelSize: 10
                            color: Theme.textSecondary
                            horizontalAlignment: Text.AlignHCenter
                            text: root.openWithApps.length === 0 ? "Cargando aplicaciones..." : "No se encontraron aplicaciones"
                            topPadding: 8
                        }
                    }
                }
            }
        }
    }

    Rectangle {
        id: confirmDeleteOverlay
        visible: root.confirmDeleteVisible
        anchors.fill: parent
        z: 400

        Rectangle {
            anchors.fill: parent
            color: "#80000000"

            MouseArea {
                anchors.fill: parent
                onClicked: root.confirmDeleteVisible = false
            }
        }

        Rectangle {
            anchors.centerIn: parent
            width: Math.min(parent.width - 40, 380)
            height: childrenRect.height + 32
            radius: Theme.radius8
            color: Theme.backgroundAlt
            border.color: Theme.accentRed
            border.width: 1

            Column {
                x: 16
                y: 16
                width: parent.width - 32
                spacing: 12

                Text {
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                    font.family: Theme.fontFamily
                    font.pixelSize: 14
                    font.bold: true
                    color: Theme.accentRed
                    text: "\u26A0 Eliminaci\u00F3n permanente"
                }

                Text {
                    width: parent.width
                    font.family: Theme.fontFamily
                    font.pixelSize: 11
                    color: Theme.textPrimary
                    wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                    text: "Esta acci\u00F3n eliminar\u00E1 los archivos seleccionados de forma definitiva.\n\nNo se podr\u00E1n recuperar, ni siquiera desde la papelera."
                }

                Row {
                    anchors.right: parent.right
                    spacing: 8

                    Button {
                        text: "Cancelar"
                        onClicked: root.confirmDeleteVisible = false
                    }

                    Button {
                        text: "Eliminar"
                        onClicked: doDelete()
                    }
                }
            }
        }
    }

}
