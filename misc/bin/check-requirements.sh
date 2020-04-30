#!/bin/bash
#
# Setup development system for Yocto Project
#
# Copyright (c) 2017-2018 Behan Webster <behanw@converseincode.com>
#
# Licensed under GPL
#
# Based on ready-for.sh
#
# Version 1.0: 2018-11-15 check-requirements.sh
#     - Remove Ubuntu-12.04
#     - Add Debian-10
#     - Fix packaging errors
#===============================================================================
VERSION=1.0

#===============================================================================
#
# You can define requirements for a particular activity by defining the following
# variables where YP is your activity code:
#
#   TITLE[YP]=""            # Name of the package group
#   ARCH[YP]=x86_64         # Required CPU arch (optional)
#   CPUS[YP]=2              # How many CPUS/cores are required
#   PREFER_CPUS[YP]=4       # How many CPUS would be preferred
#   BOGOMIPS[YP]=4000       # How many cumulative BogoMIPS you need
#   RAM[YP]=2               # How many GiB of RAM you need
#   DISK[YP]=30             # How many GiB of Disk you need free in $HOME
#   DISTRO_ARCH[YP]=x86_64  # Required Linux distro arch (optional)
#   INTERNET[YP]=y          # Is internet access required? (optional)
#   DISTROS[YP]="Fedora-21+ CentOS-6+ Ubuntu-16.04+"
#                           # List of distros you can support.
#                           #   DistroName
#                           #   DistroName:arch
#                           #   DistroName-release
#                           #   DistroName-release+
#                           #   DistroName:arch-release
#                           #   DistroName:arch-release+
#
# Note: I know BogoMIPS aren't a great measure of CPU speed, but it's what we have
# easy access to.
#
# You can also specify required packages for your distro. All the appropriate
# package lists for the running machine will be checked. This allows you to
# keep package lists for particular distros, releases, arches and classes.
# For example:
#
#   PACKAGES[Ubuntu]="gcc less"
#   PACKAGES[Ubuntu_YP]="stress trace-cmd"
#   PACKAGES[Ubuntu-14.04]="git-core"
#   PACKAGES[Ubuntu-16.04]="git"
#   PACKAGES[Ubuntu-16.04_YP]="gparted u-boot-tools"
#   PACKAGES[Ubuntu_YP]="build-dep_wireshark"
#   PACKAGES[RHEL]="gcc less"
#   PACKAGES[RHEL-6]="git"
#   PACKAGES[RHEL-6_YP]="trace-cmd"
#
# Missing packages are listed so the user can install them manually, or you can
# rerun this script with --install to do it automatically.
#
# You can also copy the identical package list from another activity with:
#
#   COPYPACKAGES[YPGUI] = "YP"
#
# Support for all distros is not yet finished, but I've templated in code where
# possible. If you can add code to support a distro, please send a patch!
#
# If you want to see extra debug output, set DEBUG=1 2 or 3
#
#    DEBUG=2 ./check-requirements.sh YP
# or
#    ./check-requirements.sh --debug=2 YP
# or
#    ./check-requirements.sh -DD YP
#

#===============================================================================
RED="\e[0;31m"
GREEN="\e[0;32m"
YELLOW="\e[0;33m"
CYAN="\e[0;36m"
BLUE="\e[0;34m"
BACK="\e[0m"

#===============================================================================
# Strict debugging
#set -euo pipefail
DEBUG=
FAILED=
MISSING_PACKAGES=
NO_WARN=
SIMULATE_FAILURE=
VERBOSE=
WARNINGS=

#-------------------------------------------------------------------------------
ask() {
    echo -ne "${YELLOW}WARN${BACK}: $* " >&2
}

#-------------------------------------------------------------------------------
bare_debug() {
    [[ -z $DEBUG ]] || echo "$@" >&2
}

#-------------------------------------------------------------------------------
bug() {
    local MSG=$1 CODE=$2
    warn "Hmm... That's not right...\n    $MSG\n    Probably a bug. Please send the output of the following to behanw@converseincode.com\n      $CODE"
}

#-------------------------------------------------------------------------------
debug() {
    local LEVEL=$1; shift
    local OPT=
    if [[ $1 == -* ]] ; then
        OPT=$1; shift
    fi
    if [[ -n $DEBUG && $LEVEL -le $DEBUG ]] ; then
        # shellcheck disable=SC2086
        bare_debug $OPT "D:" "$@"
    fi
}

#-------------------------------------------------------------------------------
divider() {
    echo '---'${VERBOSE:+ $* }'-----------------------------------------------------------------------------'
}

#-------------------------------------------------------------------------------
dothis() {
    echo -e "${BLUE}$*${BACK}"
}

#-------------------------------------------------------------------------------
export MYPID=$$
error() {
    echo E: "$@" >&2
    set -e
    kill -TERM $MYPID 2>/dev/null
}

#-------------------------------------------------------------------------------
fail() {
    echo -e "${RED}FAIL${BACK}:" "$@" >&2
}

#-------------------------------------------------------------------------------
fix_missing() {
    local MSG=$1 CMD1=$2 CMD2=$3
    highlight "$MSG by running:"
    # shellcheck disable=SC2086
    dothis "  "$CMD1
    if [[ -n $CMD2 ]] ; then
        highlight "or by:"
        # shellcheck disable=SC2086
        dothis "  "$CMD2
    fi
}

#-------------------------------------------------------------------------------
highlight() {
    echo -e "${YELLOW}$*${BACK}" >&2
}

#-------------------------------------------------------------------------------
notice() {
    local OPT=
    if [[ $1 == -* ]] ; then
        OPT=$1; shift
    fi
    if [[ -n $OPT || -z $NO_WARN ]] ; then
        # shellcheck disable=SC2086
        echo $OPT -e "${CYAN}NOTE${BACK}: $*" >&2
    fi
}

#-------------------------------------------------------------------------------
pass() {
    [[ -n ${NO_PASS:-} ]] || echo -e "${GREEN}PASS${BACK}: $*"
}

#-------------------------------------------------------------------------------
progress() {
    [[ -z ${PROGRESS:-} ]] || echo -en "$1" >&2
}

#-------------------------------------------------------------------------------
verbose() {
    [[ -z $VERBOSE ]] || echo -e "INFO:" "$@" >&2
}

#-------------------------------------------------------------------------------
warn() {
    local OPT=
    if [[ $1 == -* ]] ; then
        OPT=$1; shift
    fi
    if [[ -n $OPT || -z $NO_WARN ]] ; then
        # shellcheck disable=SC2086
        echo $OPT -e "${YELLOW}WARN${BACK}: $*" >&2
    fi
}

#-------------------------------------------------------------------------------
warn_wait() {
    if [[ -n $YES ]] ; then
        debug 1 "warn_wait: always --yes, so not asking; just continue."
        return 0
    fi
    warn -n "$*\n    Continue? [Yn] " >&2
    read -r ANS
    case $ANS in
        Y*|y*|1*) return 0 ;;
        *) [[ -z $ANS ]] || return 1 ;;
    esac
    return 0
}

#===============================================================================
# The minimum version of bash required to run this script is bash v4
if bash --version | grep -E -q 'GNU bash, version [1-3]' ; then
    fail "This script requires at least version 4 of bash"
    fail "You are running: $(bash --version | head -1)"
    exit 1
fi

#===============================================================================
check_root() {
    if [[ $USER == root || $HOME == /root ]] ; then
        fail "Please don't run as root"
        notice "Sudo will be used internally by this script as required."
        exit 1
    fi
}
check_root


#===============================================================================
CMDNAME=${CMDNAME:-$0}
CMDBASE=$(basename "$CMDNAME")
usage() {
    COURSE=${COURSE# }
    echo "Usage: $CMDBASE [options] [requirement-list]"
    echo "      --distro               List current Linux distro"
    echo "  -i  --install              Install missing packages"
    echo "      --json                 Generate JSON file of all requirements"
    echo "  -l  --list                 List all supported requirements lists"
    echo "      --list-requirements    List requirements for all Linux distros"
    echo "  -r  --remove [--all]       Remove installed packages"
    echo "      --no-cache             Don't use previously cached output."
    echo "  -I  --no-install           Don't check installed packages"
    echo "      --no-network           Disable network check (for testing purposes)"
    echo "  -R  --no-recommends        Don't install recommended packages"
    echo "  -S  --no-suggests          Don't install suggested packages"
    echo "      --update               Update to latest version of this script"
    echo "      --verify               Verify script MD5sum against upstream"
    echo "  -V  --version              List script version"
    echo "  -v  --verbose              Turn on extra messages"
    echo "  -y  --yes                  Answer 'yes' to every question"
    echo
    echo "Example: $CMDBASE --list"
    echo "         $CMDBASE YP"
    echo "         $CMDBASE --install YP"
    exit 0
}

#===============================================================================
# Default command option flags
ALL_ACTIVITIES=
ALL_LFD=
ALL_LFS=
ALL_PKGS=
CHECK_PKGS=
COURSE=
DIST_LIST=
DONTUPDATE=
DRYRUN=
FORCEUPDATE=
GATHER_INFO=
INSTALL=
JSON=
LIST_ACTIVITIES=
LIST_DISTROS=
LIST_PKGS=
LIST_REQS=
NOCACHE=
NOCM=
NOEXTRAS=
NOINSTALL=
NONETWORK=
NORECOMMENDS=
NOSUGGESTS=
NOVM=
PKGS=
PROGRESS=
REMOVE=
TRY_ALL_ACTIVITIES=
UPDATE=
USECURL=
VERIFY=
WHICH_DISTRO=
YES=
#===============================================================================
# Command option parsing
COURSE=
CMDOPTS="$*"
while [[ $# -gt 0 ]] ; do
    case "$1" in
        -A|--all|--all-activities) ALL_ACTIVITIES=y ;;
        -ap|--all-packages) ALL_PKGS=y ;;
        --check-packages) CHECK_PKGS=y ;;
        #--curl) USECURL=y ;;
        -D|--debug=1|--debug) DEBUG=1; VERBOSE=y ;;
        -DD|--debug=2) DEBUG=2; VERBOSE=y ;;
        -DDD|--debug=3) DEBUG=3; VERBOSE=y ;;
        --dry-run|--dryrun) DRYRUN=echo ;;
        --distro) WHICH_DISTRO=y ;;
        -i|--install) INSTALL=y ;;
        --force-update) FORCEUPDATE=y ;;
        --gather-info) GATHER_INFO=y ;;
        --json) JSON=y ;;
        -l|--list) LIST_ACTIVITIES=y; break ;;
        --list-distro*) LIST_DISTROS=y; break ;;
        -P|--list-packages) LIST_PKGS=y ;;
        -L|--list-requirements) LIST_REQS=y ;;
        --no-cache|--nocache) NOCACHE=y ;;
        -I|--no-install) NOINSTALL=y ;;
        --no-network) NONETWORK=y; DONTUPDATE=y ;;
        -R|--no-recommends) NORECOMMENDS=y ;;
        -S|--no-suggests) NOSUGGESTS=y ;;
        -O|--override-distro) DISTRO=$2; DIST_LIST=$2; shift ;;
        -p|--packages) LIST_PKGS=y; PKGS="${PKGS# } $2"; shift ;;
        -r|--remove) REMOVE=y ;;
        --progress) PROGRESS=y ;;
        --simulate-failure) SIMULATE_FAILURE=y; NOCACHE=y ;;
        --strict) set -euo pipefail ;;
        --trace) set -x ;;
        --update-*) UPDATE=${1#--update-}; VERIFY=''; VERBOSE=y ;;
        --update) UPDATE=y; VERBOSE=y ;;
        --verify-*) UPDATE=''; VERIFY=${1#--verify-} ;;
        --verify) VERIFY=y ;;
        -U|--user) USER=$2; HOME=$(getent passwd "$2" | cut -d: -f6); shift ;;
        -v|--verbose) VERBOSE=y ;;
        -V|--version) echo $VERSION; exit 0 ;;
        -y|--yes) YES=y ;;
        -h*|--help*|-*) usage ;;
        *) COURSE="${COURSE# } $1" ;;
    esac
    shift
done
PKGS="${PKGS# }"
debug 1 "main: Command Line Parameters: CMD=$CMDNAME => $CMDOPTS ($PKGS)"
debug 1 "main: COURSE=$COURSE $(env | grep '=y$')"

#===============================================================================
CONFFILE="$HOME/.${CMDBASE%.sh}.rc"
if [[ -f $CONFFILE ]] ; then
    notice "Reading $CONFFILE"
    # shellcheck disable=SC1090
    source "$CONFFILE"
fi

#===============================================================================
# Allow info to be gathered in order to fix distro detection problems
gather() {
    local FILE
    FILE=$(which "$1" 2>/dev/null || echo "$1")
    shift
    if [[ -n $FILE && -e $FILE ]] ; then
        echo "--- $FILE ---------------------------------------------"
        if [[ -x $FILE ]] ; then
            "$FILE" "$@"
        else
            cat "$FILE"
        fi
    fi
}

#===============================================================================
# Gather information to send to script maintainer about this computer for debugging
gather_info() {
    divider
    /bin/bash --version | head -1
    gather lsb_release --all
    gather /etc/lsb-release
    gather /etc/os-release
    gather /etc/debian_version
    gather /etc/apt/sources.list
    gather /etc/redhat-release
    gather /etc/SuSE-release
    gather /etc/arch-release
    gather /etc/gentoo-release
    divider
    exit 0
}
[[ -z $GATHER_INFO ]] || gather_info

#===============================================================================
# Just in case we're behind a proxy server (the system will add settings to /etc/environment)
if [[ -f /etc/environment ]] ; then
    . /etc/environment
fi
export all_proxy http_proxy https_proxy ftp_proxy

