#! /bin/bash
## Minecraft 7 Command-line Manager
## A Script tool designed to manage multiple minecraft server instances conviniently

## To use this script, you need at least JRE, GNU/screen, SSH up and running
## To safely login to another server and run minecraft server instance there, you also
## need an account

## Initialization check

## global variables

VERSION="0.0.1"
UPDATE_DATE="2020/06/27"
PATH_SCRIPT=$(readlink -f "$0")
PATH_DIRECTORY=$(dirname $PATH_SCRIPT)
# Clear all variables
## Global tmp
TMP=''
## Preferences
# PRE_SKIP_STARTUP_CHECK=0
# PRE_HIDE_PRIVATE_KEY=0
# PRE_DOWNLOAD_METHOD=0
# PRE_

## Environment related
## JAR related
JAR_NAME=''
JAR_TAG=''
JAR_TYPE=''
JAR_VERSION=''
JAR_VERSION_MC=''
JAR_PROXY=0
JAR_BUILDTOOL=0
JAR_SIZE=0
## ACCOUNT related
ACCOUNT_NAME=''
ACCOUNT_HOST=''
ACCOUNT_PORT=''
ACCOUNT_USER=''
ACCOUNT_KEY=''
ACCOUNT_VALID=0
## SERVER related
SERVER_ACCOUNT=''
SERVER_JAR=''
SERVER_DIRECTORY=''
SERVER_RAM_MIN=''
SERVER_RAM_MAX=''
# ### Minor JAR related 
# LINK=''
# REGEX=''
# PATH=''
## ACCOUNT related

