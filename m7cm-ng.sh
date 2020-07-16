#! /bin/bash
## Minecraft 7 Command-line Manager
## A Script tool designed to manage multiple minecraft server instances conviniently

## To use this script, you need at least JRE, GNU/screen, SSH up and running
## To safely login to another server and run minecraft server instance there, you also
## need an account

## Initialization check

## global variables
PATH_SCRIPT=$(readlink -f "$0")
PATH_DIRECTORY=$(dirname $PATH_SCRIPT)
TMP=''
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
    printf '\r'
    print_draw_line ' '
    printf '\r\033[A'
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
    echo -e "  \e[100m$2\e[0m" ## Print content
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
    print_multilayer_menu "ARGUMENT_SSH: $ACCOUNT_ARGUMENT_SSH" 
    print_multilayer_menu "ARGUMENT_RSYNC: $ACCOUNT_ARGUMENT_RSYNC" 
    if [[ "$M7CM_HIDE_KEY_PATH" = 0 ]]; then
        print_multilayer_menu "Full SSH command ->" "ssh $ACCOUNT_HOST -p $ACCOUNT_PORT -l $ACCOUNT_USER -i $ACCOUNT_KEY $ACCOUNT_ARGUMENT_SSH" 1 1
    else
        print_multilayer_menu "Full SSH command ->" "ssh $ACCOUNT_HOST -p $ACCOUNT_PORT -l $ACCOUNT_USER -i ************ $ACCOUNT_ARGUMENT_SSH" 1 1
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
    config_read_account "$SERVER_ACCOUNT" 1>/dev/null 2>&1
    if [[ -z "$3" || "$3" = 0 ]]; then     
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
            print_multilayer_menu "ARGUMENT: $ACCOUNT_ARGUMENT_SSH" '' 2 1
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
        print_multilayer_menu "ARGUMENT_JAVA: $SERVER_ARGUMENT_JAVA"
        print_multilayer_menu "ARGUMENT_JAR: $SERVER_ARGUMENT_JAR"
        print_multilayer_menu "SCREEN: $SERVER_SCREEN" 
        print_multilayer_menu "COMMAND_STOP: $SERVER_COMMAND_STOP"
    fi
    if [[ "$ENV_LOCAL_SSH" = 1 ]]; then
        check_status_server '' 1
        if [[ $? = 0 ]]; then
            print_multilayer_menu "STATUS: \e[42mRUNNING" '' 1 1
        else
            print_multilayer_menu "STATUS: \e[41mSTOP" '' 1 1
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
        print_notification 1 "Looks like this is the first time you startup M7CM on this device, initializing M7CM..."
        print_notification 1 'Cheking environment...'
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
        print_notification 1 "Checking environment, if you do not want M7CM to check environment every time, you can set 'SKIP_ENVIRONMENT_CHECK=1' in config.conf"
        check_environment_local
        check_method
    fi
}
check_environment_local() {
    if [[ $# = 0 ]]; then
        check_environment_local bash ssh scp sftp rsync timeout ncat nmap screen wget curl jre root sshd git basefolder subfolder
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
            rsync)
                rsync --version 1>/dev/null 2>&1
                if [[ $? != 0 ]]; then
                    print_notification 2 'Rsync not detected!'
                else
                    ENV_LOCAL_RSYNC=1
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
                    # print_notification 1 'M7CM uses nmap to scan open ports on specific host, but that is not a must since this function is under development.'
                    ENV_LOCAL_NMAP=0
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
                check_environment_local subfolder-server subfolder-jar subfolder-account subfolder-group subfolder-backup
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
        while [[ $# -gt 0 ]]; do
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
            local METHOD=$(tr 'a-z' 'A-Z' <<< "$M7CM_METHOD_PUSH_PULL")
            eval local AVAILABLE=\$ENV_LOCAL_"$METHOD"
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
            local METHOD=$(tr 'a-z' 'A-Z' <<< "$M7CM_METHOD_DOWNLOAD")
            eval local AVAILABLE=\$ENV_LOCAL_"$METHOD"
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
            local METHOD=$(tr 'a-z' 'A-Z' <<< "$M7CM_METHOD_PORT_DIAGNOSIS")
            eval local AVAILABLE=\$ENV_LOCAL_"$METHOD"
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
                elif [[ "$ENV_LOCAL_SFTP" = 1 ]]; then
                    M7CM_METHOD_PUSH_PULL='sftp'
                else
                    M7CM_METHOD_PUSH_PULL='rsync'
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
        while [[ $# -gt 0 ]]; do
            check_method_available $1
            shift
        done
    fi
}
check_validate_host() {
    if [[ "$1" ]]; then
        local VALIDATE_HOST="$1"
    else
        local VALIDATE_HOST="$M7CM_DEFAULT_SSH_HOST"
    fi
    print_notification 1 "Diagnosing connection to the remote host '$VALIDATE_HOST'."
    ping -c3 -i0.4 -w0.8 "$VALIDATE_HOST" 1>/dev/null 2>&1
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
        local VALIDATE_HOST="$2"
    else
        local VALIDATE_HOST="$M7CM_DEFAULT_SSH_HOST"
    fi
    print_notification 1 "Diagnosing if tcp port '$1' on host '$2' is open ..."
    case ${M7CM_METHOD_PORT_DIAGNOSIS,,} in
        timeout*)
            timeout 10 sh -c "</dev/tcp/$VALIDATE_HOST/$1" 1>/dev/null 2>&1
            ;;
        ncat*)
            ncat -z -v -w5 $VALIDATE_HOST $1 1>/dev/null 2>&1 
            ;;
        nmap*)
            nmap $VALIDATE_HOST -p $1 | grep "$1/tcp open" 1>/dev/null 2>&1 
            ;;
        wget)
            local TMP="/tmp/M7CM-port-validation-$VALIDATE_HOST-$1-`date +"%Y-%m-%d-%H-%M"`"
            mkdir "$TMP"
            pushd "$TMP" 1>/dev/null 2>&1 
            wget -t1 -T1 $VALIDATE_HOST:$1 1>/dev/null 2>&1 
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
        print_notification 1 "TCP port '$1' on '$VALIDATE_HOST' is open"
        return 0
    else
        print_notification 1 "TCP port '$1' on '$VALIDATE_HOST' is not open"
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
        local ACCOUNT_ARGUMENT_SSH
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
    if [[ "$ENV_LOCAL_SSH" = 1 ]]; then
        print_notification 1 "Validating if SSH works using account '$ACCOUNT_NAME'..."
        ssh $ACCOUNT_HOST -p $ACCOUNT_PORT -l $ACCOUNT_USER -i "$ACCOUNT_KEY" $ACCOUNT_ARGUMENT_SSH exit
        if [[ $? = 0 ]]; then
            print_notification 1 "SSH validation passed"
            
        else
            print_notification 2 "SSH test failed, maybe your account configuration is wrong?"
            return 3
        fi
    fi
    if [[ "$ENV_METHOD_PUSH_PULL" = 1 && -z "$3" ]]; then
        print_notification 1 "Validating if file transfering works using account '$ACCOUNT_NAME'..."
        if [[ "$M7CM_METHOD_PUSH_PULL" = scp ]]; then
            local TMP="/tmp/M7CM-push-pull-validation-$ACCOUNT_NAME-`date +"%Y-%m-%d-%H-%M"`"
            touch "$TMP-local"
            scp -i "$ACCOUNT_KEY" -P $ACCOUNT_PORT "$TMP-local" $ACCOUNT_USER@$ACCOUNT_HOST:"$TMP-remote"
        else
            print_notification 1 "Since your push/pull method is 'sftp', we will only test if you can successfully login using sftp. Once logged in, use ctrl+D or type exit or bye to get back to finish test."
            sftp -i "$ACCOUNT_KEY" -P $ACCOUNT_PORT
            # echo "mkdir '$TMP'" > "/tmp/M7CM-push-pull-validation-$ACCOUNT_NAME-`date +"%Y-%m-%d-%H-%M"`.batch"
            # echo "get -r '$TMP' '$TMP'" >> "/tmp/M7CM-push-pull-validation-$ACCOUNT_NAME-`date +"%Y-%m-%d-%H-%M"`.batch"
            # echo "rmdir '$TMP' '$TMP'" >> "/tmp/M7CM-push-pull-validation-$ACCOUNT_NAME-`date +"%Y-%m-%d-%H-%M"`.batch"
            # sftp -i "$ACCOUNT_KEY" -P $ACCOUNT_PORT
        fi
        rm -f "$TMP-local"
        if [[ $? = 0 ]]; then
            print_notification 1 "File transfering validation passed"
            ACCOUNT_VALID=1
            if [[ "$M7CM_METHOD_PUSH_PULL" = scp ]]; then
                rm -f "$TMP"
                if [[ "$ENV_LOCAL_SSH" = 1 ]]; then
                    ssh $ACCOUNT_HOST -p $ACCOUNT_PORT -l $ACCOUNT_USER -i "$ACCOUNT_KEY" $ACCOUNT_ARGUMENT_SSH "rm -f '$TMP-remote'"
                fi
            fi
        else
            print_notification 2 "Push/pull test failed, maybe your account configuration is wrong?"
            return 4
        fi
    fi
    ACCOUNT_VALID=1
    return 0
} # check_validate_account [account] [no read] [no file transfer]
check_validate_server() {
    if [[ "$1" ]]; then
        local SERVER_NAME="$1"
    fi
    if [[ -z "$2" ]]; then
        local SERVER_ACCOUNT
        local SERVER_DIRECTORY
        local SERVER_JAR
        local SERVER_ARGUMENT_JAR
        local SERVER_ARGUMENT_JAVA
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
    if [[ "$ENV_LOCAL_SSH" = 1 ]]; then
        ssh -oBatchmode=yes $ACCOUNT_HOST -p $ACCOUNT_PORT -l $ACCOUNT_USER -i "$ACCOUNT_KEY" $ACCOUNT_ARGUMENT_SSH "screen -mSUd m7cm-test exit" 1>/dev/null 2>&1
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
        ssh -oBatchmode=yes $ACCOUNT_HOST -p $ACCOUNT_PORT -l $ACCOUNT_USER -i "$ACCOUNT_KEY" $ACCOUNT_ARGUMENT_SSH "java -version" 1>/dev/null 2>&1
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
        ssh -oBatchmode=yes $ACCOUNT_HOST -p $ACCOUNT_PORT -l $ACCOUNT_USER -i "$ACCOUNT_KEY" $ACCOUNT_ARGUMENT_SSH "test -d $SERVER_DIRECTORY"
        if [[ $? != 0 ]]; then
            print_notification 2 "Remote directory '$SERVER_DIRECTORY' does not exist. Trying to create it..."
            ssh -oBatchmode=yes $ACCOUNT_HOST -p $ACCOUNT_PORT -l $ACCOUNT_USER -i $ACCOUNT_KEY $ACCOUNT_ARGUMENT_SSH "mkdir $SERVER_DIRECTORY" 1>/dev/null 2>&1
            if [[ $? != 0 ]]; then
                print_notification 3 "Remote directory '$SERVER_DIRECTORY' can not be created. Validation failed."
                return 3 # not exist and can not be created
            else
                print_notification 1 "Remote directory '$SERVER_DIRECTORY' created"
            fi
        else
            ssh -oBatchmode=yes $ACCOUNT_HOST -p $ACCOUNT_PORT -l $ACCOUNT_USER -i "$ACCOUNT_KEY" $ACCOUNT_ARGUMENT_SSH "test -w $SERVER_DIRECTORY"
            if [[ $? != 0 ]]; then
                print_notification 3 "Remote directory '$SERVER_DIRECTORY' exists but not writable. Validation failed."
                return 4
            else
                print_notification 1 "Remote directory '$SERVER_DIRECTORY' is writable"
            fi
        fi
        ssh -oBatchmode=yes $ACCOUNT_HOST -p $ACCOUNT_PORT -l $ACCOUNT_USER -i "$ACCOUNT_KEY" $ACCOUNT_ARGUMENT_SSH "cd $SERVER_DIRECTORY; test -f $SERVER_JAR" 
        if [[ $? = 0 ]]; then
            print_notification 1 "Remote jar '$SERVER_JAR' found."
            ssh -oBatchmode=yes $ACCOUNT_HOST -p $ACCOUNT_PORT -l $ACCOUNT_USER -i "$ACCOUNT_KEY" $ACCOUNT_ARGUMENT_SSH "cd $SERVER_DIRECTORY; test -r $SERVER_JAR" 
            if [[ $? != 0 ]]; then
                print_notification 3 "Remote jar '$SERVER_JAR' is not readable. Validation failed."
                return 5
            else
                print_notification 1 "Remote jar '$SERVER_JAR' is readable."
            fi
            print_notification 1 "Test if remote jar accepts '--version' argument"
            ssh -oBatchmode=yes $ACCOUNT_HOST -p $ACCOUNT_PORT -l $ACCOUNT_USER -i "$ACCOUNT_KEY" $ACCOUNT_ARGUMENT_SSH "cd $SERVER_DIRECTORY; java -jar $SERVER_JAR --vesison" 1>/dev/null 2>&1
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
                print_notification 1 "The remote jar '$SERVER_JAR' recognizes '--version' argument"
            fi
        else
            print_notification 2 "Remote jar '$SERVER_JAR' not found. You need to push it first."
            if [[ $ENV_METHOD_PUSH_PULL = 0 ]]; then
                print_notification 3 "Neither SSH SCP or SSH SFTP found on localhost, you can not push local jar to the remote host. Validation failed."
                return 5 # jar not found and can't push
            else
                print_notification 2 "If you want to run this server, you must import/build and push a jar to it first."
                print_notification 0 "To push a jar to the server, you can use '$PATH_SCRIPT jar push [jar] $SERVER_NAME'"
                SERVER_VALID=1
                return 7
            fi
        fi
    elif [[ "$ENV_METHOD_PUSH_PULL" = 1 ]]; then
        print_notification 2 "SSH not detected, but since jar push/pull methods are available, we just consider the server is valid anyway."
        SERVER_VALID=1
    else
        print_notification 3 "Neither SSH nor SCP or SFTP is detected. No chance you can manager or interact with this server. Validation failed."
        return 8
    fi
    SERVER_VALID=1
    print_notification 1 "Validation passed"
    return 0
} # check_validate_server [server] [no read]
check_validate_ram() {
    if [[ "$1" ]]; then
        local SERVER_RAM_MAX="$1"
    fi
    if [[ "$2" ]]; then
        local SERVER_RAM_MIN="$2"
    fi
    local COMPARE_RAM_MAX=${SERVER_RAM_MAX:0:-1}
    local COMPARE_RAM_MIN=${SERVER_RAM_MIN:0:-1}
    if [[ "${SERVER_RAM_MAX: -1}" = "G" ]]; then
        local COMPARE_RAM_MAX=$(( $COMPARE_RAM_MAX * 1024 ))
    fi
    if [[ "${SERVER_RAM_MIN: -1}" = "G" ]]; then
        local COMPARE_RAM_MIN=$(( $COMPARE_RAM_MIN * 1024 ))
    fi
    if [[ $COMPARE_RAM_MIN -lt 32 ]]; then
        print_notification 2 "'$SERVER_RAM_MIN' is too small, with this amount of RAM even lightweight proxy servers like Waterfall and BungeeCord can barely run. Enlarging minimum ram to 32M."
        SERVER_RAM_MIN=32M
    fi
    if [[ $COMPARE_RAM_MAX -gt 65536 ]]; then
        print_notification 2 "Am I missing some point or are you really allocating more than 64G RAM for a teeny-tiny Minecraft server? What Minecraft server on earth can consume more than 64G of RAM? Limiting it to 64G"
        SERVER_RAM_MAX=64G
    fi
    if [[ $COMPARE_RAM_MAX -lt $COMPARE_RAM_MIN ]]; then
        if [[ $# = 0 ]]; then
            print_notification 2 "Maximum RAM is less than minimum RAM ($SERVER_RAM_MAX < $SERVER_RAM_MIN), enlarging it to minimum RAM '$SERVER_RAM_MIN'"
            SERVER_RAM_MAX=$SERVER_RAM_MIN
        else
            print_notification 2 "Maximum RAM is less than minimum RAM ($SERVER_RAM_MAX < $SERVER_RAM_MIN)"
        fi
    fi
    # if [[ $COMPARE_RAM_MAX < 128 ]]; then
    #     print_notification 2 "Maximum RAM is less than 128M, it is very likely that your server will crash frequently."
    # fi
    # if [[ $COMPARE_RAM_MIN > 32768 ]]; then
    #     print_notification 2 "Minimum RAM '$SERVER_RAM_MAX' is greater than 32G, it's WAY too much for a Minecraft server. Why are you even running a single Minecraft server instance consuming more than 32G of RAM instead of using proxy servers like BungeeCord and allocate your load to multiple backend servers?"
    # elif [[ $COMPARE_RAM_MAX > 6144 ]]; then
    #     print_notification 2 "Maximum RAM is greater than 6G, you may be wasting your RAM since most servers never consumes this much RAM."
    # fi
    return 0

} # check_validate_ram [ram_max] [ram_min]
check_validate_group() {
    if [[ "$1" ]]; then
        local GROUP_NAME="$1"
    fi
    if [[ -z "$2" || "$2" = 0 ]]; then
        if [[ -s "$PATH_DIRECTORY/group/$GROUP_NAME.conf" ]]; then
            local SERVER_NAME
            local TMP="/tmp/M7CM-validation-group-$GROUP_NAME-`date +"%Y-%m-%d-%H-%M"`"
            cp "$PATH_DIRECTORY/group/$GROUP_NAME.conf" "$TMP"
            while read SERVER_NAME; do
                if [[ ! -f "$PATH_DIRECTORY/server/$SERVER_NAME.conf" ]]; then
                    print_notification 2 "Server '$SERVER_NAME' in group '$GROUP_NAME' does not exist, removing it..."
                    sed -i /^"$SERVER_NAME"$/d "$PATH_DIRECTORY/group/$GROUP_NAME.conf"
                fi
            done < "$TMP"
            rm -f "$TMP"
        fi    
    fi
    if [[ $(sort "$PATH_DIRECTORY/group/$GROUP_NAME.conf" | uniq -cd) ]]; then
        print_notification 2 "There are duplicated servers in group '$GROUP_NAME', following is the duplicated servers and their duplicated times:"
        sort "$PATH_DIRECTORY/group/$GROUP_NAME.conf" | uniq -cd
        local TMP="/tmp/M7CM-validation-group-$GROUP_NAME-`date +"%Y-%m-%d-%H-%M"`"
        sort "$PATH_DIRECTORY/group/$GROUP_NAME.conf" | uniq > "$TMP"
        mv -f "$TMP" "$PATH_DIRECTORY/group/$GROUP_NAME.conf"
        print_notification 1 "Removed duplicated servers in group '$GROUP_NAME', this group now contains the following servers: $(paste -d' ' -s "$PATH_DIRECTORY/group/$GROUP_NAME.conf")"
    fi
    if [[ ! -s "$PATH_DIRECTORY/group/$GROUP_NAME.conf" ]]; then
        print_notification 3 "There is no available servers in group '$GROUP_NAME'. Deleting it..."
        rm -f "$PATH_DIRECTORY/group/$GROUP_NAME.conf"
        return 1
    else
        return 0
    fi
} # check_validate_group [group] [no validating servers]
check_diagnose_server() {
    print_draw_line —
    print_center "Problem Diagnosis for Server '$SERVER_NAME'"
    print_draw_line —
    if [[ -z "$1" || "$1" = 0 ]]; then
        print_center 'Host Connection Diagnosis' - -
        check_validate_host "$ACCOUNT_HOST"
        if [[ $? != 0 ]]; then
            print_draw_line —
            return 1
        fi
    fi
    if [[ -z "$2" || "$2" = 0 ]]; then
        print_center 'SSH Port Diagnosis' - -
        check_validate_port "$ACCOUNT_PORT" "$ACCOUNT_HOST"
        if [[ $? != 0 ]]; then
            print_draw_line —
            return 2
        fi
    fi
    if [[ -z "$3" || "$3" = 0 ]]; then
        print_center 'SSH Account Diagnosis' - -
        check_validate_account '' 1 1
        if [[ $? != 0 ]]; then
            print_draw_line —
            return 3
        fi
    fi
    if [[ -z "$4" || "$4" = 0 ]]; then
        print_center 'Server File and Configuration Diagnosis' - -
        check_validate_server '' 1
        if [[ $? != 0 ]]; then
            print_draw_line —
            return 4
        fi
    fi
    print_draw_line —
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
    ssh $ACCOUNT_HOST -oBatchmode=yes -p $ACCOUNT_PORT -l $ACCOUNT_USER -i "$ACCOUNT_KEY" $ACCOUNT_ARGUMENT_SSH "screen -ls | grep '.$SERVER_SCREEN'" 1>/dev/null 2>&1
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
    local ACCOUNT_ARGUMENT_SSH
    config_read_account "$2"
    ssh $ACCOUNT_HOST -oBatchmode=yes -p $ACCOUNT_PORT -l $ACCOUNT_USER -i "$ACCOUNT_KEY" $ACCOUNT_ARGUMENT_SSH "screen -ls $1" 1>/dev/null 2>&1
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
    M7CM_FORCE_STOP='0'
    M7CM_CONFIRM_START='1'
    M7CM_CONFIRM_STOP='1'
    M7CM_CONFIRM_INTERVAL='3'
    M7CM_RETRY_START='1'
    M7CM_RETRY_STOP='1'
    M7CM_ASYNC='0'
    M7CM_DETAILED_SERVER_LIST='0'
    M7CM_SKIP_ENVIRONMENT_CHECK='0'
    M7CM_HIDE_KEY_PATH='1'
    M7CM_AGREE_EULA='0'
    if [[ -f "$PATH_DIRECTORY/config.conf" ]]; then
        local IFS="="
        local OPTION
        local VALUE
        while read -r OPTION VALUE; do
            case "$OPTION" in
                DEFAULT_SERVER_JAR|DEFAULT_SSH_HOST|DEFAULT_SSH_USER|METHOD_DOWNLOAD|METHOD_PORT_DIAGNOSIS|METHOD_PUSH_PULL)
                    if [[ "$VALUE" =~ [/\^\/\@\%\(\)\#\\\$\`\"\'\!\&\*\:\;\,\ ] ]]; then
                        print_notification 2 "Illegal character found in option '$OPTION', the following characters can not be a part of this option: ^/@%()#\\$\`\"'!&*:;,"
                        local TMP=$(echo M7CM_$OPTION)
                        print_notification 1 "Defaulting option '$OPTION' to '$TMP'"
                    else
                        eval M7CM_$OPTION="$VALUE"
                    fi
                    ;;
                DEFAULT_SERVER_PORT)
                    if [[ "$VALUE" =~ ^[0-9]+$ ]] && [[ $VALUE -ge 0 && $VALUE -le 65535 ]]; then
                        M7CM_DEFAULT_SERVER_PORT=$VALUE
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
                    local REGEX='^https?://[-A-Za-z0-9\+&@#/%?=~_|!:,.;]*[-A-Za-z0-9\+&@#/%=~_|]$'
                    if [[ -z "$VALUE" || "$VALUE" =~ $REGEX ]]; then
                        M7CM_DOWNLOAD_PROXY_HTTP="$VALUE"
                    else
                        print_notification 2 "Illegal http proxy '$VALUE', http proxy will not be used"
                    fi
                    ;;
                DOWNLOAD_PROXY_HTTPS)
                    local REGEX='^https?://[-A-Za-z0-9\+&@#/%?=~_|!:,.;]*[-A-Za-z0-9\+&@#/%=~_|]$'
                    if [[ -z "$VALUE" || "$VALUE" =~ $REGEX ]]; then
                        M7CM_DOWNLOAD_PROXY_HTTPS="$VALUE"
                    else
                        print_notification 2 "Illegal http proxy '$VALUE', https proxy will not be used"
                    fi
                    ;;
                FORCE_STOP)
                    if [[ "$VALUE" =~ ^[01]$ ]]; then
                        M7CM_FORCE_STOP=$VALUE
                    else
                        print_notification 2 "Illegal value for whether M7CM should force-stop a server if failed to stop if using the console command, defaulting it to 0. Accept:0/1"
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
                ASYNC)
                    if [[ "$VALUE" =~ ^[01]$ ]]; then
                        M7CM_ASYNC=$VALUE
                    else
                        print_notification 2 "Illegal value for whether M7CM should perform async server management, defaulting it to 0. Accept: 0/1"
                    fi
                    ;;
                CONFIRM_INTERVAL)
                    if [[ "$VALUE" =~ ^[1-9][0-9]*$ ]]; then
                        M7CM_CONFIRM_INTERVAL=$VALUE
                    else
                        print_notification 2 "Illegal value for the interval between the start/stop operation and confirmation, defaulting it to 3. Accept:interger"
                    fi
                    ;;
                RETRY_START)
                    if [[ "$VALUE" =~ ^[01]$ ]]; then
                        M7CM_RETRY_START=$VALUE
                    else
                        print_notification 2 "Illegal value for whether M7CM should retry to start a server if failed, defaulting it to 1. Accept:0/1"
                    fi
                    ;;
                RETRY_STOP)
                    if [[ "$VALUE" =~ ^[01]$ ]]; then
                        M7CM_RETRY_STOP=$VALUE
                    else
                        print_notification 2 "Illegal value for whether M7CM should retry to stop a server if failed, defaulting it to 1. Accept:0/1"
                    fi
                    ;;
                DETAILED_SERVER_LIST)
                    if [[ "$VALUE" =~ ^[01]$ ]]; then
                        M7CM_DETAILED_SERVER_LIST=$VALUE
                    else
                        print_notification 2 "Illegal value for whether M7CM should display detailed server information in server list, defaulting it to 0. Accept:0/1"
                    fi
                    ;;
                SKIP_ENVIRONMENT_CHECK)
                    if [[ "$VALUE" =~ ^[01]$ ]]; then
                        M7CM_SKIP_ENVIRONMENT_CHECK=$VALUE
                    else
                        print_notification 2 "Illegal value for whether M7CM should skip startup check, defaulting it to 0. Accept:0/1"
                    fi
                    ;;
                HIDE_KEY_PATH)
                    if [[ "$VALUE" =~ ^[01]$ ]]; then
                        M7CM_HIDE_KEY_PATH=$VALUE
                    else
                        print_notification 2 "Illegal value for whether M7CM should hide private key path, defaulting it to 1. Accept:0/1"
                    fi
                    ;;
                AGREE_EULA)
                    if [[ "$VALUE" =~ ^[01]$ ]]; then
                        M7CM_AGREE_EULA=$VALUE
                    else
                        print_notification 2 "Illegal value for whether you agree to Minecraft EULA, defaulting it to 0. Accept:0/1"
                    fi
                    ;;
                
                *)
                    if [[ ! -z "$VALUE" ]]; then
                        print_notification 1 "Omitted redundant option '$OPTION' in M7CM configuration file"
                    fi
                    ;;
            esac
        done < "$PATH_DIRECTORY/config.conf"
        #IFS=$' \t\n'
        return 0
    else
        print_notification 2 "Configuration file for M7CM not found, all configuration set to default"
        return 1
    fi
}
config_read_environment() {
    if [[ ! -r "$PATH_DIRECTORY/environment.conf" ]]; then
        print_notification 4 "Environment configuration file not readable"
    fi
    ENV_LOCAL_SSH=0
    ENV_LOCAL_SCREEN=0

    ENV_LOCAL_SCP=0
    ENV_LOCAL_SFTP=0
    ENV_LOCAL_RSYNC=0

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
    local OPTION
    local VALUE
    while read -r OPTION VALUE; do
        case "$OPTION" in
            SSH|SCREEN|SCP|SFTP|RSYNC|TIMEOUT|NCAT|NMAP|WGET|CURL|JRE|GIT)
                if [[ "$VALUE" =~ ^[10]$ ]]; then
                    eval ENV_LOCAL_$OPTION=$VALUE
                else
                    print_notification 2 "Illegal value '$VALUE' for whether '$OPTION' exists in local environmen, defualting it to '0', accept: 0/1"
                    eval ENV_LOCAL_$OPTION=0
                fi
                ;;
            *)
                if [[ ! -z "$VALUE" ]]; then
                    print_notification 1 "Omitted redundant option '$OPTION' in environment configuration file"
                fi
                ;;
        esac
    done < "$PATH_DIRECTORY/environment.conf"
    IFS=$' \t\n'
    if [[ $ENV_LOCAL_TIMEOUT = 1 || $ENV_LOCAL_NCAT = 1 || $ENV_LOCAL_NMAP = 1 || $ENV_LOCAL_WGET = 1 ]]; then
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
    if [[ "$1" ]]; then
        JAR_NAME="$1"
        utility_jar_name_fix
    fi
    if [[ ! -f "$PATH_DIRECTORY/jar/$JAR_NAME.jar" ]]; then
        print_notification 3 "Jar '$JAR_NAME' does not exist, import or build it first."
        return 1
    elif [[ ! -r "$PATH_DIRECTORY/jar/$JAR_NAME.jar" ]]; then
        print_notification 3 "Jar '$JAR_NAME' is not readable, check your permission."
        return 2
    elif [[ ! -f "$PATH_DIRECTORY/jar/$JAR_NAME.conf" ]]; then
        print_notification 3 "Configuration file for jar '$JAR_NAME' not found. You need to configure it first"
        print_notification 0 "Use '$PATH_SCRIPT jar config $JAR_NAME' to configure it."
        return 3
    elif [[ ! -r "$PATH_DIRECTORY/jar/$JAR_NAME.conf" ]]; then
        print_notification 3 "Configuration file for jar '$JAR_NAME' not readable, check your permission."
        return 4
    fi
    JAR_TAG=''
    JAR_TYPE=''
    JAR_VERSION=''
    JAR_VERSION_MC=''
    JAR_PROXY=0
    JAR_BUILDTOOL=0
    local IFS="="
    local OPTION
    local VALUE
    while read -r OPTION VALUE; do
        case "$OPTION" in
            TAG|TYPE|VERSION|VERSION_MC)
                eval JAR_$OPTION="\"$VALUE\""
                ;;
            PROXY|BUILDTOOL)
                if [[ "$VALUE" =~ ^[10]$ ]]; then
                    eval JAR_$OPTION=$VALUE
                else
                    print_notification 2 "Illegal value '$VALUE' for jar option '$OPTION', defaulting it to 0, accept: 0/1"
                    eval JAR_$OPTION=0
                fi
                ;;
            *)
                if [[ ! -z "$VALUE" ]]; then
                    print_notification 1 "Omitted redundant option '$OPTION' for jar '$JAR_NAME'"
                fi
                ;;
        esac
    done < "$PATH_DIRECTORY/jar/$JAR_NAME.conf"
    IFS=$' \t\n'
    return 0
} ## Safely read jar info, ignore redundant values
config_read_account() {
    if [[ "$1" ]]; then
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
    ACCOUNT_HOST="$M7CM_DEFAULT_SSH_HOST"
    ACCOUNT_PORT="$M7CM_DEFAULT_SSH_PORT"
    ACCOUNT_USER="$M7CM_DEFAULT_SSH_USER"
    ACCOUNT_KEY=''
    ACCOUNT_ARGUMENT_SSH=''
    ACCOUNT_ARGUMENT_RSYNC=''
    local IFS="="
    local OPTION
    local VALUE
    while read -r OPTION VALUE; do
        case "$OPTION" in
            TAG|ARGUMENT_SSH|ARGUMENT_RSYNC)
                eval ACCOUNT_$OPTION="\"$VALUE\""
                ;;
            KEY)
                if [[ -z "$VALUE" ]]; then
                    print_notification 3 "Illegal account '$ACCOUNT_NAME': 'KEY' can not be empty."
                    return 3
                else
                    ACCOUNT_KEY="$VALUE"
                fi
                ;;
            HOST|PORT|USER)
                if [[ -z "$VALUE" ]]; then
                    eval local TMP=\$ACCOUNT_$OPTION
                    print_notification 2 "'$OPTION' is empty in account '$ACCOUNT_NAME', defaulting it to '$TMP'"
                else
                    eval ACCOUNT_$OPTION="$VALUE"
                fi
                ;;
            PORT)
                if [[ "$VALUE" =~ ^[0-9]+$ ]] && [[ $VALUE -ge 0 && $VALUE -le 65535 ]]; then
                    ACCOUNT_PORT=$VALUE
                else
                    print_notification 2 "Illegal value for ssh port in account '$ACCOUNT_NAME', defaulting it to '$M7CM_DEFAULT_SSH_PORT', Accept: interger 0-65535"
                fi
                ;;
            *)
                if [[ ! -z "$VALUE" ]]; then
                    print_notification 1 "Omitted redundant option '$OPTION' for account '$ACCOUNT_NAME'"
                fi
            ;;
        esac
    done < "$PATH_DIRECTORY/account/$ACCOUNT_NAME.conf"
    IFS=$' \t\n'
    return 0
} ## Safely read account config, ignore redundant values
config_read_server() {
    if [[ "$1" ]]; then
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
    SERVER_ARGUMENT_JAVA=''
    SERVER_ARGUMENT_JAR=''
    SERVER_SCREEN=''
    SERVER_COMMAND_STOP='stop'
    local OPTION
    local VALUE
    local IFS="="
    while read -r OPTION VALUE; do
        if [[ -z "$VALUE" && "$OPTION" =~ ^(ACCOUNT|SCREEN)$ ]]; then
            print_notification 3 "Illegal server '$SERVER_NAME': either account or screen is empty."
            return 3
        fi
        case "$OPTION" in
            TAG|ARGUMENT_JAVA|ARGUMENT_JAR)
                eval SERVER_$OPTION=\""$VALUE"\"
                ;;
            ACCOUNT|SCREEN)
                if [[ -z "$VALUE" ]]; then
                    print_notification 3 "Illegal server '$SERVER_NAME': '$OPTION' can not be empty."
                    return 3
                else
                    eval SERVER_$OPTION="\"$VALUE\""
                fi
                ;;
            PORT)
                if [[ "$VALUE" =~ ^[0-9]+$ ]] && [[ $VALUE -ge 0 && $VALUE -le 65535 ]]; then
                    SERVER_PORT=$VALUE
                else
                    print_notification 2 "Illegal value for server port in server '$SERVER_NAME', defaulting it to '$M7CM_DEFAULT_SERVER_PORT', Accept: interger 0-65535"
                fi
                ;;
            RAM_MAX|RAM_MIN)
                VALUE=$(tr '[mg]' '[MG]' <<< "$VALUE")
                if [[ "$VALUE" =~ ^[1-9][0-9]*[MG]$ ]] ; then
                    eval SERVER_$OPTION=$VALUE
                else
                    print_notification 2 "Illegal value for '$OPTION', defaulting it to '1G', Accept: interger+M/G, e.g. 2048M, 3G"
                fi
                ;;
            DIRECTORY|JAR|COMMAND_STOP)
                if [[ -z "$VALUE" ]]; then
                    eval local TMP=SERVER_$OPTION
                    print_notification 2 "'$OPTION' is empty in server '$SERVER_NAME', defaulting it to '$TMP'"
                else
                    eval SERVER_$OPTION="\"$VALUE\""
                fi
                ;;
            COMMAND_STOP)
                if [[ -z "$VALUE" ]]; then
                    print_notification 2 "'COMMAND_STOP' is empty in server '$SERVER_NAME', defaulting it to 'stop'"
                # elif [[ "$VALUE" =~ (^|[^\\])\^ ]]; then
                #     print_notification 2 "'COMMAND_STOP' can not contain '^' without a prefix '\', defaulting it to 'stop'"
                else
                    SERVER_COMMAND_STOP="$VALUE"
                fi
                ;; 
            *)
                if [[ ! -z "$VALUE" ]]; then
                    print_notification 1 "Omitted redundant option '$OPTION' for server '$SERVER_NAME'"
                fi
                ;;
        esac
    done < $PATH_DIRECTORY/server/$SERVER_NAME.conf
    IFS=$' \t\n'
    check_validate_ram
    return 0
}
config_read_server_and_account() {
    if [[ "$1" ]]; then
        SERVER_NAME="$1"
    fi
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
    print_notification 1 "Proceeding to write M7CM configuration to file 'config.conf'"
    echo "## Configuration for M7CM, generated at `date +"%Y-%m-%d-%H-%M"`" > "$PATH_DIRECTORY/config.conf"
    echo "DEFAULT_SERVER_JAR=$M7CM_DEFAULT_SERVER_JAR" >> "$PATH_DIRECTORY/config.conf"
    echo "DEFAULT_SERVER_PORT=$M7CM_DEFAULT_SERVER_PORT" >> "$PATH_DIRECTORY/config.conf"
    echo "DEFAULT_SSH_HOST=$M7CM_DEFAULT_SSH_HOST" >> "$PATH_DIRECTORY/config.conf"
    echo "DEFAULT_SSH_USER=$M7CM_DEFAULT_SSH_USER" >> "$PATH_DIRECTORY/config.conf"
    echo "DEFAULT_SSH_PORT=$M7CM_DEFAULT_SSH_PORT" >> "$PATH_DIRECTORY/config.conf"
    echo "## Available download methods: wget, curl" >> "$PATH_DIRECTORY/config.conf"
    echo "METHOD_DOWNLOAD=$M7CM_METHOD_DOWNLOAD" >> "$PATH_DIRECTORY/config.conf"
    echo "## Available port diagnosis methods: timeout, ncat, nmap, wget" >> "$PATH_DIRECTORY/config.conf"
    echo "METHOD_PORT_DIAGNOSIS=$M7CM_METHOD_PORT_DIAGNOSIS" >> "$PATH_DIRECTORY/config.conf"
    echo "## Available push and pull methods: scp, sftp, rsync" >> "$PATH_DIRECTORY/config.conf"
    echo "METHOD_PUSH_PULL=$M7CM_METHOD_PUSH_PULL" >> "$PATH_DIRECTORY/config.conf"
    echo "DOWNLOAD_PROXY_HTTP=$M7CM_DOWNLOAD_PROXY_HTTP" >> "$PATH_DIRECTORY/config.conf"
    echo "DOWNLOAD_PROXY_HTTPS=$M7CM_DOWNLOAD_PROXY_HTTPS" >> "$PATH_DIRECTORY/config.conf"
    echo "## Whether we should send signal 9 to the server if failed to stop it using console command. This may lead to losing of save data if your server is very slow (since it's immediately killed). If your server is just slow saving players' date, then I suggest you increase the CONFIRM_INTERVAL instead of force stop it." >> "$PATH_DIRECTORY/config.conf"
    echo "FORCE_STOP=$M7CM_FORCE_STOP" >> "$PATH_DIRECTORY/config.conf"
    echo "## Whether M7CM should confirm a server is started. If set to 0, M7CM will consider a server is successful started so long as the start command is successfully sent. If set to 1, M7CM will try to confirm the server's status after 3 seconds(or other interval you've set in CONFIRM_INTERVAL), even the startup command is successfully sent. If all your servers work fine, and you think 3 seconds per server is a waste of time, you can set it to 0." >> "$PATH_DIRECTORY/config.conf"
    echo "CONFIRM_START=$M7CM_CONFIRM_START" >> "$PATH_DIRECTORY/config.conf"
    echo "## Whether M7CM should confirm a server is stopped. Similar to CONFIRM_STOP" >> "$PATH_DIRECTORY/config.conf"
    echo "CONFIRM_STOP=$M7CM_CONFIRM_STOP" >> "$PATH_DIRECTORY/config.conf"
    echo "## Interval between the start/stop operation and the confirmation. If your device is very slow, you may increase this. If your device is fast as blitz, you may decrease this. Unless you are very confident about your super fast server, DO NOT change this to 0" >> "$PATH_DIRECTORY/config.conf"
    echo "CONFIRM_INTERVAL=$M7CM_CONFIRM_INTERVAL" >> "$PATH_DIRECTORY/config.conf"
    echo "## Whether M7CM should retry to start the server if failed to. If so, M7CM will retry for 3 times, with intervals increasing by 3 seconds(or other value you've set in CONFIRM_INTERVAL) per try. This only works if 'CONFIRM_START' is set to 1" >> "$PATH_DIRECTORY/config.conf"
    echo "RETRY_START=$M7CM_RETRY_START" >> "$PATH_DIRECTORY/config.conf"
    echo "## Whether M7CM should retry to stop the server if failed to. Similar to RETRT_START" >> "$PATH_DIRECTORY/config.conf"
    echo "RETRY_STOP=$M7CM_RETRY_STOP" >> "$PATH_DIRECTORY/config.conf"
    echo "## Whether M7CM should using async method for multi-server/multi-group operations. In that case, all operations will be performed simultaneously in background. This may lead to a hell of mess on your terminal. Only the following actions accept async method: jar push, server start/stop/restart, group start/stop/restart/push" >> "$PATH_DIRECTORY/config.conf"
    echo "ASYNC=$M7CM_ASYNC" >> "$PATH_DIRECTORY/config.conf"
    echo "## Whether M7CM should print detailed server information in server list. If set to 0, only print server name, server account, and its status. Notice that you can always check the detailed information if you only check the information for one server." >> "$PATH_DIRECTORY/config.conf"
    echo "DETAILED_SERVER_LIST=$M7CM_DETAILED_SERVER_LIST" >> "$PATH_DIRECTORY/config.conf"
    echo "## Whether M7CM should skip environment check when startup. set to 1 if you think startup check is laggy" >> "$PATH_DIRECTORY/config.conf"
    echo "SKIP_ENVIRONMENT_CHECK=$M7CM_SKIP_ENVIRONMENT_CHECK" >> "$PATH_DIRECTORY/config.conf"
    echo "## Whether M7CM should hide private key path. set to 0 if you are the only one who have access to the user running M7CM" >> "$PATH_DIRECTORY/config.conf"
    echo "HIDE_KEY_PATH=$M7CM_HIDE_KEY_PATH" >> "$PATH_DIRECTORY/config.conf"
    echo "## Whether you agree to Minecraft EULA. set to 1 to agree. For more info, go to https://account.mojang.com/documents/minecraft_eula" >> "$PATH_DIRECTORY/config.conf"
    echo "AGREE_EULA=$M7CM_AGREE_EULA" >> "$PATH_DIRECTORY/config.conf"
    print_notification 1 "Successfully generated configuration file 'config.conf'"
    return 0
}
config_write_environment() {
    print_notification 1 "Proceeding to write detected environment status to config file 'environment.conf'"
    echo "## Configuration for local environment, generated by M7CM at `date +"%Y-%m-%d-%H-%M"`. This file is generated because you've set" > "$PATH_DIRECTORY/environment.conf"
    echo "## enabled 'SKIP_STARTUP_CHECK' in config.conf. In this case, M7CM reads this file to get environment status instead of checking it every time." >> "$PATH_DIRECTORY/environment.conf"
    echo "SSH=$ENV_LOCAL_SSH" >> "$PATH_DIRECTORY/environment.conf"
    echo "SCREEN=$ENV_LOCAL_SCREEN" >> "$PATH_DIRECTORY/environment.conf"
    echo "SCP=$ENV_LOCAL_SCP" >> "$PATH_DIRECTORY/environment.conf"
    echo "SFTP=$ENV_LOCAL_SFTP" >> "$PATH_DIRECTORY/environment.conf"
    echo "RSYNC=$ENV_LOCAL_RSYNC" >> "$PATH_DIRECTORY/environment.conf"
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
    if [[ "$1" ]]; then
        local JAR_NAME="$1"
        utility_jar_name_fix
    fi
    if [[ -f "$PATH_DIRECTORY/jar/$JAR_NAME.conf" && ! -w "$PATH_DIRECTORY/jar/$JAR_NAME.conf" ]]; then
        print_notification 3 "Can not write to configuration file '$JAR_NAME.conf' due to lacking of writing permission. Check your permission"
        return 1
    else
        print_notification 1 "Proceeding to write values to config file....'$JAR_NAME.conf'"
        echo "## Configuration for jar file '$JAR_NAME', DO NOT EDIT THIS UNLESS YOU KNOW WHAT YOU ARE DOING" > "$PATH_DIRECTORY/jar/$JAR_NAME.conf"
        echo "TAG=$JAR_TAG" >> "$PATH_DIRECTORY/jar/$JAR_NAME.conf"
        echo "TYPE=$JAR_TYPE" >> "$PATH_DIRECTORY/jar/$JAR_NAME.conf"
        echo "BUILDTOOL=$JAR_BUILDTOOL" >> "$PATH_DIRECTORY/jar/$JAR_NAME.conf"
        echo "PROXY=$JAR_PROXY" >> "$PATH_DIRECTORY/jar/$JAR_NAME.conf"
        echo "VERSION=$JAR_VERSION" >> "$PATH_DIRECTORY/jar/$JAR_NAME.conf"
        echo "VERSION_MC=$JAR_VERSION_MC" >> "$PATH_DIRECTORY/jar/$JAR_NAME.conf"
        print_notification 0 "Successfully written values to jar config file $JAR_NAME.conf"
        return 0
    fi
}
config_write_account() {
    if [[ "$1" ]]; then
        local ACCOUNT_NAME="$1"
    fi
    if [[ -f "$PATH_DIRECTORY/account/$ACCOUNT_NAME.conf" && ! -w "$PATH_DIRECTORY/account/$ACCOUNT_NAME.conf" ]]; then
        print_notification 3 "Can not write to configuration file '$ACCOUNT_NAME.conf' due to lacking of writing permission. Check your permission"
        return 1
    else
        print_notification 1 "Proceeding to write values to config file '$ACCOUNT_NAME.conf'...."
        echo "## Configuration for account '$ACCOUNT_NAME', DO NOT EDIT THIS UNLESS YOU KNOW WHAT YOU ARE DOING" > "$PATH_DIRECTORY/account/$ACCOUNT_NAME.conf"
        echo "TAG=$ACCOUNT_TAG" >> "$PATH_DIRECTORY/account/$ACCOUNT_NAME.conf"
        echo "HOST=$ACCOUNT_HOST" >> "$PATH_DIRECTORY/account/$ACCOUNT_NAME.conf"
        echo "PORT=$ACCOUNT_PORT" >> "$PATH_DIRECTORY/account/$ACCOUNT_NAME.conf"
        echo "USER=$ACCOUNT_USER" >> "$PATH_DIRECTORY/account/$ACCOUNT_NAME.conf"
        echo "KEY=$ACCOUNT_KEY" >> "$PATH_DIRECTORY/account/$ACCOUNT_NAME.conf"
        echo "ARGUMENT_SSH=$ACCOUNT_ARGUMENT_SSH" >> "$PATH_DIRECTORY/account/$ACCOUNT_NAME.conf"
        echo "ARGUMENT_RSYNC=$ACCOUNT_ARGUMENT_RSYNC" >> "$PATH_DIRECTORY/account/$ACCOUNT_NAME.conf"
        print_notification 0 "Successfully written values to account config file '$ACCOUNT_NAME.conf'"
        return 0
    fi
}
config_write_server() {
    if [[ "$1" ]]; then
        local SERVER_NAME="$1"
    fi
    if [[ -f "$PATH_DIRECTORY/server/$SERVER_NAME.conf" && ! -w "$PATH_DIRECTORY/server/$SERVER_NAME.conf" ]]; then
        print_notification 3 "Can not write to configuration file '$SERVER_NAME.conf' due to lacking of writing permission. Check your permission."
        return 1
    else
        print_notification 1 "Proceeding to write values to config file '$SERVER_NAME.conf'...."
        echo "## Configuration for server '$SERVER_NAME', DO NOT EDIT THIS UNLESS YOU KNOW WHAT YOU ARE DOING" > "$PATH_DIRECTORY/server/$SERVER_NAME.conf"
        echo "TAG=$SERVER_TAG" >> "$PATH_DIRECTORY/server/$SERVER_NAME.conf"
        echo "ACCOUNT=$SERVER_ACCOUNT" >> "$PATH_DIRECTORY/server/$SERVER_NAME.conf"
        echo "DIRECTORY=$SERVER_DIRECTORY" >> "$PATH_DIRECTORY/server/$SERVER_NAME.conf"
        echo "PORT=$SERVER_PORT" >> "$PATH_DIRECTORY/server/$SERVER_NAME.conf"
        echo "RAM_MAX=$SERVER_RAM_MAX" >> "$PATH_DIRECTORY/server/$SERVER_NAME.conf"
        echo "RAM_MIN=$SERVER_RAM_MIN" >> "$PATH_DIRECTORY/server/$SERVER_NAME.conf"
        echo "JAR=$SERVER_JAR" >> "$PATH_DIRECTORY/server/$SERVER_NAME.conf"
        echo "ARGUMENT_JAVA=$SERVER_ARGUMENT_JAVA" >> "$PATH_DIRECTORY/server/$SERVER_NAME.conf"
        echo "ARGUMENT_JAR=$SERVER_ARGUMENT_JAR" >> "$PATH_DIRECTORY/server/$SERVER_NAME.conf"
        echo "SCREEN=$SERVER_SCREEN" >> "$PATH_DIRECTORY/server/$SERVER_NAME.conf"
        echo "COMMAND_STOP=$SERVER_COMMAND_STOP" >> "$PATH_DIRECTORY/server/$SERVER_NAME.conf"
        print_notification 0 "Successfully written values to server config file '$ACCOUNT_NAME.conf'"
        return 0
    fi
}
assignment_jar() {
    local OPTION
    local VALUE
    local CHANGE
    if [[ $# = 1 ]]; then
        local IFS=' ='
        read -r OPTION VALUE <<< "$1"
        OPTION=$(tr '[a-z]' '[A-Z]' <<< "$OPTION")
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
    else
        while [[ $# -gt 0 ]]; do
            assignment_jar "$1"
            shift
        done
    fi
    return 0
} ## Usage: assignment_jar [option1=value1]   [option2=value2]
assignment_account() {
    local OPTION
    local VALUE
    local CHANGE
    if [[ $# = 1 ]]; then
        local IFS=' ='
        read -r OPTION VALUE <<< "$1"
        OPTION=$(tr '[a-z]' '[A-Z]' <<< "$OPTION")
        IFS=$' \t\n'
        case "$OPTION" in
            TAG|ARGUMENT_SSH|ARGUMENT_RSYNC)
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
                elif [[ -f "$PATH_DIRECTORY/account/$VALUE.conf" ]]; then
                    interactive_yn N "An account with the same name '$VALUE' has already exist, are you sure you want to overwrite it?"
                    if [[ $? = 1 ]]; then
                        return 5
                    fi
                fi
                ls $PATH_DIRECTORY/server/*.conf 1>/dev/null 2>&1
                if [[ $? = 0 ]]; then
                    local TMP
                    for TMP in $PATH_DIRECTORY/server/*.conf; do
                        grep -Fxq "ACCOUNT=$ACCOUNT_NAME" "$TMP" 1>/dev/null 2>&1
                        if [[ $? = 0 ]]; then
                            local SERVER_NAME=$(basename $TMP)
                            SERVER_NAME=${SERVER_NAME:0:-5}
                            print_notification 1 "Account '$ACCOUNT_NAME' is used in server '$SERVER_NAME' now, updating 'ACCOUNT=$ACCOUNT_NAME' to new account name '$VALUE'"
                            sed -i "/^ACCOUNT=$ACCOUNT_NAME$/cACCOUNT=$VALUE" "$TMP"
                        fi
                    done
                fi
                mv -f "$PATH_DIRECTORY/account/$ACCOUNT_NAME.conf" "$PATH_DIRECTORY/account/$VALUE.conf" 1>/dev/null 2>&1
                ACCOUNT_NAME="$VALUE"
                print_notification 0 "'NAME' set to '$VALUE'"
                ;;
            *)
                print_notification 1 "'$OPTION' is not an available option, ignored"
                ;;
        esac
    else
        while [[ $# -gt 0 ]]; do
            assignment_account "$1"
            shift
        done
    fi
    return 0
} ##
assignment_server() {
    local OPTION
    local VALUE
    if [[ $# = 1 ]]; then
        local IFS=' ='
        read -r OPTION VALUE <<< "$1"
        OPTION=$(tr '[a-z]' '[A-Z]' <<< "$OPTION")
        local IFS=$' \t\n'
        case "$OPTION" in
            TAG|ARGUMENT_JAVA|ARGUMENT_JAR)
                eval SERVER_$OPTION="\"$VALUE\""
                print_notification 1 "'$OPTION' is set to '$VALUE'"
                ;;
            PORT)
                local REGEX='^[0-9]+$'
                if [[ "$VALUE" =~ $REGEX ]] && [[ "$VALUE" -ge 0 && "$VALUE" -le 65535 ]]; then
                    SERVER_PORT="$VALUE"
                    print_notification 0 "'PORT' set to '$VALUE'"
                elif [[ -z "$VALUE" ]]; then
                    print_notification 2 "No port specified, using default value '$M7CM_DEFAULT_SERVER_PORT' as [port]"
                    SERVER_PORT="$M7CM_DEFAULT_SERVER_PORT"
                else
                    print_notification 2 "'$VALUE' is not a valid port, using default value '$M7CM_DEFAULT_SERVER_PORT' as [port]"
                    SERVER_PORT="$M7CM_DEFAULT_SERVER_PORT"
                fi
                ;;
            COMMAND_STOP)
                if [[ -z "$VALUE" ]]; then
                    SERVER_COMMAND_STOP='stop'
                    print_notification 2 "'COMMAND_STOP' is empty, defaulting it to 'stop'"
                # elif [[ "$VALUE" =~ (^|[^\\])\^ ]]; then
                #     SERVER_COMMAND_STOP='stop'
                #     print_notification 2 "'COMMAND_STOP' can not contain '^' without a prefix '\', defaulting it to 'stop'"
                else
                    SERVER_COMMAND_STOP="$VALUE"
                    print_notification 1 "'COMMAND_STOP' is set to '$VALUE'"
                fi
                ;;
            DIRECTORY)
                if [[ -z "$VALUE" ]]; then
                    SERVER_DIRECTORY='~'
                    print_notification 2 "'DIRECTORY' is empty, defaulting it to '~'"
                else
                    SERVER_DIRECTORY="$VALUE"
                    print_notification 1 "'DIRECTORY' is set to '$VALUE'"
                fi
                ;;
            JAR)
                if [[ -z "$VALUE" ]]; then
                    SERVER_JAR="$M7CM_DEFAULT_SERVER_JAR"
                    print_notification 2 "'JAR' is empty, defaulting to '$M7CM_DEFAULT_SERVER_JAR'"
                else
                    SERVER_JAR="$VALUE"
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
                local VALIDATE_RAM=1
                VALUE=$(tr '[mg]' '[MG]' <<< "$VALUE")
                if [[ "$VALUE" =~ ^[1-9][0-9]*[MG]$ ]] ; then
                    eval SERVER_$OPTION=$VALUE
                else
                    print_notification 2 "Illegal value for '$OPTION', defaulting it to '1G', Accept: interger+M/G, e.g. 2048M, 3G"
                    eval SERVER_$OPTION=1G
                fi
                ;;
            NAME)
                if [[ -z "$SERVER_NAME" ]]; then
                    print_notification 3 "Renaming aborted due to no server being selected"
                    return 2
                elif [[ -z "$VALUE" ]]; then
                    print_notification 3 "No new name assigned, 'NAME' kept not changed"
                    return 3
                elif [[ -f "$PATH_DIRECTORY/server/$VALUE.conf" ]]; then
                    if [[ ! -w "$PATH_DIRECTORY/server/$VALUE.conf" ]]; then
                        print_notification 3 "Renaming aborted. A server with the same name '$VALUE' has already exist and can't be overwriten due to lack of writing permission. Check your permission."
                        return 4
                    else
                        interactive_yn N "A server with the same name '$VALUE' has already exist, are you sure you want to overwrite it?"
                        if [[ $? = 1 ]]; then
                            return 5
                        fi
                    fi
                fi
                ls $PATH_DIRECTORY/group/*.conf 1>/dev/null 2>&1
                if [[ $? = 0 ]]; then   
                    local TMP
                    for TMP in $PATH_DIRECTORY/group/*.conf; do
                        grep -Fxq "$SERVER_NAME" "$TMP" 1>/dev/null 2>&1
                        if [[ $? = 0 ]]; then
                            local GROUP_NAME=$(basename $TMP)
                            GROUP_NAME=${TMP:0:-5}
                            print_notification 1 "Server '$SERVER_NAME' is a member of group '$GROUP_NAME', updating '$SERVER_NAME' to new server name '$VALUE'"
                            sed -i "/^$VALUE$/d" "$TMP"
                            sed -i "/^$SERVER_NAME$/c$VALUE"
                            check_validate_group "$GROUP_NAME" 1
                        fi
                    done
                fi
                mv -f "$PATH_DIRECTORY/account/$SERVER_NAME.conf" "$PATH_DIRECTORY/account/$VALUE.conf" 1>/dev/null 2>&1
                SERVER_NAME="$VALUE"
                print_notification 0 "'NAME' set to '$VALUE'"
                ;;
            SCREEN)
                if [[ -z "$SERVER_NAME" ]]; then
                    print_notification 3 'No server is being selected, can not assign a screen name'
                    return 6
				elif  [[ -z "$SERVER_ACCOUNT" ]]; then
                    print_notification 3 'No account is being selected, can not assign a screen name'
                    return 7
                fi
                if [[ -z "$VALUE" ]]; then
                    print_notification 2 "'SCREEN' is empty, generating screen name..."
                    VALUE="M7CM-`date +%s%N`"
                    print_notification 1 "Generated screen name '$VALUE'"
                fi
                check_status_screen "$VALUE" "$SERVER_ACCOUNT"
                if [[ $? = 0 ]]; then
                    print_notification 3 "A screen with the same name '$VALUE' is already running using account '$SERVER_ACCOUNT', can not assign the screen name"
                    return 9
                fi
                ls $PATH_DIRECTORY/server/*.conf 1>/dev/null 2>&1
                if [[ $? = 0 ]]; then
                    local TMP
                    for TMP in $PATH_DIRECTORY/server/*.conf; do
                        if [[ "$TMP" != "$PATH_DIRECTORY/server/$SERVER_NAME.conf" ]]; then
                            grep -Fxq "SCREEN=$VALUE" "$TMP" 1>/dev/null 2>&1
                            if [[ $? = 0 ]]; then
                                local SERVER_DUPLICATE=$(basename $TMP)
                                SERVER_DUPLICATE=${TMP:0:-5}
                                grep -Fxq "ACCOUNT=$SERVER_ACCOUNT" "$TMP" 1>/dev/null 2>&1
                                if [[ $? = 0 ]]; then
                                    print_notification 3 "Another server '$SERVER_DUPLICATE' is using the same screen name '$VALUE' and the same account '$SERVER_ACCOUNT'. There must be no duplicated screen name using the same account."
                                    return 11
                                else
                                    print_notification 1 "The screen name '$VALUE' is already used in server '$SERVER_DUPLICATE'. But since the server '$SERVER_DUPLICATE' is using another account instead of '$SERVER_ACCOUNT', it should be safe to use the same screen name as it."
                                    print_notification 0 "It is still recommended not to use the same screen name as others"
                                    interactive_yn N "Do you insist on using this screen name?"
                                    if [[ $? = 1 ]]; then
                                        return 12
                                    fi
                                fi
                            fi
                        fi
                    done
                fi
                SERVER_SCREEN="$VALUE"
                print_notification 0 "'SCREEN' set to '$VALUE'"
                ;;
            *)
                print_notification 1 "'$OPTION' is not an available option, ignored"
                ;;
        esac
    else 
        while [[ $# -gt 0 ]]; do
            assignment_server "$1"
            shift
        done
    fi
    return 0
}
assignment_group() {
    local SERVER_NAME
    local GROUP_NAME="$1"
    if [[ $# = 2 ]]; then
        if [[ ${2:0:1} = - ]]; then # Remove server
            SERVER_NAME=${2#-}
            grep -Fxq "$SERVER_NAME" "$PATH_DIRECTORY/group/$GROUP_NAME.conf"
            if [[ $? = 0 ]]; then
                sed -i "/^$SERVER_NAME$/"d "$PATH_DIRECTORY/group/$GROUP_NAME.conf"
                print_notification 1 "Removed server '$SERVER_NAME' from group '$GROUP_NAME'"
            else
                print_notification 1 "Server '$SERVER_NAME' is not in group '$GROUP_NAME', no need to remove it"
            fi
        else # Add server
            SERVER_NAME=${2#+}
            if [[ -f "$PATH_DIRECTORY/server/$SERVER_NAME.conf" ]]; then
                grep -Fxq "^$SERVER_NAME$" "$PATH_DIRECTORY/group/$GROUP_NAME.conf"
                if [[ $? = 0 ]]; then
                    print_notification 1 "Server '$SERVER_NAME' is already in group '$GROUP_NAME', no need to add it."
                else
                    echo "$SERVER_NAME" >> "$PATH_DIRECTORY/group/$GROUP_NAME.conf"
                    print_notification 1 "Added server '$SERVER_NAME' to group '$GROUP_NAME'"
                fi
            else
                print_notification 3 "Server '$SERVER_NAME' does not exist, failed to add it"
            fi
        fi
    else
        while [[ $# -ge 2 ]]; do
            assignment_group "$GROUP_NAME" "$2"
            shift
        done
    fi
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
    local TMP="/tmp/M7CM-identifying-$JAR_NAME-`date +"%Y-%m-%d-%H-%M"`"
    mkdir "$TMP"
    print_notification 0 "Depending on the type of the jar, the performance of this host, and your network connection, it may take a few seconds or a few minutes to identify it. e.g. Paper pre-patch jar would download the vanilla jar and patch it"
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
            JAR_TYPE='Spigot'
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
# utility_backup_archive() {
#     ls $PATH_DIRECTORY/backup/*/ 1>/dev/null 2>&1
#     if [[ $? != 0 ]]; then
#         return 1
#     fi
#     local SERVER_NAME
#     for SERVER_NAME in $PATH_DIRECTORY/backup/*/; do



# }
## jar related
action_jar_import() {
    JAR_NAME="$1"
    utility_jar_name_fix
    if [[ -f "$PATH_DIRECTORY/jar/$JAR_NAME.jar" ]]; then
        interactive_yn N "A jar with the same name '$JAR_NAME' has already been defined. Should we overwrite it?"
        if [[ $? = 1 ]]; then
            return 1
        fi
        # if [[ $? = 0 ]]; then
        #     action_jar_remove "$JAR_NAME"
        #     if [[ $? != 0 ]]; then
        #         return 1 ## already exist and can not overwrite
        #     fi
        # else
        #     return 2 ## Aborted overwriting
        # fi
    fi
    if [[ -f "$2" ]]; then
        print_notification 1 "Importing from local file '$2'..."
        local TMP="${2: -4}"
        if [[ ! -r "$2" ]]; then
            print_notification 3 "No read permission for file $2, importing failed. check your permission"
            return 3 ## No read permission for local file
        elif [[ "${TMP,,}" != ".jar" ]]; then
            print_notification 1 "The file extension of this file is not .jar, maybe you've input a wrong file, but M7CM will try to import it anyway"
        fi
        \cp -f "$2" "$PATH_DIRECTORY/jar/$JAR_NAME.jar"
        if [[ $? != 0 ]]; then
            print_notification 3 "Failed to copy file $2, importing failed"
            return 4 ## failed to copy. wtf is that reason?
        else
            JAR_TAG="Imported at `date +"%Y-%m-%d-%H:%M"` from local source $2"
        fi
    else
        local REGEX='^(https?|ftp|file)://[-A-Za-z0-9\+&@#/%?=~_|!:,.;]*[-A-Za-z0-9\+&@#/%=~_|]$'
        if [[ "$2" =~ $REGEX ]]; then
            print_notification 1 "Importing jar '$JAR_NAME' from online url '$2'"
            if [[ "$ENV_METHOD_DOWNLOAD" = 0 ]]; then
                print_notification 3 'Can not import from online url due to lacking of download method: neither wget nor curl is detected'
                return 5
            fi
            if [[ "$M7CM_DOWNLOAD_PROXY_HTTP" ]]; then
                print_notification 1 "Using http proxy $M7CM_DOWNLOAD_PROXY_HTTP..."
                http_proxy="$M7CM_DOWNLOAD_PROXY_HTTP"
            fi
            if [[ "$M7CM_DOWNLOAD_PROXY_HTTPS" ]]; then
                print_notification 1 "Using https proxy $M7CM_DOWNLOAD_PROXY_HTTPS..."
                https_proxy="$M7CM_DOWNLOAD_PROXY_HTTPS"
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
                JAR_TAG="Imported at `date +"%Y-%m-%d-%H:%M"` from online source $2"
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
        print_multilayer_menu "TYPE: $JAR_TYPE" 'What kind of jar it is, e.g. Spigot, Paper, Vanilla. Only for identification.'
        print_multilayer_menu "PROXY: $JAR_PROXY" "If it contains a proxy server, e.g. Waterfall, Bungeecord. Currently this option does nothing. Accept: 0/1"
        print_multilayer_menu "BUILDTOOL: $JAR_BUILDTOOL" "Whether it contains Spigot buildtools. Must be 1 if you want to use it to build a jar. Accept: 0/1"
        print_multilayer_menu "VERSION: $JAR_VERSION" "The version of the jar itself. Only for identification."
        print_multilayer_menu "VERSION_MC: $JAR_VERSION_MC" "The version of Minecraft this jar can host. Only for identification." 1 1
        print_draw_line
        print_notification 0 "Type in the option you want to change and its new value split by =, e.g. 'TAG = This is my first jar!' (without quote and option is case insensitive, e.g. pRoXy). You can also type 'identify' to let M7CM auto-identify it, or 'confirm' or 'save' to save thost values:"
        read -e -p " >>> " COMMAND
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
        while [[ $# -gt 0 ]]; do
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
    print_draw_line
    print_center "Jar file list"
    print_draw_line
    ls $PATH_DIRECTORY/jar/*.jar 1>/dev/null 2>&1
    if [[ $? != 0 ]]; then
        print_notification 3 "You have not added any account yet. Use '$PATH_SCRIPT jar import/build/pull ...' to add a jar first"
        return 1
    fi
    local ORDER=1
    for JAR_NAME in $PATH_DIRECTORY/jar/*.jar; do
        JAR_NAME=$(basename $JAR_NAME)
        utility_jar_name_fix 1>/dev/null 2>&1
        print_multilayer_menu "$ORDER. $JAR_NAME" "" 0
        print_info_jar
        let ORDER++
    done
    return 0
} ## Usage: action_jar_list. NO ARGUMENTS. return: 0 success
action_jar_remove() {
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
        while [[ $# -gt 0 ]]; do
            action_jar_remove "$1"
            shift
        done
    fi
} ## Usage: action_jar_remove [jar name1] [jar name2]. return: 0 success, 1 not exist, 2 jar no writable, 3 conf not writable,
action_jar_build() {
    print_draw_line
    print_center "Spigot Auto-Building Function"
    print_draw_line
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
        fi
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
        local VERSION="$3"
    else
        interactive_yn N "The version '$3' seems not a correct version, do you want to build it anyway?"
        if [[ $? = 0 ]]; then
            local VERSION="$3"
        else
            return 7 # user aborted because of suspicious version
        fi
    fi
    local TMP="/tmp/M7CM-Spigot-building-$JAR_NAME-`date +"%Y-%m-%d-%H-%M"`"
    mkdir "$TMP"
    pushd "$TMP" 1>/dev/null 2>&1
    print_notification 1 "Switched to temporary folder '$TMP'"
    print_notification 1 "Building Spigot jar '$JAR_NAME' rev '$VERSION' using Buildtools jar '$BUILDTOOL'. This may take a few minutes depending on your network connection and hardware performance"
    print_notification 0 "You can try this command if M7CM fails to build it and you believe the trouble is on M7CM side: 'java -jar $PATH_DIRECTORY/jar/$BUILDTOOL.jar --rev $VERSION'"
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
    local JAR_NEW=1
    action_jar_config "$JAR_NAME" "TAG = Built at `date +"%Y-%m-%d-%H:%M"` using M7CM" "TYPE = Spigot" "PROXY = 0" "VERSION = Spigot-$VERSION" "VERSION_MC = $VERSION" "BUILDTOOL = 0"
    return 0
} ## Usage: action_jar_build [jar name] [buildtool] [version]
    ## Return: 0 success 1 environment error-jre 2 environment error-git, 3 buildtool not exist, 4 not a buildtool, 5 can not overwrite existing jar, 6 user aborted overwriting, 7 user aborted because of suspicious version, 8 build error,9 build failed
action_jar_push() {
    if [[ -z "$JAR_NOREAD" ]]; then
        config_read_jar "$1"
        if [[ $? != 0 ]]; then
            return 1
        fi
    fi
    if [[ $# = 2 ]]; then
        config_read_server_and_account "$2"
        if [[ $? != 0 ]]; then
            return 2
        fi
        check_status_server '' 1
        if [[ $? = 0 ]]; then
            print_notification 2 "Remote server '$SERVER_NAME' is running now."
            print_notification 0 "Normally, java programs only read the jar when they are started. Once started, the jar is not needed. But overwriting the jar it's using may still lead to some unexpected consequences."
            if [[ "$M7CM_ASYNC" = 0 ]]; then
                interactive_yn N "Proceed anyway?"
                if [[ $? = 1 ]]; then
                    return 3
                fi
            fi
        fi
        if [[ "$ENV_LOCAL_SSH" = 1 ]]; then
            ssh -oBatchmode=yes $ACCOUNT_HOST -p $ACCOUNT_PORT -l $ACCOUNT_USER -i "$ACCOUNT_KEY" $ACCOUNT_ARGUMENT_SSH "cd $SERVER_DIRECTORY; test -f $SERVER_JAR" 
            if [[ $? = 0 ]]; then
                ssh -oBatchmode=yes $ACCOUNT_HOST -p $ACCOUNT_PORT -l $ACCOUNT_USER -i "$ACCOUNT_KEY" $ACCOUNT_ARGUMENT_SSH "cd $SERVER_DIRECTORY; test ! -w $SERVER_JAR" 
                if [[ $? = 0 ]]; then
                    print_notification 3 "Remote jar '$SERVER_JAR' already exists and can not be overwritten due to lacking of writing permission"
                    return 4
                fi
                if [[ "$M7CM_ASYNC" = 0 ]]; then
                    interactive_yn N "Remote jar '$SERVER_JAR' already exists, overwrite it?"
                    if [[ $? = 1 ]]; then
                        return 5
                    fi
                fi
            fi
        fi
        if [[ "$M7CM_METHOD_PUSH_PULL" = scp ]]; then #scp
            if [[ "${SERVER_JAR:0:1}" = / ]]; then
                print_notification "Remote jar '$SERVER_JAR' seems to be an absolute path"
                scp -i "$ACCOUNT_KEY" -P $ACCOUNT_PORT "$PATH_DIRECTORY/jar/$JAR_NAME.jar" $ACCOUNT_USER@$ACCOUNT_HOST:"$SERVER_JAR"
            else
                scp -i "$ACCOUNT_KEY" -P $ACCOUNT_PORT "$PATH_DIRECTORY/jar/$JAR_NAME.jar" $ACCOUNT_USER@$ACCOUNT_HOST:"$SERVER_DIRECTORY/$SERVER_JAR"
            fi
        elif [[ "$M7CM_METHOD_PUSH_PULL" = sftp ]]; then #sftp
            local TMP="/tmp/M7CM-push-pull-sftp-script-$ACCOUNT_NAME-`date +"%Y-%m-%d-%H-%M"`"
            echo "cd $SERVER_DIRECTORY" > "$TMP"
            echo "put '$PATH_DIRECTORY/jar/$JAR_NAME.jar' '$SERVER_JAR'" >> "$TMP"
            echo "bye" >> "$TMP"
            sftp -i "$ACCOUNT_KEY" -P $ACCOUNT_PORT -b "$TMP"
        else #rsync
            if [[ "${SERVER_JAR:0:1}" = / ]]; then
                print_notification "Remote jar '$SERVER_JAR' seems to be an absolute path"
                rsync -rvz -e "ssh -i '$ACCOUNT_KEY' -l $ACCOUNT_USER -p $ACCOUNT_PORT" "$PATH_DIRECTORY/jar/$JAR_NAME.jar" "$ACCOUNT_HOST:$SERVER_JAR"
            else
                rsync -rvz -e "ssh -i '$ACCOUNT_KEY' -l $ACCOUNT_USER -p $ACCOUNT_PORT" "$PATH_DIRECTORY/jar/$JAR_NAME.jar" "$ACCOUNT_HOST:$SERVER_DIRECTORY/$SERVER_JAR"
            fi
        fi
        if [[ $? = 0 ]]; then
            if [[ "$M7CM_METHOD_PUSH_PULL" = sftp ]]; then
                rm -f "$TMP"
            fi
            if [[ "$ENV_LOCAL_SSH" = 1 ]]; then
                ssh -oBatchmode=yes $ACCOUNT_HOST -p $ACCOUNT_PORT -l $ACCOUNT_USER -i "$ACCOUNT_KEY" $ACCOUNT_ARGUMENT_SSH "cd $SERVER_DIRECTORY; test -f $SERVER_JAR" 
                if [[ $? != 0 ]]; then
                    print_notification 3 "Failed to push jar '$JAR_NAME' to server '$SERVER_NAME'"
                    return 6
                fi
            fi
            print_notification 1 "Successfully pushed jar '$JAR_NAME' to server '$SERVER_NAME'"
        else
            if [[ "$M7CM_METHOD_PUSH_PULL" = sftp ]]; then
                rm -f "$TMP"
            fi
            print_notification 3 "Failed to push jar '$JAR_NAME' to server '$SERVER_NAME'"
            return 7
        fi
        if [[ "$JAR_PROXY" = 1 ]]; then
            if [[ "$SERVER_COMMAND_STOP" = stop ]]; then
                print_notification 1 "Current stop command for server '$SERVER_NAME'is 'stop', but proxy servers usually use 'end' to stop. Changing stop command to 'end'"
                assignment_server 'COMMAND_STOP = end'
                config_write_server
            elif [[ "$SERVER_COMMAND_STOP" != end ]]; then
                print_notification 0 "Proxy servers usually use 'end' to stop, since you've modified the stop command, M7CM will not update it, but you'd better check the stop command for server '$SERVER_NAME' by yourself"
            fi
        else
            if [[ "$SERVER_COMMAND_STOP" = end ]]; then
                print_notification 1 "Current stop command for server '$SERVER_NAME'is 'end', but non-proxy servers usually use 'stop' to stop. Changing stop command to 'stop'"
                assignment_server 'COMMAND_STOP = stop'
                config_write_server
            elif [[ "$SERVER_COMMAND_STOP" != stop ]]; then
                print_notification 0 "Non-proxy servers usually use 'stop' to stop, since you've modified the stop command, M7CM will not update it, but you'd better check the stop command for server '$SERVER_NAME' by yourself"
            fi
            if [[ "$ENV_LOCAL_SSH" = 1 ]]; then
                ssh -oBatchmode=yes $ACCOUNT_HOST -p $ACCOUNT_PORT -l $ACCOUNT_USER -i "$ACCOUNT_KEY" $ACCOUNT_ARGUMENT_SSH "grep 'eula=true' '$SERVER_DIRECTORY/eula.txt' 1>/dev/null 2>&1"
                if [[ $? != 0 ]]; then
                    print_notification 1 "Agreeing EULA on non-proxy server '$SERVER_NAME'"
                    ssh -oBatchmode=yes $ACCOUNT_HOST -p $ACCOUNT_PORT -l $ACCOUNT_USER -i "$ACCOUNT_KEY" $ACCOUNT_ARGUMENT_SSH "echo 'eula=true' > '$SERVER_DIRECTORY/eula.txt'"
                fi
            fi
        fi  
    else
        print_notification 1 "Pushing jar '$JAR_NAME' to multiple servers: ${@:2}"
        local JAR_NOREAD=1
        while [[ $# -gt 1 ]]; do
            if [[ "$M7CM_ASYNC" = 1 ]]; then
                action_jar_push "$JAR_NAME" "$2" &
            else
                print_center " Server '$1' " = =
                print_notification 1 "$(( $# - 1 )) servers left: ${@:2}"
                action_jar_push "$JAR_NAME" "$2"
            fi
            shift
        done
    fi
} ## action_jar_push [jar] [server1] [server2]
action_jar_pull() {
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
        fi
    fi
    config_read_server_and_account "$2"
    if [[ $? != 0 ]]; then
        return 3
    fi
    if [[ "$3" ]]; then
        local SERVER_JAR="$3"
    fi
    if [[ "$ENV_LOCAL_SSH" = 1 ]]; then
        ssh -oBatchmode=yes $ACCOUNT_HOST -p $ACCOUNT_PORT -l $ACCOUNT_USER -i "$ACCOUNT_KEY" $ACCOUNT_ARGUMENT_SSH "cd $SERVER_DIRECTORY; test -f $SERVER_JAR" 
        if [[ $? = 0 ]]; then
            ssh -oBatchmode=yes $ACCOUNT_HOST -p $ACCOUNT_PORT -l $ACCOUNT_USER -i "$ACCOUNT_KEY" $ACCOUNT_ARGUMENT_SSH "cd $SERVER_DIRECTORY; test ! -r $SERVER_JAR" 
            if [[ $? = 0 ]]; then
                print_notification 3 "Remote jar '$SERVER_JAR' exists but is not readable, check your permission"
                return 4
            fi
        else
            print_notification 3 "Remote jar '$SERVER_JAR' does not exist, failed to pull it"
            return 5
        fi
    fi
    if [[ "$M7CM_METHOD_PUSH_PULL" = scp ]]; then #scp
        if [[ "${SERVER_JAR:0:1}" = / ]]; then
            print_notification "Remote jar '$SERVER_JAR' seems to be an absolute path"
            scp -i "$ACCOUNT_KEY" -P $ACCOUNT_PORT $ACCOUNT_USER@$ACCOUNT_HOST:"$SERVER_JAR" "$PATH_DIRECTORY/jar/$JAR_NAME.jar"
        else
            scp -i "$ACCOUNT_KEY" -P $ACCOUNT_PORT  $ACCOUNT_USER@$ACCOUNT_HOST:"$SERVER_DIRECTORY/$SERVER_JAR" "$PATH_DIRECTORY/jar/$JAR_NAME.jar"
        fi
    elif [[ "$M7CM_METHOD_PUSH_PULL" = sftp ]]; then #sftp
        local TMP="/tmp/M7CM-push-pull-sftp-script-$ACCOUNT_NAME-`date +"%Y-%m-%d-%H-%M"`"
        echo "cd $SERVER_DIRECTORY" > "$TMP"
        echo "get '$SERVER_JAR' '$PATH_DIRECTORY/jar/$JAR_NAME.jar'" >> "$TMP"
        echo "bye" >> "$TMP"
        sftp -i "$ACCOUNT_KEY" -P $ACCOUNT_PORT -b "$TMP"
    else #rsync
        if [[ "${SERVER_JAR:0:1}" = / ]]; then
            print_notification "Remote jar '$SERVER_JAR' seems to be an absolute path"
            rsync -rvz -e "ssh -i '$ACCOUNT_KEY' -l $ACCOUNT_USER -p $ACCOUNT_PORT" "$ACCOUNT_HOST:$SERVER_JAR" "$PATH_DIRECTORY/jar/$JAR_NAME.jar"
        else
            rsync -rvz -e "ssh -i '$ACCOUNT_KEY' -l $ACCOUNT_USER -p $ACCOUNT_PORT" "$ACCOUNT_HOST:$SERVER_DIRECTORY/$SERVER_JAR" "$PATH_DIRECTORY/jar/$JAR_NAME.jar" 
        fi
    fi
    if [[ $? = 0 ]]; then
        if [[ "$M7CM_METHOD_PUSH_PULL" = sftp ]]; then
            rm -f "$TMP"
        fi
        if [[ -f "$PATH_DIRECTORY/jar/$JAR_NAME.jar" ]]; then
            print_notification 1 "Successfullly pulled jar '$SERVER_JAR' from server '$SERVER_NAME'"
            print_counting 3 '' 'Redirecting to jar configuration page'
            local JAR_NEW=1
            action_jar_config "$JAR_NAME" "TAG = Pulled from server '$SERVER_NAME' at `date +"%Y-%m-%d-%H:%M"` "
            return 0
        else
            print_notification 3 "Failed to pull jar '$SERVER_JAR' from server '$SERVER_NAME'"
            return 6
        fi
    else
        if [[ "$M7CM_METHOD_PUSH_PULL" = sftp ]]; then
            rm -f "$TMP"
        fi
        print_notification 3 "Failed to pull jar '$SERVER_JAR' from server '$SERVER_NAME'"
        return 7
    fi
    

} ## action_jar_pull [jar] [server] ([remote jar])
## account related
action_account_define() {
    if [[ -f "$PATH_DIRECTORY/account/$1.conf" ]]; then
        interactive_yn N "An account with the same name '$1' has already been defined. Should we remove it first?"
        if [[ $? = 0 ]]; then
            action_account_remove "$1"
            if [[ $? != 0 ]]; then
                return 1 ## already exist and can not overwrite
            fi
        else
            return 2 ## Aborted overwriting
        fi
    fi
    print_counting 3 '' 'Redirecting to account configuration page'
    local ACCOUNT_NEW=1
    action_account_config "$1" "HOST = $2" "TAG = Defined at `date +"%Y-%m-%d-%H-%M"`" "PORT = $3" "USER = $4" "KEY = $5" 
    if [[ $? = 0 ]]; then
        print_notification 1 "Successfully added account '$1'"
    else
        print_notification 3 "Failed to add server '$1'"
        return 3 # failed
    fi
} ## Usage: action_account_define [account name] [host] [port] [user] [key]
    ## Return: 0 success, 1 can not overwrite existing account, 2 aborted overwriting
action_account_config() {
    ACCOUNT_NAME="$1"
    ACCOUNT_TAG=''
    ACCOUNT_HOST=''
    ACCOUNT_PORT=''
    ACCOUNT_USER=''
    ACCOUNT_KEY=''
    ACCOUNT_ARGUMENT_SSH=''
    ACCOUNT_ARGUMENT_RSYNC=''
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
        print_multilayer_menu "HOST: $ACCOUNT_HOST" "Can be domain or ip, e.g. mc.mydomain.com, or 33.33.33.33. Default: '$M7CM_DEFAULT_SSH_HOST'"
        print_multilayer_menu "PORT: $ACCOUNT_PORT" "Interger, 0-65535. Default: '$M7CM_DEFAULT_SSH_PORT'"
        print_multilayer_menu "USER: $ACCOUNT_USER" "User name will be used to login. Default: current user('$M7CM_DEFAULT_SSH_USER')"
        print_multilayer_menu "KEY: $ACCOUNT_KEY" "Private key file used to login"
        # if [[ -z "$ACCOUNT_ARGUMENT_SSH" ]]; then
        #     print_multilayer_menu "ARGUMENT_SSH: $ACCOUNT_ARGUMENT_SSH" "Extra arguments used for SSH. DO NOT EDIT THIS if you don't know what you are doing"
        # else
        print_multilayer_menu "ARGUMENT_SSH: $ACCOUNT_ARGUMENT_SSH" "Extra arguments used for SSH, by default, M7CM already uses -l, -p, -i, and -oBatchmode=yes(only when managing servers) "
        print_multilayer_menu "ARGUMENT_RSYNC: $ACCOUNT_ARGUMENT_RSYNC" "Extra arguments for rsync, by default, M7CM already uses -aAXvz, --delete, -e, and --dryrun(only when validating)"
        print_notification 1 "Current SSH command: 'ssh $ACCOUNT_HOST -p $ACCOUNT_PORT -l $ACCOUNT_USER -i $ACCOUNT_KEY $ACCOUNT_ARGUMENT_SSH'"
        if [[ $ACCOUNT_VALID = 1 ]]; then
            print_notification 1 "This account is valid √ " "You can type 'save' or 'confirm' to save it now"
        else
            print_notification 2 "This account is invalid X " "Type 'validate' to validate it first"
        fi
        print_draw_line
        print_notification 0 "Type in the option you want to change and its new value split by =, e.g. 'PORT = 22' (without quote and option is not case sensitive, e.g. CoNfIrM)."
        read -e -p " >>> " COMMAND
        case "${COMMAND,,}" in
            validate)
                check_validate_account '' 1
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
        while [[ $# -gt 0 ]]; do
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
    if [[ "$M7CM_HIDE_KEY_PATH" = 1 ]]; then
        print_notification 0 "'HIDE_KEY_PATH' is enabled in config.conf, to show private key path, set 'HIDE_KEY_PATH=1' in config.conf"
    else
        print_notification 0 "'HIDE_KEY_PATH' is disabled, to hide key path, set 'HIDE_KEY_PATH=0' in config.conf"
    fi
    return 0
}
action_account_list() {
    print_draw_line
    print_center "Account List"
    print_draw_line
    ls $PATH_DIRECTORY/account/*.conf 1>/dev/null 2>&1
    if [[ $? != 0 ]]; then
        print_notification 3 "You have not added any account yet. Use '$PATH_SCRIPT account define ...' to define an account first"
        return 1
    fi
    local ORDER=1
    for ACCOUNT_NAME in $PATH_DIRECTORY/account/*.conf; do
        ACCOUNT_NAME=$(basename $ACCOUNT_NAME)
        ACCOUNT_NAME=${ACCOUNT_NAME:0:-5}
        print_multilayer_menu "No.$ORDER $ACCOUNT_NAME" '' 0
        print_info_account
        print_draw_line
        let ORDER++
    done
    if [[ "$M7CM_HIDE_KEY_PATH" = 1 ]]; then
        print_notification 0 "'HIDE_KEY_PATH' is enabled in config.conf, to show private key path, set 'HIDE_KEY_PATH=1' in config.conf"
    else
        print_notification 0 "'HIDE_KEY_PATH' is disabled, to hide key path, set 'HIDE_KEY_PATH=0' in config.conf"
    fi
    return 0
}
action_account_remove() {
    if [[ $# = 1 ]]; then
        if [[ ! -f "$PATH_DIRECTORY/account/$1.conf" ]]; then
            print_notification 3 "The account '$1' you specified does not exist!"
            return 1 ## not exist
        elif [[ ! -w "$PATH_DIRECTORY/account/$1.conf" ]]; then
            print_notification 3 "Removing failed due to lacking of writing permission of configuration file '$1.conf'"
            return 2 ## jar not writable 
        fi
        ls $PATH_DIRECTORY/server/*.conf 1>/dev/null 2>&1
        if [[ $? = 0 ]]; then
            local TMP
            local SERVER_LIST
            for TMP in $PATH_DIRECTORY/server/*.conf; do
                grep -Fxq "ACCOUNT=$1" "$TMP" 1>/dev/null 2>&1
                if [[ $? = 0 ]]; then
                    local SERVER_NAME=$(basename $TMP)
                    SERVER_NAME=${SERVER_NAME:0:-5}
                    SERVER_LIST="$SERVER_LIST '$SERVER_NAME'"
                    
                fi
            done
            if [[ "$SERVER_LIST" ]]; then
                print_notification 3 "Failed to remove account '$1', this account is used in the following server(s) now:$SERVER_LIST "
                return 3
            fi
        fi
        interactive_yn N "Are you sure you want to remove account '$1' from your library?"
        if [[ $? = 0 ]]; then
            rm -f "$PATH_DIRECTORY/account/$1.conf"
            print_notification 1 "Removed account '$1' from library"
            return 0
        else
            return 4 ## User refused 
        fi
    else
        print_notification 1 "Removing multiple accounts: $@"
        while [[ $# -gt 0 ]]; do
            print_notification 1 "$# accounts left: $@"
            action_account_remove "$1"
            shift
        done
    fi
}
action_server_define() {
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
    SERVER_NAME="$1"
    local SERVER_NEW=1
    action_server_config "$1" "ACCOUNT = $2" "DIRECTORY = $3" "PORT= $4" "RAM_MAX = $5" "RAM_MIN = $6" "JAR = $7" "EXTRA_JAVA = $8" "EXTRA_JAR = $9" "SCREEN = ${10}" "COMMAND_STOP = ${11}" "TAG = Added at `date +"%Y-%m-%d-%H:%M"`"
    if [[ $? != 0 ]]; then
        print_notification 3 "Failed to add server '$1'"
        return 3 # failed
    else
        print_notification 1 "Successfully added server '$1'"
        return 0
    fi
} ## Usage: action_server_define [server] [account] [directory] [port] [max ram] [min ram] [remote jar] [java extra arguments] [jar extra arguments] [screen] [stop command]
action_server_config() {
    SERVER_NAME="$1"
    SERVER_TAG=''
    SERVER_DIRECTORY=''
    SERVER_PORT="$M7CM_DEFAULT_SERVER_PORT"
    SERVER_RAM_MAX='1G'
    SERVER_RAM_MIN='1G'
    SERVER_JAR="$M7CM_DEFAULT_SERVER_JAR"
    SERVER_ARGUMENT_JAVA=''
    SERVER_ARGUMENT_JAR=''
    SERVER_SCREEN=''
    SERVER_COMMAND_STOP='stop'
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
        print_multilayer_menu "RAM_MAX: $SERVER_RAM_MAX" "Interger+M/G, e.g. 1024M. Default:1G, not less than RAM_MIN"
        print_multilayer_menu "RAM_MIN: $SERVER_RAM_MIN" "Interger+M/G, e.g. 1024M. Default:1G, not greater than RAM_MAX"
        print_multilayer_menu "JAR: $SERVER_JAR" "Remote server jar file with file extention. Can be absolute path. Default: server.jar"
        if [[ -z "$SERVER_ARGUMENT_JAVA" ]]; then
            print_multilayer_menu "EXTRA_JAVA: $SERVER_ARGUMENT_JAVA" "Extra arguments for java, e.g. -XX:+UseG1GC will enable garbage collection. Usually you don't need this"
        else
            print_multilayer_menu "EXTRA_JAVA: $SERVER_ARGUMENT_JAVA"
        fi
        if [[ -z "$SERVER_ARGUMENT_JAR" ]]; then
            print_multilayer_menu "EXTRA_JAR: $SERVER_ARGUMENT_JAR" "Extra arguments for the jar itself, e.g. --host <IP address> will make a Spigot server bind to this IP address. DO NOT EDIT THIS if you don't know what you are doing" 
        else
            print_multilayer_menu "EXTRA: $SERVER_EXTRA" "Extra arguments used for SSH." 
        fi
        print_multilayer_menu "SCREEN: $SERVER_SCREEN" "The name of the screen session, usually there's no need to change this"
        print_multilayer_menu "COMMAND_STOP: $SERVER_COMMAND_STOP" "Stop command of the server. Use ^M to split multiple commands. i.e. 'say Server is shutting down! ^M stop', if you want to include ^ in the command, use \^"  1 1
        print_draw_line
        print_notification 1 "Current Minecraft startup command: java -Xmx$SERVER_RAM_MAX -Xms$SERVER_RAM_MIN $SERVER_ARGUMENT_JAVA -jar $SERVER_JAR nogui --port $SERVER_PORT $SERVER_ARGUMENT_JAR"
        print_draw_line
        if [[ $SERVER_VALID = 1 ]]; then
            print_notification 1 "This server is valid √ " "You can type 'save' or 'confirm' to save it now"
        else
            print_notification 2 "This server is invalid X " "Type 'validate' to validate it first"
        fi
        print_draw_line
        print_notification 0 "Type in the option you want to change and its new value split by =, e.g. 'PORT = 25565' (without quote and option is not case sensitive, e.g. CoNfRim)."
        read -e -p ' >>> ' COMMAND
        case "${COMMAND,,}" in
            validate)
                check_validate_server '' 1
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
    if [[ $# = 1 ]]; then
        if [[ ! -f "$PATH_DIRECTORY/server/$1.conf" ]]; then
            print_notification 3 "The server '$1' you specified does not exist!"
            return 1 ## not exist
        elif [[ ! -w "$PATH_DIRECTORY/server/$1.conf" ]]; then
            print_notification 3 "Failed to remove server '$1': no writing permission for configuration file '$1.conf'"
            return 2 ## jar not writable 
        fi
        interactive_yn N "Are you sure you want to remove server '$1' from your library?"
        if [[ $? = 1 ]]; then
            return 3
        fi
        action_server_stop "$1"
        if [[ $? != 0 ]]; then
            return 4
        fi
        rm -f "$PATH_DIRECTORY/server/$1.conf"
        print_notification 1 "Removed server '$1' from library"
    else
        print_notification 1 "Removing multiple servers: $@"
        while [[ $# -gt 0 ]]; do
            print_notification 1 "$# servers left: $@"
            action_server_remove "$1"
            # if [[ $? != 0 ]]; then
            #     print_notification 3 "Failed to remove multiple servers, $# servers left: $@"
            #     return 5
            # fi
            shift
        done
    fi
}
action_server_info() {
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
        while [[ $# -gt 0 ]]; do
            print_multilayer_menu "$ORDER. $1" '' 0
            if [[ ! -f "$PATH_DIRECTORY/server/$1.conf" ]]; then
                print_multilayer_menu '\e[41mThis server does not exist' '' 1 1
                return 1 # not exist
            else
                if [[ "$M7CM_DETAILED_SERVER_LIST" = 1 ]]; then
                    print_info_server "$1"
                else
                    print_info_server "$1" 0 1 1
                fi
            fi
            shift
            let ORDER++
            print_draw_line
        done
        if [[ "$M7CM_DETAILED_SERVER_LIST" = 1 ]]; then
            print_notification 0 "For more abbreviated information, set 'M7CM_DETAILED_SERVER_LIST=0' in config.conf"
        else
            print_notification 0 "For more detailed information, use '$PATH_SCRIPT info [server]' to check one server a time, or you can set 'DETAILED_SERVER_LIST=1' in config.conf"
        fi
    fi
    return 0
}
action_server_list() {
    print_draw_line
    print_center "Server List"
    print_draw_line
    ls $PATH_DIRECTORY/server/*.conf 1>/dev/null 2>&1
    if [[ $? != 0 ]]; then
        print_notification 3 "You have not added any server yet. Use '$PATH_SCRIPT define ...' to define a server first"
        return 1
    fi
    local ORDER=1
    for SERVER_NAME in $PATH_DIRECTORY/server/*.conf; do
        SERVER_NAME=$(basename $SERVER_NAME)
        SERVER_NAME=${SERVER_NAME:0:-5}
        print_multilayer_menu "$ORDER. $SERVER_NAME" '' 0
        if [[ "$M7CM_DETAILED_SERVER_LIST" = 1 ]]; then
            print_info_server 
        else
            print_info_server '' 0 1 1
        fi
        let ORDER++
        print_draw_line
    done
    if [[ "$M7CM_DETAILED_SERVER_LIST" = 1 ]]; then
        print_notification 0 "For more abbreviated information, set 'M7CM_DETAILED_SERVER_LIST=0' in config.conf"
    else
        print_notification 0 "For more detailed information, use '$PATH_SCRIPT info [server]' to check one server a time, or you can set 'DETAILED_SERVER_LIST=1' in config.conf"
    fi
    return 0
}
action_server_start() {
    if [[ $# = 1 ]]; then
        SERVER_NAME="$1"
        if [[ -z "$SERVER_NO_READ" ]]; then
            config_read_server_and_account
            if [[ $? != 0 ]]; then
                return 1
            fi
        fi
        print_notification 1 "Starting server '$SERVER_NAME'..."
        check_status_server '' 1
        if [[ $? = 0 ]]; then
            print_notification 1 "Server '$SERVER_NAME' is already running, no need to start it."
            return 0
        fi
        ssh $ACCOUNT_HOST -oBatchmode=yes -p $ACCOUNT_PORT -l $ACCOUNT_USER -i "$ACCOUNT_KEY" $ACCOUNT_ARGUMENT_SSH "cd $SERVER_DIRECTORY; screen -mSUd '$SERVER_SCREEN' java -Xmx$SERVER_RAM_MAX -Xms$SERVER_RAM_MIN $SERVER_ARGUMENT_JAVA -jar '$SERVER_JAR' nogui --port $SERVER_PORT $SERVER_ARGUMENT_JAR"
        if [[ $? = 0 ]]; then
            if [[ "$M7CM_CONFIRM_START" = 0 ]]; then
                print_notification 1 "Started server '$SERVER_NAME'"
                return 0
            fi
            print_center 'Server Startup Confirmation' - -
            print_counting $M7CM_CONFIRM_INTERVAL '' "Detecting server status"
            check_status_server '' 1
            if [[ $? = 0 ]]; then
                print_notification 1 "Server '$SERVER_NAME' is successfully started"
                print_center 'End of Server Startup Confirmation' - -
                return 0
            elif [[ "$M7CM_RETRY_START" = 1 ]]; then
                print_notification 2 "Failed to start server '$SERVER_NAME'. We will retry to start it for 3 times."
                local TRY=1
                for TRY in $(seq 1 3); do
                    print_notification 1 "Retrying to start server '$SERVER_NAME'... remaining tries: $(( 4 - $TRY ))"
                    ssh $ACCOUNT_HOST -oBatchmode=yes -p $ACCOUNT_PORT -l $ACCOUNT_USER -i "$ACCOUNT_KEY" $ACCOUNT_ARGUMENT_SSH "cd $SERVER_DIRECTORY; screen -mSUd '$SERVER_SCREEN' java -Xmx$SERVER_RAM_MAX -Xms$SERVER_RAM_MIN $SERVER_ARGUMENT_JAVA -jar '$SERVER_JAR' nogui --port $SERVER_PORT $SERVER_ARGUMENT_JAR"
                    print_notification 1 "Re-sent startup command"
                    print_counting $(( $M7CM_CONFIRM_INTERVAL * $TRY )) '' "Detecting server status"
                    check_status_server '' 1
                    if [[ $? = 0 ]]; then
                        print_notification 1 "Server '$SERVER_NAME' is successfully started"
                        print_draw_line
                        return 0
                    else
                        print_notification 2 "Failed to start server '$SERVER_NAME'"
                    fi
                done
                print_notification 3 "Failed to start server '$SERVER_NAME' after 3 retries."
            else
                print_notification 3 "Failed to start server '$SERVER_NAME'"
            fi
            print_center 'End of Server Startup Confirmation' - -
        else
            print_notification 3 "Server '$SERVER_NAME' can not be started"
        fi
        check_diagnose_server 
        if [[ $? = 0 ]]; then
            print_notification 3 "We can not diagnose what is wrong with the server '$SERVER_NAME'"
            print_notification 1 "The full startup command of this server is: ssh $ACCOUNT_HOST -oBatchmode=yes -p $ACCOUNT_PORT -l $ACCOUNT_USER -i "$ACCOUNT_KEY" $ACCOUNT_ARGUMENT_SSH \"screen -mSUd '$SERVER_SCREEN' java -Xmx$SERVER_RAM_MAX -Xms$SERVER_RAM_MIN $SERVER_ARGUMENT_JAVA -jar '$SERVER_JAR' nogui --port $SERVER_PORT $SERVER_ARGUMENT_JAR\""
            print_notification 1 "The local startup command on the host is: java -Xmx$SERVER_RAM_MAX -Xms$SERVER_RAM_MIN $SERVER_ARGUMENT_JAVA -jar "$SERVER_JAR" nogui --port $SERVER_PORT $SERVER_ARGUMENT_JAR"
            print_notification 0 "You can try to start the server by yourself using this command."
            return 2
        else
            return 3
        fi
    else
        print_notification 1 "Starting multiple servers: $@"
        while [[ $# -gt 0 ]]; do
            if [[ "$M7CM_ASYNC" = 1 ]]; then
                action_server_start "$1" &
            else
                print_center " Server '$1' " = =
                print_notification 1 "$# servers left: $@"
                action_server_start "$1" 
            fi
            shift
        done
        return 0
    fi
} 
action_server_stop() {
    if [[ $# = 1 ]]; then
        SERVER_NAME="$1"
        if [[ -z "$SERVER_NO_READ" ]]; then
            config_read_server_and_account
            if [[ $? != 0 ]]; then
                return 1
            fi
        fi
        print_notification 1 "Stopping server '$SERVER_NAME'..."
        check_status_server '' 1
        if [[ $? = 1 ]]; then
            print_notification 1 "Server '$SERVER_NAME' is not running, no need to stop it."
            return 0
        fi
        ssh $ACCOUNT_HOST -oBatchmode=yes -p $ACCOUNT_PORT -l $ACCOUNT_USER -i "$ACCOUNT_KEY" $ACCOUNT_ARGUMENT_SSH "screen -rXd '$SERVER_SCREEN' stuff '^M$SERVER_COMMAND_STOP^M'"
        if [[ $? = 0 ]]; then
            if [[ "$M7CM_CONFIRM_STOP" = 0 ]]; then
                print_notification 3 "Stopped server '$SERVER_NAME'"
                return 0
            fi
            print_center 'Server Stop Confirmation' - -
            print_counting $M7CM_CONFIRM_INTERVAL '' "Detecting server status"
            check_status_server '' 1
            if [[ $? = 1 ]]; then
                print_notification 1 "Server '$SERVER_NAME' is successfully stopped"
                print_center 'End of Server Startup Confirmation' - -
                return 0
            elif [[ "$M7CM_RETRY_STOP" = 1 ]]; then
                print_notification 2 "Failed to stop server '$SERVER_NAME'. We will retry to stop it for 3 times."
                local TRY=1
                for TRY in $(seq 1 3); do
                    print_notification 1 "Retrying to stop server '$SERVER_NAME'... remaining tries: $(( 4 - $TRY ))"
                    ssh $ACCOUNT_HOST -oBatchmode=yes -p $ACCOUNT_PORT -l $ACCOUNT_USER -i "$ACCOUNT_KEY" $ACCOUNT_ARGUMENT_SSH "screen -rXd '$SERVER_SCREEN' stuff '^M$SERVER_COMMAND_STOP^M'"
                    print_notification 1 "Re-sent stop command"
                    print_counting $(( $M7CM_CONFIRM_INTERVAL * $TRY )) '' "Detecting server status"
                    check_status_server '' 1
                    if [[ $? = 1 ]]; then
                        print_notification 1 "Server '$SERVER_NAME' is successfully stopped"
                        print_center 'End of Server Startup Confirmation' - -
                        return 0
                    else
                        print_notification 2 "Failed to stop server '$SERVER_NAME'"
                    fi
                done
                print_notification 3 "Failed to stop server '$SERVER_NAME' after 3 retries."
            else
                print_notification 3 "Failed to stop server '$SERVER_NAME'"
            fi
            print_center 'End of Server Stop Confirmation' - -
        else
            print_notification 3 "Server '$SERVER_NAME' can not be stopped"
        fi
        if [[ "$M7CM_FORCE_STOP" = 1 ]]; then
            print_notification 1 "Force-stop the server '$SERVER_NAME'..."
            ssh $ACCOUNT_HOST -oBatchmode=yes -p $ACCOUNT_PORT -l $ACCOUNT_USER -i "$ACCOUNT_KEY" $ACCOUNT_ARGUMENT_SSH "screen -X -S '$SERVER_SCREEN' kill"
            check_status_server '' 1
            if [[ $? = 1 ]]; then
                print_notification 1 "Server '$SERVER_NAME' is successfully stopped"
                return 0
            else
                print_notification 3 "We still can not stop the server '$SERVER_NAME' even with signal 9"
            fi
        fi
        print_notification 1 "Maybe you should check what the server is processing on console using '$PATH_SCRIPT' console '$SERVER_NAME'"
        return 2
    else
        print_notification 1 "Stopping multiple servers: $@"
        while [[ $# -gt 0 ]]; do
            if [[ "$M7CM_ASYNC" = 1 ]]; then
                action_server_stop "$1" &
            else
                print_center " Server '$1' " = =
                print_notification 1 "$# servers left: $@"
                action_server_stop "$1"
            fi
            shift
        done
        return 0
    fi
}
action_server_restart() {
    if [[ $# = 1 ]]; then
        SERVER_NAME="$1"
        config_read_server_and_account
        if [[ $? != 0 ]]; then
            return 1
        fi
        print_notification 1 "Restarting server '$SERVER_NAME'..."
        if [[ $? != 0 ]]; then
            return 1
        fi
        local SERVER_NO_READ=1
        action_server_stop "$1"
        if [[ $? != 0 ]]; then
            print_notification 3 "Failed to restart server '$SERVER_NAME', the server is still running"
            return 2
        fi
        action_server_start "$1"
        if [[ $? != 0 ]]; then
            print_notification 3 "Failed to restart server '$SERVER_NAME', the server can not be started"
            return 3
        fi
        print_notification 1 "Restarted server '$SERVER_NAME'..."
        return 0
    else
        print_notification 1 "Restarting multiple servers: $@"
        while [[ $# -gt 0 ]]; do
            if [[ "$M7CM_ASYNC" = 1 ]]; then
                action_server_restart "$1" &
            else
                print_center " Server '$1' " = =
                print_notification 1 "$# servers left: $@"
                action_server_restart "$1"
            fi
            shift
        done
        return 0
    fi
} 
action_server_browse() {
    SERVER_NAME="$1"
    config_read_server_and_account
    if [[ $? != 0 ]]; then
        return 1
    fi
    print_notification 1 "Sending you to the remote directory '$SERVER_DIRECTORY'. Use ctrl+D  or type 'exit' to exit"
    ssh $ACCOUNT_HOST -t -p $ACCOUNT_PORT -l $ACCOUNT_USER -i "$ACCOUNT_KEY" $ACCOUNT_ARGUMENT_SSH "cd $SERVER_DIRECTORY; bash"
    if [[ $? != 0 ]]; then
        print_notification 3 "Can not connect to remote directory '$SERVER_DIRECTORY', diagnosing problems of server '$SERVER_NAME'... "
        check_diagnose_server
        if [[ $? = 0 ]]; then
            print_notification 3 "We can not diagnose what is wrong with the server '$SERVER_NAME'"
            print_notification 1 "The full browse command of this server is: ssh $ACCOUNT_HOST -t -p $ACCOUNT_PORT -l $ACCOUNT_USER -i '$ACCOUNT_KEY' $ACCOUNT_ARGUMENT_SSH 'cd $SERVER_DIRECTORY; bash'"
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
    print_notification 0 "Use Ctrl+A Ctrl+D to get back from remote console. DO NOT USE ctrl+C , that would shutdown the server."
    ssh $ACCOUNT_HOST -t -p $ACCOUNT_PORT -l $ACCOUNT_USER -i "$ACCOUNT_KEY" $ACCOUNT_ARGUMENT_SSH "screen -rd '$SERVER_SCREEN'"
    if [[ $? != 0 ]];  then
        print_notification 3 "Can not connect to remote console of server '$SERVER_NAME', diagnosing problems of server '$SERVER_NAME'... "
        check_diagnose_server
        if [[ $? = 0 ]]; then
            print_notification 3 "We can not diagnose what is wrong with the server '$SERVER_NAME'"
            print_notification 1 "The full connect command of this server is: ssh $ACCOUNT_HOST -p $ACCOUNT_PORT -l $ACCOUNT_USER -i '$ACCOUNT_KEY' $ACCOUNT_ARGUMENT_SSH 'screen -rd \"$SERVER_SCREEN\""
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
    if [[ $# = 1 ]]; then
        SERVER_NAME="$1"
    fi
    config_read_server_and_account
    if [[ $? != 0 ]]; then
        return 1
    fi
    check_status_server '' 1
    if [[ $? = 1 ]]; then
        print_notification 3 "Server '$SERVER_NAME' is not running"
        return 2
    fi
    local COMMAND
    local COMMAND_FRIENDLY
    while [[ $# -gt 1 ]]; do
        if [[ "$2" =~  (^|[^\\])\^ ]]; then
            print_notification 2 "Omitted command '$2' due to lacking of '\' before '^'. If you want to send any command containing '^', you must use '\' before the first charater of these pattern, e.g. 'say \^.\^' . Since M7CM send commands by emulating keyboard input, and ^ means holding ctrl. So ^ will convert your input into some wierd keyboard operation. e.g. ^C will kill your server, ^M will enter a break, etc"
        else
            # if [[ -z "$COMMAND" ]]; then
            #     COMMAND="$2"
            #     COMMAND_FRIENDLY="'$2'"
            # else
            COMMAND="$COMMAND^M$2"
            COMMAND_FRIENDLY="$COMMAND_FRIENDLY '$2'"
            # fi
        fi
        shift 
    done
    # local COMMAND="$2"
    # local COMMAND_FRIENDLY="'$2'"
    # while [[ $# -gt 2 ]]; do
    #     COMMAND="$COMMAND^M$3"
    #     COMMAND_FRIENDLY="$COMMAND_FRIENDLY, '$3'"
    #     shift 
    # done
    print_notification 1 "Sending commands the following commands to server '$SERVER_NAME': $COMMAND_FRIENDLY"
    ssh $ACCOUNT_HOST -oBatchmode=yes -p $ACCOUNT_PORT -l $ACCOUNT_USER -i "$ACCOUNT_KEY" $ACCOUNT_ARGUMENT_SSH "screen -rd '$SERVER_SCREEN' -X stuff '$COMMAND^M'"
    if [[ $? != 0 ]]; then
        print_notification 3 "Could not send command $COMMAND_FRIENDLY to remote directory '$SERVER_DIRECTORY', diagnosing problems of server '$SERVER_NAME'... "
        check_diagnose_server
        if [[ $? = 0 ]]; then
            print_notification 3 "We can not diagnose what is wrong with the server '$SERVER_NAME'"
            print_notification 1 "The full browse command of this server is: ssh $ACCOUNT_HOST -oBatchmode=yes -p $ACCOUNT_PORT -l $ACCOUNT_USER -i '$ACCOUNT_KEY' $ACCOUNT_ARGUMENT_SSH 'screen -rd \"$SERVER_SCREEN\" -X stuff \"^M$COMMAND^M\"'"
            print_notification 0 "You can try to browse the directory by yourself using this command."
            return 2
        else
            return 3
        fi
    else
        print_notification 1 "Successfully sent command $COMMAND_FRIENDLY to server '$SERVER_NAME'"
        return 0
    fi
}
action_server_backup() {
    print_notification 1 "Normally you should not run backup manually, if you want M7CM to create schedule backups in your crontab, use action 'plan'"
    if [[ $# = 1 ]]; then
        SERVER_NAME="$1"
        config_read_server_and_account
        if [[ $? != 0 ]]; then
            return 1
        fi
        print_notification 1 "Validating rsync...."
        rsync -aAXvz --delete --dry-run $ACCOUNT_ARGUMENT_RSYNC -e "ssh -i '$ACCOUNT_KEY' -l '$ACCOUNT_USER' -p '$ACCOUNT_PORT'" "$ACCOUNT_HOST:$SERVER_DIRECTORY/" "$PATH_DIRECTORY/backup/$SERVER_NAME"
        #echo "command: rsync -aAXvz --delete --dry-run \"$ACCOUNT_ARGUMENT_RSYNC\" -e \"ssh -i '$ACCOUNT_KEY' -l root -p '$ACCOUNT_PORT'\" \"$ACCOUNT_HOST:$SERVER_DIRECTORY/\" \"$PATH_DIRECTORY/backup/$SERVER_NAME\""
        if [[ $? != 0 ]]; then
            print_notification 3 'Validation failed for rsync.'
            return 2
        else
            print_notification 1 "Validation passed. Creating backup data of server '$SERVER_NAME' ..."
        fi
        rsync -aAXvz --delete $ACCOUNT_ARGUMENT_RSYNC -e "ssh -i '$ACCOUNT_KEY' -l '$ACCOUNT_USER' -p '$ACCOUNT_PORT'" "$ACCOUNT_HOST:$SERVER_DIRECTORY/" "$PATH_DIRECTORY/backup/$SERVER_NAME"
        if [[ $? != 0 ]]; then
            print_notification 3 "Failed to backup. Did we run out of the disk space, or was the network connection interrupted?"
            return 3
        else
            print_notification 1 "Backup complete for server '$SERVER_NAME'"
            return 0
        fi
    else
        print_notification 1 "Backuping multiple servers: $@"
        while [[ $# -gt 0 ]]; do
            if [[ "$M7CM_ASYNC" = 1 ]]; then
                action_server_backup "$1" &
            else
                print_center " Server '$1' " = =
                print_notification 1 "$# servers left: $@"
                action_server_backup "$1" 
            fi
            shift
        done
        return 0
    fi
}
action_server_backup_silent() {
    if [[ $# = 1 ]]; then
        SERVER_NAME="$1"
        config_read_server_and_account
        if [[ $? != 0 ]]; then
            return 1
        fi
        rsync -aAXvz --delete $ACCOUNT_ARGUMENT_RSYNC -e "ssh -i '$ACCOUNT_KEY' -l root -p '$ACCOUNT_PORT'" "$ACCOUNT_HOST:$SERVER_DIRECTORY/" "$PATH_DIRECTORY/backup/$SERVER_NAME"
        if [[ $? != 0 ]]; then
            return 2
        else
            return 0
        fi    
    else
        while [[ $# -gt 0 ]]; do
            if [[ "$M7CM_ASYNC" = 1 ]]; then
                action_server_backup_silent "$1" &
            else
                action_server_backup_silent "$1" 
            fi
            shift
        done
        return 0
    fi
}
action_server_plan() {
    crontab -l | grep "$PATH_SCRIPT backup-silent $SERVER_NAME" 1>/dev/null 2>&1
        if [[ $? = 0 ]]; then
            return 0
        fi
        print_notification 1 "There is no backup schedule for server '$SERVER_NAME' in your crontab"
        print_notification 0 "This is an example which means backup the server '$SERVER_NAME' at 1:00 am every day:"
        echo "0 1 * * * $PATH_SCRIPT backup-silent $SERVER_NAME"
        interactive_yn Y "Should we add the above content to your crontab so you can do a schedule backup for your server?"
        if [[ $? = 1 ]]; then
            if [[ ! -x "$PATH_SCRIPT" ]]; then
                print_notification 2 "The M7CM script is not excutable now, if you want to manually add a backup plan to your crontab, don't forget to do 'chmod +x $PATH_SCRIPT' first"
            fi
            return 4
        fi
        chmod +x "$PATH_SCRIPT"
        (crontab -l 2>/dev/null; echo "0 1 * * * $PATH_SCRIPT backup-silent $SERVER_NAME ${@:2}") | crontab -
        print_notification 1 "Added backup schedule for server '$SERVER_NAME'"
}
# action_server_archive() {

# }
# action_server_archive_silent() {

# }
# action_server_restore() {

# }
action_group_define() {
    if [[ -f "$PATH_DIRECTORY/group/$1.conf" ]]; then
        if [[ ! -w "$PATH_DIRECTORY/group/$1.conf" ]]; then
            print_notification 3 "There's already a group with the same name '$1', and we can not overwrite it due to lacking of writing permission"
            return 1
        fi
        print_notification 2 "There's already a group with the same name '$1'"
        interactive_yn N "Should we overwrite it?" 
        if [[ $? != 0 ]]; then
            return 2 # user give up
        fi
    fi
    > "$PATH_DIRECTORY/group/$1.conf"
    assignment_group "$@"
    if [[ -s "$PATH_DIRECTORY/group/$1.conf" ]]; then
        print_notification 1 "Successfully created group '$1' with the following servers: $(paste -d, -s "$PATH_DIRECTORY/group/$1.conf")"
        return 0
    else
        print_notification 3 "No servers is valid, failed to create group '$1'"
        rm -f "$PATH_DIRECTORY/group/$1.conf"
        return 3
    fi
}
action_group_config() {
    if [[ ! -f "$PATH_DIRECTORY/group/$1.conf" ]]; then
        print_notification 3 "Failed to configure group '$1': group '$1' does not exist"
        return 1
    elif [[ ! -w "$PATH_DIRECTORY/group/$1.conf" ]]; then
        print_notification 3 "Failed to configure group '$1': group '$1' is not writable"
        return 2
    fi
    assignment_group "$@"
    check_validate_group "$1"
    if [[ $? = 0 ]]; then
        print_notification 1 "Successfully configured group '$1', this group now contains server: $(paste -d, -s "$PATH_DIRECTORY/group/$1.conf")"
        return 0
    else
        return 3
    fi
}
action_group_start() {
    if [[ $# = 1 ]]; then
        if [[ ! -f "$PATH_DIRECTORY/group/$1.conf" ]]; then
            print_notification 3 "Failed to start servers in group '$1': group '$1' does not exist"
            return 1
        elif [[ ! -r "$PATH_DIRECTORY/group/$1.conf" ]]; then
            print_notification 3 "Failed to start servers in group '$1': configuration file of group '$1' is not readable"
            return 2
        fi
        check_validate_group "$1"
        if [[ $? = 0 ]]; then
            action_server_start $(paste -d' ' -s "$PATH_DIRECTORY/group/$1.conf")
            return 0
        else
            return 3
        fi
    else
        print_notification 1 "Starting servers in multiple groups: $@"
        while [[ $# -gt 0 ]]; do
            if [[ "$M7CM_ASYNC" = 1 ]]; then
                action_group_start "$1" &
            else
                print_center " Group '$1' " '>' '<'
                print_notification 1 "$# groups left: $@"
                action_group_start "$1"
            fi
            shift
        done
    fi
    return 0
}
action_group_stop() {
    if [[ $# = 1 ]]; then
        if [[ ! -f "$PATH_DIRECTORY/group/$1.conf" ]]; then
            print_notification 3 "Failed to stop servers in group '$1': group '$1' does not exist"
            return 1
        elif [[ ! -r "$PATH_DIRECTORY/group/$1.conf" ]]; then
            print_notification 3 "Failed to stop servers in group '$1': configuration file of group '$1' is not readable"
            return 2
        fi
        check_validate_group "$1"
        if [[ $? = 0 ]]; then
            action_server_stop $(paste -d' ' -s "$PATH_DIRECTORY/group/$1.conf")
            return 0
        else
            return 3
        fi
    else
        print_notification 1 "Stopping servers in multiple groups: $@"
        while [[ $# -gt 0 ]]; do
            if [[ "$M7CM_ASYNC" = 1 ]]; then
                action_group_stop "$1" &
            else
                print_center " Group '$1' " '>' '<'
                print_notification 1 "$# groups left: $@"
                action_group_stop "$1"
            fi
            shift
        done
    fi
    return 0
}
action_group_restart() {
    if [[ $# = 1 ]]; then
        if [[ ! -f "$PATH_DIRECTORY/group/$1.conf" ]]; then
            print_notification 3 "Failed to restart servers in group '$1': group '$1' does not exist"
            return 1
        elif [[ ! -r "$PATH_DIRECTORY/group/$1.conf" ]]; then
            print_notification 3 "Failed to restart servers in group '$1': configuration file of group '$1' is not readable"
            return 2
        fi
        check_validate_group "$1"
        if [[ $? = 0 ]]; then
            action_server_restart $(paste -d' ' -s "$PATH_DIRECTORY/group/$1.conf")
            return 0
        else
            return 3
        fi
    else
        print_notification 1 "Restarting servers in multiple groups: $@"
        while [[ $# -gt 0 ]]; do
            if [[ "$M7CM_ASYNC" = 1 ]]; then
                action_group_restart "$1" &
            else
                print_center " Group '$1' " '>' '<'
                print_notification 1 "$# groups left: $@"
                action_group_restart "$1"
            fi
            shift
        done
    fi
    return 0
}
action_group_send() {
    if [[ ! -f "$PATH_DIRECTORY/group/$1.conf" ]]; then
        print_notification 3 "Failed to send commands to servers in group '$1': group '$1' does not exist"
        return 1
    elif [[ ! -r "$PATH_DIRECTORY/group/$1.conf" ]]; then
        print_notification 3 "Failed to send commands to servers in group '$1': configuration file of group '$1' is not readable"
        return 2
    fi
    check_validate_group "$1"
    local SERVER_COUNT=$(wc -l "$PATH_DIRECTORY/group/$1.conf" | awk '{print $1}')
    if [[ "$SERVER_COUNT" -gt 1 ]]; then
        print_notification 1 "Sending command to multiple servers: $(paste -d, -s "$PATH_DIRECTORY/group/$1.conf")"
    fi
    local SERVER_NAME
    while read SERVER_NAME; do
        # if [[ "$SERVER_COUNT" -gt 1 ]]; then
        #     print_center " Server '$SERVER_NAME' " = = </dev/null
        # fi
        action_server_send "$SERVER_NAME" "${@:2}" </dev/null
    done < "$PATH_DIRECTORY/group/$1.conf"
    return 0
}
action_group_push() {
    if [[ ! -f "$PATH_DIRECTORY/group/$1.conf" ]]; then
        print_notification 3 "Failed to send commands to servers in group '$1': group '$1' does not exist"
        return 1
    elif [[ ! -r "$PATH_DIRECTORY/group/$1.conf" ]]; then
        print_notification 3 "Failed to send commands to servers in group '$1': configuration file of group '$1' is not readable"
        return 2
    fi
    check_validate_group "$1"
    if [[ $? = 0 ]]; then



        action_server_start $(paste -d' ' -s "$PATH_DIRECTORY/group/$1.conf")
        return 0
    else
        return 3
    fi
}
action_group_remove() {
    if [[ $# = 1 ]]; then
        if [[ ! -f "$PATH_DIRECTORY/group/$1.conf" ]]; then
            print_notification 3 "Failed to remove servers in group '$1': group '$1' does not exist"
            return 1
        elif [[ ! -r "$PATH_DIRECTORY/group/$1.conf" ]]; then
            print_notification 3 "Failed to remove servers in group '$1': configuration file of group '$1' is not readable"
            return 2
        fi
        check_validate_group "$1"
        if [[ $? = 0 ]]; then
            interactive_yn N "Are you sure you want to remove all servers in group '$1' from your library? This group contains the following servers: $(paste -d' ' -s "$PATH_DIRECTORY/group/$1.conf")"
            if [[ $? = 0 ]]; then
                action_server_remove $(paste -d' ' -s "$PATH_DIRECTORY/group/$1.conf")
                check_validate_group "$1"
                return 0
            else
                return 3
            fi
        else
            return 4
        fi
    else
        print_notification 1 "Removing servers in multiple groups: $@"
        while [[ $# -gt 0 ]]; do
            print_center " Group '$1' " '>' '<'
            print_notification 1 "$# groups left: $@"
            action_group_remove "$1"
            shift
        done
    fi
    return 0
}
action_group_delete() {
    if [[ $# = 1 ]]; then
        if [[ ! -f "$PATH_DIRECTORY/group/$1.conf" ]]; then
            print_notification 3 "Failed to delete group '$1': group '$1' does not exist"
            return 1
        elif [[ ! -r "$PATH_DIRECTORY/group/$1.conf" ]]; then
            print_notification 3 "Failed to delete group '$1': configuration file of group '$1' is not readable"
            return 2
        fi
        rm -f "$PATH_DIRECTORY/group/$GROUP_NAME.conf"
        print_notification 1 "Deleted group '$1'"
    else
        print_notification 1 "Deleting multiple groups: $@"
        while [[ $# -gt 0 ]]; do
            print_center " Group '$1' " '>' '<'
            print_notification 1 "$# groups left: $@"
            action_group_remove "$1"
            shift
        done
    fi
    return 0 
}
action_group_info() {
    local SERVER_CHECK
    print_notification 1 "Checking server info in group: $@"
    while [[ $# -gt 0 ]]; do
        if [[ ! -f "$PATH_DIRECTORY/group/$1.conf" ]]; then
            print_notification 3 "Failed to check servers information in group '$1': group '$1' does not exist"
        elif [[ ! -r "$PATH_DIRECTORY/group/$1.conf" ]]; then
            print_notification 3 "Failed to check servers information in group '$1': configuration file of group '$1' is not readable"
        else
            check_validate_group "$1"
            if [[ $? = 0 ]]; then
                SERVER_CHECK="$(paste -d' ' -s "$PATH_DIRECTORY/group/$1.conf") $SERVER_CHECK"
            fi
        fi
        shift
    done
    if [[ -z "$SERVER_CHECK" ]]; then
        print_notification 3 "No servers to check"
    else
        action_server_info $SERVER_CHECK
    fi
}
action_group_list() {
    print_draw_line
    print_center "Group List"
    print_draw_line
    ls $PATH_DIRECTORY/group/*.conf 1>/dev/null 2>&1
    if [[ $? != 0 ]]; then
        print_notification 3 "You have not added any group yet. Use '$PATH_SCRIPT group define ...' to define a group first"
        return 1
    fi
    local GROUP_NAME
    local ORDER=1
    for GROUP_NAME in $PATH_DIRECTORY/group/*.conf; do
        GROUP_NAME=$(basename $GROUP_NAME)
        GROUP_NAME=${GROUP_NAME:0:-5}
        print_multilayer_menu "$ORDER. $GROUP_NAME" '' 0
        check_validate_group 1>/dev/null 2>&1
        if [[ $? = 0 ]]; then
            print_multilayer_menu "Members:" "$(paste -d, -s "$PATH_DIRECTORY/group/$GROUP_NAME.conf")" 1 1
        else
            print_multilayer_menu "This group has no valid servers and is already deleted" 1 1
        fi
    done
}
action_version() {
    print_draw_line
    print_center "Minecraft 7 Command-line Manager, a bash-based Minecraft Servers Manager"
    print_center "Version $VERSION, updated at $UPDATE_DATE "
    print_center "Powered by GNU/bash $BASH_VERSION"
    print_draw_line
    return 0
}
action_cli() {
    clear
    print_draw_line
    print_center "M7CM Command-line UI"
    print_draw_line
    print_notification 0 "Some functions in M7CM is only available if their dependencies is detected. e.g. Jar push and pull function is only available if either SCP or SFTP is detected."
    print_multilayer_menu "Current functions status: " '' 0
    if [[ "$ENV_METHOD_DOWNLOAD" = 1 ]]; then
        print_multilayer_menu "Jar download: " "\e[42mOK"
        print_multilayer_menu '' "Current jar download method: $M7CM_METHOD_DOWNLOAD" 2 1
    else
        print_multilayer_menu "Jar download" "\e[41mNot working"
        print_multilayer_menu '' 'Neither wget nor curl detected' 2 1
    fi
    if [[ "$ENV_METHOD_PORT_DIAGNOSIS" = 1 ]]; then
        print_multilayer_menu "Port diagnosis: " "\e[42mOK"
        print_multilayer_menu '' "Current port diagnosis method: $M7CM_METHOD_PORT_DIAGNOSIS" 2 1
    else
        print_multilayer_menu "Port diagnosis: " "\e[41mNot working"
        print_multilayer_menu '' 'Neither GNU/timeout, ncat, nmap nor GNU/wget detected' 2 1
    fi
    if [[ "$ENV_METHOD_PUSH_PULL" = 1 ]]; then
        print_multilayer_menu "Jar push and pull: " "\e[42mOK"
        print_multilayer_menu '' "Current jar push and pull method: $M7CM_METHOD_PUSH_PULL" 2 1
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
        print_multilayer_menu "Spigot building: " "\e[42mOK" 1 1
    else
        print_multilayer_menu "Spigot building:" "\e[41mNot working" 1 1
        print_multilayer_menu '' 'Either java run time environment or git not detected' 2 1 1
    fi
    # if [[ "$ENV_LOCAL_SSH" = 1 && ]]
    print_notification 1 "You've entered command-line UI mode, you can now use arguments in M7CM as commands now, e.g. 'jar list', 'group start mygroup', 'restart myserver', etc."
    print_notification 1 "To exit, use command 'exit'"
    print_notification 2 "YOU CAN NOT INPUT SPACE IN A SINGLE ARGUMENT, even you quote that argument, since M7CM uses read to get your input in Command-line UI mode, and read is limited for that."
    print_notification 0 "Therefore, You CAN NOT edit any configuration to some content with spaces. But you can do that if you are using normal shell script mode. e.g., you can use '$PATH_SCRIPT config my_server \"argument_java = -XX:+UseG1GC -XX:+UseFastAccessorMethods -XX:+OptimizeStringConcat\"' to set argument_java if you're using M7CM the normal way, but you can not simply input 'config my_server \"argument_java = -XX:+UseG1GC -XX:+UseFastAccessorMethods -XX:+OptimizeStringConcat\"' in command-line UI mode."
    print_notification 0 "The above will be recognised as multiple arguments: '\"argument_java','-XX:+UseG1G', etc. And that will be a total mess. You can still config that if you use 'config my_server' to enter the interactive configuration page. Since cli is the only section relying on just read to get your input without identifying it."
    print_notification 1 "Yeah, I could've let M7CM identify your input if i want, but since 1) Command-line UI Mode is just for MANAGEMENT, and management does not require arguments with spaces, and 2) That would slow down the Command-line Mode, which is annoying since I want Command-line UI Mode to be faster and easier than shell script mode."
    print_notification 2 "So, DO NOT imput arguments with space, command-line mode is just for easy multi-server management and other stuff without startup M7CM everytime."
    local COMMAND
    local TUI=1
    while true; do
        read -e -p "[Commnad-line UI @ M7CM]# " COMMAND
        
        main $COMMAND
        if [[ $? = 255 ]]; then
            print_notification 1 "For command help, type 'help'"
        fi
        #interactive_anykey
    done
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
    print_multilayer_menu "exit" "exit M7CM, only useful in command-line UI mode."  
    print_multilayer_menu "cli" "enter the interactive command-line UI, you can then use all actions as commands. this is useful if you want to perform multiple commands." 
    print_multilayer_menu "debug" "enters the debug mode, you can call all functions in M7CM." 
    ## jar related command
    print_multilayer_menu "jar [sub action]" "jar-related commands, [jar] does not incluede the .jar suffix"
    print_multilayer_menu "import* [jar] [link/path]" "import a jar from an online source or local disk, you need GNU/Wget to download the jar" 2
    print_multilayer_menu "push♦ [jar] [server1] [server2] ..." "push the given jar to this server" 2
    print_multilayer_menu "pull♦ [jar] [server] ([remote jar])" "pull the remote jar" 2
    print_multilayer_menu "config [jar] ([option1=value1] [option2=value2] ...)" "" 2
    print_multilayer_menu "build* [jar] [buildtool-jar] ([version])" "build a jar file of the given version using spigot buildtool" 2
    # print_multilayer_menu '' "You need to import or download the [buildtool] first, and configure BUILDTOOL=1 in its configuration. You also need JRE and GIT to build a jar." 3 1
    print_multilayer_menu "remove [jar1] [jar2] ..." "remove a jar and this configuration" 2
    print_multilayer_menu "info [jar1] [jar2] ..." "check the configuration of the jar file" 2
    print_multilayer_menu "list" "lsit all jar files and their configuration" 2 1
    ## account related command
    print_multilayer_menu "account [sub action]" "" 
    print_multilayer_menu "defineΔ [account] [hostname/ip] [ssh port] [user] [private key]" "" 2
    print_multilayer_menu "configΔ [account] ([option1=value1] [option2=value2] ...)" "" 2 
    print_multilayer_menu "remove [account1] [account2] ..." "" 2
    print_multilayer_menu "info [account1] [account2] ..." "" 2
    print_multilayer_menu "list" "" 2 1
    ## server related command
    print_multilayer_menu "(server related actions)" "this section is just for easy identification, you do not need 'server related actions' in your command"
    print_multilayer_menu "defineΔ [server] [account] ([directory] [port] [ram_ram] [ram_min] [jar] [argument_java] [argument_jar] [screen] [stop command])" '' 2
    # print_multilayer_menu '' "(re)define a server so M7CM can manage it. [account] must be defined first. [jar] is the full name, could be absolute path. [extra] for extra arguments. Better to leave all options in () empty and configure it later." 3 1
    # print_multilayer_menu '' "(re)define a server so M7CM can manage it. Better to leave all options in () empty and configure it later." 3 1
    print_multilayer_menu "configΔ [server] ([option1=value1] [option2=value2]" "change one of an existing server" 2
    print_multilayer_menu "start※ [server1] [server2] ..." "start one or multiple pre-defined servers" 2
    print_multilayer_menu "stop※ [server1] [server2] ..." "stop one or multiple pre-defined servers" 2
    print_multilayer_menu "restart※ [server1] [server2] ..." '' 2
    print_multilayer_menu "browse※ [server]" "open the directory of the given server so you can modify it" 2
    print_multilayer_menu "console※ [server] ..." "connect you to the server's console, use Ctrl+A Ctrl+D to get back" 2
    print_multilayer_menu "send※ [server] [command1] [command2] .. " "send command(s), if your command inclues space, quote it so M7CM knows its a single command" 2
    print_multilayer_menu "removeΔ [server1] [server2] ..." '' 2
    print_multilayer_menu "infoΔ [server1] [server2]" '' 2
    print_multilayer_menu "list" '' 2 1
    print_multilayer_menu "backup [sub action]" ""
    print_multilayer_menu "snapshot [server1] [server2] ..." "take a snapshot of the given servers, do a full backup" 2
    print_multilayer_menu "incremental [server1] [server2] ..." "similar as backup, no interaction, no check, only use this after a successful backup" 3 1
    print_multilayer_menu "archive [archived keep day] [non-archived keep day]" "archive all backup data, remove any data older than [keep day], empty for no removal" 2
    print_multilayer_menu "archive-silent" "similar as archive, no interaction, no check, only use this after a successful archive" 3 1
    print_multilayer_menu "plan [hour, 0-23] [day of week, 0-6] [archived keep day] [non-archived keep day] [server1] [server2] ..." "set up schedule backup plan in your crontab" 2
    print_multilayer_menu "restore [server] ([archive name] [new server1] [new server2] ...)" "restore the backup data to the server (no new server specified), or other specified servers" 2 1 
    # print_multilayer_menu "backup-silent [server] ([extra arguments for rsync])" "similar as snapshot, without interaction, for use in crontab only. (You can manually use this, though)" 2
    # print_multilayer_menu '' 'by default, M7CM only keeps non-archived backup data for 7 days, and archived backup data for 28 days. If you want to keep them all, set to 0' 3 1 0 1
    # backup related command
    # print_multilayer_menu "backup [sub action] .." 'incremental '
    # print_multilayer_menu "define [server] ([folder/file1] [folder/file2] ...)" 'if no [folder/file] is given, M7CM will try to backup all folders/files' 2 
    # print_multilayer_menu "now [server] ([backup name]) " "manually backup a server, if [backup-suffix] is not given, M7CM will backup to '[server]-manual-YYMMDD'" 2 
    # print_multilayer_menu "restore [server] ([backup name] [new server])" 'restore the backup data, if [backup name] is not given, use the latest data; if [new server] is given, restore to [new server]' 2 
    # print_multilayer_menu "plan [server] [hour(0-23)] [weekday(0-6)]" 'setup a backup plan (in your crontab)' 2
    # print_multilayer_menu "deplan [server1] [server2] [server3] ..." 'cancel the backup plan (in your crontab)' 2 1
    ## group related commands
    print_multilayer_menu "group [sub action]" "group related action." 1 1
    print_multilayer_menu "define [group] [server1] [server2] ..." "(re)define a group" 2 0 1
    print_multilayer_menu "config [group] [(+/-)server1] [(+/-)server2]..." 'add or remove servers from group' 2 0 1
    print_multilayer_menu "start※ [group]" "" 2 0 1
    print_multilayer_menu "stop※ [group]" "" 2 0 1
    print_multilayer_menu "restart※ [group]"  "" 2 0 1
    print_multilayer_menu "send※ [group] [command1] [command2] ..."  "" 2 0 1
    print_multilayer_menu "removeΔ [group]" "remove all servers in the group and the group itself" 2 0 1
    print_multilayer_menu "delete [group]" "just remove the group itself, keep servers" 2 0 1
    print_multilayer_menu "push♦ [group] [jar]" "push the given jar to all servers in group" 2 0 1
    print_multilayer_menu "infoΔ [group]" "list all servers' information in the given group" 2 1 1
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
action_debug() {
    declare -F
    print_notification 1 "You've entered debug mode, Above is all functions defined in M7CM, you can call them as you like. e.g. action_server_list. Use 'exit' to exit."
    local COMMAND
    while true; do
        read -e -p "[Debug Mode @ M7CM]# " COMMAND
        ${COMMAND}
    done
}
main() {
    if [[ -z "$TUI" ]]; then
        check_startup
    fi
    if [[ $# = 0 ]]; then
        print_notification 3 "Too few arguments!"
        return 255 # Too few arguments
    fi
    case "${1,,}" in 
        help)
            action_help
            ;;
        cli)
            action_cli
            ;;
        debug)
            action_debug
            ;;
        exit)
            if [[ -z "$TUI" ]]; then
                print_notification 4 "This action only works in Command-line UI mode"
            else
                exit
            fi
            ;;
        backup-silent)
            action_server_backup_silent "${@:2}"
            ;;
        archive-silent)
            action_server_archive_silent "${@:2}"
            ;;
        jar) #jar related actions
            if [[ $# -lt 2 ]] || [[ $# -lt 3 && "${2,,}" =~ ^(config|remove|info)$ ]] || [[ $# -lt 4 && "${2,,}" =~ ^(import|build|push|pull)$ ]]; then
                print_notification 3 "Too few arguments"
                return 255  
            elif [[ "${2,,}" != list && "$3" =~ [/\^\/\@\%\(\)\#\\\$\`\"\'\!\&\*\:\;\,\ ] ]]; then
                print_notification 3 "Invalid jar name, the following characters can not be a part of the name: '^/@%()#\\$\`\"'!&*:;, '"
                return
            elif [[ "$ENV_METHOD_PUSH_PULL" = 0 && "${2,,}" =~ ^(push|pull)$ ]]; then
                print_notification 3 "Jar push/pull function disabled. Neither SCP nor SFTP detected."
                return 4
            fi
            #check_environment_local subfolder-jar
            case "${2,,}" in 
                import) #import a local jar #4
                    action_jar_import "${@:3}"
                ;;
                config) #3
                    action_jar_config "${@:3}"
                ;;
                build) # 4
                    action_jar_build "${@:3}"
                ;;
                push) # 4
                    #push a jar to a server
                    action_jar_push "${@:3}"
                ;;
                pull) # 4
                    #pull a jar from a server
                    action_jar_pull "${@:3}"
                ;;
                remove) # 3
                    action_jar_remove "${@:3}"
                ;;
                info) # 3
                    action_jar_info "${@:3}"
                ;;
                list) # 2
                    action_jar_list 
                ;;
                *)
                    print_notification 3 "Unrecognised subaction '$2' for jar"
                    return 255 #wrong command
                ;;
            esac
            ;;
        account)
            if [[ $# -lt 2 ]] || [[ $# -lt 3 && "${2,,}" =~ ^(config|remove|info)$ ]] || [[ $# -lt 7 && "${2,,}" = define ]]; then
                print_notification 3 "Too few arguments"
                return 255  
            elif [[ "${2,,}" != list && "$3" =~ [/\^\/\@\%\(\)\#\\\$\`\"\'\!\&\*\:\;\,\ ] ]]; then
                print_notification 3 "Invalid account name, the following characters can not be a part of the name: '^/@%()#\\$\`\"'!&*:;, '"
                return
            elif [[ "$ENV_LOCAL_SSH" = 0 && "$ENV_METHOD_PUSH_PULL" = 0 && "${2,,}" =~ ^(define|config)$ ]]; then
                print_notification 3 "Account configuration function disabled. Neither SSH nor SCP or SFTP detected."
                return 3
            fi
            # check_environment_local subfolder-account subfolder-server
            #account related actions
            case "${2,,}" in
                define) #7
                    action_account_define "${@:3}"
                    ;;
                config) #3
                    action_account_config "${@:3}"
                    ;;
                remove) #3
                    action_account_remove "${@:3}"
                    ;;
                info) #3
                    action_account_info "${@:3}"
                    ;;
                list) #2
                    action_account_list
                    ;;
                *)
                    print_notification 3 "Unrecognised subaction '$2' for account"
                    return 255 # wrong command
                    ;;
            esac
            ;;
        define|config|browse|start|stop|restart|console|send|remove|info|list|backup|archive|restore) #Serve related  
            if [[ "$M7CM_AGREE_EULA" != 1 ]]; then
                print_notification 3 "You need to agree to the Minecraft EULA in order to use the server management function. Go to 'https://account.mojang.com/documents/minecraft_eula' for more info. If you agree to the Minecraft EULA, set 'AGREE_EULA=1' in config.conf. Once agreed, M7CM will set 'eula=true' in every server it manages, so you don't need to manually edit that for every server."
                return 1
            elif [[ $# = 1 && "${1,,}" != list ]] || [[ $# = 2 && "${1,,}" =~ ^(define|send|restore)$ ]]; then
                print_notification 3 "Too few arguments"
                return 255
            elif [[ "${1,,}" != list && "$2" =~ [/\^\/\@\%\(\)\#\\\$\`\"\'\!\&\*\:\;\,\ ] ]]; then
                print_notification 3 "Invalid server name, the following characters can not be a part of the server name: '^/@%()#\\$\`\"'!&*:;,\ '"
                return 5
            elif [[ "$ENV_LOCAL_SSH" = 0 && "${1,,}" =~ ^(browse|start|stop|restart|console|send|account)$ ]]; then
                print_notification 3 "Remote management function for servers disabled due to lacking of SSH"
                return 1
            elif [[ "$ENV_LOCAL_SSH" = 0 && "$ENV_METHOD_PUSH_PULL" = 0 && "${1,,}" =~ ^(define|config)$ ]]; then
                print_notification 3 "Neither SSH nor SCP or SFTP detected. No server can be defined or configured."
                return 2
            fi
            #check_environment_local subfolder-server subfolder-account
            case "${1,,}" in 
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
                backup)
                    action_server_backup "${@:2}"
                    ;;
                archive)
                    action_server_archive "${@:2}"
                    ;;
                restore)
                    action_server_restore "${@:2}"
                    ;;
            esac
            ;;
        backup) #backup related
            if [[ "$M7CM_AGREE_EULA" != 1 ]]; then
                print_notification 3 "You need to agree to the Minecraft EULA in order to use the server management function. Go to 'https://account.mojang.com/documents/minecraft_eula' for more info. If you agree to the Minecraft EULA, set 'AGREE_EULA=1' in config.conf. Once agreed, M7CM will set 'eula=true' in every server it manages, so you don't need to manually edit that for every server."
                return 1
            elif [[ $# = 2 && "${2,,}" != list ]] || [[ $# = 3 && "${2,,}" =~ ^(define|send)$ ]]; then
                print_notification 3 "Too few arguments"
                return 255
            elif [[ "${2,,}" != list && "$3" =~ [/\^\/\@\%\(\)\#\\\$\`\"\'\!\&\*\:\;\,] ]]; then
                print_notification 3 "Invalid server name, the following characters can not be a part of the server name: '^/@%()#\\$\`\"'!&*:;,\ '"
                return 5
            elif [[ "$ENV_LOCAL_SSH" = 0 && "${2,,}" =~ ^(browse|start|stop|restart|console|send|account)$ ]]; then
                print_notification 3 "Remote management function for servers disabled due to lacking of SSH"
                return 1
            elif [[ "$ENV_LOCAL_SSH" = 0 && "$ENV_METHOD_PUSH_PULL" = 0 && "${2,,}" =~ ^(define|config)$ ]]; then
                print_notification 3 "Neither SSH nor SCP or SFTP detected. No server can be defined or configured."
                return 2
            fi
            case  "${2,,}" in
                define)

                    ;;
                now)

                    ;;
                restore)

                    ;;
                plan)

                    ;;
                deplan)

                    ;;
            esac


            ;;
        group) #group related actions
            if [[ "$M7CM_AGREE_EULA" != 1 ]]; then
                print_notification 3 "You need to agree to the Minecraft EULA in order to use the server management function. Go to 'https://account.mojang.com/documents/minecraft_eula' for more info. If you agree to the Minecraft EULA, set 'AGREE_EULA=1' in config.conf. Once agreed, M7CM will set 'eula=true' in every server it manages, so you don't need to manually edit that for every server."
                return 1
            elif [[ $# -lt 2 ]] || [[ $# -lt 3 && "${2,,}" =~ ^(config|start|stop|restart|remove|delete|info)$ ]] || [[ $# -lt 4 && "${2,,}" =~ ^(define|push|send)$ ]]; then
                print_notification 3 "Too few arguments"
                return 255
            elif [[ "${2,,}" != list && "$3" =~ [/\^\/\@\%\(\)\#\\\$\`\"\'\!\&\*\:\;\,] ]]; then
                print_notification 3 "Invalid group name, the following characters can not be a part of the name: '^/@%()#\\$\`\"'!&*:;, '"
                return
            elif [[ "$ENV_LOCAL_SSH" = 0 && "${2,,}" =~ ^(start|stop|restart|send)$ ]]; then
                print_notification 3 "Remote management function disabled due to lacking of SSH"
                return 1
            fi
            #check_environment_local subfolder-group subfolder-server subfolder-account
            case "${2,,}" in
                define) #4
                    action_group_define "${@:3}"
                    #define a group
                    ;;
                config) #3
                    action_group_config "${@:3}"
                    ;;
                start) #3
                    action_group_start "${@:3}"
                    #start a group
                    ;;
                stop) #3
                    action_group_stop "${@:3}"
                    #stop a group
                    ;;
                restart) #3
                    action_group_restart "${@:3}"
                    #restart a group
                    ;;
                send)
                    action_group_send "${@:3}"
                    ;;
                remove) #3
                    action_group_remove "${@:3}"
                    #remove a group
                    ;;
                delete) #3
                    action_group_delte "${@:3}"
                    ;;
                push) #4
                    if [[ "$ENV_METHOD_PUSH_PULL" = 0 ]]; then
                        print_notification 3 "Jar push/pull function disabled. Neither SCP nor SFTP detected."
                        return 4
                    fi
                    action_group_push "${@:3}"
                    ;;
                info) #3
                    action_group_info "${@:3}"
                    #info of a group
                    ;;
                list) #2
                    action_group_list
                    #list all groups
                    ;;
                *)
                    print_notification 3 "Unrecognised subaction '$2' for group"
                    return 255 # wrong command
                    ;;
            esac
            ;;
        *)
            print_notification 3 "Unrecognised action '$1'"
            return 255 # wrong command
            ;;
    esac
    return 0
}
main "$@"
if [[ $? = 255 ]]; then
    interactive_anykey 'Press any key to show help message'
    action_help
fi
exit