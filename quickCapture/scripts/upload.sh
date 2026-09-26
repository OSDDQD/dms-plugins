#!/bin/sh
# Quick Capture uploader: uploads a file and prints its public URL as the last line.
#
#   upload.sh <provider> <file> <remote-name> [option] [rc-socket]
#
# provider:
#   rclone     option = rclone destination folder, e.g. "OneDrive:Pictures/Screenshots".
#              Uploads with `rclone copyto`, then prints a share link from `rclone link`
#              (OneDrive, Google Drive, Dropbox, S3 and anything else rclone can link).
#              rc-socket (optional) = unix socket of an already running rclone with
#              `--rc --rc-addr unix://<path> --rc-no-auth` (e.g. `rclone mount`): the
#              upload then reuses its warm connection, token and directory cache instead
#              of starting a new rclone — seconds instead of tens of seconds on OneDrive.
#   catbox     https://catbox.moe, permanent, up to 200 MB, no account needed.
#   litterbox  https://litterbox.catbox.moe, temporary; option = 1h | 12h | 24h | 72h.
#   0x0        https://0x0.st, 30 days to 1 year depending on size, up to 512 MB.
#   custom     option = shell command; the file path is passed as $1 and the remote
#              name as $2. Whatever URL it prints last is used, e.g. for Zipline:
#              curl -fsS -H "authorization: TOKEN" -F file=@"$1" https://zipline.example/api/upload | jq -r '.files[0].url'
#
# QC_UPLOAD_PROXY (env, optional): proxy for the curl-based providers and the custom
# command, e.g. socks5h://127.0.0.1:1080 — for networks whose IP the host blocks.
#
# On failure prints "ERROR: <reason>" and exits non-zero.

PATH="$HOME/.local/bin:$PATH"
export PATH

provider=$1
file=$2
name=$3
option=$4
rc_socket=$5
ua="DMS-QuickCapture/1.0 (+https://github.com/hthienloc/dms-plugins)"
proxy=${QC_UPLOAD_PROXY:-}
if [ -n "$proxy" ]; then
    ALL_PROXY=$proxy HTTPS_PROXY=$proxy
    export ALL_PROXY HTTPS_PROXY
fi

fail() {
    printf 'ERROR: %s\n' "$1"
    exit 1
}

[ -s "$file" ] || fail "file is missing or empty: $file"
[ -n "$name" ] || name=$(basename -- "$file")

need() {
    command -v "$1" >/dev/null 2>&1 || fail "$1 is not installed"
}

run() {
    # Runs a command capturing stdout+stderr; on failure the last lines become the
    # error message, collapsed into one line so it fits a notification.
    out=$("$@" 2>&1) || {
        printf 'ERROR: %s\n' "$(printf '%s' "$out" | tail -n 3 | tr '\n' ' ')"
        return 1
    }
    printf '%s' "$out"
}

# $(...) runs in a subshell, so a failed `run` must be propagated explicitly.
or_die() {
    printf '%s\n' "$1"
    exit 1
}

case "$provider" in
rclone)
    need rclone
    [ -n "$option" ] || fail "rclone destination is not set (e.g. OneDrive:Pictures/Screenshots)"
    dest="${option%/}/$name"
    case "$file" in /*) ;; *) file="$PWD/$file" ;; esac
    if [ -n "$rc_socket" ] && [ -S "$rc_socket" ] && [ "${dest#*:}" != "$dest" ]; then
        fs="${dest%%:*}:"
        remote="${dest#*:}"
        res=$(run rclone rc --unix-socket "$rc_socket" operations/copyfile \
            srcFs=/ "srcRemote=${file#/}" "dstFs=$fs" "dstRemote=$remote") || or_die "$res"
        url=$(run rclone rc --unix-socket "$rc_socket" operations/publiclink "fs=$fs" "remote=$remote") || or_die "$url"
    else
        res=$(run rclone copyto -- "$file" "$dest") || or_die "$res"
        url=$(run rclone link -- "$dest") || or_die "$url"
    fi
    ;;
catbox)
    need curl
    url=$(run curl -fsS -A "$ua" -F reqtype=fileupload -F "fileToUpload=@$file;filename=$name" https://catbox.moe/user/api.php) || or_die "$url"
    ;;
litterbox)
    need curl
    case "$option" in 1h | 12h | 24h | 72h) ;; *) option=24h ;; esac
    url=$(run curl -fsS -A "$ua" -F reqtype=fileupload -F "time=$option" -F "fileToUpload=@$file;filename=$name" https://litterbox.catbox.moe/resources/internals/api.php) || or_die "$url"
    ;;
0x0)
    need curl
    url=$(run curl -fsS -A "$ua" -F "file=@$file;filename=$name" https://0x0.st) || or_die "$url"
    ;;
custom)
    [ -n "$option" ] || fail "custom upload command is not set"
    url=$(run sh -c "$option" _ "$file" "$name") || or_die "$url"
    ;;
*)
    fail "unknown upload provider: $provider"
    ;;
esac

url=$(printf '%s\n' "$url" | tr -d '\r' | grep -Eo 'https?://[^[:space:]"]+' | tail -n 1)
[ -n "$url" ] || fail "no URL in the $provider response"
printf '%s\n' "$url"
