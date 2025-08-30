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

# aliases for vscode
alias cdiff='code --new-window --diff'

# aliases for searching (ripgrep)
alias rgh='rg --no-heading -H'

# aliases for kubernetes
alias k='kubectl'

# drawing/utilities
alias newexcalidraw='cp -v ~/Pictures/template.excalidraw.png'

# prettier
alias prettier-check-changed='git diff --name-only origin/main | xargs -r npx prettier --check'
alias prettier-fix-changed='git diff --name-only origin/main | xargs -r npx prettier --write'
