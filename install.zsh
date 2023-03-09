#!/bin/zsh


# download
echo "Downloading..."
# create tmp folder
TMPFOLDER="/tmp/zsh-config-$$$RANDOM" # e.g. /tmp/zsh-config-3754419952
mkdir $TMPFOLDER
# echo $TMPFOLDER
git clone https://github.com/StudioProcess/zsh-config $TMPFOLDER
#cp ./*(DN) $TMPFOLDER > /dev/null 2>&1 # for local testing only


# zsh config
echo "Installing .zshrc ..."
if  [ -f ~/.zshrc ]; then
  # backup existing .zshrc
  mv ~/.zshrc ~/.zshrc.old-$$$RANDOM
fi
cp $TMPFOLDER/.zshrc ~/


# Terminal.app theme
echo "Installing Terminal theme..."
sleep 3 # wait a bit, otherwise ~/.zplug doesn't seem to be ready
open $TMPFOLDER/Snazzy\ Custom.terminal
defaults write com.apple.Terminal "Default Window Settings" -string "Snazzy Custom"
defaults write com.apple.Terminal "Startup Window Settings" -string "Snazzy Custom"


# Cleanup
echo "Cleaning up..."
rm -rf $TMPFOLDER

echo "Done."