#===============================================================================
# See if version is less than the other
version_greater_equal() {
    local i LEN VER1 VER2
    IFS=. read -r -a VER1 <<< "$1"
    IFS=. read -r -a VER2 <<< "$2"
    # shellcheck disable=SC2145
    debug 3 "version_greater_equal: $1(${#VER1[*]})=>[${VER1[@]}] $2(${#VER2[*]})=>[${VER2[@]}]"
    LEN=$( (( ${#VER1[*]} > ${#VER2[*]} )) && echo ${#VER1[*]} || echo ${#VER2[*]})
    #echo "VER1[0] => ${VER1[0]}"
    #echo "VER2[0] => ${VER2[0]}"
    for ((i=0; i<LEN; i++)) ; do
        VER1[i]=${VER1[i]:-0}; VER1[i]=${VER1[i]#0};
        VER2[i]=${VER2[i]:-0}; VER2[i]=${VER2[i]#0};
        debug 3 "  version_greater_equal: Compare ${VER1[i]} and ${VER2[i]}"
        if (( ${VER1[i]:-0} > ${VER2[i]:-0} )) ; then
            return 0
        elif (( ${VER1[i]:-0} < ${VER2[i]:-0} )) ; then
            return 1
        fi
    done
    return 0
}

#===============================================================================
# See if md5sum is the same
md5cmp() {
    local FILE=$1 MD5=$2
    debug 3 "md5cmp FILE=$FILE MD5=$MD5"
    [[ $MD5 = $(md5sum "$FILE" | awk '{print $1}') ]] || return 1
    return 0
}

CMCACHE="$HOME/.cache/${CMDBASE%.sh}"

#===============================================================================
# Clean meta variable cache
clean_cache() {
    debug 1 "clean_cache: $CMCACHE"
    mkdir -p "$CMCACHE"
    find "$CMCACHE" -mtime +0 -type f -print0 | xargs -0 --no-run-if-empty rm -f
    rm -f "$CMCACHE/*.conf"
}
clean_cache

#===============================================================================
cache_output() {
    local ACTIVITY="$1"
    local CMD="$2"
    local OUTPUT="$CMCACHE/$ACTIVITY-${CMDBASE%.sh}.output"
    debug 1 "cache_output: ACTIVITY=$ACTIVITY CMD=$CMD OUTPUT=$OUTPUT"

    mkdir -p "$CMCACHE"

    if [[ -n $NOCACHE || -n $VERBOSE ]] ; then
        "$CMD"
        rm -f "$OUTPUT"
    elif [[ -s $OUTPUT ]] ; then
        cat "$OUTPUT"
    else
        "$CMD" 2>&1 | tee "$OUTPUT"
    fi
}


UPGRADE="https://cm.converseincode.com/cr"

get_file() {
    return
}
get_activity_file() {
    return
}

CMPASSWORD=""
CURL_PASS=""
LFCM=""
VMURL=""
WGET_PASS=""

declare -A CARDREADER DISTRO_DEFAULT EMBEDDED FOLLOWON INCLUDES INPERSON INSTR_LED_CLASS MOOC NATIVELINUX OS OS_NEEDS PREREQ SELFPACED SELFPACED_CLASS VIRTUAL VMOKAY WEBPAGE

# shellcheck disable=SC2034
CARDREADER=
# shellcheck disable=SC2034
DISTRO_DEFAULT=
EMBEDDED=
FOLLOWON=
# shellcheck disable=SC2034
INCLUDES=
INPERSON=
INSTR_LED_CLASS=
# shellcheck disable=SC2034
NATIVELINUX=
MOOC=
# shellcheck disable=SC2034
OS=Linux
# shellcheck disable=SC2034
OS_NEEDS=
PREREQ=
SELFPACED=
SELFPACED_CLASS=
VIRTUAL=
# shellcheck disable=SC2034
VMOKAY=
WEBPAGE=

WGET_VERSION=$(wget --version | awk '{print $3; exit}')
WGET_PROGRESS="--quiet --progress=bar"
WGET_TIMEOUT="--timeout=10"

if version_greater_equal "$WGET_VERSION" 1.17 ; then
    WGET_PROGRESS="$WGET_PROGRESS --show-progress"
fi

CURL_TIMEOUT="--location --connect-timeout 10"

#===============================================================================
# Download file (try wget, then curl, then perl)
get() {
    local URL=$1 WGET_OPTS=${2:-} CURL_OPTS=${3:-}
    if [[ -n $NONETWORK ]] ; then
        warn "get: Can't access $URL because no-network selected."
        return 1
    elif [[ -z $USECURL ]] && which wget >/dev/null ; then
        debug 2 "  get: wget --quiet --no-cache --no-check-certificate $WGET_TIMEOUT $WGET_OPTS $URL"
        # shellcheck disable=SC2086
        $DRYRUN wget --quiet --no-cache $WGET_TIMEOUT $WGET_OPTS "$URL" -O- 2>/dev/null || return 1
    elif which curl >/dev/null ; then
        debug 2 "  get: curl $CURL_TIMEOUT $CURL_OPTS $URL"
        # shellcheck disable=SC2086
        $DRYRUN curl $CURL_TIMEOUT $CURL_OPTS "$URL" 2>/dev/null || return 1
    elif which perl >/dev/null ; then
        debug 2 "  perl LWP::Simple $URL"
        $DRYRUN perl -MLWP::Simple -e "getprint '$URL'" 2>/dev/null || return 1
    else
        warn "No download tool found."
        return 1
    fi
    return 0
}


WGET_CM_OPTS="$WGET_PASS --no-check-certificate $WGET_TIMEOUT"
CURL_CM_OPTS="$CURL_PASS $CURL_TIMEOUT"

#===============================================================================
# Get File from web site
get_file() {
    local ACTIVITY=${1%/}
    local FILE=${2:-}
    local TODIR=${3:-}
    local PARTIAL=${4:-}
    debug 1 "get_file ACTIVITY=$ACTIVITY FILE=$FILE TODIR=$TODIR PARTIAL=$PARTIAL"

    local URL="$LFCM/$ACTIVITY${FILE:+/$FILE}"

    [[ -z $TODIR ]] || pushd "$TODIR" >/dev/null
    if [[ -n $NONETWORK ]] ; then
        warn "get_file: Can't access $FILE because no-network selected."
        return 1
    elif [[ -z $USECURL ]] && which wget >/dev/null ; then
        local OPTS=''
        if [[ -n $FILE ]] ; then
            OPTS="--continue $WGET_PROGRESS"
        else
            OPTS="--quiet -O -"
        fi
        debug 2 "  get_file: wget $WGET_CM_OPTS $OPTS $URL"
        # shellcheck disable=SC2086
        $DRYRUN wget $WGET_CM_OPTS $OPTS "$URL" || true
    elif which curl >/dev/null ; then
        local OPTS='-s'
        [[ -z $FILE ]] || OPTS="-# -O"
        if [[ $PARTIAL = y ]] ; then
            rm -f "$FILE"
        elif [[ -z $PARTIAL && -f $FILE ]] ; then
            notice "Verifying $FILE... (for curl)"
            tar tf "$FILE" >/dev/null 2>&1 || rm -f "$FILE"
        fi
        debug 2 "  get_file: curl $CURL_CM_OPTS $OPTS $URL"
        # shellcheck disable=SC2086
        [[ -f $FILE ]] || $DRYRUN curl $CURL_CM_OPTS $OPTS "$URL"
    else
        warn "No download tool found."
        return 1
    fi
    [[ -z $TODIR ]] || popd >/dev/null
    return 0
}

#===============================================================================
# Try to get file
try_file() {
    local ACTIVITY=${1%/}
    local FILE=$2
    local TODIR=$3
    debug 1 "try_file ACTIVITY=$ACTIVITY FILE=$FILE TODIR=$TODIR"

    local URL SIZE
    URL=$LFCM/$ACTIVITY${FILE:+/$FILE}
    debug 2 "  try_file: wget $URL"
    SIZE=$(wget "$URL" || true 2>&1 | awk '/Length:/ {print $2}')

    local LOCALFILE="$TODIR/$FILE"
    debug 2 "  try_file: LOCALFILE=$LOCALFILE"
    if [[ -f $LOCALFILE && $(stat --format="%s" "$LOCALFILE") -eq $SIZE ]] ; then
        debug 1 "Already downloaded $LOCALFILE"
        return 1
    fi
    return 0
}

#===============================================================================
# Get meta variable (cache lookups)
get_var(){
    local KEY=$1
    local ACTIVITY=${2# }
    debug 1 "get_var: KEY=$KEY ACTIVITY=$ACTIVITY"

    mkdir -p "$CMCACHE"
    local CONF="${CMDBASE%.sh}.conf"
    local FILE="$CMCACHE/$ACTIVITY-$CONF"
    debug 2 "  get_var: CONF=$CONF FILE=$FILE"
    if [[ ! -e $FILE ]] ; then
        (get_file "$ACTIVITY/.$CONF"; get_file ".$ACTIVITY-$CONF") >"$FILE"
    fi
    awk -F= '/'"$KEY"'=/ {print $2}' "$FILE" | sed -e 's/^"\(.*\)"$/\1/'
}

#===============================================================================
# Get Version
get_file_version() {
    local FILE=$1
    sed -re 's/^.*(V[0-9.]+).*$/\1/' <<<"$FILE"
}

#===============================================================================
# Get Extras
get_activity_file() {
    local ACTIVITY=$1
    local KIND=${2:-SOLUTIONS}
    debug 1 "get_activity_file: ACTIVITY=$ACTIVITY KIND=$KIND"
    local FILE VER

    if [[ -n $NONETWORK ]] ; then
        warn "get_activity_file: Can't get activity files because no-network selected."
        return 0
    fi

    # Find newest SOLUTIONS file
    # shellcheck disable=SC2086
    FILE=$(get_file "$ACTIVITY" \
        | awk -F\" '/'$KIND'/ {print $8}' \
        | sed -Ee 's/^(.*V)([0-9.]+)(_.*)$/\2.0.0 \1\2\3/' \
        | sort -t. -n -k1,1 -k2,2 -k3,3 \
        | awk 'END {print $2}')
    # shellcheck disable=SC2086
    if [[ -z $FILE ]] ; then
        FILE=$(get_file "$ACTIVITY" \
        | awk -F\" '/'$KIND'/ {print $8}' \
        | sort | tail -1)
    fi

    if [[ -n $FILE ]] ; then
        VER=$(get_file_version "$FILE")
        debug 2 "   get_activity_file: ACTIVITY=$ACTIVITY FILE=$FILE VER=$VER"
        echo "$FILE" "$VER"
    else
        debug 2 "   get_activity_file: No files found for $ACTIVITY"
    fi
}


#===============================================================================
# Indicates whether Internet connectivity has been found
INTERNET_AVAILABLE=

#===============================================================================
# Check for updates
# As a side effect of finding the version will determine if INTERNET_AVAILABLE
check_version() {
    verbose "Checking for updated script"
    [[ -z $DONTUPDATE ]] || return 0

    if [[ -n $NONETWORK ]] ; then
        warn "check_version: Can't check version because no-network selected."
        return 0
    fi

    local URL="$UPGRADE"
    local CMD="$CMDBASE"
    local META="${CMD/.sh/}.meta"
    local NEW="${TMPDIR:-/tmp}/${CMD/.sh/.$$}"

    #---------------------------------------------------------------------------
    # Beta update
    if [[ $UPDATE =~ ...* || $VERIFY =~ ...* ]] ; then
        if [[ $UPDATE =~ ...* ]] ; then
            URL+="/$UPDATE"
        elif [[ $VERIFY =~ ...* ]] ; then
            URL+="/$VERIFY"
        fi
        FORCEUPDATE=y
    fi

    #---------------------------------------------------------------------------
    # Get metadata
    local VER MD5 OTHER
    # shellcheck disable=SC2046,SC2086
    read -r VER MD5 OTHER <<< "$(get $URL/$META?$(date +%s))"

    #---------------------------------------------------------------------------
    # Verify metadata
    if [[ -n $VERIFY ]] ; then
        if [[ -n $MD5 ]] ; then
            if md5cmp "$CMDNAME" "$MD5" ; then
                pass "md5sum matches"
            elif md5cmp "$CMDNAME" "$OTHER" ; then
                MD5="$OTHER"
                pass "md5sum matches"
            else
                fail "md5sum failed (you might want to run a --force-update to re-download)"
            fi
#        elif [[ -z $VER ]] ; then
#            return 0
        else
            warn "md5sum can't be checked, none found"
        fi
        exit 0
    fi

    #---------------------------------------------------------------------------
    # Get update for script
    INTERNET_AVAILABLE=y
    debug 1 "  check_version: ver:$VERSION VER:$VER MD5:$MD5"
    [[ -z $FORCEUPDATE ]] || UPDATE=y
    if [[ -n $FORCEUPDATE ]] || ( ! md5cmp "$CMDNAME" "$MD5" && ! version_greater_equal "$VERSION" "$VER" ) ; then
        if [[ -n $UPDATE ]] ; then
            if get "$URL/$CMD" >"$NEW" ; then
                mv "$NEW" "$CMDNAME"
                chmod 755 "$CMDNAME"
                if [[ $UPDATE =~ ...* ]] ; then
                    warn "Now running $UPDATE version of this script"
                else
                    notice "A new version of this script was found. Upgrading..."
                    # shellcheck disable=SC2086
                    [[ -z $COURSE ]] || DONTUPDATE=1 eval bash "$CMDNAME" $CMDOPTS
                fi
            else
                rm -f "$NEW"
                warn "No script found"
            fi
        else
            notice "A new version of this script was found. (use \"$CMDNAME --update\" to download)"
        fi
    else
        verbose "No update found"
    fi
    [[ -z $UPDATE ]] || exit 0
}
check_version

#===============================================================================
# Make associative arrays
declare -A DEBREL DISTRO_ALIASES DISTRO_NAMES FALLBACK PACKAGES

#===============================================================================
# Create empty Package lists for all distros
#===============================================================================
PACKAGES[Arch]=
#-------------------------------------------------------------------------------
PACKAGES[CentOS]=
PACKAGES[CentOS-6]=
PACKAGES[CentOS-7]=
#-------------------------------------------------------------------------------
PACKAGES[Debian]=
PACKAGES[Debian-7]=
PACKAGES[Debian-8]=
PACKAGES[Debian-9]=
PACKAGES[Debian-10]=
PACKAGES[Debian-999]=
#-------------------------------------------------------------------------------
PACKAGES[Fedora]=
PACKAGES[Fedora-27]=
PACKAGES[Fedora-28]=
PACKAGES[Fedora-999]=
#-------------------------------------------------------------------------------
PACKAGES[LinuxMint]=
PACKAGES[LinuxMint-17]=
PACKAGES[LinuxMint-17.1]=
PACKAGES[LinuxMint-17.2]=
PACKAGES[LinuxMint-17.3]=
PACKAGES[LinuxMint-18]=
PACKAGES[LinuxMint-18.1]=
#-------------------------------------------------------------------------------
PACKAGES[openSUSE]=
PACKAGES[openSUSE-42.2]=
PACKAGES[openSUSE-42.3]=
PACKAGES[openSUSE-15]=
PACKAGES[openSUSE-999]=
#-------------------------------------------------------------------------------
PACKAGES[RHEL]=
PACKAGES[RHEL-6]=
PACKAGES[RHEL-7]=
#-------------------------------------------------------------------------------
PACKAGES[Ubuntu]=
PACKAGES[Ubuntu-14.04]=
PACKAGES[Ubuntu-16.04]=
PACKAGES[Ubuntu-18.04]=
PACKAGES[Ubuntu-18.10]=
#-------------------------------------------------------------------------------
PACKAGES[SLES]=
PACKAGES[SLES-12.2]=
PACKAGES[SLES-15]=

#===============================================================================
# If we can't find settings/packages for a distro fallback to the next one
FALLBACK=(
    [amzn]="CentOS-7"
    [amzn-2.0]="CentOS-7"
    [CentOS]="RHEL"
    [CentOS-6]="RHEL-6"
    [CentOS-7]="RHEL-7"
    [Debian]="Ubuntu"
    [Debian-8]="Debian-7 Ubuntu-14.04"
    [Debian-9]="Debian-8 Ubuntu-16.04"
    [Debian-10]="Debian-9 Ubuntu-18.04"
    [Debian-999]="Debian-10 Ubuntu-18.10 Ubuntu-18.04"
    [Fedora]="RHEL CentOS"
    [Fedora-27]="Fedora"
    [Fedora-28]="Fedora-27"
    [Fedora-29]="Fedora-29"
    [Fedora-999]="Fedora-28 Fedora-27"
    [LinuxMint]="Ubuntu"
    [LinuxMint-17]="Ubuntu-14.04 Debian-7"
    [LinuxMint-17.1]="LinuxMint-17 Ubuntu-14.04 Debian-7"
    [LinuxMint-17.2]="LinuxMint-17.1 LinuxMint-17 Ubuntu-14.04 Debian-7"
    [LinuxMint-17.3]="LinuxMint-17.2 LinuxMint-17.1 LinuxMint-17 Ubuntu-14.04 Debian-7"
    [LinuxMint-18]="Ubuntu-16.04 Debian-9"
    [LinuxMint-18.1]="LinuxMint-18 Ubuntu-16.04 Debian-9"
    [Mint]="LinuxMint Ubuntu"
    [RHEL]="CentOS"
    [RHEL-6]="CentOS-6"
    [RHEL-7]="CentOS-7"
    [openSUSE-42.2]="openSUSE"
    [openSUSE-42.3]="openSUSE-42.2"
    [openSUSE-15]="openSUSE-42.3"
    [openSUSE-999]="openSUSE-15"
    [SLES]="openSUSE"
    [SLES-12.2]="openSUSE-42.2"
    [SLES-15]="openSUSE-15"
    [SUSE]="openSUSE"
    [Ubuntu]="Debian"
    [Ubuntu-14.04]="Debian-8"
    [Ubuntu-16.04]="Debian-9 Ubuntu-14.04"
    [Ubuntu-18.04]="Debian-10 Ubuntu-16.04"
    [Ubuntu-18.10]="Debian-10 Ubuntu-18.04"
    [Kubuntu]="Ubuntu Debian"
    [XUbuntu]="Ubuntu Debian"
)

#===============================================================================
# Distro release aliases
DISTRO_ALIASES=(
    [Debian-sid]="Debian-999"
    [Fedora-Rawhide]="Fedora-999"
    [openSUSE-Tumbleweed]="openSUSE-999"
    [Ubuntu-LTS]="Ubuntu-14.04 Ubuntu-16.04 Ubuntu-18.04"
    [Ubuntu-14.04+LTS]="Ubuntu-14.04 Ubuntu-16.04 Ubuntu-18.04"
    [Ubuntu-14.04+LTS+]="Ubuntu-14.04 Ubuntu-16.04 Ubuntu-18.04+"
    [Ubuntu-16.04+LTS]="Ubuntu-16.04 Ubuntu-18.04"
    [Ubuntu-16.04+LTS+]="Ubuntu-16.04 Ubuntu-18.04+"
    [Ubuntu-18.04+LTS]="Ubuntu-18.04"
    [Ubuntu-18.04+LTS+]="Ubuntu-18.04+"
)

#===============================================================================
# Distro release code names
DISTRO_NAMES=(
    [Debian-999]="Debian-sid"
    [Fedora-999]="Fedora-Rawhide"
    [openSUSE-999]="openSUSE-Tumbleweed"
)

#===============================================================================
# Distro release code names
DEBREL=(
    [hamm]=2
    [slink]=2.1
    [potato]=2.2
    [woody]=3
    [sarge]=3.1
    [etch]=4
    [lenny]=5
    [squeeze]=6
    [wheezy]=7
    [jessie]=8
    [stretch]=9
    [buster]=10
    [bullseye]=11
    [bookworm]=12
    [stable]=9
    [testing]=10
    [sid]=999
    [unstable]=999
)

#===============================================================================
declare -A ACTIVITY_ALIASES
ACTIVITY_ALIASES=(
    [doc]=YPDOC
    [Doc]=YPDOC
    [DOC]=YPDOc
    [gui]=YPGUI
    [Gui]=YPGUI
    [GUI]=YPGUI
    [OEST]=YPST
    [selftest]=YPST
    [Selftest]=YPST
    [SelfTest]=YPST
    [st]=YPST
    [ST]=YPST
    [Yoctoproject]=YP
    [YoctoProject]=YP
    [YÖP]=YP
    [YPDoc]=YPDOC
    [YPGui]=YPGUI
    [yp]=YP
)

#===============================================================================
distrib_list() {
    for D in ${!PACKAGES[*]}; do
        echo "$D"
    done | sed -e 's/_.*$//' | grep -- - | sort -u
}
ALL_DISTS=$(distrib_list)
# shellcheck disable=SC2086
debug 1 "ALL_DISTS: "$ALL_DISTS

#===============================================================================
check_distros() {
    local DISTS
    DISTS=$(distrib_list)

    if [[ $DISTS != "$ALL_DISTS" ]] ; then
        # shellcheck disable=SC2086
        warn "ALL_DISTS: "$ALL_DISTS
        # shellcheck disable=SC2086
        warn "DISTS_NOW: "$DISTS
        error "More distros were added in package lists in error"
    fi
}


declare -A ARCH CONFIGS BOGOMIPS BOOT COPYPACKAGES CPUFLAGS CPUS DISK DISTROS \
    DISTRO_ARCH DISTRO_BL INTERNET PREFER_CPUS PREREQ RAM RECOMMENDS RUNCODE \
    SUGGESTS TITLE

#===============================================================================
# Common strings
#DISCOURAGED="Highly Discouraged"
#PROVIDED="Required (one will be Provided)"
RECOMMENDED="Highly Recommended"
#REQUIRED="Required"

#===============================================================================
# Default Requirements for all activities
#===============================================================================
#VMOKAY="$DISCOURAGED"
ARCH=x86_64
BOGOMIPS=20000
BOOT=
CONFIGS=
COPYPACKAGES=
CPUFLAGS=
CPUS=4
DISK=100
DISTROS="CentOS-7+ Debian-8+ Fedora-27+ LinuxMint-18+ openSUSE-42.3+ RHEL-7+ Ubuntu-16.04+LTS+ SLES-12+ Arch"
DISTROS[EMBEDDED]=""
DISTROS[LFD]=""
DISTROS[LFS]=""
DISTRO_ARCH=x86_64
DISTRO_BL="CentOS-6 Debian-7 Fedora-25 RHEL-6 LinuxMint-16 Ubuntu-12.04 Ubuntu-12.10 Ubuntu-13.04 Ubuntu-13.10 Ubuntu-14.10 Ubuntu-15.04 Ubuntu-15.10 Ubuntu-16.10 Ubuntu-17.04"
INTERNET="$RECOMMENDED"
PACKAGES=
PREFER_CPUS=8
RAM=4
RECOMMENDS=
RUNCODE=
SUGGESTS=

#===============================================================================
# Build packages
#===============================================================================
PACKAGES[@build]="make patch"
RECOMMENDS[@build]="ccache texinfo"
#-------------------------------------------------------------------------------
PACKAGES[Arch_@build]="gcc"
#-------------------------------------------------------------------------------
PACKAGES[openSUSE_@build]="[RHEL_@build] makeinfo -texinfo"
#-------------------------------------------------------------------------------
PACKAGES[RHEL_@build]="gcc gcc-c++ glibc-devel"
#-------------------------------------------------------------------------------
PACKAGES[Ubuntu_@build]="build-essential"

#===============================================================================
# Common packages used in various activities
#===============================================================================
PACKAGES[@common]="bash bzip2 file gawk git gzip rsync sed tar unzip wget"
#-------------------------------------------------------------------------------
PACKAGES[Ubuntu_@common]="iputils-ping xz-utils"
#-------------------------------------------------------------------------------
PACKAGES[RHEL-7_@common]="which xz"
PACKAGES[Fedora_@common]="[RHEL-7_@common]"
#-------------------------------------------------------------------------------
PACKAGES[openSUSE_@common]="which xz"

#===============================================================================
# Java packages
#===============================================================================
PACKAGES[@java]=""
PACKAGES[Debian_@java]="default-jdk"
PACKAGES[Ubuntu-14.04_@java]="openjdk-7-jdk"
PACKAGES[Ubuntu-16.04_@java]="openjdk-8-jdk"
PACKAGES[RHEL_@java]="java-1.8.0-openjdk"
PACKAGES[Fedora-28_@java]="java-9-openjdk"
PACKAGES[Fedora-999_@java]="[RHEL_@java] java-openjdk"
PACKAGES[openSUSE_@java]="java-1_8_0-openjdk"
PACKAGES[openSUSE-999_@java]="java-1_8_0-openjdk java-9-openjdk"

#===============================================================================
# SDN packages
#===============================================================================
PACKAGES[@sdn]="@java wireshark"
PACKAGES[Ubuntu_@sdn]="mininet openvswitch-common openvswitch-testcontroller"
PACKAGES[Ubuntu-14.04_@sdn]="-openvswitch-testcontroller"
PACKAGES[Debian-7_@sdn]="-mininet -openvswitch-testcontroller"
PACKAGES[Debian-10_@sdn]="[Ubuntu_@sdn] -openvswitch-test"
PACKAGES[LinuxMint_@sdn]="-"
PACKAGES[Fedora_@sdn]="openvswitch"
PACKAGES[CentOS-7_@sdn]="[Fedora_@sdn]"
PACKAGES[OpenSUSE_@sdn]="mininet openvswitch"

#===============================================================================
# Virt related packages
#===============================================================================
PACKAGES[@virt]="bridge-utils ebtables qemu-kvm virt-manager virt-viewer"
PACKAGES[Debian_@virt]="libosinfo-bin libvirt-daemon-system libvirt-clients \
	qemu-utils spice-client-gtk virtinst"
PACKAGES[Debian-7_@virt]="libvirt-bin"
PACKAGES[Debian-10_@virt]="-"
PACKAGES[Ubuntu_@virt]="[Debian_@virt] libvirt-bin"
PACKAGES[Ubuntu-14.04_@virt]="-libvirt-clients -libvirt-daemon-system"
PACKAGES[Ubuntu-16.04_@virt]="[Ubuntu-14.04_@virt]"
PACKAGES[Ubuntu-18.10_@virt]="-libvirt-bin"
PACKAGES[LinuxMint-17.3_@virt]="[Ubuntu-14.04_@virt]"
PACKAGES[RHEL_@virt]="libvirt libvirt-client spice-gtk-tools virt-install"
PACKAGES[RHEL-6_@virt]="-virt-install"
PACKAGES[RHEL-7_@virt]="-spice-gtk"
PACKAGES[openSUSE_@virt]="[RHEL_@virt] libvirt-daemon spice-gtk -spice-gtk-tools"


#===============================================================================
# Extra requirements for BuildRoot
#===============================================================================
TITLE[BR]="Requirements for BuildRoot"
#-------------------------------------------------------------------------------
CPUS[BR]=2
PREFER_CPUS[BR]=4
DISK[BR]=20
RAM[BR]=2
BOGOMIPS[BR]=5000
PACKAGES[BR]="@build @common bc cpio file perl python"
#-------------------------------------------------------------------------------
PACKAGES[Arch_BR]="ncurses aur:ncurses5-compat-libs"
PACKAGES[Fedora_BR]="[RHEL_BR] -python"
PACKAGES[RHEL_BR]="ncurses-devel"
PACKAGES[Ubuntu_BR]="libncurses5-dev"

#===============================================================================
# Extra requirements for C-ALE
#===============================================================================
TITLE[CALE]="Requirements for C-ALE"
#-------------------------------------------------------------------------------
RAM[CALE]=4
DISK[CALE]=20
INTERNET[CALE]="$RECOMMENDED"
CPUFLAGS[CALE]="svm|vmx"
#-------------------------------------------------------------------------------
PACKAGES[CALE]="@build @common @sdn @virt"

#===============================================================================
# Extra requirements for E-ALE
#===============================================================================
TITLE[EALE]="Requirements for E-ALE"
#-------------------------------------------------------------------------------
PACKAGES[EALE]="@build @common"

#===============================================================================
# Extra requirements for YoctoProject
#===============================================================================
TITLE[YP]="Requirements for Yocto Project"
#-------------------------------------------------------------------------------
PACKAGES[YP]="@build @common chrpath cpio diffstat diffutils findutils python socat"
#-------------------------------------------------------------------------------
PACKAGES[Arch_YP]="perl python-pip python-pexpect"
PACKAGES[Fedora_YP]="[RHEL_YP] [RHEL-7_YP] perl-bignum -python python3 python3-pexpect python3-pip"
PACKAGES[RHEL_YP]="cpp perl which"
PACKAGES[RHEL-7_YP]="perl-Data-Dumper perl-Text-ParseWords perl-Thread-Queue"
PACKAGES[openSUSE_YP]="python3 python3-curses python3-pexpect python3-pip python-curses python-xml which"
PACKAGES[Ubuntu_YP]="debianutils gcc-multilib libglib2.0-dev libxml2-utils
        python3 python3-pexpect python3-pip"
PACKAGES[Debian-7_YP]="-python3-pexpect"

#===============================================================================
# Extra requirements for YoctoProject Graphical 
#===============================================================================
TITLE[YPGUI]="Requirements for Yocto Project GUI"
#-------------------------------------------------------------------------------
PACKAGES[YPGUI]="xterm"
#-------------------------------------------------------------------------------
PACKAGES[Arch_YPGUI]="jre8-openjdk libnfs nfs-utils"
PACKAGES[Ubuntu_YPGUI]="libsdl2-dev"
RECOMMENDS[Ubuntu_YPGUI]="default-jre"
PACKAGES[Ubuntu-14.04_YPGUI]="libnfs1 libsdl1.2-dev"
PACKAGES[Ubuntu-16.04_YPGUI]="libnfs8"
PACKAGES[Ubuntu-18.04_YPGUI]="libnfs11"
PACKAGES[Debian-8_YPGUI]="libnfs4"
PACKAGES[Debian-9_YPGUI]="[Ubuntu-16.04_YPGUI]"
PACKAGES[Debian-10_YPGUI]="libnfs11"
PACKAGES[RHEL_YPGUI]="SDL-devel"
PACKAGES[openSUSE_YPGUI]="libSDL-devel"
PACKAGES[openSUSE-42.2_YPGUI]="libnfs8"
PACKAGES[openSUSE-999_YPGUI]="libnfs11"

#===============================================================================
# Extra requirements for YP Documentation
#===============================================================================
TITLE[YPDOC]="Requirements for Yocto Project Documentation"
#-------------------------------------------------------------------------------
PACKAGES[YPDOC]="dblatex docbook-utils fop make xmlto"
#-------------------------------------------------------------------------------
PACKAGES[Ubuntu_YPDOC]="xsltproc"
PACKAGES[RHEL_YPDOC]="docbook-dtds docbook-style-dsssl docbook-style-xsl docbook-utils libxslt"
PACKAGES[CentOS-6_YPDOC]="-dblatex"
PACKAGES[openSUSE_YPDOC]="-fop"

#===============================================================================
# Extra requirements for YP Selt-Test
#===============================================================================
TITLE[YPST]="Requirements for OpenEmbedded Self-Test"
#-------------------------------------------------------------------------------
PACKAGES[Arch_YPST]="python-gitpython"
PACKAGES[Fedora_YPST]="python3-GitPython"
PACKAGES[openSUSE_YPST]="python-GitPython"
PACKAGES[RHEL_YPST]="GitPython"
PACKAGES[Ubuntu_YPST]="python-git"
PACKAGES[Ubuntu-16.04_YPST]="python3-git"

#==============================================================================
list_grep() {
    local REGEX
    REGEX=$(sed -e 's/\+/\\+/g' <<<"$1"); shift
    # shellcheck disable=SC2086
    debug 3 "list_grep REGEX=$REGEX => "$*
    sed 's/ /\n/g' <<< "$@" | grep -E "$REGEX" | sort -u
}

#===============================================================================
list_sort() {
    sed 's/ /\n/g' <<< "$@" | sort -u
}

#===============================================================================
value() {
    local VAR=$1
    local ACTIVITY=${2:-}
    local LIST
    # shellcheck disable=SC2016
    LIST='${'$VAR'['$ACTIVITY']:-} ${'$VAR'['${ACTIVITY:0:3}']:-} ${'$VAR':-}'

    for V in $LIST; do
        V=$(eval echo "$V")
        if [[ -n $V ]] ; then
            echo "$V"
            return 0
        fi
    done
}

#===============================================================================
for_each_activity() {
    local CODE=$1; shift
    local ACTIVITIES ACTIVITY
    ACTIVITIES=$(list_sort "$@")
    # shellcheck disable=SC2086
    debug 1 "for_each_activity: CODE=$CODE ACTIVITIES="$ACTIVITIES
    for ACTIVITY in $ACTIVITIES ; do
        debug 2 "  for_each_activity: eval $CODE $ACTIVITY"
        eval "$CODE $ACTIVITY"
    done
}

#===============================================================================
supported_activity() {
    local ACTIVITY=$1
    [[ -n ${TITLE[$ACTIVITY]} ]] || warn "Unsupported activity: $ACTIVITY"
}


#===============================================================================
check_activity() {
    local ACTIVITY=$1
    local DESC=${TITLE[$ACTIVITY]}
    debug 1 "check_activity: ACTIVITY=$ACTIVITY"

    if [[ -z $DESC ]] ; then
        if DESC=$(get_var TITLE "$ACTIVITY") && [[ -n $DESC ]] ; then
            debug 2 "  check_activity: Custom $ACTIVITY"
        elif [[ -n ${ACTIVITY_ALIASES[$ACTIVITY]} ]] ; then
            debug 2 "  check_activity: Alias $ACTIVITY"
            ACTIVITY=${ACTIVITY_ALIASES[$ACTIVITY]}
            DESC=${TITLE[$ACTIVITY]}
        fi
        debug 2 "  check_activity: ACTIVITY=$ACTIVITY DESC=$DESC"
    fi

    if [[ -n $DESC ]] ; then
        highlight "Checking that this computer is suitable for $ACTIVITY: $DESC"
    else
        warn "Unknown \"$ACTIVITY\"; checking defaults requirements instead"
    fi
}

#===============================================================================
try_activity() {
    local ACTIVITY=$1 NEWACTIVITY=$2
    [[ -n ${TITLE[$NEWACTIVITY]} ]] || return 1
    if warn_wait "I think you meant $NEWACTIVITY (not $ACTIVITY)" ; then
        echo "$NEWACTIVITY"
    else
        echo "$ACTIVITY"
    fi
}

#===============================================================================
spellcheck_activity() {
    local ACTIVITY=$1
    local ACTIVITIES
    [[ -n $ACTIVITY ]] || return 0
    if [[ -n ${TITLE[$ACTIVITY]} ]] ; then
        echo "$ACTIVITY"
    elif ACTIVITIES=$(get_var COURSES "$ACTIVITY") && [[ -n $ACTIVITIES ]] ; then
        echo "$ACTIVITIES"
    else
        try_activity "$ACTIVITY" "${ACTIVITY/LFD/LFS}" \
            || try_activity "$ACTIVITY" "${ACTIVITY/LFS/LFD}" \
            || echo "$ACTIVITY"
    fi
}

#===============================================================================
find_activity() {
    local ACTIVITY=$1

    if [[ -n $ACTIVITY && -n ${ACTIVITY_ALIASES[$ACTIVITY]:-} ]] ; then
        notice "$ACTIVITY is an alias for ${ACTIVITY_ALIASES[$ACTIVITY]}"
        ACTIVITY=${ACTIVITY_ALIASES[$ACTIVITY]}
    fi
    spellcheck_activity "$ACTIVITY"
}

#===============================================================================
# List available activities
list_activities() {
    echo "Available (${#TITLE[@]}) options:"
    for D in ${!TITLE[*]}; do
        echo "  $D - ${TITLE[$D]}"
    done | sort
    exit 0
}
[[ -z $LIST_ACTIVITIES ]] || list_activities

#===============================================================================
# Try package list for all activities
try_all_activities() {
    local A
    # shellcheck disable=SC2086
    for A in $(list_sort ${!TITLE[*]}); do
        divider "$A"
        NO_PASS=y $CMDNAME \
                ${NOCM:+--no-course-files} \
                ${NOEXTRAS:+--no-extras} \
                ${NOINSTALL:+--no-install} \
                ${NORECOMMENDS:+--no-recommends} \
                ${NOSUGGESTS:+--no-suggests} \
                ${NOVM:+--no-vm} \
                "$A"
    done
    exit 0
}
[[ -z $TRY_ALL_ACTIVITIES ]] || try_all_activities

#===============================================================================
# shellcheck disable=SC2086
debug 1 "before: ACTIVITIES="$COURSE
# shellcheck disable=SC2005,SC2046,SC2086
[[ -z $ALL_LFD ]] || COURSE=$(echo $(list_grep LFD ${!TITLE[*]}))
# shellcheck disable=SC2005,SC2046,SC2086
[[ -z $ALL_LFS ]] || COURSE=$(echo $(list_grep LFS ${!TITLE[*]}))
# shellcheck disable=SC2005,SC2046,SC2086
[[ -z $ALL_ACTIVITIES ]] || COURSE=$(echo $(list_sort ${!TITLE[*]}))
# shellcheck disable=SC2086
debug 1 "after: ACTIVITIES="$COURSE

#===============================================================================
ORIG_COURSE=$COURSE
# shellcheck disable=SC2046,SC2086
COURSE=$(list_sort $(for_each_activity find_activity $COURSE))
# shellcheck disable=SC2086
debug 1 "main: Initial classes="$COURSE


declare -A DISTS

#===============================================================================
list_distro_names() {
    local DISTS D
    DISTS=$(distrib_list)
    for D in $DISTS ; do
       if [[ -n ${DISTRO_NAMES[$D]:-} ]] ; then
           echo "${DISTRO_NAMES[$D]}"
       else
           echo "$D"
       fi
    done
}

#===============================================================================
# Make sure we're using a defined distribution key
distrib_ver() {
    local DID=$1 DREL=$2
    local AVAIL_INDEXES AVAIL_RELS DVER
    debug 1 "distrib_ver: DID=$DID DREL=$DREL"
    AVAIL_INDEXES=$(for D in "${!PACKAGES[@]}" "${!RECOMMENDS[@]}" "${!SUGGESTS[@]}"; do
        echo "$D"
    done | grep "$DID" | sort -u)
    # shellcheck disable=SC2086
    debug 2 "  distrib_ver: Available package indexes for $DID:" $AVAIL_INDEXES
    AVAIL_RELS=$(for R in $AVAIL_INDEXES; do
        local R=${R#*-}
        echo "${R%_*}"
    done | grep -v "^$DID" | sort -n -u)
    # shellcheck disable=SC2086
    debug 2 "  distrib_ver: Available distro releases for $DID:" $AVAIL_RELS
    DVER=1
    for R in $AVAIL_RELS ; do
        if version_greater_equal "$R" "$DREL" ; then
            DVER="$R"
            break
        fi
    done
    debug 1 "  distrib_ver: We're going to use $DID-$DVER (was $DID-$DREL)"
    echo "$DVER"
}

#===============================================================================
# Do a lookup in DB of KEY
lookup() {
    local DB=$1
    local KEY=${2%_}
    debug 1 "  lookup: DB=$DB KEY=$KEY"
    if [[ -n $KEY ]] ; then
        local DATA
        DATA=$(eval "echo \${$DB[$KEY]:-}")
        if [[ -n $DATA ]] ; then
            debug 2 "    lookup: hit $DB[$KEY] -> $DATA"
            echo "$DATA"
            return 0
        fi
    fi
    return 1
}

#===============================================================================
# Do a lookup in DB for DID[-DVER] and if not found, consult FALLBACK distros
lookup_fallback() {
    local DB=$1
    local DID=$2
    local DVER=$3
    local NAME=$4
    debug 2 "  lookup_fallback: DB=$DB DID=$DID DVER=$DVER NAME=$NAME"
    DID+=${DVER:+-$DVER}
    local KEY
    if [[ -n $DID && -n ${FALLBACK[${DID}]:-} ]] ; then
        debug 2 "    lookup_fallback: $DID => ${FALLBACK[${DID}]}"
        for KEY in $DID ${FALLBACK[${DID}]} ; do
            KEY+=${NAME:+_$NAME}
            if lookup "$DB" "$KEY" ; then
                return 0
            fi
        done
    fi
}

#===============================================================================
# Do a lookup in DB for NAME, DID_NAME, DID-DVER_NAME
get_db() {
    local DB=$1
    local DID=$2
    local DVER=$3
    local NAME=${4:-}
    local RESULT
    debug 1 "get_db: DB=$DB DID=$DID DVER=$DVER NAME=$NAME"

    # Example: Ubuntu-18.04 Ubuntu-18.04_LFD420 Ubuntu_LFD420
    RESULT="$(lookup "$DB" "$NAME")"
    RESULT+=" $(lookup "$DB" "${DID}_$NAME")"
    RESULT+=" $(lookup "$DB" "$DID-${DVER}_$NAME")"
    RESULT+=" $(lookup_fallback "$DB" "$DID" '' "$NAME")"
    RESULT+=" $(lookup_fallback "$DB" "$DID" "$DVER" "$NAME")"
    # shellcheck disable=SC2086
    debug 3 "  get_db: RESULT="$RESULT
    # shellcheck disable=SC2086
    echo $RESULT
}

#===============================================================================
# Recursively expand macros in package list
pkg_list_expand() {
    local DB=$1; shift
    local DID=$1; shift
    local DREL=$1; shift
    local KEY PKGS
    # shellcheck disable=SC2086
    debug 3 "  pkg_list_expand: DB=$DB DID=$DID DREL=$DREL PLIST="$*

    for KEY in "$@" ; do
        case $KEY in
            @*) PKGS=$(get_db "$DB" "$DID" "$DREL" "$KEY")
                # shellcheck disable=SC2086
                pkg_list_expand "$DB" "$DID" "$DREL" $PKGS ;;
            [*) PKGS=$(eval "echo \${$DB$KEY:-}") #]
                debug 3 "    pkg_list_expand: lookup macro $DB$KEY -> $PKGS"
                [[ $KEY != "$PKGS" ]] || error "Recursive package list: $KEY"
                # shellcheck disable=SC2086
                pkg_list_expand "$DB" "$DID" "$DREL" $PKGS ;;
            *) echo "$KEY" ;;
        esac
    done
}

#===============================================================================
# Handle removing packages from the list: foo -foo
pkg_list_contract() {
    local BEFORE AFTER
    BEFORE=$(list_sort "$@")
    AFTER=$BEFORE
    # shellcheck disable=SC2086
    debug 3 "  pkg_list_contract BEFORE="$BEFORE
    for PKG in $BEFORE; do
        if [[ $PKG == -* ]] ; then
            AFTER=$(for P in $AFTER; do
                echo "$P"
            done | grep -E -v "^-?${PKG#-}$")
        fi
    done
    # shellcheck disable=SC2086
    debug 3 "  pkg_list_contract: AFTER="$AFTER
    # shellcheck disable=SC2086
    list_sort $AFTER
}

#===============================================================================
# Check package list for obvious problems
pkg_list_check() {
    for PKG in "${!PACKAGES[@]}" "${!RECOMMENDS[@]}" "${!SUGGESTS[@]}"; do
        # shellcheck disable=SC2188
        case "$PKG" in
            @*|*_@*) >/dev/null;;
            *@*) fail "'$PKG' is likely invalid. I think you meant '${PKG/@/_@}'";;
            *-LF*) fail "'$PKG' is likely invalid. I think you meant '${PKG/-LF/_LF}'";;
            LF*_*) fail "'$PKG' is likely invalid. I think you meant '$(sed -re 's/(LF....)_([^_]+)/\2_\1/')'";;
            *) >/dev/null;;
        esac
    done
}

#===============================================================================
# Add packages to the list
pkg_list_lookup() {
    local TYPE=$1
    local DID=$2
    local DVER=$3
    local NAME=$4
    local LIST

    LIST=$(get_db "$TYPE" "$DID" "$DVER" "$NAME")
    # shellcheck disable=SC2086
    debug 2 "  pkg_list_lookup: $TYPE DID=$DID DVER=$DVER NAME=$NAME LIST="$LIST
    echo "$LIST"
}

#===============================================================================
# Build package list
# TODO: Needs to be tested more with other distros
package_list() {
    local DID=$1
    local DREL=$2
    local ACTIVITY=$3
    local DVER LIST PLIST RLIST='' SLIST=''
    debug 1 "package_list: DID=$DID DREL=$DREL ACTIVITY=$ACTIVITY"

    DVER=$(distrib_ver "$DID" "$DREL")

    pkg_list_check

    if [[ -n ${COPYPACKAGES[$ACTIVITY]:-} ]] ; then
        debug 1 "  package_list: COPYPACKAGES $ACTIVITY -> ${COPYPACKAGES[$ACTIVITY]}"
        ACTIVITY=${COPYPACKAGES[$ACTIVITY]}
    fi

    #---------------------------------------------------------------------------
    # Build initial lists
    PLIST=$(pkg_list_lookup PACKAGES "$DID" "$DVER" "$ACTIVITY")
    # shellcheck disable=SC2086
    debug 2 "  package_list:(initial) PACKAGES PLIST="$PLIST
    if [[ -z $NORECOMMENDS ]] ; then
        # shellcheck disable=SC2046,SC2086
        RLIST=$(list_sort $(pkg_list_lookup RECOMMENDS "$DID" "$DVER" "$ACTIVITY") $PLIST)
        # shellcheck disable=SC2086
        debug 2 "  package_list:(initial) RECOMMENDS RLIST="$RLIST
    fi
    if [[ -z $NOSUGGESTS ]] ; then
        # shellcheck disable=SC2046,SC2086
        SLIST=$(list_sort $(pkg_list_lookup SUGGESTS "$DID" "$DVER" "$ACTIVITY") $PLIST $RLIST)
        # shellcheck disable=SC2086
        debug 2 "  package_list:(initial) SUGGESTS SLIST="$SLIST
    fi

    #---------------------------------------------------------------------------
    # Expand lists
    # shellcheck disable=SC2046,SC2086
    PLIST=$(pkg_list_expand PACKAGES "$DID" "$DVER" $PLIST)
    # shellcheck disable=SC2086
    debug 1 "  package_list:(expanded) PACKAGES PLIST="$PLIST
    if [[ -z $NORECOMMENDS ]] ; then
        # shellcheck disable=SC2046,SC2086
        RLIST=$(pkg_list_expand RECOMMENDS "$DID" "$DVER" $RLIST)
        # shellcheck disable=SC2086
        debug 1 "  package_list:(expanded) RECOMMENDS RLIST="$RLIST
    fi
    if [[ -z $NOSUGGESTS ]] ; then
        # shellcheck disable=SC2046,SC2086
        SLIST=$(pkg_list_expand SUGGESTS "$DID" "$DVER" $SLIST)
        # shellcheck disable=SC2086
        debug 1 "  package_list:(expanded) SUGGESTS SLIST="$SLIST
    fi

    #---------------------------------------------------------------------------
    # Contract list
    # shellcheck disable=SC2086
    LIST=$(pkg_list_contract ${PLIST:-} ${RLIST:-} ${SLIST:-})
    # shellcheck disable=SC2086
    debug 1 "  package_list: Final packages for $DID-${DVER}_$ACTIVITY:" $LIST
    echo "$LIST"
}

CKCACHE="$CMCACHE"

#===============================================================================
# Check Packages
check_packages() {
    local ACTIVITIES="$*"
    local DISTS D DIST P
    local SEARCH="./scripts/pkgsearch"
    if [[ ! -x $SEARCH ]] ; then
        error "$SEARCH not found"
    fi
    # shellcheck disable=SC2086
    [[ -n $ACTIVITIES ]] || ACTIVITIES=$(list_sort ${!TITLE[*]})
    # shellcheck disable=SC2086
    debug 1 "check_packages: ACTIVITIES="$ACTIVITIES

    mkdir -p "$CKCACHE"
    [[ -z $NOCACHE ]] || $SEARCH --dropcache

    if [[ -z $DIST_LIST ]] ; then
        DISTS=$(distrib_list)
    else
        DISTS=$DIST_LIST
    fi
    # shellcheck disable=SC2086
    debug 1 "  check_packages: DISTS="$DISTS
    local A
    for A in $ACTIVITIES; do
        local CHECKED="$CKCACHE/$A-checked" CP=""
        if [[ -z $NOCACHE && -e $CHECKED ]] ; then
            verbose "Already checked $A"
            [[ -n $VERBOSE ]] || cat "$CHECKED"
            continue
        fi
        supported_activity "$A"

        CP="$A "
        [[ -n $VERBOSE ]] || progress "$CP"
        for DIST in $DISTS; do
            CP="$CP."
            [[ -n $VERBOSE ]] || progress '.'
            # shellcheck disable=SC2086
            P=$(package_list ${DIST/-/ } $A)
            # shellcheck disable=SC2086
            debug 2 "    check_packages: P="$P
            local OPTS='' OUTPUT
            [[ -n $VERBOSE ]] || OPTS="--quiet --progress"
            # shellcheck disable=SC2086
            debug 2 "    check_packages: $SEARCH $OPTS -df $DIST "$P
            # shellcheck disable=SC2086
            OUTPUT=$($SEARCH $OPTS -df "$DIST" $P)
            if [[ -n $OUTPUT ]] ; then
                [[ -n $VERBOSE ]] || echo
                notice "Checking $DIST for $A..."
                echo "$OUTPUT"
                CHECKED=""
            fi
        done

        [[ -n $VERBOSE ]] || progress "\n"
        if [[ -n $CHECKED ]] ; then
            echo "$CP" > "$CHECKED"
        fi
    done
    [[ -n $VERBOSE ]] || echo
}

#===============================================================================
# List Packages
list_packages() {
    local ACTIVITIES=$1
    local DISTS D DIST PL P

    DISTS=$(distrib_list)
    # shellcheck disable=SC2086
    debug 1 "list_packages: ACTIVITIES=$ACTIVITIES PKGS=$PKGS DISTS="$DISTS

    if [[ -n $ACTIVITIES ]] ; then
        supported_activity "$ACTIVITIES"
    else
        # shellcheck disable=SC2086
        ACTIVITIES=$(list_sort ${!TITLE[*]})
    fi
    for D in $ACTIVITIES; do
        notice "Listing packages for $D..."
        for DIST in $DISTS; do
            # shellcheck disable=SC2086
            PL=$(package_list ${DIST/-/ } $D)
            # shellcheck disable=SC2086
            debug 2 PL1=$PL
            # shellcheck disable=SC2086
            [[ -z $PKGS ]] || PL=$(list_grep "^$PKGS$" $PL)
            # shellcheck disable=SC2086
            debug 2 PL2=$PL
            for P in $PL ; do
                echo -e "$DIST\t$P"
            done
        done
    done
}

#===============================================================================
# List All Packages
list_all_packages() {
    debug 1 "list_all_packages: List All Packages"

    local K
    # shellcheck disable=SC2086
    for K in $(list_sort ${!PACKAGES[*]}) ; do
        echo "PACKAGES[$K]=${PACKAGES[$K]}"
    done
    # shellcheck disable=SC2086
    for K in $(list_sort ${!RECOMMENDS[*]}) ; do
        echo "RECOMMENDS[$K]=${RECOMMENDS[$K]}"
    done
    # shellcheck disable=SC2086
    for K in $(list_sort ${!SUGGESTS[*]}) ; do
        echo "SUGGESTS[$K]=${SUGGESTS[$K]}"
    done
}

#===============================================================================
if [[ -n $ALL_PKGS ]] ; then
    list_all_packages
    exit 0
fi
if [[ -n $LIST_DISTROS ]] ; then
    list_distro_names
    exit 0
fi


#===============================================================================
get_md5sum() {
    local ACTIVITY=$1 FILE=${2:-}
    debug 1 "get_checksum: ACTIVITY=$ACTIVITY FILE=$FILE"

    local DIR CACHED MD5="md5sums.txt"
    DIR=$(dirname "${FILE}")
    if [[ $DIR = '.' ]] ; then unset DIR ; fi
    CACHED="$CMCACHE/$ACTIVITY-${DIR:+$DIR-}$MD5"

    if [[ ! -f "$CACHED" ]] ; then
        local URL="$ACTIVITY/${DIR:+$DIR/}$MD5"
        get_file "$URL" > "$CACHED"
    fi
    echo "$CACHED"
}

#===============================================================================
check_md5sum() {
    local ACTIVITY=$1 FILE=$2 TODIR=$3
    local DLOAD="$TODIR/$FILE"

    if [[ -f $DLOAD ]] ; then
        local CACHED
        CACHED=$(get_md5sum "$ACTIVITY" "$FILE")
        if [[ -f $CACHED ]] ; then
            local MD5
            MD5=$(awk "/  $FILE$/ {print \$1}" "$CACHED")
            if md5cmp "$DLOAD" "$MD5" ; then
                return 0
            fi
        fi
    fi
    return 1
}


#===============================================================================
# Determine Distro and release
guess_distro() {
    local DISTRO=${1:-}
    debug 1 "guess_distro: DISTRO=$DISTRO"
    local DISTRIB_SOURCE DISTRIB_ID DISTRIB_RELEASE DISTRIB_CODENAME DISTRIB_DESCRIPTION DISTRIB_ARCH
    #-------------------------------------------------------------------------------
    if [[ -f /etc/lsb-release ]] ; then
        DISTRIB_SOURCE+="/etc/lsb-release"
        source /etc/lsb-release
    fi
    #-------------------------------------------------------------------------------
    if [[ -z $DISTRIB_ID ]] ; then
        if [[ -f /usr/bin/lsb_release ]] ; then
            DISTRIB_SOURCE+=" lsb_release"
            DISTRIB_ID=$(lsb_release -is 2>/dev/null)
            DISTRIB_RELEASE=$(lsb_release -rs 2>/dev/null)
            DISTRIB_CODENAME=$(lsb_release -cs 2>/dev/null)
            DISTRIB_DESCRIPTION=$(lsb_release -ds 2>/dev/null)
        fi
    fi
    #-------------------------------------------------------------------------------
    if [[ -f /etc/os-release ]] ; then
        DISTRIB_SOURCE+=" /etc/os-release"
        . /etc/os-release
        DISTRIB_ID=${DISTRIB_ID:-${ID^}}
        DISTRIB_RELEASE=${DISTRIB_RELEASE:-$VERSION_ID}
        DISTRIB_DESCRIPTION=${DISTRIB_DESCRIPTION:-$PRETTY_NAME}
    fi
    #-------------------------------------------------------------------------------
    if [[ -f /etc/debian_version ]] ; then
        DISTRIB_SOURCE+=" /etc/debian_version"
        DISTRIB_ID=${DISTRIB_ID:-Debian}
        [[ -n $DISTRIB_CODENAME ]] || DISTRIB_CODENAME=$(sed 's|^.*/||' /etc/debian_version)
        [[ -n $DISTRIB_RELEASE ]] || DISTRIB_RELEASE=${DEBREL[$DISTRIB_CODENAME]:-$DISTRIB_CODENAME}
    #-------------------------------------------------------------------------------
    elif [[ -f /etc/SuSE-release ]] ; then
        DISTRIB_SOURCE+=" /etc/SuSE-release"
        [[ -n $DISTRIB_ID ]] || DISTRIB_ID=$(awk 'NR==1 {print $1}' /etc/SuSE-release)
        [[ -n $DISTRIB_RELEASE ]] || DISTRIB_RELEASE=$(awk '/^VERSION/ {print $3}' /etc/SuSE-release)
        [[ -n $DISTRIB_CODENAME && $DISTRIB_CODENAME != "n/a" ]] || DISTRIB_CODENAME=$(awk '/^CODENAME/ {print $3}' /etc/SuSE-release)
    #-------------------------------------------------------------------------------
    elif [[ -f /etc/redhat-release ]] ; then
        DISTRIB_SOURCE+=" /etc/redhat-release"
        if grep -E -q "^Red Hat Enterprise Linux" /etc/redhat-release ; then
            [[ -n $DISTRIB_RELEASE ]] || DISTRIB_RELEASE=$(awk '{print $7}' /etc/redhat-release)
        elif grep -E -q "^CentOS|Fedora" /etc/redhat-release ; then
            DISTRIB_ID=$(awk '{print $1}' /etc/redhat-release)
            [[ -n $DISTRIB_RELEASE ]] || DISTRIB_RELEASE=$(awk '{print $3}' /etc/redhat-release)
        fi
        DISTRIB_ID=${DISTRIB_ID:-RHEL}
        [[ -n $DISTRIB_CODENAME ]] || DISTRIB_CODENAME=$(sed 's/^.*(//; s/).*$//;' /etc/redhat-release)
    #-------------------------------------------------------------------------------
    elif [[ -e /etc/arch-release ]] ; then
        DISTRIB_SOURCE+=" /etc/arch-release"
        DISTRIB_ID=${DISTRIB_ID:-Arch}
        # Arch Linux doesn't have a "release"...
        # So instead we'll look at the modification date of pacman
        # shellcheck disable=SC2012
        [[ -n $DISTRIB_RELEASE ]] || DISTRIB_RELEASE=$(ls -l --time-style=+%Y.%m /bin/pacman | cut -d' ' -f6)
    #-------------------------------------------------------------------------------
    elif [[ -e /etc/gentoo-release ]] ; then
        DISTRIB_SOURCE+=" /etc/gentoo-release"
        DISTRIB_ID=${DISTRIB_ID:-Gentoo}
        [[ -n $DISTRIB_RELEASE ]] || DISTRIB_RELEASE=$(cut -d' ' -f5 /etc/gentoo-release)
    fi
    #-------------------------------------------------------------------------------
    if [[ -n $DISTRO ]] ; then
        debug 1 "  Overriding distro: $DISTRO"
        DISTRIB_SOURCE+=" override"
        DISTRIB_ID=${DISTRO%%-*}
        DISTRIB_RELEASE=${DISTRO##*-}
        DISTRIB_CODENAME=Override
        DISTRIB_DESCRIPTION="$DISTRO (Override)"
    fi
    #-------------------------------------------------------------------------------
    shopt -s nocasematch
    if [[ $DISTRIB_ID == Centos ]] ; then
        DISTRIB_ID=CentOS
    elif [[ $DISTRIB_ID =~ Debian ]] ; then
        DISTRIB_RELEASE=${DEBREL[$DISTRIB_RELEASE]:-$DISTRIB_RELEASE}
    elif [[ $DISTRIB_ID == RedHat* || $DISTRIB_ID == Rhel ]] ; then
        DISTRIB_ID=RHEL
    elif [[ $DISTRIB_ID =~ Sles || $DISTRIB_ID =~ SLE ]] ; then
        DISTRIB_ID=SLES
    elif [[ $DISTRIB_ID =~ Suse ]] ; then
        DISTRIB_ID=openSUSE
        version_greater_equal 20000000 "$DISTRIB_RELEASE" || DISTRIB_RELEASE=999
    elif [[ -z $DISTRIB_ID ]] ; then
        DISTRIB_ID=Unknown
    fi
    shopt -u nocasematch
    #-------------------------------------------------------------------------------
    DISTRIB_RELEASE=${DISTRIB_RELEASE:-0}
    #DISTRIB_CODENAME=${DISTRIB_CODENAME:-Unknown}
    [[ -n $DISTRIB_DESCRIPTION ]] || DISTRIB_DESCRIPTION="$DISTRIB_ID $DISTRIB_RELEASE"

    #===============================================================================
    # Determine Distro arch
    local DARCH
    if [[ -e /usr/bin/dpkg && $DISTRIB_ID =~ Debian|Kubuntu|LinuxMint|Mint|Ubuntu|Xubuntu ]] ; then
        DARCH=$(dpkg --print-architecture)
    elif [[ -e /bin/rpm || -e /usr/bin/rpm ]] && [[ $DISTRIB_ID =~ CentOS|Fedora|Rhel|RHEL|openSUSE|SLES ]] ; then
        DARCH=$(rpm --eval %_arch)
    elif [[ -e /usr/bin/file ]] ; then
        DARCH=$(/usr/bin/file /usr/bin/file | cut -d, -f2)
        DARCH=${DARCH## }
        DARCH=${DARCH/-64/_64}
    else
        DARCH=Unknown
    fi
    # Because Debian and derivatives use amd64 instead of x86_64...
    if [[ "$DARCH" == "amd64" ]] ; then
        DISTRIB_ARCH=x86_64
    else
        DISTRIB_ARCH=$(sed -re 's/IBM //' <<<$DARCH)
    fi

    #===============================================================================
    debug 1 "  DISTRIB_SOURCE=$DISTRIB_SOURCE"
    debug 1 "  DISTRIB_ID=$DISTRIB_ID"
    debug 1 "  DISTRIB_RELEASE=$DISTRIB_RELEASE"
    debug 1 "  DISTRIB_CODENAME=$DISTRIB_CODENAME"
    debug 1 "  DISTRIB_DESCRIPTION=$DISTRIB_DESCRIPTION"
    debug 1 "  DISTRIB_ARCH=$DISTRIB_ARCH"
    debug 1 "  DARCH=$DARCH"
    echo "$DISTRIB_ID,$DISTRIB_RELEASE,$DISTRIB_CODENAME,$DISTRIB_DESCRIPTION,$DISTRIB_ARCH,$DARCH"
}

#===============================================================================
which_distro() {
    local ID=$1 ARCH=$2 RELEASE=$3 CODENAME=$4
    debug 1 "which_distro: ID=$ID ARCH=$ARCH RELEASE=$RELEASE CODENAME=$CODENAME"
    echo "Linux Distro: $ID${ARCH:+:$ARCH}-$RELEASE ${CODENAME:+($CODENAME)}"
    exit 0
}

#===============================================================================
extract_arch () {
    local D=$1 DIST ARCH
    read -r DIST ARCH <<< "$(sed -re 's/^([a-zA-Z0-9]+):([a-zA-Z0-9]+)(-.*)$/\1\3 \2/' <<<"$D")"
    if [[ -n $ARCH ]] ; then
        debug 2 "extract_arch: $DIST $ARCH"
        echo "$DIST $ARCH"
    else
        echo "$D"
    fi
}

#===============================================================================
include_arch () {
    local D DIST=$1 ARCH=$2
    D=$(sed -re 's/([a-zA-Z0-9]+)(-[^ ]+)?/\1'"${ARCH:+:$ARCH}"'\2/g' <<<"$DIST")
    debug 2 "    include_arch: $DIST -> $D"
    echo "${D:-$DIST}"
}

#===============================================================================
# Expand distro aliases into the real (list) of distro names
fix_distro_alias() {
    local D
    for D in "$@" ; do
        local DIST ARCH ALIAS
        # shellcheck disable=SC2086
        read -r DIST ARCH <<<"$(extract_arch $D)"
        ALIAS="${DISTRO_ALIASES[${DIST}]:-}"
        if [[ -n $ALIAS ]] ; then
            debug 2 "  fix_distro_alias: $DIST -> $ALIAS"
            include_arch "$ALIAS" "$ARCH"
        else
            debug 2 "  fix_distro_alias: $D"
            echo "$D"
        fi
    done
}

#===============================================================================
# shellcheck disable=SC2086
IFS=, read -r ID RELEASE CODENAME DESCRIPTION ARCH DARCH <<<"$(guess_distro ${DISTRO:-})"
debug 1 "main: guess_distro split: ID=$ID RELEASE=$RELEASE CODENAME=$CODENAME DESCRIPTION=$DESCRIPTION ARCH=$ARCH DARCH=$DARCH"
[[ -z $WHICH_DISTRO ]] || which_distro "$ID" "$ARCH" "$RELEASE" "$CODENAME"

#===============================================================================
# Expand Distro lists via distro aliases
# shellcheck disable=SC2086
[[ -z ${DISTROS:-} ]] || DISTROS=$(fix_distro_alias $DISTROS)
# shellcheck disable=SC2086
[[ -z ${DISTROS[LFD]} ]] || DISTROS[LFD]=$(fix_distro_alias ${DISTROS[LFD]})
# shellcheck disable=SC2086
[[ -z ${DISTROS[EMBEDDED]} ]] || DISTROS[EMBEDDED]=$(fix_distro_alias ${DISTROS[EMBEDDED]})
# shellcheck disable=SC2086
[[ -z ${DISTROS[LFS]} ]] || DISTROS[LFS]=$(fix_distro_alias ${DISTROS[LFS]})



#===============================================================================
parse_distro() {
    local DIST DARCH DVER GT
    IFS='-' read -r DIST GT <<< "$1"
    DVER=${GT%+}
    GT=${GT/$DVER/}
    IFS=':' read -r DIST DARCH <<< "$DIST"
    debug 3 "parse_distro: $DIST,$DARCH,$DVER,$GT"
    echo "$DIST,$DARCH,$DVER,$GT"
}

#===============================================================================
# Is distro-B in filter-A?
cmp_dists() {
    local A=$1 B=$2
    debug 2 "cmp_dists: $A $B"

    if [[ $A = "$B" || $A+ = "$B" || $A = $B+ ]] ; then
        return 0
    fi

    local AD AA AV AG
    local BD BA BV BG
    # shellcheck disable=SC2046
    IFS=',' read -r AD AA AV AG <<< $(parse_distro "$A")
    # shellcheck disable=SC2034,SC2046
    IFS=',' read -r BD BA BV BG <<< $(parse_distro "$B")

    if [[ $AD == "$BD" ]] ; then
        if [[ -n $AA || -n $BA ]] && [[ $AA != "$BA" ]] ; then
            return 1
        elif [[ $AV == "$BV" ]] ; then
            return 0
        elif [[ -n $AG ]] ; then
            version_greater_equal "$AV" "$BV" || return 0
        fi
    fi
    return 1
}

#===============================================================================
filter_dists() {
    local FILTER=${1/:*-/-}
    local DISTS=$2
    local F D

    # shellcheck disable=SC2027,SC2086
    debug 1 "filter_dists FILTER="$FILTER" DISTS="$DISTS

    if [[ -z $FILTER ]] ; then
        echo "$DISTS"
        return 0
    fi

    for D in $DISTS; do
        for F in $FILTER; do
            if cmp_dists "$F" "$D" ; then
                debug 2 "  filter_dists $D is in $F"
                echo "$D"
            fi
        done
    done
}

#===============================================================================
fix_distro_names() {
    local D
    for D in "$@" ; do
        local ALIAS
        ALIAS="${DISTRO_NAMES[${D%+}]:-}"
        if [[ -n $ALIAS ]] ; then
            debug 1 "fix_distro_names: $D -> $ALIAS"
            echo "$ALIAS"
        else
            debug 1 "fix_distro_names: $D"
            echo "$D"
        fi
    done
}

#===============================================================================
# JSON support
json_entry() {
    local NAME=$1 VALUE="$2" P=${3:-.}
    progress "$P"
    [[ -z $VALUE ]] || echo "      \"$NAME\": \"$VALUE\","
}
#-------------------------------------------------------------------------------
json_array() {
    # shellcheck disable=SC2155,SC2116,SC2086
    local NAME=$1 LIST=$(echo $2) WS=${3:-} P=${4:-+}
    progress "$P"
    [[ -z $LIST ]] || echo "      $WS\"$NAME\": [\"${LIST// /\", \"}\"],"
}
#-------------------------------------------------------------------------------
json_flag() {
    local FLAG=$1 YES=$2 NO=${3:-}
    shopt -s nocasematch
    case $FLAG in
        1|y*|on) echo "$YES";;
        0|n*|off) echo "$NO";;
    esac
    shopt -u nocasematch
}

#===============================================================================
# Distros, blacklists, and packages
json_distros() {
    local A=$1 DISTS="$2"
    # shellcheck disable=SC2086
    debug 1 "json_distros: A=$A DISTS="$DISTS

    #-------------------------------------------------------------------
    local DS
    # shellcheck disable=SC2086
    DS="$(value DISTROS $A)"
    # shellcheck disable=SC2086
    DS="$(fix_distro_alias $DS)"
    # shellcheck disable=SC2086
    debug 2 "list_json DISTROS="$DS
    json_array distros "$DS"

    #-------------------------------------------------------------------
    # shellcheck disable=SC2086
    json_entry distro_default "$(value DISTRO_DEFAULT $A)"

    #-------------------------------------------------------------------
    local BL
    if [[ ${DISTRO_BL[$A]:-} != delete ]] ; then
        # shellcheck disable=SC2086
        BL="$(value DISTRO_BL $A)"
        # shellcheck disable=SC2086
        json_array distro_bl "$BL"
    fi

    #-------------------------------------------------------------------
    # Packages per distro
    local DLIST
    # shellcheck disable=SC2086
    DLIST=$(filter_dists "$DS" "$DISTS")
    if [[ -n $DLIST ]] ; then
        echo '      "packages": {'
        local DIST
        # shellcheck disable=SC2013
        for DIST in $(sed 's/:[a-zA-Z0-9]*-/-/g; s/\+//g' <<<"$DLIST"); do
            [[ ! $BL =~ $DIST ]] || continue;
            local P
            # shellcheck disable=SC2086
            P=$(package_list ${DIST/-/ } $A)
            # shellcheck disable=SC2086
            json_array "$(fix_distro_names $DIST)" "$P" '  ' '*'
        done
        echo '      },'
    fi
}

#===============================================================================
# Calculate follow on classes from from PREREQ
declare -A FOLLOWON
calculate_follow_on() {
    debug 1 "calculate_follow_on"
    local A
    # shellcheck disable=SC2086
    for A in $(list_sort ${!TITLE[*]}); do
        debug 2 "  calculate_follow_on: $A"
        local K="${PREREQ[$A]:-}"
        if [[ -n $K ]] ; then
            debug 2 "    calculate_follow_on FOLLOWON[$K]=$A"
            local S="${FOLLOWON[$K]:-}"
            FOLLOWON[$K]="${S:+$S }$A"
        fi
    done
}

#===============================================================================
# Find file from md5sums file
find_file() {
    local FILE=$1 PAT=$2
    awk "/$PAT/ {a=\$2} END{print a}" "$FILE"
}

#===============================================================================
# Calculate Materials
calculate_materials() {
    local A=$1
    debug 1 "calculate_materials: $A"

    local MD5 APPENDICES ERRATA RESOURCES SOLUTIONS VER
    MD5=$(get_md5sum "$A")
    APPENDICES=$(find_file "$MD5" APPENDICES)
    RESOURCES=$(find_file "$MD5" RESOURCES)
    SOLUTIONS=$(find_file "$MD5" SOLUTIONS)
    VER=$(get_file_version "$SOLUTIONS")
    ERRATA=$(find_file "$MD5" "${VER}_ERRATA")
    debug 1 "calculate_materials: $APPENDICES, $ERRATA, $RESOURCES, $SOLUTIONS"
    echo "$APPENDICES" "$ERRATA" "$RESOURCES" "$SOLUTIONS"
}

#===============================================================================
json_activities() {
    local DISTS="$1" A
    # shellcheck disable=SC2086
    debug 1 "json_activities: DISTS="$DISTS

    calculate_follow_on

    # shellcheck disable=SC2086
    for A in $(list_sort ${!TITLE[*]}); do
        debug 1 "  json_activities: $A"
        progress "$A: "
        echo "    \"$A\": {"
        json_entry title "${TITLE[$A]}"
        json_entry url "${WEBPAGE[$A]:-}"
        # shellcheck disable=SC2046
        local ATTR
        read -r -d '' ATTR <<-ENDATTR
		$(json_flag "${EMBEDDED[$A]:-$EMBEDDED}" "Embedded")
		${MOOC[$A]:-$MOOC}
		$(json_flag "${SELFPACED[$A]:-$SELFPACED}" "Self-paced" "Instructor-led")
		$(json_flag "${INPERSON[$A]:-$INPERSON}" "On-site")
		$(json_flag "${VIRTUAL[$A]:-$VIRTUAL}" "Virtual")
		ENDATTR
        json_array attr "$ATTR"
        json_entry instr_led_class "${INSTR_LED_CLASS[$A]:-}"
        json_entry selfpaced_class "${SELFPACED_CLASS[$A]:-}"
        json_entry prereq "${PREREQ[$A]:-}"
        json_entry followon "${FOLLOWON[$A]:-}"
        local O M
        O="$(value OS $A)"
        json_entry internet "$(value INTERNET $A)"
        M=$(calculate_materials "$A")
        [[ -z $M ]] || json_array materials "$M"
        json_entry os "$O"
        json_entry nativelinux "$(value NATIVELINUX $A)"
        json_entry vm_okay "$(value VMOKAY $A)"

        #-----------------------------------------------------------------------
        # Do more if the OS is Linux
        if [[ $O != "Linux" ]] ; then
            json_entry os_needs "$(value OS_NEEDS $A)"
        else
            json_entry arch "$(value ARCH $A)"
            local CP PCP
            CP="$(value CPUS $A)"
            PCP="$(value PREFER_CPUS $A)"
            json_entry cpus "${PCP:-$CP}${PCP:+ (minimum $CP)}"
            json_entry cpuflags "$(value CPUFLAGS $A)"
            json_entry bogomips "$(value BOGOMIPS $A)"
            json_entry ram "$(value RAM $A)"
            json_entry disk "$(value DISK $A)"
            json_entry boot "$(value BOOT $A)"
            json_entry configs "$(value CONFIGS $A)"
            json_entry distro_arch "$(value DISTRO_ARCH $A)"
            json_entry card_reader "$(value CARDREADER $A)"
            json_entry os_needs "$(value OS_NEEDS $A)"
            json_entry includes "$(value INCLUDES $A)"
            json_distros "$A" "$DISTS"
        fi
        echo '    },'
        progress "\n"
    done
}

#===============================================================================
json_password() {
    [[ -n $CMPASSWORD ]] || return 0

    cat <<ENDJSON
  "user": "$CMUSERNAME",
  "pass": "$CMPASSWORD",
ENDJSON
}

#===============================================================================
json_vms() {
    [[ -n $VMURL ]] || return 0

    if [[ -n $NONETWORK ]] ; then
        warn "json_vms: Can't get VMs because no-network selected."
        return 0
    fi

    local FILES FILE
    FILES=$(get_file "$VMURL" \
        | awk -F '"' '/<tr><td.*[A-Z].*\.tar/ {print $8}' \
        | sort -i)
    # shellcheck disable=SC2086
    debug 1 "json_vms:"$FILES
    local URL="$LFCM/$VMURL"

    echo '  "vms": {'
    progress "VMs: "
    for FILE in $FILES; do
        local NAME
        NAME=${FILE%%.tar*}
        case "$FILE" in
            CentOS*) json_entry "fl-centos,$NAME" "$URL/$FILE" ;;
            Debian*) json_entry "fl-debian,$NAME" "$URL/$FILE" ;;
            FC*|Fedora*) json_entry "fl-fedora,${NAME/FC/Fedora}" "$URL/$FILE" ;;
            GENTOO*) json_entry "fl-gentoo,$NAME" "$URL/$FILE" ;;
            Linux-Mint*|LinuxMint*|Mint*) json_entry "fl-linuxmint,${NAME/*Mint/Linux-Mint}" "$URL/$FILE" ;;
            OpenSUSE*|openSUSE*) json_entry "fl-opensuse,${NAME/OpenSUSE/openSUSE}" "$URL/$FILE" ;;
            Ubuntu*) json_entry "fl-ubuntu,$NAME" "$URL/$FILE" ;;
            *) error "Unknown VM type in $URL" ;;
        esac
    done
    progress "\n"
    echo '  }'
}

