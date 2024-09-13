#!/bin/bash

# Enable debugging if DEBUG is set to true
[ "${DEBUG:-false}" = true ] && set -x

# Exit on error, unset variables, and fail on pipe failures
set -euo pipefail

# Vars
# ----
: "${ARCHI_PROJECT_PATH:=${GITHUB_WORKSPACE:-${CI_PROJECT_DIR:-/archi/project}}}"
: "${ARCHI_REPORT_PATH:=/archi/report}"
: "${ARCHI_HTML_REPORT_ENABLED:=true}"
: "${ARCHI_JASPER_REPORT_ENABLED:=false}"
: "${ARCHI_JASPER_REPORT_FORMATS:=PDF,DOCX}"
: "${ARCHI_CSV_REPORT_ENABLED:=false}"
: "${ARCHI_EXPORT_MODEL_ENABLED:=true}"
: "${ARCHI_APP:=com.archimatetool.commandline.app}"
: "${GITHUB_SERVER_URL:=https://github.com}"
: "${GITHUB_PAGES_BRANCH:=gh-pages}"
: "${GIT_SUBTREE_PREFIX:=.archi_report}"

# Tools environments
declare -a _ssh_args=(
    -o BatchMode=yes
    -o UserKnownHostsFile=/dev/null
    -o StrictHostKeyChecking=no
)

GIT_SSH_COMMAND="ssh ${_ssh_args[*]}"
GIT_TERMINAL_PROMPT=0
DISPLAY=:1

export GIT_SSH_COMMAND GIT_TERMINAL_PROMPT DISPLAY

# Regex patterns
_re_url='([\w.@\:/~\-]+)(\.git)(\/)?'
_re_proto_http='(http(s)?(:(\/){0,3}))?'
_re_proto_ssh='((((git|user)@[\w.-]+)|(git|ssh))(:(\/){0,3}))'

# Functions
# ---------

# Run Archi
archi_run() {
    local -a _args=()

    # Html report
    if [ "${ARCHI_HTML_REPORT_ENABLED,,}" == true ]; then
        _args+=( --html.createReport "${ARCHI_HTML_REPORT_PATH:=$ARCHI_REPORT_PATH/html}" )
    fi

    # CSV report
    if [ "${ARCHI_CSV_REPORT_ENABLED,,}" == true ]; then
        _args+=( --csv.export "${ARCHI_CSV_REPORT_PATH:=$ARCHI_REPORT_PATH/csv}" )
    fi

    # Export model
    if [ "${ARCHI_EXPORT_MODEL_ENABLED,,}" == true ]; then
        _args+=( --saveModel "${ARCHI_EXPORT_MODEL_PATH:=$ARCHI_REPORT_PATH}/$_project.archimate" )
    fi

    # Jasper report
    if [ "${ARCHI_JASPER_REPORT_ENABLED,,}" == true ]; then
        _args+=( --jasper.createReport "${ARCHI_JASPER_REPORT_PATH:=$ARCHI_REPORT_PATH/jasper}" )
        _args+=( --jasper.format "$ARCHI_JASPER_REPORT_FORMATS" )
        _args+=( --jasper.filename "$_project" )
        _args+=( --jasper.title "${ARCHI_JASPER_REPORT_TITLE:=$_project}" )
    fi

    # Run Archi
    xvfb-run /opt/Archi/Archi -application "$ARCHI_APP" -consoleLog -nosplash \
        --modelrepository.loadModel "$ARCHI_PROJECT_PATH" "${_args[@]}"

    printf '\n%s\n\n' "Done. Reports saved to $ARCHI_REPORT_PATH"
}

# Check if first argument matches regex present in second argument
re_match() {
    local value="${1:-}" regex="${2:-.*}"
    if [ -n "$value" ] && grep -Pq "$regex" <<<"$value"; then
        return 0
    fi
    return 1
}

# Encode URL symbols
urlencode() {
    local LC_COLLATE=C length="${#1}"
    for ((i = 0; i < length; i++)); do
        local c="${1:$i:1}"
        case $c in
            [a-zA-Z0-9.~_-]) printf '%s' "$c" ;;
            *) printf '%%%02X' "'$c" ;;
        esac
    done
}

update_html() {
    if [ "${ARCHI_CSV_REPORT_ENABLED,,}" == true ]; then
        for item in {elements,properties,relations}; do
            _li="
            <!-- Update logic for $item goes here -->
            "
            # Add your logic to process each item here
        done
    fi
}
