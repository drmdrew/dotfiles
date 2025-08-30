# Add your own custom plugins in the custom/plugins directory. Plugins placed
# here will override ones with the same name in the main plugins directory.
# See: https://github.com/ohmyzsh/ohmyzsh/wiki/Customization#overriding-and-adding-plugins

function aws-login() {
  if [[ -z "$1" ]]; then
    echo "Missing profile"
    return
  fi
  local profile="$1"
  aws sso login --profile "$profile" || return
  eval "$(aws configure export-credentials --profile "$profile" --format env)" || return
  export AWS_PROFILE="$profile" || return
}

_aws-login() {
  aws configure list-profiles | while read -r profile; do
    compadd "$profile"
  done
}
compdef _aws-login aws-login
aws-logout() {
  unset AWS_ACCESS_KEY_ID
  unset AWS_SECRET_ACCESS_KEY
  unset AWS_SESSION_TOKEN
  unset AWS_CREDENTIAL_EXPIRATION
  unset AWS_PROFILE
}
