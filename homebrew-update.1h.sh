#!/usr/bin/env bash

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
SCRIPT_NAME=$(basename "$0")
ASSETS_DIR=${SCRIPT_DIR}/homebrew-update/assets
MAX_LOG_HISTORY=10000
IGNORE_FILE=${ASSETS_DIR}/brew-upgrade-ignore.json
LOG_FILE=${ASSETS_DIR}/brew-upgrade.log
ERR_FILE=${ASSETS_DIR}/brew-upgrade.errors
if [[ -f "${ASSETS_DIR}/.term" ]]; then
    TERM=true
else
    TERM=false
fi


# Create an empty ignore file if it doesn't exist
if [[ ! -f "${IGNORE_FILE}" ]]; then
    echo '{"casks": [], "formulae": []}' > "${IGNORE_FILE}"
fi

export HOMEBREW_CASK_OPTS=--no-quarantine

add_date() {
    while IFS= read -r line; do
        printf '%s %s\n' "$(date '+%d.%m.%Y-%M:%H:%S')" "$line";
    done
}

# Logrotate after MAX_LOG_HISTORY number of lines
if [[ $(wc -l <"${LOG_FILE}") -ge ${MAX_LOG_HISTORY} ]]; then
    tail -n${MAX_LOG_HISTORY} "${LOG_FILE}" > "${LOG_FILE}"
fi

if [ -f /opt/homebrew/bin/brew ]; then
    HOMEBREW_BIN=/opt/homebrew/bin
else
    if [ -f /usr/local/bin/brew ]; then
        HOMEBREW_BIN=/usr/local/bin
    else
        if [ -f $HOME/.local/opt/homebrew/bin/brew ]; then
            HOMEBREW_BIN=$HOME/.local/opt/homebrew/bin
        else
            echo "Failed!"
            echo "---"
            echo "Homebrew not found in /opt/homebrew/bin, /usr/local/bin or ~/.local/opt/homebrew/bin!"
            exit
        fi
    fi
fi

PATH="${HOMEBREW_BIN}:${PATH}"

brew update >> /dev/null 2>&1

outdated="$(brew outdated --greedy-auto-updates --json)"

ignore_formulae=$(jq -r '.formulae[]' "${IGNORE_FILE}")
ignore_casks=$(jq -r '.casks[]' "${IGNORE_FILE}")

# Filter out ignored formulae
formulae=$(echo "${outdated}" | jq '.formulae.[].name' -r | while read -r formula; do
    echo "${ignore_formulae}" | grep -q "${formula}" || echo "${formula}"
done | xargs)

# Filter out ignored casks
casks=$(echo "${outdated}" | jq '.casks.[].name' -r | while read -r cask; do
    echo "${ignore_casks}" | grep -q "${cask}" || echo "${cask}"
done | xargs)

count_formulae=$(echo ${formulae} | wc -w | xargs)
count_casks=$(echo ${casks} | wc -w | xargs)

count_all=$((count_formulae + count_casks))

count_ignore_formulae=$(echo ${ignore_formulae} | wc -w | xargs)
count_ignore_casks=$(echo ${ignore_casks} | wc -w | xargs)

count_ignore_all=$((count_ignore_casks + count_ignore_formulae))

icon=$(base64 -i "${ASSETS_DIR}/icon.png")
icon_attention=$(base64 -i "${ASSETS_DIR}/icon_attention.png")
icon_updating=$(base64 -i "${ASSETS_DIR}/icon_updating.png")