print_draw_line() {
    if [[ -z "$1" || ${#1} > 1 ]]; then
        local SYMBOL=-
    else
        local SYMBOL=$1
    fi
    local LENGTH=`stty size|awk '{print $2}'`
    if [[ "$2" =~ ^[0-9]+$ && $2 -le $LENGTH ]]; then
        LENGTH=$2
    fi
    local i
    for i in $(seq 1 $LENGTH); do
        printf "$SYMBOL"
    done
    if [[ -z "$3" || "$3" = 0 ]]; then
        echo
    fi
    return 0
} ## Usage: print_draw_line [symbol] [length] [not break]
print_center() {
    local EMPTY=$(($((`stty size|awk '{print $2}'` - ${#1})) / 2))
    if [[ -z "$2" || ${#2} > 1 ]]; then
        print_draw_line ' ' "$EMPTY" 1
    else
        print_draw_line "$2" "$EMPTY" 1
    fi
    printf "\e[1m"
    printf "$1"
    printf "\e[0m"
    if [[ -z "$3" || ${#3} > 1 ]]; then
        print_draw_line ' ' "$EMPTY"
    else
        print_draw_line "$3" "$EMPTY"
    fi
    return 0
} ## Usage: print_center [string] [left symbol] [right symbol]
print_notification() {
    case $1 in 
    0)
        printf '\e[42m\e[1mNOTICE\e[0m: '
        ;;
    1)
        printf '\e[44m\e[1mINFO\e[0m: '
        ;;
    2)
        printf '\e[43m\e[1mWARNING\e[0m: '
        ;;
    3)
        printf '\e[45m\e[1mERROR\e[0m: '
        ;;
    4)
        printf '\e[41m\e[1mFATAL\e[0m: '
        echo -e "\e[100m${@:2}\e[0m"
        echo 'M7CM exiting...'
        exit
        ;;
    esac
    echo -e "\e[100m${@:2}\e[0m"
    return 0
} ## Usage: print_notification [level] [notification]
print_counting() {
    local i
    local j
    for i in $(seq "$1" -1 1); do
        if [[ "$2" || "$2" = 0 ]]; then
            printf "\r\e[1m\e[5m$2\e[0m: "
        else
            printf '\r\e[1m\e[5mATTENTION\e[0m: '
        fi
        if [[ "$3" ]]; then
            echo -e "${@:3}\c"
        else
            printf 'Refreshing'
        fi
        printf " in $i seconds"
        for j in $(seq 1 $(( $1 - $i + 1 ))); do
            printf '.'
        done
        sleep 1
    done
    echo
} ## Usage: print_counting_counting [second] [title] [content]
print_multilayer_menu() {
    local TMP=''
    if [[ "$3" =~ ^[0-9]+$ && $3 -ge 0 ]]; then
        local LAYER="$3"
    else
        local LAYER='1'
    fi
    for i in $(seq 1 $LAYER); do
        printf "  "
        local CURRENT=`eval echo '$'$(( $i + 4 ))` 
        if [[ -z "$CURRENT" || "$CURRENT" = 0 ]]; then
            if [[ $LAYER = $i ]]; then ## Draw > for current layer
                if [[ -z "$4" || "$4" = 0 ]]; then
                    printf "┣> "
                else
                    printf "┗> " ##Draw L if ends
                fi
            else
                printf "┃"
            fi
        else
            printf " " ##Do not draw | for closed layer
        fi
    done
    printf "\e[1m$1\e[0m " ## Print title
    echo -e "\e[100m$2\e[0m" ## Print content
    return 0
} ## Usage: print_multilayer_menu [title] [content] [layer] [end] [no layer1] [no layer2] [...]
print_info_jar() {
    if [[ "$1" ]]; then
        local JAR_NAME="$1"
        utility_jar_name_fix
    fi
    if [[ -z "$2" || "$2" = 0 ]]; then
        config_read_jar
        if [[ $? != 0 ]]; then
            return 1
        fi
    fi
    local JAR_SIZE=`wc -c $PATH_DIRECTORY/jar/$JAR_NAME.jar |awk '{print $1}'`
    print_multilayer_menu "SIZE: $JAR_SIZE"
    print_multilayer_menu "TYPE: $JAR_TYPE"
    print_multilayer_menu "TAG: $JAR_TAG"
    if [[ "$JAR_PROXY" = 1 ]]; then
        print_multilayer_menu "PROXY: √" 
    else
        print_multilayer_menu "PROXY: X" 
    fi
    if [[ "$JAR_BUILDTOOL" = 1 ]]; then
        print_multilayer_menu "BUILDTOOL: √"
    else
        print_multilayer_menu "BUILDTOOL: X"
    fi
    print_multilayer_menu "VERSION: $JAR_VERSION" 
    print_multilayer_menu "VERSION_MC: $JAR_VERSION_MC" '' 1 1
    return 0
} ## print_info_jar [jar] [no read]
print_info_account() {
    if [[ "$1" ]]; then
        local ACCOUNT_NAME="$1"
    fi
    if [[ -z "$2" || "$2" = 0 ]]; then
        config_read_account
        if [[ $? != 0 ]]; then
            return 1
        fi
    fi
    print_multilayer_menu "TAG: $ACCOUNT_TAG"
    print_multilayer_menu "HOST: $ACCOUNT_HOST"
    print_multilayer_menu "PORT: $ACCOUNT_PORT"
    print_multilayer_menu "USER: $ACCOUNT_USER"
    if [[ "$M7CM_HIDE_KEY_PATH" = 1 ]]; then
        print_multilayer_menu "KEY: ************" 
    else
        print_multilayer_menu "KEY: $ACCOUNT_KEY"
    fi
    print_multilayer_menu "EXTRA: $ACCOUNT_EXTRA" 
    if [[ -s "$PATH_DIRECTORY/account/$ACCOUNT_NAME.server" ]]; then
        print_multilayer_menu "Used by servers: $(paste -d, -s $PATH_DIRECTORY/account/$ACCOUNT_NAME.server)"
    fi
    if [[ "$M7CM_HIDE_KEY_PATH" = 0 ]]; then
        print_multilayer_menu "Full SSH command ->" "ssh $ACCOUNT_HOST -p $ACCOUNT_PORT -l $ACCOUNT_USER -i $ACCOUNT_KEY $ACCOUNT_EXTRA" 1 1
    else
        print_multilayer_menu "Full SSH command ->" "ssh $ACCOUNT_HOST -p $ACCOUNT_PORT -l $ACCOUNT_USER -i ************ $ACCOUNT_EXTRA" 1 1
    fi
    return 0
} ## print_info_account [account] [no read]
print_info_server() {
    if [[ "$1" ]]; then
        local SERVER_NAME="$1"
    fi
    if [[ -z "$2" || "$2" = 0 ]]; then
        config_read_server
        if [[ $? != 0 ]]; then
            return 1
        fi
    fi
    print_multilayer_menu "TAG: $SERVER_TAG"
    if [[ -z "$3" || "$3" = 0 ]]; then
        config_read_account "$SERVER_ACCOUNT" 1>/dev/null 2>&1
        if [[ $? = 0 ]]; then
            print_multilayer_menu "ACCOUNT: $SERVER_ACCOUNT"
            print_multilayer_menu "TAG: $ACCOUNT_TAG" '' 2 
            print_multilayer_menu "HOST: $ACCOUNT_HOST" '' 2
            print_multilayer_menu "PORT: $ACCOUNT_PORT" '' 2
            print_multilayer_menu "USER: $ACCOUNT_USER" '' 2
            if [[ "$M7CM_HIDE_KEY_PATH" = 1 ]]; then
                print_multilayer_menu "KEY: ************" '' 2 
            else
                print_multilayer_menu "KEY: $ACCOUNT_KEY" '' 2
            fi
            print_multilayer_menu "EXTRA: $ACCOUNT_EXTRA" '' 2 1
        else
            print_multilayer_menu "ACCOUNT: $SERVER_ACCOUNT" 'This account does not exist, you should change it to another account'
        fi
    else
        if [[ -f "$PATH_DIRECTORY/account/$SERVER_ACCOUNT.conf" ]]; then
            print_multilayer_menu "ACCOUNT: $SERVER_ACCOUNT"
        else
            print_multilayer_menu "ACCOUNT: $SERVER_ACCOUNT" 'This account does not exist, you should change it to another account'
        fi
    fi
    if [[ -z "$3" || "$3" = 0 ]]; then
        print_multilayer_menu "DIRECTORY: $SERVER_DIRECTORY"
        print_multilayer_menu "PORT: $SERVER_PORT"
        print_multilayer_menu "RAM_MAX: $SERVER_RAM_MAX"
        print_multilayer_menu "RAM_MIN: $SERVER_RAM_MIN"
        print_multilayer_menu "JAR: $SERVER_JAR"
        print_multilayer_menu "EXTRA_JAVA: $SERVER_EXTRA_JAVA"
        print_multilayer_menu "EXTRA_JAR: $SERVER_EXTRA_JAR"
        print_multilayer_menu "SCREEN: $SERVER_SCREEN" 
        if [[ -s "$PATH_DIRECTORY/server/$SERVER_NAME.group" ]]; then
            print_multilayer_menu "Is a member of: $(paste -d, -s $PATH_DIRECTORY/server/$SERVER_NAME.group)"
        fi    
    fi
    if [[ "$ENV_LOCAL_SSH" = 1 ]]; then
        check_status_server '' 1
        if [[ $? = 0 ]]; then
            print_multilayer_menu "STATUS: \e[42mRUNNING" '' 1 1
        else
            print_multilayer_menu "STATUS: \e[42mSTOP" '' 1 1
        fi
    else
        print_multilayer_menu "STATUS:" "Unavailable due to lacking of SSH" 1 1
    fi
} # print_info_server [server] [no read] [no expand account] [no minor options]
interactive_yn() {
    local CHOICE
    while true; do
        if [[ "$1" =~ ^(y|Y)$ ]]; then
            printf "\e[7mConfirmation:\e[0m ${@:2}(Y/n)"
        else
            printf "\e[7mConfirmation:\e[0m ${@:2}(y/N)"
        fi
        read -e -p "" CHOICE
        if [[ "${CHOICE,,}" = y ]] || [[ -z "$CHOICE" && "${1,,}" = y ]]; then
            return 0
        elif [[ "${CHOICE,,}" = n ]] || [[ -z "$CHOICE" && "${1,,}" = n ]]; then
            return 1
        fi
    done
} ## Usage: interactive_yn [default option, Y/N] [content], return: 0 for yes, 1 for no
interactive_anykey() {
    if [[ $# = 0 ]]; then
        read -t 5 -n 1 -s -r -p $'\e[1m\e[5mPress any key to continue...\n\e[0m'
    else
        echo -e "\e[1m\e[5m$@...\n\e[0m\c"
        read -t 5 -n 1 -s -r -p ''
    fi
} ## Usage: interactive_anykey [content]
check_startup() {
    config_read_m7cm
    if [[ $? = 1 ]]; then # Configuration not exist, first startup
        check_environment_local 
        check_method
        config_write_m7cm
    elif [[ $M7CM_SKIP_ENVIRONMENT_CHECK = 1 ]]; then # Configuration exists, skip startup check
        if [[ -f "$PATH_DIRECTORY/environment.conf" ]]; then
            config_read_environment
            check_method
        else
            print_notification 2 "You have enabled 'SKIP_ENVIRONMENT_CHECK', M7CM will generate environment configuration file 'environment.conf' at working folder '$PATH_DIRECTORY' after checking all environment status."
            check_environment_local
            check_method
            config_write_environment
        fi
    else # Configuration exists, do not skip
        check_environment_local
        check_method
    fi
}
check_environment_local() {
    if [[ $# = 0 ]]; then
        check_environment_local bash ssh scp sftp timeout ncat nmap screen wget curl jre root sshd git basefolder subfolder
    elif [[ $# = 1 ]]; then
        case "$1" in
            root)
                if [[ $UID = 0 ]]; then
                    print_notification 2 "You are running M7CM as root. It is strongly recommended to run M7CM with a dedicated account for security concerns."
                fi
                ;;
            bash)
                if [[ -z "$BASH_VERSION" ]]; then
                    print_notification 3 'GNU/Bash not detected! You need GNU/Bash to run M7CM.'
                    print_notification 2 'You can only ignore this if you believe that the shell you are using can perform the same as GNU/Bash, and you are brave enough to force M7CM to run with a shell it was not initally coded to run with'
                    interactive_yn N 'Proceed anyway?'
                    if [[ $? = 0 ]]; then
                        print_notification 2 'For any unexpected result, do not open issues on github repository. You are on your own, buddy.'
                    else
                        exit
                    fi 
                fi
                ;;
            ssh)
                ssh 1>/dev/null 2>&1
                if [[ $? != 255 ]]; then
                    print_notification 3 'SSH not detected!'
                    print_notification 2 'You need SSH to perform server management. For security and isolation, M7CM takes every server as a remote server, and manage it via SSH, even on the same device you are running M7CM on.'
                    interactive_yn N 'Should we ignore this and use M7CM as just a local jar library manager?'
                    if [[ $? = 0 ]]; then
                        ENV_LOCAL_SSH=0
                    else
                        exit
                    fi
                else
                    ENV_LOCAL_SSH=1
                fi
                ;;
            sshd)
                pidof sshd 1>/dev/null 2>&1
                if [[ $? != 0 ]]; then
                    print_notification 2 'SSH Daemon is not running on localhost.'
                    print_notification 0 'Are you running M7CM in a local terminal? Since M7CM use SSH and its pubkey authentication to switch between users for security, you will not be able to run and manage servers on localhost'
                fi 
                ;;
            screen)
                screen -mSUd m7cm_test exit 1>/dev/null 2>&1
                if [[ $? != 0 ]]; then
                    print_notification 2 'GNU/Screen not detected.'
                    ENV_LOCAL_SCREEN=0
                else
                    ENV_LOCAL_SCREEN=1
                fi
                ;;
            scp)
                scp --version 1>/dev/null 2>&1
                if [[ $? != 1 ]]; then
                    print_notification 2 'SSH SCP not detected'
                else
                    ENV_LOCAL_SCP=1
                    ENV_METHOD_PUSH_PULL=1
                fi
                ;;
            sftp)
                sftp --version 1>/dev/null 2>&1
                if [[ $? != 1 ]]; then
                    print_notification 2 'SSH SFTP not detected!'
                else
                    ENV_LOCAL_SFTP=1
                    ENV_METHOD_PUSH_PULL=1
                fi
                ;;
            timeout)
                timeout --version 1>/dev/null 2>&1
                if [[ $? != 0 ]]; then
                    print_notification 1 'GNU/Timeout not detected.'
                    ENV_LOCAL_TIMEOUT=0
                else
                    ENV_LOCAL_TIMEOUT=1
                    ENV_METHOD_PORT_DIAGNOSIS=1
                fi
                ;;
            ncat)
                ncat --version 1>/dev/null 2>&1
                if [[ $? != 0 ]]; then
                    print_notification 1 'Ncat not detected.'
                    ENV_LOCAL_NCAT=0
                else
                    ENV_LOCAL_NCAT=1
                    ENV_METHOD_PORT_DIAGNOSIS=1
                fi
                ;;
            nmap)
                nmap --version 1>/dev/null 2>&1
                if [[ $? != 0 ]]; then
                    print_notification 1 'Nmap not detected.'
                    print_notification 2 'M7CM uses nmap to scan open ports on specific host, but that is not a must.'
                    interactive_yn N 'Should we ignore this and disable the open ports scanning function?'
                    if [[ $? = 0 ]]; then
                        ENV_LOCAL_NMAP=0
                    else
                        exit
                    fi
                else
                    ENV_LOCAL_NMAP=1
                    ENV_METHOD_PORT_DIAGNOSIS=1
                fi
                ;;
            wget)
                wget --version 1>/dev/null 2>&1
                if [[ $? != 0 ]]; then
                    print_notification 2 'GNU/Wget not detected.'
                    ENV_LOCAL_WGET=0
                else
                    ENV_LOCAL_WGET=1
                    ENV_METHOD_PORT_DIAGNOSIS=1
                    ENV_METHOD_DOWNLOAD=1
                fi 
                ;;
            curl)
                curl --version 1>/dev/null 2>&1
                if [[ $? != 0 ]]; then
                    print_notification 2 'Curl not detected'
                    ENV_LOCAL_CURL=0
                else
                    ENV_LOCAL_CURL=1
                    ENV_METHOD_PORT_DIAGNOSIS=1
                    ENV_METHOD_DOWNLOAD=1
                fi 
                ;;  
            jre)
                java -version 1>/dev/null 2>&1
                if [[ $? != 0 ]]; then
                    print_notification 2 'JAVA Runtime Environment not detected. Jar identification function disabled'
                    print_notification 1 'You need JRE to run servers on localhost, however you can proceed without installing it if all your servers are on other remote hosts. But to identify the type of a jar, JRE is a must.'
                    ENV_LOCAL_JRE=0
                else
                    ENV_LOCAL_JRE=1
                fi 
                ;;  
            git)
                git --version 1>/dev/null 2>&1
                if [[ $? != 0 ]]; then
                    print_notification 2 'Git not detected. Spigot jar building function disabled.'
                    ENV_LOCAL_GIT=0
                else
                    ENV_LOCAL_GIT=1
                fi
                ;;
            basefolder)
                if [[ ! -w "$PATH_DIRECTORY" ]]; then
                    print_notification 4 "Script directory $PATH_DIRECTORY not writable."
                fi
                if [[ ! -r "$PATH_DIRECTORY" ]]; then
                    print_notification 4 "Script directory $PATH_DIRECTORY not readable."
                fi
                ;;
            subfolder)
                check_environment_local subfolder-server subfolder-jar subfolder-account subfolder-group subfolder-config
                ;;
            subfolder-*)
                local SUBFOLDER=${1:10}
                if [[ -d "$PATH_DIRECTORY/$SUBFOLDER" ]]; then
                    if [[ ! -w "$PATH_DIRECTORY/$SUBFOLDER" ]]; then
                        print_notification 4 "Subfolder $SUBFOLDER not writable. script exiting..."
                    fi
                    if [[ ! -r "$PATH_DIRECTORY/$SUBFOLDER" ]]; then
                        print_notification 4 "Subfolder $SUBFOLDER not readable. script exiting..."
                    fi
                else
                    rm -f "$PATH_DIRECTORY/$SUBFOLDER" 1>/dev/null 2>&1
                    mkdir "$PATH_DIRECTORY/$SUBFOLDER" 1>/dev/null 2>&1
                    if [[ $? = 0 ]]; then
                        print_notification 1 "Subfolder $SUBFOLDER not existed but successfully created."
                    elif [[ ! -w "$PATH_DIRECTORY" ]]; then
                        print_notification 4 "Subfolder $SUBFOLDER not existed and can't be created due to lacking of writing permission of folder $PATH_DIRECTORY."
                    elif [[ -f "$PATH_DIRECTORY/$SUBFOLDER" ]]; then
                        print_notification 4 "Subfolder $SUBFOLDER not existed and can't be created due to the existance of a file with the same name and not being able to remove it."
                    else
                        print_notification 4 "Subfolder $SUBFOLDER not existed and can't be created due to not recognised reasons."
                    fi
                fi
                ;;
        esac
    else
        while [[ $# > 0 ]]; do
            check_environment_local "$1"
            shift
        done
    fi
    return 0
} ## Usage: check_environment_local [environment1] [environment2] | environments: bash screen wget jre root sshd git basefolder subfolder subfolder-* , 0 arguments to check for all 
check_method() {
    if [[ "$ENV_METHOD_PUSH_PULL" = 1 ]]; then
        if [[ -z "$M7CM_METHOD_PUSH_PULL" ]]; then
            check_method_available push_pull
        else
            local METHOD=$(echo "$M7CM_METHOD_PUSH_PULL" | tr 'a-z' 'A-Z')]]
            local AVAILABLE=`eval echo '$ENV_LOCAL_'"$METHOD"`
            if [[ "$AVAILABLE" != 1 ]]; then
                print_notification 2 "Illegal jar push/pull method '$M7CM_METHOD_PUSH_PULL' set in configuration"
                check_method_available push_pull
            fi
        fi
    fi
    if [[ "$ENV_METHOD_DOWNLOAD" = 1 ]]; then
        if [[ -z "$M7CM_METHOD_DOWNLOAD" ]]; then
            check_method_available download
        else
            local METHOD=$(echo "$M7CM_METHOD_DOWNLOAD" | tr 'a-z' 'A-Z')]]
            local AVAILABLE=`eval echo '$ENV_LOCAL_'"$METHOD"`
            if [[ "$AVAILABLE" != 1 ]]; then
                print_notification 2 "Illegal jar download method '$M7CM_METHOD_DOWNLOAD' set in configuration"
                check_method_available download
            fi
        fi
    fi
    if [[ "$ENV_METHOD_PORT_DIAGNOSIS" = 1 ]]; then
        if [[ -z $M7CM_METHOD_PORT_DIAGNOSIS ]]; then
            check_method_available port_diagnosis
        else
            local METHOD=$(echo "$M7CM_METHOD_PORT_DIAGNOSIS" | tr 'a-z' 'A-Z')]]
            local AVAILABLE=`eval echo '$ENV_LOCAL_'"$METHOD"`
            if [[ "$AVAILABLE" != 1 ]]; then
                print_notification 2 "Illegal port diagnosis method '$M7CM_METHOD_PORT_DIAGNOSIS' set in configuration"
                check_method_available port_diagnosis
            fi
        fi
    fi
   
} ## To check pull/push method and port diagnosis method and download method
check_method_available() {
    if [[ $# = 1 ]]; then
        case "$1" in 
            push_pull)
                if [[ "$ENV_LOCAL_SCP" = 1 ]]; then
                    M7CM_METHOD_PUSH_PULL='scp'
                else
                    M7CM_METHOD_PUSH_PULL='sftp'
                fi
                print_notification 1 "Jar push/pull method set to '$M7CM_METHOD_PUSH_PULL'"
                ;;
            download)
                if [[ "$ENV_LOCAL_WGET" = 1 ]]; then
                    M7CM_METHOD_DOWNLOAD='wget'
                else
                    M7CM_METHOD_DOWNLOAD='curl'
                fi
                print_notification 1 "Jar download method set to '$M7CM_METHOD_DOWNLOAD'"
                ;;
            port_diagnosis)
                if [[ "$ENV_LOCAL_TIMEOUT" = 1 ]]; then
                    M7CM_METHOD_PORT_DIAGNOSIS='timeout'
                elif [[ "$ENV_LOCAL_NCAT" = 1 ]]; then
                    M7CM_METHOD_PORT_DIAGNOSIS='ncat'
                elif [[ "$ENV_LOCAL_NMAP" = 1 ]]; then
                    M7CM_METHOD_PORT_DIAGNOSIS='nmap'
                else
                    M7CM_METHOD_PORT_DIAGNOSIS='wget'
                fi
                print_notification 1 "Port dianosis method set to '$M7CM_METHOD_PORT_DIAGNOSIS'"
                ;;
        esac
    elif [[ $# = 0 ]]; then
        check_method_available push_pull download port_diagnosis
    else
        while [[ $# > 0 ]]; do
            check_method_available $1
            shift
        done
    fi
}
check_validate_host() {
    if [[ "$1" ]]; then
        local HOST="$1"
    else
        local HOST="$M7CM_DEFAULT_SSH_HOST"
    fi
    print_notification 1 "Diagnosing connection to the remote host '$HOST'."
    ping -c3 -i0.4 -w0.8 "$HOST" 1>/dev/null 2>&1
    if  [[ $? = 0 ]]; then
        print_notification 1 "Connection to the remote host '$ACCOUNT_HOST' is working fine"
        return 0
    else
        print_notification 3 "Can not get IGMP replay from remote host '$ACCOUNT_HOST', check your network connection"
        return 3 # ping failed, not connectable
    fi
} # check_validate_connection [host]
check_validate_port() {
    if [[ $ENV_METHOD_PORT_DIAGNOSIS = 0 ]]; then
        print_notification 3 "Neither timeout, ncat, nmap, nor wget detected. Port validation function is disabled."
        return 1
    fi
    if [[ "$2" ]]; then
        local HOST="$2"
    else
        local HOST="$M7CM_DEFAULT_SSH_HOST"
    fi
    print_notification 1 "Diagnosing if tcp port '$1' on host '$2' is open ..."
    case ${M7CM_METHOD_PORT_DIAGNOSIS,,} in
        timeout*)
            timeout 10 sh -c "</dev/tcp/$1/$HOST" 1>/dev/null 2>&1
            ;;
        ncat*)
            ncat -z -v -w5 $HOST $1 1>/dev/null 2>&1 
            ;;
        nmap*)
            nmap $HOST -p $1 | grep "$1/tcp open" 1>/dev/null 2>&1 
            ;;
        wget)
            local TMP="/tmp/M7CM-port-validation-$HOST-$1-`date +"%Y-%m-%d-%k-%M"`"
            mkdir "$TMP"
            pushd "$TMP" 1>/dev/null 2>&1 
            wget -t1 -T1 $HOST:$1 1>/dev/null 2>&1 
            test -f index.*
            ;;
        *)
            print_notification 3 "You have set an illegal port validation method '$M7CM_METHOD_PORT_DIAGNOSIS' in configuration file"
            return 2 
            ;;
    esac
    if [[ $? = 0 ]]; then
        if [[ "$TMP" ]]; then
            popd 1>/dev/null 2>&1 
            rm -rf "$TMP"
        fi
        print_notification 1 "TCP port '$1' on '$HOST' is open"
        return 0
    else
        print_notification 1 "TCP port '$1' on '$HOST' is not open"
        return 3
    fi
} ## Usage: check_validate_port [port] [host]
check_validate_account() {
    if [[ "$1" ]]; then
        local ACCOUNT_NAME="$1"
    fi
    if [[ -z "$2" ]]; then
        local ACCOUNT_TAG
        local ACCOUNT_HOST
        local ACCOUNT_PORT
        local ACCOUNT_USER
        local ACCOUNT_KEY
        local ACCOUNT_EXTRA
        config_read_account
        if [[ $? != 0 ]]; then
            return 1
        fi
    fi
    print_notification 1 "Validating account '$ACCOUNT_NAME'"
    if [[ ! -f "$ACCOUNT_KEY" ]]; then
        print_notification 3 "Keyfile '$ACCOUNT_KEY' does not exist, validation failed."
        return 2 # key not exist
    fi
    print_notification 1 "Validating account configuration..."
    ssh $ACCOUNT_HOST -p $ACCOUNT_PORT -l $ACCOUNT_USER -i $ACCOUNT_KEY $ACCOUNT_EXTRA exit
    if [[ $? = 0 ]]; then
        print_notification 1 "Validation passed"
        ACCOUNT_VALID=1
        return 0
    else
        print_notification 2 "SSH test failed, maybe your account configuration is wrong?"
    fi
    check_validate_host "$ACCOUNT_HOST"
    check_validate_port "$ACCOUNT_PORT" "$ACCOUNT_HOST"
    return 4
} # check_validate_account [account] [no read]
check_validate_server() {
    if [[ "$1" ]]; then
        local SERVER_NAME="$1"
    fi
    if [[ -z "$2" ]]; then
        local SERVER_ACCOUNT
        local SERVER_DIRECTORY
        local SERVER_JAR
        local SERVER_EXTRA_JAR
        local SERVER_EXTRA_JAVA
        local SERVER_PORT
        local SERVER_RAM_MAX
        local SERVER_RAM_MIN
        local SERVER_SCREEN
        local SERVER_TAG
        config_read_server
        if [[ $? != 0 ]]; then
            return 1
        fi
    fi
    print_notification 1 "Validating server '$SERVER_NAME'"
    config_read_account "$SERVER_ACCOUNT"
    if [[ $? != 0 ]]; then
        print_notification 3 "Invalid account. Validation failed."
        return 1 # invalid account
    fi
    ssh -oBatchmode=yes $ACCOUNT_HOST -p $ACCOUNT_PORT -l $ACCOUNT_USER -i $ACCOUNT_KEY $ACCOUNT_EXTRA "screen -mSUd m7cm-test exit" 1>/dev/null 2>&1
    if [[ $? != 0 ]]; then
        print_notification 3 'GNU/Screen not detected on remote host.'
        print_notification 0 'You can ignore this if you do not want to run servers on this host, since M7CM uses GNU/Screen to keep servers in background so it can send command and performs tasks like message before shuting down, schedule restart, etc. Lacking of GNU/Screen means M7CM can not startup and manage servers.'
        print_notification 0 'You may be wondering why we can not just ssh and run the server and use normal out-of-the-box linux methods to keep them in background, such as the crtl+Z jobs method or nohup + & method'
        print_notification 0 'The answer is, for security concern, M7CM only connects to remote host at certain neccessary occasions. Most of the time there is no SSH connection nor any communication between the host running M7CM and the host running a Minecraft server.'
        print_notification 0 'While nohup + & method can provide the always-in-background function we need, the background task can no longer accept new commands from outside, and we can not bring you to the console for debug or management anymore'
        print_notification 2 'Unless you just want to import a jar from this server and do not want to run any Minecraft server on it, you better not ignore this.'
        interactive_yn N "Ignore the lack of GNU/screen?"
        if [[ $? = 1 ]]; then
            print_notification 3 'Validation failed.'
            return 2 # screen not found
        fi
    else
        print_notification 1 'GNU/screen detected.'
    fi
    ssh -oBatchmode=yes $ACCOUNT_HOST -p $ACCOUNT_PORT -l $ACCOUNT_USER -i $ACCOUNT_KEY $ACCOUNT_EXTRA "java -version" 1>/dev/null 2>&1
    if [[ $? != 0 ]]; then
        print_notification 3 "Java runtime environment not detected on remote host. You can not run Minecraft servers on this host."
        print_notification 2 'Unless you just want to import a jar from this server and do not want to run any Minecraft server on it, you better not ignore this.'
        interactive_yn N "Ignore the lack of JRE?"
        if [[ $? = 1 ]]; then
            print_notification 3 'Validation failed.'
            return 3 # jre not found
        fi
    else
        print_notification 1 'Java runtime environment detected.'
    fi
    ssh -oBatchmode=yes $ACCOUNT_HOST -p $ACCOUNT_PORT -l $ACCOUNT_USER -i $ACCOUNT_KEY $ACCOUNT_EXTRA "test -d $SERVER_DIRECTORY"
    if [[ $? != 0 ]]; then
        print_notification 2 "Remote directory '$SERVER_DIRECTORY' does not exist. Trying to create it..."
        ssh -oBatchmode=yes $ACCOUNT_HOST -p $ACCOUNT_PORT -l $ACCOUNT_USER -i $ACCOUNT_KEY $ACCOUNT_EXTRA "mkdir $SERVER_DIRECTORY" 1>/dev/null 2>&1
        if [[ $? != 0 ]]; then
            print_notification 3 "Remote directory '$SERVER_DIRECTORY' can not be created. Validation failed."
            return 3 # not exist and can not be created
        else
            print_notification 1 "Remote directory '$SERVER_DIRECTORY' created"
        fi
    else
        ssh -oBatchmode=yes $ACCOUNT_HOST -p $ACCOUNT_PORT -l $ACCOUNT_USER -i $ACCOUNT_KEY $ACCOUNT_EXTRA "test -w $SERVER_DIRECTORY"
        if [[ $? != 0 ]]; then
            print_notification 3 "Remote directory '$SERVER_DIRECTORY' exists but not writable. Validation failed."
            return 4
        else
            print_notification 1 "Remote directory '$SERVER_DIRECTORY' is writable"
        fi
    fi
    ssh -oBatchmode=yes $ACCOUNT_HOST -p $ACCOUNT_PORT -l $ACCOUNT_USER -i $ACCOUNT_KEY $ACCOUNT_EXTRA "cd $SERVER_DIRECTORY; test -f $SERVER_JAR" 
    if [[ $? = 0 ]]; then
        print_notification 1 "Remote jar '$SERVER_JAR' found."
        ssh -oBatchmode=yes $ACCOUNT_HOST -p $ACCOUNT_PORT -l $ACCOUNT_USER -i $ACCOUNT_KEY $ACCOUNT_EXTRA "cd $SERVER_DIRECTORY; test -r $SERVER_JAR" 
        if [[ $? != 0 ]]; then
            print_notification 3 "Remote jar '$SERVER_JAR' is not readable. Validation failed."
            return 5
        else
            print_notification 1 "Remote jar '$SERVER_JAR' is readable."
        fi
        print_notification 1 "Test if remote jar accepts '--version' argument"
        ssh -oBatchmode=yes $ACCOUNT_HOST -p $ACCOUNT_PORT -l $ACCOUNT_USER -i $ACCOUNT_KEY $ACCOUNT_EXTRA "cd $SERVER_DIRECTORY; java -jar $SERVER_JAR --vesison" 1>/dev/null 2>&1
        if [[ $? != 0 ]]; then
            print_notification 3 "The remote jar '$SERVER_JAR' does not recognize '--version' argument"
            print_notification 0 "For most Minecraft server jars that would mean they are corrupt. Even for some servers like vanilla which do not 'RECOGNIZE' '--vesison' argument, they should at least 'ACCEPT' the '--version' argument and then report they do not 'RECOGNIZE' it. The very rare counterexample is Spigot BuildTools, it is the only jar I know would never 'ACCEPT' a '--version' argument."
            print_notification 1 "You can ignore this if you believe your jar is OK and the trouble is on M7CM side."
            interactive_yn N "Ignore it?"
            if [[ $? = 1 ]]; then
                print_notification 3 'Validation failed'
                return 6
            fi
        else
            print_notification 3 "The remote jar '$SERVER_JAR' recognizes '--version' argument"
        fi
    else
        print_notification 2 "Remote jar '$SERVER_JAR' not found. You need M7CM's jar push function to setup this server"
        if [[ $ENV_METHOD_PUSH_PULL = 0 ]]; then
            print_notification 3 "Neither SSH SCP or SSH SFTP found on localhost, you can not push local jar to the remote host. Validation failed."
            return 5 # jar not found and can't push
        else
            print_notification 2 "Jar push/pull method available. You should push jar to this server later using '$PATH_SCRIPT jar push [jar] $SERVER_NAME'"
        fi
    fi
    print_notification 1 "Validation passed"
    SERVER_VALID=1
    return 0
} # check_validate_server [server] [no read]
check_diagnose_server() {
    print_notification 1 "Dignosing problems of server '$SERVER_NAME'..."
    if [[ -z "$1" || "$1" = 0 ]]; then
        check_validate_host "$ACCOUNT_HOST"
        if [[ $? != 0 ]]; then
            return 1
        fi
    fi
    if [[ -z "$2" || "$2" = 0 ]]; then
        check_validate_port "$ACCOUNT_PORT" "$ACCOUNT_HOST"
        if [[ $? != 0 ]]; then
            return 2
        fi
    fi
    if [[ -z "$3" || "$3" = 0 ]]; then
        check_validate_account '' 1
        if [[ $? != 0 ]]; then
            return 3
        fi
    fi
    if [[ -z "$4" || "$4" = 0 ]]; then
        check_validate_server '' 1
        if [[ $? != 0 ]]; then
            return 4
        fi
    fi
    return 0
} # check_diagnose_server [no host] [no port] [no account] [no server]
check_status_server() {
    if [[ "$1" ]]; then
        local SERVER_NAME="$1"
    fi
    if [[ -z "$2" || "$2" = 0 ]]; then
        config_read_server
        config_read_account "$SERVER_ACCOUNT"
    fi
    ssh $ACCOUNT_HOST -oBatchmode=yes -p $ACCOUNT_PORT -l $ACCOUNT_USER -i $ACCOUNT_KEY $ACCOUNT_EXTRA "screen -ls $SERVER_SCREEN" 1>/dev/null 2>&1
    if [[ $? = 0 ]]; then
        return 0 #running
    else
        return 1 #not running
    fi
} # check_status_server [server name] [no read]
check_status_screen() {
    local ACCOUNT_TAG
    local ACCOUNT_HOST
    local ACCOUNT_PORT
    local ACCOUNT_USER
    local ACCOUNT_KEY
    local ACCOUNT_EXTRA
    config_read_account "$2"
    ssh $ACCOUNT_HOST -oBatchmode=yes -p $ACCOUNT_PORT -l $ACCOUNT_USER -i $ACCOUNT_KEY $ACCOUNT_EXTRA "screen -ls $1" 1>/dev/null 2>&1
    if [[ $? = 0 ]]; then
        return 0 #running
    else
        return 1 #not running
    fi

} # check_status_screen [screen name] [account name]
config_read_m7cm() {
    M7CM_DEFAULT_SERVER_JAR='server.jar'
    M7CM_DEFAULT_SERVER_PORT='25565'
    M7CM_DEFAULT_SSH_HOST='localhost'
    M7CM_DEFAULT_SSH_PORT='22'
    M7CM_DEFAULT_SSH_USER="$USER"
    M7CM_METHOD_DOWNLOAD=''
    M7CM_METHOD_PORT_DIAGNOSIS=''
    M7CM_METHOD_PUSH_PULL=''
    M7CM_DOWNLOAD_PROXY_HTTP=''
    M7CM_DOWNLOAD_PROXY_HTTPS=''
    M7CM_CONFIRM_START='1'
    M7CM_CONFIRM_STOP='1'
    M7CM_SCREEN_LOCAL='0'
    M7CM_DETAILED_SERVER_LIST='0'
    M7CM_SKIP_ENVIRONMENT_CHECK='0'
    M7CM_HIDE_KEY_PATH='1'
    if [[ -f "$PATH_DIRECTORY/m7cm.conf" ]]; then
        local IFS="="
        while read -r NAME VALUE; do
            case "$NAME" in
                DEFAULT_SERVER_JAR|DEFAULT_SSH_HOST|DEFAULT_SSH_USER|METHOD_DOWNLOAD|METHOD_PORT_DIAGNOSIS|METHOD_PUSH_PULL)
                    eval M7CM_$NAME=$VALUE
                    ;;
                DEFAULT_SERVER_PORT|DEFAULT_SSH_PORT)
                    if [[ "$VALUE" =~ ^[0-9]+$ ]] && [[ $VALUE -ge 0 && $VALUE -le 65535 ]]; then
                        M7CM_DEFAULT_SERVER_PORT
                    else
                        print_notification 2 'Illegal value for default server port, defaulting it to 25565. Accept: interger 0-65535'
                    fi
                    ;;
                DEFAULT_SSH_PORT)
                    if [[ "$VALUE" =~ ^[0-9]+$ ]] && [[ $VALUE -ge 0 && $VALUE -le 65535 ]]; then
                        M7CM_DEFAULT_SSH_PORT=$VALUE
                    else
                        print_notification 2 'Illegal value for default ssh port, defaulting it to 22. Accept: interget 0-65535'
                    fi
                    ;;
                DOWNLOAD_PROXY_HTTP)
                    if [[ "$VALUE" =~ '^https?://[-A-Za-z0-9\+&@#/%?=~_|!:,.;]*[-A-Za-z0-9\+&@#/%=~_|]$' ]]; then
                        M7CM_DOWNLOAD_PROXY_HTTP=$VALUE
                    else
                        print_notification 2 "Illegal http proxy '$VALUE', http proxy will not be used"
                    fi
                    ;;
                DOWNLOAD_PROXY_HTTPS)
                    if [[ "$VALUE" =~ '^https?://[-A-Za-z0-9\+&@#/%?=~_|!:,.;]*[-A-Za-z0-9\+&@#/%=~_|]$' ]]; then
                        M7CM_DOWNLOAD_PROXY_HTTPS=$VALUE
                    else
                        print_notification 2 "Illegal http proxy '$VALUE', https proxy will not be used"
                    fi
                    ;;
                CONFIRM_START)
                    if [[ "$VALUE" =~ ^[01]$ ]]; then
                        M7CM_CONFIRM_START=$VALUE
                    else
                        print_notification 2 "Illegal value for whether M7CM should confirm a server is successfully started, defaulting it to 1. Accept:0/1"
                    fi
                    ;;
                CONFIRM_STOP)
                    if [[ "$VALUE" =~ ^[01]$ ]]; then
                        M7CM_CONFIRM_STOP=$VALUE
                    else
                        print_notification 2 "Illegal value for whether M7CM should confirm a server is successfully stopped, defaulting it to 1. Accept:0/1"
                    fi
                    ;;
                DETAILED_SERVER_LIST)
                    if [[ "$VALUE" =~ ^[01]$ ]]; then
                        M7CM_DETAILED_SERVER_LIST=$VALUE
                    else
                        print_notification 2 "Illegal value for whether M7CM should display detailed server information in server list, defaulting it to 0. Accept:0/1"
                    fi
                SKIP_ENVIRONMENT_CHECK)
                    if [[ "$VALUE" =~ ^[01]$ ]]; then
                        M7CM_SKIP_ENVIRONMENT_CHECK=$VALUE
                    else
                        print_notification 2 "Illegal value for whether M7CM should skip startup check, defaulting it to 0. Accept:0/1"
                    ;;
                HIDE_KEY_PATH)
                    if [[ "$VALUE" =~ ^[01]$ ]]; then
                        M7CM_HIDE_KEY_PATH=$VALUE
                    else
                        print_notification 2 "Illegal value for whether M7CM should hide private key path, defaulting it to 1. Accept:0/1"
                    ;;
                LOCAL_SCREEN)
                    if [[ "$VALUE" =~ ^[01]$ ]]; then
                        M7CM_LOCAL_SCREEN=$VALUE
                    else
                        print_notification 2 "Illegal value for whether M7CM should run screen at local , defaulting it to 0. Accept:0/1"
                    ;;
                *)
                    if [[ ! -z "$VALUE" ]]; then
                        print_notification 1 "Omitted redundant variable '$NAME' found in M7CM configuration file"
                    fi
                ;;
            esac
        done < $PATH_DIRECTORY/m7cm.conf
        IFS=$' \t\n'
        return 0
    else
        print_notification 2 "Configuration file for M7CM not found, all configuration set to default"
        return 1
    fi
}
config_read_environment() {
    ENV_LOCAL_SSH=0
    ENV_LOCAL_SCREEN=0

    ENV_LOCAL_SCP=0
    ENV_LOCAL_SFTP=0

    ENV_LOCAL_TIMEOUT=0
    ENV_LOCAL_NCAT=0
    ENV_LOCAL_NMAP=0

    ENV_LOCAL_WGET=0
    ENV_LOCAL_CURL=0
    
    ENV_LOCAL_JRE=0
    ENV_LOCAL_GIT=0

    ENV_METHOD_PORT_DIAGNOSIS=0
    ENV_METHOD_PUSH_PULL=0
    ENV_METHOD_DOWNLOAD=0
    local IFS="="
    while read -r NAME VALUE; do
        case "$NAME" in
            SSH|SCREEN|SCP|SFTP|TIMEOUT|NCAT|NMAP|WGET|CURL|JRE|GIT)
                if [[ "$VALUE" =~ ^[10]$ ]]; then
                    eval ENV_LOCAL_$NAME=$VALUE
                else
                    print_notification 2 "Illegal value '$VALUE' for local environment status of '$NAME', defualting it to '0', accept: 0/1"
                    eval ENV_LOCAL_$NAME=0
                fi
            ;;
            *)
                if [[ ! -z "$VALUE" ]]; then
                    print_notification 1 "Redundant variable '$NAME' found in environment configuration file, ignored"
                fi
            ;;
        esac
    done < $PATH_DIRECTORY/environment.conf
    IFS=$' \t\n'
    if [[ $ENV_LOCAL_TIMEOUT = 1 || $ENV_LOCAL_NCAT = 1 || $ENV_LOCAL_NMAP = 1 || $ENV_LOCAL_WGET = 1]]; then
        ENV_METHOD_PORT_DIAGNOSIS=1
    fi
    if [[ $ENV_LOCAL_WGET = 1 || $ENV_LOCAL_CURL = 1 ]]; then
        ENV_METHOD_DOWNLOAD=1
    fi
    if [[ $ENV_LOCAL_SCP = 1 || $ENV_LOCAL_SFTP = 1 ]]; then
        ENV_METHOD_PUSH_PULL=1
    fi
    return 0
}
config_read_jar() {
    if [[ ! -z "$1" ]]; then
        JAR_NAME="$1"
        utility_jar_name_fix
    fi
    if [[ ! -f "$PATH_DIRECTORY/jar/$JAR_NAME.jar" ]]; then
        print_notification 3 "Jar '$JAR_NAME' does not exist, import or build it first."
        return 1
    elif [[ ! -f "$PATH_DIRECTORY/jar/$JAR_NAME.conf" ]]; then
        print_notification 2 "Configuration file '$JAR_NAME.conf' not found"
        return 2
    elif [[ ! -r "$PATH_DIRECTORY/jar/$JAR_NAME.conf" ]]; then
        print_notification 2 "Configuration file '$JAR_NAME.conf' not readable, check your permission."
        return 3
    fi
    JAR_TAG=''
    JAR_TYPE=''
    JAR_VERSION=''
    JAR_VERSION_MC=''
    JAR_PROXY=0
    JAR_BUILDTOOL=0
    local IFS="="
    while read -r NAME VALUE; do
        case "$NAME" in
            JAR_TAG|JAR_TYPE|JAR_PROXY|JAR_VERSION|JAR_VERSION_MC|JAR_BUILDTOOL)
                eval $NAME=$VALUE
            ;;
            *)
                if [[ ! -z "$VALUE" ]]; then
                    print_notification 1 "Redundant variable $NAME found in jar configuration file '$JAR_NAME.conf', ignored"
                fi
            ;;
        esac
    done < $PATH_DIRECTORY/jar/$JAR_NAME.conf
    IFS=$' \t\n'
    return 0
} ## Safely read jar info, ignore redundant values
config_read_account() {
    if [[ $# > 0 ]]; then
        ACCOUNT_NAME="$1"
    fi
    if [[ ! -f $PATH_DIRECTORY/account/$ACCOUNT_NAME.conf ]]; then
        print_notification 3 "Configuration file for Account '$ACCOUNT_NAME' not found, use '$PATH_SCRIPT account define $ACCOUNT_NAME' to define it first."
        return 1
    elif [[ ! -r $PATH_DIRECTORY/account/$ACCOUNT_NAME.conf ]]; then
        print_notification 3 "Configuration file for Account '$ACCOUNT_NAME' not readable, check your permission."
        return 2
    fi
    ACCOUNT_TAG=''
    ACCOUNT_HOST='localhost'
    ACCOUNT_PORT="$M7CM_DEFAULT_SSH_PORT"
    ACCOUNT_USER="$M7CM_DEFAULT_SSH_USER"
    ACCOUNT_KEY=''
    ACCOUNT_EXTRA=''
    local IFS="="
    while read -r NAME VALUE; do
        case "$NAME" in
            ACCOUNT_TAG|ACCOUNT_HOST|ACCOUNT_PORT|ACCOUNT_USER|ACCOUNT_KEY|ACCOUNT_EXTRA)
                eval $NAME=$VALUE
            ;;
            *)
                if [[ ! -z "$VALUE" ]]; then
                    print_notification 1 "Redundant variable '$NAME' found in configuration file '$ACCOUNT_NAME.conf', ignored"
                fi
            ;;
        esac
    done < $PATH_DIRECTORY/account/$ACCOUNT_NAME.conf
    IFS=$' \t\n'
    return 0
} ## Safely read account config, ignore redundant values
config_read_server() {
    if [[ $# > 0 ]]; then
        SERVER_NAME="$1"
    fi
    if [[ ! -f $PATH_DIRECTORY/server/$SERVER_NAME.conf ]]; then
        print_notification 3 "Configuration file for server '$SERVER_NAME' not found, use '$PATH_SCRIPT server define $SERVER_NAME' to define it first."
        return 1
    elif [[ ! -r $PATH_DIRECTORY/server/$SERVER_NAME.conf ]]; then
        print_notification 3 "Configuration file for server '$SERVER_NAME' not readable, check your permission"
        return 2
    fi
    SERVER_TAG=''
    SERVER_ACCOUNT=''
    SERVER_DIRECTORY='~'
    SERVER_PORT="$M7CM_DEFAULT_SERVER_PORT"
    SERVER_RAM_MAX='1G'
    SERVER_RAM_MIN='1G'
    SERVER_JAR="$M7CM_DEFAULT_SERVER_JAR"
    SERVER_EXTRA_JAVA=''
    SERVER_EXTRA_JAR=''
    SERVER_SCREEN=''
    local IFS="="
    while read -r NAME VALUE; do
        case "$NAME" in
            SERVER_TAG|SERVER_ACCOUNT|SERVER_DIRECTORY|SERVER_PORT|SERVER_RAM_MAX|SERVER_RAM_MIN|SERVER_JAR|SERVER_EXTRA_JAVA|SERVER_EXTRA_JAR|SERVER_SCREEN)
                eval $NAME=$VALUE
            ;;
            *)
                if [[ ! -z "$VALUE" ]]; then
                    print_notification 1 "Redundant variable '$NAME' found in configuration file '$SERVER_NAME.conf', ignored"
                fi
            ;;
        esac
    done < $PATH_DIRECTORY/account/$SERVER_NAME.conf
    IFS=$' \t\n'
    return 0
}
config_read_server_and_account() {
    config_read_server
    if [[ $? != 0 ]]; then
        return 1
    fi
    config_read_account "$SERVER_ACCOUNT"
    if [[ $? != 0 ]]; then
        return 2
    fi
    return 0
}
config_write_m7cm() {
    print_notification 1 "Proceeding to write M7CM configuration to file 'm7cm.conf'"
    echo "## Configuration for M7CM, generated at `date +"%Y-%m-%d-%k-%M"`" > "$PATH_DIRECTORY/environment.conf"
    echo "DEFAULT_SERVER_JAR=$M7CM_DEFAULT_SERVER_JAR" >> "$PATH_DIRECTORY/m7cm.conf"
    echo "DEFAULT_SERVER_PORT=$M7CM_DEFAULT_SERVER_PORT" >> "$PATH_DIRECTORY/m7cm.conf"
    echo "DEFAULT_SSH_HOST=$M7CM_DEFAULT_SSH_HOST" >> "$PATH_DIRECTORY/m7cm.conf"
    echo "DEFAULT_SSH_USER=$M7CM_DEFAULT_SSH_USER" >> "$PATH_DIRECTORY/m7cm.conf"
    echo "DEFAULT_SSH_PORT=$M7CM_DEFAULT_SSH_PORT" >> "$PATH_DIRECTORY/m7cm.conf"
    echo "METHOD_DOWNLOAD=$M7CM_METHOD_DOWNLOAD" >> "$PATH_DIRECTORY/m7cm.conf"
    echo "METHOD_PORT_DIAGNOSIS=$M7CM_METHOD_PORT_DIAGNOSIS" >> "$PATH_DIRECTORY/m7cm.conf"
    echo "METHOD_PUSH_PULL=$M7CM_METHOD_PUSH_PULL" >> "$PATH_DIRECTORY/m7cm.conf"
    echo "DOWNLOAD_PROXY_HTTP=$M7CM_DOWNLOAD_PROXY_HTTP" >> "$PATH_DIRECTORY/m7cm.conf"
    echo "DOWNLOAD_PROXY_HTTPS=$M7CM_DOWNLOAD_PROXY_HTTPS" >> "$PATH_DIRECTORY/m7cm.conf"
    echo "CONFIRM_START=$M7CM_CONFIRM_START" >> "$PATH_DIRECTORY/m7cm.conf"
    echo "CONFIRM_STOP=$M7CM_CONFIRM_STOP" >> "$PATH_DIRECTORY/m7cm.conf"
    echo "DETAILED_SERVER_LIST=$M7CM_DETAILED_SERVER_LIST" >> "$PATH_DIRECTORY/m7cm.conf"
    echo "SKIP_ENVIRONMENT_CHECK=$M7CM_SKIP_ENVIRONMENT_CHECK" >> "$PATH_DIRECTORY/m7cm.conf"
    echo "SCREEN_LOCAL=$M7CM_SCREEN_LOCAL" >> "$PATH_DIRECTORY/m7cm.conf"
    echo "HIDE_KEY_PATH=$M7CM_HIDE_KEY_PATH" >> "$PATH_DIRECTORY/m7cm.conf"
    print_notification 1 "Successfully generated configuration file 'm7cm.conf'"
    return 0
}
config_write_environment() {
    print_notification 1 "Proceeding to write detected environment status to config file 'environment.conf'"
    echo "## Configuration for local environment, generated by M7CM at `date +"%Y-%m-%d-%k-%M"`. This file is generated because you've set" > "$PATH_DIRECTORY/environment.conf"
    echo "## SKIP_STARTUP_CHECK=1 in m7cm.conf. In this case, M7CM reads this file to get environment status instead of checking it every time." >> "$PATH_DIRECTORY/environment.conf"
    echo "SSH=$ENV_LOCAL_SSH" >> "$PATH_DIRECTORY/environment.conf"
    echo "SCREEN=$ENV_LOCAL_SCREEN" >> "$PATH_DIRECTORY/environment.conf"
    echo "SCP=$ENV_LOCAL_SCP" >> "$PATH_DIRECTORY/environment.conf"
    echo "SFTP=$ENV_LOCAL_SFTP" >> "$PATH_DIRECTORY/environment.conf"
    echo "TIMEOUT=$ENV_LOCAL_TIMEOUT" >> "$PATH_DIRECTORY/environment.conf"
    echo "NCAT=$ENV_LOCAL_NCAT" >> "$PATH_DIRECTORY/environment.conf"
    echo "NMAP=$ENV_LOCAL_NMAP" >> "$PATH_DIRECTORY/environment.conf"
    echo "WGET=$ENV_LOCAL_WGET" >> "$PATH_DIRECTORY/environment.conf"
    echo "CURL=$ENV_LOCAL_CURL" >> "$PATH_DIRECTORY/environment.conf"
    echo "JRE=$ENV_LOCAL_JRE" >> "$PATH_DIRECTORY/environment.conf"
    echo "GIT=$ENV_LOCAL_GIT" >> "$PATH_DIRECTORY/environment.conf"
    print_notification 1 "Successfully written environment status to 'environment.conf'"
    return 0
}
config_write_jar() {
    if [[ $# > 0 ]]; then
        local JAR_NAME="$1"
        utility_jar_name_fix
    fi
    if [[ -f "$PATH_DIRECTORY/jar/$JAR_NAME.conf" && ! -w "$PATH_DIRECTORY/jar/$JAR_NAME.conf" ]]; then
        print_notification 3 "Can not write to configuration file '$JAR_NAME.conf' due to lacking of writing permission. Check your permission"
        return 1
    else
        print_notification 1 "Proceeding to write values to config file....'$JAR_NAME.conf'"
        echo "## Configuration for jar file '$JAR_NAME', DO NOT EDIT THIS UNLESS YOU KNOW WHAT YOU ARE DOING" > "$PATH_DIRECTORY/jar/$JAR_NAME.conf"
        echo "JAR_TAG=\"$JAR_TAG\"" >> "$PATH_DIRECTORY/jar/$JAR_NAME.conf"
        echo "JAR_TYPE=\"$JAR_TYPE\"" >> "$PATH_DIRECTORY/jar/$JAR_NAME.conf"
        echo "JAR_BUILDTOOL=\"$JAR_BUILDTOOL\"" >> "$PATH_DIRECTORY/jar/$JAR_NAME.conf"
        echo "JAR_PROXY=\"$JAR_PROXY\"" >> "$PATH_DIRECTORY/jar/$JAR_NAME.conf"
        echo "JAR_VERSION=\"$JAR_VERSION\"" >> "$PATH_DIRECTORY/jar/$JAR_NAME.conf"
        echo "JAR_VERSION_MC=\"$JAR_VERSION_MC\"" >> "$PATH_DIRECTORY/jar/$JAR_NAME.conf"
        print_notification 0 "Successfully written values to config file $JAR_NAME.conf"
        return 0
    fi
}
config_write_account() {
    if [[ $# > 0 ]]; then
        local ACCOUNT_NAME="$1"
    fi
    if [[ -f "$PATH_DIRECTORY/account/$ACCOUNT_NAME.conf" && ! -w "$PATH_DIRECTORY/account/$ACCOUNT_NAME.conf" ]]; then
        print_notification 3 "Can not write to configuration file '$ACCOUNT_NAME.conf' due to lacking of writing permission. Check your permission"
        return 1
    else
        print_notification 1 "Proceeding to write values to config file '$ACCOUNT_NAME.conf'...."
        echo "## Configuration for account '$ACCOUNT_NAME', DO NOT EDIT THIS UNLESS YOU KNOW WHAT YOU ARE DOING" > "$PATH_DIRECTORY/account/$ACCOUNT_NAME.conf"
        echo "ACCOUNT_TAG=\"$ACCOUNT_TAG\"" >> "$PATH_DIRECTORY/account/$ACCOUNT_NAME.conf"
        echo "ACCOUNT_HOST=\"$ACCOUNT_HOST\"" >> "$PATH_DIRECTORY/account/$ACCOUNT_NAME.conf"
        echo "ACCOUNT_PORT=\"$ACCOUNT_PORT\"" >> "$PATH_DIRECTORY/account/$ACCOUNT_NAME.conf"
        echo "ACCOUNT_USER=\"$ACCOUNT_USER\"" >> "$PATH_DIRECTORY/account/$ACCOUNT_NAME.conf"
        echo "ACCOUNT_KEY=\"$ACCOUNT_KEY\"" >> "$PATH_DIRECTORY/account/$ACCOUNT_NAME.conf"
        echo "ACCOUNT_EXTRA=\"$ACCOUNT_EXTRA\"" >> "$PATH_DIRECTORY/account/$ACCOUNT_NAME.conf"
        print_notification 0 "Successfully written values to config file '$ACCOUNT_NAME.conf'"
        return 0
    fi
}
config_write_server() {
    if [[ $# > 0 ]]; then
        local SERVER_NAME="$1"
    fi
    if [[ -f "$PATH_DIRECTORY/server/$SERVER_NAME.conf" && ! -w "$PATH_DIRECTORY/server/$SERVER_NAME.conf" ]]; then
        print_notification 3 "Can not write to configuration file '$SERVER_NAME.conf' due to lacking of writing permission. Check your permission."
        return 1
    else
        print_notification 1 "Proceeding to write values to config file '$SERVER_NAME.conf'...."
        echo "## Configuration for server '$SERVER_NAME', DO NOT EDIT THIS UNLESS YOU KNOW WHAT YOU ARE DOING" > "$PATH_DIRECTORY/server/$SERVER_NAME.conf"
        echo "SERVER_TAG=\"$SERVER_TAG\"" >> "$PATH_DIRECTORY/server/$SERVER_NAME.conf"
        echo "SERVER_ACCOUNT=\"$SERVER_ACCOUNT\"" >> "$PATH_DIRECTORY/server/$SERVER_NAME.conf"
        echo "SERVER_DIRECTORY=\"$SERVER_DIRECTORY\"" >> "$PATH_DIRECTORY/server/$SERVER_NAME.conf"
        echo "SERVER_PORT=\"$SERVER_PORT\"" >> "$PATH_DIRECTORY/server/$SERVER_NAME.conf"
        echo "SERVER_RAM_MAX=\"$SERVER_RAM_MAX\"" >> "$PATH_DIRECTORY/server/$SERVER_NAME.conf"
        echo "SERVER_RAM_MIN=\"$SERVER_RAM_MIN\"" >> "$PATH_DIRECTORY/server/$SERVER_NAME.conf"
        echo "SERVER_JAR=\"$SERVER_JAR\"" >> "$PATH_DIRECTORY/server/$SERVER_NAME.conf"
        echo "SERVER_EXTRA_JAVA=\"$SERVER_EXTRA_JAVA\"" >> "$PATH_DIRECTORY/server/$SERVER_NAME.conf"
        echo "SERVER_EXTRA_JAR=\"$SERVER_EXTRA_JAR\"" >> "$PATH_DIRECTORY/server/$SERVER_NAME.conf"
        echo "SERVER_SCREEN=\"$SERVER_SCREEN\"" >> "$PATH_DIRECTORY/server/$SERVER_NAME.conf"
        print_notification 0 "Successfully written values to config file '$ACCOUNT_NAME.conf'"
        grep -q "^$SERVER_NAME$" "$PATH_DIRECTORY/account/$SERVER_ACCOUNT.server" 1>/dev/null 2>&1
        if [[ $? != 0 ]]; then
            print_notification 1 "Adding server '$SERVER_NAME' to the assosiated list of account '$SERVER_ACCOUNT'"
            echo "$SERVER_NAME" >> "$PATH_DIRECTORY/account/$SERVER_ACCOUNT.server"
        fi
        return 0
    fi
}
assignment_jar() {
    local OPTION
    local VALUE
    local CHANGE
    local IFS
    while [[ $# > 0 ]]; do
        CHANGE="$1"
        IFS=' ='
        read -r OPTION VALUE <<< "$CHANGE"
        OPTION=`echo "$OPTION" | tr [a-z] [A-Z]`
        IFS=$' \t\n'
        case "$OPTION" in
            TAG|TYPE|VERSION|VERSION_MC)
                eval JAR_$OPTION=\"$VALUE\"
                print_notification 0 "'$OPTION' set to '$VALUE'"
            ;;
            PROXY|BUILDTOOL)
                if [[ "$VALUE" =~ ^[0nN]$ ]]; then
                    eval JAR_$OPTION=0
                    print_notification 0 "'$OPTION' set to 0"
                elif [[ "$VALUE" =~ ^[1yY]$ ]]; then
                    eval JAR_$OPTION=1
                    print_notification 1 "'$OPTION' set to 1"
                else 
                    eval JAR_$OPTION=0
                    print_notification 2 "Invalid value '$VALUE' for '$OPTION', defaulting it to '0'. Accedpting: 0/n/N, 1/y/Y"
                fi
            ;;
            NAME)
                if [[ -z "$JAR_NAME" ]]; then
                    print_notification 3 "Renaming aborted due to no jar being selected"
                    return 1
                elif [[ -z "$VALUE" ]]; then
                    print_notification 3 "No new name assigned, 'NAME' kept not changed"
                    return 2
                fi
                if [[ -f "$PATH_DIRECTORY/jar/$VALUE.jar" || -f "$PATH_DIRECTORY/jar/$VALUE.conf" ]]; then
                    interactive_yn N "A jar with the same name '$VALUE' has already exist, are you sure you want to overwrite it?"
                    if [[ $? = 1 ]]; then
                        return 3
                    fi
                fi
                mv -f "$PATH_DIRECTORY/jar/$JAR_NAME.jar" "$PATH_DIRECTORY/jar/$VALUE.jar" 1>/dev/null 2>&1
                mv -f "$PATH_DIRECTORY/jar/$JAR_NAME.conf" "$PATH_DIRECTORY/jar/$VALUE.conf" 1>/dev/null 2>&1
                JAR_NAME="$VALUE"
                print_notification 0 "'NAME' set to '$VALUE'"
            ;;
            *)
                print_notification 1 "'$OPTION' is not an available option, ignored"
            ;;
        esac
        shift
    done
    return 0
} ## Usage: assignment_jar [option1=value1]   [option2=value2]
assignment_account() {
    local OPTION
    local VALUE
    local CHANGE
    local IFS
    while [[ $# > 0 ]]; do
        CHANGE="$1"
        IFS=' ='
        read -r OPTION VALUE <<< "$CHANGE"
        OPTION=`echo "$OPTION" | tr [a-z] [A-Z]`
        IFS=$' \t\n'
        case "$OPTION" in
            TAG|EXTRA)
                eval ACCOUNT_$OPTION=\"$VALUE\"
                print_notification 0 "'$OPTION' set to '$VALUE'"
            ;;
            HOST)
                if [[ -z "$VALUE" ]]; then
                    ACCOUNT_HOST="localhost"
                    print_notification 2 "No host specified, using default value 'localhost'"
                else
                    ACCOUNT_HOST="$VALUE"
                    print_notification 0 "'HOST' set to '$VALUE'"
                fi
            ;;
            USER)
                if [[ -z "$VALUE" ]]; then
                    ACCOUNT_USER="$M7CM_DEFAULT_SSH_USER"
                    print_notification 2 "No user specified, using default ssh user '$M7CM_DEFAULT_SSH_USER'"
                else
                    ACCOUNT_USER="$VALUE"
                    print_notification 0 "'USER' set to '$VALUE'"
                fi
            ;;
            PORT)
                local REGEX='^[0-9]+$'
                if [[ "$VALUE" =~ $REGEX ]] && [[ "$VALUE" -ge 0 && "$VALUE" -le 65535 ]]; then
                    ACCOUNT_PORT="$VALUE"
                    print_notification 0 "'PORT' set to '$VALUE'"
                elif [[ -z "$VALUE" ]]; then
                    ACCOUNT_PORT="$M7CM_DEFAULT_SSH_PORT"
                    print_notification 2 "No port specified, using default port ssh port '$M7CM_DEFAULT_SSH_PORT'"
                else
                    ACCOUNT_PORT="$M7CM_DEFAULT_SSH_PORT"
                    print_notification 2 "'$VALUE' is not a valid port, using default ssh port  '$M7CM_DEFAULT_SSH_PORT'"
                fi
            ;;
            KEY)
                VALUE=$(eval echo "$VALUE")
                ## convert ~ to real location
                if [[ ! -f "$VALUE" ]]; then
                    print_notification 3 "Keyfile '$VALUE' not exist, failed to assign it."
                    return 1 # key not readable
                elif [[ ! -r "$VALUE" ]]; then
                    print_notification 3 "Keyfile '$VALUE' not readable, failed to assign it. Check your permission"
                    return 2 # not readable
                else
                    ACCOUNT_KEY="$VALUE"
                    print_notification 0 "'KEY' set to '$VALUE'"
                fi
            ;;
            NAME)
                if [[ -z "$ACCOUNT_NAME" ]]; then
                    print_notification 2 "Renaming aborted due to no account being selected"
                    return 3
                elif [[ -z "$VALUE" ]]; then
                    print_notification 3 "No new name assigned, 'NAME' kept not changed"
                    return 4
                fi
                if [[ -f "$PATH_DIRECTORY/account/$VALUE.conf" || -f "$PATH_DIRECTORY/account/$VALUE.server" ]]; then
                    interactive_yn N "An account with the same name '$VALUE' has already exist, are you sure you want to overwrite it?"
                    if [[ $? = 1 ]]; then
                        return 5
                    fi
                fi
                if [[ -s "$PATH_DIRECTORY/account/$VALUE.server" ]]; then
                    print_notification 2 "The current account is being used by the following servers:"
                    more "$PATH_DIRECTORY/account/$VALUE.server"
                    interactive_yn "Are you sure you want to rename this account? M7CM will try to change all 'SERVER_ACCOUNT' in assosiated server's configuration to '$VALUE' after rename. But if that failed, you will have to manually edit all those values manually."
                    if [[ $? = 0 ]]; then
                        local EDIT_SERVER=1
                    else
                        return 4
                    fi
                fi
                mv -f "$PATH_DIRECTORY/account/$ACCOUNT_NAME.conf" "$PATH_DIRECTORY/account/$VALUE.conf" 1>/dev/null 2>&1
                mv -f "$PATH_DIRECTORY/account/$ACCOUNT_NAME.server" "$PATH_DIRECTORY/account/$VALUE.server" 1>/dev/null 2>&1
                if [[ "$EDIT_SERVER" = 1 ]]; then
                    print_notification 1 "Trying to change all assosiated servers' account to '$VALUE'"
                    local SERVER_NAME
                    while read SERVER_NAME; do
                        if [[ -f "$PATH_DIRECTORY/server/$SERVER_NAME.conf" ]]; then
                            grep -q "^SERVER_ACCOUNT=\"$ACCOUNT_NAME\"$" "$PATH_DIRECTORY/server/$SERVER_NAME.conf"
                            if [[ $? = 0 ]]; then
                                sed -i "/^SERVER_ACCOUNT=\"$ACCOUNT_NAME\"$/ c SERVER_ACCOUNT=\"$VALUE\"" "$PATH_DIRECTORY/server/$SERVER.conf"
                            else
                                print_notification 2 "Server '$SERVER_NAME' is using another account, maybe you've manually edited it? "
                            fi
                        else
                            print_notification 2 "Assosiated server '$SERVER_NAME' does not exist, maybe you've manually removed it?"
                        fi
                    done < "$PATH_DIRECTORY/account/$VALUE.server"
                fi
                ACCOUNT_NAME="$VALUE"
                print_notification 0 "'NAME' set to '$VALUE'"
            ;;
            *)
                print_notification 1 "'$OPTION' is not an available option, ignored"
            ;;
        esac
        shift
    done
    return 0
} ##
assignment_server() {
    local CHANGE
    local OPTION
    local VALUE
    local IFS
    while [[ $# > 0 ]]; do
        CHANGE="$1"
        IFS=' ='
        read -r OPTION VALUE <<< "$CHANGE"
        OPTION=`echo "$OPTION" | tr [a-z] [A-Z]`
        local IFS=$' \t\n'
        case "$OPTION" in
            TAG|EXTRA_JAVA|EXTRA_JAR)
                eval SERVER_$OPTION="$VALUE"
                print_notification 1 "'$OPTION' is set to '$VALUE'"
                ;;
            PORT)
                local REGEX='^[0-9]+$'
                if [[ "$VALUE" =~ $REGEX ]] && [[ "$VALUE" -ge 0 && "$VALUE" -le 65535 ]]; then
                    ACCOUNT_PORT="$VALUE"
                    print_notification 0 "'PORT' set to '$VALUE'"
                elif [[ -z "$VALUE" ]]; then
                    print_notification 2 "No port specified, using default value '25565' as [port]"
                    ACCOUNT_PORT="25565"
                else
                    print_notification 2 "'$VALUE' is not a valid port, using default value '25565' as [port]"
                    ACCOUNT_PORT="25565"
                fi
                ;;
            DIRECTOTY)
                if [[ -z "$VALUE" ]]; then
                    SERVER_DIRECTORY='~'
                    print_notification 3 "'DIRECTORY' is empty, defaulting it to '~'"
                else
                    SERVER_DIRECTORY="$VALUE"
                    print_notification 1 "'DIRECTORY' is set to '$VALUE'"
                fi
                ;;
            JAR)
                if [[ -z "$VALUE" ]]; then
                    SERVER_DIRECTORY="server.jar"
                    print_notification 3 "'JAR' is empty, defaulting to 'server.jar'"
                else
                    SERVER_DIRECTORY="$VALUE"
                    print_notification 1 "'JAR' is set to '$VALUE'"
                fi
                ;;
            ACCOUNT)
                if [[ ! -f "$PATH_DIRECTORY/account/$VALUE.conf" ]]; then
                    print_notification 3 "Account '$VALUE' does not exist"
                    return 1 #Account not exist
                else
                    if [[ -f "$PATH_DIRECTORY/account/$ACCOUNT_NAME.server" ]]; then
                        sed -i "/^$SERVER_NAME$/"d "$PATH_DIRECTORY/account/$ACCOUNT_NAME.server"
                    fi
                    echo "$SERVER_NAME" >> "$PATH_DIRECTORY/account/$VALUE.server"
                    SERVER_ACCOUNT="$VALUE"
                    print_notification 1 "'ACCOUNT' is set to '$VALUE'"
                fi
                ;;
            RAM_MIN|RAM_MAX)
                VALUE=`echo "$VALUE" | tr [a-z] [A-Z]`
                if [[ "$VALUE" =~ ^[0-9]+[MG]$ ]]; then
                    local SIZE=${VALUE:0:-1}
                    if [[ "${VALUE: -1}" = "G" ]]; then
                        SIZE=$(( $SIZE * 1024 ))
                    fi
                    eval local COMPARE_$OPTION=$SIZE
                    if [[ $SIZE -lt 32 ]]; then
                        print_notification 3 "'$VALUE' is too small, you need at least 32M to even start a server instance."
                        return 4 #Too small
                    elif [[ $SIZE -lt 128 ]]; then
                        print_notification 2 "'$VALUE' seems to be too small, we suggest at least 128M, but maybe you can start a server with '$VALUE' ram?"
                        interactive_yn N "Set '$OPTION' to '$VALUE' anyway?"
                        if [[ $? = 0 ]]; then
                            print_notification 1 "'$OPTION' is set to '$VALUE'"
                            eval SERVER_$OPTION="$VALUE"
                        else
                            return 5 ## aborted, kind of small
                        fi
                    elif [[ $SIZE -gt 8192 ]]; then
                        print_notification 2 "'$VALUE' seems to be too large, 8G of ram is usually the most a normal minecraft server takes, and even that is already overkill under an extreme situation"
                        interactive_yn N "Set '$OPTION' to '$VALUE' anyway?"
                        if [[ $? = 0 ]]; then
                            print_notification 1 "'$OPTION' is set to '$VALUE'"
                            eval SERVER_$OPTION="$VALUE"
                        else
                            return 6 ## aborted, too large
                        fi
                    else
                        print_notification 1 "'$OPTION' is set to '$VALUE'"
                        eval SERVER_$OPTION="$VALUE"
                    fi
                elif [[ -z "$VALUE" ]]; then
                    local OLD_VALUE=$(eval echo \$SERVER_$OPTION)
                    if [[ ! -z "$OLD_VALUE" ]]; then
                        print_notification 2 "'$OPTION' is not changed ($OLD_VALUE)"
                    ## It is empty, should check if another value is also empty
                    ## Both empty
                    elif [[ -z "$SERVER_RAM_MIN" && -z "$SERVER_RAM_MAX" ]]; then
                        eval SERVER_$OPTION="1G"
                        print_notification 2 "'$OPTION' is empty, defaulting to 1G"
                    ## The other is not empty: ram_max
                    elif [[ "$OPTION" = "RAM_MIN" ]]; then
                        SERVER_RAM_MIN="$SERVER_RAM_MAX"
                        print_notification 2 "'RAM_MIN' is empty, defaulting to current maximum ram '$SERVER_RAM_MAX'"
                    ## The other is not empty: ram_min
                    elif [[ "$OPTION" = "RAM_MAX" ]]; then
                        SERVER_RAM_MAX="$SERVER_RAM_MIN"
                        print_notification 2 "'RAM_MAX' is empty, defaulting to current minimum ram '$SERVER_RAM_MIN'"
                    fi
                else
                    print_notification 3 "'$VALUE' is not a valid ram size. Accept: interger+M/G, i.e. 1024M, 1G"
                    return 7 ## illegal format
                fi
                ;;
            NAME)
                if [[ -z "$SERVER_NAME" ]]; then
                    print_notification 3 "Renaming aborted due to no server being selected"
                elif [[ ! -f "$PATH_DIRECTORY/server/$VALUE.conf" ]]; then
                    SERVER_NAME="$VALUE"
                    print_notification 0 "'NAME' set to '$VALUE'"
                elif [[ -f "$PATH_DIRECTORY/server/$VALUE.conf" ]]; then
                    if [[ ! -w "$PATH_DIRECTORY/server/$VALUE.conf" ]]; then
                        print_notification 3 "Renaming aborted. A server with the same name '$VALUE' has already exist and can't be overwriten due to lack of writing permission. Check your permission."
                    else
                        interactive_yn N "A server with the same name '$VALUE' has already exist, are you sure you want to overwrite it?"
                        if [[ $? = 0 ]]; then
                            mv -f "$PATH_DIRECTORY/account/$SERVER_NAME.conf" "$PATH_DIRECTORY/account/$VALUE.conf"
                            SERVER_NAME="$VALUE"
                            print_notification 0 "'NAME' set to '$VALUE'"
                        else
                            return 8 # abort overwriting
                        fi
                    fi  
                else
                    mv "$PATH_DIRECTORY/account/$SERVER_NAME.conf" "$PATH_DIRECTORY/account/$VALUE.conf" 
                    SERVER_NAME="$VALUE"
                    print_notification 0 "'NAME' set to '$VALUE'"
                fi
                ;;
            SCREEN)
                if [[ -z "$VALUE" ]]; then
                    print_notification 3 'Screen name must not be empty'
                elif [[ -z "$SERVE_NAME" ]]; then
                    print_notification 3 'No server is being selected, can not assign a screen name'
				elif  [[ -z "$SERVE_ACCOUNT" ]]; then
                    print_notification 3 'No account is being selected, can not assign a screen name'
                else 
                    check_status_screen "$VALUE" "$SERVER_ACCOUNT"
                    if [[ $? = 0 ]]; then
                        print_notification 3 "A screen with the same name '$VALUE' is already running using account '$SERVER_ACCOUNT', can not assign the screen name"
                    else
                        if [[ -s "$PATH_DIRECTORY/account/$SERVE_ACCOUNT" ]]; then
                            local SERVER_TEST
                            while read SERVER_TEST; do
                                grep -q "^SERVER_SCREEN=\"$VALUE\"$" $PATH_DIRECTORY/server/$SERVER_TEST.conf 1>/dev/null 2>&1
                                if [[ $? = 0 ]]; then
                                    print_notification 2 "The screen name '$VALUE' is already used by server '$SERVER_TEST'"
                                    local SCREEN_DUPLICATE=1
                                fi
                            done < "$PATH_DIRECTORY/account/$SERVE_ACCOUNT"
                            if [[ -z "$SCREEN_DUPLICATE" ]]; then
                                SERVER_SCREEN="$VALUE"
                                print_notification 0 "'SCREEN' set to '$VALUE'"
                            else
                                print_notification 3 "Can not assign the same screen name '$VALUE' as other servers using the same account '$SERVER_ACCOUNT'"
                            fi
                        else
                            SERVER_SCREEN="$VALUE"
                            print_notification 0 "'SCREEN' set to '$VALUE'"
                        fi
                    fi
                fi
                ;;
            *)
                print_notification 1 "'$OPTION' is not an available option, ignored"
                ;;
        esac
        shift
    done
    ## Compare ram size
    if [[ ! -z "$COMPARE_RAM_MIN" || ! -z "$COMPARE_RAM_MAX" ]]; then
        if [[ -z "$COMPARE_RAM_MIN" ]]; then
            local COMPARE_RAM_MIN=${SERVER_RAM_MIN:0:-1}
            if [[ "${VALUE: -1}" = "G" ]]; then
                COMPARE_RAM_MIN=$(( $COMPARE_RAM_MIN * 1024 ))
            fi
        elif [[ -z "$COMPARE_RAM_MAX" ]]; then
            local COMPARE_RAM_MAX=${SERVER_RAM_MAX:0:-1}
            if [[ "${VALUE: -1}" = "G" ]]; then
                COMPARE_RAM_MAX=$(( $COMPARE_RAM_MAX * 1024 ))
            fi
        fi
        if [[ $COMPARE_RAM_MIN -gt $COMPARE_RAM_MAX ]]; then
            SERVER_RAM_MIN="$SERVER_RAM_MAX"
            print_notification 2 "The mininum ram is greater than the maximum ($SERVER_RAM_MIN > $SERVER_RAM_MAX), 'RAM_MAX' is adjusted to '$SERVER_RAM_MIN'"
        fi
    fi
    return 0
}
#### sub functions, these functions are just meant to be used in other functions, and don't accpet arguments
utility_jar_name_fix() {
    local TMP
    while true; do
        TMP=${JAR_NAME,,}
        if [[ "${JAR_NAME: -4}" =~ ^.[jJ][aA][rR]$ ]]; then
            JAR_NAME="${JAR_NAME:0:-4}"
            local CUT=1
        else
            break
        fi
    done
    echo $CUT
    if [[ "$CUT" = 1 ]]; then
        print_notification 2 "You jar name has redundant .jar suffix and has been automatically cut to '$JAR_NAME'"
    fi
}  ## Fix jar name, cut out .jar extension
utility_jar_identify() {
    print_notification 1 "Auto-identifying jar information for JAR '$JAR_NAME'..." 
    if [[ ENV_LOCAL_JRE = 0 ]]; then
        print_notification 3 "Auto-identifying failed due to lacking of Java Runtime Environment" 
        return 1 # lacking of JRE
    fi
    local TMP="/tmp/M7CM-identifying-$JAR_NAME-`date +"%Y-%m-%d-%k-%M"`"
    mkdir "$TMP"
    print_notification 0 "Depending on the type of the jar, the performance of this host, and your network connection, it may take a few seconds or a few minutes to identify it. i.e. Paper pre-patch jar would download the vanilla jar and patch it"
    pushd "$TMP" 1>/dev/null 2>&1
    print_notification 1 "Switched to temporary folder '$TMP'"
    print_notification 2 'Identification started, do not interrupt unless it takes too long.'
    JAR_VERSION=$(java -jar "$PATH_DIRECTORY/jar/$JAR_NAME.jar" --version) 1>/dev/null 2>&1 3>&1
    if [[ $? = 0 ]]; then
        if [[ "$JAR_VERSION" =~ BungeeCord ]]; then 
            JAR_TYPE='BungeeCord'
            JAR_PROXY=1
            JAR_BUILDTOOL=0
            print_notification 1 'Detected a Bungeecord proxy server jar'
        elif [[ "$JAR_VERSION" =~ Waterfall ]]; then 
            JAR_TYPE='Waterfall'
            JAR_PROXY=1
            JAR_BUILDTOOL=0
            print_notification 1 'Detected a Waterfull proxy server jar'
        elif [[ "$JAR_VERSION" =~ Spigot ]]; then 
            JAR_TYPE='Spifot'
            JAR_PROXY=0
            JAR_BUILDTOOL=0
            print_notification 1 'Detected a Spigot game server jar'
        elif [[ "$JAR_VERSION" =~ Paper ]]; then 
            JAR_TYPE='Paper'
            JAR_PROXY=0
            JAR_BUILDTOOL=0
            if [[ "$JAR_VERSION" =~ 'Downloading vanilla jar...' ]]; then
                print_notification 1 'Detected a Paper pre-patch game server jar'
                local TARGET=$(echo `ls $TMP/cache/patched_*.jar` | awk '{print $1}') 1>/dev/null 2>&1
                if [[ "$TARGET" ]]; then
                    JAR_VERSION_MC=${BASENAME:8:-4} 
                    JAR_VERSION="git${JAR_VERSION#*git}"
                    mv -f "$TARGET" "$PATH_DIRECTORY/jar/$JAR_NAME.jar"
                    print_notification 0 'Successfully patched paper and overwritten existing paper pre-patch jar with post-patch jar'
                    return 0
                else
                    print_notification 3 'The PaperMC pre-patch jar file should download a vanilla jar and patch it. But it seems it failed to patch the vanilla jar. Maybe you should check your network connection.'
                    popd
                    print_notification 1 "Got out from temporary folder '$TMP'"
                    rm -rf "$TMP"
                    return 2 ## paper patch error
                fi
            else    
                print_notification 1 'Detected a Paper post-patch game server jar'
            fi
        elif [[ "$JAR_VERSION" =~ 'version is not a recognized option' ]]; then
            JAR_PROXY=0
            JAR_BUILDTOOL=0
            JAR_TYPE='Vanilla'
            JAR_VERSION='Unknown'
            print_notification 1 'Detected a Vanilla game server jar'
        else
            JAR_TYPE='Unknown'
            JAR_VERSION='Unknown'
            JAR_VERSION_MC='Unknown'
            JAR_PROXY=0
            JAR_BUILDTOOL=0
            print_notification 2 'We could not identify the its type'
        fi
    else
        if [[ "$JAR_VERSION" =~ "BuildTools" ]]; then
            print_notification 1 'Detected a Spigot BuildTools jar'
            echo "Sweet! You can build Spigot jars using '$PATH_SCRIPT jar build [jar] $JAR_NAME [version]'!"
            JAR_PROXY=0
            JAR_BUILDTOOL=1
            JAR_TYPE="Spigot Buildtools"
            JAR_VERSION="git${JAR_VERSION#*git}"
            JAR_VERSION=`echo $JAR_VERSION | awk '{print $1}'`
            JAR_VERSION_MC="From 1.8"
            JAR_TAG="Sweet! You can build a spigot jar using '$PATH_SCRIPT jar build [jar] $JAR_NAME [version]!'"
        elif [[ "$JAR_VERSION" =~ "Error: Invalid or corrupt jarfile" ]]; then
            interactive_yn Y "The jar file is broken, delete it?"
            if [[ $? = 0 ]]; then
                rm -f "$PATH_DIRECTORY/jar/$JAR_NAME.jar" "$PATH_DIRECTORY/jar/$JAR_NAME.conf"
                popd
                rm -rf "$TMP"
                print_notification 1 "Got out from temporary folder '$TMP'"
                return 3 #corrupt jar and deleted
            else
                JAR_PROXY=0
                JAR_BUILDTOOL=0
                JAR_TYPE='Corrupt'
                JAR_VERSION='Corrupt'
                JAR_VERSION_MC='None'
                JAR_TAG='This jar is definitely broken, do not use it to deploy servers!'
            fi
        fi
    fi
    popd 1>/dev/null 2>&1
    print_notification 1 "Got out from temporary folder '$TMP'"
    rm -rf "$TMP"
    return 0
} ## Identify the type of the jar file, need $JAR_NAME 
#### action functions, these functions are directly called by main function to process users' arguments
## jar related
action_jar_import() {
    if [[ $# -lt 2 ]]; then
        print_notification 3 "Too few arguments!"
        interactive_anykey
        action_help
        return 255 # Too few arguments
    fi
    check_environment_local subfolder-jar
    JAR_NAME="$1"
    utility_jar_name_fix
    if [[ -f "$PATH_DIRECTORY/jar/$JAR_NAME.jar" ]]; then
        interactive_yn N "A jar with the same name '$JAR_NAME' has already been defined. Should we remove it first?"
        if [[ $? = 0 ]]; then
            action_jar_remove "$JAR_NAME"
            if [[ $? != 0 ]]; then
                return 1 ## already exist and can not overwrite
            fi
        else
            return 2 ## Aborted overwriting
        else
    fi
    if [[ -f "$2" ]]; then
        print_notification 1 "Importing from local file '$2'..."
        local TMP=`echo "${2: -4}" | tr [A-Z] [a-z]`
        if [[ ! -r "$2" ]]; then
            print_notification 3 "No read permission for file $2, importing failed. check your permission"
            return 3 ## No read permission for local file
        elif [[ "$TMP" != ".jar" ]]; then
            print_notification 1 "The file extension of this file is not .jar, maybe you've input a wrong file, but M7CM will try to import it anyway"
        fi
        \cp -f "$2" "$PATH_DIRECTORY/jar/$JAR_NAME.jar"
        if [[ $? != 0 ]]; then
            print_notification 3 "Failed to copy file $2, importing failed"
            return 4 ## failed to copy. wtf is that reason?
        else
            JAR_TAG="Imported at `date +"%Y-%m-%d-%k:%M"` from local source $2"
        fi
    else
        local REGEX='(https?|ftp|file)://[-A-Za-z0-9\+&@#/%?=~_|!:,.;]*[-A-Za-z0-9\+&@#/%=~_|]'
        if [[ "$2" =~ $REGEX ]]; then
            print_notification 1 "Importing jar '$JAR_NAME' from online url '$2'"
            if [[ "$ENV_METHOD_DOWNLOAD" = 0 ]]; then
                print_notification 3 'Can not import from online url due to lacking of download method: neither wget nor curl is detected'
                return 5
            fi
            if [[ "$M7CM_METHOD_DOWNLOAD" = wget ]]; then
                wget -O "$PATH_DIRECTORY/jar/$JAR_NAME.jar" "$2"
            else
                curl -o "$PATH_DIRECTORY/jar/$JAR_NAME.jar" "$2"
            fi            
            if [[ $? != 0 ]]; then
                print_notification 3 "Failed to download file $2, importing failed. check your network connection"
                return 5
            else
                JAR_TAG="Imported at `date +"%Y-%m-%d-%k:%M"` from online source $2"
            fi
        else
            print_notification 3 "$2 is neither an existing local file nor a valid url, importing failed"
            return 6
        fi
    fi
    print_notification 1 "Successfully imported jar '$JAR_NAME'"
    print_counting 3 '' 'Redirecting to jar configuration page'
    local JAR_NEW=1
    action_jar_config "$JAR_NAME" "TAG = $JAR_TAG"
    return 0
} ## Usage: action_jar_download [jar name] [link/path]
    ## return: 0 success, 1 abort overwriting, 2 already exist and can not overwrite, 3 no read permission for local source, 4 failed to copy, 5 failed to cownload, 6 invalid source
action_jar_config() {
    if [[ $# = 0 ]]; then
        print_notification 3 "Too few arguments!"
        interactive_anykey
        action_help
        return 255 # Too few arguments
    fi
    check_environment_local subfolder-jar
    JAR_NAME="$1"
    utility_jar_name_fix
    JAR_TAG=''
    JAR_TYPE=''
    JAR_VERSION=''
    JAR_VERSION_MC=''
    JAR_PROXY=0
    JAR_BUILDTOOL=0
    if [[ -z "$JAR_NEW" ]]; then
        config_read_jar
        if [[ $? != 0 ]]; then
            return 1
        fi
    fi
    if [[ "$2" ]]; then
        assignment_jar "${@:2}"
    fi
    ## Get jar size
    local JAR_SIZE=`wc -c $PATH_DIRECTORY/jar/$JAR_NAME.jar |awk '{print $1}'`
    ## Interactive-menu
    while true; do
        clear
        print_draw_line
        print_center "Configuration for Jar File '$JAR_NAME'"
        print_draw_line
        print_multilayer_menu "NAME: $JAR_NAME" "" 0
        print_multilayer_menu "SIZE: $JAR_SIZE" 'File size, not a configurable option.'
        print_multilayer_menu "TAG: $JAR_TAG" 'Only for identification.'
        print_multilayer_menu "TYPE: $JAR_TYPE" 'What kind of jar it is, i.e. Spigot, Paper, Vanilla. Only for identification.'
        print_multilayer_menu "PROXY: $JAR_PROXY" "If it contains a proxy server, i.e. Waterfall, Bungeecord. Currently this option does nothing. Accept: 0/1"
        print_multilayer_menu "BUILDTOOL: $JAR_BUILDTOOL" "Whether it contains Spigot buildtools. Must be 1 if you want to use it to build a jar. Accept: 0/1"
        print_multilayer_menu "VERSION: $JAR_VERSION" "The version of the jar itself. Only for identification."
        print_multilayer_menu "VERSION_MC: $JAR_VERSION_MC" "The version of Minecraft this jar can host. Only for identification." 1 1
        print_draw_line
        print_notification 0 "Type in the option you want to change and its new value split by =, i.e. 'TAG = This is my first jar!' (without quote and option is case insensitive, i.e. pRoXy). You can also type 'identify' to let M7CM auto-identify it, or 'confirm' or 'save' to save thost values:"
        read -p " >>> " COMMAND
        case "${COMMAND,,}" in
            identify)
                utility_jar_identify
                if [[ $? = 3 ]]; then
                    return 3 ## jar broken and deleted
                fi
                subinteractive_anykey
            ;;
            confirm|save)
                config_write_jar
                return 0 # success
            ;;
            '')
                print_notification 2 'You must input at least one option'
                interactive_anykey 
            ;;
            *)
                assignment_jar "$COMMAND"
                subinteractive_anykey
            ;;
        esac
    done
} ## Usage: action_jar_config [jar name] [option1=value1] [option2=value2]
    ## return: 0 success, 1 not exist, 2 existing configuration not writable, 3 jar broken and deleted
