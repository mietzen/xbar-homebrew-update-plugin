#!/usr/bin/env bash

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
SCRIPT_NAME=$(basename "$0")
ASSESTS_DIR=${SCRIPT_DIR}/homebrew-update/assests

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

brew update --auto-update --quiet 2>&1 >/dev/null

formulae=$(brew install --dry-run --formulae --quiet $(brew list --formulae) 2>/dev/null | sed -e '1,/==> Would install/d' | tr " " "\n")
casks=$(brew install --dry-run --casks --quiet $(brew list --casks) 2>/dev/null | sed -e '1,/==> Would install/d' | tr " " "\n")

count_formulae=$(echo ${formulae} | wc -w | xargs)
count_casks=$(echo ${cask} | wc -w | xargs)

count_all=$((count_formulae + count_casks))

icon=$(base64 -i ${ASSESTS_DIR}/icon.png)
icon_attention=$(base64 -i ${ASSESTS_DIR}/icon_attention.png)

if [ $# -eq 0 ]; then
    if [[ "${count_all}" != "0" ]]; then
        echo " | templateImage=${icon_attention}"
        if [ -f ${ASSESTS_DIR}/.notify ]; then
            ${ASSESTS_DIR}/notifier.app/Contents/MacOS/applet
        fi
    else
        echo " | templateImage=${icon}"
    fi
    echo "---"
    if [[ "${count_formulae}" != "0" ]]; then
        for line in ${formulae}; do
            echo "${line}" | grep "[a-z]" | sed 's_\(.*\)_& | bash=brew param1=install param2=--formula param3=& param4=\&\& param5=exit terminal=true refresh=true_g'
        done
    fi
    if [[ "${count_formulae}" == "0" ]]; then
        echo "No formulae to update"
    fi
    echo "---"
    if [[ "${count_casks}" != "0" ]]; then
        for line in ${casks}; do
            echo "${line}" | grep "[a-z]" | sed 's_\(.*\)_& | bash=brew param1=install param2=--cask param3=& param4=\&\& param5=exit terminal=true refresh=true_g'
        done
    fi
    if [[ "${count_casks}" == "0" ]]; then
        echo "No casks to update"
    fi
    echo "---"
    if [[ "${count_all}" != "0" ]]; then
        echo "Brew Upgrade All | bash=${SCRIPT_DIR}/${SCRIPT_NAME} param1=upgrade param2=&& param3=exit terminal=true refresh=true"
    fi
    echo "Brew Cleanup | bash=${SCRIPT_DIR}/${SCRIPT_NAME} param1=cleanup param2=&& param3=exit terminal=true refresh=true"
    echo "---"
    if [ -f ${ASSESTS_DIR}/.notify ]; then
        echo "Disable Notification  | bash=rm param1=-f param2=${ASSESTS_DIR}/.notify terminal=false refresh=true"
    else
        echo "Enable Notification | bash=touch param1=${ASSESTS_DIR}/.notify terminal=false refresh=true"
    fi
    echo "---"
    echo "Refresh | refresh=true"
else
    if [[ ${1} == 'upgrade' ]]; then
        if [[ "${count_formulae}" != "0" ]]; then
            brew upgrade --formulae ${formulae}
        fi
        if [[ "${count_casks}" != "0" ]]; then
            brew upgrade --casks ${casks}
        fi
        /usr/bin/open --background xbar://app.xbarapp.com/refreshPlugin?path=${SCRIPT_NAME}
    fi
    if [[ ${1} == 'cleanup' ]]; then
        brew cleanup --formulae
        brew cleanup --casks
    fi
fi