#===============================================================================
# shellcheck disable=SC2120
print_json() {
    local DISTS
    DISTS=$(distrib_list)
    # shellcheck disable=SC2086
    debug 1 "print_json: DISTS="$DISTS

    cat <<ENDJSON | perl -e '$/=undef; $_=<>; s/,(\s+[}\]])/$1/gs; print;'
{
  "whatisthis": "Activity requirements",
  "version": "$VERSION",
  "tool": "$LFCM/prep/${CMDBASE/-full/}",
  "form": {
    "title": "Title",
    "attr": "Attributes",
    "instr_led_class": "Equivalent Instructor Led Course",
    "selfpaced_class": "Equivalent Online Self-Paced Course",
    "prereq": "Suggested Prior Courses",
    "followon": "Suggested Follow-on Courses",
    "internet": "Internet Access",
    "materials": "Supplemental Materials",
    "os": "OS required for class",
    "vm_okay": "Virtual Machine",
    "nativelinux": "Native Linux",
    "os_needs": "Required SW for class",
    "arch": "Required CPU Architecture",
    "cpus": "Preferred Number of CPUs",
    "bogomips": "Minimum CPU Performance (bogomips)",
    "cpuflags": "Required CPU features",
    "ram": "Minimum Amount of RAM (GiB)",
    "disk": "Free Disk Space in \$HOME (GiB)",
    "boot": "Free Disk Space in /boot (MiB)",
    "configs": "Kernel Configuration Options",
    "distro_arch": "Distro Architecture",
    "distros": "Supported Linux Distros",
    "distro_bl": "Unsupported Linux Distros",
    "card_reader": "Is the use of a Card Reader Required?",
    "includes": "What is provided?",
    "packages": "Package List"
  },
  "help": {
    "prereq": "Course(s) which we suggest you take before this one",
    "internet": "Fast Internet access in the classroom is mandatory for this course",
    "os_needs": "These are the kinds of SW needed for the course",
    "cpus": "CPUs = Chips x Cores x Hyperthreads. Preferably in a computer which is less than 5yrs old",
    "bogomips": "This is a terrible measure of performance, but consistent across architectures",
    "cpuflags": "Your CPU must have these flags set which indicate CPU HW capabilities",
    "disk": "If not in \$HOME, then in some other attached drive",
    "boot": "We will be installing kernels, so there needs to be room available",
    "configs": "Your Linux kernel must be configured with these options",
    "distro_bl": "These versions of distros will cause problems in class",
    "card_reader": "A card reader will be provided to you in class",
    "includes": "There is a HW kit which is (optionally) included with this course",
  },
  "distros": [
$(for DIST in $DISTS ; do echo '    "'"$DIST"'+",'; done | sort)
  ],
  "distro_fallback": {
$(for FB in ${!FALLBACK[*]} ; do echo '    "'"$FB"'": "'"${FALLBACK[$FB]}"'",'; done | sort)
  },
  "activities": {
$(json_activities "$DISTS")
  },
$(json_password)
$(json_vms)
}
ENDJSON
    # Minification
    #| sed ':a;N;$!ba; s/\n//g; s/   *//g; s/\([:,]\) \([\[{"]\)/\1\2/g'

    verbose "JSON generated"
    exit 0
}

