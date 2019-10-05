# wintermute derived from fox.zsh-theme

# BRANCH symbol looks nice for git prompt (using font: Hack Regular Nerd Font Complete 12pt)
BRANCH="\ue0a0"
RIGHT_BRACKET="❯"
RIGHT_TRIANGLE=$'\ue0b0'
RIGHT_SEMICIRCLE=$'\ue0b4'
LEFT_SEMICIRCLE=$'\ue0b6'
SEPARATOR=$RIGHT_SEMICIRCLE

PROMPT='%{$fg[white]%}%{$bg[black]%}${LEFT_SEMICIRCLE}%{$bg[white]%}%{$fg[black]%}%{$fg_bold[black]%}%n◉%m%{$fg[white]%}%{$bg[black]%}${RIGHT_SEMICIRCLE}%{$reset_color%}%{$fg[cyan]%}(%{$fg_bold[white]%}%~%{$reset_color%}%{$fg[cyan]%})$(git_prompt_info)
$RIGHT_TRIANGLE % %{$reset_color%}'

ZSH_THEME_GIT_PROMPT_PREFIX=" %{$reset_color%}%{$fg[white]%}${BRANCH} %{$fg_bold[white]%}"
ZSH_THEME_GIT_PROMPT_SUFFIX="%{$reset_color%}"
ZSH_THEME_GIT_PROMPT_DIRTY=" %{$fg[red]%}✗%{$reset_color%}"
ZSH_THEME_GIT_PROMPT_CLEAN=" %{$fg[green]%}✔%{$reset_color%}"
