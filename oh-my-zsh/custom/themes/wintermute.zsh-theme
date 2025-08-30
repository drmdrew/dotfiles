# wintermute derived from fox.zsh-theme

# Symbol definitions for better readability
BRANCH="\ue0a0"           # Git branch symbol (using font: Hack Regular Nerd Font Complete 12pt)
KUBERNETES="☸"            # Traditional Kubernetes symbol
TRIANGLE_LEFT="\ue0b2"    # Solid left-pointing triangle
TRIANGLE_RIGHT="\ue0b0"   # Solid right-pointing triangle

# Check for required tools and show warning on first login
function check_required_tools() {
  local warning_file="$HOME/.wintermute_tools_warning_shown"

  # Only show warning once per session
  if [[ -f "$warning_file" ]]; then
    return
  fi

  local missing_tools=()
  local tools=("git" "kubectl" "kubectx" "kubens" "k9s")

  for tool in "${tools[@]}"; do
    if ! command -v "$tool" >/dev/null 2>&1; then
      missing_tools+=("$tool")
    fi
  done

  if [[ ${#missing_tools[@]} -gt 0 ]]; then
    echo ""
    echo "%{$fg[yellow]%}⚠️  Wintermute theme warning:%{$reset_color%}"
    echo "%{$fg[yellow]%}   Missing tools: ${missing_tools[*]}%{$reset_color%}"
    echo "%{$fg[yellow]%}   Some prompt features may not work correctly.%{$reset_color%}"
    echo "%{$fg[yellow]%}   Install missing tools or ignore this warning.%{$reset_color%}"
    echo ""
  fi

  # Mark warning as shown for this session
  touch "$warning_file"
}

# Function to get current timestamp
function get_timestamp() {
  local local_time=$(date '+%H:%M %Z')
  local utc_time=$(date -u '+%H%MZ')
  echo "%{$fg[white]%}${local_time}%{$reset_color%}/%{$fg[gray]%}${utc_time}%{$reset_color%}"
}

# Function to show current history number
function get_history_number() {
  echo "%{$fg[gray]%}#${HISTCMD}%{$reset_color%}"
}

# Function to show last command exit status
function get_exit_status() {
  local exit_code=$?
  if [[ $exit_code -eq 0 ]]; then
    echo "%{$fg[green]%}✅%{$reset_color%}"
  else
    echo "%{$fg[red]%}💣%{$reset_color%}"
  fi
}

# Function to get Kubernetes context and namespace
function kube_prompt_info() {
  if command -v kubectl >/dev/null 2>&1; then
    local context=$(kubectl config current-context 2>/dev/null)
    local namespace=$(kubectl config view --minify --output 'jsonpath={..namespace}' 2>/dev/null)

    if [[ -n "$context" ]]; then
      local kube_info=""
      if [[ -n "$namespace" && "$namespace" != "default" ]]; then
        kube_info="${context}:${namespace}"
      else
        kube_info="${context}"
      fi

      # Truncate if longer than 20 characters
      if [[ ${#kube_info} -gt 20 ]]; then
        kube_info="${kube_info:0:17}..."
      fi

      echo "%{$fg[blue]%}${TRIANGLE_LEFT}%{$bg[blue]%}%{$fg[white]%} ${KUBERNETES} ${kube_info} %{$reset_color%}%{$fg[blue]%}${TRIANGLE_RIGHT}"
    fi
  fi
}

# Function to truncate git branch name
function truncate_git_branch() {
  local branch="$1"
  if [[ ${#branch} -gt 20 ]]; then
    echo "${branch:0:17}..."
  else
    echo "$branch"
  fi
}

# Build prompt sections for better readability
HOSTNAME_SECTION='%{$fg[black]%}#%{$reset_color%}%{$bg[white]%}%{$fg[black]%}%{$fg_bold[black]%}%m❯%{$reset_color%}'
DIRECTORY_SECTION='%{$fg[cyan]%}(%{$fg_bold[white]%}%~%{$reset_color%}%{$fg[cyan]%})'
HISTORY_SECTION='$(get_history_number)'
EXIT_STATUS_SECTION='$(get_exit_status)'
TIMESTAMP_SECTION='$(get_timestamp)'
KUBERNETES_SECTION='$(kube_prompt_info)'
GIT_SECTION='$(git_prompt_info)'

# Combine all sections into the final prompt
PROMPT="${HOSTNAME_SECTION}${DIRECTORY_SECTION} ${HISTORY_SECTION} ${EXIT_STATUS_SECTION} ${TIMESTAMP_SECTION} ${KUBERNETES_SECTION}${GIT_SECTION}
%{$fg[black]%}#%{$reset_color%}❯ % %{$reset_color%}"

ZSH_THEME_GIT_PROMPT_PREFIX=" %{$fg[green]%}${TRIANGLE_LEFT}%{$bg[green]%}%{$fg[white]%} ${BRANCH} %{$fg_bold[white]%}"
ZSH_THEME_GIT_PROMPT_SUFFIX="%{$reset_color%}%{$fg[green]%}${TRIANGLE_RIGHT}"
ZSH_THEME_GIT_PROMPT_DIRTY=" %{$fg[red]%}✗%{$reset_color%}"
ZSH_THEME_GIT_PROMPT_CLEAN=" %{$fg[green]%}✔%{$reset_color%}"

# Run tool check when theme is loaded
check_required_tools
