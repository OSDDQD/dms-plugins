# DMS Components Reference

Always prefer built-in DMS primitives (`qs.Widgets`) and repository shared components (`import "./shared"`) over custom ad-hoc shapes.

---

## 1. Official DMS Widgets (`qs.Widgets`)

### `DankActionButton`
Compact circular or square icon buttons for toolbars, headers, and DankBar widgets.

```qml
import qs.Common
import qs.Widgets

DankActionButton {
    buttonSize: Theme.buttonHeightS // 40px standard
    circular: true
    iconName: "volume_up"
    iconSize: Theme.iconSizeMedium  // 20px
    iconColor: Theme.surfaceText
    backgroundColor: Theme.surfaceContainerHigh
    tooltipText: I18n.tr("Adjust Volume")
    onClicked: root.toggleMute()
}
```

### `DankButton`
Standard text button with optional leading or trailing icons.

```qml
DankButton {
    text: I18n.tr("Save")
    iconName: "check"
    buttonHeight: Theme.buttonHeightS
    onClicked: root.save()
}
```

### `DankDropdown`
Dropdown selector supporting outside-click dismissal, anchoring, and keyboard focus.

```qml
DankDropdown {
    width: parent.width
    height: Theme.buttonHeightS
    compactMode: true
    dropdownWidth: width
    emptyText: I18n.tr("Select preset…")
    options: root.presets.map(p => p.name)
    currentValue: root.currentPresetName
    onValueChanged: (val) => root.selectPreset(val)
}
```

### `DankSlider`
Compact slider for continuous numeric ranges (opacity, volume, speed).

```qml
DankSlider {
    width: parent.width
    from: 0
    to: 100
    value: root.currentVolume
    onMoved: (val) => root.setVolume(val)
}
```

---

## 2. Repository Shared Components (`./shared`)

Import the local plugin shared folder:
```qml
import "./shared"
```

| Component | Purpose & Description |
| :--- | :--- |
| **`SettingsCard`** | Standard container card grouping related settings rows with background and padding. |
| **`SectionTitle`** | Card header with icon, collapsible toggle support, and reset button. |
| **`UsageGuide`** | Collapsible or inline list of instruction bullets with formatted emphasis. |
| **`ToggleSettingPlus`** | Standard toggle switch row with label, description, and settings persistence. |
| **`SliderSettingPlus`** | Slider row with unit, min/max bounds, left/right labels, and reset button. |
| **`SelectionSettingPlus`**| Dropdown or modal selection row with options array. |
| **`ColorSettingPlus`** | Color swatch picker row with hex input and predefined palette presets. |
| **`StringSettingPlus`** | Single-line text input row with placeholder and clear button. |
| **`ButtonGroupSettingPlus`**| Horizontal segmented button selector for discrete modes. |
| **`CopyBox`** | Command/text display box with one-click copy button. |
| **`CreditsList`** | Standardized credits list with Material 3 author chip badges, URLs, and role text. |
| **`Separator`** | Thin divider line between settings rows. |
| **`NumericText`** | Number counter or readout with formatted units. |
