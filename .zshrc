# 2020-09-24, 2020-09-18, 2020-01-21, 2022-03-09, 2022-07-06, 2022-08-30, 2022-11-07, 2023-02-17, 2023-03-21, 2026-11-22
# Plugin selection mainly from:
# https://medium.com/@ahadsheriff/how-to-get-a-better-development-experience-on-your-mac-8478be58bba4


# set up homebrew environment in ~/.zprofile (if brew is installed, but not set up there yet)
# Note: Apple Silicon only (Homebrew in /opt/homebrew)
if [[ -x /opt/homebrew/bin/brew ]]; then
    if ! grep -qs "brew shellenv" ~/.zprofile; then
        print -P "%F{yellow}Note: Adding Homebrew setup to ~/.zprofile%f"
        {
            echo
            echo "# Homebrew (added by zsh-config)"
            echo 'eval "$(/opt/homebrew/bin/brew shellenv zsh)"'
        } >> ~/.zprofile
    fi
    # ~/.zprofile has already run for this shell, so set up homebrew now if needed
    which brew > /dev/null || eval "$(/opt/homebrew/bin/brew shellenv zsh)"
fi

# check for homebrew
if which brew > /dev/null; then
    # check for chroma (needed for colored cat/less/hexdump)
    which chroma > /dev/null || print -P "%F{yellow}Note: chroma is not installed (needed for colored cat/less). Install it with: brew install chroma%f"
else
    print -P "%F{yellow}Note: Homebrew (brew) is not installed. Install it from https://brew.sh%f"
fi


# VARIABLES
# Locale (UTF-8, English): the fallback for all LC_* categories (encoding, sorting, date formats, …)
# Terminal.app would set LANG from the system's language and region, but en_AT.UTF-8 doesn't exist;
# other terminals might not set it at all. Individual categories can still be overridden, e.g. LC_TIME.
export LANG=en_US.UTF-8
export EDITOR='nova'

# put ~/.local/bin (uv's python, python3 and uv tools) in front of the system paths
# Note: ~/.zshenv adds it too (via uv), but macOS's path_helper (in /etc/zprofile) then moves it behind /usr/bin
typeset -U path # remove duplicate entries from PATH (keeps the first one)
[[ -d ~/.local/bin ]] && path=(~/.local/bin $path)

# fnm (node version manager): put node/npm on the PATH,
# and switch versions automatically in folders with a .nvmrc or .node-version file
which fnm > /dev/null && eval "$(fnm env --use-on-cd --shell zsh)"


# PLUGINS
# Download Znap, if it's not there yet.
if [[ ! -f ~/.znap/zsh-snap/znap.zsh ]]; then
    print -P "%F{yellow}Installing Znap (zsh plugin manager) to ~/.znap/zsh-snap%f"
    git clone --depth 1 -- \
        https://github.com/marlonrichert/zsh-snap.git ~/.znap/zsh-snap
fi
source ~/.znap/zsh-snap/znap.zsh  # Start Znap

# pure prompt
znap source sindresorhus/pure async.zsh pure.zsh
# znap prompt sindresorhus/pure # fast prompt (needs to be put after motd though)

# add exit code to prompt (if non-zero) → breaks pwd display in pure prompt
# _PROMPT_NEWLINE=$'\n' # workaround to get newline within prompt
# PROMPT='%(?.%F{magenta}.%F{red}%?${_PROMPT_NEWLINE})❯%f '

# plugins
znap source zsh-users/zsh-autosuggestions
# oh-my-zsh plugins
znap source ohmyzsh/ohmyzsh lib/theme-and-appearance # required libraries for the following plugins
znap source ohmyzsh/ohmyzsh plugins/colored-man-pages
znap source ohmyzsh/ohmyzsh plugins/colorize # needs `pygments` or `chroma`. Installs `ccat` and `cless`
ZSH_COLORIZE_TOOL=chroma # use chroma, even if pygments is installed too
znap source ohmyzsh/ohmyzsh plugins/common-aliases
# Fix 'common-aliases' `-i` aliases
# rm/cp/mv: ask before deleting/overwriting , but only when there's a terminal to answer;
# without one (tools, scripts), the question can't be answered and would silently count as "no"
unalias rm cp mv 2> /dev/null
function rm () { if [[ -t 0 ]]; then command rm -i "$@"; else command rm "$@"; fi; }
function cp () { if [[ -t 0 ]]; then command cp -i "$@"; else command cp "$@"; fi; }
function mv () { if [[ -t 0 ]]; then command mv -i "$@"; else command mv "$@"; fi; }
# syntax highlighting: needs to be loaded after all other plugins (it wraps the widgets they define)
znap source zsh-users/zsh-syntax-highlighting


