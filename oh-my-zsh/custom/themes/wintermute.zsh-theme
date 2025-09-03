# wintermute derived from fox.zsh-theme

# Symbol definitions for better readability
BRANCH="\ue0a0"           # Git branch symbol (using font: Hack Regular Nerd Font Complete 12pt)
KUBERNETES="☸"            # Traditional Kubernetes symbol
TRIANGLE_LEFT="\ue0b2"    # Solid left-pointing triangle
TRIANGLE_RIGHT="\ue0b0"   # Solid right-pointing triangle

# Cache tool availability to avoid repeated command -v calls
typeset -g _WINTERMUTE_HAS_KUBECTL=false
typeset -g _WINTERMUTE_HAS_GIT=false
typeset -g _WINTERMUTE_TOOLS_CHECKED=false

# Check for required tools and show warning on first login
function check_required_tools() {
  # Always cache tool availability regardless of warning status
  if ! $_WINTERMUTE_TOOLS_CHECKED; then
    command -v kubectl >/dev/null 2>&1 && _WINTERMUTE_HAS_KUBECTL=true
    command -v git >/dev/null 2>&1 && _WINTERMUTE_HAS_GIT=true
    _WINTERMUTE_TOOLS_CHECKED=true
  fi

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

# Function to get current timestamp (optimized to use single date call)
function get_timestamp() {
  # Use a single date call and parse the output
  local date_output=$(date '+%H:%M %Z %H%MZ')
  local local_time="${date_output% * *}"  # Extract HH:MM TZ
  local utc_time="${date_output##* }"     # Extract HHMMZ
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

# Function to get Kubernetes context
function kube_prompt_info() {
  # Use cached kubectl availability
  if ! $_WINTERMUTE_HAS_KUBECTL; then
    return
  fi

  # Get kubectl context
  local context=$(kubectl config current-context 2>/dev/null)

  if [[ -n "$context" ]]; then
    local kube_info="$context"

    # Truncate if longer than 20 characters
    if [[ ${#kube_info} -gt 20 ]]; then
      kube_info="${kube_info:0:17}..."
    fi

    echo "%{$fg[blue]%}${TRIANGLE_LEFT}%{$bg[blue]%}%{$fg[white]%} ${KUBERNETES} ${kube_info} %{$reset_color%}%{$fg[blue]%}${TRIANGLE_RIGHT}%{$reset_color%}"
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
PROMPT="${HOSTNAME_SECTION}${DIRECTORY_SECTION} ${HISTORY_SECTION} ${EXIT_STATUS_SECTION} ${TIMESTAMP_SECTION} ${GIT_SECTION}${KUBERNETES_SECTION}
%{$fg[black]%}#%{$reset_color%}❯ % %{$reset_color%}"

ZSH_THEME_GIT_PROMPT_PREFIX=" %{$fg[green]%}${TRIANGLE_LEFT}%{$bg[green]%}%{$fg[white]%} ${BRANCH} %{$fg_bold[white]%}"
ZSH_THEME_GIT_PROMPT_SUFFIX="%{$reset_color%}%{$fg[green]%}${TRIANGLE_RIGHT}%{$reset_color%}"
ZSH_THEME_GIT_PROMPT_DIRTY=" %{$fg[red]%}✗%{$reset_color%}"
ZSH_THEME_GIT_PROMPT_CLEAN=" %{$fg[green]%}✔%{$reset_color%}"

# Run tool check when theme is loaded
check_required_tools
