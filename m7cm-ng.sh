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
    if [[ "$2" =~ '^[0-9]+$' && $2 -le $LENGTH ]]; then
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
        if [[ ! -z "$2" || "$2" = 0 ]]; then
            printf "\r\e[1m\e[5m$2\e[0m: "
        else
            printf '\r\e[1m\e[5mATTENTION\e[0m: '
        fi
        if [[ ! -z "$3" ]]; then
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
    if [[ "$3" =~ '^[0-9]+$' && $3 > 0 ]]; then
        local LAYER=$3
    else
        local LAYER=1
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

interactive_yn() {
    local CHOICE
    while true; do
        if [[ "$1" =~ ^(y|Y)$ ]]; then
            printf "\e[7mConfirmation:\e[0m ${@:2}(Y/n)"
        else
            printf "\e[7mConfirmation:\e[0m ${@:2}(y/N)"
        fi
        read -p "" CHOICE
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

check_environment_local() {
    if [[ $# = 0 ]]; then
        check_environment_local bash ssh scp sftp timeout ncat nmap screen wget curl jre root sshd git basefolder subfolder
    elif [[ $# > 1 ]]; then
        local TMP
        while [[ $# > 0 ]]; do
            check_environment_local "$1"
            shift
        done
    else
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
check_validate_port() {
    if [[ $ENV_METHOD_PORT_DIAGNOSIS = 0 ]]; then
        print_notification 3 "Port validation function is disabled."
        return 1
    fi
    if [[ -z "$2" ]]; then
        local HOST='localhost'
    else
        local HOST="$2"
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
        if [[ ! -z "$TMP" ]]; then
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
    if [[ $# > 0 ]]; then
        local ACCOUNT_NAME="$1"
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
        print_notification 3 "Keyfile '$ACCOUNT_KEY' does not exist, validation failed"
        return 2 # key not exist
    fi
    if [[ $ENV_LOCAL_SSH = 0 ]]; then
        print_notification 3 "SSH not detected, further validation functions disabled"
        interactive_yn N "Should we consider this account"
        return 3 # no ssh
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
    print_notification 1 "Diagnosing connection to the remote host"
    ping -c3 -i0.4 -w0.8 "$ACCOUNT_HOST" 1>/dev/null 2>&1
    if  [[ $? = 0 ]]; then
        print_notification 1 "Connection to the remote host '$ACCOUNT_HOST' is working fine, maybe there's problem with the port '$ACCOUNT_PORT'?"
    else
        print_notification 3 "Can not get IGMP replay from remote host '$ACCOUNT_HOST', check your network connection"
        return 3 # ping failed, not connectable
    fi
    check_validate_port "$ACCOUNT_HOST" "$ACCOUNT_PORT"
}
check_validate_server() {
    local ACCOUNT_NAME="$SERVER_ACCOUNT"
    config_read_
    sut_validate
    print_notification 1 "Validating server '$SERVER_NAME'"
    if [[ $? != 0 ]]; then
        print_notification 3 "Invalid account"
        return 1 # invalid account
    fi
    ssh -oBatchmode=yes $ACCOUNT_HOST -p $ACCOUNT_PORT -l $ACCOUNT_USER -i $ACCOUNT_KEY $ACCOUNT_EXTRA "screen -mSUd m7cm exit" 1>/dev/null 2>&1
    if [[ $? != 0 ]]; then
        print_notification 2 "GNU/Screen not found on remote host. You can ignore this if you don't want to run servers on this host, since M7CM use GNU/Screen to keep servers in background so you can reconnect to them and execute additional commands in console later."
        interactive_yn N "Ignore it?"
        if [[ $? != 0 ]]; then
            return 2 # screen not found
        fi
    fi
    ssh -oBatchmode=yes $ACCOUNT_HOST -p $ACCOUNT_PORT -l $ACCOUNT_USER -i $ACCOUNT_KEY $ACCOUNT_EXTRA "java -version" 1>/dev/null 2>&1
    if [[ $? != 0 ]]; then
        print_notification 3 "Java runtime environment not found on remote host. You can ignore this if all you need is to pull a jar from this host, but that is very, very, very rare"
        interactive_yn N "Ignore it?"
        if [[ $? != 0 ]]; then
            return 3 # jre not found
        # else 
        #     print_notification 2 "OK we're serious now. Should that magic jar does not exist, your validation is dead end."
        #     ssh -oBatchmode=yes $ACCOUNT_HOST -p $ACCOUNT_PORT -l $ACCOUNT_USER -i $ACCOUNT_KEY $ACCOUNT_EXTRA "cd $SERVER_DIRECTORY; test -f $SERVER_JAR"
        #     if [[ $? != 0 ]]; then
        #         print_notification 3 "Remote jar not exist"
        #         return 4 # not exist jar
        #     else
        #         print_notification 2 "Remote jar '$SERVER_JAR' exists, "
        #     fi
        fi
    fi
    ssh -oBatchmode=yes $ACCOUNT_HOST -p $ACCOUNT_PORT -l $ACCOUNT_USER -i $ACCOUNT_KEY $ACCOUNT_EXTRA "test -d $SERVER_DIRECTORY"
    if [[ $? != 0 ]]; then
        print_notification 2 "Remote directory '$SERVER_DIRECTORY' does not exist. Trying to create it..."
        ssh -oBatchmode=yes $ACCOUNT_HOST -p $ACCOUNT_PORT -l $ACCOUNT_USER -i $ACCOUNT_KEY $ACCOUNT_EXTRA "mkdir $SERVER_DIRECTORY"
        if [[ $? != 0 ]]; then
            print_notification 3 "Remote directory '$SERVER_DIRECTORY' can not be created."
            return 3 # not exist and can not be created
        else
            print_notification 1 "Remote directory '$SERVER_DIRECTORY' created"
        fi
    else
        ssh -oBatchmode=yes $ACCOUNT_HOST -p $ACCOUNT_PORT -l $ACCOUNT_USER -i $ACCOUNT_KEY $ACCOUNT_EXTRA "test -w $SERVER_DIRECTORY"
        print_notification 3 "Remote directory '$SERVER_DIRECTORY' exists but not writable."
        return 4
    fi
    ssh -oBatchmode=yes $ACCOUNT_HOST -p $ACCOUNT_PORT -l $ACCOUNT_USER -i $ACCOUNT_KEY $ACCOUNT_EXTRA "test -f $SERVER_DIRECTORY/$SERVER_JAR" 
    if [[ $? != 0 ]]; then
        print_notification 2 "Remote jar '$SERVER_JAR' not found."
        if [[ $ENV_METHOD_PUSH_PULL = 0 ]]; then
            print_notification 3 "Neither SSH SCP or SSH SFTP found on localhost, you can not push local jar to the remote host."
            return 5 # jar not found and can't push
        else
            print_notification 2 "You should push jar to this server later using '$PATH_SCRIPT jar push [jar] $SERVER_NAME'"
        fi
    fi
    print_notification 1 "Validation passed"
    SERVER_VALID=1
    return 0
}
check_startup() {
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

    

    config_read_m7cm
    if [[ $? = 1 ]]; then # Configuration not exist
        check_environment_local 
        check_method
        config_write_m7cm
    elif [[ $M7CM_SKIP_STARTUP_CHECK = 1 ]]; then
        if [[ -f "$PATH_DIRECTORY/environment.conf" ]]; then
            config_read_environment
        else
            print_notification 2 "You have set 'SKIP_STARTUP_CHECK=1', M7CM will generate environment configuration file 'environment.conf' at working folder '$PATH_DIRECTORY' after checking all environment status."
            check_environment_local
            check_method
            config_write_environment
        fi
    else
        check_environment_local
        check_method
    fi
}

config_read_m7cm() {
    if [[ -f "$PATH_DIRECTORY/m7cm.conf" ]]; then
        local IFS="="
        while read -r NAME VALUE; do
            case "$NAME" in
                DEFAULT_SERVER_JAR|DEFAULT_SSH_USER|METHOD_DOWNLOAD|METHOD_PORT_DIAGNOSIS|METHOD_PUSH_PULL)
                    eval M7CM_$NAME=$VALUE
                    ;;
                DEFAULT_SERVER_PORT)
                    if [[ "$VALUE" =~ ^[0-9]+$ ]] && [[ $VALUE -ge 0 && $VALUE -le 65535 ]]; then
                        M7CM_DEFAULT_SERVER_PORT
                    else
                        M7CM_DEFAULT_SERVER_PORT='25565'
                        print_notification 2 'Illegal value for default server port, defaulting it to 25565. Accept: interger 0-65535'
                    fi
                    ;;
                DEFAULT_SSH_PORT)
                    if [[ "$VALUE" =~ ^[0-9]+$ ]] && [[ $VALUE -ge 0 && $VALUE -le 65535 ]]; then
                        M7CM_DEFAULT_SSH_PORT=$VALUE
                    else
                        M7CM_DEFAULT_SSH_PORT='22'
                        print_notification 2 'Illegal value for default ssh port, defaulting it to 22. Accept: interget 0-65535'
                    fi
                    ;;
                DOWNLOAD_PROXY_HTTP)
                    if [[ "$VALUE" =~ '^https?://[-A-Za-z0-9\+&@#/%?=~_|!:,.;]*[-A-Za-z0-9\+&@#/%=~_|]$' ]]; then
                        M7CM_DOWNLOAD_PROXY_HTTP=$VALUE
                    else
                        M7CM_DOWNLOAD_PROXY_HTTP=''
                        print_notification 2 "Illegal http proxy '$VALUE', http proxy will not be used"
                    fi
                    ;;
                DOWNLOAD_PROXY_HTTPS)
                    if [[ "$VALUE" =~ '^https?://[-A-Za-z0-9\+&@#/%?=~_|!:,.;]*[-A-Za-z0-9\+&@#/%=~_|]$' ]]; then
                        M7CM_DOWNLOAD_PROXY_HTTPS=$VALUE
                    else
                        M7CM_DOWNLOAD_PROXY_HTTPS=''
                        print_notification 2 "Illegal http proxy '$VALUE', https proxy will not be used"
                    fi
                    ;;
                SKIP_STARTUP_CHECK)
                    if [[ "$VALUE" =~ ^[01]$ ]]; then
                        M7CM_SKIP_STARTUP_CHECK=$VALUE
                    else
                        print_notification 2 "Illegal value for whether M7CM should skip startup check, defaulting it to 0. Accept:0/1"
                    ;;
                HIDE_KEY_PATH)
                    if [[ "$VALUE" =~ ^[01]$ ]]; then
                        M7CM_HIDE_KEY_PATH=$VALUE
                    else
                        print_notification 2 "Illegal value for whether M7CM should hide private key path, defaulting it to 0. Accept:0/1"
                    ;;
                *)
                    if [[ ! -z "$VALUE" ]]; then
                        print_notification 1 "Redundant variable $NAME found in M7CM configuration file, ignored"
                    fi
                ;;
            esac
        done < $PATH_DIRECTORY/m7cm.conf
        return 0
    else
        print_notification 2 "Configuration file for M7CM not found, setting all configuration to default"
        M7CM_DEFAULT_SERVER_JAR='server.jar'
        M7CM_DEFAULT_SERVER_PORT='25565'
        M7CM_DEFAULT_SSH_PORT='22'
        M7CM_DEFAULT_SSH_USER="$USER"
        M7CM_METHOD_DOWNLOAD=''
        M7CM_METHOD_PORT_DIAGNOSIS=''
        M7CM_METHOD_PUSH_PULL=''
        M7CM_DOWNLOAD_PROXY_HTTP=''
        M7CM_DOWNLOAD_PROXY_HTTPS=''
        M7CM_SKIP_STARTUP_CHECK='0'
        M7CM_HIDE_KEY_PATH='1'
        return 1
    fi
}
config_read_environment() {
    local IFS="="
    while read -r NAME VALUE; do
        case "$NAME" in
            SCREEN|SCP|SFTP|TIMEOUT|NCAT|NMAP|WGET|CURL|JRE|GIT)
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
    local IFS=$' \t\n'
    if [[ $ENV_LOCAL_TIMEOUT = 1 || $ENV_LOCAL_NCAT = 1 || $ENV_LOCAL_NMAP = 1 || $ENV_LOCAL_WGET = 1]]; then
        ENV_METHOD_PORT_DIAGNOSIS=1
    fi
    if [[ $ENV_LOCAL_WGET = 1 || $ENV_LOCAL_CURL = 1 ]]; then
        ENV_METHOD_DOWNLOAD=1
    fi
    if [[ $ENV_LOCAL_SCP = 1 || $ENV_LOCAL_SFTP = 1 ]]; then
        ENV_METHOD_PUSH_PULL=1
    fi
}
config_read_jar() {
    if [[ $# > 0 ]]; then
        local JAR_NAME="$1"
        utility_name_fix_jar
    fi
    if [[ ! -f $PATH_DIRECTORY/jar/$JAR_NAME.conf ]]; then
        print_notification 3 "Configuration file '$JAR_NAME.conf' not found, all configuration for jar '$JAR_NAME' set to default, you may try '$PATH_SCRIPT jar config $JAR_NAME' to reconfigure it."
        JAR_TAG=''
        JAR_TYPE=''
        JAR_VERSION=''
        JAR_VERSION_MC=''
        JAR_PROXY=0
        JAR_BUILDTOOL=0
        return 1
    fi
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
    return 0
} ## Safely read jar info, ignore redundant values
config_read_account() {
    if [[ $# > 0 ]]; then
        local ACCOUNT_NAME="$1"
    fi
    if [[ ! -f $PATH_DIRECTORY/account/$ACCOUNT_NAME.conf ]]; then
        print_notification 3 "Configuration file for Account '$ACCOUNT_NAME' not found, use '$PATH_SCRIPT account define $ACCOUNT_NAME' to define it first."
        return 1
    elif [[ ! -r $PATH_DIRECTORY/account/$ACCOUNT_NAME.conf ]]; then
        print_notification 3 "Configuration file for Account '$ACCOUNT_NAME' not readable, check your permission."
        return 2
    fi
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
    return 0
} ## Safely read account config, ignore redundant values
config_read_server() {
    if [[ $# > 0 ]]; then
        local SERVER_NAME="$1"
    fi
    if [[ ! -f $PATH_DIRECTORY/server/$SERVER_NAME.conf ]]; then
        print_notification 3 "Configuration file for server '$SERVER_NAME' not found, use '$PATH_SCRIPT server define $SERVER_NAME' to define it first."
        return 1
    elif [[ ! -r $PATH_DIRECTORY/server/$SERVER_NAME.conf ]]; then
        print_notification 3 "Configuration file for server '$SERVER_NAME' not readable, check your permission"
        return 2
    fi
    local IFS="="
    while read -r NAME VALUE; do
        case "$NAME" in
            SERVER_TAG|SERVER_ACCOUNT|SERVER_DIRECTORY|SERVER_PORT|SERVER_RAM_MAX|SERVER_RAM_MIN|SERVER_JAR|SERVER_EXTRA_JAVA|SERVER_EXTRA_JAR)
                eval $NAME=$VALUE
            ;;
            *)
                if [[ ! -z "$VALUE" ]]; then
                    print_notification 1 "Redundant variable '$NAME' found in configuration file '$SERVER_NAME.conf', ignored"
                fi
            ;;
        esac
    done < $PATH_DIRECTORY/account/$SERVER_NAME.conf
    return 0
}

config_write_m7cm() {
    print_notification 1 "Proceeding to write M7CM configuration to file 'm7cm.conf'"
    echo "## Configuration for M7CM, generated at `date +"%Y-%m-%d-%k-%M"`" > "$PATH_DIRECTORY/environment.conf"
    echo "DEFAULT_SERVER_JAR=$M7CM_DEFAULT_SERVER_JAR" >> "$PATH_DIRECTORY/m7cm.conf"
    echo "DEFAULT_SERVER_PORT=$M7CM_DEFAULT_SERVER_PORT" >> "$PATH_DIRECTORY/m7cm.conf"
    echo "DEFAULT_SSH_USER=$M7CM_DEFAULT_SSH_USER" >> "$PATH_DIRECTORY/m7cm.conf"
    echo "DEFAULT_SSH_PORT=$M7CM_DEFAULT_SSH_PORT" >> "$PATH_DIRECTORY/m7cm.conf"
    echo "METHOD_DOWNLOAD=$M7CM_METHOD_DOWNLOAD" >> "$PATH_DIRECTORY/m7cm.conf"
    echo "METHOD_PORT_DIAGNOSIS=$M7CM_METHOD_PORT_DIAGNOSIS" >> "$PATH_DIRECTORY/m7cm.conf"
    echo "METHOD_PUSH_PULL=$M7CM_METHOD_PUSH_PULL" >> "$PATH_DIRECTORY/m7cm.conf"
    echo "DOWNLOAD_PROXY_HTTP=$M7CM_DOWNLOAD_PROXY_HTTP" >> "$PATH_DIRECTORY/m7cm.conf"
    echo "DOWNLOAD_PROXY_HTTPS=$M7CM_DOWNLOAD_PROXY_HTTPS" >> "$PATH_DIRECTORY/m7cm.conf"
    echo "SKIP_STARTUP_CHECK=$M7CM_SKIP_STARTUP_CHECK" >> "$PATH_DIRECTORY/m7cm.conf"
    echo "HIDE_KEY_PATH=$M7CM_HIDE_KEY_PATH" >> "$PATH_DIRECTORY/m7cm.conf"
    print_notification 1 "Successfully written configuration to 'm7cm.conf'"
    return 0
}
config_write_environment() {
    print_notification 1 "Proceeding to write detected environment status to config file 'environment.conf'"
    echo "## Configuration for local environment, generated by M7CM at `date +"%Y-%m-%d-%k-%M"`. This file is generated because you've set" > "$PATH_DIRECTORY/environment.conf"
    echo "## SKIP_STARTUP_CHECK=1 in m7cm.conf. In this case, M7CM reads this file to get environment status instead of checking it every time." >> "$PATH_DIRECTORY/environment.conf"
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
        utility_name_fix_jar
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
        print_notification 3 "Can not write to configuration file '$SERVER_NAME.conf' due to lacking of writing permission. Check your permission"
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
        print_notification 0 "Successfully written values to config file '$ACCOUNT_NAME.conf'"
        return 0
    fi
}

assignment_jar() {
    local CHANGE
    local OPTION
    local VALUE
    local IFS
    if [[ $# = 1 ]]; then
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
                if [[ "$VALUE" = 0 ]]; then
                    eval JAR_$OPTION=0
                    print_notification 0 "'$OPTION' set to 0"
                elif [[ "$VALUE" = 1 ]]; then
                    eval JAR_$OPTION=1
                    print_notification 1 "'$OPTION' set to 1"
                else 
                    print_notification 2 "Invalid value '$VALUE' for '$OPTION', ignored. Accedpting: 0, 1"
                fi
            ;;
            NAME)
                if [[ -z "$JAR_NAME" ]]; then
                    print_notification 2 "Renaming aborted due to no jar being selected"
                elif [[ -f "$PATH_DIRECTORY/jar/$VALUE.jar" || -f "$PATH_DIRECTORY/jar/$VALUE.conf" ]]; then
                    if [[ ! -w "$PATH_DIRECTORY/jar/$VALUE.jar" || ! -w "$PATH_DIRECTORY/jar/$VALUE.conf" ]]; then
                        print_notification 2 "Renaming aborted. A jar with the same name '$VALUE' has already exist and can't be overwriten due to lack of writing permission. Check your permission."
                    else
                        interactive_yn N "A jar with the same name '$VALUE' has already exist, are you sure you want to overwrite it?"
                        if [[ $? = 0 ]]; then
                            mv -f "$PATH_DIRECTORY/jar/$JAR_NAME.jar" "$PATH_DIRECTORY/jar/$VALUE.jar"
                            rm -f "$PATH_DIRECTORY/jar/$VALUE.conf" 1>/dev/null 2>&1
                            mv -f "$PATH_DIRECTORY/jar/$JAR_NAME.conf" "$PATH_DIRECTORY/jar/$VALUE.conf" 1>/dev/null 2>&1
                            JAR_NAME="$VALUE"
                            print_notification 0 "'NAME' set to '$VALUE'"
                        fi
                    fi  
                else
                    # assignment for new jar which is not imported yet
                    mv "$PATH_DIRECTORY/jar/$JAR_NAME.jar" "$PATH_DIRECTORY/jar/$VALUE.jar"
                    mv -f "$PATH_DIRECTORY/jar/$JAR_NAME.conf" "$PATH_DIRECTORY/jar/$VALUE.conf" 1>/dev/null 2>&1
                    JAR_NAME="$VALUE"
                    print_notification 0 "'NAME' set to '$VALUE'"
                fi
            ;;
            *)
                print_notification 1 "'$OPTION' is not an available option, ignored"
            ;;
        esac

    else
    while [[ $# > 0 ]]; do
        CHANGE="$1"
        IFS=' ='
        
        shift
    done
    return 0
} ## Usage: assignment_jar [option1=value1]   [option2=value2]
assignment_account() {
    local CHANGE
    local OPTION
    local VALUE
    local IFS
    while [[ $# > 0 ]]; do
        local CHANGE="$1"
        local IFS=' ='
        read -r OPTION VALUE <<< "$CHANGE"
        OPTION=`echo "$OPTION" | tr [a-z] [A-Z]`
        local IFS=$' \t\n'
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
                    ACCOUNT_USER="$USER"
                    print_notification 2 "No user specified, using current user '$USER'"
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
                    print_notification 2 "No port specified, using default value '22' as [port]"
                    ACCOUNT_PORT="22"
                else
                    print_notification 2 "'$VALUE' is not a valid port, using default value '22' as [port]"
                    ACCOUNT_PORT="22"
                fi
            ;;
            KEY)
                VALUE=$(eval echo "$VALUE")
                ## convert ~ to real location
                if [[ ! -f "$VALUE" ]]; then
                    print_notification 3 "Keyfile '$VALUE' not exist"
                    return 1 # key not readable
                elif [[ ! -r "$VALUE" ]]; then
                    print_notification 3 "Keyfile '$VALUE' not readable, check your permission"
                    return 2 # not readable
                else
                    ACCOUNT_KEY="$VALUE"
                    print_notification 0 "'KEY' set to '$VALUE'"
                fi
            ;;
            NAME)
                if [[ -z "$ACCOUNT_NAME" ]]; then
                    print_notification 2 "Renaming aborted due to no account being selected"
                elif [[ ! -f "$PATH_DIRECTORY/account/$ACCOUNT_NAME.conf" ]]; then
                    ACCOUNT_NAME="$VALUE"
                    print_notification 0 "'NAME' set to '$VALUE'"
                elif [[ -f "$PATH_DIRECTORY/account/$VALUE.conf" ]]; then
                    if [[ ! -w "$PATH_DIRECTORY/account/$VALUE.conf" ]]; then
                        print_notification 2 "Renaming aborted. An account with the same name '$VALUE' has already exist and can't be overwriten due to lack of writing permission. Check your permission."
                    else
                        interactive_yn N "An account with the same name '$VALUE' has already exist, are you sure you want to overwrite it?"
                        if [[ $? = 0 ]]; then
                            mv -f "$PATH_DIRECTORY/account/$ACCOUNT_NAME.conf" "$PATH_DIRECTORY/account/$VALUE.conf"
                            ACCOUNT_NAME="$VALUE"
                            print_notification 0 "'NAME' set to '$VALUE'"
                        else
                            return 3 # abort overwriting
                        fi
                    fi  
                else
                    mv "$PATH_DIRECTORY/account/$ACCOUNT_NAME.conf" "$PATH_DIRECTORY/account/$VALUE.conf" 
                    ACCOUNT_NAME="$VALUE"
                    print_notification 0 "'NAME' set to '$VALUE'"
                fi
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
        local CHANGE="$1"
        local IFS=' ='
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
                    print_notification 3 "'DIRECTORY' is empty, defaulting to '~'"
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
                    SERVER_ACCOUNT="$VALUE"
                    print_notification 1 "'ACCOUNT' is set to '$VALUE'"
                fi
                ;;
            RAM_MIN|RAM_MAX)
                VALUE=`echo "$VALUE" | tr [a-z] [A-Z]`
                local REGEX='^[0-9]+[MG]$'
                if [[ "$VALUE" =~ $REGEX ]]; then
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
                        print_notification 2 "'$VALUE' seems to be too large, 8G of ram is usually the most a normal minecraft server can take, and even that is under an extrodinary situation"
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
                    print_notification 2 "Renaming aborted due to no server being selected"
                elif [[ ! -f "$PATH_DIRECTORY/server/$VALUE.conf" ]]; then
                    SERVER_NAME="$VALUE"
                    print_notification 0 "'NAME' set to '$VALUE'"
                elif [[ -f "$PATH_DIRECTORY/server/$VALUE.conf" ]]; then
                    if [[ ! -w "$PATH_DIRECTORY/server/$VALUE.conf" ]]; then
                        print_notification 2 "Renaming aborted. A server with the same name '$VALUE' has already exist and can't be overwriten due to lack of writing permission. Check your permission."
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
utility_name_fix_jar() {
    while true; do
        local TMP=`echo "${JAR_NAME: -4}" | tr [A-Z] [a-z]`
        if [[ "$TMP" = ".jar" ]]; then
            print_notification 2 "You jar name has redundant .jar suffix and has been automatically cut"
            JAR_NAME="${JAR_NAME:0:-4}"
            local FIXED=1
        else
            return 0
        fi
    done
    if [[ ! -z "$FIXED" ]]; then
        print_notification 1 "New jar name: $JAR_NAME"
    fi
} ## Fix jar name, cut out .jar extension
subfunc_identify_jar() {
    echo "Auto-identifying jar information for JAR '$JAR_NAME'..." 
    if [[ ENV_LOCAL_JRE = 0 ]]; then
        print_notification 3 "Auto-identifying failed due to lacking of Java Runtime Environment " 
        return 1 # lacking of JRE
    else
        local TMP="/tmp/M7CM-identifying-$JAR_NAME-`date +"%Y-%m-%d-%k-%M"`"
        mkdir "$TMP"
        print_notification 0 "Depending on the type of the jar, the performance of this host, and your network connection, it may take a few seconds or a few minutes to identify it. i.e. Paper pre-patch jar would download the vanilla jar and patch it"
        pushd "$TMP" 1>/dev/null 2>&1
        print_notification 1 "Switched to temporary folder '$TMP'"
        JAR_VERSION=$(java -jar "$PATH_DIRECTORY/jar/$JAR_NAME.jar" --version) 1>/dev/null 2>&1 3>&1
        local RETURN=$?
        if [[ $RETURN = 0 ]]; then
            if [[ "$JAR_VERSION" =~ "BungeeCord" ]]; then 
                JAR_TYPE="BungeeCord"
                JAR_PROXY=1
                JAR_BUILDTOOL=0
                echo "Looks like it contains a Bungeecord proxy server"
            elif [[ "$JAR_VERSION" =~ "Waterfall" ]]; then 
                JAR_TYPE="Waterfall"
                JAR_PROXY=1
                JAR_BUILDTOOL=0
                echo "Looks like it contains a Waterfall proxy server"
            elif [[ "$JAR_VERSION" =~ "Spigot" ]]; then 
                JAR_TYPE="Spigot"
                JAR_PROXY=0
                JAR_BUILDTOOL=0
                echo "Looks like it contains a Spigot game server"
            elif [[ "$JAR_VERSION" =~ "Paper" ]]; then 
                JAR_TYPE="Paper"
                JAR_PROXY=0
                JAR_BUILDTOOL=0
                if [[ "$JAR_VERSION" =~ "Downloading vanilla jar..." ]]; then
                    echo "Looks like it is a PaperMC pre-patch jar"
                    local BASENAME=$(basename $(ls $TMP/cache/patched_*.jar)) 1>/dev/null 2>&1
                    if [[ $? != 0 ]]; then
                        print_notification 3 "The PaperMC pre-patch jar file should download a vanilla jar and patch it. But it seems it failed to patch the vanilla jar. Maybe you should check your network connection."
                        popd
                        print_notification 1 "Got out from temporary folder '$TMP'"
                        rm -rf "$TMP"
                        return 2 ## paper patch error
                    else
                        check_environment_local subfolder-jar
                        JAR_VERSION_MC=${BASENAME:8:-4} 
                        JAR_VERSION="git${JAR_VERSION#*git}"
                        local TARGET=`ls $TMP/cache/patched_*.jar |awk '{print $1}'`
                        mv -f "$TARGET" "$PATH_DIRECTORY/jar/$JAR_NAME.jar"
                        print_notification 0 "Successfully patched paper and overwritten existing paper pre-patch jar with post-patch jar"
                    fi
                else    
                    echo "Looks like it contains a Paper game server"
                fi
            elif [[ "$JAR_VERSION" =~ "version is not a recognized option" ]]; then
                echo "Looks like it contains a vannila server"
                JAR_PROXY=0
                JAR_BUILDTOOL=0
                JAR_TYPE="Vanilla"
                JAR_VERSION="Unknown"
            else
                JAR_TYPE="$JAR_VERSION"
                JAR_PROXY=0
                JAR_BUILDTOOL=0
                echo "We could not identify the jar's type, using version as its type"
            fi
        elif [[ $RETURN = 1 ]]; then
            if [[ "$JAR_VERSION" =~ "BuildTools" ]]; then
                echo "Looks like it contains Spigot BuildTools"
                echo "Sweet! You can build a spigot jar using '$PATH_SCRIPT jar build [jar] $JAR_NAME [version]'!"
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
                    print_notification 1 "Got out from temporary folder '$TMP'"
                    return 3 #corrupt jar and deleted
                else
                    JAR_TAG=""
                    JAR_PROXY=0
                    JAR_BUILDTOOL=0
                    JAR_TYPE="Corrupt"
                    JAR_VERSION="Corrupt"
                    JAR_TAG="This jar is definitely broken, do not use it to deploy servers!"
                fi
            fi
        fi
        popd 1>/dev/null 2>&1
        print_notification 1 "Got out from temporary folder '$TMP'"
        rm -rf "$TMP"
        return 0
    fi
} ## Identify the type of the jar file, need $JAR_NAME 


subfunc_info_jar() {
    if [[ ! -f "$PATH_DIRECTORY/jar/$JAR_NAME.conf" ]]; then
        print_notification 3 "Configuration file for jar '$JAR_NAME' does not exist, maybe you should run '$PATH_SCRIPT jar config $JAR_NAME' first"
        return 1 #config not exist
    else
        local JAR_SIZE=`wc -c $PATH_DIRECTORY/jar/$JAR_NAME.jar |awk '{print $1}'`
        config_read_
  rint_multilayer_menu "SIZE: $JAR_SIZE"
        print_multilayer_menu "TYPE: $JAR_TYPE"
        if [[ ! -z "$JAR_TAG" ]]; then
            print_multilayer_menu "TAG: $JAR_TAG"
        else
            print_multilayer_menu "TAG:" "You have not tagged this jar yet"
        fi
        if [[ $JAR_PROXY = 1 ]]; then
            print_multilayer_menu "PROXY: √" "This jar contains a proxy server. You can do a multi-host using this proxy"
        else
            print_multilayer_menu "PROXY: X" 
        fi
        if [[ $JAR_BUILDTOOL = 1 ]]; then
            print_multilayer_menu "BUILDTOOL: √ " "This jar contains Spigot Buildtools. You may want to build a jar using '$PATH_SCRIPT jar build [jar] $JAR_NAME $VERSION'"
        else
            print_multilayer_menu "BUILDTOOL: X"
        fi
        print_multilayer_menu "VERSION: $JAR_VERSION" "The version of the jar itself"
        print_multilayer_menu "VERSION_MC: $JAR_VERSION_MC" "The version of minecraft server it can provide" 1 1
        return 0
    fi
} ## Read and print jar configuration. Return: 0 success, 1 not exist
subfunc_info_account() {
    if [[ ! -f "$PATH_DIRECTORY/account/$ACCOUNT_NAME.conf" ]]; then
        print_notification 3 "Configuration file for account '$ACCOUNT_NAME' does not exist, maybe you should run '$PATH_SCRIPT account define $JAR_NAME' first"
        return 1 #config not exist
    else
        config_read_
      _multilayer_menu "HOST: $ACCOUNT_HOST"
        print_multilayer_menu "PORT: $ACCOUNT_PORT"
        if [[ ! -z "$ACCOUNT_TAG" ]]; then
            print_multilayer_menu "TAG: $ACCOUNT_TAG"
        else
            print_multilayer_menu "TAG:" "You have not tagged this jar yet"
        fi
        print_multilayer_menu "USER: $ACCOUNT_USER"
        if [[ ! -z "$ACCOUNT_LIST" ]]; then
            print_multilayer_menu "KEY: ********" "Private key path is hiden in list"
        else
            print_multilayer_menu "KEY: $ACCOUNT_KEY"
        fi
        if [[ ! -z "$ACCOUNT_EXTRA" ]]; then
            print_multilayer_menu "EXTRA: $ACCOUNT_EXTRA" "" 
        else
            print_multilayer_menu "EXTRA: " "You have not added extra arguments for this account" 
        fi
        if [[ ! -z "$ACCOUNT_LIST" ]]; then
            print_multilayer_menu "Current SSH command ->" "ssh $ACCOUNT_HOST -p $ACCOUNT_PORT -l $ACCOUNT_USER -i ******** $ACCOUNT_EXTRA" 1 1
        else
            print_multilayer_menu "Current SSH command ->" "ssh $ACCOUNT_HOST -p $ACCOUNT_PORT -l $ACCOUNT_USER -i $ACCOUNT_KEY $ACCOUNT_EXTRA" 1 1
        fi
        return 0
    fi
} 





subfunc_server_status() {
    $SERVER_SSH "screen -ls | grep -q \"$SERVER_SCREEN\""
    return $?
} NOT_PROGRAMED

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
    local JAR_NAME="$1"
    utility_name_fix_jar
    if [[ -f "$PATH_DIRECTORY/jar/$JAR_NAME.jar" ]]; then
        interactive_yn N "A jar with the same name $JAR_NAME has already been defined, you will overwrite this jar file. Are you sure you want to overwrite it?"
        if [[ $? = 1 ]]; then
            return 1 ## Aborted overwriting
        elif [[ ! -w "$PATH_DIRECTORY/jar/$JAR_NAME.jar" ]]; then
            print_notification 3 "No permission to overwrite $JAR_NAM.jar, importing failed. check your permission"
            return 2 ## already exist and can not overwrite
        fi
    fi
    if [[ -f "$2" ]]; then
        local TMP=`echo "${2: -4}" | tr [A-Z] [a-z]`
        if [[ ! -r "$2" ]]; then
            print_notification 3 "No read permission for file $2, importing failed. check your permission"
            return 3 ## No read permission for local file
        elif [[ "$TMP" != ".jar" ]]; then
            print_notification 1 "The file extension of this file is not .jar, maybe you've input a wrong file, but M7CM will try to import it anyway"
        fi
        print_notification 1 "Importing jar '$JAR_NAME' from local file '$2'"
        \cp -f "$2" "$PATH_DIRECTORY/jar/$JAR_NAME.jar"
        if [[ $? != 0 ]]; then
            print_notification 3 "Failed to copy file $2, importing failed"
            return 4 ## failed to copy. wtf is that reason?
        else
            local JAR_TAG="Imported at `date +"%Y-%m-%d-%k:%M"` from local source $2"
        fi
    else
        local REGEX='(https?|ftp|file)://[-A-Za-z0-9\+&@#/%?=~_|!:,.;]*[-A-Za-z0-9\+&@#/%=~_|]'
        if [[ "$2" =~ $REGEX ]]; then
            print_notification 1 "Importing jar '$JAR_NAME' from url '$2'"
            wget -O "$PATH_DIRECTORY/jar/$JAR_NAME.jar" "$2"
            if [[ $? != 0 ]]; then
                print_notification 3 "Failed to download file $2, importing failed. check your network connection"
                return 5
            else
                local JAR_TAG="Imported at `date +"%Y-%m-%d-%k:%M"` from online source $2"
            fi
        else
            print_notification 3 "$2 is not an existing local file nor a valid url, importing failed"
            return 6
        fi
    fi
    config_write_jar
    interactive_yn Y "Importing success! Do you want to auto-identify and configure it now?"
    if [[ $? = 0 ]]; then
        action_jar_config $JAR_NAME "TAG = $JAR_TAG"
    else
        print_notification 1 "Aborted configuring jar '$JAR_NAME', you may want to use '$PATH_SCRIPT jar config $JAR_NAME' to configure it later"
    fi
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
    local JAR_NAME="$1"
    utility_name_fix_jar
    if [[ ! -f "$PATH_DIRECTORY/jar/$JAR_NAME.jar" ]]; then
        print_notification 3 "Jar '$JAR_NAME' does not exist, failed to configure it"
        return 1 # not exist
    fi
    local JAR_TAG=''
    local JAR_TYPE=''
    local JAR_VERSION=''
    local JAR_VERSION_MC=''
    local JAR_PROXY=0
    local JAR_BUILDTOOL=0
    if [[ -f "$PATH_DIRECTORY/jar/$JAR_NAME.conf" ]]; then
        if [[ ! -w "$PATH_DIRECTORY/jar/$JAR_NAME.conf" ]]; then
            print_notification 3 "Configuration file of jar '$JAR_NAME' is not writable now, thus we can not configure it."
            return 2 # existing configuration not writable
        elif [[ ! -r "$PATH_DIRECTORY/jar/$JAR_NAME.conf" ]]; then
            print_notification 2 "We can not read existing configuration file for jar '$JAR_NAME', did you edited it as other users? All options set to default"
            ## still proceed
        else
            config_read_
   fi
    if [[ ! -z "$2" ]]; then
        assignment_jar "${@:2}"
    fi
    if [[ ! -f "$PATH_DIRECTORY/jar/$JAR_NAME.conf" ]]; then
        print_notification 1 "Looks like this jar is just added to our library or its configuration file has been lost, proceeding to auto-identify it"
        subfunc_identify_jar 
        interactive_anykey
    fi
    ## Get jar size
    JAR_SIZE=`wc -c $PATH_DIRECTORY/jar/$JAR_NAME.jar |awk '{print $1}'`
    ## Interactive-menu
    while true; do
        clear
        print_draw_line
        print_center "Configuration for Jar File '$JAR_NAME'"
        print_draw_line
        print_multilayer_menu "NAME: $JAR_NAME" "" 0
        print_multilayer_menu "SIZE: $JAR_SIZE" "UNCHANGABLE"
        print_multilayer_menu "TAG: $JAR_TAG" 
        print_multilayer_menu "TYPE: $JAR_TYPE" "What kind of jar it is, i.e. Spigot, Paper, Vanilla. Only for memo."
        print_multilayer_menu "PROXY: $JAR_PROXY" "If it contains a proxy server, i.e. Waterfall, Bungeecord. Accept: 0/1"
        print_multilayer_menu "BUILDTOOL: $JAR_BUILDTOOL" "Whether it contains Spigot buildtools. Accept: 0/1"
        print_multilayer_menu "VERSION: $JAR_VERSION" "The version of the jar itself"
        print_multilayer_menu "VERSION_MC: $JAR_VERSION_MC" "The version of Minecraft this jar can host" 1 1
        print_draw_line
        echo "Type in the option you want to change and its new value split by =, i.e. 'TAG = This is my first jar!' (without quote and option is not case sensitive). You can also type 'identify' to let M7CM auto-identify it, or 'confirm' or 'save' to save thost values:"
        read -p " >>> " COMMAND
        case "$COMMAND" in
            identify)
                subfunc_identify_jar
                if [[ $? = 3 ]]; then
                    return 3 ## jar broken and deleted
                fi
                subinteractive_anykey
            ;;
            confirm|save)
                config_write_jar
                return 0 # success
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
        local JAR_NAME="$1"
        utility_name_fix_jar
        if [[ ! -f "$PATH_DIRECTORY/jar/$JAR_NAME.jar" ]]; then
            print_notification 3 "The jar file '$JAR_NAME' does not exist"
            return 1 #invalid jar
        else
            print_multilayer_menu "NAME: $JAR_NAME" "" 0
            subfunc_info_jar
        fi
    else
        local ORDER=1
        while [[ $# > 0 ]]; do
            local JAR_NAME="$1"
            utility_name_fix_jar
            if [[ ! -f "$PATH_DIRECTORY/jar/$JAR_NAME.jar" ]]; then
                print_notification 3 "The jar file '$JAR_NAME' does not exist"
            else
                print_multilayer_menu "No.$ORDER $JAR_NAME" "" 0
                subfunc_info_jar
            fi
            shift
            let ORDER++
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
    local JAR_NAME=''
    local ORDER=1
    for JAR_NAME in $(ls $PATH_DIRECTORY/jar/*.jar); do
        JAR_NAME=$(basename $JAR_NAME)
        JAR_NAME=${JAR_NAME:0:-4}
        print_multilayer_menu "No.$ORDER $JAR_NAME" "" 0
        subfunc_info_jar
        let ORDER++
    done
    print_draw_line
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
        local JAR_NAME="$1"
        utility_name_fix_jar
        if [[ ! -f "$PATH_DIRECTORY/jar/$JAR_NAME.jar" ]]; then
            print_notification 3 "The jar '$JAR_NAME' you specified does not exist!"
            return 1 ## not exist
        elif [[ ! -w "$PATH_DIRECTORY/jar/$JAR_NAME.jar" ]]; then
            print_notification 3 "Removing failed due to lacking of writing permission of jar file '$JAR_NAME.jar'"
            return 2 ## jar not writable 
        elif [[ ! -w "$PATH_DIRECTORY/jar/$JAR_NAME.conf" ]]; then
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
    if [[ $# -lt 2 ]]; then
        action_help
        print_notification 3 "Too few arguments!"
        interactive_anykey
        return 255 # Too few arguments
    fi
    check_environment_local jre git subfolder-jar
    if [[ ENV_LOCAL_JRE = 0 ]]; then
        print_notification 3 "Spigot build function is not available due to lacking of Java Runtime Environment"
        return 1 #environment error-jre
    elif [[ ENV_LOCAL_GIT = 0 ]]; then
        print_notification 3 "Spigot build function is not available due to lacking of Git"
        return 2 #environment error-git
    fi
    local JAR_NAME="$2"
    utility_name_fix_jar
    if [[ ! -f "$PATH_DIRECTORY/jar/$JAR_NAME.jar" ]]; then
        print_notification 3 "The buildtool you set does not exist"
        return 3 #buildtool not exist
    fi
    local JAR_TAG=''
    local JAR_TYPE=''
    local JAR_VERSION=''
    local JAR_VERSION_MC=''
    local JAR_PROXY=0
    local JAR_BUILDTOOL=0
    config_read_
  _BUILDTOOL != 1 ]]; then
        print_notification 3 "The buildtool you set was not set as a buildtool"
        return 4 # not a buildtool
    fi
    local BUILDTOOL="$JAR_NAME"
    JAR_NAME="$1"
    utility_name_fix_jar
    if [[ -f "$PATH_DIRECTORY/jar/$JAR_NAME.jar" ]]; then
        if [[ ! -w "$PATH_DIRECTORY/jar/$JAR_NAME.jar" ]]; then
            print_notification 3 "Another jar with the same name '$JAR_NAME' has existed, and can not be overwritten due to lacking of writing permission. Check your permission"
            return 5 # can not overwrite existing jar

        else
            interactive_yn N "Another jar with the same name '$JAR_NAME' has existed, would you like to overwrite it?"
            if [[ $? = 1 ]]; then
                return 6 # user aborted overwriting
            fi
        fi
    fi
    local REGEX='^1.[0-9]+.[0-9]+$'
    if [[ -z "$3" || "$3" = "latest" ]]; then
        local VERSION="latest"
    elif [[ "$3" =~ ^[0-9][0-9]w[0-9][0-9][a-e]$ ]]; then
        print_notification 2 "You are trying to build snapshot rev '$3', usually Spigot does not support Minecraft snapshot versions."
        interactive_yn N "Continue anyway?"
        if [[ $? = 0 ]]; then
            return 7 ##  user aborted because of suspicious version
        fi
    elif [[ "$3" =~ (1.(1[0-9]|[0-9]).[0-9]|1.(1[0-9]|[0-9])) ]]; then
        local VERSION1 VERSION2 VERSION3
        local IFS='.'
        read -r VERSION1 VERSION2 VERSION3 <<< "$3"
        local IFS=$' \t\n'
        if [[ "$VERSION2" -ge 8 ]] && [[ "$VERSION3" -le 8 || -z "$VERSION3" ]]; then
            local VERSION="$3"
        else
            interactive_yn N "The version '$3' seems not a correct version, do you want to proceed anyway?"
            if [[ $? = 0 ]]; then
                local VERSION="$3"
            else
                return 7 # user aborted because of suspicious version
            fi
        fi
    else
        interactive_yn N "The version '$3' seems not a correct version, do you want to proceed anyway?"
        if [[ $? = 1 ]]; then
            local VERSION="$3"
        else
            return 7 # user aborted because of suspicious version
        fi
    fi
    local TMP="/tmp/M7CM-Spigot-building-$JAR_NAME-`date +"%Y-%m-%d-%k-%M"`"
    mkdir "$TMP" 1>/dev/null 2>&1
    pushd "$TMP" 1>/dev/null 2>&1
    print_notification 1 "Switched to temporary folder '$TMP'"
    print_notification 1 "Using build command: java -jar $PATH_DIRECTORY/jar/$BUILDTOOL.jar --rev $VERSION"
    print_notification 1 "Building Spigot jar '$JAR_NAME' rev '$VERSION' using Buildtools jar '$BUILDTOOL'. This may take a few minutes depending on your network connection and hardware performance"
    java -jar "$PATH_DIRECTORY/jar/$BUILDTOOL.jar" --rev "$VERSION"
    if [[ $? != 0 ]]; then
        print_notification 3 "Failed to build Spigot version $BUILD_VERSION"
        popd 1>/dev/null 2>&1
        print_notification 1 "Got out from temporary folder '$TMP'"
        rm -rf "$TMP"
        return 8 #build error
    else
        local OUTPUT=`ls spigot-*.jar | awk '{print $1}'`
        cp "$OUTPUT" "$PATH_DIRECTORY/jar/$JAR_NAME.jar"
        if [[ $? != 0 ]]; then
            print_notification "Failed to get compiled jar '$JAR_NAME', building failed"
            return 9 #build failed
        fi
        popd 1>/dev/null 2>&1
        print_notification 1 "Got out from temporary folder '$TMP'"
        rm -rf "$TMP"
        print_notification 1 "Successfully built Spigot jar '$JAR_NAME' rev '$VERSION' using Buildtools jar '$BUILDTOOL'! It's already added in your jar library."
        config_write_jar
        interactive_yn Y "Would you like to configure it now?"
        if [[ $? = 0 ]]; then
            action_jar_config "$JAR_NAME" "TAG=Built at `date +"%Y-%m-%d-%k:%M"` using M7CM" "TYPE=Spigot" "PROXY=0" "VERSION=Spigot-$VERSION" "VERSION_MC=$VERSION" "BUILDTOOL=0"
        else
            print_notification 2 "You have aborted configuring jar '$JAR_NAME', this may result in unexpected consequences. It'd be better to configure it now using '$PATH_SCRIPT jar config $JAR_NAME' "
        fi
        return 0
    fi
} ## Usage: action_jar_build [jar name] [buildtool] [version]
    ## Return: 0 success 1 environment error-jre 2 environment error-git, 3 buildtool not exist, 4 not a buildtool, 5 can not overwrite existing jar, 6 user aborted overwriting, 7 user aborted because of suspicious version, 8 build error,9 build failed
## account related
action_account_define() {
    if [[ $# -lt 5 ]]; then
        print_notification 3 "Too few arguments!"
        interactive_anykey
        action_help
        return 255 # Too few arguments
    fi
    check_environment_local subfolder-account
    if [[ -f "$PATH_DIRECTORY/account/$1.conf" ]]; then
        if [[ ! -w "$PATH_DIRECTORY/account/$1.conf" ]]; then
            print_notification 3 "There's already an account with the same name '$1', and can not be overwritten due to lacking of writing permission. Check your permission"
            return 1 # can not overwrite existing account
        else
            interactive_yn N "You've already defined an account with the same name '$1', are you sure you want to overwrite it?"
            if [[ $? = 0 ]]; then
                print_notification 1 "Proceeding to overwrite account '$1'..."
            else
                return 2 # aborted overwriting
            fi
        fi
    fi
    print_notification 0 "Proceeding to configuration page of account '$1' in 1 second..."
    sleep 1
    local ACCOUNT_NEW=1
    action_account_config "$1" "HOST = $2" "TAG = Defined at `date +"%Y-%m-%d-%k-%M"`" "PORT = $3" "USER = $4" "KEY = $5" 
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
    local ACCOUNT_NAME="$1"
    local ACCOUNT_TAG=''
    local ACCOUNT_HOST=''
    local ACCOUNT_PORT=''
    local ACCOUNT_USER=''
    local ACCOUNT_KEY=''
    local ACCOUNT_EXTRA=''
    local ACCOUNT_VALID=0
    if [[ -z "$ACCOUNT_NEW" ]]; then
        ## Only try to read if not from action_account_define
        if [[ ! -f "$PATH_DIRECTORY/account/$ACCOUNT_NAME.conf" ]]; then
        ## Not defined in action_account_define
            print_notification 3 "The account '$ACCOUNT_NAME' does not exist. "
            return 1 # non-exist account
        # elif [[ ! -r "$PATH_DIRECTORY/account/$ACCOUNT_NAME.conf" ]]; then
        #     print_notification 3 "Con '$ACCOUNT_NAME' not readable"
        else
            config_read_
          if [[ ! -z "$2" ]]; then
        assignment_account "${@:2}"
    fi
    while true; do
        clear
        print_draw_line
        print_center "Configuration for Account '$ACCOUNT_NAME'"
        print_draw_line
        print_multilayer_menu "NAME: $ACCOUNT_NAME" "" 0
        print_multilayer_menu "TAG: $ACCOUNT_TAG" "Just for memo"
        print_multilayer_menu "HOST: $ACCOUNT_HOST" "Can be domain or ip, i.e. mc.mydomain.com, or 33.33.33.33. Default: localhost"
        print_multilayer_menu "PORT: $ACCOUNT_PORT" "Interger, 0-65535. Default: 22"
        print_multilayer_menu "USER: $ACCOUNT_USER" "User name will be used to login. Default: current user('$USER')"
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
            print_notification 1 "This account is invalid X " "Type 'validate' to validate it first"
        fi
        print_draw_line
        echo "Type in the option you want to change and its new value split by =, i.e. 'PORT = 22' (without quote and option is not case sensitive)."
        read -p ">>>" COMMAND
        case "$COMMAND" in
            validate)
                check_validate_account
            ;;
            confirm|save)
               if [[ $ACCOUNT_VALID = 1 ]]; then
                    config_write_
       return 0
                elif [[ $ACCOUNT_VALID = 0 ]]; then
                    print_notification 3 "This account is invalid" "You must use 'validate' to validate it first"
                fi
            ;;
            *)
                assignment_account "$COMMAND"
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
        print_multilayer_menu "NAME: $1" "" 0
        local ACCOUNT_NAME="$1"
        if [[ ! -f "$PATH_DIRECTORY/account/$ACCOUNT_NAME.conf" ]]; then
            print_notification 3 "This account does not exist"
            return 1 # not exist
        else
            subfunc_info_account
        fi
    else
        local ORDER=1
        while [[ $# > 0 ]]; do
            local ACCOUNT_NAME="$1"
            if [[ ! -f "$PATH_DIRECTORY/account/$ACCOUNT_NAME.conf" ]]; then
                print_notification 3 "The jar file '$ACCOUNT_NAME' does not exist"
            else
                config_read_
      nc_print_multilayer_menu "No.$ORDER $ACCOUNT_NAME" "" 0
                subfunc_info_account
                let ORDER++
            fi
            shift
        done
    fi
    print_draw_line
    return 0
}
action_account_list() {
    print_draw_line
    print_center "Account list"
    print_draw_line
    check_environment_local subfolder-account
    local ACCOUNT_NAME=''
    local ORDER=1
    for ACCOUNT_NAME in $(ls $PATH_DIRECTORY/account/*.conf); do
        ACCOUNT_NAME=$(basename $ACCOUNT_NAME)
        ACCOUNT_NAME=${ACCOUNT_NAME:0:-5}
        print_multilayer_menu "No.$ORDER $ACCOUNT_NAME" "" 0
        local ACCOUNT_LIST=1
        subfunc_info_account
        let ORDER++
    done
    print_draw_line
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
        else
            interactive_yn N "Are you sure you want to remove account '$1' from your library?"
            if [[ $? = 0 ]]; then
                rm -f "$PATH_DIRECTORY/account/$1.conf"
                print_notification 1 "Removed jar '$1' from library"
                return 0
            else
                return 3 ## User refused 
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
    local SERVER_NAME="$1"
    if [[ -f "$PATH_DIRECTORY/server/$SERVER_NAME.conf" ]]; then
        if [[ -w "$PATH_DIRECTORY/server/$SERVER_NAME.conf" ]]; then
            print_notification 3 "There's already a server with the same name '$SERVER_NAME' and can not be overwritten due to lacking of writing permission to file '$SERVER_NAME.conf'"
            return 1 # duplication and not want to overwrite
        else
            print_notification 2 "There's already a server with the same name '$SERVER_NAME'"
            interactive_yn N "Are you sure you want to overwrite it?" 
            if [[ $? != 0 ]]; then
                return 2 # user give up
            fi
        fi
    fi
    local SERVER_TAG="Added at `date +"%Y-%m-%d-%k:%M"`"
    action_server_config "$SERVER_NAME" "ACCOUNT = $2" "DIRECTORY = $3" "PORT= $4" "RAM_MAX = $5" "RAM_MIN = $6" "JAR = $7" "EXTRA_JAVA = $8" "EXTRA_JAR = $9"
    if [[ $? = 0 ]]; then
        print_notification 1 "Successfully added server '$SERVER_NAME'"
    else
        print_notification 3 "Failed to add server '$SERVER_NAME'"
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
    local SERVER_NAME="$1"
    local SERVER_TAG
    local SERVER_DIRECTORY
    local SERVER_PORT
    local SERVER_RAM_MAX
    local SERVER_RAM_MIN
    local SERVER_JAR
    local SERVER_EXTRA_JAVA
    local SERVER_EXTRA_JAR
    local SERVER_VALID=0
    if [[ -z "$SERVER_NEW" ]]; then
        ## Only try to read if not from action_account_define
        if [[ ! -f "$PATH_DIRECTORY/server/$SERVER_NAME.conf" ]]; then
        ## Not defined in action_account_define
            print_notification 3 "The server '$SERVER_NAME' does not exist"
            return 1 # non-exist account
        else
            config_read_server
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
        print_multilayer_menu "PORT: $SERVER_PORT" "Interger. Default: 25565"
        print_multilayer_menu "RAM_MAX: $SERVER_RAM_MAX" "Interger+M/G, i.e. 1024M. Default:1G, not less than RAM_MIN"
        print_multilayer_menu "RAM_MIN: $SERVER_RAM_MIN" "Interger+M/G, i.e. 1024M. Default:1G, not greater than RAM_MAX"
        print_multilayer_menu "JAR: $SERVER_RAM_MIN" "Remote server jar file with file extention. Can be absolute path. Default: server.jar"
        if [[ -z "$SERVER_EXTRA_JAVA" ]]; then
            print_multilayer_menu "EXTRA_JAVA: $SERVER_EXTRA_JAVA" "Extra arguments for java, i.e. -XX:+UseG1GC. Usually you don't need this"
        else
            print_multilayer_menu "EXTRA_JAVA: $SERVER_EXTRA_JAVA"
        fi
        if [[ -z "$SERVER_EXTRA_JAR" ]]; then
            print_multilayer_menu "EXTRA_JAR: $SERVER_EXTRA_JAR" "Extra arguments for the jar itself, i.e. used for SSH. DO NOT EDIT THIS if you don't know what you are doing" 1 1
        else
            print_multilayer_menu "EXTRA: $SERVER_EXTRA" "Extra arguments used for SSH." 1 1
        fi
        print_draw_line
        print_notification 1 "Current startup command: 'java -Xmx$SERVER_RAM_MAX -Xms$SERVER_RAM_MIN $SERVER_EXTRA_JAVA -jar $SERVER_JAR nogui --port $SERVER_PORT $SERVER_EXTRA_JAR'"
        print_draw_line
        if [[ $ACCOUNT_VALID = 1 ]]; then
            print_notification 1 "This server is valid √ " "You can type 'save' or 'confirm' to save it now"
        elif [[ $ACCOUNT_VALID = 0 ]]; then
            print_notification 1 "This server is invalid X " "Type 'validate' to validate it first"
        fi
        print_draw_line
        echo "Type in the option you want to change and its new value split by =, i.e. 'PORT = 25565' (without quote and option is not case sensitive)."
        read -p ' >>> ' COMMAND
        case "$COMMAND" in
            validate)
                check_validate_server
            ;;
            confirm|save)
               if [[ $SERVER_VALID = 1 ]]; then
                    config_write_server
                    if [[ ! -z "$1" ]]; then
        local ACCOUNT_NAME="$1"
    fi
                    return 0
                elif [[ $ACCOUNT_VALID = 0 ]]; then
                    print_notification 3 "This server is invalid" "You must use 'validate' to validate it first"
                fi
            ;;
            *)
                assignment_account "$COMMAND"
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
    fi
    if [[ $# = 1 ]]; then
        if [[ ! -f "$PATH_DIRECTORY/server/$1.conf" ]]; then
            print_notification 3 "The server '$1' you specified does not exist!"
            return 1 ## not exist
        elif [[ ! -w "$PATH_DIRECTORY/server/$1.conf" ]]; then
            print_notification 3 "Removing failed due to lacking of writing permission of configuration file '$1.conf'"
            return 2 ## jar not writable 
        else
            interactive_yn N "Are you sure you want to remove server '$1' from your library?"
            if [[ $? = 0 ]]; then
                action_server_stop "$1"
                rm -f "$PATH_DIRECTORY/server/$1.conf"
                print_notification 1 "Removed server '$1' from library"
                return 0
            else
                return 3 ## User refused 
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

}
action_server_list() {

}
action_server_start() {
    if [[ $# = 0 ]]; then
        action_help
        print_notification 3 "Too few arguments!"
        interactive_anykey
        return 255 # Too few arguments
    fi
    if [[ $# = 1 ]]; then
        if [[ ! -f "$PATH_DIRECTORY/server/$1.conf" ]]; then
            print_notification 3 "The server '$1' you specified does not exist!"
            return 1 ## not exist
        elif [[ ! -r "$PATH_DIRECTORY/server/$1.conf" ]]; then
            print_notification 3 "Configuration file for server '$1' not readable, check your permission"
            return 2
        else
            local SERVER_NAME="$1"
            local SERVER_ACCOUNT
            local SERVER_DIRECTORY
            local SERVER_PORT
            local SERVER_RAM_MAX
            local SERVER_RAM_MIN
            local SERVER_JAR
            local SERVER_EXTRA_JAVA
            local SERVER_EXTRA_JAR
            config_read_server
            local ACCOUNT_NAME="$SERVER_ACCOUNT"
            local ACCOUNT_HOST
            local ACCOUNT_PORT
            local ACCOUNT_USER
            local ACCOUNT_KEY
            local ACCOUNT_EXTRA
            config_read_
      SERVER_SSH="ssh $ACCOUNT_HOST -p $ACCOUNT_PORT -l $ACCOUNT_USER -i $ACCOUNT_KEY $ACCOUNT_EXTRA"
            local SERVER_SCREEN="M7CM-server-$SERVER_ACCOUNT-$SERVER_NAME-$SERVER_JAR-on-$SERVER_PORT"
            $SERVER_SSH "screen -ls | grep -q \"$SERVER_SCREEN\""
            if [[ $? = 0 ]]; then
                print_notification 3 "Server '$SERVER_NAME' is already running, failed to start it"
                return 3
            else
                local SERVER_JAVA="java -Xmx$SERVER_RAM_MAX -Xms$SERVER_RAM_MIN $SERVER_EXTRA_JAVA -jar $SERVER_JAR nogui --port $SERVER_PORT $SERVER_EXTRA_JAR"
                $SERVER_SSH "screen -mSUd \"$SERVER_SCREEN\" \"$SERVER_JAVA\""
                print_notification 1 "Started server '$SERVER_NAME'"
                return 0
            fi
        fi
    else
        while [[ $# > 0 ]]; do
            action_server_remove "$1"
            shift
        done
    fi
} 
action_server_stop() {
    if [[ $# = 0 ]]; then
        action_help
        print_notification 3 "Too few arguments!"
        interactive_anykey
        return 255 # Too few arguments
    fi
    if [[ $# = 1 ]]; then
        if [[ ! -f "$PATH_DIRECTORY/server/$1.conf" ]]; then
            print_notification 3 "The server '$1' you specified does not exist!"
            return 1 ## not exist
        elif [[ ! -r "$PATH_DIRECTORY/server/$1.conf" ]]; then
            print_notification 3 "Configuration file for server '$1' not readable, check your permission"
            return 2
        else
            local SERVER_NAME="$1"
            local SERVER_ACCOUNT
            local SERVER_DIRECTORY
            local SERVER_PORT
            local SERVER_RAM_MAX
            local SERVER_RAM_MIN
            local SERVER_JAR
            local SERVER_EXTRA_JAVA
            local SERVER_EXTRA_JAR
            config_read_server
            local ACCOUNT_NAME="$SERVER_ACCOUNT"
            local ACCOUNT_HOST
            local ACCOUNT_PORT
            local ACCOUNT_USER
            local ACCOUNT_KEY
            local ACCOUNT_EXTRA
            config_read_
      SERVER_SSH="ssh $ACCOUNT_HOST -p $ACCOUNT_PORT -l $ACCOUNT_USER -i $ACCOUNT_KEY $ACCOUNT_EXTRA"
            local SERVER_SCREEN="M7CM-server-$SERVER_ACCOUNT-$SERVER_NAME-$SERVER_JAR-on-$SERVER_PORT"
            $SERVER_SSH "screen -ls | grep -q \"$SERVER_SCREEN\""
            if [[ $? = 1 ]]; then
                print_notification 3 "Server '$SERVER_NAME' is not running, no need to stop it"
                return 3
            else
                $SERVER_SSH "screen -rXd \"$SERVER_SCREEN\" stuff \"^Mend^Mexit^M\""
                print_notification 1 "Issued stop command(end/exit) to '$SERVER_NAME'"
                print_notification 1 "Checking if server is correctly stopped in 3 seconds... "
                sleep 3
                $SERVER_SSH "screen -ls | grep -q \"$SERVER_SCREEN\""
                if [[ $? = 0 ]]; then
                    print_notification 2 "Server not stopped in 3 seconds"
                $SERVER_SSH "screen -mSUd \"$SERVER_SCREEN\" \"$SERVER_JAVA\""
                print_notification 1 "Stopped server '$SERVER_NAME'"
                return 0


                local TMP=$(screen -ls | grep "$SSERVER_SCREEN" | awk '{print $1}')
                local TMP_PID
                local TMP_NAME
                local IFS='.'
                read -r TMP_PID TMP_NAME <<< "$TMP"
                ##########################################
                ###########################################
                ######### NOT FINISHED

            fi
        fi
    else
        while [[ $# > 0 ]]; do
            action_server_remove "$1"
            shift
        done
    fi
} NOT_PROGRAMED
action_server_restart() {
    if [[ $# = 0 ]]; then
        action_help
        print_notification 3 "Too few arguments!"
        interactive_anykey
        return 255 # Too few arguments
    fi
    if [[ $# = 1 ]]; then
        if [[ ! -f "$PATH_DIRECTORY/server/$1.conf" ]]; then
            print_notification 3 "The server '$1' you specified does not exist!"
            return 1 ## not exist
        else
            action_server_stop "$1"
            action_server_start "$1"
        fi
    else
        while [[ $# > 0 ]]; do
            action_server_remove "$1"
            shift
        done
    fi
} 
action_help() {
    print_draw_line
    print_center "Command Help for Minecraft 7 Command-line Manager"
    print_draw_line
    print_multilayer_menu "$PATH_SCRIPT" "" 0
    print_multilayer_menu "help" "print this help message" 
    print_multilayer_menu "define [server] [account] ([directory] [port] [max ram] [min ram] [remote jar])" "(re)define a server so M7CM can manage it." 
    print_multilayer_menu "config [server] ([option1=value1] [option2=value2]" "change one specific option you defined by $PATH_SCRIPT define" 
    print_multilayer_menu "start [server1] [server2] ..." "start one or multiple pre-defined servers" 
    print_multilayer_menu "stop [server1] [server2] ..." "stop one or multiple pre-defined servers" 
    print_multilayer_menu "restart [server1] [server2] ..." 
    print_multilayer_menu "browse [server]" "open the directory of the given server so you can modify it" 
    print_multilayer_menu "console [server] ..." "connect you to the server's console" 
    print_multilayer_menu "send [server] [command]" "send a command" 
    print_multilayer_menu "remove [server]"
    print_multilayer_menu "status [server]"
    ## group related commands
    print_multilayer_menu "group [sub action]" "group related action. m7cm have a reserverd group _ALL_ for all servers you defined"
    print_multilayer_menu "define [group] [server1] [server2] ..." "(re)define a group" 2
    print_multilayer_menu "start [group]" "" 2
    print_multilayer_menu "stop [group]" "" 2
    print_multilayer_menu "restart [group]"  "" 2
    print_multilayer_menu "remove [group]" "remove all servers in the group and the group itself" 2
    print_multilayer_menu "delete [group]" "just remove the group itself, keep servers" 2
    print_multilayer_menu "push [group] [jar]" "push the given jar to all servers in group" 2
    print_multilayer_menu "status [group]" "list all servers' status in the given group" 2 1
    ## jar related command
    print_multilayer_menu "jar [sub action]" "jar-related commands, [jar] does not incluede the .jar suffix"
    print_multilayer_menu "import [jar] [link/path]" "import a jar from an online source or local disk, you need GNU/Wget to download the jar" 2
    print_multilayer_menu "push [jar] [server]" "push the given jar to this server" 2
    print_multilayer_menu "pull [jar] [server] [remote jar]" "pull the remote jar, use fullname" 2
    print_multilayer_menu "config [jar] ([option1=value1] [option2=value2] ...)" "" 2
    print_multilayer_menu "build [jar] [buildtool-jar] ([version])" "build a jar file of the given version using spigot buildtool, you need to import or download the buildtool first" 2
    print_multilayer_menu "remove [jar1] [jar2] ..." "remove a jar and this configuration" 2
    print_multilayer_menu "info [jar1] [jar2] ..." "check the configuration of the jar file" 2
    print_multilayer_menu "list" "lsit all jar files and their configuration" 2 1
    ## account related command
    print_multilayer_menu "account [sub action]" "" 1 1
    print_multilayer_menu "define [account] [hostname/ip] [ssh port] [user] [private key]" "" 2 0 1
    print_multilayer_menu "config [account] ([option1=value1] [option2=value2] ...)" "" 2 0 1
    print_multilayer_menu "remove [account1] [account2] ..." "" 2 0 1
    print_multilayer_menu "info [account1] [account2] ..." "" 2 0 1
    print_multilayer_menu "list" "" 2 1 1
    print_draw_line
    print_notification 0 "Any [account] used by a server must have been pre-defined by '$PATH_SCRIPT account define', M7CM will use SSH to connect to this host and perform management. Even if you want to run and manage servers on the same host as M7CM, you still need to use SSH to ensure both the isolation and the security. Notice that the [account] here is just for easy memorizing, and does not have to be the same as [user]"
    print_notification 0 "The [remote jar] defined in a server is the remote jar's full name with file extension. But the [jar] defined in jar-related actions is a simple name for memo, without file extension (though M7CM can auto-remove it if you accidently add '.jar')"
    print_notification 1 "It's strongly recommended to use simple alphabet name for [server], [group] [account] and [jar], any extra suffix may result in unexpected accidents"
    ##print_notification 0 "Any [jar] used by a server must have been pre-imported by '$PATH_SCRIPT import', or you can use '_REMOTE_' to let M7CM use the remote jar, if so, you must define [remote jar] with its full name. refer to a jar file in the directory of the server (will be renamed to server.jar and import into jar library with the same name of the server then)"
    print_notification 0 "M7CM has a reserverd server '_LAST_' refering to the last server you've successfully managed and also a reserverd group '_LAST_'. there's also a reserverd group named '_ALL_' refering to all servers"
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
# main() {
#     func_environment_check_pre_run
#    config_read_m7cm
#     [[ $# = 0 ]] && action_help && exit
#     case "$1" in 
#         define)
#             echo "defining"
#         ;;
#         config)
#             echo "configing"
#         ;;
#         browse)
#             echo "browsing"
#         ;;
#         start)
#             echo "starting"
#         ;;
#         stop)
#             echo "stopping"
#         ;;
#         restart)
#             echo "restarting"
#         ;;
#         console)
#             echo "to console"
#         ;;
#         send)
#             echo "send command"
#         ;;
#         remove)
#             echo "removing server"
#         ;;
#         status)
#             echo "checking status"
#         ;;
#         group)
#             shift
#             #group related actions
#             case "$2" in
#                 define)
#                     #define a group
#                 ;;
#                 start)
#                     #start a group
#                 ;;
#                 stop)
#                     #stop a group
#                 ;;
#                 restart)
#                     #restart a group
#                 ;;
#                 remove)
#                     #remove a group
#                 ;;
#                 info)
#                     #info of a group
#                 ;;
#                 list)
#                     #list all groups
#                 ;;
#             esac
#         ;;
#         jar)
#             #jar related actions
#             case "$2" in 
#                 import)
#                     #import a local jar
#                     action_jar_import "${@:3}"
#                 ;;
#                 push)
#                     echo "UNDER PROGRAMMING"
#                     #push a jar to a server
#                     action_jar_push "${@:3}"
#                 ;;
#                 pull)
#                     echo "UNDER PROGRAMMING"
#                     #pull a jar from a server
#                     action_jar_pull "${@:3}"
#                 ;;
#                 config)
#                     action_jar_config "${@:3}"
#                 ;;
#                 build)
#                     action_jar_build "${@:3}"
#                 ;;
#                 remove)
#                     action_jar_remove "${@:3}"
#                 ;;
#                 info)
#                     action_jar_info "${@:3}"
#                 ;;
#                 list)
#                     action_jar_list 
#                 ;;
#                 *)
#                     action_help
#                     return 1 #Unrecognized
#                 ;;
#             esac
#         ;;
#         account)
#             #account related actions
#             case "$2" in
#                 define)
#                     action_account_define "${@:3}"
#                 ;;
#                 config)
#                     action_account_config "${@:3}"
#                 ;;
#                 remove)
#                     action_account_remove "${@:3}"
#                 ;;
#             esac
#         *)
#             action_help && return
#         ;;
#     esac
# }
# main && exit