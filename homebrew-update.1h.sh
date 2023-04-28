#!/opt/homebrew/bin/bash

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
SCRIPT_NAME=$(basename "$0")

brew (){
    /opt/homebrew/bin/brew $@
}

brew update 2>&1 >/dev/null

formulae=$(brew install --dry-run --formulae --quiet $(brew list --formulae) 2>/dev/null | sed -e '1,/==> Would install/d' | tr " " "\n")
casks=$(brew install --dry-run --casks --quiet $(brew list --casks) 2>/dev/null | sed -e '1,/==> Would install/d' | tr " " "\n")

count_formulae=0
count_casks=0

count_formulae=$(echo $formulae | wc -w | xargs)
count_casks=$(echo $cask | wc -w | xargs)

count_all=$((count_formulae + count_casks))

icon=$(base64 -i ${SCRIPT_DIR}/homebrew-update/icon.png)
icon_attention=$(base64 -i ${SCRIPT_DIR}/homebrew-update/icon_attention.png)

if [ $# -eq 0 ]; then
    if [[ "${count_all}" != "0" ]]; then
        echo " | templateImage=${icon_attention}"
    else
        echo " | templateImage=${icon}"
    fi
    echo "---"
    if [[ "${count_formulae}" != "0" ]]; then
        for line in $formulae; do 
            echo "$line" | grep "[a-z]" | sed 's_\(.*\)_& | bash=brew param1=install param2=--formula param3=& param4=\&\& param5=exit terminal=true refresh=true_g'
        done
    fi
    if [[ "${count_formulae}" == "0" ]]; then
        echo "No formulae to update"
    fi
    echo "---"
    if [[ "${count_casks}" != "0" ]]; then
        for line in $casks; do 
            echo "$line" | grep "[a-z]" | sed 's_\(.*\)_& | bash=brew param1=install param2=--cask param3=& param4=\&\& param5=exit terminal=true refresh=true_g'
        done
    fi
    if [[ "${count_casks}" == "0" ]]; then
        echo "No casks to update"
    fi
    echo "---"
    echo "Brew Upgrade All | bash=${SCRIPT_DIR}/${SCRIPT_NAME} param1=upgrade param2=&& param3=exit terminal=true refresh=true"
    echo "Brew Cleanup | bash=${SCRIPT_DIR}/${SCRIPT_NAME} param1=cleanup param2=&& param3=exit terminal=true refresh=true"
    echo "---"
    echo "Refresh | refresh=true"
else
    if [[ $1 == 'upgrade' ]]; then
        if [[ "${count_formulae}" != "0" ]]; then
            brew upgrade --formulae ${formulae}
        fi
        if [[ "${count_casks}" != "0" ]]; then
            brew upgrade --casks ${casks}
        fi
        /usr/bin/open --background xbar://app.xbarapp.com/refreshPlugin?path=${SCRIPT_NAME}
    fi
    if [[ $1 == 'cleanup' ]]; then
        brew cleanup --formulae
        brew cleanup --casks
    fi
fi
