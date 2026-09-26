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
#   0x0        The Null Pointer (https://0x0.st) or any compatible instance; option =
#              instance URL (default https://0x0.st), e.g. https://x0.at.
#              QC_UPLOAD_TOKEN (env, optional) is sent as the X-Upload-Token header —
#              for a private instance whose proxy only accepts uploads carrying it.
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
ua="DMS-QuickCapture/1.0 (+https://github.com/OSDDQD/dms-plugins)"
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

# POSTs a multipart form with curl and prints the response body. Unlike `curl -f`,
# an HTTP error keeps the server's own explanation (e.g. 0x0.st's "uploads disabled").
post() {
    body=$(curl -sS -A "$ua" -w '\n%{http_code}' "$@" 2>&1) || {
        printf 'ERROR: %s\n' "$(printf '%s' "$body" | grep 'curl:' | tail -n 1)"
        return 1
    }
    code=$(printf '%s' "$body" | tail -n 1)
    body=$(printf '%s' "$body" | sed '$d')
    case "$code" in
    2??) printf '%s' "$body" ;;
    *)
        # HTML error pages are useless in a notification — keep only plain-text replies.
        case "$body" in *"<"*">"*) body="" ;; esac
        [ "$code" = 403 ] && [ -z "$body" ] && body="forbidden (the host may block your network — try an upload proxy)"
        printf 'ERROR: HTTP %s %s\n' "$code" "$(printf '%s' "$body" | head -n 2 | tr '\n' ' ' | cut -c1-200)"
        return 1
        ;;
    esac
}

# $(...) runs in a subshell, so a failed `run`/`post` must be propagated explicitly.
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
    url=$(post -F reqtype=fileupload -F "fileToUpload=@$file;filename=$name" https://catbox.moe/user/api.php) || or_die "$url"
    ;;
litterbox)
    need curl
    case "$option" in 1h | 12h | 24h | 72h) ;; *) option=24h ;; esac
    url=$(post -F reqtype=fileupload -F "time=$option" -F "fileToUpload=@$file;filename=$name" https://litterbox.catbox.moe/resources/internals/api.php) || or_die "$url"
    ;;
0x0)
    need curl
    instance=${option:-https://0x0.st}
    set -- -F "file=@$file;filename=$name" "${instance%/}/"
    [ -n "${QC_UPLOAD_TOKEN:-}" ] && set -- -H "X-Upload-Token: $QC_UPLOAD_TOKEN" "$@"
    url=$(post "$@") || {
        # A private instance hides its upload route from requests without the
        # right token, so a 404 on POST almost always means a token problem.
        case "$url" in "ERROR: HTTP 404"*) url="ERROR: upload rejected (HTTP 404) — check the upload token" ;; esac
        or_die "$url"
    }
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
