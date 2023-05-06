#!/usr/bin/env bash

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
SCRIPT_NAME=$(basename "$0")
ASSETS_DIR=${SCRIPT_DIR}/homebrew-update/assets

if [ -f /opt/homebrew/bin/brew ]; then
    HOMEBREW_BIN=/opt/homebrew/bin/brew
else
    if [ -f /usr/local/bin/brew ]; then
        HOMEBREW_BIN=/usr/local/bin/brew 
    else
        echo "Failed!"
        echo "---"
        echo "Homebrew not found in /opt/homebrew/bin/brew or /usr/local/bin/brew!"
        exit
    fi
fi

brew (){
    ${HOMEBREW_BIN} $@
}

brew update >> /dev/null 2>&1

formulae=$(brew upgrade --dry-run --formulae --quiet $(brew list --formulae) 2>/dev/null | grep -e "^[a-z].*" | cut -d' ' -f1 | sort -n | uniq)
casks=$(brew upgrade --dry-run --casks --quiet $(brew list --casks) 2>/dev/null | grep -e "^[a-z].*" | cut -d' ' -f1 | sort -n | uniq)

count_formulae=$(echo ${formulae} | wc -w | xargs)
count_casks=$(echo ${casks} | wc -w | xargs)

count_all=$((count_formulae + count_casks))

if [ -f ${ASSETS_DIR}/.darkmode ]; then
    icon=$(base64 -i ${ASSETS_DIR}/icon_dark.png)
    icon_attention=$(base64 -i ${ASSETS_DIR}/icon_attention_dark.png)
else
    icon=$(base64 -i ${ASSETS_DIR}/icon.png)
    icon_attention=$(base64 -i ${ASSETS_DIR}/icon_attention.png)
fi

if [ $# -eq 0 ]; then
    if [[ "${count_all}" != "0" ]]; then
        echo " | templateImage=${icon_attention}"
        if [ -f ${ASSETS_DIR}/.notify ]; then
            ${ASSETS_DIR}/notifier.app/Contents/MacOS/applet
        fi
    else
        echo " | templateImage=${icon}"
    fi
    echo "---"
    if [[ "${count_all}" != "0" ]]; then
        if [[ "${count_formulae}" != "0" ]]; then
            ident=''
            if [[ "${count_formulae}" -gt 5 ]]; then
                ident='--'
                echo "${count_formulae} Formulae can be update"
            fi
            for line in ${formulae}; do
                echo "${ident}${line}" | grep "[a-z]" | sed "s_\(.*\)_& | bash=${SCRIPT_DIR}/${SCRIPT_NAME} param1=upgrade param2=--formula param3=& param4=\&\& param5=exit terminal=true refresh=true_g"
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
                echo "${ident}${line}" | grep "[a-z]" | sed "s_\(.*\)_& | bash=${SCRIPT_DIR}/${SCRIPT_NAME} param1=upgrade param2=--cask param3=& param4=\&\& param5=exit terminal=true refresh=true_g"
            done
        fi
        if [[ "${count_casks}" == "0" ]]; then
            echo "Casks are up to date!"
        fi
        echo "---"
        echo "Brew Upgrade All | bash=${SCRIPT_DIR}/${SCRIPT_NAME} param1=upgrade-all param2=&& param3=exit terminal=true refresh=true"
    else
        echo "Everthing is up to date!"
        echo "---"
    fi
    echo "Brew Cleanup | bash=${SCRIPT_DIR}/${SCRIPT_NAME} param1=cleanup param2=&& param3=exit terminal=true refresh=true"
    echo "---"
    echo "Settings"
    if [ -f ${ASSETS_DIR}/.notify ]; then
        echo "-- Disable Notification  | bash=rm param1=-f param2=${ASSETS_DIR}/.notify terminal=false refresh=true"
    else
        echo "-- Enable Notification | bash=touch param1=${ASSETS_DIR}/.notify terminal=false refresh=true"
    fi
    if [ -f ${ASSETS_DIR}/.darkmode ]; then
        echo "-- Lightmode | bash=rm param1=-f param2=${ASSETS_DIR}/.darkmode terminal=false refresh=true"
    else
        echo "-- Darkmode | bash=touch param1=${ASSETS_DIR}/.darkmode terminal=false refresh=true"
    fi
    echo "---"
    echo "Refresh | refresh=true"
else
    if [ "$#" -eq 3 ] && [ ${1} == 'upgrade' ]; then
        brew upgrade ${2} ${3}
        sleep 1
        /usr/bin/open --background xbar://app.xbarapp.com/refreshPlugin?path=${SCRIPT_NAME}
    fi
    if [ "$#" -eq 1 ]; then
        if [[ ${1} == 'upgrade-all' ]]; then
            if [[ "${count_formulae}" != "0" ]]; then
                brew upgrade --formulae ${formulae}
            fi
            if [[ "${count_casks}" != "0" ]]; then
                brew upgrade --casks ${casks}
            fi
            sleep 1
            /usr/bin/open --background xbar://app.xbarapp.com/refreshPlugin?path=${SCRIPT_NAME}
        fi
        if [[ ${1} == 'cleanup' ]]; then
            brew cleanup --formulae
            brew cleanup --casks
        fi
    fi
fi