#===============================================================================
# shellcheck disable=SC2119
if [[ -n $JSON ]] ; then
    print_json
    exit 0
fi

#===============================================================================
# TEST: Right cpu architecture?
check_cpu() {
    local ARCH=$1
    local CPU_ARCH

    if [[ -n $ARCH ]] ; then
        CPU_ARCH=$(uname -m)
        verbose "check_cpu: ARCH='$ARCH' CPU_ARCH='$CPU_ARCH'"
        if [[ $ARCH = i386 && $CPU_ARCH = i686 ]] ; then
            pass "CPU architecture is $ARCH ($CPU_ARCH)"
        elif [[ $CPU_ARCH = "$ARCH" && -z $SIMULATE_FAILURE ]] ; then
            pass "CPU architecture is $CPU_ARCH"
        else
            fail "CPU architecture is not $ARCH (it is $CPU_ARCH)"
            FAILED=y
        fi
    fi
}

#===============================================================================
# TEST: Right cpu flags?
check_cpu_flags() {
    local CPUFLAGS=$1
    local FLAGS NOTFOUND

    if [[ -n $CPUFLAGS ]] ; then
        verbose "check_cpu_flags: CPUFLAGS=$CPUFLAGS"
        for FLAGS in $CPUFLAGS ; do
             grep -qc " ${FLAGS/|/\\|} " /proc/cpuinfo || NOTFOUND+=" $FLAGS"
        done
        if [[ -n $NOTFOUND ]] ; then
            fail "CPU doesn't have the following capabilities:$NOTFOUND"
            FAILED=y
        else
            pass "CPU has all needed capabilities: $CPUFLAGS"
        fi
    fi
}

