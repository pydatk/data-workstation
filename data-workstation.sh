#!/usr/bin/bash
set -e

echo -e "\ndata-workstation"

echo -e "\nIMPORTANT: Please read the README.md and LICENSE files before using this program. Take a snapshot and backup data before deploying. Test thoroughly before deploying in a production environment.\n"
read -p "Press any key to continue..."

# create required directories
echo "Making directories"
mkdir -p "$HOME/.data-workstation"
mkdir -p "$HOME/.data-workstation/.updates"
mkdir -p "$HOME/temp"
mkdir -p "$HOME/archive"
mkdir -p "$HOME/projects"
echo "Finished making directories"

module="data-workstation"

# function: output message to log and terminal
#    arg 1: log level (DEBUG, INFO, WARNING, ERROR, CRITICAL)
#    arg 2: message to output
echo "Starting log: $HOME/.data-workstation/.data-workstation.log"
function log_message() {  
    if [ ! $# == 2 ]; then
        level="CRITICAL"
        msg="Function log_message takes two arguments"
    else 
        level=$1
        msg=$2
    fi
    now=$(date +"%Y-%m-%d %H:%M:%S.%3N")
    line="$now | $level | $module | $msg"
    echo $line >> "$HOME/.data-workstation/.data-workstation.log"
    echo $line
    if [ $level == "CRITICAL" ]; then
        exit 1
    elif [ $level == "WARNING" ] || [ $level == "ERROR" ]; then
        read -p "$level occured. Continue? [y, N]" input
        if ! [[ $input == "y" || $input == "Y" ]]; then
            exit 1
        fi
    fi
}
log_message "INFO" "=== data-workstation started ==="

# get project version
version=$(head -n 1 "$HOME/data-workstation/.version")
version=$(echo "$version" | cut -d ":" -f 2)
log_message "DEBUG" "data-workstation version: $version"

# check that latest version is being used
log_message "DEBUG" "Getting latest available data-workstation version"
wget https://raw.githubusercontent.com/pydatk/data-workstation/refs/heads/main/.version -O /tmp/.latest-version
latest=$(head -n 1 /tmp/.latest-version)
latest=$(echo "$latest" | cut -d ":" -f 2)
if [ "$latest" == "$version" ]; then
    log_message "DEBUG" "Latest data-workstation version installed."
else
    log_message "WARNING" "Version $latest of data-workstation is available. Installed version: $version"
fi

function check_os() {

    # get currently installed os
    current_os=$(lsb_release -d -s | tail -1)
    log_message "INFO" "Installed Operating System: $current_os"

    # check if OS has changed
    if [ -f "$HOME/.data-workstation/.os" ]; then
        last_os=$(cat "$HOME/.data-workstation/.os")
        log_message "DEBUG" "Previous Operating System: $last_os"
        if [ ! "$current_os" == "$last_os" ]; then
            log_message "WARNING" "Operating system has changed from $last_os to $current_os"
        else
            log_message "DEBUG" "Operating system has not changed"
        fi    
    fi

    # check if OS is supported
    set +e 
    grout=$(grep "$current_os" "$HOME/data-workstation/.os-support")
    if [ $? != 0 ]; then
        set -e
        log_message "CRITICAL" "Installed Operating System not supported: $current_os"
    else
        set -e
        log_message "DEBUG" "Installed Operating System supported: $current_os"
    fi
    set -e

    # save current os
    echo $current_os > "$HOME/.data-workstation/.os"
    log_message "DEBUG" "Saved current Operating System: $current_os"

}

check_os

# get module parameters
if [ ! $1 ]; then
    log_message "CRITICAL" "Module option required"
else
    if [ $1 == "setup" ]; then
        module="setup"
        if [ -f "$HOME/.data-workstation/.auto-option" ]; then
            auto=$(cat "$HOME/.data-workstation/.auto-option")
        else
            echo -e "\nMachine type:"
            echo "1. Base"
            echo "2. Workstation"
            read -p "Choose an option [1,2]: " mtype
            if [ "$mtype" == "1" ]; then
                auto="auto-base"
                echo $auto > "$HOME/.data-workstation/.auto-option"
            elif [ "$mtype" == "2" ]; then
                auto="auto-all"
                echo $auto > "$HOME/.data-workstation/.auto-option"
            else
                log_message "CRITICAL" "Option not recognised: $mtype"
            fi
        fi
        log_message "DEBUG" "Auto option: $auto"
    elif [ $1 == "project" ]; then
        module="project"
    elif [ $1 == "backup" ]; then
        module="backup"
    elif [ $1 == "deploy-www" ]; then
        module="deploy-www"
        if [ "$2" == "" ]; then
            log_message "CRITICAL" "Please specify input and output paths for deploy-www"
        else
            wwwin=$2
        fi
        if [ "$3" == "" ]; then
            log_message "CRITICAL" "Please specify input and output paths for deploy-www"
        else
            wwwout=$3
        fi
    else
        log_message "CRITICAL" "Invalid module: $1"
    fi
fi
log_message "DEBUG" " Module ready: $module"

# function: try to run command and catch error if occurs
#    arg 1: command to run
#    arg 2: reference (e.g. update name) to display in log message
function try_command() {

    log_message "DEBUG" "Trying command ($2): $1"

    # don't exit on error (will catch and log)
    set +e 
    $1
    if [ $? != 0 ]; then
        set -e
        log_message "CRITICAL" "Command failed ($2): $1"
        exit 1
    fi
    set -e
    log_message "DEBUG" "Command ok ($2): $1"
}

function apply_update() {
    apply=0
    # get update version
    updateversion=$(echo "$1" | cut -d "/" -f 1)
    lookup=$(grep "$updateversion" .version)
    addedversion=$(echo "$lookup" | cut -d ":" -f 2)
    # get update code
    updatecode=$(echo "$1" | cut -d "/" -f 2)
    # get metadata type
    line=$(sed -n '1p' "updates/$1.metadata")
    key=$(echo $line | cut -d ":" -f 1)
    value=$(echo $line | cut -d ":" -f 2)
    if [ $key == "type" ]; then
        if [ $value == "base" ] || [ $value == "workstation" ]; then
            type=$value
        else
            log_message "CRITICAL" "Invalid type [$value] for $1"
        fi
    else
        log_message "CRITICAL" "Invalid type metadata [$line] for $1"
    fi
    # get metadata name
    line=$(sed -n '2p' "updates/$1.metadata")
    key=$(echo $line | cut -d ":" -f 1)
    value=$(echo $line | cut -d ":" -f 2)
    if [ $key == "name" ]; then
        charcount=$(echo -n "$value" | wc -m)
        if [ $charcount != 0 ]; then
            name=$value
        else
            log_message "CRITICAL" "Name not found [$line] for $1"
        fi
    else
        log_message "CRITICAL" "Invalid type metadata [$line] for $1"
    fi
    # get metadata description
    desc=$(tail -n +3 "updates/$1.metadata")
    charcount=$(echo -n "$desc" | wc -m)
    if [ $charcount == 0 ]; then
        log_message "CRITICAL" "Desc not found for $1"
    fi
    # output metadata
    echo "----------------------------------------------------------"
    echo "Update name: $name"
    echo "Update code: $updatecode"
    echo "Update type: $type"
    echo "Update version: $updateversion"
    echo "Update added in version: $addedversion"
    echo "Update description:"
    echo $desc
    echo "----------------------------------------------------------"
    # create dir for update history files
    mkdir -p "$HOME/.data-workstation/.updates/.$updateversion"
    # get data (for outputting to update history)
    now=$(date +"%Y-%m-%d %H:%M:%S.%3N")
    # check if update has already been applied
    if [ -f "$HOME/.data-workstation/.updates/.$updateversion/.$updatecode" ]; then
        log_message "DEBUG" "Skipping update (already done): $updateversion $updatecode"
    else
        if [ $auto == "auto-all" ]; then
            log_message "DEBUG" "Will apply $type update: $name"
            apply=1
        elif [ $auto == "auto-base" ] && [ $type == "base" ]; then
            log_message "DEBUG" "Will apply $type update: $name"
            apply=1
        else
            log_message "DEBUG" "Will not apply $type update: $name"
        fi
        if [ $apply != 1 ]; then
            log_message "INFO" "Skipped update : $updateversion $updatecode"
            echo "skipped" >> "$HOME/.data-workstation/.updates/.$updateversion/.$updatecode"
        else
            log_message "INFO" "Applying update: $updateversion $updatecode"
            try_command "updates/$updateversion/$updatecode.sh" $name
            echo "applied" >> "$HOME/.data-workstation/.updates/.$updateversion/.$updatecode"
        fi
    fi
}

function end_data_workstation() {
    log_message "INFO" "=== data-workstation finished ==="
    exit 0
}

function setup() {
    # apt update / upgrade (runs at start of setup each time)
    log_message "INFO" "Applying apt update / upgrade"
    try_command "sudo apt -y update" "apt update"
    try_command "sudo apt -y upgrade" "apt upgrade"        
    # check for OS version change as result of apt update/upgrade
    check_os
    # initial setup
    apply_update "0001/ufw_firewall"
    apply_update "0001/prevent_power_saving"
    apply_update "0001/tidy_home_dir"
    apply_update "0001/brave_browser"
    apply_update "0001/uninstall_firefox"
    apply_update "0001/install_postgres"
    apply_update "0001/change_postgres_locale"
    apply_update "0001/revoke_postgres_db_public"
    apply_update "0001/install_quarto_v1-7-32"
    apply_update "0004/install_python_venv"
    apply_update "0004/psycopg2-dependencies"
    apply_update "0001/install_vs_code"
    apply_update "0001/install_vs_code_extensions"
    apply_update "0001/install_libre_office_calc"
    apply_update "0001/install_dconf_editor"
    # restart (necessary after initial setup)
    apply_update "0001/restart"
    if [ $apply == 1 ]; then
        end_data_workstation
    fi
    # UI configuration
    apply_update "0001/dark_style"
    apply_update "0001/dock_config"
    apply_update "0001/set_favorite_apps"
    # installs after initial restart
    apply_update "0001/github_authentication"
    apply_update "0004/install_nginx"
    # final restart
    apply_update "0001/final_restart"
    if [ $apply == 1 ]; then
        end_data_workstation
    fi
}

function system_check() {
    # start system check
    log_message "INFO" "Starting system check"
    # check ufw is active
    status=$(sudo ufw status)
    if [ "$status" == "Status: active" ]; then
        log_message "DEBUG" "ufw is active"
    else
        log_message "WARNING" "ufw is not active"
    fi
    # check apparmor is active
    status=$(systemctl is-active apparmor.service)
    if [ "$status" == "active" ]; then
        log_message "DEBUG" "apparmor is active"
    else
        log_message "WARNING" "apparmor is not active"
    fi
    # tidy home dir
    if [ -f "$HOME/.data-workstation/.tidy-home" ]; then
        log_message "INFO" "Tidying home directory"
        # archive existing tmp content
        now=$(date +"%Y%m%d-%H%M%S")
        mkdir -p $HOME/temp
        zip -r -9 -q -T -m "$HOME/archive/temp-$now" "$HOME/temp"
        mkdir -p $HOME/temp
    else
        log_message "DEBUG" "tidy-home option not set"
    fi
    # finished system check
    log_message "INFO" "Finished system check"
}

function project() {

    log_message "INFO" "Started project module"
    
    read -p "Project name (e.g. myproject): " projectdir
    read -p "GitHub repository name (e.g. test-project-public): " gitrepo
    read -p "GitHub repository owner user name (e.g. pydatk): " gituser
    read -p "GitHub repository branch (e.g. main): " branch
    
    mkdir -p $HOME/projects
    mkdir -p $HOME/projects/$projectdir
    mkdir -p $HOME/projects/$projectdir/storage
    mkdir -p $HOME/projects/$projectdir/config
    
    git clone -b $branch https://github.com/$gituser/$gitrepo.git $HOME/projects/$projectdir/$gitrepo
        
    echo ""
    read -p "Add Quarto website to project repository? [y,n] " input
    if [ $input == "y" ] || [ $input == "Y" ]; then
        pushd $HOME/projects/$projectdir/$gitrepo
        quarto create --no-open project website quarto
        popd
        fn="$HOME/projects/$projectdir/$gitrepo/deploy-quarto.sh"
        echo "#!/usr/bin/bash" > $fn
        echo "set -e" >> $fn
        echo "$HOME/data-workstation/data-workstation.sh deploy-www $HOME/projects/$projectdir/$gitrepo/quarto/_site/ /var/www/html/$projectdir/" >> $fn
        chmod +x $fn
    fi

    echo ""
    read -p "Customize .gitignore? [y,n] " input
    if [ $input == "y" ] || [ $input == "Y" ]; then
        echo -e "# custom\n.vscode/\nquarto/\ndeploy-quarto.sh\n" > /tmp/.gitignore
        cat $HOME/projects/$projectdir/$gitrepo/.gitignore >> /tmp/.gitignore
        mv /tmp/.gitignore $HOME/projects/$projectdir/$gitrepo/.gitignore
    fi

    log_message "DEBUG" "Creating virtual environment"
    echo ""
    mkdir -p $HOME/venvs
    venvts=$(date +"%y%m%d-%H%M")
    venvname="$projectdir-$venvts"
    python3 -m venv "$HOME/venvs/$venvname"
    log_message "INFO" "Created virtual environment: $venvname"
    echo ""
    read -p "Created Python virtual environment: $venvname. Press enter to continue..."

    echo ""
    read -p "Add default requirements.txt to project? [y,n] " input
    if [ $input == "y" ] || [ $input == "Y" ]; then
        cp updates/0001/requirements.txt $HOME/projects/$projectdir/$gitrepo      
    fi

    echo ""
    mkdir -p $HOME/workspaces
    echo -e "{" > $HOME/workspaces/$projectdir.code-workspace
    echo -e "    \"folders\": [" >> $HOME/workspaces/$projectdir.code-workspace
    echo -e "        {" >> $HOME/workspaces/$projectdir.code-workspace
    echo -e "            \"path\": \"../projects/$projectdir/$gitrepo\"" >> $HOME/workspaces/$projectdir.code-workspace
    echo -e "        }" >> $HOME/workspaces/$projectdir.code-workspace
    echo -e "    ]," >> $HOME/workspaces/$projectdir.code-workspace
    echo -e "    \"settings\": {}" >> $HOME/workspaces/$projectdir.code-workspace
    echo -e "}" >> $HOME/workspaces/$projectdir.code-workspace

    echo ""
    read -p "Create VS Code settings.json and add venv as default Python interpreter? [y,n] " input
    if [ $input == "y" ] || [ $input == "Y" ]; then
        mkdir -p $HOME/projects/$projectdir/$gitrepo/.vscode
        echo -e "{" > $HOME/projects/$projectdir/$gitrepo/.vscode/settings.json
        echo -e "    \"python.defaultInterpreterPath\": \"$HOME/venvs/$projectdir-$venvts/bin/python\"" >> $HOME/projects/$projectdir/$gitrepo/.vscode/settings.json 
        echo -e "}" >> $HOME/projects/$projectdir/$gitrepo/.vscode/settings.json 
    fi

    echo ""
    read -p "Create new postgres database? [y,n] " input
    if [ $input == "y" ] || [ $input == "Y" ]; then
        
        dbname=$projectdir
        pguser="$dbname"_owner

        if [ -f "$HOME/.data-workstation/.postgres-encoding" ]; then
            encoding=$(cat "$HOME/.data-workstation/.postgres-encoding")
        else
            read -p "Enter encoding (e.g. utf8) - will be saved as default: " encoding
            echo $encoding > "$HOME/.data-workstation/.postgres-encoding"
        fi

        if [ -f "$HOME/.data-workstation/.postgres-locale" ]; then
            locale=$(cat "$HOME/.data-workstation/.postgres-locale")
        else
            read -p "Enter locale (e.g. en_NZ.utf8) - will be saved as default: " locale
            echo $locale > "$HOME/.data-workstation/.postgres-locale"
        fi        

        try_command "sudo -u postgres createuser --no-createdb --pwprompt --no-createrole --no-superuser $pguser"
        sql="create database $dbname owner $pguser template 'template0' encoding $encoding lc_collate='$locale' lc_ctype='$locale';"
        fn="/tmp/create-$dbname.sql"
        echo $sql > $fn
        try_command "sudo -u postgres psql -f $fn"
        sql="REVOKE connect ON DATABASE $dbname FROM PUBLIC;"
        fn="/tmp/revoke-public-$dbname.sql"
        echo $sql > $fn
        try_command "sudo -u postgres psql -f $fn"

        log_message "INFO" "Created database: $dbname - owner: $pguser - locale: $locale - encoding: $encoding"
        echo ""
        read -p "Created postgres database $dbname with owner $pguser. Press enter to continue..."

    fi

    log_message "INFO" "Finished project module"

}    

function backup() {

    log_message "DEBUG" "Starting backup module"

    # get current timestamp
    now=$(date +"%Y%m%d-%H%M")

    # make backup & restore directories
    sourcedir="$HOME/projects"
    backupdir="$HOME/archive/backup-$HOSTNAME-$now"
    restoredir="/tmp/restore-$HOSTNAME-$now"
    mkdir $backupdir
    mkdir $restoredir

    # postgres backup
    log_message "INFO" "Backing up all PostgreSQL databases"
    # can't use try_command with pipe
    sudo -i -u postgres pg_dumpall | zip -9 $backupdir/postgres_backup -
    log_message "INFO" "Finished backing up PostgreSQL databases"

    # start backup process
    log_message "INFO" "File backup started"

    # create file lists
    # can't use try command with output to file
    log_message "DEBUG" "Creating file lists"
    ls $sourcedir/* -a --format=single-column --group-directories-first -p -R -1 -U --width=0 > $backupdir/projects-list-name.txt
    ls $sourcedir/* -a --group-directories-first -l -p -R --time=mtime -U --width=0 --block-size=K --time-style=long-iso > $backupdir/projects-list-metadata.txt

    # compress backup files to zip archive
    log_message "DEBUG" "Zipping files"
    try_command "zip -r -9 -dc $backupdir/projects-backup $sourcedir/*"

    # create list of backed up files
    log_message "DEBUG" "Creating list of zipped files"
    unzip -l $backupdir/projects-backup  > $backupdir/projects-list-zip.txt

    log_message "INFO" "File backup finished"

    # start testing process
    log_message "INFO" "File restore test started"

    # unzip backup to restore dir
    try_command "unzip $backupdir/projects-backup.zip -d $restoredir"

    log_message "DEBUG" "Comparing backup to restored"
    # compare original and restored files
    diffresult=$(diff -qr $sourcedir/ $restoredir/$HOME/projects/)
    # check if any differences were found
    if [ "$diffresult" == "" ]; then
        # no differences - backup ok
        log_message "INFO" "File restore test OK"
    else
        # differences found - backup failed
        log_message "DEBUG" "File restore test failed, saving differences"
        # output differences to file
        fn=$backupdir/restore-diff.txt
        echo $diffresult > $fn
        # exit with error code
        log_message "CRITICAL" "File restore test failed. Difference saved to: $fn"
    fi

    log_message "DEBUG" "Deleting $restoredir"
    try_command "rm -rf $restoredir"

    log_message "INFO" "Backup module finished. Backup location: $backupdir"

}

function deploy-www() {
    log_message "DEBUG" "Copying files from $wwwin to $wwwout"
    try_command "rsync -r --delete $wwwin $wwwout"
    log_message "DEBUG" "Changing permissions in $wwwout"
    try_command "sudo chown $USER:www-data -R $wwwout"
    try_command "sudo chmod u=rwX,g=srX,o=rX -R $wwwout"
    # can't use try_command with find
    sudo find /var/www/html -type d -exec chmod g=rwxs "{}" \;
    sudo find /var/www/html -type f -exec chmod g=rws "{}" \;
    log_message "DEBUG" "deploy-www finished OK"
}

# run module
if [ $module == "setup" ]; then    
    log_message "INFO" "Started $module"
    $module
    # do system check after module (setup installs some apps needed
    # to do system check
    system_check 
    log_message "INFO" "Finished $module"
elif [ $module == "backup" ] || [ $module == "project" ] || [ $module == "deploy-www" ]; then
    log_message "INFO" "Started $module"
    system_check # do security check before module
    $module
    log_message "INFO" "Finished $module"
else
    log_message "CRITICAL" "Invalid module: $module"
fi

end_data_workstation
