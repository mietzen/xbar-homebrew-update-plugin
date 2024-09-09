#!/usr/bin/env bash

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
SCRIPT_NAME=$(basename "$0")
ASSETS_DIR="${SCRIPT_DIR}/homebrew-update/assets"

export HOMEBREW_CASK_OPTS=--no-quarantine

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
formulae=$(echo "${outdated}" | jq '.formulae.[].name' -r | xargs)
casks=$(echo "${outdated}" | jq '.casks.[].name' -r | xargs)

count_formulae=$(echo ${formulae} | wc -w | xargs)
count_casks=$(echo ${casks} | wc -w | xargs)

count_all=$((count_formulae + count_casks))

icon=$(base64 -i "${ASSETS_DIR}/icon.png")
icon_attention=$(base64 -i "${ASSETS_DIR}/icon_attention.png")

if [ $# -eq 0 ]; then
    if [[ "${count_all}" != "0" ]]; then
        echo " | templateImage=${icon_attention}"
    else
        echo " | templateImage=${icon}"
    fi
    echo "---"
    if [[ -f "${ASSETS_DIR}/.errors" ]]; then
        echo "Errors while upgrading: | color=red"
        errors=$(cat "${ASSETS_DIR}/.errors")
        for err_pkg in ${errors}; do
            echo "- ${err_pkg}"
            echo "--Show log | bash=less param1='${ASSETS_DIR}/.log' terminal=true refresh=true"
            echo "--Reinstall | bash='${SCRIPT_DIR}/${SCRIPT_NAME}' param1=reinstall param2=${err_pkg} terminal=true refresh=true"
            echo "--Uninstall | bash='${SCRIPT_DIR}/${SCRIPT_NAME}' param1=uninstall param2=${err_pkg} terminal=true refresh=true"
        done
        echo "Clear Errors | color=#68696C | bash=rm param1=-rf param2='${ASSETS_DIR}/.errors' terminal=false refresh=true"
        echo "---"
    fi
    if [[ "${count_all}" != "0" ]]; then
        if [[ "${count_formulae}" != "0" ]]; then
            ident=''
            if [[ "${count_formulae}" -gt 5 ]]; then
                ident='--'
                echo "${count_formulae} Formulae can be update"
            fi
            for line in ${formulae}; do
                echo "${ident}${line}" | grep "[a-z]" | sed "s_\(.*\)_& | bash='${SCRIPT_DIR}/${SCRIPT_NAME}' param1=upgrade param2=--formula param3=& param4=\&\& param5=killall param6=Terminal terminal=true refresh=true_g"
            done
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
                echo "${ident}${line}" | grep "[a-z]" | sed "s_\(.*\)_& | bash='${SCRIPT_DIR}/${SCRIPT_NAME}' param1=upgrade param2=--cask param3=& param4=\&\& param5=killall param6=Terminal terminal=true refresh=true_g"
            done
        fi
        if [[ "${count_casks}" == "0" ]]; then
            echo "Casks are up to date!"
        fi
        echo "---"
        echo "Brew Upgrade All | bash='${SCRIPT_DIR}/${SCRIPT_NAME}' param1=upgrade-all param2=&& param3=killall param4=Terminal terminal=true refresh=true"
    else
        echo "Everthing is up to date!"
        echo "---"
    fi
    echo "Brew Cleanup | bash='${SCRIPT_DIR}/${SCRIPT_NAME}' param1=cleanup param2=&& param3=killall param4=Terminal terminal=true refresh=true"
    echo "---"
    echo "Refresh | refresh=true"
else
    if [ "$#" -eq 3 ] && [ ${1} == 'upgrade' ]; then
        brew upgrade ${2} ${3} 2>&1 | tee "${ASSETS_DIR}/.log"
        cat "${ASSETS_DIR}/.log" | sed '1,/Error:/d' | grep -E '^[a-zA-Z0-9_\-]+:' | awk -F ":" '{print $1}' > "${ASSETS_DIR}/.errors"
        sleep 1
        /usr/bin/open --background xbar://app.xbarapp.com/refreshPlugin?path=${SCRIPT_NAME}
    fi
    if [ "$#" -eq 2 ] && [ ${1} == 'reinstall' ]; then
        brew reinstall ${2} 2>&1
        cat "${ASSETS_DIR}/.errors" | grep -v ${2} > "${ASSETS_DIR}/.errors"
        sleep 1
        /usr/bin/open --background xbar://app.xbarapp.com/refreshPlugin?path=${SCRIPT_NAME}
    fi
    if [ "$#" -eq 2 ] && [ ${1} == 'uninstall' ]; then
        brew uninstall ${2} 2>&1
        cat "${ASSETS_DIR}/.errors" | grep -v ${2} > "${ASSETS_DIR}/.errors"
        sleep 1
        /usr/bin/open --background xbar://app.xbarapp.com/refreshPlugin?path=${SCRIPT_NAME}
    fi
    if [ "$#" -eq 1 ]; then
        if [[ ${1} == 'upgrade-all' ]]; then
            brew upgrade --greedy-auto-updates 2>&1 | tee "${ASSETS_DIR}/.log"
            cat "${ASSETS_DIR}/.log" | sed '1,/Error:/d' | grep -E '^[a-zA-Z0-9_\-]+:' | awk -F ":" '{print $1}' > "${ASSETS_DIR}/.errors"
            sleep 1
            /usr/bin/open --background xbar://app.xbarapp.com/refreshPlugin?path=${SCRIPT_NAME}
        fi
        if [[ ${1} == 'cleanup' ]]; then
            brew cleanup
        fi
    fi
fi