#===============================================================================
get_number_of_cpus() {
    local NUM_CPU
    NUM_CPU=$(lscpu | awk '/^CPU\(s\):/ {print $2}')
    [[ -n $NUM_CPU ]] || NUM_CPU=$(grep -c ^processor /proc/cpuinfo)
    echo "${NUM_CPU:-0}"
}

#===============================================================================
# Used to pass information between check_number_of_cpus() and check_bogomips()
NOTENOUGH=

#===============================================================================
# TEST: Enough CPUS?
check_number_of_cpus() {
    local CPUS=$1
    verbose "check_number_of_cpus: CPUS=$CPUS"
    local NUM_CPU

    NUM_CPU=$(get_number_of_cpus)
    if [[ -z $NUM_CPU || $NUM_CPU == 0 ]] ; then
        bug "I didn't find the number of cpus you have" "lscpu | awk '/^CPU\\(s\\):/ {print \$2}'"
    elif [[ $NUM_CPU -lt $CPUS || -n $SIMULATE_FAILURE ]] ; then
        fail "Single core CPU: not powerful enough (require at least $CPUS, though $PREFER_CPUS is preferred)"
        FAILED=y
        NOTENOUGH=y
    elif [[ $NUM_CPU -lt $PREFER_CPUS ]] ; then
        pass "$NUM_CPU core CPU (good enough but $PREFER_CPUS is preferred)"
    else
        pass "$NUM_CPU core CPU"
    fi
}

