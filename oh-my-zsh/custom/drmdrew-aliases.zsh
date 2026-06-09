git_main_or_master() {
  echo "$(git remote show origin | sed -n "/HEAD branch/s/.*: //p")"
}

# aliases for git
alias glog10='git --no-pager log --oneline --decorate --color -10'
alias glog100='git --no-pager log --oneline --decorate --color -100'
alias gcm='git checkout $(git_main_or_master)'
alias gcmain='git checkout main'
alias gcmaster='git checkout master'
alias gtfo='git push --set-upstream origin $(git branch --show-current)'
alias gclean='git clean -df'
alias grbias='git pull origin $(git_main_or_master) && git rebase  --interactive --autosquash origin/$(git_main_or_master)'
alias gpfwl='git push --force-with-lease'
alias greset='git reset --hard origin/$(git branch --show-current)'
alias glogarch='git log -w -M -C -C -C'
alias gblamearch='git blame -w -n -M -C -C -C'
alias gfom='git fetch origin main:main'
alias gundo='gco origin/$(git_main_or_master) --'
alias gdno='git --no-pager diff --name-only'
alias gdnomh='git --no-pager diff --name-only master..HEAD'
alias gmorm='git_main_or_master'

# functions and aliases for k8s
alias k='kubectl'
alias kctx='kubectx'
alias kns='kubens'
alias kgpods='kubectl get pods'

# aliases for vscode
alias cdiff='code --new-window --diff'

# aliases for cursor
alias cursor-ui='open -a Cursor'

# aliases for searching (ripgrep)
alias rgh='rg --no-heading -H'

# aliases for kubernetes
alias k='kubectl'

# drawing/utilities
alias newexcalidraw='cp -v ~/Pictures/template.excalidraw.png'

# prettier
alias prettier-check-changed='git diff --name-only origin/main | xargs -r npx prettier --check'
alias prettier-fix-changed='git diff --name-only origin/main | xargs -r npx prettier --write'

# Things 3 - add a todo item via URL scheme
# Usage: todo "Task title" [-n "notes"] [-w today|tomorrow|someday] [-l "List name"] [-t "tag1,tag2"]
todo() {
  local title="$1"; shift
  local notes="" when="" list="" tags=""
  local OPTIND opt
  while getopts "n:w:l:t:" opt; do
    case $opt in
      n) notes="$OPTARG" ;;
      w) when="$OPTARG" ;;
      l) list="$OPTARG" ;;
      t) tags="$OPTARG" ;;
    esac
  done
  [[ -z "$title" ]] && { echo "Usage: todo \"title\" [-n notes] [-w today|tomorrow|someday] [-l list] [-t tag1,tag2]"; return 1; }
  _urlencode() { python3 -c "import urllib.parse,sys; print(urllib.parse.quote(sys.argv[1]))" "$1"; }
  local url="things:///add?title=$(_urlencode "$title")"
  [[ -n "$notes" ]] && url+="&notes=$(_urlencode "$notes")"
  [[ -n "$when"  ]] && url+="&when=$when"
  [[ -n "$list"  ]] && url+="&list=$(_urlencode "$list")"
  [[ -n "$tags"  ]] && url+="&tags=$(_urlencode "$tags")"
  open "$url"
}

# claude-qq - quick one-shot question to Claude using the fast Haiku model
# Usage: claude-qq how can I switch byobu from tmux/screen keybinds?
claude-qq() {
  claude --model claude-haiku-4-5-20251001 --print "$*"
}

alias qq='claude-qq'

