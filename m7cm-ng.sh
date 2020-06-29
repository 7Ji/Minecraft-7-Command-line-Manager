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

SCREEN_WIDTH=`stty size|awk '{print $2}'`

# Clear all variables
## JAR related
JAR_NAME=''
JAR_TAG=''
JAR_TYPE=''
JAR_VERSION=''
JAR_VERSION_MC=''
JAR_PROXY=0
JAR_BUILDTOOL=0
### Minor JAR related 
LINK=''
REGEX=''
PATH=''
## ACCOUNT related

func_draw_line() {
    ## Usage: func_draw_line [character] [length] [not break]
    local CHARACTER="$1"
    [[ -z "$1" ]] && local CHARACTER="-"
    local LENGTH="$2"
    [[ -z "$2" ]] && LENGTH=`stty size|awk '{print $2}'`
    for i in $(seq 1 $LENGTH ); do
        printf "$CHARACTER"
    done
    ## only break if $3 is empty, keep in the same line if not
    [[ -z "$3" ]] && echo
}
func_print_center() {
    #usage: func_print_center [string] [left character] [right character]
    SCREEN_WIDTH=`stty size|awk '{print $2}'`
    local EMPTY=$(($(($SCREEN_WIDTH - ${#1})) / 2))
    local CHARACTER_LEFT="$2"
    local CHARACTER_RIGHT="$3"
    [[ -z "$2" ]] && CHARACTER_LEFT=" "
    [[ -z "$3" ]] && CHARACTER_RIGHT=" "
    func_draw_line "$CHARACTER_LEFT" "$EMPTY" 1
    printf "\e[1m"
    printf "$1"
    printf "\e[0m"
    func_draw_line "$CHARACTER_RIGHT" "$EMPTY"
}

func_get_arguments() {

}

func_print_title() {
    func_draw_line
    echo "Minecraft 7 Command-line Manager, a bash-based Minecraft Servers Manager"
    echo "Version $VERSION, updated at $UPDATE_DATE "
    echo "Running with GNU bash $BASH_VERSION"
    func_draw_line
}
func_environment_check_pre_run() {
    ENV_SCREEN=1
    ENV_WGET=1
    ENV_JRE=1
    ENV_WGET=1
    ENV_SSHD=1
    ENV_GIT=1
    [[ -z "$BASH_VERSION" ]] && echo  "WARNING: GNU/Bash not detected! You need GNU/Bash to run M7CM, script exiting..." && exit
    screen -mSUd m7cm_test echo "testing" 1>/dev/null 2>&1
    [[ $? != 0 ]] && echo -e "\e[31mWARNING\e[0m: \e[5m\e[1mGNU/Screen\e[0m \e[5mnot detected on this host.\e[0m\n -> You need \e[1mGNU/Screen\e[0m to run and manage servers in background on this host, however you can proceed without installing it if you just want M7CM to manage servers on other hosts. \e[4mIt is still strongly recommended to get GNU/Screen installed to maximize the utility of M7CM\e[0m." && ENV_SCREEN=0
    wget --version 1>/dev/null 2>&1
    [[ $? != 0 ]] && echo -e "\e[33mINFO\e[0m: \e[5m\e[1mGNU/Wget\e[0m \e[5mnot detected on this host.\e[0m\n -> You need \e[1mGNU/Wget\e[0m to download jar files, however you can proceed without installing it if you just want M7CM to use imported local jar files" && ENV_WGET=0
    java -version 1>/dev/null 2>&1
    [[ $? != 0 ]] && echo -e "\e[33mINFO\e[0m: \e[5m\e[1mJAVA Runtime Environment\e[0m \e[5mnot detected on this host.\e[0m\n -> You need \e[1mJRE\e[0m to run servers on this host, however you can proceed without installing it if all your servers are on other hosts." && ENV_JRE=0
    [[ $UID = 0 ]] && echo -e "\e[31mWARNING\e[0m: \e[5mYou are running M7CM as root.\e[0m It is strongly recommended to run M7CM with a dedicated account"
    pidof sshd 1>/dev/null 2>&1
    [[ $? != 0 ]] && echo -e "\e[33mINFO\e[0m: \e[5mSSH Daemon is not running on this host.\e[0m Since M7CM use ssh to switch between users, you will not be able to run and manage servers on this host" && ENV_SSHD=0
    git --version 1>/dev/null 2>&1
    [[ $? != 0 ]] && echo -e "\e[31mWARNING\e[0m: \e[5mGit not found on this host. You will not be able to build jars using Spigot buildtool" && ENV_GIT=0
    [[ ! -w "$PATH_DIRECTORY" ]] && echo -e "\e[31mERROR\e[0m: \e[5mScript directory $PATH_DIRECTORY not writable.\e[0m M7CM exiting..." && exit
    for TEST_FOLDER in "server" "jar" "group" "account"; do
        [[ ! -d "$PATH_DIRECTORY/$TEST_FOLDER" ]] && mkdir "$PATH_DIRECTORY/$TEST_FOLDER" 1>/dev/null 2>&1 && [[ $? != 0 ]] && "\e[31mERROR\e[0m: \e[5mSub folder $TEST_FOLDER not exist and can not be created.\e[0m M7CM exiting..." && exit
        [[ ! -w "$PATH_DIRECTORY/$TEST_FOLDER" ]] && "\e[31mERROR\e[0m: \e[5mSub folder $TEST_FOLDER not writable.\e[0m M7CM exiting..." && exit
    done  
}
func_environment_check() {

}
action_help() {
echo -e "
\e[1m./m7cm\e[0m
  ┣> \e[1mhelp\e[0m \e[100mprint this help message\e[0m
  ┣> \e[1mdefine [server] [host]\e[5m*\e[0m \e[1m[jar]\e[5m**\e[0m \e[1m[user] [directory] [max ram] [min ram]\e[0m \e[100m(re)define a server so M7CM can manage it. \e[0m
  ┣> \e[1mconfig [server] [option] [value] \e[0m \e[100mchange one specific option defined by ./m7cm define\e[0m
  ┣> \e[1mbrowse [server]\e[0m \e[100mopen the directory of the given server so you can modify it\e[0m
  ┣> \e[1mstart [server]\e[0m 
  ┣> \e[1mstop [server]\e[0m
  ┣> \e[1mrestart [server]\e[0m
  ┣> \e[1mconsole [server]\e[0m \e[100msend you to a running server's console\e[0m
  ┣> \e[1msend [server] [command]\e[0m \e[100msend a command to a running server\e[0m
  ┣> \e[1mremove [server] [--force]\e[0m \e[100mremove a server from m7cm's library, you need to stop it first. Use --force to ignore its running state\e[0m
  ┣> \e[1mstatus [server]\e[0m \e[100mget and print a server's status. \e[0m
  ┣> \e[1mgroup [sub action]\e[0m \e[100mgroup-related actions\e[0m
  ┃  ┣> \e[1mdefine [group]\e[5m***\e[0m \e[1m [server1] [server2] ... \e[0m \e[100m(re)define a group\e[0m
  ┃  ┣> \e[1mstart [group]\e[0m
  ┃  ┣> \e[1mstop [group]\e[0m
  ┃  ┣> \e[1mrestart [group]\e[0m
  ┃  ┣> \e[1mremove [group]\e[0m \e[100mremove all servers in a group from library\e[0m
  ┃  ┣> \e[1mdelete [group]\e[0m \e[100mjust delete the group itself\e[0m
  ┃  ┣> \e[1mpush [group] [jar]\e[0m \e[100mpush the jar file to all servers in group\e[0m
  ┃  ┗> \e[1mstatus [group]\e[0m \e[100mget and print all servers' status in a group\e[0m
  ┣> \e[1mjar [sub action]\e[0m \e[100mjar-related commands, [jar name] does not incluede the .jar suffix \e[0m
  ┃  ┣> \e[1mdownload [jar name] [link]\e[0m \e[100mdownload a jar from a given link, you need GNU/Wget to do this \e[0m
  ┃  ┣> \e[1mimport [jar name] [path]\e[0m \e[100mimport a jar from local disk\e[0m
  ┃  ┣> \e[1mpush [jar name] [server]\e[0m
  ┃  ┣> \e[1mpull [jar name] [server] ([full jar name on server side])\e[0m
  ┃  ┣> \e[1mconfig [jar name]\e[0m \e[100mchange the types and other stuff of a jar\e[0m
  ┃  ┣> \e[1mbuild [jar name] [version] \e[0m \e[100mbuild a jar file of the given version using spigot buildtool, you need to import or download the buildtool first\e[0m
  ┃  ┣> \e[1mremove [jar name]\e[0m \e[100mremove a jar\e[0m
  ┃  ┣> \e[1minfo [jar name]\e[0m \e[100mcheck information of one of you jar\e[0m
  ┃  ┗> \e[1mlist\e[0m \e[100mlist all your jar files and their info\e[0m
  ┗ \e[1maccount [sub action]\e[0m
     ┣> \e[1mdefine [account]\e[5m****\e[0m \e[1m [hostname/ip] [ssh port] [user] [private key] \e[0m
     ┣> \e[1mconfig [account] \e[0m   
     ┗> \e[1mremove [account] \e[0m

\e[1m*:\e[0m The [host] here must be predefined by ./m7cm host define, M7CM will use SSH to connect to this host and perform management. Even though you want to run and manage servers on the same host as M7CM, you still need to use SSH to ensure both the isolation and the security
\e[1m**:\e[0m The [jar] here must have been imported/downloaded by ./m7cm jar download/import, or you can use a full file name with .jar to refer to a jar file in the directory of the server(will be renamed to server.jar and import into jar library with the same name of the server)
\e[1m***:\e[0m The group _ALL_ can be used to refer to all servers
\e[1m****:\e[0m The [account] here is just the name stored in M7CM's library, it does not have to be the same as the user name.
\e[1m#:\e[0m If you download or import a spigot buildtool, M7CM will recognize it and put it in sub folder spigot-build as buildtool.jar, ignore the [jar name] you defined. You can only keep one spigot buildtool jar.
"
}
action_jar_download() {
    ##usage: action_jar_download() [jar name] [link]
    local JAR_NAME="$1"
    [[ "${JAR_NAME: -4}" = ".jar" ]] && JAR_NAME="${JAR_NAME:0:-4}"
    [[ -f "$PATH_DIRECTORY/jar/$JAR_NAME.jar" ]] && echo -e "\e[31mWARNING\e[0m: A jar with the same name $JAR_NAME has already been defined, you will overwrite this jar file. Press enter to continue, or use ctrl+C to exit" && read -p ""
    local LINK="$2"
    local REGEX='(https?|ftp|file)://[-A-Za-z0-9\+&@#/%?=~_|!:,.;]*[-A-Za-z0-9\+&@#/%=~_|]'
    if [[ "$LINK" =~ $REGEX ]]; then
        wget -O "$PATH_DIRECTORY/jar/$JAR_NAME.jar" "$LINK"
        [[ $? != 0 ]] && return 2 ## download failed
        local JAR_TAG="Downloaded at `date +"%Y-%m-%d-%k:%M"`"
        func_jar_config "$JAR_NAME" 1
    else
        echo -e "\e[31mERROR\e[0m: The following content is not a valid link: $LINK, download aborted" && return 1 ## invalid url
    fi
}
action_jar_import() {
    local JAR_NAME="$1"
    [[ "${JAR_NAME: -4}" = ".jar" ]] && JAR_NAME="${JAR_NAME:0:-4}"
    [[ -f "$PATH_DIRECTORY/jar/$JAR_NAME.jar" ]] && echo -e "\e[31mWARNING\e[0m: A jar with the same name $JAR_NAME has already been defined, you will overwrite this jar file. Press enter to continue, or use ctrl+C to exit" && read -p ""
    local PATH="$2"
    if [[ -f "$PATH" ]]; then
        [[ "${JAR_NAME: -4}" != ".jar" ]] && echo -e "\e[31mWARNING\e[0m: The file extension of this file is not .jar, maybe you've input a wrong file, but M7CM will try to import it anyway"
        [[ ! -r "$PATH" ]] && echo -e "\e[31mERROR\e[0m: No read permission for file \e[100m$PATH\e[0m, check your permission" && return 2 ## no read permission
        \cp -f "$PATH" "$PATH_DIRECTORY/jar/$JAR_NAME.jar"
        local JAR_TAG="Imported at `date +"%Y-%m-%d-%k:%M"`"
        func_jar_config "$JAR_NAME" 1
    else
        echo -e "\e[31mERROR\e[0m: The following content is not a valid path or does not exist: $LINK, import aborted" && return 1
    fi
}
action_jar_config() {
    local JAR_NAME="$1"
    [[ "${JAR_NAME: -4}" = ".jar" ]] && JAR_NAME="${JAR_NAME:0:-4}"
    [[ ! -f "$PATH_DIRECTORY/jar/$JAR_NAME.jar" ]] && echo -e "\e[31mWARNING\e[0m: The jar file $JAR_NAME does not exist" && return 1 #invalid jar
    func_jar_config "$JAR_NAME"
    [[ $? = 0 ]] && echo "Successfully changed config file of jar $JAR_NAME" && return 0
}
action_jar_info() {
    local JAR_NAME="$1"
    [[ "${JAR_NAME: -4}" = ".jar" ]] && JAR_NAME="${JAR_NAME:0:-4}"
    [[ -f "$PATH_DIRECTORY/jar/$JAR_NAME.jar" ]] && echo -e "\e[31mWARNING\e[0m: The jar file $JAR_NAME does not exist" && return 1 #invalid jar
    echo -e "\e[1m<※>\e[0m $JAR_NAME"
    func_jar_info "$JAR_NAME"
    return 0
}
action_jar_list() {
    local JAR_NAME=''
    local ORDER=1
    for JAR_NAME in $(ls $PATH_DIRECTORY/jar/*.jar); do
        JAR_NAME=$(basename $JAR_NAME)
        JAR_NAME=${JAR_NAME:0:-4}
        echo -e "\e[1m<$ORDER>\e[0m $JAR_NAME"
        func_jar_info "$JAR_NAME"
        let ORDER++
    done
    return 0
}
action_jar_remove() {
    local JAR_NAME="$1"
    [[ "${JAR_NAME: -4}" = ".jar" ]] && JAR_NAME="${JAR_NAME:0:-4}"
    [[ ! -f "$PATH_DIRECTORY/jar/$JAR_NAME.jar" ]] && echo -e "\e[31mERROR\e[0m: The jar you specified does not exist!" && return 1 ## not exist
    rm -f "$PATH_DIRECTORY/jar/$JAR_NAME.*"
    [[ $? = 0 ]] && echo "Successfully removed jar $JAR_NAME from library"
}
action_jar_build() {
    ## action_jar_build [jar name] [buildtool] [version]
    [[ ENV_JRE = 0 ]] && echo -e "\e[31mERROR\e[0m: \e[5mSpigot build function is not available due to lacking of Java Runtime Environment " && return 11 #environment error-jre
    [[ ENV_GIT = 0 ]] && echo -e "\e[31mERROR\e[0m: \e[5mSpigot build function is not available due to lacking of Git" && return 12 #environment error-git
    local JAR_NAME="$1"
    local JAR_BUILDTOOL=0
    local BUILD_TOOL="$2"
    local BUILD_VERSION="$3"
    [[ -z "$BUILD_VERSION" ]] && BUILD_VERSION="latest"
    [[ "${JAR_NAME: -4}" = ".jar" ]] && JAR_NAME="${JAR_NAME:0:-4}"
    [[ "${BUILD_TOOL: -4}" = ".jar" ]] && BUILD_TOOL="${BUILD_TOOL:0:-4}"
    [[ ! -f "$PATH_DIRECTORY/jar/$BUILD_TOOL.jar" ]] &&  echo -e "\e[31mERROR\e[0m: The build tool you specified does not exist!" && return 2 ## build tool not exist
    func_jar_info_safely_read "$BUILD_TOOL"
    [[ $JAR_BUILD_TOOL = 0 ]] && echo -e "\e[31mERROR\e[0m: $BUILD_TOOL is not a build tool" && return 2 ## not exist
    local JAR_TAG="Built at `date +"%Y-%m-%d-%k:%M"` with using M7CM auto-build"
    local JAR_TYPE="Spigot"
    local JAR_PROXY=0
    local JAR_VERSION=$BUILD_VERSION
    local JAR_BUILDTOOL=0
    local TMP="/tmp/M7CM-build-$JAR_NAME-`date +"%Y-%m-%d-%k:%M"`"
    mkdir "$TMP" && pushd "$TMP"
    \cp -f "$PATH_DIRECTORY/jar/$BUILD_TOOL.jar" "BuildTools.jar"
    java -jar BuildTools.jar --rev $BUILD_VERSION
    if [[ $? != 0 ]]; then
        echo -e "\e[31mERROR\e[0m: \e[5mFailed to build Spigot version $BUILD_VERSION"
        popd
        rm -rf "$TMP"
        return 3 #build error
    else
        local OUTPUT=`ls spigot-*.jar | awk '{print $1}'`
        cp "$OUTPUT" "$PATH_DIRECTORY/jar/$JAR_NAME.jar"
        popd
        rm -rf "$TMP"
        func_jar_config "$JAR_NAME"
    fi
    return 0
}
func_jar_info_safely_read() {
    local OPTION=''
    for OPTION in TAG PROXY VERSION VERSION_MC BUILDTOOL
    $(sed -n '/JAR_$OPTION=/'p $PATH_DIRECTORY/jar/$1.info)
}
func_jar_config() {
    ##usage: action_jar_identify [jar name] [auto identify(any value to activite it)]
    
    local COMMAND=''
    [[ -f "$PATH_DIRECTORY/jar/$JAR_NAME.info" ]] && func_jar_info_safely_read "$JAR_NAME"
    [[ ! -z "$2" ]] && func_jar_identify "$JAR_NAME" && [[ $? = 1 ]] &&  return 1 ## auto identify if any value is given for $2, and if jar broken then return 1
    while true; do
        clear
        func_draw_line
        func_print_center "Jar File Configuration"
        func_draw_line
        echo -e "\e[1mNAME:\e[0m $JAR_NAME "
        echo -e "\e[1mTAG:\e[0m $JAR_TAG " 
        echo -e "\e[1mTYPE:\e[0m $JAR_TYPE \e[100mWhat kind of jar it is, i.e. Spigot, Paper, Vanilla\e[0m"
        echo -e "\e[1mPROXY:\e[0m $JAR_PROXY \e[100mIf it contains a proxy server, i.e. Waterfall, Bungeecord. Accept: 0/1\e[0m"
        echo -e "\e[1mVERSION:\e[0m $JAR_VERSION \e[100mWhat is this jar's version, i.e. Git-Paper-137\e[0m"
        echo -e "\e[1mVERSION_MC:\e[0m $JAR_VERSION_MC \e[100mWhich version of minecraft does this jar support, i.e. 1.16.1\e[0m"
        echo -e "\e[1mBUILDTOOL:\e[0m $JAR_BUILDTOOL \e[100mWhether it contains a Spigot buildtool\e[0m"
        func_draw_line
        echo -e "\e[4mType in the option you want to change and the new value split by =, i.e.TAG=This is my first jar!\nYou can also type 'identify' to let M7CM identify it, or 'confirm' to confirm these values\e[0m"
        read -p ">>>" COMMAND
        case "$COMMAND" in
            identify)
                func_jar_identify $JAR_NAME
                [[ $? = 1 ]] &&  return 1 ## jar broken
                printf "Refreshing jar information in 3 seconds.\r"
                sleep 1
                printf "Refreshing jar information in 2 seconds..\r"
                sleep 1
                echo "Refreshing jar information in 1 seconds..."
                sleep 1
            ;;
            confirm)
                echo "Proceeding to write values to config file...."
                echo "## Infos for jar file $JAR_NAME, DO NOT EDIT THIS UNLESS YOU KNOW WHAT YOU ARE DOING" > "$PATH_DIRECTORY/jar/$JAR_NAME.info"
                echo "JAR_TAG=\"$JAR_TAG\"" >> "$PATH_DIRECTORY/jar/$JAR_NAME.info"
                echo "JAR_PROXY=$JAR_PROXY" >> "$PATH_DIRECTORY/jar/$JAR_NAME.info"
                echo "JAR_VERSION=\"$JAR_VERSION\"" >> "$PATH_DIRECTORY/jar/$JAR_NAME.info"
                echo "JAR_VERSION_MC=\"$JAR_VERSION_MC\"" >> "$PATH_DIRECTORY/jar/$JAR_NAME.info"
                echo "JAR_BUILDTOOL=$JAR_BUILDTOOL" >> "$PATH_DIRECTORY/jar/$JAR_NAME.info"
                return 0
            ;;
            *)
                local OPTION=''
                local VALUE=''
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
                            echo "\e[31mWARNING\e[0m: \e[1mA jar with the same name has already exist, renaming aborted \e[0m\c"
                            read -n 1 -s -r -p "Press any key to continue..."    
                        else
                            mv "$PATH_DIRECTORY/jar/$JAR_NAME.jar" "$PATH_DIRECTORY/jar/$VALUE.jar"
                            [[ -f "$PATH_DIRECTORY/jar/$VALUE.info" ]] && mv "$PATH_DIRECTORY/jar/$JAR_NAME.info" "$PATH_DIRECTORY/jar/$VALUE.info"
                            JAR_NAME=$VALUE
                        fi
                    ;;
                    *)
                        echo -e "\e[31mWARNING\e[0m: \e[5m\e[1mInput not recognized! \e[0m Press any key to continue...\c"
                        read -n 1 -s -r -p ""
                    ;;
            ;;
        esac
    done
}
func_jar_identify() {
    [[ ENV_JRE = 0 ]] && echo -e "\e[31mERROR\e[0m: \e[5mAuto-identifying function is not available due to lacking of Java Runtime Environment " && return 11 #environment error-JRE
    echo "Auto-identifying jar information for $JAR_NAME..." 
    local TMP="/tmp/M7CM-identifying-$JAR_NAME-`date +"%Y-%m-%d-%k:%M"`"
    mkdir "$TMP" && pushd "$TMP"
    JAR_VERSION=$(java -jar "$PATH_DIRECTORY/jar/$JAR_NAME.jar" --version) 
    local RETURN=$?
    if [[ $RETURN = 0 ]]; then
        if [[ "$JAR_VERSION" =~ "BungeeCord" ]]; then JAR_TYPE="BungeeCord" && JAR_PROXY=1 && echo "Looks like it contains a Bungeecord proxy server"
        elif [[ "$JAR_VERSION" =~ "Waterfall" ]]; then JAR_TYPE="Waterfall" && JAR_PROXY=1 && echo "Looks like it contains a Waterfall proxy server"
        elif [[ "$JAR_VERSION" =~ "Spigot" ]]; then JAR_TYPE="Spigot" && JAR_PROXY=0 && echo "Looks like it contains a Spigot game server"
        elif [[ "$JAR_VERSION" =~ "Paper" ]]; then 
            JAR_TYPE="Paper"
            JAR_PROXY=0
            if [[ "$JAR_VERSION" =~ "Downloading vanilla jar..." ]]; then
                echo "Looks like it is a PaperMC pre-patch jar"
                local BASENAME=$(basename $(ls $TMP/cache/patched_*.jar)) 1>/dev/null 2>&1
                if [[ $? != 0 ]]; then
                    echo -e "\e[31mERROR\e[0m: You've downloaded a paper jar file which should then download a vanilla jar and patch it. But it failed to patch the vanilla jar, you may need to check your source and network connection. \n Failed adding jar $JAR_NAME"
                    rm -rf "$TMP"
                    return 2 ## paper patch error
                else
                    JAR_VERSION_MC=${BASENAME:8:-4} && mv -f "$TMP/cache/patched_*.jar" "$PATH_DIRECTORY/jar/$JAR_NAME.jar"
                    JAR_VERSION="git${JAR_VERSION#*git}"
                fi
            else    
                echo "Looks like it contains a Paper game server"
            fi
        fi
    else if [[ $RETURN =1 ]]; then
        if [[ "$JAR_VERSION" =~ "BuildTools" ]]; then
            echo "Looks like it is a spigot buildtool"
            JAR_BUILDTOOL=1
            JAR_TYPE="Spigot"
            JAR_VERSION="Unknown"
        elif [[ "$JAR_VERSION" =~ "version is not a recognized option" ]]; then JAR_TYPE="Vanilla" && JAR_VERSION="Unknown"
        elif [[ "$JAR_VERSION" =~ "Error: Invalid or corrupt jarfile" ]]; then
            printf "\e[31mWARNING\e[0m: The jar file must be broken, proceeding to delete it in 3 seconds, ctrl+C to cancel.\r"
            sleep 1
            printf "\e[31mWARNING\e[0m: The jar file must be broken, proceeding to delete it in 2 seconds, ctrl+C to cancel..\r"
            sleep 1
            printf "\e[31mWARNING\e[0m: The jar file must be broken, proceeding to delete it in 1 seconds, ctrl+C to cancel...\r"
            sleep 1
            printf "\e[31mWARNING\e[0m: The jar file is broken, proceeding to delete it                                                            \n"
            rm -f "$PATH_DIRECTORY/jar/$JAR_NAME.jar" && popd && return 1  # jar broken
        fi
    fi
    popd && rm -rf "$TMP"
    return 0
}
func_jar_info() {
    #usage: func_jar_info [jar name]
    if [[ -f "$PATH_DIRECTORY/jar/$JAR_NAME.info" ]]; then
        echo -e "\e[31mWARNING\e[0m: Info file for jar $JAR_NAME not exist, maybe you should run ./m7cm jar config $JAR_NAME first"
    else
        func_jar_info_safely_read "$JAR_NAME"
        [[ ! -z "$JAR_TAG" ]] && echo -e " ┣> \e[1mTAG:\e[0m $JAR_TAG"
        [[ $JAR_PROXY = 1 ]] && echo -e " ┣> \e[1mPROXY:\e[0m This is a proxy server"
        [[ $JAR_BUILDTOOL = 1 ]] && echo -e " ┣> \e[1mBUILDTOOL:\e[0m This is a spigot buildtool"
        [[ $JAR_BUILDTOOL = 0 ]] && echo -e " ┣> \e[1mTYPE:\e[0m $JAR_TYPE"
        echo -e " ┣> \e[1mVERSION:\e[0m $JAR_VERSION"
        echo -e " ┗> \e[1mVERSION_MC:\e[0m $JAR_VERSION_MC" 
    fi
}

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
    func_account_safely_read "$ACCOUNT_NAME"
    func_account_config "$ACCOUNT_NAME"
}
action_account_remove() {
    
}
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
func_account_safely_read() {
    local OPTION=''
    for OPTION in HOST PORT USER KEY
    $(sed -n '/ACCOUNT_$OPTION=/'p $PATH_DIRECTORY/account/$1.account)
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
                download)
                    #download a jar
                    action_jar_download "$3" "$4"
                ;;
                import)
                    #import a local jar
                    action_jar_import "$3" "$4"
                ;;
                push)
                    #push a jar to a server
                    action_jar_push "$3" "$4"
                ;;
                pull)
                    #pull a jar from a server
                    action_jar_pull "$3" "$4" "$5"
                ;;
                config)
                    action_jar_config "$3"
                ;;
                build)
                    action_jar_build "$3" "$4" "$5"
                ;;
                remove)
                    action_jar_remove "$3"
                ;;
                info)
                    action_jar_info "$3"
                ;;
                list)
                    action_jar_list 
                ;;
                *)
                    action_help && return
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