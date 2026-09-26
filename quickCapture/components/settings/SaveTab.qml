import QtQuick
import qs.Common
import "../../dms-common"
import "../core/Defaults.js" as Defaults

SettingsGroup {
    id: root

    property QtObject config: null

    SettingsSection {
        title: I18n.trFor("quickCapture", "Save")
        icon: "save"

        ButtonGroupSettingPlus {
            settingKey: "doneAction"
            label: I18n.trFor("quickCapture", "Action on %1").arg("Enter")
            options: [
                {
                    label: I18n.trFor("quickCapture", "Copy"),
                    value: "clipboard"
                },
                {
                    label: I18n.trFor("quickCapture", "Save"),
                    value: "file"
                },
                {
                    label: I18n.trFor("quickCapture", "Copy & Save"),
                    value: "both"
                },
                {
                    label: I18n.trFor("quickCapture", "Upload"),
                    value: "upload"
                }
            ]
            defaultValue: Defaults.values.doneAction
        }

        Separator {}

        StringSettingPlus {
            settingKey: "saveDirectory"
            label: I18n.trFor("quickCapture", "Screenshot Folder")
            placeholder: Defaults.values.saveDirectory
            defaultValue: Defaults.values.saveDirectory
            isDirectory: true
        }

        Separator {}

        StringSettingPlus {
            settingKey: "saveFilenamePattern"
            label: I18n.trFor("quickCapture", "Filename Pattern")
            placeholder: Defaults.values.saveFilenamePattern
            defaultValue: Defaults.values.saveFilenamePattern
        }

        InfoText {
            text: I18n.trFor("quickCapture", "Format tokens: %Y (Year), %y (2-digit year), %m (Month), %d (Day), %H (Hour), %M (Minute), %S (Second), {zzz} (Ms)")
        }

        Separator {}

        ButtonGroupSettingPlus {
            id: outputFormat
            settingKey: "outputFormat"
            label: I18n.trFor("quickCapture", "Output Format")
            options: [
                {
                    label: "PNG",
                    value: "png"
                },
                {
                    label: "JPEG",
                    value: "jpg"
                },
                {
                    label: "WebP",
                    value: "webp"
                },
                {
                    label: "PDF",
                    value: "pdf"
                },
                {
                    label: "PPM",
                    value: "ppm"
                }
            ]
            defaultValue: Defaults.values.outputFormat
        }

        InfoText {
            text: I18n.trFor("quickCapture", "Output format applies only to disk saves. Clipboard copies are always PNG.")
        }

        SettingsGroup {
            visible: outputFormat.value === "jpg"

            Separator {}

            SliderSettingPlus {
                settingKey: "jpegQuality"
                label: I18n.trFor("quickCapture", "JPEG Quality")
                defaultValue: Defaults.values.jpegQuality
                minimum: 1
                maximum: 100
                unit: "%"
                leftLabel: "1"
                rightLabel: "100"
            }
        }

        SettingsGroup {
            visible: outputFormat.value === "webp"

            Separator {}

            SliderSettingPlus {
                settingKey: "webpQuality"
                label: I18n.trFor("quickCapture", "WebP Quality")
                defaultValue: Defaults.values.webpQuality
                minimum: 1
                maximum: 100
                unit: "%"
                leftLabel: "1"
                rightLabel: "100"
            }
        }
    }

    SettingsSection {
        title: I18n.trFor("quickCapture", "Upload")
        icon: "cloud_upload"

        SelectionSettingPlus {
            id: uploadProvider
            settingKey: "uploadProvider"
            label: I18n.trFor("quickCapture", "Upload Provider")
            description: I18n.trFor("quickCapture", "Where Ctrl+U and the upload button send the image. The link is copied to the clipboard.")
            options: [
                {
                    label: "catbox.moe",
                    value: "catbox"
                },
                {
                    label: I18n.trFor("quickCapture", "litterbox (temporary)"),
                    value: "litterbox"
                },
                {
                    label: "0x0.st",
                    value: "0x0"
                },
                {
                    label: I18n.trFor("quickCapture", "rclone (OneDrive, Google Drive, S3...)"),
                    value: "rclone"
                },
                {
                    label: I18n.trFor("quickCapture", "Custom command"),
                    value: "custom"
                }
            ]
            defaultValue: Defaults.values.uploadProvider
        }

        SettingsGroup {
            visible: uploadProvider.value === "rclone"

            Separator {}

            StringSettingPlus {
                settingKey: "uploadRcloneRemote"
                label: I18n.trFor("quickCapture", "rclone Destination")
                placeholder: "OneDrive:Pictures/Screenshots"
                defaultValue: Defaults.values.uploadRcloneRemote
            }

            InfoText {
                text: I18n.trFor("quickCapture", "Remote and folder from `rclone config`. The public link comes from `rclone link` (view-only, anyone with the link).")
            }

            Separator {}

            StringSettingPlus {
                settingKey: "uploadRcloneRcSocket"
                label: I18n.trFor("quickCapture", "rclone RC Socket (optional)")
                placeholder: "/run/user/1000/rclone-onedrive.sock"
                defaultValue: Defaults.values.uploadRcloneRcSocket
            }

            InfoText {
                text: I18n.trFor("quickCapture", "Unix socket of a running rclone (e.g. your `rclone mount`) started with `--rc --rc-addr unix://<path> --rc-no-auth`. Reuses its warm connection: uploads take seconds instead of tens of seconds. Falls back to plain rclone if the socket is missing.")
            }
        }

        SettingsGroup {
            visible: uploadProvider.value === "litterbox"

            Separator {}

            ButtonGroupSettingPlus {
                settingKey: "uploadLitterboxTime"
                label: I18n.trFor("quickCapture", "Expires After")
                options: [
                    {
                        label: "1h",
                        value: "1h"
                    },
                    {
                        label: "12h",
                        value: "12h"
                    },
                    {
                        label: "24h",
                        value: "24h"
                    },
                    {
                        label: "72h",
                        value: "72h"
                    }
                ]
                defaultValue: Defaults.values.uploadLitterboxTime
            }
        }

        SettingsGroup {
            visible: uploadProvider.value === "custom"

            Separator {}

            StringSettingPlus {
                settingKey: "uploadCustomCommand"
                label: I18n.trFor("quickCapture", "Upload Command")
                placeholder: "curl -fsS -H 'authorization: TOKEN' -F file=@\"$1\" https://zipline.example/api/upload | jq -r '.files[0].url'"
                defaultValue: Defaults.values.uploadCustomCommand
            }

            InfoText {
                text: I18n.trFor("quickCapture", "Runs with sh: $1 is the file, $2 its name. The last URL printed is used.")
            }
        }

        SettingsGroup {
            visible: uploadProvider.value !== "rclone"

            Separator {}

            StringSettingPlus {
                settingKey: "uploadProxy"
                label: I18n.trFor("quickCapture", "Upload Proxy (optional)")
                placeholder: "socks5h://127.0.0.1:1080"
                defaultValue: Defaults.values.uploadProxy
            }

            InfoText {
                text: I18n.trFor("quickCapture", "Some hosts reject uploads from certain networks with 403. Route uploads through a proxy (curl syntax).")
            }
        }

        Separator {}

        ToggleSettingPlus {
            settingKey: "uploadCopyUrl"
            label: I18n.trFor("quickCapture", "Copy Link to Clipboard")
            defaultValue: Defaults.values.uploadCopyUrl
        }

        Separator {}

        ToggleSettingPlus {
            settingKey: "uploadKeepLocal"
            label: I18n.trFor("quickCapture", "Also Save to Screenshot Folder")
            description: I18n.trFor("quickCapture", "Keep a local copy of every uploaded screenshot.")
            defaultValue: Defaults.values.uploadKeepLocal
        }

        Separator {}

        ToggleSettingPlus {
            settingKey: "uploadRecordings"
            label: I18n.trFor("quickCapture", "Upload Recordings Automatically")
            description: I18n.trFor("quickCapture", "Upload every finished screen recording and copy its link.")
            defaultValue: Defaults.values.uploadRecordings
        }
    }

    SettingsSection {
        title: I18n.trFor("quickCapture", "Notifications")
        icon: "notifications"

        ButtonGroupSettingPlus {
            settingKey: "postNotification"
            label: I18n.trFor("quickCapture", "Post-Capture Notification")
            description: I18n.trFor("quickCapture", "Choose notifications shown after copy or save.")
            defaultValue: Defaults.values.postNotification
            options: [
                {
                    label: I18n.trFor("quickCapture", "Notification"),
                    value: "notification"
                },
                {
                    label: I18n.trFor("quickCapture", "Toast"),
                    value: "toast"
                },
                {
                    label: I18n.trFor("quickCapture", "Both"),
                    value: "both"
                },
                {
                    label: I18n.trFor("quickCapture", "None"),
                    value: "none"
                }
            ]
        }
    }
}
