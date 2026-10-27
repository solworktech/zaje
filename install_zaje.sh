#!/bin/sh

set -e
log_use_fancy_output () {
    TPUT_STYLE=
    if [ -t 1 ] && [ -z "${NO_COLOR:-}" ] &&
       [ -n "${TERM:-}" ] && [ "$TERM" != "dumb" ]; then
        if tput setaf 1 >/dev/null 2>&1; then
            TPUT_STYLE=terminfo
        elif tput AF 1 >/dev/null 2>&1; then
            TPUT_STYLE=termcap
        fi
    fi

    # an explicit FANCYTTY from the caller wins; otherwise colours are on if tput works
    if [ -z "${FANCYTTY:-}" ]; then
        if [ -n "$TPUT_STYLE" ]; then FANCYTTY=1; else FANCYTTY=0; fi
    fi

    case "$FANCYTTY" in
        1|Y|yes|true) return 0 ;;
        *)            return 1 ;;
    esac
}

# _cap <terminfo name> [args]: runs tput with the name that this system understands
_cap () {
    _cap_name=$1; shift
    if [ "$TPUT_STYLE" = termcap ]; then
        case "$_cap_name" in
            setaf) _cap_name=AF ;;   # foreground colour
            bold)  _cap_name=md ;;
            sgr0)  _cap_name=me ;;   # all attributes off
            op)    _cap_name=op ;;   # original colour pair (same in both)
        esac
    fi
    tput "$_cap_name" "$@"
}

if log_use_fancy_output; then
    RED=$(_cap setaf 1)
    YELLOW=$(_cap setaf 3)
    BLUE=$(_cap setaf 6)
    NORMAL=$(_cap setaf 2)
    BOLD=$(_cap bold)
    UNSET=$(_cap op)
fi

if [ ! "$(which curl 2>/dev/null)" ];then
	printf '%b' "${RED}Need to install curl.${NORMAL}\n"
	exit 2
fi   

GIT_BASE_DOMAIN="github.com"
NAME="zaje"
HIGHLIGHT_REPO_NAME="gohighlight"
GH_SPACE="jessp01"
LATEST_VER=$(curl -sL "https://api.${GIT_BASE_DOMAIN}/repos/$GH_SPACE/$NAME/releases/latest" \
  | grep tag_name \
  | sed 's@[[:space:]]*"tag_name":[[:space:]]*"\(.*\)".*@\1@' \
  | xargs)
OS=$(uname)
case "$(uname -m)" in
  x86_64|amd64)        ARCH=x86_64 ;;
  aarch64|arm64)       ARCH=arm64 ;;
  i386|i486|i586|i686) ARCH=i386 ;;
  armv7*)              ARCH=armv7 ;;
  armv6*)              ARCH=armv6 ;;
  *) echo "unsupported architecture: $(uname -m)" >&2; exit 1 ;;
esac

BIN_ARCHIVE="${NAME}_${OS}_${ARCH}.tar.gz"

# we need this for the lexers
LATEST_HIGHLIGHT_VER=$(curl -sL "https://api.${GIT_BASE_DOMAIN}/repos/$GH_SPACE/$HIGHLIGHT_REPO_NAME/releases/latest" \
  | grep tag_name \
  | sed 's@[[:space:]]*"tag_name":[[:space:]]*"\(.*\)".*@\1@' \
  | xargs)
HIGHLIGHT_SOURCE_ARCHIVE="${LATEST_HIGHLIGHT_VER}.tar.gz"

CONFIG_DIR="$HOME/.config/$NAME"
LEXERS_DIR="$CONFIG_DIR/syntax_files"
TMP_DIR="/tmp/${NAME}_$(id -u)"
FUNCTIONS_RC_FILE="$CONFIG_DIR/${NAME}_functions.rc"


printf '%b' "${BOLD}${NORMAL}\nWelcome to ${BLUE}$NAME ($LATEST_VER)${NORMAL}'s installation script:)\n"

mkdir -p "$CONFIG_DIR" "$TMP_DIR"
cd "$TMP_DIR"

printf '%b' "${NORMAL}Fetching sources...\n\n"
curl -Ls "https://${GIT_BASE_DOMAIN}/$GH_SPACE/$NAME/releases/download/${LATEST_VER}/${BIN_ARCHIVE}" --output "${BIN_ARCHIVE}"
curl -Ls "https://${GIT_BASE_DOMAIN}/$GH_SPACE/$HIGHLIGHT_REPO_NAME/archive/refs/tags/${HIGHLIGHT_SOURCE_ARCHIVE}" --output "${HIGHLIGHT_SOURCE_ARCHIVE}"

tar zxf "$BIN_ARCHIVE"
mkdir -p ~/bin
mv "$NAME" ~/bin
mv README.md LICENSE "$CONFIG_DIR"