if [ $# -eq 0 ]; then
    if [[ -f "${ASSETS_DIR}/.updating" ]]; then
        echo " | templateImage=${icon_updating}"
    else
        if [[ "${count_all}" != "0" ]]; then
            echo " | templateImage=${icon_attention}"
        else
            echo " | templateImage=${icon}"
        fi
    fi
    echo "---"
    if [[ -f "${ERR_FILE}" ]]; then
        if [[ ! -s "${ERR_FILE}" ]]; then
            # Delete File if empty
            rm -rf "${ERR_FILE}"
        else
            echo "Errors while upgrading: | color=#D92519"
            errors=$(cat "${ERR_FILE}")
            for err_pkg in ${errors}; do
                echo "- ${err_pkg}"
                echo "--Show log | bash=/usr/bin/open param1='${LOG_FILE}' terminal=false refresh=true"
                echo "--Reinstall | bash='${SCRIPT_DIR}/${SCRIPT_NAME}' param1=reinstall param2=${err_pkg} terminal=true refresh=true"
                echo "--Uninstall | bash='${SCRIPT_DIR}/${SCRIPT_NAME}' param1=uninstall param2=${err_pkg} terminal=true refresh=true"
            done
            echo "Clear Errors | color=#68696C | bash=rm param1=-rf param2='${ERR_FILE}' terminal=false refresh=true"
            echo "---"
        fi
    fi
    if [[ "${count_all}" != "0" ]]; then
        if [[ "${count_formulae}" != "0" ]]; then
            ident=''
            if [[ "${count_formulae}" -gt 5 ]]; then
                ident='--'
                echo "${count_formulae} Formulae can be update"
            fi
            for line in ${formulae}; do
                echo "${ident}${line}" | grep "[a-z]" | sed "s_${ident}\(.*\)_& | bash='${SCRIPT_DIR}/${SCRIPT_NAME}' param1=upgrade param2=--cask param3=\1 terminal=${TERM} refresh=true_g"
            done
            if [[ "${count_formulae}" -gt 1 ]]; then
                echo "Brew Upgrade All Formulae | bash='${SCRIPT_DIR}/${SCRIPT_NAME}' param1=upgrade-all-formulae terminal=${TERM} refresh=true"
            fi
        fi
        if [[ "${count_formulae}" == "0" ]]; then
            echo "Formulae are up to date!"
        fi
        echo "---"
        if [[ "${count_casks}" != "0" ]]; then
            ident=''
            if [[ "${count_casks}" -gt 5 ]]; then
                ident='--'
                echo "${count_casks} Casks can be update"
            fi
            for line in ${casks}; do
                echo "${ident}${line}" | grep "[a-z]" | sed "s_${ident}\(.*\)_& | bash='${SCRIPT_DIR}/${SCRIPT_NAME}' param1=upgrade param2=--cask param3=\1 terminal=${TERM} refresh=true_g"
            done
            if [[ "${count_casks}" -gt 1 ]]; then
                echo "Brew Upgrade All Casks | bash='${SCRIPT_DIR}/${SCRIPT_NAME}' param1=upgrade-all-casks terminal=${TERM} refresh=true"
            fi
        fi
        if [[ "${count_casks}" == "0" ]]; then
            echo "Casks are up to date!"
        fi
        echo "---"
        echo "Brew Upgrade All | bash='${SCRIPT_DIR}/${SCRIPT_NAME}' param1=upgrade-all terminal=${TERM} refresh=true"
        echo "Add to ignore list"
        for line in ${formulae}; do
            echo "--${line} | bash='${SCRIPT_DIR}/${SCRIPT_NAME}' param1=ignore param2=formulae param3=${line} terminal=false refresh=true"
        done
        for line in ${casks}; do
            echo "--${line} | bash='${SCRIPT_DIR}/${SCRIPT_NAME}' param1=ignore param2=casks param3=${line} terminal=false refresh=true"
        done
        if [[ "${count_ignore_all}" != "0" ]]; then
            echo "Open Ignore List | bash=/usr/bin/open param1='${IGNORE_FILE}' terminal=false refresh=true"
        fi
    else
        echo "Everthing is up to date!"
        echo "---"
    fi
    echo "Brew Cleanup | bash='${SCRIPT_DIR}/${SCRIPT_NAME}' param1=cleanup terminal=${TERM} refresh=true"
    echo "---"
    if [[ ${TERM} == 'true' ]]; then
        echo "Hide Terminal | bash='rm' param1=${ASSETS_DIR}/.term terminal=false refresh=true"
    else
        echo "Show Terminal | bash='touch' param1=${ASSETS_DIR}/.term terminal=false refresh=true"
    fi
    echo "---"
    echo "Refresh | refresh=true"
else
    nohup caffeinate -dism -w $$ >/dev/null 2>&1 &
    if [ "$#" -eq 3 ] && [ ${1} == 'upgrade' ]; then
        echo "Starting brew upgrade ${2} ${3}" | add_date | tee -a "${LOG_FILE}"
        touch "${ASSETS_DIR}/.updating"
        /usr/bin/open --background xbar://app.xbarapp.com/refreshPlugin?path=${SCRIPT_NAME}
        sleep 1
        brew upgrade ${2} ${3} 2>&1 | add_date | tee -a "${LOG_FILE}"
        cat "${LOG_FILE}" | sed '1,/Error:/d' | grep -E '^[a-zA-Z0-9_\-]+:' | awk -F ":" '{print $1}' > "${ERR_FILE}"
        sleep 1
        /usr/bin/open --background xbar://app.xbarapp.com/refreshPlugin?path=${SCRIPT_NAME}
        echo "Finished brew upgrade ${2} ${3}" | add_date | tee -a "${LOG_FILE}"
    fi
    if [ "$#" -eq 3 ] && [ "${1}" == 'ignore' ]; then
        ignore_type="${2}"
        ignore_item="${3}"
        jq --arg item "${ignore_item}" --arg ignore_type "${ignore_type}" '.[$ignore_type] += [$item]' "${IGNORE_FILE}" | jq '.' --indent 4 > "${IGNORE_FILE}.tmp" && mv "${IGNORE_FILE}.tmp" "${IGNORE_FILE}"
        echo "Ignored ${ignore_item} in ${ignore_type}" | add_date | tee -a "${LOG_FILE}"
        /usr/bin/open --background xbar://app.xbarapp.com/refreshPlugin?path=${SCRIPT_NAME}
        sleep 1
    fi
    if [ "$#" -eq 2 ] && [ ${1} == 'reinstall' ]; then
        echo "Starting brew reinstall ${2}" | add_date | tee -a "${LOG_FILE}"
        brew reinstall ${2} 2>&1
        cat "${ERR_FILE}" | grep -v ${2} > "${ERR_FILE}"
        sleep 1
        /usr/bin/open --background xbar://app.xbarapp.com/refreshPlugin?path=${SCRIPT_NAME}
        echo "Finished brew reinstall ${2}" | add_date | tee -a "${LOG_FILE}"
    fi
    if [ "$#" -eq 2 ] && [ ${1} == 'uninstall' ]; then
        echo "Starting brew uninstall ${2}" | add_date | tee -a "${LOG_FILE}"
        brew uninstall ${2} 2>&1
        cat "${ERR_FILE}" | grep -v ${2} > "${ERR_FILE}"
        sleep 1
        /usr/bin/open --background xbar://app.xbarapp.com/refreshPlugin?path=${SCRIPT_NAME}
        echo "Finished brew uninstall ${2}" | add_date | tee -a "${LOG_FILE}"
    fi
    if [ "$#" -eq 1 ]; then
        if [[ ${1} == 'upgrade-all' ]]; then
            echo "Starting brew upgrade --greedy-auto-updates" | add_date | tee -a "${LOG_FILE}"
            touch "${ASSETS_DIR}/.updating"
            /usr/bin/open --background xbar://app.xbarapp.com/refreshPlugin?path=${SCRIPT_NAME}
            sleep 1
            brew upgrade --greedy-auto-updates 2>&1 | add_date | tee -a "${LOG_FILE}"
            errors=$(cat "${LOG_FILE}" | sed '1,/Error:/d' | grep -E '^[a-zA-Z0-9_\-]+:' | awk -F ":" '{print $1}')
            if [[ $errors ]]; then
                echo "$errors" > "${ERR_FILE}"
            fi
            sleep 1
            rm "${ASSETS_DIR}/.updating"
            /usr/bin/open --background xbar://app.xbarapp.com/refreshPlugin?path=${SCRIPT_NAME}
            echo "Finished brew upgrade --greedy-auto-updates" | add_date | tee -a "${LOG_FILE}"
        fi
        if [[ ${1} == 'cleanup' ]]; then
            echo "Starting brew cleanup" | add_date | tee -a "${LOG_FILE}"
            brew cleanup
            echo "Finished brew cleanup" | add_date | tee -a "${LOG_FILE}"
        fi
    fi
fi
