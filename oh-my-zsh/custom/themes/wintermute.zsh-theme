# wintermute derived from fox.zsh-theme

# BRANCH symbol looks nice for git prompt (using font: Hack Regular Nerd Font Complete 12pt)
BRANCH="\ue0a0"

PROMPT='%{$bg[white]%}%{$fg[black]%}%{$fg_bold[black]%}${HOSTNAME}❯%{$reset_color%}%{$fg[cyan]%}(%{$fg_bold[white]%}%~%{$reset_color%}%{$fg[cyan]%})$(git_prompt_info)
❯ % %{$reset_color%}'

ZSH_THEME_GIT_PROMPT_PREFIX=" %{$reset_color%}%{$fg[white]%}${BRANCH} %{$fg_bold[white]%}"
ZSH_THEME_GIT_PROMPT_SUFFIX="%{$reset_color%}"
ZSH_THEME_GIT_PROMPT_DIRTY=" %{$fg[red]%}✗%{$reset_color%}"
ZSH_THEME_GIT_PROMPT_CLEAN=" %{$fg[green]%}✔%{$reset_color%}"