TIMESTAMP=$(date +%s)

if [ -f "$CONFIG_DIR/${NAME}_functions.rc" ];then
# shellcheck disable=SC2059
    printf "${BOLD}${YELLOW}$FUNCTIONS_RC_FILE already exists...\n${NORMAL}I'll place the new copy under ${BLUE}${FUNCTIONS_RC_FILE}.${TIMESTAMP}${NORMAL}\n\n"
    FUNCTIONS_RC_FILE="${FUNCTIONS_RC_FILE}.${TIMESTAMP}"
fi

curl -Ls "https://${GIT_BASE_DOMAIN}/$GH_SPACE/$NAME/raw/$LATEST_VER/utils/functions.rc" -o "$FUNCTIONS_RC_FILE"

if [ -d "$LEXERS_DIR" ];then
# shellcheck disable=SC2059
    printf "${YELLOW}$LEXERS_DIR already exists...\n${NORMAL}I'll place the new lexers under ${BLUE}${LEXERS_DIR}.${TIMESTAMP}${NORMAL}\n\n"
    LEXERS_DIR="${LEXERS_DIR}.${TIMESTAMP}"
fi

tar zxf "$HIGHLIGHT_SOURCE_ARCHIVE"
VERSION_NO_V=$(echo "$LATEST_HIGHLIGHT_VER" | sed 's/^v\(.*\)/\1/')
mv "$HIGHLIGHT_REPO_NAME-$VERSION_NO_V/syntax_files" "$LEXERS_DIR"

# shellcheck disable=SC2059
printf "All sorted:)\n\n${BLUE}* $NAME${NORMAL} binary is in ~/bin/${NAME}. Make sure to include it in PATH.\n"
# shellcheck disable=SC2059
printf "* Useful helper functions are under ${BLUE}$FUNCTIONS_RC_FILE\n${NORMAL}  Source them with ${BLUE}'. $FUNCTIONS_RC_FILE'${NORMAL}.\n"
# shellcheck disable=SC2059
printf "* Lexers are under ${BLUE}$LEXERS_DIR${NORMAL}\n\n"
# shellcheck disable=SC2059
printf "Downloaded archives are available in ${BLUE}$TMP_DIR${NORMAL}.. Feel free to discard them.${UNSET}\n"


PATH=$PATH:~/bin
# shellcheck disable=SC1090
. "$FUNCTIONS_RC_FILE"

cd -
# shellcheck disable=SC2059
printf "\nWe've sourced ${BLUE}$FUNCTIONS_RC_FILE${NORMAL} and set 'PATH=\$PATH:~/bin' in this script to check that it is working...\nsample output:\n\n"

# shellcheck disable=SC2059
printf "${YELLOW}df -h:${NORMAL}\n"
df -h /home /

# shellcheck disable=SC2059
printf "${YELLOW}du -h $0:${NORMAL}\n"
du -h "$0"

# shellcheck disable=SC2059
printf "${YELLOW}ping localhost -c1:${NORMAL}\n"
ping localhost -c1

# shellcheck disable=SC2059
printf "\n${YELLOW}hello.c:${NORMAL}\n"
printf "#include <stdio.h>\nprintf(\"hello world\");\n" | zaje

if [ "$(id -u)" = 0 ];then
    cp ~/bin/${NAME} /usr/local/bin/${NAME}
# shellcheck disable=SC2059
    printf "Copied ${BLUE}~/bin/${NAME}${NORMAL} to ${BLUE}/usr/local/bin/${NAME}${NORMAL}\n"
    # we don't want to override if exists
    if [ ! -r /etc/profile.d/${NAME}.sh ];then
	cp "$FUNCTIONS_RC_FILE" /etc/profile.d/${NAME}.sh
# shellcheck disable=SC2059
	printf "Copied ${BLUE}$FUNCTIONS_RC_FILE${NORMAL} to ${BLUE}/etc/profile.d/${NAME}.sh${NORMAL}\n"
    fi
    if [ ! -d /etc/${NAME}/syntax_files ];then
	mkdir -p /etc/${NAME}
	cp -r "$LEXERS_DIR" "/etc/${NAME}"
# shellcheck disable=SC2059
	printf "Copied ${BLUE}$LEXERS_DIR${NORMAL} to ${BLUE}/etc/${NAME}${NORMAL}\n"
    fi
else
	printf "Add the below to shell's RC (~/.bashrc, ~/.profile, etc):\n===\n%s. %s\nPATH=\$PATH:~/bin\n%s===\n" "${BLUE}" "${FUNCTIONS_RC_FILE}" "${NORMAL}"
fi

if log_use_fancy_output ;then
    _cap sgr0
fi

