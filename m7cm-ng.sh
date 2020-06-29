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
## Environment related
ENV_SCREEN=0
ENV_WGET=0
ENV_JRE=0
ENV_WGET=0
ENV_SSHD=0
ENV_GIT=0
## JAR related
JAR_NAME=''
JAR_TAG=''
JAR_TYPE=''
JAR_VERSION=''
JAR_VERSION_MC=''
JAR_PROXY=0
JAR_BUILDTOOL=0
JAR_SIZE=0
# ### Minor JAR related 
# LINK=''
# REGEX=''
# PATH=''
## ACCOUNT related
## func: accept arguments, can be used individually
## subfunc: do not accept arguments, can only be used in other funtions
## action: every "action" users can do, i.e. start a server, define a group, etc
## Universal return value: 255 for too few arguments
func_draw_line() {
    ## Usage: func_draw_line [symbol] [length] [not break]
    if [[ -z "$1" ]]; then
        local SYMBOL="-"
    else
        local SYMBOL="$1"
    fi
    if [[ -z "$2" ]]; then
        local LENGTH=`stty size|awk '{print $2}'`
    else
        local LENGTH="$2"
    fi
    for i in $(seq 1 $LENGTH); do
        printf "$SYMBOL"
    done
    [[ -z "$3" ]] && echo
    return 0
} ## Usage: func_draw_line [symbol] [length] [not break]
func_print_center() {
    #usage: func_print_center [string] [left symbol] [right symbol]
    local EMPTY=$(($((`stty size|awk '{print $2}'` - ${#1})) / 2))
    if [[ -z "$2" ]]; then
        func_draw_line " " "$EMPTY" 1
    else
        func_draw_line "$2" "$EMPTY" 1
    fi
    printf "\e[1m"
    printf "$1"
    printf "\e[0m"
    if [[ -z "$3" ]]; then
        func_draw_line " " "$EMPTY"
    else
        func_draw_line "$3" "$EMPTY"
    fi
    return 0
} ## Usage: func_print_center [string] [left symbol] [right symbol]
func_notification() {
    ## func_echo_notification [level] [notification]
    ## Notification levels:
    # 0 Notice: Actually not a notification, nothing is wrong
    # 1 Info: Just tell the user what is wrong , keep running
    # 2 Warning: Something is incorrectly input or set, could be corrected or ignored, keep running
    # 3 Error: Something incorrect happened and cannot be fixed right now, maybe quit to the main thread and encourage the user to fix it
    # 4 Fatal: Something incorrect happened and cannot be fixed, even quiting to the main thread leads to nothing helpful, just exit the whole script.
    case $1 in 
    0)
        printf "\e[42m\e[1mNOTICE\e[0m: "
        ;;
    1)
        printf "\e[44m\e[1mINFO\e[0m: "
        ;;
    2)
        printf "\e[43m\e[1mWARNING\e[0m: "
        ;;
    3)
        printf "\e[45m\e[1mERROR\e[0m: "
        ;;
    4)
        printf "\e[41m\e[1mFATAL\e[0m: "
        ;;
    esac
    echo -e "\e[100m${@:2}\e[0m"
    [[ $1 = 4 ]] && echo "Script exiting..." && exit
    return 0
} ## Usage: func_echo_notification [level] [notification]
func_environment_local() {
    [[ $# = 0 ]] && func_environment_local bash screen wget jre root sshd git basefolder subfolder
    for TMP in $@; do
        case "$TMP" in
        bash)
            [[ -z "$BASH_VERSION" ]] && func_notification 4 "GNU/Bash not detected! You need GNU/Bash to run M7CM."
            ;;
        screen)
            screen -mSUd m7cm_test exit 1>/dev/null 2>&1
            if [[ $? != 0 ]]; then
                func_notification 2 "GNU/Screen not detected on this host. You need GNU/Screen to run and manage servers in background on this host, however you can proceed without installing it if you just want M7CM to manage servers on other hosts.It is still strongly recommended to get GNU/Screen installed to maximize the utility of M7CM."
                ENV_SCREEN=0
            else
                ENV_SCREEN=1
            fi
            ;;
        wget)
            wget --version 1>/dev/null 2>&1
            if [[ $? != 0 ]]; then
                func_notification 2 "GNU/Wget not detected on this host. You need GNU/Wget to download jar files from online resources, however you can proceed without installing it if you just want M7CM to use imported local jar files."
                ENV_WGET=0
            else
                ENV_WGET=1
            fi 
            ;;  
        jre)
            java -version 1>/dev/null 2>&1
            if [[ $? != 0 ]]; then
                func_notification 2 "JAVA Runtime Environment not detected on this host. You need JRE to run servers on this host, however you can proceed without installing it if all your servers are on other hosts."
                ENV_JRE=0
            else
                ENV_JRE=1
            fi 
            ;;  
        root)
            if [[ $UID = 0 ]]; then
                func_notification 2 "You are running M7CM as root. It is strongly recommended to run M7CM with a dedicated account for security concerns."
            fi
            ;;
        sshd)
            pidof sshd 1>/dev/null 2>&1
            if [[ $? != 0 ]]; then
                func_notification 2 "SSH Daemon is not running on this host. Are you running M7CM in a local terminal? Since M7CM use SSH and its pubkey authentication to switch between users for security, you will not be able to run and manage servers on this host"
                ENV_SSHD=0
            else
                ENV_SSHD=1
            fi 
            ;;
        git)
            git --version 1>/dev/null 2>&1
            if [[ $? != 0 ]]; then
                func_notification 2 "Git not found on this host. You will not be able to automatically build Spigot jars."
                ENV_GIT=0
            else
                ENV_GIT=1
            fi
            ;;
        basefolder)
            [[ ! -w "$PATH_DIRECTORY" ]] && func_notification 4 "Script directory $PATH_DIRECTORY not writable."
            [[ ! -r "$PATH_DIRECTORY" ]] && func_notification 4 "Script directory $PATH_DIRECTORY not readable."
            ;;
        subfolder)
            func_environment_local subfolder-server subfolder-jar subfolder-account subfolder-group
            ;;
        subfolder-*)
            local SUBFOLDER=${TMP:10}
            if [[ -d "$PATH_DIRECTORY/$SUBFOLDER" ]]; then
                [[ ! -w "$PATH_DIRECTORY/$SUBFOLDER" ]] && func_notification 4 "Subfolder $SUBFOLDER not writable. script exiting..."
                [[ ! -r "$PATH_DIRECTORY/$SUBFOLDER" ]] && func_notification 4 "Subfolder $SUBFOLDER not readable. script exiting..."
            else
                rm -f "$PATH_DIRECTORY/$SUBFOLDER" 1>/dev/null 2>&1
                mkdir "$PATH_DIRECTORY/$SUBFOLDER" 1>/dev/null 2>&1
                if [[ $? = 0 ]]; then
                    func_notification 1 "Subfolder $SUBFOLDER not existed but successfully created."
                elif [[ ! -w "$PATH_DIRECTORY" ]]; then
                    func_notification 4 "Subfolder $SUBFOLDER not existed and can't be created due to lacking of writing permission of folder $PATH_DIRECTORY."
                elif [[ -f "$PATH_DIRECTORY/$SUBFOLDER" ]]; then
                    func_notification 4 "Subfolder $SUBFOLDER not existed and can't be created due to the existance of a file with the same name and not being able to remove it."
                else
                    func_notification 4 "Subfolder $SUBFOLDER not existed and can't be created due to undetected reasons."
                fi
            fi
            ;;
        esac
    done
    return 0
    [[ ! -w "$PATH_DIRECTORY" ]] && echo -e "\e[31mERROR\e[0m: \e[5mScript directory $PATH_DIRECTORY not writable.\e[0m M7CM exiting..." && exit
    for TEST_FOLDER in "server" "jar" "group" "account"; do
        [[ ! -d "$PATH_DIRECTORY/$TEST_FOLDER" ]] && mkdir "$PATH_DIRECTORY/$TEST_FOLDER" 1>/dev/null 2>&1 && [[ $? != 0 ]] && "\e[31mERROR\e[0m: \e[5mSub folder $TEST_FOLDER not exist and can not be created.\e[0m M7CM exiting..." && exit
        [[ ! -w "$PATH_DIRECTORY/$TEST_FOLDER" ]] && "\e[31mERROR\e[0m: \e[5mSub folder $TEST_FOLDER not writable.\e[0m M7CM exiting..." && exit
    done  
} ## Usage: func_environment_local [environment1] [environment2] | environments: bash screen wget jre root sshd git basefolder subfolder subfolder-* , 0 arguments to check for all 
func_multilayer_expand_menu() {
    local TMP=''
    if [[ -z "$3" ]]; then
        local LAYER="1"
    else
        local LAYER="$3"
    fi
    for i in $(seq 1 $LAYER); do
        printf "  "
        TMP=`eval echo '$'$(( $i + 4 ))` 
        if [[ -z "$TMP" ]]; then
            if [[ $LAYER = $i ]]; then
            ## Draw > for current layer
                if [[ -z "$4" ]]; then
                    printf "┣> "
                else
                    ##Draw L if ends
                    printf "┗> "
                fi
            else
                printf "┃"
            fi
        else
            printf " "
            ##Do not draw | for closed layer
        fi
    done
    ## Print title
    printf "\e[1m$1\e[0m "
    ## Print content
    echo -e "\e[100m$2\e[0m"
} ## Usage: func_multilayer_expand_menu [title] [content] [layer] [end] [no layer1] [no layer2] [...]
func_yn() {
    local CHOICE=''
    while true; do
        if [[ "$1" = "Y" ]]; then
            printf "\e[100mConfirmation:\e[0m ${@:2}(Y/n)"
        elif [[ "$1" = "N" ]]; then
            printf "\e[100mConfirmation:\e[0m ${@:2}(y/N)"
        else
            return 255 #wrong option
        fi
        read -p "" CHOICE
        if [[ "$CHOICE" = "y" || "$CHOICE" = "Y" ]] || [[ -z "$CHOICE" && "$1" = "Y" ]]; then
            return 0
        elif [[ "$CHOICE" = "n" || "$CHOICE" = "N" ]] || [[ -z "$CHOICE" && "$1" = "N" ]]; then
            return 1
        fi
    done
} ## Usage: func_yn [default option, Y/N] [content], return: 0 for yes, 1 for no, 255 for wrong yn
func_jar_config() {
    local CHANGE
    local OPTION
    local VALUE
    for CHANGE in $@; do
        IFS='=' read -r OPTION VALUE <<< "$COMMAND"
        case "$OPTION" in
            NAME|TAG|TYPE|VERSION|VERSION_MC|PROXY|BUILDTOOL)
                eval JAR_$OPTION="$VALUE"
                func_notification 0 "Option '$OPTION' is changed to '$VALUE'"
            *)
                func_notification 1 "Option '$OPTION' not exist or not changable, omitted"
            ;;
        esac
    done
} ## Usage: func_jar_config [option1=value1] [option2=value2]
subfunc_jar_identify() {
    echo "Auto-identifying jar information for $JAR_NAME..." 
    if [[ ENV_JRE = 0 ]]; then
        func_notification 3 "Auto-identifying failed due to lacking of Java Runtime Environment " 
        return 1 # lacking of JRE
    else
        local TMP="/tmp/M7CM-identifying-$JAR_NAME-`date +"%Y-%m-%d-%k:%M"`"
        mkdir "$TMP" && pushd "$TMP"
        JAR_VERSION=$(java -jar "$PATH_DIRECTORY/jar/$JAR_NAME.jar" --version)
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
                        func_notification 3 "The PaperMC pre-patch jar file should download a vanilla jar and patch it. But it seems it failed to patch the vanilla jar. Maybe you should check your network connection."
                        popd
                        rm -rf "$TMP"
                        return 2 ## paper patch error
                    else
                        func_environment_local subfolder-jar
                        JAR_VERSION_MC=${BASENAME:8:-4} && mv -f "$TMP/cache/patched_*.jar" "$PATH_DIRECTORY/jar/$JAR_NAME.jar"
                        JAR_VERSION="git${JAR_VERSION#*git}"
                        func_notification 0 "Successfully patched paper and overwritten existing paper pre-patch jar with post-patch jar"
                    fi
                else    
                    echo "Looks like it contains a Paper game server"
                fi
            else
                JAR_TYPE="$JAR_VERSION"
                JAR_PROXY=0
                JAR_BUILDTOOL=0
                echo "We could not identify the jar's type, using version as its type"
            fi
        else if [[ $RETURN = 1 ]]; then
            if [[ "$JAR_VERSION" =~ "BuildTools" ]]; then
                echo "Looks like it contains Spigot BuildTools"
                echo "Sweet! You can build a spigot jar using $PATH_SCRIPT jar build [jar] [version] $JAR_NAME!"
                JAR_PROXY=0
                JAR_BUILDTOOL=1
                JAR_TYPE="Spigot Buildtools"
                JAR_VERSION="From 1.8"
                JAR_TAG="Sweet! You can build a spigot jar using $PATH_SCRIPT jar build [jar] [version] $JAR_NAME!"
            elif [[ "$JAR_VERSION" =~ "version is not a recognized option" ]]; then
                echo "Looks like it contains a vannila server"
                JAR_PROXY=0
                JAR_BUILDTOOL=0
                JAR_TYPE="Vanilla"
                JAR_VERSION="Unknown"
            elif [[ "$JAR_VERSION" =~ "Error: Invalid or corrupt jarfile" ]]; then
                func_yn Y "The jar file is broken, delete it?"
                if [[ $? = 0 ]]; then
                    rm -f "$PATH_DIRECTORY/jar/$JAR_NAME.jar" "$PATH_DIRECTORY/jar/$JAR_NAME.conf"
                    popd
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
        popd
        rm -rf "$TMP"
        return 0
    fi
} ## Identify the type of the jar file, need $JAR_NAME 
subfunc_jar_info() {
    if [[ ! -f "$PATH_DIRECTORY/jar/$JAR_NAME.conf" ]]; then
        func_notification 3 "Configuration file for jar '$JAR_NAME not exist, maybe you should run '$PATH_SCRIPT jar config $JAR_NAME' first"
        return 1 #config not exist
    else
        local JAR_SIZE=`wc -c $PATH_DIRECTORY/jar/$JAR_NAME.jar |awk '{print $1}'`
        subfunc_jar_config_read
        func_multilayer_expand_menu "SIZE: $JAR_SIZE"
        func_multilayer_expand_menu "TYPE: $JAR_TYPE"
        if [[ ! -z "$JAR_TAG" ]]; then
            func_multilayer_expand_menu "TAG: $JAR_TAG"
        else
            func_multilayer_expand_menu "TAG:" "You have not tagged this jar yet"
        fi
        if [[ $JAR_PROXY = 1 ]]; then
            func_multilayer_expand_menu "PROXY: This jar contains a proxy server" "You can do a multi-host using this proxy"
        else
            func_multilayer_expand_menu "PROXY: X" 
        fi
        if [[ $JAR_BUILDTOOL = 1 ]]; then
            func_multilayer_expand_menu "BUILDTOOL: This jar contains Spigot Buildtools" "You may want to try '$PATH_SCRIPT jar build [jar] $JAR_NAME $VERSION'"
        else
            func_multilayer_expand_menu "BUILDTOOL: X"
        fi
        func_multilayer_expand_menu "VERSION: $JAR_VERSION" "The version of the jar itself"
        func_multilayer_expand_menu "VERSION_MC: $JAR_VERSION_MC" "The version of minecraft servers it can provide" 1 1
        return 0
    fi
} ## Read and print jar configuration. Return: 0 success, 1 not exist
subfunc_jar_config_read() {
    if [[ ! -f $PATH_DIRECTORY/jar/$JAR_NAME.conf ]]; then
        func_notification 3 "Configuration file $JAR_NAME.conf not found, all configuration for jar $JAR_NAME set to default, you may try $PATH_SCRIPT jar config $JAR_NAME to reconfigure it."
        JAR_TAG=''
        JAR_TYPE=''
        JAR_VERSION=''
        JAR_VERSION_MC=''
        JAR_PROXY=0
        JAR_BUILDTOOL=0
        JAR_SIZE=0
        return 1
    fi
    IFS="="
    while read -r NAME VALUE; do
        case "$NAME" in
            JAR_TAG|JAR_PROXY|JAR_VERSION|JAR_VERSION_MC|JAR_BUILDTOOL)
                eval $NAME=$VALUE
            ;;
            *)
                func_notification 1 "Redundant variable $NAME found in jar info file $JAR_NAME.info, ignored"
            ;;
        esac
    done < $PATH_DIRECTORY/jar/$JAR_NAME.conf
    return 0
} ## Safely read jar info, ignore redundant values
subfunc_account_read() {
    if [[ ! -f $PATH_DIRECTORY/account/$ACCOUNT_NAME.account ]]; then
        func_notification 3 "Account file $ACCOUNT_NAME.account not found, use $PATH_SCRIPT account define $ACCOUNT_NAME to define it first."
        return 1
    fi
    IFS="="
    while read -r NAME VALUE; do
        case "$NAME" in
            ACCOUNT_HOST|ACCOUNT_PORT|ACCOUNT_USER|ACCOUNT_KEY)
                eval $NAME=$VALUE
            ;;
            *)
                func_notification 1 "Redundant variable $NAME found in jar info file $JAR_NAME.info, ignored"
            ;;
        esac
    done < $PATH_DIRECTORY/account/$ACCOUNT_NAME.account
    return 0
} ## Safely read account config, ignore redundant values
subfunc_jar_name_fix() {
    while true; do
        local TMP=`echo "${JAR_NAME: -4}" | tr [A-Z] [a-z]`
        if [[ "$TMP" = ".jar" ]]; then
            echo "You jar name has redundant .jar suffix and has been automatically cut"
            JAR_NAME="${JAR_NAME:0:-4}"
        else
            return 0
        fi
    done
} ## Fix jar name, cut out .jar extension
func_ssh_validity() {
    printf "Testing keyfile..."
    if [[ ! -f "$ACCOUNT_KEY" ]; then
        echo "failed"
        echo -e "\e[100m >>> Keyfile not exist\e[0m"
        return 1 # keyfile not exist
    elif [[ ! -r "$ACCOUNT_KEY" ]]; then
        echo "failed"
        echo -e "\e[100m >>> Keyfile unreadable\e[0m"
        return 2 # keyfile unreadable
    else
        echo "success"
        printf "Testing network connectivity..." 
        ping -c3 -i0.4 -w0.8 "$ACCOUNT_HOST" 1>/dev/null 2>&1
        [[ $? != 0 ]] && echo "failed" && echo -e "\e[100m >>> Host unreachable\e[0m" && return 3 # unreachable
        echo "success"
        printf "Testing SSH config validity..."
        ssh "$ACCOUNT_HOST" -p "$ACCOUNT_PORT" -i "$ACCOUNT_KEY" -l "$ACCOUNT_USER" exit 
        [[ $? != 0 ]] && echo "failed" && echo -e "\e[100m >>> Cannot connect via SSH\e[0m" && return 4 # ssh unreachable
        echo "success"
        return 0
    fi
}
func_account_config() {
    local ACCOUNT_VALID=0
    while true; do
        clear
        func_draw_line
        func_print_center "Account Configuration"
        func_draw_line
        echo -e "\e[1mNAME:\e[0m $ACCOUNT_NAME"
        echo -e "\e[1mHOST:\e[0m $ACCOUNT_HOST \e[100mYou must specify a hostname/ip, even your servers are running on the same host as M7CM\e[0m" 
        echo -e "\e[1mPORT:\e[0m $ACCOUNT_PORT \e[100mPort of SSH\e[0m"
        echo -e "\e[1mUSER:\e[0m $ACCOUNT_USER \e[100mUse this account to connect the remote host\e[0m"
        echo -e "\e[1mKEY:\e[0m $ACCOUNT_KEY \e[100mPrivate key to SSH, absolute path\e[0m"
        printf "\n\e[1mVALIDITY:\e[0m "
        [[ $ACCOUNT_VALID = 0 ]] && echo -e "\e[41mINVALID\e[0m"
        [[ $ACCOUNT_VALID = 1 ]] && echo -e "\e[42mVALID\e[0m"
        func_draw_line
        echo -e "\e[4mType in the option you want to change and the new value split by =, i.e.PORT=2222, or KEY=/home/mcManager/keys/server1.key\nYou can also type 'validate' to let M7CM identify it, or 'confirm' to confirm these values\e[0m"
        read -p ">>>" COMMAND
        case "$COMMAND" in
            validate)
                func_ssh_validity
                [[ $? = 0 ]] && ACCOUNT_VALID=1
                read -n 1 -s -r -p "Press any key to continue..."
            ;;
            confirm)
                if [[ $ACCOUNT_VALID = 0 ]]; then
                    echo -e "\e[31mWARNING\e[0m: \e[5m\e[1mYou must validate this account first \e[0m\c"
                    read -n 1 -s -r -p "Press any key to continue..."
                else
                    echo "Proceeding to write values to config file...."
                    echo "## Configuration for account $ACCOUNT_NAME, DO NOT EDIT THIS UNLESS YOU KNOW WHAT YOU ARE DOING" > "$PATH_DIRECTORY/account/$ACCOUNT_NAME.account"
                    echo "ACCOUNT_HOST=\"$ACCOUNT_HOST\"" >> "$PATH_DIRECTORY/account/$ACCOUNT_NAME.account"
                    echo "ACCOUNT_PORT=\"$ACCOUNT_PORT\"" >> "$PATH_DIRECTORY/account/$ACCOUNT_NAME.account"
                    echo "ACCOUNT_USER=\"$ACCOUNT_USER\"" >> "$PATH_DIRECTORY/account/$ACCOUNT_NAME.account"
                    echo "ACCOUNT_KEY=\"$ACCOUNT_KEY\"" >> "$PATH_DIRECTORY/account/$ACCOUNT_NAME.account"
                    return 0
                fi
            ;;
            *)
                local OPTION=''
                local VALUE=''
                IFS='=' read -r OPTION VALUE <<< "$COMMAND"
                ACCOUNT_VALID=0
                case "$OPTION" in
                    HOST|PORT|USER|KEY)
                        eval ACCOUNT_$OPTION="$VALUE"
                    ;;
                    NAME)
                        "$VALUE"
                        if [[ -f "$PATH_DIRECTORY/account/$VALUE.account" ]]; then
                            echo "\e[31mWARNING\e[0m: \e[1mA An account with the same name has already exist, renaming aborted. \e[0m\c"
                            read -n 1 -s -r -p "Press any key to continue..."
                        elif [[ -f "$PATH_DIRECTORY/account/$ACCOUNT_NAME.account" ]]; then
                            mv "$PATH_DIRECTORY/account/$ACCOUNT_NAME.account" "$PATH_DIRECTORY/account/$VALUE.account"
                            ACCOUNT_NAME=$VALUE
                        fi
                    ;;
                    *)
                        echo -e "\e[31mWARNING\e[0m: \e[5m\e[1mInput not recognized! \e[0m\c"
                        read -n 1 -s -r -p "Press any key to continue..."
                    ;;
                esac
            ;;
        esac
    done
}
action_jar_import() {
    if [[ $# -lt 2 ]]; then
        func_notification 3 "Too few arguments!"
        action_help
        return 255 # Too few arguments
    fi
    func_environment_local subfolder-jar
    local JAR_NAME="$1"
    subfunc_jar_name_fix
    if [[ -f "$PATH_DIRECTORY/jar/$JAR_NAME.jar" ]]; then
        func_yn N "A jar with the same name $JAR_NAME has already been defined, you will overwrite this jar file. Are you sure you want to overwrite it?"
        if [[ $? = 1 ]]; then
            return 1 ## Aborted overwriting
        fi
        elif [[ ! -w "$PATH_DIRECTORY/jar/$JAR_NAME.jar" ]]; then
            func_notification 3 "No permission to overwrite $JAR_NAM.jar, importing failed. check your permission"
            return 2 ## already exist and can not overwrite
        fi
    fi
    if [[ -f "$2" ]]; then
        local TMP=`echo "${2: -4}" | tr [A-Z] [a-z]`
        if [[ "$TMP" != ".jar" ]]; then
            func_notification 1 "The file extension of this file is not .jar, maybe you've input a wrong file, but M7CM will try to import it anyway"
        elif [[ ! -r "$2" ]]; then
            func_notification 3 "No read permission for file $2, importing failed. check your permission"
            return 3 ## No read permission for local file
        else
            \cp -f "$PATH" "$PATH_DIRECTORY/jar/$JAR_NAME.jar"
            if [[ $? != 0 ]]; then
                func_notification 3 "Failed to copy file $2, importing failed"
                return 4 ## failed to copy. wtf is that reason?
            else
                local JAR_TAG="Imported at `date +"%Y-%m-%d-%k:%M"` from local source $2"
            fi
        fi
    else
        local REGEX='(https?|ftp|file)://[-A-Za-z0-9\+&@#/%?=~_|!:,.;]*[-A-Za-z0-9\+&@#/%=~_|]'
        if [[ "$LINK" =~ $REGEX ]]; then
            wget -O "$PATH_DIRECTORY/jar/$JAR_NAME.jar" "$2"
            if [[ $? != 0 ]]; then
                func_notification 3 "Failed to download file $2, importing failed. check your network connection"
                return 5
            else
                local JAR_TAG="Imported at `date +"%Y-%m-%d-%k:%M"` from online source $2"
            fi
        else
            func_notification 3 "$2 is not an existing local file nor a valid url, importing failed"
            return 6
        fi
    fi
    func_notification 0 "Importing success! Proceeding to configure it in 3 seconds."
    sleep 1
    func_notification 0 "Importing success! Proceeding to configure it in 2 seconds.."
    sleep 1
    func_notification 0 "Importing success! Proceeding to configure it in 1 seconds..."
    sleep 1
    action_jar_config $JAR_NAME 1 "TAG=$JAR_TAG"
} ## Usage: action_jar_download [jar name] [link/path]
    ## return: 0 success, 1 abort overwriting, 2 already exist and can not overwrite, 3 no read permission for local source, 4 failed to copy, 5 failed to cownload, 6 invalid source
action_jar_config() {
    if [[ $# = 0 ]]; then
        func_notification 3 "Too few arguments!"
        action_help
        return 255 # Too few arguments
    fi
    func_environment_local subfolder-jar
    local JAR_NAME="$1"
    subfunc_jar_name_fix
    if [[ ! -f "$PATH_DIRECTORY/jar/$JAR_NAME.jar" ]]; then
        func_notification 3 "Jar '$JAR_NAME' does not exist, failed to configure it"
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
            func_notification 3 "Strange things happended. Configuration file of jar '$JAR_NAME' is not writable now, thus we can not edit it."
            return 2 # existing configuration not writable
        elif [[ ! -r "$PATH_DIRECTORY/jar/$JAR_NAME.conf" ]]; then
            func_notification 2 "What magic! We can not read existing configuration file for jar '$JAR_NAME', did you edited it as other users?"
            ## still proceed
        else
            subfunc_jar_config_read
        fi
    fi
    if [[ ! -z "$3" ]]; then
        func_jar_config ${@:3}
    fi
    if [[ ! -z "$2" || ! -f "$PATH_DIRECTORY/jar/$JAR_NAME.conf" ]]; then
        func_notification 1 "Looks like this jar is just added to our library or its configuration file has been lost, proceeding to auto-identify it"
        subfunc_jar_identify 
    fi
    ## Get jar size
    local JAR_SIZE=`wc -c $PATH_DIRECTORY/jar/$JAR_NAME.jar |awk '{print $1}'`
    ## Interactive-menu
    while true; do
        clear
        func_draw_line
        func_print_center "Configuration for Jar File '$JAR_NAME'"
        func_draw_line
        func_multilayer_expand_menu "NAME: $JAR_NAME" "" 0
        func_multilayer_expand_menu "SIZE: $JAR_SIZE" "UNCHANGABLE"
        func_multilayer_expand_menu "TAG: $JAR_TAG" 
        func_multilayer_expand_menu "TYPE: $JAR_TYPE" "What kind of jar it is, i.e. Spigot, Paper, Vanilla. Only for memo."
        func_multilayer_expand_menu "PROXY: $JAR_PROXY" "If it contains a proxy server, i.e. Waterfall, Bungeecord. Accept: 0/1"
        func_multilayer_expand_menu "BUILDTOOL: $JAR_BUILDTOOL" "Whether it contains Spigot buildtools. Accept: 0/1"
        func_multilayer_expand_menu "VERSION: $JAR_VERSION" "The version of the jar itself"
        func_multilayer_expand_menu "VERSION_MC: $JAR_VERSION_MC" "The version of Minecraft this jar can host" 1 1
        func_draw_line
        echo "Type in the option you want to change and its new value split by =, without quote. i.e. 'TAG=This is my first jar!' You can also type 'identify' to let M7CM identify it, or 'confirm' to confirm thost values:"
        read -p ">>>" COMMAND
        case "$COMMAND" in
            identify)
                subfunc_jar_identify
                if [[ $? = 3 ]]; then
                    return 3 ## jar broken and deleted
                fi
            ;;
            confirm)
                echo "Proceeding to write values to config file...."
                echo "## Configuration for jar file '$JAR_NAME', DO NOT EDIT THIS UNLESS YOU KNOW WHAT YOU ARE DOING" > "$PATH_DIRECTORY/jar/$JAR_NAME.conf"
                echo "JAR_TAG=\"$JAR_TAG\"" >> "$PATH_DIRECTORY/jar/$JAR_NAME.conf"
                echo "JAR_TYPE=\"$JAR_TYPE\"" >> "$PATH_DIRECTORY/jar/$JAR_NAME.conf"
                echo "JAR_BUILDTOOL=\"$JAR_BUILDTOOL\"" >> "$PATH_DIRECTORY/jar/$JAR_NAME.conf"
                echo "JAR_PROXY=\"$JAR_PROXY\"" >> "$PATH_DIRECTORY/jar/$JAR_NAME.conf"
                echo "JAR_VERSION=\"$JAR_VERSION\"" >> "$PATH_DIRECTORY/jar/$JAR_NAME.conf"
                echo "JAR_VERSION_MC=\"$JAR_VERSION_MC\"" >> "$PATH_DIRECTORY/jar/$JAR_NAME.conf"
                return 0 # success
            ;;
            *)
                local OPTION=
                local VALUE=
                IFS='=' read -r OPTION VALUE <<< "$COMMAND"
                case "$OPTION" in
                    TAG|TYPE|VERSION|VERSION_MC)
                        eval JAR_$OPTION="$VALUE"
                    ;;
                    PROXY|BUILDTOOL)
                        if [[ "$OPTION" = "0" ]]; then
                            eval JAR_$OPTION=0
                        else
                            eval JAR_$OPTION=1
                        fi
                    ;;
                    NAME)
                        if [[ -f "$PATH_DIRECTORY/jar/$VALUE.jar" ]]; then
                            if [[ ! -w "$PATH_DIRECTORY/jar/$VALUE.jar" || ! -w "$PATH_DIRECTORY/jar/$VALUE.conf" ]]; then
                                func_notification 2 "A jar with the same name '$VALUE' has already exist and can't be overwriten due to lack of writing permission. Check your permission."
                            else
                                func_yn N "A jar with the same name '$VALUE' has already exist, are you sure you want to overwrite it?"
                                if [[ $? = 0 ]]; then
                                    mv -f "$PATH_DIRECTORY/jar/$JAR_NAME.jar" "$PATH_DIRECTORY/jar/$VALUE.jar"
                                    mv -f "$PATH_DIRECTORY/jar/$JAR_NAME.conf" "$PATH_DIRECTORY/jar/$VALUE.conf" 1>/dev/null 2>&1
                                    JAR_NAME="$VALUE"
                                fi
                            fi  
                        else
                            mv "$PATH_DIRECTORY/jar/$JAR_NAME.jar" "$PATH_DIRECTORY/jar/$VALUE.jar"
                            mv -f "$PATH_DIRECTORY/jar/$JAR_NAME.conf" "$PATH_DIRECTORY/jar/$VALUE.conf" 1>/dev/null 2>&1
                            JAR_NAME="$VALUE"
                        fi
                    ;;
                    *)
                        func_notification 2 "Input not recognized."
                        read -n 1 -s -r -p "Press any key to refresh..."
                    ;;
                esac
            ;;
        esac
    done
    fi
    
} ## Usage: action_jar_config [jar name] [auto-identify(any value)] [option1=value1] [option2=value2]
    ## return: 0 success, 1 not exist, 2 existing configuration not writable, 3 jar broken and deleted
