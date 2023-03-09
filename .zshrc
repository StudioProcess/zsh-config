# 2020-09-24, 2020-09-18, 2020-01-21, 2022-03-09
# Plugin selection mainly from:
# https://medium.com/@ahadsheriff/how-to-get-a-better-development-experience-on-your-mac-8478be58bba4
#
# Requirements
# zplug: curl -sL --proto-redir -all,https https://raw.githubusercontent.com/zplug/installer/master/installer.zsh | zsh
# pygments (for colorize): brew install python && pip3 install pygments



# PLUGINS
# zplug 
source ~/.zplug/init.zsh

# pure prompt
zplug mafredri/zsh-async, from:github
zplug sindresorhus/pure, use:pure.zsh, from:github, as:theme, defer:0

# For color indices, see: https://en.wikipedia.org/wiki/Xterm#/media/File:Xterm_256color_chart.svg
# zstyle :prompt:pure:execution_time color yellow
# zstyle :prompt:pure:git:arrow color cyan
# zstyle :prompt:pure:git:branch color 242
# zstyle :prompt:pure:git:branch:cached color red
# zstyle :prompt:pure:git:action color 242
# zstyle :prompt:pure:git:dirty color 218
# zstyle :prompt:pure:host color 242
# zstyle :prompt:pure:path color blue
# zstyle :prompt:pure:prompt:error color red
# zstyle :prompt:pure:prompt:success color magenta
# zstyle :prompt:pure:prompt:continuation color 242
# zstyle :prompt:pure:prompt:user color 242
# zstyle :prompt:pure:prompt:user:root color default
# zstyle :prompt:pure:prompt:virtualenv color 242
# PURE_PROMPT_SYMBOL='❯'
# PURE_PROMPT_VICMD_SYMBOL='❮'

# oh-my-zsh plugins
# zplug "plugins/brew", from:oh-my-zsh
zplug "plugins/colored-man-pages", from:oh-my-zsh
zplug "plugins/colorize", from:oh-my-zsh
zplug "plugins/common-aliases", from:oh-my-zsh
  #zplug "plugins/cp", from:oh-my-zsh
# zplug "plugins/git", from:oh-my-zsh
# zplug "plugins/node", from:oh-my-zsh
# zplug "plugins/npm", from:oh-my-zsh
# zplug "plugins/sudo", from:oh-my-zsh
# zplug "plugins/yarn", from:oh-my-zsh
# zplug "plugins/z", from:oh-my-zsh

zplug "zsh-users/zsh-syntax-highlighting"
zplug "zsh-users/zsh-autosuggestions"

zplug "MichaelAquilina/zsh-autoswitch-virtualenv"
# export AUTOSWITCH_VIRTUAL_ENV_DIR="./venv" # store virtualenvs in each project folder

  #zplug "~/code/zsh-autoswitch-virtualenv", from:local, defer:1
export AUTOSWITCH_VIRTUAL_ENV_DIR="./venv" # store virtualenvs in each project folder
# export AUTOSWITCH_VIRTUAL_ENV_DIR="." # store virtualenvs in each project folder
# export AUTOSWITCH_VIRTUAL_ENV_NAME="venv"

if ! zplug check --verbose; then
  zplug install
fi

zplug load


# OPTIONS
setopt auto_cd # cd by just typing the folder name
# setopt auto_pushd pushd_ignore_dups setopt pushd_minus


# VARIABLES
# not needed when Pygments is installed via homebrew pip3
# export PATH=/Users/$USER/Library/Python/3.8/bin:$PATH # add pip3 user folder to path (for pygmentize)
export EDITOR='atom'



# ALIASES
alias ls='ls -G' # colored ls
if type 'ccat' > /dev/null; then # colored cat (if available)
  alias cat=ccat
fi
if type 'cless' > /dev/null; then # colored less (if available)
  alias less=cless
fi

alias home='cd ~'
alias lanip="ifconfig | sed -En 's/127.0.0.1//;s/.*inet (addr:)?(([0-9]*\.){3}[0-9]*).*/\2/p'" #https://stackoverflow.com/a/13322549
alias wanip='curl http://ipecho.net/plain; echo'



# FUNCTIONS
CODE_FOLDER=~/code # don't quote so tilde gets expanded
function code () {
  if (( $# == 0 )); then # of args is empty (length zero?)
    1=10
	fi
	cd $CODE_FOLDER; ls -t | head -n $1 | column;
}

AUTHOR_STRING='Martin Grödl <martin@process.studio> (https://process.studio)'
function new () {
  mkdir $1
  if [ $? -eq 0 ]; then
    cd $1
    npm init -y 1>/dev/null
    sed -i '' 's/"main": "index.js"/"private": true/g' package.json
    sed -i '' 's/1.0.0/0.1.0/g' package.json
    sed -i '' "s#\"author\": \"\"#\"author\": \"$AUTHOR_STRING\"#g" package.json
    sed -i '' 's/ISC"/AGPL-3.0",/g' package.json
    node=$(node -v); node="${node:1}" # remove first character ('v') from version string
    # add engines field with current versions of node and npm
    sed -i '' '$i\
      \ \ "engines": {\
      \ \ \ \ "node": "'$node'",\
      \ \ \ \ "npm": "'$(npm -v)'"\
      \ \ }\
      ' package.json
    echo "node_modules\n.DS_Store\nvenv\n.venv" > .gitignore
    git init 1>/dev/null
    sed -i '' 's/master/main/g' .git/HEAD # rename master to main
  fi
}

function quote () {
	emulate -L zsh
	Q=$(curl -s --connect-timeout 1 "http://www.quotationspage.com/random.php" | iconv -c -f ISO-8859-1 -t UTF-8 | grep -m 1 "dt ") 
	TXT=$(echo "$Q" | sed -e 's/<\/dt>.*//g' -e 's/.*html//g' -e 's/^[^a-zA-Z]*//' -e 's/<\/a..*$//g') 
	WHO=$(echo "$Q" | sed -e 's/.*\/quotes\///g' -e 's/<.*//g' -e 's/.*">//g') 
	[[ -n "$WHO" && -n "$TXT" ]] && echo "\"${TXT}\"\n\t-${WHO}"
}

function motd () {
  TD=$(date -r ~/.motd +%s 2>/dev/null || echo 0) # touch date in seconds (or 0 if date fails i.e. file doesn't exit)
  MD=$(date -v 0H -v 0M -v 0S +%s) # midnight date in seconds
  if (( TD < MD )); then
    # todo: handle timeout of quote
    quote > ~/.motd # get new quote and save it
  fi
  /bin/cat ~/.motd
}

# Show motd when logging in
echo; motd

# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
__conda_setup="$('/Users/mlg/miniconda3/bin/conda' 'shell.zsh' 'hook' 2> /dev/null)"
if [ $? -eq 0 ]; then
    eval "$__conda_setup"
else
    if [ -f "/Users/mlg/miniconda3/etc/profile.d/conda.sh" ]; then
        . "/Users/mlg/miniconda3/etc/profile.d/conda.sh"
    else
        export PATH="/Users/mlg/miniconda3/bin:$PATH"
    fi
fi
unset __conda_setup
# <<< conda initialize <<<

export PATH="/usr/local/sbin:$PATH"
