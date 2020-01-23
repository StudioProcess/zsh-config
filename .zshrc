# 2020-01-21
# Plugin selection mainly from:
# https://medium.com/@ahadsheriff/how-to-get-a-better-development-experience-on-your-mac-8478be58bba4
#
# Requirements
# zplug: curl -sL --proto-redir -all,https https://raw.githubusercontent.com/zplug/installer/master/installer.zsh | zsh
# pygments (for colorize): pip3 install pygments --user



# PLUGINS
# zplug 
source ~/.zplug/init.zsh

# pure prompt
zplug mafredri/zsh-async, from:github
zplug sindresorhus/pure, use:pure.zsh, from:github, as:theme

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
zplug "plugins/cp", from:oh-my-zsh
zplug "plugins/git", from:oh-my-zsh
# zplug "plugins/node", from:oh-my-zsh
# zplug "plugins/npm", from:oh-my-zsh
zplug "plugins/sudo", from:oh-my-zsh
# zplug "plugins/yarn", from:oh-my-zsh
zplug "plugins/z", from:oh-my-zsh

zplug "zsh-users/zsh-syntax-highlighting"
zplug "zsh-users/zsh-autosuggestions"

if ! zplug check --verbose; then
  zplug install
fi

zplug load



# VARIABLES
export PATH=/Users/$USER/Library/Python/3.7/bin:$PATH # add pip3 user folder to path (for pygmentize)
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
    sed -i '' 's/1.0.0/0.1.0/g' package.json
    sed -i '' 's/ISC/AGPL-3.0/g' package.json
    sed -i '' "s#\"author\": \"\"#\"author\": \"$AUTHOR_STRING\"#g" package.json
    echo 'node_modules' > .gitignore
    git init 1>/dev/null
  fi
}

function quote () {
	emulate -L zsh
	Q=$(curl -s --connect-timeout 2 "http://www.quotationspage.com/random.php" | iconv -c -f ISO-8859-1 -t UTF-8 | grep -m 1 "dt ") 
	TXT=$(echo "$Q" | sed -e 's/<\/dt>.*//g' -e 's/.*html//g' -e 's/^[^a-zA-Z]*//' -e 's/<\/a..*$//g') 
	WHO=$(echo "$Q" | sed -e 's/.*\/quotes\///g' -e 's/<.*//g' -e 's/.*">//g') 
	[[ -n "$WHO" && -n "$TXT" ]] && echo "\"${TXT}\"\n\t-${WHO}"
}