action_jar_info() {
    if [[ $# = 0 ]]; then
        print_notification 3 "Too few arguments!"
        interactive_anykey
        action_help
        return 255 # Too few arguments
    fi
    check_environment_local subfolder-jar
    print_draw_line
    print_center "Jar file information"
    print_draw_line
    if [[ $# = 1 ]]; then
        JAR_NAME="$1"
        utility_jar_name_fix
        print_multilayer_menu "$JAR_NAME" "" 0
        if [[ ! -f "$PATH_DIRECTORY/jar/$JAR_NAME.jar" ]]; then
            print_multilayer_menu '\e[41mThis jar file does not exist' '' 1 1
            return 1 #invalid jar
        else
            print_info_jar
        fi
        print_draw_line
    else
        local ORDER=1
        while [[ $# > 0 ]]; do
            JAR_NAME="$1"
            utility_jar_name_fix
            print_multilayer_menu "$ORDER. $JAR_NAME" "" 0
            if [[ ! -f "$PATH_DIRECTORY/jar/$JAR_NAME.jar" ]]; then
                print_multilayer_menu '\e[41mThis jar file does not exist' '' 1 1
            else
                print_info_jar
            fi
            shift
            let ORDER++
            print_draw_line
        done
    fi
    return 0
} ## Usage: action_jar_info [jar name]
    ## return: 0 success, 1 not exist
action_jar_list() {
    check_environment_local subfolder-jar
    print_draw_line
    print_center "Jar file list"
    print_draw_line
    ls $PATH_DIRECTORY/jar/*.jar
    if [[ $? != 0 ]]; then
        print_notification 3 "You have not added any account yet. Use '$PATH_SCRIPT jar import/build/pull ...' to add a jar first"
        return 1
    fi
    local ORDER=1
    for JAR_NAME in $(ls $PATH_DIRECTORY/jar/*.jar); do
        JAR_NAME=$(basename $JAR_NAME)
        utility_jar_name_fix
        print_multilayer_menu "$ORDER. $JAR_NAME" "" 0
        print_info_jar
        let ORDER++
    done
    return 0
} ## Usage: action_jar_list. NO ARGUMENTS. return: 0 success
action_jar_remove() {
    if [[ $# = 0 ]]; then
        print_notification 3 "Too few arguments!"
        interactive_anykey
        action_help
        return 255 # Too few arguments
    fi
    check_environment_local subfolder-jar
    if [[ $# = 1 ]]; then
        JAR_NAME="$1"
        utility_jar_name_fix
        if [[ ! -f "$PATH_DIRECTORY/jar/$JAR_NAME.jar" ]]; then
            print_notification 3 "The jar '$JAR_NAME' you specified does not exist!"
            return 1 ## not exist
        elif [[ ! -w "$PATH_DIRECTORY/jar/$JAR_NAME.jar" ]]; then
            print_notification 3 "Removing failed due to lacking of writing permission of jar file '$JAR_NAME.jar'"
            return 2 ## jar not writable 
        elif [[ -f "$PATH_DIRECTORY/jar/$JAR_NAME.conf" && ! -w "$PATH_DIRECTORY/jar/$JAR_NAME.conf" ]]; then
            print_notification 3 "Removing failed due to lacking of writing permission of configuration file '$JAR_NAME.conf'"
            return 3 ## configuration not writable 
        else
            interactive_yn N "Are you sure you want to remove jar '$JAR_NAME' from your library?"
            if [[ $? = 0 ]]; then
                rm -f "$PATH_DIRECTORY/jar/$JAR_NAME.jar"
                rm -f "$PATH_DIRECTORY/jar/$JAR_NAME.conf" 1>/dev/null 2>&1
                print_notification 1 "Removed jar '$JAR_NAME' from library"
                return 0
            else
                return 4 ## User refused 
            fi
        fi
    else
        while [[ $# > 0 ]]; do
            action_jar_remove "$1"
            shift
        done
    fi
} ## Usage: action_jar_remove [jar name1] [jar name2]. return: 0 success, 1 not exist, 2 jar no writable, 3 conf not writable,
action_jar_build() {
    print_draw_line
    print_center "Spigot Auto-Building Function"
    print_draw_line
    if [[ $# < 2 ]]; then
        print_notification 3 "Too few arguments!"
        action_help
        interactive_anykey
        return 255 # Too few arguments
    fi
    if [[ "$ENV_LOCAL_JRE" = 0 ]]; then
        print_notification 3 "Spigot build function is not available due to lacking of Java Runtime Environment"
        return 1 #environment error-jre
    elif [[ "$ENV_LOCAL_GIT" = 0 ]]; then
        print_notification 3 "Spigot build function is not available due to lacking of Git"
        return 2 #environment error-git
    fi
    JAR_NAME="$2"
    utility_jar_name_fix
    if [[ ! -f "$PATH_DIRECTORY/jar/$JAR_NAME.jar" ]]; then
        print_notification 3 "The buildtool you set does not exist"
        return 3 #buildtool not exist
    fi
    config_read_jar
    if [[ "$JAR_BUILDTOOL" != 1 ]]; then
        print_notification 3 "The buildtool you set was not set as a buildtool"
        return 4 # not a buildtool
    fi
    local BUILDTOOL="$JAR_NAME"
    JAR_NAME="$1"
    utility_jar_name_fix
    if [[ -f "$PATH_DIRECTORY/jar/$JAR_NAME.jar" ]]; then
        interactive_yn N "A jar with the same name '$JAR_NAME' has already been defined. Should we remove it first?"
        if [[ $? = 0 ]]; then
            action_jar_remove "$JAR_NAME"
            if [[ $? != 0 ]]; then
                return 5 ## already exist and can not overwrite
            fi
        else
            return 6 ## Aborted overwriting
        else
    fi
    local REGEX='^1.[0-9]+.[0-9]+$'
    if [[ -z "$3" || "${3,,}" = "latest" ]]; then
        local VERSION="latest"
    elif [[ "$3" =~ ^[1-3][0-9]w[0-9][0-9][a-e]$ ]]; then
        print_notification 2 "You are trying to build snapshot rev '$3', Spigot does not support Minecraft snapshot versions by the day I write M7CM. If you believe Spigot supports snapshot versions now, you can ignore this warning."
        interactive_yn N "Continue anyway?"
        if [[ $? = 0 ]]; then
            local VERSION="$3"
        else
            return 7 ##  user aborted because of suspicious version
        fi

    elif [[ "$3" =~ ^1\.[1-9][0-9]?(\.[1-9][0-9]?)?$ ]]; then
        print_notification 1 "Version '$3' seems to be a release verison, but it may be not buildable because Spigot only supports certain Minecraft release versions."
    else
        interactive_yn N "The version '$3' seems not a correct version, do you want to build it anyway?"
        if [[ $? = 0 ]]; then
            local VERSION="$3"
        else
            return 7 # user aborted because of suspicious version
        fi
    fi
    local TMP="/tmp/M7CM-Spigot-building-$JAR_NAME-`date +"%Y-%m-%d-%k-%M"`"
    mkdir "$TMP"
    pushd "$TMP" 1>/dev/null 2>&1
    print_notification 1 "Switched to temporary folder '$TMP'"
    print_notification 1 "Building Spigot jar '$JAR_NAME' rev '$VERSION' using Buildtools jar '$BUILDTOOL'. This may take a few minutes depending on your network connection and hardware performance"
    print_notification 1 "Using build command: java -jar $PATH_DIRECTORY/jar/$BUILDTOOL.jar --rev $VERSION"
    print_notification 2 'You can try this command if M7CM fails to build it and you believe the trouble is on M7CM side to build by yourself.'
    java -jar "$PATH_DIRECTORY/jar/$BUILDTOOL.jar" --rev "$VERSION"
    if [[ $? != 0 ]]; then
        print_notification 3 "Failed to build Spigot version $BUILD_VERSION"
        print_notification 1 "The command M7CM used was 'java -jar $PATH_DIRECTORY/jar/$BUILDTOOL.jar --rev $VERSION', if you believe the trouble is on M7CM side, you can try to build by yourself"
        popd 1>/dev/null 2>&1
        print_notification 1 "Got out from temporary folder '$TMP'"
        rm -rf "$TMP"
        return 8 #build error
    fi
    local TARGET=$(echo `ls spigot-*.jar` | awk '{print $1}') 1>/dev/null 2>&1
    if [[ $? != 0 ]]; then
        print_notification 2 "Failed to detect compiled jar '$JAR_NAME', no built Spigot jars detected in temporary folder, this is the file list of temporary folder: "
        ls 
        print_notification 0 "The name of a freshly built spigot jar usually starts with 'spigot' and ends with '.jar', with version in the middle, sometimes with 'snapshot'. And M7CM did not detect any "
        interactive_yn N 'Do you believe that Spigot jar is successfully built but M7CM failed to recognise it?'
        popd 1>/dev/null 2>&1
        print_notification 1 "Got out from temporary folder '$TMP'"
        if [[ $? = 0 ]]; then
            print_notification 1 "M7CM will exit while keeping the temporary folder, you can then try '$PATH_SCRIPT jar import [$JAR_NAME or other jar name] $TMP/[file name you think is the Spigot jar]' to manually add the jar to library."
            print_notification 0 "Once complete, you can use 'rm -rf $TMP' to remove the temporary folder."
            return 9
        else
            rm -rf "$TMP"
            return 10 #not exist
        fi
    fi
    cp "$TARGET" "$PATH_DIRECTORY/jar/$JAR_NAME.jar"
    popd 1>/dev/null 2>&1
    print_notification 1 "Got out from temporary folder '$TMP'"
    rm -rf "$TMP"
    print_notification 1 "Successfully built Spigot jar '$JAR_NAME' rev '$VERSION' using Buildtools jar '$BUILDTOOL'! It's already added in your jar library."
    print_counting 3 '' 'Redirecting to jar configuration page'
    action_jar_config "$JAR_NAME" "TAG = Built at `date +"%Y-%m-%d-%k:%M"` using M7CM" "TYPE = Spigot" "PROXY = 0" "VERSION = Spigot-$VERSION" "VERSION_MC = $VERSION" "BUILDTOOL = 0"
    return 0
} ## Usage: action_jar_build [jar name] [buildtool] [version]
    ## Return: 0 success 1 environment error-jre 2 environment error-git, 3 buildtool not exist, 4 not a buildtool, 5 can not overwrite existing jar, 6 user aborted overwriting, 7 user aborted because of suspicious version, 8 build error,9 build failed
## account related
action_account_define() {
    if [[ $ENV_LOCAL_SSH = 0 ]]; then
        print_notification 4 'Remote function is disabled due to lacking of SSH'
    fi
    if [[ $# -lt 5 ]]; then
        print_notification 3 "Too few arguments!"
        interactive_anykey
        action_help
        return 255 # Too few arguments
    fi
    check_environment_local subfolder-account
    if [[ -f "$PATH_DIRECTORY/account/$1.conf" ]]; then
        interactive_yn N "An account with the same name '$1' has already been defined. Should we remove it first?"
        if [[ $? = 0 ]]; then
            action_account_remove "$1"
            if [[ $? != 0 ]]; then
                return 1 ## already exist and can not overwrite
            fi
        else
            return 2 ## Aborted overwriting
        else
    fi
    print_counting 3 '' 'Redirecting to account configuration page'
    local ACCOUNT_NEW=1
    action_account_config "$1" "HOST = $2" "TAG = Defined at `date +"%Y-%m-%d-%k-%M"`" "PORT = $3" "USER = $4" "KEY = $5" 
    if [[ $? = 0 ]]; then
        print_notification 1 "Successfully added account '$1'"
    else
        print_notification 3 "Failed to add server '$1'"
        return 3 # failed
    fi
} ## Usage: action_account_define [account name] [host] [port] [user] [key]
    ## Return: 0 success, 1 can not overwrite existing account, 2 aborted overwriting
action_account_config() {
    if [[ $# = 0 ]]; then
        action_help
        print_notification 3 "Too few arguments!"
        interactive_anykey
        return 255 # Too few arguments
    fi
    check_environment_local subfolder-account
    ACCOUNT_NAME="$1"
    ACCOUNT_TAG=''
    ACCOUNT_HOST=''
    ACCOUNT_PORT=''
    ACCOUNT_USER=''
    ACCOUNT_KEY=''
    ACCOUNT_EXTRA=''
    local ACCOUNT_VALID=0
    if [[ -z "$ACCOUNT_NEW" ]]; then
        config_read_account
        if [[ $? != 0 ]]; then
            return 1
        fi
    fi
    if [[ "$2" ]]; then
        assignment_account "${@:2}"
    fi
    while true; do
        clear
        print_draw_line
        print_center "Configuration for Account '$ACCOUNT_NAME'"
        print_draw_line
        print_multilayer_menu "NAME: $ACCOUNT_NAME" "" 0
        print_multilayer_menu "TAG: $ACCOUNT_TAG" "Just for memo"
        print_multilayer_menu "HOST: $ACCOUNT_HOST" "Can be domain or ip, i.e. mc.mydomain.com, or 33.33.33.33. Default: '$M7CM_DEFAULT_SSH_HOST'"
        print_multilayer_menu "PORT: $ACCOUNT_PORT" "Interger, 0-65535. Default: '$M7CM_DEFAULT_SSH_PORT'"
        print_multilayer_menu "USER: $ACCOUNT_USER" "User name will be used to login. Default: current user('$M7CM_DEFAULT_SSH_USER')"
        print_multilayer_menu "KEY: $ACCOUNT_KEY" "Private key file used to login"
        if [[ -z "$ACCOUNT_EXTRA" ]]; then
            print_multilayer_menu "EXTRA: $ACCOUNT_EXTRA" "Extra arguments used for SSH. DO NOT EDIT THIS if you don't know what you are doing" 1 1
        else
            print_multilayer_menu "EXTRA: $ACCOUNT_EXTRA" "Extra arguments used for SSH." 1 1
        fi
        print_draw_line
        print_notification 1 "Current SSH command: 'ssh $ACCOUNT_HOST -p $ACCOUNT_PORT -l $ACCOUNT_USER -i $ACCOUNT_KEY $ACCOUNT_EXTRA'"
        print_draw_line
        if [[ $ACCOUNT_VALID = 1 ]]; then
            print_notification 1 "This account is valid √ " "You can type 'save' or 'confirm' to save it now"
        elif [[ $ACCOUNT_VALID = 0 ]]; then
            print_notification 2 "This account is invalid X " "Type 'validate' to validate it first"
        fi
        print_draw_line
        print_notification 0 "Type in the option you want to change and its new value split by =, i.e. 'PORT = 22' (without quote and option is not case sensitive, i.e. CoNfIrM)."
        read -p ">>>" COMMAND
        case "${COMMAND,,}" in
            validate)
                check_validate_account
            ;;
            confirm|save)
                if [[ $ACCOUNT_VALID = 1 ]]; then
                    config_write_account
                    return 0
                elif [[ $ACCOUNT_VALID = 0 ]]; then
                    print_notification 3 "This account is invalid" "You must use 'validate' to validate it first"
                fi
            ;;
            *)
                assignment_account "$COMMAND"
                if [[ "$ACCOUNT_VALID" = 1 ]]; then
                    print_notification 2 "New value assigned, you must validate again."
                fi
                ACCOUNT_VALID=0
            ;;
        esac
        interactive_anykey
    done
} ## Usage: action_account_config [account name] [option1=value1] [option2=value2] ...
action_account_info() {
    if [[ $# = 0 ]]; then
        action_help
        print_notification 3 "Too few arguments!"
        interactive_anykey
        return 255 # Too few arguments
    fi
    check_environment_local subfolder-account
    print_draw_line
    print_center "Account information"
    print_draw_line
    if [[ $# = 1 ]]; then
        print_multilayer_menu "$1" '' 0
        if [[ ! -f "$PATH_DIRECTORY/account/$1.conf" ]]; then
            print_multilayer_menu '\e[41mThis account does not exist' '' 1 1
            return 1 # not exist
        else
            print_info_account "$1"
        fi
        print_draw_line
    else
        local ORDER=1
        while [[ $# > 0 ]]; do
            print_multilayer_menu "$ORDER. $ACCOUNT_NAME" '' 0
            if [[ ! -f "$PATH_DIRECTORY/account/$1.conf" ]]; then
                print_multilayer_menu '\e[41mThis account does not exist' '' 1 1
                return 1 # not exist
            else
                print_info_account "$1"
            fi
            shift
            let ORDER++
            print_draw_line
        done
    fi
    print_draw_line
    return 0
}
action_account_list() {
    check_environment_local subfolder-account
    print_draw_line
    print_center "Account List"
    print_draw_line
    ls $PATH_DIRECTORY/account/*.conf 1>/dev/null 2>&1
    if [[ $? != 0 ]]; then
        print_notification 3 "You have not added any account yet. Use '$PATH_SCRIPT account define ...' to define an account first"
        return 1
    fi
    local ORDER=1
    for ACCOUNT_NAME in $(ls $PATH_DIRECTORY/account/*.conf); do
        ACCOUNT_NAME=$(basename $ACCOUNT_NAME)
        ACCOUNT_NAME=${ACCOUNT_NAME:0:-5}
        print_multilayer_menu "No.$ORDER $ACCOUNT_NAME" '' 0
        print_info_account
        print_draw_line
        let ORDER++
    done
    return 0
}
action_account_remove() {
    if [[ $# = 0 ]]; then
        print_notification 3 "Too few arguments!"
        interactive_anykey
        action_help
        return 255 # Too few arguments
    fi
    check_environment_local subfolder-account
    if [[ $# = 1 ]]; then
        if [[ ! -f "$PATH_DIRECTORY/account/$1.conf" ]]; then
            print_notification 3 "The account '$1' you specified does not exist!"
            return 1 ## not exist
        elif [[ ! -w "$PATH_DIRECTORY/account/$1.conf" ]]; then
            print_notification 3 "Removing failed due to lacking of writing permission of configuration file '$1.conf'"
            return 2 ## jar not writable 
        elif [[ -f "$PATH_DIRECTORY/account/$1.server" ]]; then
            if [[ -s "$PATH_DIRECTORY/account/$1.server" ]]; then
                print_notification 3 "Can not remove account '$1', this account is being used by the following servers:"
                more "$PATH_DIRECTORY/account/$1.server"
                return 3
            elif [[ ! -w "$PATH_DIRECTORY/account/$1.server" ]]; then
                print_notification 3 "Can not remove account '$1', can not remove the file which records servers using this account."
                return 4
            fi
        else
            interactive_yn N "Are you sure you want to remove account '$1' from your library?"
            if [[ $? = 0 ]]; then
                rm -f "$PATH_DIRECTORY/account/$1.conf"
                rm -f "$PATH_DIRECTORY/account/$1.server" 1>/dev/null 2>&1
                print_notification 1 "Removed account '$1' from library"
                return 0
            else
                return 5 ## User refused 
            fi
        fi
    else
        while [[ $# > 0 ]]; do
            action_account_remove "$1"
            shift
        done
    fi
}
action_server_define() {
    if [[ $# -lt 5 ]]; then
        print_notification 3 "Too few arguments!"
        interactive_anykey
        action_help
        return 255 # Too few arguments
    fi
    check_environment_local subfolder-server
    if [[ -f "$PATH_DIRECTORY/server/$1.conf" ]]; then
        print_notification 2 "There's already a server with the same name '$1'"
        interactive_yn N "Should we remove it?" 
        if [[ $? != 0 ]]; then
            return 2 # user give up
        fi
        action_server_remove "$1"
        if [[ $? != 0 ]]; then
            return 3 
        fi
    fi
    action_server_config "$1" "ACCOUNT = $2" "DIRECTORY = $3" "PORT= $4" "RAM_MAX = $5" "RAM_MIN = $6" "JAR = $7" "EXTRA_JAVA = $8" "EXTRA_JAR = $9" "TAG = Added at `date +"%Y-%m-%d-%k:%M"`" "SCREEN = M7CM-`date +%s%N`"
    if [[ $? = 0 ]]; then
        print_notification 1 "Successfully added server '$1'"
    else
        print_notification 3 "Failed to add server '$1'"
        return 3 # failed
    fi
} ## Usage: action_server_define [server] [account] [directory] [port] [max ram] [min ram] [remote jar] [java extra arguments] [jar extra arguments]
action_server_config() {
    if [[ $# = 0 ]]; then
        action_help
        print_notification 3 "Too few arguments!"
        interactive_anykey
        return 255 # Too few arguments
    fi
    check_environment_local subfolder-server
    SERVER_NAME="$1"
    SERVER_TAG=''
    SERVER_DIRECTORY=''
    SERVER_PORT="$M7CM_DEFAULT_SERVER_PORT"
    SERVER_RAM_MAX='1G'
    SERVER_RAM_MIN='1G'
    SERVER_JAR="$M7CM_DEFAULT_SERVER_JAR"
    SERVER_EXTRA_JAVA=''
    SERVER_EXTRA_JAR=''
    SERVER_SCREEN=''
    local SERVER_VALID=0
    if [[ -z "$SERVER_NEW" ]]; then
        config_read_server
        if [[ $? != 0 ]]; then
            return 1
        fi
    fi
    if [[ ! -z "$2" ]]; then
        assignment_server "${@:2}"
    fi
    while true; do
        clear
        print_draw_line
        print_center "Configuration for Server '$SERVER_NAME'"
        print_draw_line
        print_multilayer_menu "NAME: $SERVER_NAME" "" 0
        print_multilayer_menu "TAG: $SERVER_TAG" 
        print_multilayer_menu "DIRECTORY: $SERVER_DIRECTORY" "Remote working directory. Default: ~"
        print_multilayer_menu "PORT: $SERVER_PORT" "Interger. Default: '$M7CM_DEFAULT_SERVER_PORT'. For proxy servers like Waterfall and BungeeCord or other strange servers, you have to manually edit the 'query_port' in config.yml"
        print_multilayer_menu "RAM_MAX: $SERVER_RAM_MAX" "Interger+M/G, i.e. 1024M. Default:1G, not less than RAM_MIN"
        print_multilayer_menu "RAM_MIN: $SERVER_RAM_MIN" "Interger+M/G, i.e. 1024M. Default:1G, not greater than RAM_MAX"
        print_multilayer_menu "JAR: $SERVER_RAM_MIN" "Remote server jar file with file extention. Can be absolute path. Default: server.jar"
        if [[ -z "$SERVER_EXTRA_JAVA" ]]; then
            print_multilayer_menu "EXTRA_JAVA: $SERVER_EXTRA_JAVA" "Extra arguments for java, i.e. -XX:+UseG1GC will enable garbage collection. Usually you don't need this"
        else
            print_multilayer_menu "EXTRA_JAVA: $SERVER_EXTRA_JAVA"
        fi
        if [[ -z "$SERVER_EXTRA_JAR" ]]; then
            print_multilayer_menu "EXTRA_JAR: $SERVER_EXTRA_JAR" "Extra arguments for the jar itself, i.e. --host <IP address> will make a Spigot server bind to this IP address. DO NOT EDIT THIS if you don't know what you are doing" 
        else
            print_multilayer_menu "EXTRA: $SERVER_EXTRA" "Extra arguments used for SSH." 
        fi
        print_multilayer_menu "SCREEN: $SERVER_SCREEN" "The name of the screen session, usually there's no need to change this" 1 1
        print_draw_line
        print_notification 1 "Current Minecraft startup command: java -Xmx$SERVER_RAM_MAX -Xms$SERVER_RAM_MIN $SERVER_EXTRA_JAVA -jar $SERVER_JAR nogui --port $SERVER_PORT $SERVER_EXTRA_JAR"
        # config_read_account "$1"
        # if [[ "$M7CM_HIDE_KEY_PATH" = 0 ]]; then
        #     print_notification 1 "Current full startup command: ssh $ACCOUNT_HOST -oBatchmode=yes -p $ACCOUNT_PORT -l $ACCOUNT_USER -i $ACCOUNT_KEY $ACCOUNT_EXTRA \"cd $SERVER_DIRECTORY; screen -mSUd $SERVER_SCREEN java -Xmx$SERVER_RAM_MAX -Xms$SERVER_RAM_MIN $SERVER_EXTRA_JAVA -jar $SERVER_JAR nogui --port $SERVER_PORT $SERVER_EXTRA_JAR\""
        # else
        #     print_notification 1 "Current full startup command: ssh $ACCOUNT_HOST -oBatchmode=yes -p $ACCOUNT_PORT -l $ACCOUNT_USER -i ********** $ACCOUNT_EXTRA \"cd $SERVER_DIRECTORY; screen -mSUd $SERVER_SCREEN java -Xmx$SERVER_RAM_MAX -Xms$SERVER_RAM_MIN $SERVER_EXTRA_JAVA -jar $SERVER_JAR nogui --port $SERVER_PORT $SERVER_EXTRA_JAR\""
        # fi
        print_draw_line
        if [[ $ACCOUNT_VALID = 1 ]]; then
            print_notification 1 "This server is valid √ " "You can type 'save' or 'confirm' to save it now"
        elif [[ $ACCOUNT_VALID = 0 ]]; then
            print_notification 1 "This server is invalid X " "Type 'validate' to validate it first"
        fi
        print_draw_line
        echo "Type in the option you want to change and its new value split by =, i.e. 'PORT = 25565' (without quote and option is not case sensitive, i.e. CoNfRim)."
        read -p ' >>> ' COMMAND
        case "${COMMAND,,}" in
            validate)
                check_validate_server
            ;;
            confirm|save)
                if [[ $SERVER_VALID = 1 ]]; then
                    config_write_server
                    if [[ $? = 0 ]]; then
                        return 0
                    fi
                else
                    print_notification 3 "This server is invalid, you must use 'validate' to validate it first"
                fi
            ;;
            *)
                assignment_server "$COMMAND"
                if [[ "$SERVER_VALID" = 1 ]]; then
                    print_notification 2 "New value assigned, you must validate again."
                fi
                SERVER_VALID=0
            ;;
        esac
        interactive_anykey
    done
} 
action_server_remove() {
    if [[ $# = 0 ]]; then
        action_help
        print_notification 3 "Too few arguments!"
        interactive_anykey
        return 255 # Too few arguments
    elif [[ $# = 1 ]]; then
        if [[ ! -f "$PATH_DIRECTORY/server/$1.conf" ]]; then
            print_notification 3 "The server '$1' you specified does not exist!"
            return 1 ## not exist
        elif [[ ! -w "$PATH_DIRECTORY/server/$1.conf" ]]; then
            print_notification 3 "Removing failed due to lacking of writing permission of configuration file '$1.conf'"
            return 2 ## jar not writable 
        elif [[ -f "$PATH_DIRECTORY/server/$1.group" ]]; then
            if [[ -s "$PATH_DIRECTORY/server/$1.group" ]]; then
                print_notification 3 "Can not remove server '$1', this server is a member of the following groups:"
                more "$PATH_DIRECTORY/server/$1.group"
                return 3
            elif [[ ! -w "$PATH_DIRECTORY/account/$1.server" ]]; then
                print_notification 3 "Can not remove account '$1', can not remove the file which records servers using this account."
                return 4
            fi
        fi
        else
            interactive_yn N "Are you sure you want to remove server '$1' from your library?"
            if [[ $? = 0 ]]; then
                check_status_server "$1"
                if [[ $? = 0 ]]; then
                    print_notification 1 "Server '$1' is running, trying to stop it..."
                fi
                action_server_stop "$1"
                if [[ $? = 0 ]]; then
                    rm -f "$PATH_DIRECTORY/server/$1.conf"
                    rm -f "$PATH_DIRECTORY/server/$1.group" 1>/dev/null 2>&1
                    print_notification 1 "Removed server '$1' from library"
                    return 0
                else
                    return 3 # failed to stop, still running
                fi
            else
                return 4 ## User refused 
            fi
        fi
    else
        while [[ $# > 0 ]]; do
            action_server_remove "$1"
            shift
        done
    fi
}
action_server_info() {
    if [[ $# = 0 ]]; then
        action_help
        print_notification 3 "Too few arguments!"
        interactive_anykey
        return 255 # Too few arguments
    fi
    check_environment_local subfolder-server subfolder-account
    print_draw_line
    print_center "Server information"
    print_draw_line
    if [[ $# = 1 ]]; then
        print_multilayer_menu "$1" '' 0
        if [[ ! -f "$PATH_DIRECTORY/server/$1.conf" ]]; then
            print_multilayer_menu '\e[41mThis server does not exist' '' 1 1
            return 1 # not exist
        else
            print_info_server "$1"
        fi
        print_draw_line
    else
        local ORDER=1
        while [[ $# > 0 ]]; do
            print_multilayer_menu "$ORDER. $1" '' 0
            if [[ ! -f "$PATH_DIRECTORY/server/$1.conf" ]]; then
                print_multilayer_menu '\e[41mThis server does not exist' '' 1 1
                return 1 # not exist
            else
                print_info_server "$1" 0 1
            fi
            shift
            let ORDER++
            print_draw_line
        done
    fi
    print_draw_line
    return 0
}
action_server_list() {
    check_environment_local subfolder-server subfolder-account
    print_draw_line
    print_center "Server List"
    print_draw_line
    ls $PATH_DIRECTORY/server/*.conf 1>/dev/null 2>&1
    if [[ $? != 0 ]]; then
        print_notification 3 "You have not added any server yet. Use '$PATH_SCRIPT define ...' to define a server first"
        return 1
    fi
    local ORDER=1
    for SERVER_NAME in $(ls $PATH_DIRECTORY/server/*.conf); do
        SERVER_NAME=$(basename $SERVER_NAME)
        SERVER_NAME=${SERVER_NAME:0:-5}
        print_multilayer_menu "$ORDER. $1" '' 0
        if [[ "$M7CM_DETAILED_SERVER_LIST" = 1 ]]; then
            print_info_server 
        else
            print_info_server '' 0 1 1
        fi
        print_draw_line
        let ORDER++
    done
    if [[ "$M7CM_DETAILED_SERVER_LIST" = 1 ]]; then
        print_notification 0 "For more abbreviated information, set 'M7CM_DETAILED_SERVER_LIST=0' in m7cm.conf"
    else
        print_notification 0 "For more detailed information, use '$PATH_SCRIPT info [server1] [server2] ...', or you can set 'M7CM_DETAILED_SERVER_LIST=1' in m7cm.conf"
    fi
    return 0
}
action_server_start() {
    if [[ $# = 0 ]]; then
        action_help
        print_notification 3 "Too few arguments!"
        interactive_anykey
        return 255 # Too few arguments
    elif [[ $# = 1 ]]; then
        if [[ -z "$SERVER_RESTART" ]]; then
            SERVER_NAME="$1"
            config_read_server_and_account
            if [[ $? != 0 ]]; then
                return 1
            fi
        fi
        check_status_server '' 1
        if [[ $? = 0 ]]; then
            print_notification 1 "Server '$SERVER_NAME' is already running"
            return 0
        fi
        print_notification 1 "Starting server '$SERVER_NAME'..."
        ssh $ACCOUNT_HOST -oBatchmode=yes -p $ACCOUNT_PORT -l $ACCOUNT_USER -i $ACCOUNT_KEY $ACCOUNT_EXTRA "screen -mSUd \"$SERVER_SCREEN\" \"java -Xmx$SERVER_RAM_MAX -Xms$SERVER_RAM_MIN $SERVER_EXTRA_JAVA -jar $SERVER_JAR nogui --port $SERVER_PORT $SERVER_EXTRA_JAR\""
        if [[ $? = 0 ]]; then
            print_notification 3 "Started server '$SERVER_NAME'"
            if [[ "$M7CM_CONFIRM_START" = 0 ]]; then
                return 0
            else
                print_notification 1 "Waiting 3 seconds to check if server '$SERVER_NAME' is successfully started."
                sleep 3
                local TRY=1
                local REMAIN
                for TRY in $(seq 1 3); do
                    check_status_server '' 1
                    if [[ $? = 0 ]]; then
                        print_notification 1 "Server '$SERVER_NAME' is successfully started"
                        return 0
                    else
                        print_notification 2 "Server '$SERVER_NAME' is not successfully started"
                        print_notification 1 "Retrying to start server '$SERVER_NAME'... remaining tries: $(( 3 - $TRY ))"
                        ssh $ACCOUNT_HOST -oBatchmode=yes -p $ACCOUNT_PORT -l $ACCOUNT_USER -i $ACCOUNT_KEY $ACCOUNT_EXTRA "screen -mSUd \"$SERVER_SCREEN\" \"java -Xmx$SERVER_RAM_MAX -Xms$SERVER_RAM_MIN $SERVER_EXTRA_JAVA -jar $SERVER_JAR nogui --port $SERVER_PORT $SERVER_EXTRA_JAR\""
                        print_notification 1 "Detecting server status in $(( 5 * $TRY )) seconds..."
                        print_counting $(( 5 * $TRY ))
                    echo $TRY
                done
                print_notification 3 "Server '$SERVER_NAME' is not started after 3 retries."
            fi
        else
            print_notification 3 "Server '$SERVER_NAME' can not be started"
        fi
        print_notification 1 "Dignosing problems of server '$SERVER_NAME'..."
        check_diagnose_server 
        if [[ $? = 0 ]]; then
            print_notification 3 "We can not diagnose what is wrong with the server '$SERVER_NAME'"
            print_notification 1 "The full startup command of this server is: ssh $ACCOUNT_HOST -oBatchmode=yes -p $ACCOUNT_PORT -l $ACCOUNT_USER -i $ACCOUNT_KEY $ACCOUNT_EXTRA \"screen -mSUd \\\"$SERVER_SCREEN\\\" \\\"java -Xmx$SERVER_RAM_MAX -Xms$SERVER_RAM_MIN $SERVER_EXTRA_JAVA -jar $SERVER_JAR nogui --port $SERVER_PORT $SERVER_EXTRA_JAR\\\"\""
            print_notification 1 "The local startup command on the host is: java -Xmx$SERVER_RAM_MAX -Xms$SERVER_RAM_MIN $SERVER_EXTRA_JAVA -jar $SERVER_JAR nogui --port $SERVER_PORT $SERVER_EXTRA_JAR"
            print_notification 0 "You can try to start the server by yourself using this command."
            return 2
        else
            return 3
        fi
    else
        while [[ $# > 0 ]]; do
            action_server_start "$1"
            shift
        done
        return 0
    fi
} 
action_server_stop() {
    if [[ $# = 0 ]]; then
        action_help
        print_notification 3 "Too few arguments!"
        interactive_anykey
        return 255 # Too few arguments
    elif [[ $# = 1 ]]; then
        if [[ -z "$SERVER_RESTART" ]]; then
            SERVER_NAME="$1"
            config_read_server_and_account
            if [[ $? != 0 ]]; then
                return 1
            fi
        fi
        check_status_server '' 1
        if [[ $? = 1 ]]; then
            print_notification 1 "Server '$SERVER_NAME' is already stopped"
            return 0
        fi
        print_notification 1 "Stopping server '$SERVER_NAME'..."
        ssh $ACCOUNT_HOST -oBatchmode=yes -p $ACCOUNT_PORT -l $ACCOUNT_USER -i $ACCOUNT_KEY $ACCOUNT_EXTRA "screen -rXd \"$SERVER_SCREEN\" stuff \"^Mend^Mexit^M\""
        if [[ $? = 0 ]]; then
            print_notification 3 "Stopped server '$SERVER_NAME'"
            if [[ "$M7CM_CONFIRM_STOP" = 0 ]]; then
                return 0
            else
                print_notification 1 "Waiting 3 seconds to check if server '$SERVER_NAME' is successfully stopped."
                sleep 3
                local TRY=1
                local REMAIN
                for TRY in $(seq 1 3); do
                    check_status_server '' 1
                    if [[ $? = 1 ]]; then
                        print_notification 1 "Server '$SERVER_NAME' is successfully stopped"
                        return 0
                    else
                        print_notification 2 "Server '$SERVER_NAME' is not successfully stopped"
                        print_notification 1 "Retrying to stop server '$SERVER_NAME'... remaining tries: $(( 3 - $TRY ))"
                        ssh $ACCOUNT_HOST -oBatchmode=yes -p $ACCOUNT_PORT -l $ACCOUNT_USER -i $ACCOUNT_KEY $ACCOUNT_EXTRA "screen -rd \"$SERVER_SCREEN\" -X stuff \"^Mend^Mexit^M\""
                        print_notification 1 "Detecting server status in $(( 5 * $TRY )) seconds..."
                        print_counting $(( 5 * $TRY ))
                    echo $TRY
                done
                print_notification 3 "Server '$SERVER_NAME' is not stopped after 3 retries."
            fi
        else
            print_notification 3 "Server '$SERVER_NAME' can not be stopped"
        fi
        print_notification 1 "Maybe you should check what the server is processing on console using '$PATH_SCRIPT' console '$SERVER_NAME'"
        return 2
        # check_diagnose_server 
        # if [[ $? = 0 ]]; then
        #     print_notification 3 "We can not diagnose what is wrong with the server '$SERVER_NAME'"
        #     print_notification 1 "The full stop command of this server is: ssh $ACCOUNT_HOST -oBatchmode=yes -p $ACCOUNT_PORT -l $ACCOUNT_USER -i $ACCOUNT_KEY $ACCOUNT_EXTRA \"screen -rd \\\"$SERVER_SCREEN\\\" -X stuff \\\"^Mend^Mexit^M\\\"\""
        #     print_notification 0 "You can try to stop the server by yourself using this command."
        #     return 2
        # else
        #     return 3
        # fi
    else
        while [[ $# > 0 ]]; do
            action_server_stop "$1"
            shift
        done
        return 0
    fi
}
action_server_restart() {
    if [[ $# = 0 ]]; then
        action_help
        print_notification 3 "Too few arguments!"
        interactive_anykey
        return 255 # Too few arguments
    elif [[ $# = 1 ]]; then
        SERVER_NAME="$1"
        config_read_server_and_account
        if [[ $? != 0 ]]; then
            return 1
        fi
        action_server_stop
        if [[ $? != 0 ]]; then
            print_notification 3 "Failed to restart server '$SERVER_NAME', the server is still running"
            return 2
        fi
        action_server_start
        if [[ $? != 0 ]]; then
            print_notification 3 "Failed to restart server '$SERVER_NAME', the server can not be started"
            return 3
        fi
        return 0
    else
        while [[ $# > 0 ]]; do
            action_server_restart "$1"
            shift
        done
        return 0
    fi
} 
action_server_browse() {
    if [[ $# = 0 ]]; then
        action_help
        print_notification 3 "Too few arguments!"
        interactive_anykey
        return 255 # Too few arguments
    fi
    SERVER_NAME="$1"
    config_read_server_and_account
    if [[ $? != 0 ]]; then
        return 1
    fi
    print_notification 1 "Sending you to the remote directory '$SERVER_DIRECTORY'. Use ctrl+D  or type 'exit' to exit"
    ssh $ACCOUNT_HOST -t -p $ACCOUNT_PORT -l $ACCOUNT_USER -i $ACCOUNT_KEY $ACCOUNT_EXTRA "cd $SERVER_DIRECTORY; bash"
    if [[ $? != 0 ]]; then
        print_notification 3 "Can not connect to remote directory '$SERVER_DIRECTORY', diagnosing problems of server '$SERVER_NAME'... "
        check_diagnose_server
        if [[ $? = 0 ]]; then
            print_notification 3 "We can not diagnose what is wrong with the server '$SERVER_NAME'"
            print_notification 1 "The full browse command of this server is: ssh $ACCOUNT_HOST -t -p $ACCOUNT_PORT -l $ACCOUNT_USER -i $ACCOUNT_KEY $ACCOUNT_EXTRA \"cd $SERVER_DIRECTORY; bash\""
            print_notification 0 "You can try to browse the directory by yourself using this command."
            return 2
        else
            return 3
        fi
    else
        print_notification 1 "Welcome back. Everything seems fine."
        return 0
    fi
}
action_server_console() {
    if [[ $# = 0 ]]; then
        action_help
        print_notification 3 "Too few arguments!"
        interactive_anykey
        return 255 # Too few arguments
    fi
    SERVER_NAME="$1"
    config_read_server_and_account
    if [[ $? != 0 ]]; then
        return 1
    fi
    check_status_server '' 1
    if [[ $? = 1 ]]; then
        print_notification 3 "Server '$SERVER_NAME' is not running"
        return 2
    fi
    print_notification 1 "Bringing you to the server console in 3 seconds. Use ctrl+A ctrl+D to get back."
    print_counting 3
    ssh $ACCOUNT_HOST -p $ACCOUNT_PORT -l $ACCOUNT_USER -i $ACCOUNT_KEY $ACCOUNT_EXTRA "screen -rd \"$SERVER_SCREEN\""
    if [[ $? != 0 ]];  then
        print_notification 3 "Can not connect to remote console of server '$SERVER_NAME', diagnosing problems of server '$SERVER_NAME'... "
        check_diagnose_server
        if [[ $? = 0 ]]; then
            print_notification 3 "We can not diagnose what is wrong with the server '$SERVER_NAME'"
            print_notification 1 "The full connect command of this server is: ssh $ACCOUNT_HOST -p $ACCOUNT_PORT -l $ACCOUNT_USER -i $ACCOUNT_KEY $ACCOUNT_EXTRA \"screen -rd \\\"$SERVER_SCREEN\\\"\""
            print_notification 0 "You can try to connect to the console by yourself using this command."
            return 3
        else
            return 4
        fi
    else
        print_notification 1 "Welcome back. Everything seems fine."
        return 0
    fi
}
action_server_send() {
    if [[ $# < 2 ]]; then
        action_help
        print_notification 3 "Too few arguments!"
        interactive_anykey
        return 255 # Too few arguments
    fi
    SERVER_NAME="$1"
    config_read_server_and_account
    if [[ $? != 0 ]]; then
        return 1
    fi
    check_status_server '' 1
    if [[ $? = 1 ]]; then
        print_notification 3 "Server '$SERVER_NAME' is not running"
        return 2
    fi
    print_notification 1 "Sending command '${@:2}' to server '$SERVER_NAME'..."
    ssh $ACCOUNT_HOST -oBatchmode=yes -p $ACCOUNT_PORT -l $ACCOUNT_USER -i $ACCOUNT_KEY $ACCOUNT_EXTRA "screen -rd \"$SERVER_SCREEN\" -X stuff \"^M${@:2}^M\""
    if [[ $? != 0 ]]; then
        print_notification 3 "Can not send command '${@:2}' to remote directory '$SERVER_DIRECTORY', diagnosing problems of server '$SERVER_NAME'... "
        check_diagnose_server
        if [[ $? = 0 ]]; then
            print_notification 3 "We can not diagnose what is wrong with the server '$SERVER_NAME'"
            print_notification 1 "The full browse command of this server is: ssh $ACCOUNT_HOST -t -p $ACCOUNT_PORT -l $ACCOUNT_USER -i $ACCOUNT_KEY $ACCOUNT_EXTRA \"cd $SERVER_DIRECTORY; bash\""
            print_notification 0 "You can try to browse the directory by yourself using this command."
            return 2
        else
            return 3
        fi
    else
        print_notification 1 "Successfully sent command '${@:2}' to server '$SERVER_NAME'"
        return 0
    fi
}
action_group_define() {
    
}
action_group_config() {

}
action_group_start() {

}
action_group_stop() {

}
action_group_restart() {

}
action_group_remove() {

}
action_group_delete() {

}
action_group_info() {

}
action_group_list() {

}
action_help() {
    if [[ "$TUI" ]]; then
        print_notification 1 "Below are the commands avialable for M7CM:"
    else
        print_draw_line
        print_center "Command Help for Minecraft 7 Command-line Manager"
        print_draw_line
        print_multilayer_menu "$PATH_SCRIPT" "" 0
    fi
    print_multilayer_menu "help" "print this help message" 
    print_multilayer_menu "exit" "exit M7CM, only useful in terminal UI mode."  
    print_multilayer_menu "cui" "enter the interactive command-line UI, you can then use all actions as commands. this is useful if you want to perform multiple commands." 
    print_multilayer_menu "debug" "enters the debug mode, you can call all functions in M7CM." 
    print_multilayer_menu "defineΔ [server] [account] ([directory] [port] [ram_ram] [ram_min] [jar] [extra_java] [extra_jar] [screen (custom screen name)])"
    print_multilayer_menu '' "(re)define a server so M7CM can manage it. [account] must be defined first. [jar] is the full name, could be absolute path. [extra] for extra arguments" 2 1
    print_multilayer_menu "configΔ [server] ([option1=value1] [option2=value2]" "change one of an existing server" 
    print_multilayer_menu "start※ [server1] [server2] ..." "start one or multiple pre-defined servers" 
    print_multilayer_menu "stop※ [server1] [server2] ..." "stop one or multiple pre-defined servers" 
    print_multilayer_menu "restart※ [server1] [server2] ..." 
    print_multilayer_menu "browse※ [server]" "open the directory of the given server so you can modify it" 
    print_multilayer_menu "console※ [server] ..." "connect you to the server's console" 
    print_multilayer_menu "send※ [server] [command]" "send a command" 
    print_multilayer_menu "removeΔ [server1] [server2] ..."
    print_multilayer_menu "infoΔ [server1] [server2]"
    print_multilayer_menu "list"
    ## group related commands
    print_multilayer_menu "group [sub action]" "group related action. m7cm have a reserverd group _ALL_ for all servers you defined"
    print_multilayer_menu "define [group] [server1] [server2] ..." "(re)define a group" 2
    print_multilayer_menu "config [group] [+/-server1] [+/-server2]..." '' 2
    print_multilayer_menu "start※ [group]" "" 2
    print_multilayer_menu "stop※ [group]" "" 2
    print_multilayer_menu "restart※ [group]"  "" 2
    print_multilayer_menu "send※ [group] [command]"  "" 2
    print_multilayer_menu "removeΔ [group]" "remove all servers in the group and the group itself" 2
    print_multilayer_menu "delete [group]" "just remove the group itself, keep servers" 2
    print_multilayer_menu "push♦ [group] [jar]" "push the given jar to all servers in group" 2
    print_multilayer_menu "infoΔ [group]" "list all servers' information in the given group" 2 1
    ## jar related command
    print_multilayer_menu "jar [sub action]" "jar-related commands, [jar] does not incluede the .jar suffix"
    print_multilayer_menu "import* [jar] [link/path]" "import a jar from an online source or local disk, you need GNU/Wget to download the jar" 2
    print_multilayer_menu "push♦ [jar] [server]" "push the given jar to this server" 2
    print_multilayer_menu "pull♦ [jar] [server] [remote jar]" "pull the remote jar, use fullname" 2
    print_multilayer_menu "config [jar] ([option1=value1] [option2=value2] ...)" "" 2
    print_multilayer_menu "build* [jar] [buildtool-jar] ([version])" "build a jar file of the given version using spigot buildtool" 2
    print_multilayer_menu '' "You need to import or download the [buildtool] first, and configure BUILDTOOL=1 in its configuration. You also need JRE and GIT to build a jar." 3 1
    print_multilayer_menu "remove [jar1] [jar2] ..." "remove a jar and this configuration" 2
    print_multilayer_menu "info [jar1] [jar2] ..." "check the configuration of the jar file" 2
    print_multilayer_menu "list" "lsit all jar files and their configuration" 2 1
    ## account related command
    print_multilayer_menu "account [sub action]" "" 1 1
    print_multilayer_menu "defineΔ [account] [hostname/ip] [ssh port] [user] [private key]" "" 2 0 1
    print_multilayer_menu "configΔ [account] ([option1=value1] [option2=value2] ...)" "" 2 0 1
    print_multilayer_menu "remove [account1] [account2] ..." "" 2 0 1
    print_multilayer_menu "info [account1] [account2] ..." "" 2 0 1
    print_multilayer_menu "list" "" 2 1 1
    print_draw_line
    print_notification 0 "Actions with ※ only works if you have SSH"
    print_notification 0 "Actions with Δ only fully works if you have SSH, but can work without it"
    print_notification 0 "Actions with ♦ only works if you have SCP or SFTP"
    print_notification 0 "Acitons with * have their own requirement"
    # print_notification
    # print_notification 0 "Any [account] used by a server must have been pre-defined by '$PATH_SCRIPT account define', M7CM will use SSH to connect to this host and perform management. Even if you want to run and manage servers on the same host as M7CM, you still need to use SSH to ensure both the isolation and the security. Notice that the [account] here is just for easy memorizing, and does not have to be the same as [user]"
    # print_notification 0 "The [remote jar] defined in a server is the remote jar's full name with file extension, which can be absolute path outside of the working [directory] (In that case, the [directory] just holds the world data and configuration files). But the [jar] defined in jar-related actions is a simple name for memo, without file extension (though M7CM can auto-remove it if you accidently add '.jar')"
    # print_notification 1 "It's strongly recommended to use simple alphabet name for [server], [group] [account] and [jar], any extra suffix may result in unexpected accidents"
    ##print_notification 0 "Any [jar] used by a server must have been pre-imported by '$PATH_SCRIPT import', or you can use '_REMOTE_' to let M7CM use the remote jar, if so, you must define [remote jar] with its full name. refer to a jar file in the directory of the server (will be renamed to server.jar and import into jar library with the same name of the server then)"
    # print_notification 0 "M7CM has a reserverd server '_LAST_' refering to the last server you've successfully managed and also a reserverd group '_LAST_'. there's also a reserverd group named '_ALL_' refering to all servers"
    print_notification 0 "M7CM has a reserverd group '_ALL_' which contains all servers."
    print_notification 0 "To build a spigot jar using a spigot buildtool, you need import a buildtool first, configure it to be recognized as a buildtool, and got jre and git installed."
    print_draw_line
    return 0
}
action_version() {
    print_draw_line
    print_center "Minecraft 7 Command-line Manager, a bash-based Minecraft Servers Manager"
    print_center "Version $VERSION, updated at $UPDATE_DATE "
    print_center "Powered by GNU/bash $BASH_VERSION"
    print_draw_line
    return 0
}
action_cui() {
    print_draw_line
    print_center "M7CM Command-line UI"
    print_draw_line
    print_multilayer_menu "Current functions status: "
    if [[ "$ENV_METHOD_DOWNLOAD" = 1 ]]; then
        print_multilayer_menu "Jar download: " "\e[42mOK"
        print_multilayer_menu "Current jar download method: $M7CM_METHOD_DOWNLOAD" 2 1
    else
        print_multilayer_menu "Jar download" "\e[41mNot working"
        print_multilayer_menu '' 'Neither wget nor curl detected' 2 1
    fi
    if [[ "$ENV_METHOD_PORT_DIAGNOSIS" = 1 ]]; then
        print_multilayer_menu "Port diagnosis: " "\e[42mOK"
        print_multilayer_menu "Current port diagnosis method: $M7CM_METHOD_PORT_DIAGNOSIS" 2 1
    else
        print_multilayer_menu "Port diagnosis: " "\e[41mNot working"
        print_multilayer_menu '' 'Neither GNU/timeout, ncat, nmap nor GNU/wget detected' 2 1
    fi
    if [[ "$ENV_METHOD_PUSH_PULL" = 1 ]]; then
        print_multilayer_menu "Jar push and pull: " "\e[42mOK"
        print_multilayer_menu "Current jar push and pull method: $M7CM_METHOD_PUSH_PULL" 2 1
    else
        print_multilayer_menu "Jar push and pull: " "\e[41mNot working"
        print_multilayer_menu '' 'Neither SCP nor SFTP detected' 2 1
    fi
    if [[ "$ENV_LOCAL_JRE" = 1 ]]; then
        print_multilayer_menu "Jar type identification:" "\e[42mOK"
    else
        print_multilayer_menu "Jar type identification:" "\e[41mNot working"
        print_multilayer_menu '' 'Java run time environment not detected' 2 1
    fi
    if [[ "$ENV_LOCAL_JRE" = 1 && "$ENV_LOCAL_GIT" = 1 ]]; then
        print_multilayer_menu "Spigot building: " "\e[42mOK"
    else
        print_multilayer_menu "Spigot building:" "\e[41mNot working"
        print_multilayer_menu '' 'Either java run time environment or git not detected' 2 1
    fi
    if [[ "$ENV_LOCAL_SSH" = 1 && ]]
    local COMMAND
    local TUI=1
    while true; do
        

        print_notification 
        read -e -p "[Terminal UI @ M7CM]# " COMMAND
        main $COMMAND
        interactive_anykey
    done
}
action_debug() {
    declare -F
    echo "You've entered debug mode, Above is all functions defined in M7CM, you can call them as you like. i.e. action_server_list. Use 'exit' to exit."
    local COMMAND
    while true; do
        read -e -p "[Debug Mode @ M7CM]# " COMMAND
        ${COMMAND}
    done
}
main() {
    if [[ $# = 0 ]]; then
        if [[ "$TUI" ]]; then
            print_notification 3 "Too few arguments! For command help, type 'help'"
        else
            action_help
        fi
        return 255 # Too few arguments
    fi
    if [[ -z "$TUI" ]]; then
        check_startup
    fi
    if [[ "$ENV_LOCAL_SSH" = 0 ]]; then
        if [[ "${1,,}" =~ ^(browse|start|stop|restart|console|send)$ ]]; then
            print_notification 3 "Remote management function disabled due to lacking of SSH"
            return 1
        elif [[ "${1,,}" = group && "${2,,}" =~ ^(start|stop|restart|send)$ ]]; then
            print_notification 3 "Remote management function disabled due to lacking of SSH"
            return 1
        fi
    fi
    case "${1,,}" in 
        cui)
            action_cui
            ;;
        debug)
            action_debug
            ;;
        exit)
            if [[ -z "$TUI" ]]; then
                print_notification 4 "This action only works in Terminal UI mode"
            else
                exit
            fi
            ;;
        define)
            action_server_define "${@:2}"
            ;;
        config)
            action_server_config "${@:2}"
            ;;
        browse)
            action_server_browse "$2"
            ;;
        start)
            action_server_start "${@:2}"
            ;;
        stop)
            action_server_stop "${@:2}"
            ;;
        restart)
            action_server_restart "${@:2}"
            ;;
        console)
            action_server_console "$2"
            ;;
        send)
            action_server_send "${@:2}"
            ;;
        remove)
            action_server_remove "${@:2}"
            ;;
        info)
            action_server_info "${@:2}"
            ;;
        list)
            action_server_list
            ;;
        group) #group related actions
            case "$2" in
                define)
                    action_group_define "${@:3}"
                    #define a group
                    ;;
                start)
                    action_group_start "${@:3}"
                    #start a group
                    ;;
                stop)
                    action_group_stop "${@:3}"
                    #stop a group
                    ;;
                restart)
                    action_group_restart "${@:3}"
                    #restart a group
                    ;;
                remove)
                    action_group_remove "${@:3}"
                    #remove a group
                    ;;
                info)
                    action_group_info "${@:3}"
                    #info of a group
                    ;;
                list)
                    action_group_list
                    #list all groups
                    ;;
                *)
                    if [[ "$TUI" ]]; then
                        print_notification 3 "Wrong command! For command help, type 'help'"
                    else
                        action_help
                    fi
                    return 2 # wrong command
                    ;;
            esac
            ;;
        jar) #jar related actions
            case "$2" in 
                import) #import a local jar
                    action_jar_import "${@:3}"
                ;;
                config)
                    action_jar_config "${@:3}"
                ;;
                build)
                    action_jar_build "${@:3}"
                ;;
                push)
                    echo "UNDER PROGRAMMING"
                    #push a jar to a server
                    action_jar_push "${@:3}"
                ;;
                pull)
                    echo "UNDER PROGRAMMING"
                    #pull a jar from a server
                    action_jar_pull "${@:3}"
                ;;
                remove)
                    action_jar_remove "${@:3}"
                ;;
                info)
                    action_jar_info "${@:3}"
                ;;
                list)
                    action_jar_list 
                ;;
                *)
                    if [[ "$TUI" ]]; then
                        print_notification 3 "Wrong command! For command help, type 'help'"
                    else
                        action_help
                    fi
                    return 2 #wrong command
                ;;
            esac
        ;;
        account)
            #account related actions
            case "$2" in
                define)
                    action_account_define "${@:3}"
                    ;;
                config)
                    action_account_config "${@:3}"
                    ;;
                remove)
                    action_account_remove "${@:3}"
                    ;;
                info)
                    action_account_info "${@:3}"
                    ;;
                list)
                    action_account_list
                    ;;
                *)
                    if [[ "$TUI" ]]; then
                        print_notification 3 "Wrong command! For command help, type 'help'"
                    else
                        action_help
                    fi
                    return 1 # wrong command
                    ;;
            esac
        *)
            if [[ "$TUI" ]]; then
                print_notification 3 "Wrong command! For command help, type 'help'"
            else
                action_help
            fi
            return 1 # wrong command
        ;;
    esac
    return 0
}
main "$@"
exit