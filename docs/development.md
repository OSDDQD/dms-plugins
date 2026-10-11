# Testing & Verification Workflow

This document describes the workflow for testing, hot-reloading, and linting plugins in `dms-plugins`.

---

## 1. Local Development Setup

Symlink your target plugin into the local DMS plugins directory:

```bash
ln -sfn "$PWD/<pluginName>" "$HOME/.config/DankMaterialShell/plugins/<pluginName>"
```

---

## 2. Hot-Reloading via IPC

Never restart DMS or Quickshell to verify plugin changes. Reload immediately via IPC:

```bash
dms ipc call plugins reload <pluginName>
```

A successful reload outputs:
```
PLUGIN_RELOAD_SUCCESS: <pluginName>
```

---

## 3. Interactive Testing via IPC

Exercise plugin actions, toggles, and modal states directly from your terminal:

```bash
dms ipc call <pluginName> open
dms ipc call <pluginName> close
dms ipc call <pluginName> toggle
```

---

## 4. Linting & Validation

Before committing changes, run the validation checks:

```bash
# 1. QML syntax check
qmllint <pluginName>/*.qml <pluginName>/shared/*.qml

# 2. Check for unused QML imports
python3 scripts/check_unused_imports.py <pluginName>

# 3. Verify backward compatibility against DMS 1.6.2 (Stable)
python3 scripts/check_compatibility.py <pluginName>
```

All three checks must pass with zero errors.