#===============================================================================
get_bogomips() {
    local NUM_CPU BMIPS
    NUM_CPU=$(get_number_of_cpus)
    BMIPS=$(lscpu | awk '/^BogoMIPS:/ {print $2}' | sed -re 's/\.[0-9]{2}$//')
    [[ -n $BMIPS ]] || BMIPS=$(awk '/^bogomips/ {mips+=$3} END {print int(mips + 0.5)}' /proc/cpuinfo)
    echo $(( ${NUM_CPU:-0} * ${BMIPS:-0} ))
}

#===============================================================================
# TEST: Enough BogoMIPS?
check_bogomips() {
    local BOGOMIPS=$1
    local BMIPS

    if [[ -n $BOGOMIPS ]] ; then
        verbose "check_bogomips: BOGOMIPS=$BOGOMIPS"
        BMIPS=$(get_bogomips)
        if [[ -z $BMIPS || $BMIPS == 0 ]] ; then
            bug "I didn't find the number of BogoMIPS your CPU(s) have" \
                "awk '/^bogomips/ {mips+=\$3} END {print int(mips + 0.5)}' /proc/cpuinfo"
        elif [[ $BMIPS -lt $BOGOMIPS || -n $SIMULATE_FAILURE ]] ; then
            fail "Your CPU isn't powerful enough (must be at least $BOGOMIPS BogoMIPS cumulatively)"
            FAILED=y
        else
            if [[ -n $NOTENOUGH ]] ; then
                notice "Despite not having enough CPUs, you may still have enough speed (currently at $BMIPS BogoMIPS)"
            else
                pass "Your CPU appears powerful enough (currently at $BMIPS BogoMIPS cumulatively)"
            fi
        fi
    fi
}

#===============================================================================
# TEST: Enough RAM?
check_ram() {
    local RAM=$1
    verbose "check_ram: RAM=$RAM"
    local RAM_GBYTES

    RAM_GBYTES=$(awk '/^MemTotal/ {print int($2/1024/1024+0.7)}' /proc/meminfo)
    if [[ -z $RAM_GBYTES ]] ; then
        bug "I didn't how much free RAM you have" \
            "awk '/^MemTotal/ {print int(\$2/1024/1024+0.7)}' /proc/meminfo"
    elif [[ $RAM_GBYTES -lt $RAM || -n $SIMULATE_FAILURE ]] ; then
        fail "Only $RAM_GBYTES GiB RAM (require at least $RAM GiB)"
        FAILED=y
    else
        pass "$RAM_GBYTES GiB RAM"
    fi
}

#===============================================================================
# df wrapper
get_df() {
    local DIR=$1
    local UNIT=$2

    if [[ -n $DIR ]] ; then
        local KBYTES
        KBYTES=$(df -k "$DIR" | awk '{if (NR == 2) print int($4)}')
        case $UNIT in
            MiB) echo $(( (KBYTES + 512) / 1024 ));;
            GiB) echo $(( (KBYTES + 512*1024) / 1024 / 1024));;
        esac
    fi
}

#===============================================================================
# find space on another attached drive
find_alternate_disk() {
    local MINSIZE=$1
    local UNIT=$2
    local STRING=$3
    local NOTFOUND=1 FS TOTAL USED AVAIL USE MP
    debug 1 "find_alternate_disk: Looking for disk ${STRING:+(${STRING%=})} bigger than $MINSIZE $UNIT"

    # shellcheck disable=SC2034
    while read -r FS TOTAL USED AVAIL USE MP; do
        [[ -n $MP ]] || continue
        AVAIL=$(get_df "$MP" "$UNIT")
        debug 2 "  Check MP=$MP AVAIL=$AVAIL UNIT=$UNIT"
        if [[ $AVAIL -ge $MINSIZE ]] ; then
           echo "$STRING$MP has $AVAIL $UNIT free"
           NOTFOUND=0
        fi
    done <<< "$(df | awk '{if (NR > 1) print}')"
    return $NOTFOUND
}

#===============================================================================
# TEST: Enough free disk space in $BUILDHOME? (defaults to $HOME)
check_free_disk() {
    local DISK=$1
    local BUILDHOME=$2
    [[ -n $BUILDHOME ]] || BUILDHOME=$(getent passwd "$USER" | cut -d: -f6)
    [[ -n $BUILDHOME ]] || error "No BUILDHOME specified"
    verbose "check_free_disk: DISK=$DISK BUILDHOME=$BUILDHOME"
    local DISK_GBYTES ALT

    DISK_GBYTES=$(get_df "$BUILDHOME" GiB)
    if [[ -z $DISK_GBYTES ]] ; then
        bug "I didn't find how much disk space is free in $BUILDHOME" \
            "df --output=avail $BUILDHOME | awk '{if (NR == 2) print int(($4+524288)/1048576)}'"
    elif [[ ${DISK_GBYTES:=1} -lt $DISK || -n $SIMULATE_FAILURE ]] ; then
        ALT=$(find_alternate_disk "$DISK" GiB "BUILDHOME=")
        if [[ -n $ALT ]] ; then
            warn "$BUILDHOME only has $DISK_GBYTES GiB free (need at least $DISK GiB)"
            pass "However, $ALT"
        else
            fail "only $DISK_GBYTES GiB free in $BUILDHOME (need at least $DISK GiB) Set BUILDHOME=/path/to/disk to override \$HOME"
            FAILED=y
        fi
    else
        pass "$DISK_GBYTES GiB free disk space in $HOME"
    fi
}

#===============================================================================
# TEST: Enough free disk space in /boot?
check_free_boot_disk() {
    local BOOT=$1
    local BOOTDIR=${2:-/boot}
    [[ -n $BOOTDIR ]] || error "No BOOTDIR specified"
    verbose "check_free_boot_disk: BOOT=$BOOT BOOTDIR=$BOOTDIR"
    local BOOT_MBYTES

    BOOT_MBYTES=$(get_df "$BOOTDIR" MiB)
    if [[ -z $BOOT_MBYTES ]] ; then
        bug "I didn't find how much disk space is free in $BOOTDIR" \
            "awk '/^MemTotal/ {print int(\$2/1024/1024+0.7)}' /proc/meminfo"
    elif [[ ${BOOT_MBYTES:=1} -le $BOOT || -n $SIMULATE_FAILURE ]] ; then
        fail "only $BOOT_MBYTES MiB free in /boot (need at least $BOOT MiB)"
        FAILED=y
    else
        pass "$BOOT_MBYTES MiB free disk space in /boot"
    fi
}

#===============================================================================
# TEST: Right Linux distribution architecture?
check_distro_arch() {
    local ARCH=$1
    local DISTRO_ARCH=$2

    if [[ -n $DISTRO_ARCH ]] ; then
        verbose "check_distro_arch: DISTRO_ARCH=$DISTRO_ARCH ARCH=$ARCH"
        if [[ -z $ARCH || -z $DISTRO_ARCH ]] ; then
            bug "Wasn't able to determine Linux distribution architecture" \
                "$0 --gather-info"
        elif [[ $ARCH != "$DISTRO_ARCH" || -n $SIMULATE_FAILURE ]] ; then
            fail "The distribution architecture must be $DISTRO_ARCH"
            FAILED=y
        else
            pass "Linux distribution architecture is $DISTRO_ARCH"
        fi
    fi
}

