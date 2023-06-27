# 2020-09-24, 2020-09-18, 2020-01-21, 2022-03-09, 2022-07-06, 2022-08-30, 2022-11-07, 2023-02-17, 2023-03-21
# Plugin selection mainly from:
# https://medium.com/@ahadsheriff/how-to-get-a-better-development-experience-on-your-mac-8478be58bba4
#
# Requirements
# pygments (for colorize): brew install pygments


# install homebrew if necessary (https://brew.sh)
which brew > /dev/null || /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# install pygments if necessary
which pygmentize > /dev/null || brew install pygments


# VARIABLES
export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8
export EDITOR='nova'
# Note: homebrew bins are linked from /usr/local/bin, which is already in the path
export PATH="/usr/local/sbin:$PATH"
export PATH="/usr/local/opt/python@3/libexec/bin:$PATH" # python3 unversioned symlinks (from homebrew)
which pyenv > /dev/null && export PATH="$(pyenv root)/shims:$PATH" # pyenv (if installed)


# PLUGINS
# Download Znap, if it's not there yet.
[[ -f ~/.znap/zsh-snap/znap.zsh ]] ||
    git clone --depth 1 -- \
        https://github.com/marlonrichert/zsh-snap.git ~/.znap/zsh-snap
source ~/.znap/zsh-snap/znap.zsh  # Start Znap

# pure prompt
znap source sindresorhus/pure async.zsh pure.zsh
# znap prompt sindresorhus/pure # fast prompt (needs to be put after modt though)

# plugins
znap source zsh-users/zsh-syntax-highlighting
znap source zsh-users/zsh-autosuggestions

# znap source MichaelAquilina/zsh-autoswitch-virtualenv
#export AUTOSWITCH_VIRTUAL_ENV_DIR="./venv" # store virtualenvs in each project folder
## export AUTOSWITCH_VIRTUAL_ENV_DIR="." # store virtualenvs in each project folder
## export AUTOSWITCH_VIRTUAL_ENV_NAME="venv"

# oh-my-zsh plugins
znap source ohmyzsh/ohmyzsh lib/theme-and-appearance # required libraries for the following plugins
znap source ohmyzsh/ohmyzsh plugins/colored-man-pages
znap source ohmyzsh/ohmyzsh plugins/colorize
znap source ohmyzsh/ohmyzsh plugins/common-aliases



# OPTIONS
setopt auto_cd # cd by just typing the folder name
# setopt auto_pushd pushd_ignore_dups setopt pushd_minus



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
alias edit="$EDITOR"