action_jar_info() {
    if [[ $# = 0 ]]; then
        func_notification 3 "Too few arguments!"
        action_help
        return 255 # Too few arguments
    fi
    func_environment_local subfolder-jar
    local JAR_NAME="$1"
    subfunc_jar_name_fix
    if [[ ! -f "$PATH_DIRECTORY/jar/$JAR_NAME.jar" ]]; then
        func_notification 3 "The jar file '$JAR_NAME' does not exist"
        return 1 #invalid jar
    else
        func_multilayer_expand_menu "<※> $JAR_NAME" "" 0
        subfunc_jar_info
    fi
    return 0
} ## Usage: action_jar_info [jar name]
    ## return: 0 success, 1 not exist
action_jar_list() {
    func_environment_local subfolder-jar
    local JAR_NAME=''
    local ORDER=1
    for JAR_NAME in $(ls $PATH_DIRECTORY/jar/*.jar); do
        JAR_NAME=$(basename $JAR_NAME)
        JAR_NAME=${JAR_NAME:0:-4}
        func_multilayer_expand_menu "<$ORDER> $JAR_NAME" "" 0
        subfunc_jar_info
    done
    return 0
} ## Usage: action_jar_list. NO ARGUMENTS. return: 0 success
action_jar_remove() {
    if [[ $# = 0 ]]; then
        func_notification 3 "Too few arguments!"
        action_help
        return 255 # Too few arguments
    fi
    func_environment_local subfolder-jar
    local JAR_NAME="$1"
    subfunc_jar_name_fix
    if [[ ! -f "$PATH_DIRECTORY/jar/$JAR_NAME.jar" ]]; then
        func_notification 3 "The jar you specified does not exist!"
        return 1 ## not exist
    elif [[ ! -w "$PATH_DIRECTORY/jar/$JAR_NAME.jar" ]]; then
        func_notification 3 "Removing failed due to lacking of writing permission of jar file '$JAR_NAME.jar'"
        return 2 ## jar not writable 
    elif [[ ! -w "$PATH_DIRECTORY/jar/$JAR_NAME.conf" ]]; then
        func_notification 3 "Removing failed due to lacking of writing permission of configuration file '$JAR_NAME.conf'"
        return 3 ## configuration not writable 
    else
        rm -f "$PATH_DIRECTORY/jar/$JAR_NAME.jar"
        rm -f "$PATH_DIRECTORY/jar/$JAR_NAME.jar" 1>/dev/null 2>&1
        echo "Removed jar '$JAR_NAME' from library"
        return 0
    fi
} ## Usage: action_jar_remove [jar name]. return: 0 success, 1 not exist, 2 jar no writable, 3 conf not writable,
action_jar_build() {
    if [[ $# -lt 2 ]]; then
        action_help
        func_notification 3 "Too few arguments!"
        return 255 # Too few arguments
    fi
    func_environment_local jre git subfolder-jar
    if [[ ENV_JRE = 0 ]]; then
        func_notification 3 "Spigot build function is not available due to lacking of Java Runtime Environment"
        return 1 #environment error-jre
    elif [[ ENV_GIT = 0 ]]; then
        func_notification 3 "Spigot build function is not available due to lacking of Git"
        return 2 #environment error-git
    else
        local JAR_NAME="$2"
        if [[ ! -f "$PATH_DIRECTORY/jar/$JAR_NAME.jar" ]]; then
            func_notification 3 "The buildtool you set does not exist"
            return 3 #buildtool not exist
        else
            local JAR_TAG=''
            local JAR_TYPE=''
            local JAR_VERSION=''
            local JAR_VERSION_MC=''
            local JAR_PROXY=0
            local JAR_BUILDTOOL=0
            subfunc_jar_name_fix
            subfunc_jar_config_read
            if [[ $JAR_BUILDTOOL != 1 ]]; then
                func_notification 3 "The buildtool you set was not set as a buildtool"
                return 4 # not a buildtool
            else
                local BUILDTOOL="$JAR_NAME"
                JAR_NAME="$1"
                if [[ -z "$3" || "$3" = "latest" ]]; then
                    local VERSION="latest"
                elif [[ "$3" =~ "1." ]]; then
                    local VERSION2
                    local VERSION3
                    read -r VERSION2 VERSION3 <<< "$COMMAND"
                    if [[ "$VERSION2" -ge 8 && "$VERSION3" -le 8 ]]; then
                        local VERSION="$3"
                    else
                        func_yn N "The version '$3' seems not a correct version, do you want to proceed anyway?"
                        if [[ $? = 1 ]]; then
                            local VERSION="$3"
                        else
                            return 5 # user aborted because of suspicious version
                        fi
                    fi
                else
                    func_yn N "The version '$3' seems not a correct version, do you want to proceed anyway?"
                    if [[ $? = 1 ]]; then
                        local VERSION="$3"
                    else
                        return 5 # user aborted because of suspicious version
                    fi
                fi
                local TMP="/tmp/M7CM-build-$JAR_NAME-`date +"%Y-%m-%d-%k:%M"`"
                mkdir "$TMP" && pushd "$TMP"
                java -jar "$PATH_DIRECTORY/jar/$BUILDTOOL.jar" --rev $VERSION
                if [[ $? != 0 ]]; then
                    func_notification 3 "Failed to build Spigot version $BUILD_VERSION"
                    popd
                    rm -rf "$TMP"
                    return 6 #build error
                else
                    local OUTPUT=`ls spigot-*.jar | awk '{print $1}'`
                    cp "$OUTPUT" "$PATH_DIRECTORY/jar/$JAR_NAME.jar"
                    popd
                    rm -rf "$TMP"
                    func_notification 0 "Building success! Proceeding to configure it in 3 seconds."
                    sleep 1
                    func_notification 0 "Building success! Proceeding to configure it in 2 seconds.."
                    sleep 1
                    func_notification 0 "Building success! Proceeding to configure it in 1 seconds..."
                    sleep 1
                    action_jar_config $JAR_NAME "" "TAG=Built at `date +"%Y-%m-%d-%k:%M"` using M7CM" "TYPE=Spigot" "PROXY=0" "VERSION=Spigot-$VERSION" "VERSION_MC=$VERSION" "BUILDTOOL=0"
                    return 0
                fi
            fi
        fi
    fi
} ## Usage: action_jar_build [jar name] [buildtool] [version]
    ## Return: 0 success 1 environment error-jre 2 environment error-git, 3 buildtool not exist, 4 not a buildtool, 5 user aborted because of suspicious version, 6 build error,


action_account_define() {
    local ACCOUNT_NAME="$1"
    local ACCOUNT_HOST="$2"
    local ACCOUNT_PORT="$3"
    [[ -z "$3" ]] && ACCOUNT_PORT="22"
    local ACCOUNT_USER="$4"
    [[ -z "$4" ]] && ACCOUNT_USER="$USER"
    local ACCOUNT_KEY="$5"
    func_account_config "$ACCOUNT_NAME"
}
action_account_config() {
    local ACCOUNT_NAME="$1"
    local ACCOUNT_HOST=''
    local ACCOUNT_PORT=''
    local ACCOUNT_USER=''
    local ACCOUNT_KEY=''
    [[ ! -f "$PATH_DIRECTORY/account/$ACCOUNT_NAME.account" ]] && echo -e "\e[31mWARNING\e[0m: The account $ACCOUNT_NAME does not exist" && return 1 #invalid jar
    subfunc_account_safely_read "$ACCOUNT_NAME"
    func_account_config "$ACCOUNT_NAME"
}
action_account_remove() {
    
}
action_help() {
    echo "$PATH_SCRIPT"
    func_multilayer_expand_menu "help" "print this help message" 
    func_multilayer_expand_menu "define [server] [account] [jar] [user] [directory] [max ram] [min ram]" "(re)define a server so M7CM can manage it." 
    func_multilayer_expand_menu "config [server] [option] [value]" "change one specific option you defined by $PATH_SCRIPT define" 
    func_multilayer_expand_menu "start [server1] [server2] ..." "start one or multiple pre-defined servers" 
    func_multilayer_expand_menu "stop [server1] [server2] ..." "stop one or multiple pre-defined servers" 
    func_multilayer_expand_menu "restart [server1] [server2] ..." 
    func_multilayer_expand_menu "browse [server]" "open the directory of the given server so you can modify it" 
    func_multilayer_expand_menu "console [server] ..." "connect you to the server's console" 
    func_multilayer_expand_menu "send [server] [command]" "send a command" 
    func_multilayer_expand_menu "remove [server]"
    func_multilayer_expand_menu "status [server]"
    func_multilayer_expand_menu "group [sub action]" "group related action. m7cm have a reserverd group _ALL_ for all servers you defined"
    func_multilayer_expand_menu "define [group] [server1] [server2] ..." "(re)define a group" 2
    func_multilayer_expand_menu "start [group]" "" 2
    func_multilayer_expand_menu "stop [group]" "" 2
    func_multilayer_expand_menu "restart [group]"  "" 2
    func_multilayer_expand_menu "remove [group]" "remove all servers in the group and the group itself" 2
    func_multilayer_expand_menu "delete [group]" "just remove the group itself, keep servers" 2
    func_multilayer_expand_menu "push [group] [jar]" "push the given jar to all servers in group" 2
    func_multilayer_expand_menu "status [group]" "list all servers' status in the given group" 2 1
    func_multilayer_expand_menu "jar [sub action]" "jar-related commands, [jar] does not incluede the .jar suffix"
    func_multilayer_expand_menu "import [jar] [link/path]" "import a jar from an online source or local disk, you need GNU/Wget to download the jar" 2
    func_multilayer_expand_menu "push [jar] [server]" "push the given jar to this server" 2
    func_multilayer_expand_menu "pull [jar] [server] [remote jar]" "pull the remote jar, use fullname" 2
    func_multilayer_expand_menu "config [jar]" "change the configuration of the jar" 2
    func_multilayer_expand_menu "build [jar] [buildtool-jar] [version]" "build a jar file of the given version using spigot buildtool, you need to import or download the buildtool first" 2
    func_multilayer_expand_menu "remove [jar name]" "remove a jar and this configuration" 2
    func_multilayer_expand_menu "info [jar]" "check the configuration of the jar file" 2
    func_multilayer_expand_menu "list" "lsit all jar files and their configuration" 2 1
    func_multilayer_expand_menu "account [sub action]" "" 1 1
    func_multilayer_expand_menu "define [account] [hostname/ip] [ssh port] [user] [private key]" "" 2 "" 1
    func_multilayer_expand_menu "config [account]" "" 2 "" 1
    func_multilayer_expand_menu "remove [account]" "" 2 1 1

    func_notification 0 "Any [account] used by a server must have been pre-defined by $PATH_SCRIPT account define, M7CM will use SSH to connect to this host and perform management. Even though you want to run and manage servers on the same host as M7CM, you still need to use SSH to ensure both the isolation and the security. Notice that the [account] here is just for easy memorizing, and does not have to be the same as [user]"
    func_notification 0 "Any [jar] used by a server must have been pre-imported by $PATH_SCRIPT import, or you can use remote:[full name with file extension] to refer to a jar file in the directory of the server (will be renamed to server.jar and import into jar library with the same name of the server then)"
    func_notification 0 "M7CM has a reserverd server named _LAST_ refering to the last server you've successfully managed and also a reserverd group _LAST_. there's also a reserverd group named _ALL_ contains all servers"
    func_notification 0 "To build a spigot jar using a spigot buildtool, you need import a buildtool first, configure it to be recognized as a buildtool, and got jre and git installed."
}
action_version() {
    func_draw_line
    func_print_center "Minecraft 7 Command-line Manager, a bash-based Minecraft Servers Manager"
    func_print_center "Version $VERSION, updated at $UPDATE_DATE "
    func_print_center "Powered by GNU/bash $BASH_VERSION"
    func_draw_line
}
main() {
    func_environment_check_pre_run
    [[ $# = 0 ]] && action_help && exit
    case "$1" in 
        define)
            echo "defining"
        ;;
        config)
            echo "configing"
        ;;
        browse)
            echo "browsing"
        ;;
        start)
            echo "starting"
        ;;
        stop)
            echo "stopping"
        ;;
        restart)
            echo "restarting"
        ;;
        console)
            echo "to console"
        ;;
        send)
            echo "send command"
        ;;
        remove)
            echo "removing server"
        ;;
        status)
            echo "checking status"
        ;;
        group)
            shift
            #group related actions
            case "$2" in
                define)
                    #define a group
                ;;
                start)
                    #start a group
                ;;
                stop)
                    #stop a group
                ;;
                restart)
                    #restart a group
                ;;
                remove)
                    #remove a group
                ;;
                info)
                    #info of a group
                ;;
                list)
                    #list all groups
                ;;
            esac
        ;;
        jar)
            #jar related actions
            case "$2" in 
                import)
                    #import a local jar
                    action_jar_import "${@:3}"
                ;;
                push)
                    #push a jar to a server
                    action_jar_push "${@:3}"
                ;;
                pull)
                    #pull a jar from a server
                    action_jar_pull "${@:3}"
                ;;
                config)
                    action_jar_config "${@:3}"
                ;;
                build)
                    action_jar_build "${@:3}"
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
                    action_help
                    return 1 #Unrecognized
                ;;
            esac
        ;;
        account)
            #account related actions
            case "$2" in
                define)
                    action_account_define "$3" "$4" "$5" "$6" "$7"
                ;;
                config)
                    action_account_config "$3"
                ;;
                remove)
                    action_account_remove "$3"
                ;;
            esac
        *)
            action_help && return
        ;;
    esac
}
main && exit