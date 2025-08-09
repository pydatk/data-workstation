#!/usr/bin/bash
set -e

# change default XDG dirs (use ~/tmp for everything - these dirs won't
# usually be used by workstation)
mv $HOME/.config/user-dirs.dirs $HOME/.config/user-dirs.dirs.old
cp updates/0001/user-dirs.dirs $HOME/.config/user-dirs.dirs

# hide unused files and directories
echo Desktop > $HOME/.hidden
echo Documents >> $HOME/.hidden
echo Downloads >> $HOME/.hidden
echo Music >> $HOME/.hidden
echo Pictures >> $HOME/.hidden
echo Public >> $HOME/.hidden
echo snap >> $HOME/.hidden
echo Templates >> $HOME/.hidden
echo Videos >> $HOME/.hidden

# hide above files when using ls
aliasls=$(cat updates/0001/bash_aliases)
echo "$aliasls" >> $HOME/.bash_aliases

# create file to identify whether this option is being used - if so system
# check will archive tmp files to .tmp-archive and move files in above
# dirs to tmp
touch $HOME/.data-workstation/.tidy-home