#===============================================================================
# Look for the current distro in a list of distros
found_distro() {
    local ID=$1 DARCH=$2 RELEASE=$3 DISTROS=$4
    local DISTRO
    debug 1 "found_distro: ID=$ID DARCH=$DARCH RELEASE=$RELEASE DISTROS=$DISTROS"

    for DISTRO in $DISTROS ; do
        debug 2 "  found_distro: $ID:$DARCH-$RELEASE compare $DISTRO"
        local G='' R='*' A='*'
        if [[ $DISTRO = *+ ]] ; then 
            G=y
            DISTRO=${DISTRO%\+}
            debug 2 "    distro_found: $DISTRO or greater"
        fi
        if [[ $DISTRO = *-* ]] ; then
            R=${DISTRO#*-}
            DISTRO=${DISTRO%-*}
        fi
        if [[ $DISTRO = *:* ]] ; then
            A=${DISTRO#*:}
            DISTRO=${DISTRO%:*}
        fi
        local MSG="    found_distro: Are we running DISTRO=$DISTRO ARCH=$A REL=$R ${G:+or-newer }?"
        # shellcheck disable=SC2053
        if [[ $ID = "$DISTRO" && $DARCH = $A ]] ; then
            debug 2 "    found_distro: RELEASE=$RELEASE G=$G R=$R"
            if [[ $G = y && $R != "*" ]] && version_greater_equal "$RELEASE" "$R" ; then
                debug 2 "    distro_found: $RELEASE >= $R"
                R='*'
            fi
            # shellcheck disable=SC2053
            if [[ $RELEASE = $R ]] ; then
                debug 2 "$MSG Yes"
                return 0
            fi
        fi
        debug 2 "$MSG No"
    done
    return 1
}

#===============================================================================
# TEST: Blacklisted Linux distribution?
check_distro_bl() {
    local ID=$1 DARCH=$2 RELEASE=$3 CODENAME=$4 DISTRO_BL=$5
    debug 1 "check_distro_bl: ID=$ID DARCH=$DARCH RELEASE=$RELEASE DISTRO_BL=$DISTRO_BL"

    if [[ -n $SIMULATE_FAILURE ]] ; then
        DISTRO_BL=$ID-$RELEASE
    fi
    if [[ -z $ID || -z $DARCH ]] ; then
        bug "Wasn't able to determine Linux distribution" \
            "$0 --gather-info"
    elif [[ -n $DISTRO_BL ]] ; then
        if found_distro "$ID" "$DARCH" "$RELEASE" "$DISTRO_BL" ; then
            fail "This Linux distribution can't be used for this activity: $ID:$DARCH-$RELEASE ${CODENAME:+($CODENAME)}"
            FAILED=y
            [[ -n $SIMULATE_FAILURE ]] || exit 1
        fi
    fi
}

#===============================================================================
# TEST: Right Linux distribution?
check_distro() {
    local ID=$1 DARCH=$2 RELEASE=$3 CODENAME=$4 DESCRIPTION=$5 DISTROS=$6
    debug 1 "check_distro: ID=$ID DARCH=$DARCH RELEASE=$RELEASE DISTROS=$DISTROS"

    if [[ -n $SIMULATE_FAILURE ]] ; then
        DISTROS=NotThisDistro-0
    fi
    if [[ -z $DISTROS ]] ; then
        notice "Currently running $DESCRIPTION (supported)"
    elif [[ -z $ID || -z $DARCH ]] ; then
        bug "Wasn't able to determine Linux distribution" \
            "$0 --gather-info"
    else
        if found_distro "$ID" "$DARCH" "$RELEASE" "$DISTROS" ; then
            pass "Linux distribution is $ID:$DARCH-$RELEASE ${CODENAME:+($CODENAME)}"
        else
            warn "Linux distribution is $ID:$DARCH-$RELEASE ${CODENAME:+($CODENAME)}"
            fail "The distribution must be: $DISTROS"
            FAILED=y
        fi
    fi
}

#===============================================================================
# TEST: Is the kernel configured properly?
check_kernel_config() {
    local CONFIGS=$1

    if [[ -n $CONFIGS ]] ; then
        verbose "check_kernel_config: CONFIGS=$CONFIGS"
        local MISSINGCONFIG KERNELCONFIG
        KERNELCONFIG=${KERNELCONFIG:-/boot/config-$(uname -r)}
        if [[ ! -f $KERNELCONFIG ]] ; then
            warn "Wasn't able to find kernel config. You can specify it by setting KERNELCONFIG=<filename>"
            return 1
        fi
        for CONFIG in $CONFIGS ; do
            grep -qc "CONFIG_$CONFIG" "$KERNELCONFIG" || MISSINGCONFIG+=" $CONFIG"
        done
        if [[ -z $MISSINGCONFIG ]] ; then
            pass "The Current kernel is properly configured: $CONFIGS"
        else
            fail "Current kernel is missing these options:$MISSINGCONFIG"
            FAILED=y
        fi
    fi
}

#===============================================================================
# TEST: Is there Internet?
#   You can set the PINGHOST environment variable in order to override the default
check_internet() {
    local INTERNET=$1
    local AVAILABLE=$2
    local PINGHOST=${3:-8.8.8.8}

    if [[ -n $INTERNET ]] ; then
        verbose "check_internet: INTERNET=$INTERNET AVAILABLE=${AVAILABLE:-n} PINGHOST=$PINGHOST"
        if [[ -n $NONETWORK ]] ; then
            warn "check_internet: No Internet because no-network selected."
        elif [[ -z $SIMULATE_FAILURE && -n $AVAILABLE ]] ; then
            pass "Internet is available (which is required in this case)"
        elif [[ -z $SIMULATE_FAILURE ]] && ping -q -c 1 "$PINGHOST" >/dev/null 2>&1 ; then
            verbose "check_internet with ping PINGHOST=$PINGHOST"
            pass "Internet is available (which is required in this case)"
        else
            fail "Internet doesn't appear to be available"
            FAILED=y
        fi
    else
        verbose "Not requiring Internet availability"
    fi
}

#===============================================================================
check_all() {
    check_cpu "$ARCH"
    check_cpu_flags "$CPUFLAGS"
    check_number_of_cpus "$CPUS"
    check_bogomips "$BOGOMIPS"
    check_ram "$RAM"
    check_free_disk "$DISK" "${BUILDHOME:-$HOME}"
    check_distro_arch "$ARCH" "$DISTRO_ARCH"
    check_distro_bl "$ID" "$DARCH" "$RELEASE" "$CODENAME" "$DISTRO_BL"
    check_distro "$ID" "$DARCH" "$RELEASE" "$CODENAME" "$DESCRIPTION" "${DISTROS:-}"
    check_kernel_config "$CONFIGS"
    check_internet "$INTERNET" "$INTERNET_AVAILABLE" "${PINGHOST:-}"
}


EPELURL="http://download.fedoraproject.org/pub/epel"

#===============================================================================
# See whether sudo is available
check_sudo() {
    local DID=$1 DREL=$2
    if ! sudo -V >/dev/null 2>&1 ; then
        [[ $USER == root ]] || warn "sudo isn't installed, so you will have to run these commands as root instead"
        # Provide sudo wrapper for try_packages
        sudo() {
             if [[ $USER == root ]] ; then
                 "$@"
             else
                 highlight "Please enter root password to run the following as root"
                 highlight "$*" >&2
                 su -c "$*" root
             fi
        }
        INSTALL=y NO_CHECK=y NO_PASS=y NO_WARN=y try_packages "$DID" "$DREL" ACTIVITY sudo
        unset sudo
        if [[ -f /etc/sudoers ]] ; then
            # Add $USER to sudoers
            highlight "Please enter root password to add yourself to sudoers"
            su -c "sed -ie 's/^root\(.*ALL$\)/root\1\n$USER\1/' /etc/sudoers" root
        fi
        highlight "From now on you will be asked for your user password"
    fi
}

#===============================================================================
check_repos() {
    local ID=$1
    local RELEASE=$2
    local CODENAME=$3
    local ARCH=$4
    local CHANGES='' REPOS SECTION
    debug 1 "check_repos: ID=$ID RELEASE=$RELEASE CODENAME=$CODENAME ARCH=$ARCH"
    verbose "Checking installed repos"

    #-------------------------------------------------------------------------------
    if [[ $ID == Debian ]] ; then
        debug 2 "  Check repos for Debian"
        REPOS="contrib non-free"
        local LISTFILE=/etc/apt/sources.list.d/debian.list
        # shellcheck disable=SC2046
        for SECTION in $REPOS ; do
            # shellcheck disable=SC2016
            while read -r LINE ; do
                [[ -n $LINE ]] || continue
                debug 2 "    Is '$LINE' enabled?"
                [[ -f $LISTFILE ]] || sudo touch $LISTFILE
                if ! grep -h -q "$LINE" $LISTFILE ; then
                    echo "$LINE" | sudo tee -a $LISTFILE
                    verbose "Adding '$LINE' to $LISTFILE"
                    CHANGES=y
                fi
            done <<< "$(grep -h "deb .*debian.* main" /etc/apt/sources.list \
                $(if [[ -f $LISTFILE ]] ; then echo "$LISTFILE" ; fi) \
                | sed -e '/^#/d; /"$SECTION"/d; s/main.*/'"$SECTION"'/')"
        done
        if [[ -n $CHANGES ]] ; then
            notice "Enabling $REPOS in sources.list... updating"
            sudo apt-get -qq update
        fi

    #-------------------------------------------------------------------------------
    elif [[ $ID =~ CentOS|RHEL ]] ; then
        debug 2 "  Check repos for CentOS|RHEL"
        if rpm -q epel-release >/dev/null ; then
            verbose "epel is already installed"
        else
            case "$RELEASE" in
                6*) [[ $ARCH != i386 && $ARCH != x86_64 ]] \
                        || EPEL="$EPELURL/6/i386/Packages/epel-release-6-8.noarch.rpm" ;;
                7*) [[ $ARCH != x86_64 ]] \
                        || EPEL="$EPELURL/7/x86_64/Packages/e/epel-release-7-11.noarch.rpm" ;;
            esac
            if [[ -n $EPEL ]] ; then
                notice "Installing epel in ${ID}..."
                sudo rpm -Uvh $EPEL
            fi
        fi

    #-------------------------------------------------------------------------------
    elif [[ $ID == Ubuntu ]] ; then
        debug 2 "  Check repos for Ubuntu"
        REPOS="universe multiverse"
        for SECTION in $REPOS ; do
            local DEB URL DIST SECTIONS
            # shellcheck disable=SC2094
            while read -r DEB URL DIST SECTIONS ; do
                [[ $DEB = deb-src ]] || continue
                [[ $URL =~ http && $DIST =~ $CODENAME && $SECTIONS =~ main ]] || continue
                if [[ $URL =~ archive.canonical.com || $URL =~ extras.ubuntu.com ]] ; then continue ; fi
                debug 2 "    $ID: is $SECTION enabled for $URL $DIST $SECTIONS"
                # shellcheck disable=2094
                if ! grep -E -q "^$DEB $URL $DIST .*$SECTION" /etc/apt/sources.list ; then
                    verbose "Running: sudo add-apt-repository '$DEB $URL $DIST $SECTION'"
                    sudo add-apt-repository "$DEB $URL $DIST $SECTION"
                    CHANGES=y
                fi
            done </etc/apt/sources.list
        done
        if [[ -n $CHANGES ]] ; then
            notice "Enabling $REPOS in sources.list... updating"
            sudo apt-get -qq update
        fi
    fi
}

#===============================================================================
BUILDDEPSTR=build-dep_
no_build_dep() {
    sed 's/ /\n/g' <<<"$@" | sed -e "/$BUILDDEPSTR/d"
}

#===============================================================================
only_build_dep() {
    sed 's/ /\n/g' <<<"$@" | sed "/$BUILDDEPSTR/!d; s/$BUILDDEPSTR//g"
}

