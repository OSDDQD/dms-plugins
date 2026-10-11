import QtQuick

Item {
    id: editor

    required property var window
    required property var drawingCanvas

    readonly property bool editing: window && window.isTyping && window.textInputMode === "inline"
    property bool synchronizing: false

    Component.onCompleted: {
        if (editor.window)
            editor.window.inlineTextEditorItem = editor;
    }

    Component.onDestruction: {
        if (editor.window && editor.window.inlineTextEditorItem === editor)
            editor.window.inlineTextEditorItem = null;
    }

    visible: editing
    z: 20
    x: editor.displayOrigin.x - editor.horizontalPadding * editor.displayScale
    y: editor.displayOrigin.y - editor.verticalPadding * editor.displayScale
    width: Math.max(1, (textEdit.contentWidth + editor.horizontalPadding * 2) * editor.displayScale)
    height: Math.max(editor.fontSize, textEdit.contentHeight + editor.verticalPadding * 2) * editor.displayScale
    rotation: window && window.editingStroke ? Number(window.editingStroke.rotation) || 0 : 0
    transformOrigin: Item.Center

    readonly property real displayScale: {
        if (!window)
            return 1;
        return window.editScale * (window.effectiveBackgroundMode !== "none" ? window.backgroundScaleFactor : 1);
    }
    readonly property real canvasOriginX: window && window.hasActiveCropSelection ? window.cropRect.x : 0
    readonly property real canvasOriginY: window && window.hasActiveCropSelection ? window.cropRect.y : 0
    readonly property point displayOrigin: {
        if (!window)
            return Qt.point(0, 0);
        const point = window.typingCoords;
        const offsetX = window.effectiveBackgroundMode !== "none" ? window.screenshotXOffset : 0;
        const offsetY = window.effectiveBackgroundMode !== "none" ? window.screenshotYOffset : 0;
        const factor = window.effectiveBackgroundMode !== "none" ? window.backgroundScaleFactor : 1;
        return Qt.point((offsetX + (point.x - editor.canvasOriginX) * factor) * window.editScale, (offsetY + (point.y - editor.canvasOriginY) * factor) * window.editScale);
    }
    // Logical (canvas-unit) font size, identical to the Canvas renderer's
    // Math.round(stroke.width). The TextEdit is scaled by displayScale instead
    // of shrinking font.pixelSize, which is an int and would truncate.
    readonly property int fontSize: window ? Math.round(window.textFontSize) : 16
    readonly property real horizontalPadding: Math.max(2, editor.fontSize * 0.02)
    readonly property real verticalPadding: Math.max(1, editor.fontSize * 0.02)
    // Line advance relative to font size, as laid out by TextEdit. Stored on
    // committed strokes so the Canvas renderer reproduces the same spacing.
    readonly property real lineSpacingRatio: editor.fontSize > 0 ? editorFontMetrics.lineSpacing / editor.fontSize : 0

    FontMetrics {
        id: editorFontMetrics
        font: textEdit.font
    }

    function synchronizeFromSession() {
        if (!editor.editing || !editor.window)
            return;
        Qt.callLater(() => {
            if (!editor.editing)
                return;
            editor.synchronizing = true;
            textEdit.text = editor.window.currentTypingText || "";
            textEdit.cursorPosition = Math.min(editor.window.typingCursorIndex, textEdit.length);
            editor.synchronizing = false;
            textEdit.forceActiveFocus();
            textEdit.ensureVisible(textEdit.cursorPosition);
        });
    }

    onEditingChanged: {
        if (editing) {
            editor.synchronizeFromSession();
        } else if (editor.window) {
            Qt.callLater(() => editor.window.focusModalAfterToolbarAction());
        }
    }

    TextEdit {
        id: textEdit
        x: editor.horizontalPadding * editor.displayScale
        y: editor.verticalPadding * editor.displayScale
        scale: editor.displayScale
        transformOrigin: Item.TopLeft
        focus: editor.editing
        activeFocusOnPress: true
        selectByMouse: true
        selectByKeyboard: true
        persistentSelection: true
        wrapMode: TextEdit.NoWrap
        textFormat: TextEdit.PlainText
        font.family: editor.window ? editor.window.textFontFamily : "sans-serif"
        font.pixelSize: editor.fontSize
        font.bold: editor.window ? editor.window.textBold : false
        font.italic: editor.window ? editor.window.textItalic : false
        font.underline: editor.window ? editor.window.textUnderline : false
        color: editor.window ? editor.window.currentColor : "white"
        selectionColor: editor.window ? editor.window.currentColor : "#448aff"
        selectedTextColor: editor.window ? editor.window.currentColor : "white"
        inputMethodHints: Qt.ImhNoAutoUppercase

        onVisibleChanged: {
            if (!visible || !editor.window)
                return;
            editor.synchronizeFromSession();
        }

        onTextChanged: {
            if (!editor.window || editor.synchronizing || !editor.editing)
                return;
            editor.window.currentTypingText = text;
            editor.window.typingCursorIndex = cursorPosition;
            editor.window.requestAnnotationPaintAll();
        }

        onCursorPositionChanged: {
            if (!editor.window || editor.synchronizing || !editor.editing)
                return;
            editor.window.typingCursorIndex = cursorPosition;
            editor.window.requestAnnotationPaintAll();
        }

        function applyEnterAction(shouldCommit) {
            if (!editor.window || !editor.editing)
                return;
            if (!shouldCommit) {
                const start = selectionStart;
                const end = selectionEnd;
                if (start !== end)
                    remove(start, end);
                insert(start, "\n");
                cursorPosition = start + 1;
                return;
            }
            editor.window.currentTypingText = text;
            editor.window.commitTypingText();
        }

        function handleEnterKey(event) {
            const hasModifier = !!(event.modifiers & (Qt.ShiftModifier | Qt.ControlModifier));
            const shouldCommit = !hasModifier;
            if (!editor.window || !editor.editing)
                return;
            if (inputMethodComposing) {
                Qt.inputMethod.commit();
                Qt.callLater(() => textEdit.applyEnterAction(shouldCommit));
            } else {
                textEdit.applyEnterAction(shouldCommit);
            }
            event.accepted = true;
        }

        Keys.onEscapePressed: event => {
            if (!editor.window || !editor.editing)
                return;
            editor.window.cancelTypingText();
            event.accepted = true;
        }
        Keys.priority: Keys.BeforeItem
        Keys.onPressed: event => {
            if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.text === "\n") {
                textEdit.handleEnterKey(event);
            }
        }
    }

    Connections {
        target: editor.window
        enabled: !!editor.window

        function onCurrentTypingTextChanged() {
            if (!textEdit.activeFocus || editor.synchronizing || !editor.editing)
                return;
            if (textEdit.text === editor.window.currentTypingText)
                return;
            editor.synchronizing = true;
            textEdit.text = editor.window.currentTypingText || "";
            textEdit.cursorPosition = Math.min(editor.window.typingCursorIndex, textEdit.length);
            editor.synchronizing = false;
        }
    }
}