# OPTIONS
setopt auto_cd # cd by just typing the folder name
# setopt auto_pushd pushd_ignore_dups setopt pushd_minus


# ALIASES
alias ls='ls -G' # colored ls
# Colored cat/less (colorize plugin), but only when output goes to a terminal.
# Tools (e.g. Claude Code, IDEs) snapshot this shell's aliases/functions and replay them
# non-interactively, where colorize_cat breaks (it ignores file args when stdin isn't a tty).
# These are functions (not aliases) so the check happens at call time.
# Requires `colorize_cat`/`colorize_less` (functions from the colorize plugin) and `chroma` (brew install chroma).
# Note: call the functions, not the plugin's `ccat`/`cless` aliases. Znap compiles this file
# (~/.zshrc.zwc) before the plugin is loaded, so aliases inside function bodies never get expanded.
function cat () {
    # colorize only if: stdout is a tty, no options given (e.g. -n), colorize_cat and chroma are available
    # (checking $1 is enough: macOS cat only accepts options before file names)
    if [[ -t 1 && "$1" != -* ]] && which colorize_cat chroma > /dev/null; then
        # colorize_cat reads either files (stdin is a tty) or piped stdin (no file args), not both
        if [[ -t 0 && $# -gt 0 ]] || [[ ! -t 0 && $# -eq 0 ]]; then
            colorize_cat "$@"
            return
        fi
    fi
    command cat "$@"
}
function less () {
    if [[ -t 1 ]] && which colorize_less chroma > /dev/null; then
        colorize_less "$@"
    else
        command less "$@"
    fi
}

alias home='cd ~'
alias lanip="ifconfig | sed -En 's/127.0.0.1//;s/.*inet (addr:)?(([0-9]*\.){3}[0-9]*).*/\2/p'" #https://stackoverflow.com/a/13322549
alias wanip='curl http://ipecho.net/plain; echo'
alias edit="$EDITOR"


# FUNCTIONS
CODE_FOLDER=~/code # don't quote so tilde gets expanded
function code () {
    if (( $# == 0 )); then
        # of args is empty (length zero?)
        1=15
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
        sed -i '' 's/ISC"/AGPL-3.0"/g' package.json
        # sed -i '' 's/"type": "commonjs"/"type": "commonjs",/g' package.json # keep type line but add trailing comma
        sed -i '' '/"type"/d' package.json # delete "type" line
        node=$(node -v); node="${node:1}" # remove first character ('v') from version string
        # add engines field with current versions of node and npm (use caret ^ to allow minor and patch changes)
        sed -i '' '$i\
\ \ "engines": {\
\ \ \ \ "node": "^'$node'",\
\ \ \ \ "npm": "^'$(npm -v)'"\
\ \ }
' package.json
        # node major version for fnm, which switches to it when entering the folder
        # (major only, like the ^ in engines: any installed 26.x.x matches "26")
        echo "${node%%.*}" > .node-version
        echo "node_modules\n.DS_Store\n__pycache__\nvenv\n.venv" > .gitignore
        git init -b main 1>/dev/null
    fi
}

# Print a random quote
# Usage: quote [timeout-in-seconds] (default 10; the limit for the whole request, not just connecting)
function quote () {
    local QUOTE_TIMEOUT=10 Q TXT WHO
    [[ -n "$1" ]] && QUOTE_TIMEOUT=$1
    emulate -L zsh
    Q=$(curl -s --max-time $QUOTE_TIMEOUT -L "https://www.quotationspage.com/random.php" | iconv -c -f ISO-8859-1 -t UTF-8 | grep -m 1 "dt ")
    TXT=$(echo "$Q" | sed -e 's/<\/dt>.*//g' -e 's/.*html//g' -e 's/^[^a-zA-Z]*//' -e 's/<\/a..*$//g')
    setopt extended_glob # extended globbing required for next line
    TXT="${TXT// #<br> #/\n}" # replace <br> with newlines (preceded and followed by 0 or more spaces)
    WHO=$(echo "$Q" | sed -e 's/.*\/quotes\///g' -e 's/<.*//g' -e 's/.*">//g')
    [[ -n "$WHO" && -n "$TXT" ]] && echo "\"${TXT}\"\n\t-${WHO}"
}

# https://gist.github.com/jaytaylor/6527607
# TODO: only supports `timeout SECONDS command`: unit suffixes are silently dropped (`timeout 1m …` stops
#       after 1 second!), no options like -k/--signal, no exit code 124 on timeout. It would also shadow
#       a real `timeout` command if one gets installed, also in tools that replay this shell's functions.
#       Rename it, or fall back to the real one if installed.
function timeout() { perl -e 'alarm shift; exec @ARGV' "$@"; }

function motd () {
    local TD MD new_quote
    TD=$(date -r ~/.motd +%s 2>/dev/null || echo 0) # touch date in seconds (or 0 if date fails i.e. file doesn't exist)
    MD=$(date -v 0H -v 0M -v 0S +%s) # midnight date in seconds
    if (( TD < MD )) || [[ "$1" == "-f" ]]; then # (( )) compares numbers ([[ < ]] would compare strings)
        new_quote=$(quote 3) # get new quote (timeout 3 seconds)
        [[ -n $new_quote ]] && echo $new_quote > ~/.motd # save, if not empty
    fi
    /bin/cat ~/.motd
}

# Python virtual environments (via uv)
# A venv is a folder named .venv (uv's default) or venv (older projects) containing a pyvenv.cfg.
# It is activated automatically when entering the project folder (or any of its subfolders),
# and deactivated when leaving it.
VENV_NAMES=(.venv venv)
GRAY="\033[2;37m"
NC="\033[0m"

# Print the path of the nearest venv, searching the current folder and then its parent folders
function findvenv () {
    local dir=$PWD name
    while true; do
        for name in $VENV_NAMES; do
            if [[ -f "$dir/$name/pyvenv.cfg" ]]; then
                echo "$dir/$name"
                return 0
            fi
        done
        [[ $dir == / ]] && return 1
        dir=${dir:h} # parent folder
    done
}

# Create a venv in the current folder (and activate it)
# Usage: mkvenv [python-version] (e.g. `mkvenv 3.14`; the version is pinned in .python-version)
# Without a version, an existing .python-version is used, or the default version (e.g. 3.15) is pinned
function mkvenv () {
    local name
    for name in $VENV_NAMES; do
        if [[ -f "$PWD/$name/pyvenv.cfg" ]]; then
            echo "venv already present: ${GRAY}$PWD/$name${NC}"
            return 1
        fi
    done
    if [[ -n "$1" ]]; then
        uv python pin "$1" || return 1 # writes .python-version
    elif [[ ! -f .python-version ]]; then
        # pin the minor version of the python uv would use here (e.g. 3.15.2 → 3.15)
        local version
        version=$(uv python find --show-version) || return 1
        uv python pin "${version%.*}" || return 1
    fi
    echo "Creating venv: ${GRAY}$PWD/.venv${NC}"
    if [[ -f pyproject.toml ]]; then
        uv sync --quiet || return 1 # uv project: create .venv and install its dependencies
    else
        uv venv --quiet || return 1 # uses the version from .python-version (if present)
    fi
    switchvenv
}

# Remove the venv in the current folder (and deactivate it)
function rmvenv () {
    local name venv
    for name in $VENV_NAMES; do
        venv="$PWD/$name"
        if [[ -f "$venv/pyvenv.cfg" ]]; then
            if [[ $VIRTUAL_ENV == "$venv" ]] && (( $+functions[deactivate] )); then
                echo "Deactivating venv: ${GRAY}$venv${NC}"
                deactivate
            fi
            echo "Removing venv: ${GRAY}$venv${NC}"
            rm -rf "$venv"
            return 0
        fi
    done
    echo "No venv in the current folder"
    return 1
}

# Activate the nearest venv (if it isn't active yet), or deactivate when we left the project
function switchvenv () {
    local venv=$(findvenv)
    [[ $venv == "$VIRTUAL_ENV" ]] && return # already active (or no venv and none active)
    if [[ -n $VIRTUAL_ENV ]] && (( $+functions[deactivate] )); then
        echo "Deactivating venv: ${GRAY}$VIRTUAL_ENV${NC}"
        deactivate
    fi
    if [[ -n $venv ]]; then
        source "$venv/bin/activate"
        echo "Activating venv: ${GRAY}$venv ($(python --version))${NC}"
    fi
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


# Check Node, Python, Rust, npm and Homebrew for outdated versions
# Note: the _outdated_update_* variables are global on purpose: a check stores the update command there,
# and a later `outdated update` reuses it (without checking again)
function outdated () {
    local FN_NAME=$0

    function check_node() {
        which fnm > /dev/null 2>&1 || {
            [[ $1 != "nowarn" ]] && echo "node (fnm) is not installed"
            return 1
        }
    }
    
    function check_py() {
        which uv > /dev/null 2>&1 || {
            [[ $1 != "nowarn" ]] && echo "python (uv) is not installed"
            return 1
        }
    }
    
    function check_npm() {
        which npm > /dev/null 2>&1 || {
            [[ $1 != "nowarn" ]] && echo "npm is not installed"
            return 1
        }
    }
    
    function check_brew() {
        which brew > /dev/null 2>&1 || {
            [[ $1 != "nowarn" ]] && echo "brew is not installed"
            return 1
        }
    }
    
    function check_rust() {
        which rustup > /dev/null 2>&1 || {
            [[ $1 != "nowarn" ]] && echo "rust (rustup) is not installed"
            return 1
        }
    }
    
    ## node (via fnm)
    function out_node() {
        check_node $1 || return 1
        echo "node"
        echo "-------------------"
        local node_current node_latest
        # current: fnm's default version (not `node -v`, which can be a per-project version via --use-on-cd)
        node_current=$(fnm default 2>/dev/null) # e.g. "v26.13.1"
        node_current=${node_current#v}
        [[ -z $node_current ]] && node_current="none"
        # latest: newest LTS release, e.g. "v26.13.1 (Lithium)"
        node_latest=$(fnm ls-remote --lts --latest 2>/dev/null | sed -E 's/^v([0-9.]+).*/\1/')
        if [[ -z $node_latest ]]; then
            echo "Couldn't get the latest LTS version (offline?)"
            return 1
        fi
        if [[ $node_current == $node_latest ]]; then
            echo "✅          $node_current"
        else
            echo "Latest LTS: $node_latest"
            echo "Current:    $node_current"
            # install, make it the default for new shells, and use it in this shell
            _outdated_update_node="fnm install $node_latest && fnm default $node_latest && fnm use $node_latest"
            if [[ $1 != "noupcmd" ]]; then
                echo "🔄 Update with \`$FN_NAME update node\` (or \`$_outdated_update_node\`)"
            fi
        fi
    }
    
    ## python (via uv)
    function out_py() {
        check_py $1 || return 1
        echo "\npython"
        echo   "-------------------"
        # current: the default python (`python` executable installed by `uv python install --default`)
        local python_bin="$(uv python dir --bin)/python" python_current python_latest
        python_current="none"
        if [[ -x "$python_bin" ]]; then
            python_current=$("$python_bin" --version) # e.g. "Python 3.15.2"
            python_current=${python_current#Python }
        fi
        # latest: newest stable cpython known to uv (skips alpha/beta/rc and freethreaded builds)
        # Note: the list of available versions comes with uv itself, so it's only as recent as uv
        python_latest=$(uv python list --managed-python | grep -E '^cpython-[0-9]+\.[0-9]+\.[0-9]+-' \
            | head -1 | sed -E 's/^cpython-([0-9.]+)-.*/\1/')
        if [[ -z $python_latest ]]; then
            echo "Couldn't get the latest Python version"
            return 1
        fi
        if [[ $python_current == $python_latest ]]; then
            echo "✅           $python_current"
        else
            echo "Latest:      $python_latest"
            echo "Current:     $python_current"
            # --default (installs `python` and `python3`) is still experimental in uv;
            # --preview-features opts in to it and silences the warning
            _outdated_update_py="uv python install --default --preview-features python-install-default $python_latest"
            if [[ $1 != "noupcmd" ]]; then
                echo "🔄 Update with \`$FN_NAME update py\` (or \`$_outdated_update_py\`)"
            fi
        fi
    }
    
    ## npm
    function out_npm() {
        check_npm $1 || return 1
        echo "\nnpm"
        echo   "-------------------"
        local npm_out
        npm_out=$(npm out -g)
        if [[ -z "$npm_out" ]]; then
            echo "✅"
        else
            echo $npm_out
            # echo "🔄 Update with \`npm i -g <package>\`"
            npm_out=`echo "$npm_out" | tail -n +2` # remove header (1 line)
            npm_out=`echo "$npm_out" | sed -e 's/[[:space:]].*$//'` # only keep first part of each line
            npm_out=`echo "$npm_out" | xargs` # contract to arg list
            _outdated_update_npm="npm i -g $npm_out"
            if [[ $1 != "noupcmd" ]]; then
                echo "🔄 Update with \`$FN_NAME update npm\` (or \`$_outdated_update_npm\`)"
            fi
        fi
    }
    
    ## uv tools
    # No global pip anymore (uv uses per-project venvs). If we start using uv tools
    # (`uv tool install …`), add a check here: `uv tool list --outdated` / `uv tool upgrade --all`

    ## homebrew
    function out_brew() {
        check_brew $1 || return 1
        echo "\nbrew"
        echo   "-------------------"
        brew update --quiet
        local brew_out
        brew_out=$(brew outdated)
        if [[ -z "$brew_out" ]]; then
            echo "✅"
        else
            echo $brew_out
            _outdated_update_brew="brew upgrade"
            if [[ $1 != "noupcmd" ]]; then
                echo "🔄 Update with \`$FN_NAME update brew\` (or \`$_outdated_update_brew\`)"
            fi
        fi
    }
    
    ## rust
    function out_rust() {
        check_rust $1 || return 1
        echo "\nrust"
        echo   "-------------------"
        local rust_out rust_current
        rust_out=$(rustup check)
        if [[ "$rust_out" == *"up to date"* ]]; then
            rust_current=`echo "$rust_out" | sed -r 's/^.*up to date: ([^ ]+).*$/\1/'`
            echo "✅           $rust_current"
        else
            echo $rust_out
            _outdated_update_rust="rustup update"
            if [[ $1 != "noupcmd" ]]; then
                echo "🔄 Update with \`$FN_NAME update rust\` (or \`$_outdated_update_rust\`)"
            fi
        fi
    }
    
    function out_all() {
        out_node nowarn; out_py nowarn; out_rust nowarn; out_npm nowarn; out_brew nowarn
    }
    
    function up_node() {
        check_node $1 || return 1
        [[ -z "$_outdated_update_node" ]] && out_node noupcmd
        if [[ ! -z "$_outdated_update_node" ]]; then
            echo "\n🆙 Updating node..."
            echo "Running \`$_outdated_update_node\`"
            eval "$_outdated_update_node"
            _outdated_update_node=''
        fi
    }
    
    function up_py() {
        check_py $1 || return 1
        [[ -z "$_outdated_update_py" ]] && out_py noupcmd
        if [[ ! -z "$_outdated_update_py" ]]; then
            echo "\n🆙 Updating python..."
            echo "Running \`$_outdated_update_py\`"
            eval "$_outdated_update_py"
            _outdated_update_py=''
        fi
    }
    
    function up_npm() {
        check_npm $1 || return 1
        [[ -z "$_outdated_update_npm" ]] && out_npm noupcmd
        if [[ ! -z "$_outdated_update_npm" ]]; then
            echo "\n🆙 Updating npm packages..."
            echo "Running \`$_outdated_update_npm\`"
            eval "$_outdated_update_npm"
            _outdated_update_npm=''
        fi
    }
    
    function up_brew() {
        check_brew $1 || return 1
        [[ -z "$_outdated_update_brew" ]] && out_brew noupcmd
        if [[ ! -z "$_outdated_update_brew" ]]; then
            echo "\n🆙 Updating brew packages..."
            echo "Running \`$_outdated_update_brew\`"
            eval "$_outdated_update_brew"
            _outdated_update_brew=''
        fi
    }
    
    function up_rust() {
        check_rust $1 || return 1
        [[ -z "$_outdated_update_rust" ]] && out_rust noupcmd
        if [[ ! -z "$_outdated_update_rust" ]]; then
            echo "\n🆙 Updating rust..."
            echo "Running \`$_outdated_update_rust\`"
            eval "$_outdated_update_rust"
            _outdated_update_rust=''
        fi
    }
    
    function up_all() {
        up_node nowarn; up_py nowarn; up_rust nowarn; up_npm nowarn; up_brew nowarn
    }
    
    function usage() {
        echo "Usage:"
        echo "  Check all:        $FN_NAME"
        echo "  Check specific:   $FN_NAME [node|python|py|rust|npm|homebrew|brew|all]"
        echo "  Update all:       $FN_NAME update|up"
        echo "  Update specific:  $FN_NAME update|up [node|python|py|rust|npm|homebrew|brew|all]"
    }
    
    if [[ $1 == "node" ]] ; then
        out_node
    elif [[ $1 == "python" || $1 == "py" ]]; then
        out_py
    elif [[ $1 == "npm" ]]; then
        out_npm
    elif [[ $1 == "homebrew" || $1 == "brew" ]]; then
        out_brew
    elif [[ $1 == "rust" ]]; then
        out_rust
    elif [[ $1 == "all" || -z "$1" ]]; then
        out_all
    elif [[ $1 == "update" || $1 == "up" ]]; then
        if [[ $2 == "node" ]]; then
            up_node
        elif [[ $2 == "python" || $2 == "py" ]]; then
            up_py
        elif [[ $2 == "npm" ]]; then
            up_npm
        elif [[ $2 == "homebrew" || $2 == "brew" ]]; then
            up_brew
        elif [[ $2 == "rust" ]]; then
            up_rust
        elif [[ $2 == "all" || -z "$2" ]]; then
            up_all
        else
            usage
        fi
    else
        usage
    fi
    local exit_status=$?

    # remove the helper functions again (zsh defines functions inside functions globally)
    unfunction check_node check_py check_npm check_brew check_rust \
        out_node out_py out_npm out_brew out_rust out_all \
        up_node up_py up_npm up_brew up_rust up_all usage
    return $exit_status
}

# Hexdump
# TODO: shadows /usr/bin/hexdump with a different interface (`hexdump file [lines]`), so the standard
#       `hexdump -C file` fails ("bad math expression"), also in tools that replay this shell's functions.
#       Rename it (e.g. `hd`), or fall back to `command hexdump` when the first argument is an option.
function hexdump () {
    if [[ -z "$1" ]]; then
        echo "Usage:"
        echo "  $0 file [number-of-lines]"
        return 1
    fi
    if [[ -t 1 ]]; then
        # stdout is a terminal
        local NUM_LINES=20
        [[ -n "$2" ]] && NUM_LINES="$2"
        # highlight with chroma (if available), using the same style as the colorize plugin
        local highlight=(command cat)
        which chroma > /dev/null && highlight=(chroma --lexer=hexdump \
            --style="${ZSH_COLORIZE_STYLE:-emacs}" --formatter="${ZSH_COLORIZE_CHROMA_FORMATTER:-terminal}")
        if [[ $NUM_LINES -eq 0 ]]; then
            xxd $1 | $highlight
        else
            xxd $1 | head -n "$NUM_LINES" | $highlight
        fi
        [[ -z "$2" ]] && echo "/*\n    Output truncated to $NUM_LINES lines.\n    Specify number of lines as 2nd argument (0 for unlimited).\n    When redirecting to a file (with \'>\'), the whole file is dumped by default.\n*/"
    else
        # stdout isn't a terminal
        local NUM_LINES=0
        [[ -n "$2" ]] && NUM_LINES="$2"
        if [[ $NUM_LINES -eq 0 ]]; then
            xxd $1
        else
            xxd $1 | head -n "$NUM_LINES"
        fi
    fi
}

# Get path of c header file
function cheader () {
    if [[ -z "$1" ]]; then
        echo "Usage:"
        echo "  $0 header-filename ... Print path of C header file (.h can be omitted)"
        return 1
    fi

    # add .h if omitted
    if [[ "$1" != *.h ]]; then
        1="$1.h"
    fi

    # list of paths
    local paths=() p sdk

    paths+=("/usr/include/$1")
    if [[ $(uname) == 'Darwin' ]]; then
        # macOS SDK (from the Command Line Tools or Xcode, whichever is selected)
        sdk=$(xcrun --show-sdk-path 2> /dev/null)
        [[ -n $sdk ]] && paths+=("$sdk/usr/include/$1")
        # Homebrew (/opt/homebrew on Apple Silicon)
        paths+=("${HOMEBREW_PREFIX:-/opt/homebrew}/include/$1")
    fi
    paths+=("/usr/local/include/$1")

    for p in $paths; do
        # check if file exists
        if [[ -f $p ]]; then
            echo "$p"
            return 0
        fi
    done
   
    echo "Couldn't find header $1"
    return 2
}
alias ch=cheader

# Box drawing alignment tests
# https://stackoverflow.com/q/54718201
# https://www.w3.org/2001/06/utf-8-test/UTF-8-demo.html
function box-drawing-test () {
    cat << EOF
Box drawing alignment tests:                                          █
                                                                      ▉
  ╔══╦══╗  ┌──┬──┐  ╭──┬──╮  ╭──┬──╮  ┏━━┳━━┓  ┎┒┏┑   ╷  ╻ ┏┯┓ ┌┰┐    ▊ ╱╲╱╲╳╳╳
  ║┌─╨─┐║  │╔═╧═╗│  │╒═╪═╕│  │╓─╁─╖│  ┃┌─╂─┐┃  ┗╃╄┙  ╶┼╴╺╋╸┠┼┨ ┝╋┥    ▋ ╲╱╲╱╳╳╳
  ║│╲ ╱│║  │║   ║│  ││ │ ││  │║ ┃ ║│  ┃│ ╿ │┃  ┍╅╆┓   ╵  ╹ ┗┷┛ └┸┘    ▌ ╱╲╱╲╳╳╳
  ╠╡ ╳ ╞╣  ├╢   ╟┤  ├┼─┼─┼┤  ├╫─╂─╫┤  ┣┿╾┼╼┿┫  ┕┛┖┚     ┌┄┄┐ ╎ ┏┅┅┓ ┋ ▍ ╲╱╲╱╳╳╳
  ║│╱ ╲│║  │║   ║│  ││ │ ││  │║ ┃ ║│  ┃│ ╽ │┃  ░░▒▒▓▓██ ┊  ┆ ╎ ╏  ┇ ┋ ▎
  ║└─╥─┘║  │╚═╤═╝│  │╘═╪═╛│  │╙─╀─╜│  ┃└─╂─┘┃  ░░▒▒▓▓██ ┊  ┆ ╎ ╏  ┇ ┋ ▏
  ╚══╩══╝  └──┴──┘  ╰──┴──╯  ╰──┴──╯  ┗━━┻━━┛           └╌╌┘ ╎ ┗╍╍┛ ┋  ▁▂▃▄▅▆▇█
EOF
}

# Show motd when logging in
echo; motd

switchvenv_init


# --------------------------------------
# AUTOMATICALLY UPDATED BELOW THIS POINT
# --------------------------------------