#===============================================================================
RFCONFIG="$HOME/.config/${CMDBASE%.sh}"
clear_installed() {
    if [[ -n $ALL_ACTIVITIES ]] ; then
        $DRYRUN rm -f "$RFCONFIG"/*-installed-packages.list
    else
        local ACTIVITY FILE
        # shellcheck disable=SC2048
        for ACTIVITY in $* ; do
            FILE="$RFCONFIG/${ACTIVITY}-installed-packages.list"
            if [[ -f $FILE ]] ; then
                $DRYRUN rm "$FILE"
            fi
        done
    fi
}

#===============================================================================
read_installed() {
    if [[ -n $ALL_ACTIVITIES ]] ; then
        cat "$RFCONFIG"/*-installed-packages.list
    else
        local ACTIVITY FILE
        for ACTIVITY in "$@" ; do
            FILE="$RFCONFIG/${ACTIVITY}-installed-packages.list"
            if [[ -f $FILE ]] ; then
                cat "$FILE"
            fi
        done
    fi
}

#===============================================================================
save_installed() {
    local ACTIVITY FILE
    ACTIVITY=$(head -1 <<<"$1"); shift
    mkdir -p "$RFCONFIG"
    FILE="$RFCONFIG/${ACTIVITY%% *}-installed-packages.list"
    debug 1 "Saving installed packages ($*) to file: $FILE"
    # shellcheck disable=SC2001
    echo "$*" | sed -e 's/ /\n/g' >>"$FILE"
}

#===============================================================================
deb_check() {
    verbose "Check dpkg is in a good state"
    while [[ $( (dpkg -C 2>/dev/null || sudo dpkg -C) | wc -l) -gt 0 ]] ; do
        local PKG FILE
        if sudo dpkg -C | grep -q "missing the md5sums" ; then
            for PKG in $(sudo dpkg -C | awk '/^ / {print $1}') ; do
                [[ ! -f /var/lib/dpkg/info/${PKG}.md5sums ]] || continue
                if warn_wait "The md5sums for $PKG need updating. Can I fix it?" ; then
                    for FILE in $(sudo dpkg -L "$PKG" | grep -v "^/etc" | sort) ; do
                        if [[ -f $FILE && ! -L $FILE ]] ; then
                            md5sum "$FILE"
                        fi
                    done | sed 's|/||' | sudo tee "/var/lib/dpkg/info/${PKG}.md5sums" >/dev/null
                fi
            done
            verbose "Updated all missing MD5SUM files"
        else
            if warn_wait "dpkg reports some issues with the package system. I can't continue without these being fixed.\n    Is it okay if I try a \"dpkg --configure -a\"?" ; then
                sudo dpkg --configure -a
                verbose "Attempted to configure all unconfigured packages"
            fi
        fi
    done
}

#===============================================================================
# Install packages with apt-get
debinstall() {
    local PKGLIST BDLIST NEWPKG
    local ACTIVITY=$1; shift
    PKGLIST=$(no_build_dep "$@")
    BDLIST=$(only_build_dep "$@")
    if [[ -z $PKGLIST && -z $BDLIST ]] ; then
        return 0
    fi
    # shellcheck disable=SC2086
    debug 1 "debinstall: "$*

    deb_check

    local APTGET="apt-get --no-install-recommends"
    # Check for packages which can't be found
    if [[ -n $PKGLIST ]] ; then
        local ERRPKG
        # shellcheck disable=SC2086
        ERRPKG=$($APTGET --dry-run install $PKGLIST 2>&1 \
            | awk '/^E: Package/ {print $3}; /^E: Unable to correct/ {print $2}; /^E: Unable/ {print $6}' \
            | sed -e "/-f/d; s/'//g")
        if [[ $ERRPKG =~ Unable ]] ; then
            # shellcheck disable=SC2086
            $APTGET --dry-run install $PKGLIST
            $DRYRUN sudo dpkg --audit
            error "Unable to install package list, or your packaging system is in an inconsistent state"
        elif [[ -n $ERRPKG ]] ; then
            warn "Can't find package(s) in index: $ERRPKG"
            echo "Looks like you may need to run 'sudo apt-get update' and try this again"
            MISSING_PACKAGES=y
            return 0
        fi
    fi

    # Find new packages which need installing
    # shellcheck disable=SC2046
    NEWPKG=$(list_sort $(
        # shellcheck disable=SC2086
        [[ -z $PKGLIST ]] || $APTGET --dry-run install $PKGLIST | awk '/^Inst / {print $2}';
        # shellcheck disable=SC2086
        [[ -z $BDLIST ]] || $APTGET --dry-run build-dep $BDLIST | awk '/^Inst / {print $2}'))
    [[ -z $SIMULATE_FAILURE ]] || NEWPKG=$PKGLIST
    if [[ -z $NEWPKG ]] ; then
        pass "All required packages are already installed"
        return 0
    else
        warn "Some packages are missing"
        WARNINGS=y
        MISSING_PACKAGES=y
        if [[ -z $INSTALL ]] ; then
            #notice "Need to install:" $NEWPKG
            fix_missing "You can install missing packages" \
                    "$0 --install $ACTIVITY" \
                    "sudo $APTGET install $NEWPKG"
        else
            local CONTINUE=
            if [[ -n $YES ]] ; then
                debug 1 "  debinstall: always --yes, so not asking; just continue."
                CONTINUE=y
            else
                # shellcheck disable=SC2086
                ask "About to install:" $NEWPKG "\nIs that okay? [y/N]"
                local CONFIRM
                read -r CONFIRM
                case $CONFIRM in
                    y*|Y*|1) CONTINUE=y;;
                esac
            fi
            if [[ -n $CONTINUE ]]  ; then
                # shellcheck disable=SC2086
                $DRYRUN sudo $APTGET install $NEWPKG
                if [[ -z ${NO_CHECK:-} ]] ; then
                    # shellcheck disable=SC2086
                    FAILPKG=$( (sudo $APTGET --dry-run install $PKGLIST | awk '/^Conf / {print $2}') 2>&1 )
                    if [[ -n $FAILPKG ]] ; then
                        warn "Some packages didn't install: $FAILPKG"
                        WARNINGS=y
                    else
                        save_installed "$ACTIVITY" "$NEWPKG"
                        pass "All required packages are now installed"
                        unset MISSING_PACKAGES
                        return 0
                    fi
                fi
            fi
        fi
    fi
    return 1
}

#===============================================================================
# Install packages with yum or zypper
rpminstall() {
    local ACTIVITY=$1; shift
    local TOOL=$1; shift
    local PKGLIST=$*
    [[ -n $PKGLIST ]] || return 0
    debug 1 "rpminstall: TOOL=$TOOL $PKGLIST"
    local NEWPKG

    # shellcheck disable=SC2046,SC2086
    NEWPKG=$(list_sort $(rpm -q $PKGLIST | awk '/is not installed$/ {print $2}'))
    [[ -z $SIMULATE_FAILURE ]] || NEWPKG=$PKGLIST
    if [[ -z $NEWPKG ]] ; then
        pass "All required packages are already installed"
        return 0
    else
        warn "Some packages are missing"
        #notice "Need to install:" $NEWPKG
        if [[ -z $INSTALL ]] ; then
            fix_missing "You can install missing packages" \
                    "$0 --install $ACTIVITY" \
                    "sudo $TOOL install $NEWPKG"
            MISSING_PACKAGES=y
        else
            # shellcheck disable=SC2086
            sudo $TOOL install $NEWPKG
            if [[ -z ${NO_CHECK:-} ]] ; then
                # shellcheck disable=SC2086
                FAILPKG=$(rpm -q $PKGLIST | awk '/is not installed$/ {print $2}')
                if [[ -n $FAILPKG ]] ; then
                    warn "Some packages didn't install: $FAILPKG"
                    WARNINGS=y
                else
                    save_installed "$ACTIVITY" "$NEWPKG"
                    pass "All required packages are now installed"
                    return 0
                fi
            fi
        fi
    fi
    return 1
}

#===============================================================================
# Install packages with pacman
pacinstall(){
    local ACTIVITY=$1; shift
    local PKGLIST=$*
    [[ -n $PKGLIST ]] || return 0
    debug 1 "pacinstall: Activity=${ACTIVITY} ${PKGLIST}"
    local NEWPKG NEWAUR PACPKG AURPKG

    for PKG in $PKGLIST; do
        if [[ $PKG =~ aur: ]]; then
           PACPKG="$PACPKG $PKG"
        else
           AURPKG="$AURPKG ${PKG/aur:/}"
        fi
    done

    debug 2 "Arch packages: $PACPKG, AUR packages: $AURPKG"
    # shellcheck disable=SC2086
    NEWPKG=$(pacman -Q $PACPKG 2>&1 | awk '/was not found$/ {print $3}' | sed "s/'//g" )

    if [[ -n $AURPKG ]]; then
        # shellcheck disable=SC2086
        NEWAUR=$(pacman -Q $AURPKG 2>&1 | awk '/was not found$/ {print $3}' | sed "s/'//g" )
    fi

    if [[ -n $SIMULATE_FAILURE ]] ; then
        NEWPKG=$PACPKG
        NEWAUR=$AURPKG
    fi

    debug 2 "$NEWPKG $NEWAUR"
    if [[ -z $NEWPKG && -z $NEWAUR ]]; then
        pass "All required packages are already installed"
        return 0
    else
        warn "Some packages are missing"
        # shellcheck disable=SC2086
        [[ -z $NEWPKG ]] || notice "Need to install Arch packages:" $NEWPKG
        # shellcheck disable=SC2086
        [[ -z $NEWAUR ]] || notice "Need to install Arch AUR packages:" $NEWAUR

        if [[ -z $INSTALL ]]; then
            local MSG
            [[ -z $NEWPKG ]] || MSG="sudo pacman -S $NEWPKG"
            [[ -z $NEWAUR ]] || MSG=$MSG"\n   AUR packages: $NEWAUR should be installed with your preferred AUR process"

            fix_missing "You can install missing packages" \
                "$0 install $ACTIVITY" "$MSG"

            WARNINGS=y
            MISSING_PACKAGES=y
        else
            warn "Some Arch Linux packages are mutually exclusive, i.e. gcc and gcc-multilib."
            notice "Please review the list of missing packages and validate."
            notice "Your environment will not be harmed before continuing."

            # shellcheck disable=SC2086
            ask "About to install:" $NEWPKG "\nIs that okay? [y/N]"
            local CONFIRM
            read -r CONFIRM
            case $CONFIRM in
                y*|Y*|1) CONTINUE=y;;
            esac

            if [[ $CONTINUE == y ]]; then
                # shellcheck disable=SC2086
                $DRYRUN sudo pacman -S $NEWPKG

                # Installing some AUR packages is simple, as the block below demonstrates, but some AUR packages may
                # have dependencies that are also AUR packages.  It will be necessary to actually parse the package,
                # interpret dependencies, check if they are AUR packages, and the clone, build, and install them.  This
                # process would also have to be recursive.
                # Dependencies within dependencies within dependencies...  AURception.  Arch users should be capable of
                # handling this in stride during a session.  I did.
                #
                # TEMPDIR="$(mktemp -d $0.aur.XXXX)"
                # trap "rm -rf '$TEMPDIR'" 0               # EXIT
                # trap "rm -rf '$TEMPDIR'; exit 1" 2       # INT
                # trap "rm -rf '$TEMPDIR'; exit 1" 1 15    # HUP TERM
                #
                # CURDIR="$(pwd)"
                # cd $TEMPDIR
                #
                # for CLONE in ${NEWAUR}; do
                #     $(git clone "https://aur.archlinux.org/${CLONE}.git")
                #     cd ./$CLONE
                #     makepkg -isr
                #     cd ..
                # done
                #
                # cd $CURDIR
                # rm -rf $TEMPDIR
            fi

            if [[ -z $NO_CHECK ]]; then
                # shellcheck disable=SC2086
                FAILPKG=$(pacman -Q $PACPKG 2>&1 | awk '/was not found$/ {print $3}' | sed "s/'//g" )

                if [[ -n $FAILPKG ]] ; then
                    warn "Some packages didn't install: $FAILPKG"
                    WARNINGS=y
                else
                    save_installed "$ACTIVITY" "$NEWPKG"

                    if [[ -z $NEWAUR ]]; then
                        pass "All required packages are now installed"
                    else
                        # shellcheck disable=SC2086
                        warn "AUR packages must be installed manually:" $NEWAUR
                    fi
                    return 0
                fi
            fi
        fi
    fi
    return 1
}

#===============================================================================
# Run extra code based on distro, release, and activity
run_extra_code() {
    local DID=$1
    local DREL=$2
    local ACTIVITY=$3
    local CODE
    debug 1 "run_extra_code: DID=$DID DREL=$DREL ACTIVITY=$ACTIVITY"

    for KEY in $DID-${DREL}_$ACTIVITY ${DID}_$ACTIVITY $ACTIVITY $DID-$DREL $DID ; do
        CODE=${RUNCODE[${KEY:-no_code_key}]:-}
        if [[ -n $CODE ]] ; then
            debug 2 "  run exra setup code for $KEY -> eval $CODE"
            eval "$CODE $ACTIVITY"
            return 0
        fi
    done
}

#===============================================================================
# TEST: Are the correct packages installed?
try_packages() {
    local ID=$1; shift
    local RELEASE=$1; shift
    local ACTIVITY=$1; shift
    local PKGLIST
    PKGLIST=$(list_sort "$@")
    # shellcheck disable=SC2086,SC2116
    debug 1 "try_packages: ID=$ID RELEASE=$RELEASE ACTIVITY=$(echo $ACTIVITY) PKGLIST="$PKGLIST

    #-------------------------------------------------------------------------------
    if [[ $ID =~ Debian|Kubuntu|LinuxMint|Mint|Ubuntu|Xubuntu ]] ; then
        # shellcheck disable=SC2086
        debinstall "$ACTIVITY" $PKGLIST || true
        # shellcheck disable=SC2086
        for_each_activity "run_extra_code $ID $RELEASE" $ACTIVITY

    #-------------------------------------------------------------------------------
    elif [[ $ID =~ CentOS|Fedora|RHEL ]] ; then
        PKGMGR=yum
        if [[ -e /bin/dnf || -e /usr/bin/dnf ]] ; then
            PKGMGR=dnf
        fi
        # shellcheck disable=SC2086
        rpminstall "$ACTIVITY" "$PKGMGR" $PKGLIST || true
        # shellcheck disable=SC2086
        for_each_activity "run_extra_code $ID $RELEASE" $ACTIVITY

    #-------------------------------------------------------------------------------
    elif [[ $ID =~ openSUSE|SLES ]] ; then
        # shellcheck disable=SC2086
        rpminstall "$ACTIVITY" zypper $PKGLIST || true
        # shellcheck disable=SC2086
        for_each_activity "run_extra_code $ID $RELEASE" $ACTIVITY

    #-------------------------------------------------------------------------------
    elif [[ $ID == "Arch" ]]  ; then
        # shellcheck disable=SC2086
        pacinstall "$ACTIVITY" $PKGLIST
        notice "Any AUR packages installed for this activity will need to be removed manually"
        # shellcheck disable=SC2086
        for_each_activity "run_extra_code $ID $RELEASE" $ACTIVITY

    #-------------------------------------------------------------------------------
    elif [[ $ID == "Gentoo" ]]  ; then
    # TODO: Add support for emerge here to provide similar functionality as apt-get code above
        warn "Currently there is no package support for Gentoo"
        # shellcheck disable=SC2086
        for_each_activity "run_extra_code $ID $RELEASE" $ACTIVITY
    fi
}

#===============================================================================
# Remove packages installed by this script
rm_packages() {
    local ID=$1; shift
    local RELEASE=$1; shift
    local ACTIVITY=$1; shift
    local PKGLIST
    # shellcheck disable=2086
    PKGLIST=$(read_installed $ACTIVITY)
    # shellcheck disable=SC2116,SC2086
    debug 1 "rm_packages: ID=$ID RELEASE=$RELEASE ACTIVITY=$(echo $ACTIVITY) PKGLIST="$PKGLIST

    # shellcheck disable=SC2116,SC2086
    warn_wait "About to remove: $(echo $PKGLIST)\nShould I continue?" || return 0

    #-------------------------------------------------------------------------------
    if [[ $ID =~ Debian|Kubuntu|LinuxMint|Mint|Ubuntu|Xubuntu ]] ; then
        # shellcheck disable=SC2086
        $DRYRUN sudo dpkg --purge $PKGLIST

    #-------------------------------------------------------------------------------
    elif [[ $ID =~ CentOS|Fedora|RHEL ]] ; then
        PKGMGR=yum
        if [[ -e /bin/dnf || -e /usr/bin/dnf ]] ; then
            PKGMGR=dnf
        fi
        # shellcheck disable=SC2086
        $DRYRUN sudo $PKGMGR remove $PKGLIST

    #-------------------------------------------------------------------------------
    elif [[ $ID =~ openSUSE|SLES ]] ; then
        # shellcheck disable=SC2086
        $DRYRUN sudo zypper remove $PKGLIST

    #-------------------------------------------------------------------------------
    elif [[ $ID == "Arch" ]]  ; then
        local ARCHLIST
        ARCHLIST=${PKGLIST/aur:/}
        # shellcheck disable=SC2086
        debug 2 "Removing Arch packages:" $PKGLIST
        # shellcheck disable=SC2086
        $DRYRUN sudo pacman -Rs $ARCHLIST

    #-------------------------------------------------------------------------------
    elif [[ $ID == "Gentoo" ]]  ; then
    # TODO: Add support for emerge here to provide similar functionality as apt-get code above
        warn "Currently there is no package support for Gentoo"
    fi

    clear_installed "$ACTIVITY"
}

#===============================================================================
if [[ -n $REMOVE ]] ; then
    rm_packages "$ID" "$RELEASE" "$COURSE"
    exit 0
fi


#===============================================================================
setup_meta() {
    local ACTIVITY=$1
    debug 1 "setup_meta: ACTIVITY=$ACTIVITY"

    local ATTR
    local ATTRS="ARCH BOGOMIPS CPUS PREFER_CPUS RAM DISK \
            INTERNET DISTROS DISTRO_BL DISTRO_ARCH"

    for ATTR in $ATTRS ; do
        eval "debug 2 \"  setup_meta(before): $ATTR=\${$ATTR:-} (\${$ATTR[$ACTIVITY]:-})\"
        case \${$ATTR:-} in
            [0-9]*) [[ \${$ATTR[$ACTIVITY]:-} -le \${$ATTR:-} ]] || $ATTR=\"\${$ATTR[$ACTIVITY]}\" ;;
            *)  if [[ \${$ATTR[$ACTIVITY]:-} == - ]] ; then
                    unset $ATTR[$ACTIVITY]
                    $ATTR=''
                elif [[ -n \${$ATTR[$ACTIVITY]:-} ]] ; then
                    $ATTR=\"\${$ATTR[$ACTIVITY]}\"
                fi ;;
        esac
        debug 2 \"  setup_meta(after): $ATTR=\${$ATTR:-} (\${$ATTR[$ACTIVITY]:-})\""
        if [[ ${ATTR:-} == DISTROS ]] ; then
            # shellcheck disable=SC2086
            DISTROS[$ACTIVITY]="$(fix_distro_alias ${DISTROS[$ACTIVITY]:-})"
        fi
    done
}

#===============================================================================
[[ -n $COURSE ]] || usage
# shellcheck disable=SC2086
debug 1 "main: Final classes: "$COURSE
# shellcheck disable=SC2086
for_each_activity setup_meta $COURSE

#===============================================================================
if [[ -n $CHECK_PKGS ]] ; then
    # shellcheck disable=SC2086
    debug 1 "Check Packages for "$COURSE
    PROGRESS=y
    # shellcheck disable=SC2086
    check_packages $COURSE
    exit 0
fi

#===============================================================================
if [[ -n $LIST_PKGS ]] ; then
    debug 1 "List Packages for $COURSE => $PKGS"
    # shellcheck disable=SC2086
    for_each_activity list_packages $COURSE | sort -k2
    exit 0
fi

#===============================================================================
# List information
list_entry() {
    local NAME=$1; shift
    [[ -z "$*" ]] || echo "    $NAME: $*"
}
list_array() {
    local NAME=$1; shift
    local WS=$1; shift
    local LIST=$*
    [[ -z $LIST ]] || echo "    $WS$NAME: $LIST"
}
#-------------------------------------------------------------------------------
# shellcheck disable=SC2086 
list_requirements() {
    local ACTIVITY=$*
    local A DISTS DIST
    [[ -z $ACTIVITY ]] || for_each_activity supported_activity "$ACTIVITY"
    # shellcheck disable=SC2086
    if [[ -n $ACTIVITY ]] ; then
        ACTIVITIES="$ACTIVITY"
    else
        ACTIVITIES=$(list_sort ${!TITLE[*]})
    fi
    debug 1 "list_requirements: ACTIVITY=$ACTIVITY ACTIVITIES=$ACTIVITIES"
    echo 'Courses:'
    for A in $ACTIVITIES; do
        echo "  $A:"
        list_entry TITLE "${TITLE[$A]}"
        list_entry WEBPAGE "${WEBPAGE[$A]:-}"
        list_entry INPERSON "${INPERSON[$A]:-}"
        list_entry VIRTUAL "${VIRTUAL[$A]:-}"
        list_entry SELFPACED "${SELFPACED[$A]:-}"
        list_entry EMBEDDED "${EMBEDDED[$A]:-}"
        list_entry MOOC "${MOOC[$A]:-}"
        list_entry INSTR_LED_CLASS "${INSTR_LED_CLASS[$A]:-}"
        list_entry SELFPACED_CLASS "${SELFPACED_CLASS[$A]:-}"
        list_entry PREREQ "${PREREQ[$A]:-}"
        list_entry OS "$(value OS $A)"
        list_entry OS_NEEDS "$(value OS_NEEDS $A)"
        list_entry ARCH "$(value ARCH $A)"
        list_entry CPUFLAGS "$(value CPUFLAGS $A)"
        list_entry CPUS "$(value CPUS $A)"
        list_entry PREFER_CPUS "$(value PREFER_CPUS $A)"
        list_entry BOGOMIPS "$(value BOGOMIPS $A)"
        list_entry RAM "$(value RAM $A)"
        list_entry DISK "$(value DISK $A)"
        list_entry BOOT "$(value BOOT $A)"
        list_entry CONFIGS "$(value CONFIGS $A)"
        list_entry INTERNET "$(value INTERNET $A)"
        list_entry SYMLINKS "$(value SYMLINKS $A)"
        list_entry VERSIONS "$(value VERSIONS $A)"
        list_entry INCLUDES "$(value INCLUDES $A)"
        list_entry CARDREADER "$(value CARDREADER $A)"
        list_entry NATIVELINUX "$(value NATIVELINUX $A)"
        list_entry VMOKAY "$(value VMOKAY $A)"
        list_entry DISTRO_ARCH "$(value DISTRO_ARCH $A)"
        list_entry DISTRO_DEFAULT "$(value DISTRO_DEFAULT $A)"
        list_array DISTROS "" "$(value DISTROS $A)"
        # shellcheck disable=SC2086
        list_array DISTRO_BL "" "$(value DISTRO_BL $A)"
        if [[ -z $DIST_LIST ]] ; then
            DISTS=$(distrib_list)
        else
            DISTS=$DIST_LIST
        fi
        # shellcheck disable=SC2086
        debug 2 "list_requirements: DISTS="$DISTS
        if [[ -n $DISTS ]] ; then
            echo '    PACKAGES:'
            for DIST in $DISTS; do
                local P
                # shellcheck disable=SC2086
                P=$(package_list ${DIST/-/ } $A)
                # shellcheck disable=SC2086
                debug 2 "list_requirements: package list =" $P
                # shellcheck disable=SC2086
                list_array "$DIST" "  " $P
            done
        fi
    done
}

#===============================================================================
if [[ -n $LIST_REQS ]] ; then
    debug 1 "List Requirements for $COURSE"
    # shellcheck disable=SC2086
    list_requirements $COURSE
    exit 0
fi


#===============================================================================
# shellcheck disable=SC2086
for_each_activity check_activity $ORIG_COURSE

#===============================================================================
# Check all the things
divider "Check"
cache_output "$COURSE" check_all

#===============================================================================
# Check package list
divider "Packages"
if [[ -n $INSTALL || -z $NOINSTALL ]] ; then
    check_sudo "$ID" "$RELEASE"
    check_repos "$ID" "$RELEASE" "$CODENAME" "$ARCH"
    # shellcheck disable=SC2086
    PKGLIST=$(for_each_activity "package_list $ID $RELEASE" $COURSE)
    # shellcheck disable=SC2086
    try_packages "$ID" "$RELEASE" "$COURSE" $PKGLIST
else
    notice "Not checking whether the appropriate packages are being installed"
fi


#===============================================================================
# Overall PASS/FAIL
divider "Result"
if [[ -n $FAILED ]] ; then
    warn "Your computer doesn't meet the stated requirements"
elif [[ -n $WARNINGS ]] ; then
    warn "Your computer doesn't meet the stated requirements unless you can fix the above warnings."
    if [[ -n $MISSING_PACKAGES ]] ; then
        warn "You also have some missing packages."
    fi
else
    pass "You are ready to go! W00t!"
fi


#===============================================================================
# Clean up and exit
clean_cache

notice "Make sure to follow the instructions above to fix any issues found"

exit 0