# FUNCTIONS
CODE_FOLDER=~/code # don't quote so tilde gets expanded
function code () {
    if (( $# == 0 )); then
        # of args is empty (length zero?)
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
        # add engines field with current versions of node and npm (use caret ^ to allow minor and patch changes)
        sed -i '' '$i\
\ \ "engines": {\
\ \ \ \ "node": "^'$node'",\
\ \ \ \ "npm": "^'$(npm -v)'"\
\ \ }\
' package.json
        echo "node_modules\n.DS_Store\n__pycache__\nvenv\n.venv" > .gitignore
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

# https://gist.github.com/jaytaylor/6527607
function timeout() { perl -e 'alarm shift; exec @ARGV' "$@"; }

function motd () {
    TD=$(date -r ~/.motd +%s 2>/dev/null || echo 0) # touch date in seconds (or 0 if date fails i.e. file doesn't exit)
    MD=$(date -v 0H -v 0M -v 0S +%s) # midnight date in seconds
    if [[ $TD < $MD || "$1" == "-f" ]]; then
        # todo: handle timeout of quote
        new_quote=$(quote) # get new quote
        [[ -n $new_quote ]] && echo $new_quote > ~/.motd # save, if not empty
    fi
    /bin/cat ~/.motd
}

# Autoswitch python venv
# Looks in $VENV_DIR and one subdirectory deep for pyvenv.cfg
VENV_DIR='venv'
GRAY="\033[2;37m"
NC="\033[0m"
function mkvenv () {
    if [[ -f "$PWD/$VENV_DIR/pyvenv.cfg" ]]; then
        echo "venv already present: ${GRAY}$PWD/$VENV_DIR${NC}"
        return
    fi
    echo "Creating venv: ${GRAY}$PWD/$VENV_DIR${NC}"
    python -m venv $VENV_DIR
    [[ -f "$PWD/$VENV_DIR/pyvenv.cfg" ]] && source $PWD/$VENV_DIR/bin/activate
}
function rmvenv () {
    for venv_dir in $VENV_DIR $VENV_DIR/*(N); do
        if [[ -f "$PWD/$venv_dir/pyvenv.cfg" ]]; then
            echo "Removing venv: ${GRAY}$PWD/$venv_dir${NC}"
            [[ -n $VIRTUAL_ENV ]] && deactivate
            rm -rf $PWD/$venv_dir
        fi
    done
}
function switchvenv () {
    if [[ -n $VIRTUAL_ENV ]]; then
        # a virtual env is already activated
        local DIR=$(dirname $VIRTUAL_ENV) # parnt directory of the venv
        # if we are in a subdirectory of $DIR do nothing; we are already activated
        if [[ $PWD == $DIR || $PWD == $DIR/* ]]; then
            # echo 'already activated'
            return
        fi
        # we are not in a directory of the activated env; deactivate
        echo "Deactivating venv: ${GRAY}$VIRTUAL_ENV${NC}";
        deactivate
    fi
    for venv_dir in $VENV_DIR $VENV_DIR/*(N); do # the N supresses an error when no expansion can't be found (nullglob)
        if [[ -f "$PWD/$venv_dir/pyvenv.cfg" ]]; then
            echo "Activating venv: ${GRAY}$PWD/$venv_dir${NC}";
            source $PWD/$venv_dir/bin/activate
            break
        fi
    done;
}
function switchvenv_first() {
    add-zsh-hook -D precmd switchvenv_first
    add-zsh-hook chpwd switchvenv
    switchvenv
}
function switchvenv_init() {
    autoload -Uz add-zsh-hook
    add-zsh-hook precmd switchvenv_first
}


# Check Node, Python and Homebrew for outdated versions
function outdated () {
    FN_NAME=$0
    
    ## node
    function out_node() {
        echo "node"
        echo "-------------------"
        node_current=${"$(node -v)":1} # remove leading 'v'
        node_latest=$(n lsr lts)
        if [[ $node_current == $node_latest ]]; then
            echo "✅          $node_current"
        else
            echo "Latest LTS: $node_latest"
            echo "Current:    $node_current"
            export _outdated_update_node="n lts --preserve"
            if [[ $1 != "noupcmd" ]]; then
                echo "🔄 Update with \`$FN_NAME update node\` (or \`$_outdated_update_node\`)"
            fi
        fi
    }
    
    ## python
    function out_py() {
        echo "\npython"
        echo   "-------------------"
        python_current=$(pyenv version-name)
        ## latest (without characters other than digits and .) Note: xargs trims the string
        python_latest=$(pyenv install --list | grep -E "^\s+[0-9.]+$" | tail -1 | xargs echo)
        if [[ $python_current == $python_latest ]]; then
            echo "✅           $python_current"
        else
            echo "Latest:      $python_latest"
            echo "Current:     $python_current"
            export _outdated_update_py="pyenv install $python_latest"
            if [[ $1 != "noupcmd" ]]; then
                echo "🔄 Update with \`$FN_NAME update py\` (or \`$_outdated_update_py\`)"
            fi
        fi
    }
    
    ## npm
    function out_npm() {
        echo "\nnpm"
        echo   "-------------------"
        npm_out=$(npm out -g)
        if [[ -z "$npm_out" ]]; then
            echo "✅"
        else
            echo $npm_out
            # echo "🔄 Update with \`npm i -g <package>\`"
            npm_out=`echo "$npm_out" | tail -f -n +2` # remove header (1 line)
            npm_out=`echo "$npm_out" | sed -e 's/[[:space:]].*$//'` # only keep first part of each line
            npm_out=`echo "$npm_out" | xargs` # contract to arg list
            export _outdated_update_npm="npm i -g $npm_out"
            if [[ $1 != "noupcmd" ]]; then
                echo "🔄 Update with \`$FN_NAME update npm\` (or \`$_outdated_update_npm\`)"
            fi
        fi
    }
    
    ## pip
    function out_pip() {
        echo "\npip"
        echo   "-------------------"
        pip_out=$(pyenv exec pip list --outdated)
        if [[ -z "$pip_out" ]]; then
            echo "✅"
        else
            echo $pip_out
            # echo "🔄 Update with \`pip install --upgrade <package>\`"
            pip_out=`echo "$pip_out" | tail -f -n +3` # remove header (2 lines)
            pip_out=`echo "$pip_out" | sed -e 's/[[:space:]].*$//'` # only keep first part of each line
            pip_out=`echo "$pip_out" | xargs` # contract to arg list
            export _outdated_update_pip="pip install --upgrade $pip_out"
            if [[ $1 != "noupcmd" ]]; then
                echo "🔄 Update with \`$FN_NAME update pip\` (or \`$_outdated_update_pip\`)"
            fi
        fi
    }
    
    ## homebrew
    function out_brew() {
        echo "\nbrew"
        echo   "-------------------"
        brew update --quiet
        brew_out=$(brew outdated)
        if [[ -z "$brew_out" ]]; then
            echo "✅"
        else
            echo $brew_out
            export _outdated_update_brew="brew upgrade"
            if [[ $1 != "noupcmd" ]]; then
                echo "🔄 Update with \`$FN_NAME update brew\` (or \`$_outdated_update_brew\`)"
            fi
        fi
    }
    
    function out_all() {
        out_node; out_py; out_npm; out_pip; out_brew
    }
    
    function up_node() {
        [[ -z "$_outdated_update_node" ]] && out_node noupcmd
        if [[ ! -z "$_outdated_update_node" ]]; then
            echo "\n🆙 Updating node..."
            echo "Running \`$_outdated_update_node\`"
            eval "$_outdated_update_node"
            export _outdated_update_node=''
        fi
    }
    
    function up_py() {
        [[ -z "$_outdated_update_py" ]] && out_py noupcmd
        if [[ ! -z "$_outdated_update_py" ]]; then
            echo "\n🆙 Updating python..."
            echo "Running \`$_outdated_update_py\`"
            eval "$_outdated_update_py"
            export _outdated_update_py=''
        fi
    }
    
    function up_npm() {
        [[ -z "$_outdated_update_npm" ]] && out_npm noupcmd
        if [[ ! -z "$_outdated_update_npm" ]]; then
            echo "\n🆙 Updating npm packages..."
            echo "Running \`$_outdated_update_npm\`"
            eval "$_outdated_update_npm"
            export _outdated_update_npm=''
        fi
    }
    
    function up_pip() {
        [[ -z "$_outdated_update_pip" ]] && out_pip noupcmd
        if [[ ! -z "$_outdated_update_pip" ]]; then
            echo "\n🆙 Updating pip packages..."
            echo "Running \`$_outdated_update_pip\`"
            eval "$_outdated_update_pip"
            export _outdated_update_pip=''
        fi
    }
    
    function up_brew() {
        [[ -z "$_outdated_update_brew" ]] && out_brew noupcmd
        if [[ ! -z "$_outdated_update_brew" ]]; then
            echo "\n🆙 Updating brew packages..."
            echo "Running \`$_outdated_update_brew\`"
            eval "$_outdated_update_brew"
            export _outdated_update_brew=''
        fi
    }
    
    function up_all() {
        up_node; up_py; up_npm; up_pip; up_brew
    }
    
    function usage() {
        echo "Usage:"
        echo "  Check all:        $FN_NAME"
        echo "  Check specific:   $FN_NAME [node|python|py|npm|pip|homebrew|brew|all]"
        echo "  Update all:       $FN_NAME update|up"
        echo "  Update specific:  $FN_NAME update|up [node|python|py|npm|pip|homebrew|brew|all]"
    }
    
    if [[ $1 == "node" ]] ; then
        out_node
    elif [[ $1 == "python" || $1 == "py" ]]; then
        out_py
    elif [[ $1 == "npm" ]]; then
        out_npm
    elif [[ $1 == "pip" ]]; then
        out_pip
    elif [[ $1 == "homebrew" || $1 == "brew" ]]; then
        out_brew
    elif [[ $1 == "all" || -z "$1" ]]; then
        out_all
    elif [[ $1 == "update" || $1 == "up" ]]; then
        if [[ $2 == "node" ]]; then
            up_node
        elif [[ $2 == "python" || $2 == "py" ]]; then
            up_py
        elif [[ $2 == "npm" ]]; then
            up_npm
        elif [[ $2 == "pip" ]]; then
            up_pip
        elif [[ $2 == "homebrew" || $2 == "brew" ]]; then
            up_brew
        elif [[ $2 == "all" || -z "$2" ]]; then
            up_all
        else
            usage
        fi
    else
        usage
    fi  
}

# Show motd when logging in
echo; motd

switchvenv_init



# --------------------------------------
# AUTOMATICALLY UPDATED BELOW THIS POINT
# --------------------------------------

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
export PATH="/usr/local/opt/openssl@3/bin:$PATH"
