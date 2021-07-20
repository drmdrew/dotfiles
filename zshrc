# for ZSH
case "$OSTYPE" in
  darwin*)
    # Node/nvm
    export NVM_DIR=~/.nvm
    source $(brew --prefix nvm)/nvm.sh
    # Swift
    export PATH=/Library/Developer/Toolchains/swift-latest.xctoolchain/usr/bin:"${PATH}"
    # Go
    # launchctl setenv GOPATH $GOPATH

    export PATH="$PATH:$HOME/.rvm/bin" # Add RVM to PATH for scripting
  ;;
  linux*)
    # ...
  ;;
esac

# Path to oh-my-zsh install/customizations if present
if [ ! -f ~/.oh-my-zsh/oh-my-zsh.sh ]; then
  ln -s ~/dotfiles/oh-my-zsh ~/.oh-my-zsh
  export ZSH=~/.oh-my-zsh
fi
export ZSH=~/.oh-my-zsh

# Path to oh-my-zsh install/customizations if present
if [ ! -f ~/.vim/bundle ]; then
  cp -r ~/dotfiles/vim ~/.vim
fi

# Set name of the theme to load.
# Look in ~/.oh-my-zsh/themes/
# Optionally, if you set this to "random", it'll load a random theme each
# time that oh-my-zsh is loaded.
#ZSH_THEME="robbyrussell"
#ZSH_THEME="darkblood"
#ZSH_THEME="fox"
ZSH_THEME="wintermute"

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to disable bi-weekly auto-update checks.
DISABLE_AUTO_UPDATE="true"

# Uncomment the following line to change how often to auto-update (in days).
# export UPDATE_ZSH_DAYS=13

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# The optional three formats: "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# HIST_STAMPS="mm/dd/yyyy"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load? (plugins can be found in ~/.oh-my-zsh/plugins/*)
# Custom plugins may be added to ~/.oh-my-zsh/custom/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(git)

# User configuration
source $ZSH/oh-my-zsh.sh

# Load all custom zshrc configurations from custom/zshrc
for zshrc_file ($ZSH_CUSTOM/zshrc/*.zsh(N)); do
  source $zshrc_file
done
unset zshrc_file

export PATH="/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:$HOME/bin"

# Preferred editor for local and remote sessions
if [[ -n $SSH_CONNECTION ]]; then
  export EDITOR='vim'
else
  export EDITOR='vim'
fi

# Key bindings
# Skip forward/back a word with opt-arrow
bindkey '[C' forward-word
bindkey '[D' backward-word

# Compilation flags
# export ARCHFLAGS="-arch x86_64"

# golang
export GOPATH=~/go
export PATH=$PATH:$GOPATH/bin

alias mvim='mvim --remote'
alias vi='vim'

alias glog10='git --no-pager log --oneline --decorate --color -10'
alias glog100='git --no-pager log --oneline --decorate --color -100'

