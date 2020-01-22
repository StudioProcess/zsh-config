#!/bin/zsh

# create tmp folder
TMPFOLDER="/tmp/zsh-setup-$$$RANDOM"
mkdir $TMPFOLDER
# echo $TMPFOLDER

git clone https://github.com/StudioProcess/zsh-config $TMPFOLDER
#cp ./*(DN) $TMPFOLDER > /dev/null 2>&1 # for local testing only

# install homebrew
# if ! type "brew" > /dev/null; then
#   echo "Installing Homebrew... https://brew.sh"
#   /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
# else
#   echo "Homebrew already installed"
# fi

# install pygments
if ! type "pygmentize" > /dev/null; then
  echo "Installing Pygments... https://pygments.org"
  pip3 install pygments --user
else
  echo "Pygments already installed"
fi

# install zplug
if [ ! -d ~/.zplug/ ]; then
  echo "Installing zplug... https://github.com/zplug/zplug"
  ZPLUG_HOME="" # so zplug gets installed to the default location ~/.zplug/
  curl -sL --proto-redir -all,https https://raw.githubusercontent.com/zplug/installer/master/installer.zsh | zsh
else
  echo "zplug already installed"
fi

# zsh config
echo "Installing .zshrc ..."
if  [ -f ~/.zshrc ]; then
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
#rm -rf $TMPFOLDER

echo "Done."
