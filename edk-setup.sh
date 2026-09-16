#!/bin/bash
#
# edk-setup.sh — Onboard a macOS user/computer onto the Elementum EDK.
#
# Installs (or updates) the `elementum` CLI, authenticates a profile against
# an Elementum org, and/or bootstraps a local workspace by pulling an app.
#
# Usage: ./edk-setup.sh

set -uo pipefail

INSTALL_URL="https://elementum-toolchain-distribution.vercel.app"
ELEMENTUM_HOME="${ELEMENTUM_HOME:-$HOME/.elementum}"
ELEMENTUM_BIN="$ELEMENTUM_HOME/bin/elementum"

# ---------------------------------------------------------------------------
# Output helpers
# ---------------------------------------------------------------------------

if [ -t 1 ]; then
  C_RESET=$'\033[0m'; C_BOLD=$'\033[1m'; C_RED=$'\033[31m'
  C_GREEN=$'\033[32m'; C_YELLOW=$'\033[33m'; C_BLUE=$'\033[34m'
else
  C_RESET=""; C_BOLD=""; C_RED=""; C_GREEN=""; C_YELLOW=""; C_BLUE=""
fi

info()    { printf '%s\n' "${C_BLUE}==>${C_RESET} $*" >&2; }
success() { printf '%s\n' "${C_GREEN}==>${C_RESET} $*" >&2; }
warn()    { printf '%s\n' "${C_YELLOW}==> Warning:${C_RESET} $*" >&2; }
err()     { printf '%s\n' "${C_RED}==> Error:${C_RESET} $*" >&2; }
heading() { printf '\n%s\n' "${C_BOLD}$*${C_RESET}" >&2; }

die() { err "$*"; exit 1; }

# ---------------------------------------------------------------------------
# Prompt helpers (prompt text goes to stderr; only the value is echoed to
# stdout, so callers can safely do `x=$(prompt ...)`)
# ---------------------------------------------------------------------------

prompt() {
  # prompt "question" ["default"]
  local q="$1" def="${2:-}" ans
  if [ -n "$def" ]; then
    read -r -p "$q [$def]: " ans
  else
    read -r -p "$q: " ans
  fi
  printf '%s' "${ans:-$def}"
}

prompt_required() {
  local q="$1" ans
  while true; do
    read -r -p "$q: " ans
    if [ -n "$ans" ]; then
      printf '%s' "$ans"
      return
    fi
    warn "This value is required."
  done
}

prompt_secret() {
  local q="$1" ans
  read -r -s -p "$q: " ans
  printf '\n' >&2
  printf '%s' "$ans"
}

confirm() {
  # confirm "question?" [y|n default]
  local q="$1" def="${2:-y}" ans hint
  if [ "$def" = "y" ]; then hint="Y/n"; else hint="y/N"; fi
  read -r -p "$q [$hint]: " ans
  ans="${ans:-$def}"
  case "$ans" in
    [Yy]*) return 0 ;;
    *) return 1 ;;
  esac
}

# ---------------------------------------------------------------------------
# Preflight
# ---------------------------------------------------------------------------

if [ "$(uname -s)" != "Darwin" ]; then
  warn "This script targets macOS. Detected $(uname -s); continuing anyway."
fi

command -v curl >/dev/null 2>&1 || die "curl is required but not found."

# Make sure this session can see a freshly-installed CLI without a new shell.
case ":$PATH:" in
  *":$ELEMENTUM_HOME/bin:"*) ;;
  *) export PATH="$ELEMENTUM_HOME/bin:$PATH" ;;
esac

# ---------------------------------------------------------------------------
# Step 1: make sure the CLI is installed and current
# ---------------------------------------------------------------------------

install_cli() {
  info "Installing the Elementum CLI..."
  if curl -fsSL "$INSTALL_URL" | sh; then
    success "Elementum CLI installed."
  else
    die "Elementum CLI installation failed."
  fi
}

check_cli() {
  heading "Checking Elementum CLI installation"

  if ! command -v elementum >/dev/null 2>&1; then
    warn "Elementum CLI not found."
    if confirm "Install it now?" y; then
      install_cli
    else
      die "The Elementum CLI is required to continue."
    fi
  fi

  command -v elementum >/dev/null 2>&1 || die "elementum still not on PATH after install."

  local version
  version=$(elementum --version 2>/dev/null || echo "unknown")
  info "Installed version: $version"

  info "Checking for updates..."
  local check_output json_line status selected
  check_output=$(elementum update --check --json 2>&1)
  json_line=$(printf '%s\n' "$check_output" | grep -o '{.*}' | tail -1)

  if [ -z "$json_line" ]; then
    warn "Could not determine update status:"
    printf '%s\n' "$check_output" >&2
    return
  fi

  status=$(printf '%s' "$json_line" | sed -n 's/.*"status":"\([^"]*\)".*/\1/p')
  selected=$(printf '%s' "$json_line" | sed -n 's/.*"selectedVersion":"\([^"]*\)".*/\1/p')

  if [ "$status" = "update-available" ]; then
    warn "Elementum $selected is available (currently $version)."
    if confirm "Update to $selected now?" y; then
      info "Updating..."
      if elementum update; then
        success "Updated to $(elementum --version 2>/dev/null)."
      else
        warn "Update to $selected failed; continuing with $version."
        warn "(A Gatekeeper/notarization rejection is often transient — you can retry later by running 'elementum update'.)"
      fi
    else
      info "Skipping update; continuing with $version."
    fi
  else
    success "Elementum is up to date."
  fi
}

# ---------------------------------------------------------------------------
# Step 2: authenticate this computer
# ---------------------------------------------------------------------------

run_auth_setup() {
  heading "Authenticate this computer"

  PROFILE=$(prompt "Profile name" "${PROFILE:-default}")
  local instance environment org client_id client_secret
  instance=$(prompt "Instance (us, eu, stage, dev, custom)" "us")
  environment=$(prompt "Environment slug (e.g. staging; leave blank for default)" "")
  org=$(prompt "Organization ID (leave blank if you don't have one yet)" "")
  client_id=$(prompt "Client ID (leave blank to use the default interactive login)" "")

  client_secret=""
  if [ -n "$client_id" ]; then
    if confirm "Provide a client secret too?" n; then
      client_secret=$(prompt_secret "Client Secret (input hidden)")
    fi
  fi

  local args=(auth login --profile "$PROFILE")
  [ -n "$instance" ]      && args+=(--instance "$instance")
  [ -n "$environment" ]   && args+=(--environment "$environment")
  [ -n "$org" ]           && args+=(--org "$org")
  [ -n "$client_id" ]     && args+=(--client-id "$client_id")
  [ -n "$client_secret" ] && args+=(--client-secret "$client_secret")

  info "Running: elementum auth login --profile $PROFILE [...] (browser sign-in may open)"
  if ! elementum "${args[@]}"; then
    die "Authentication failed."
  fi

  info "Verifying authentication status..."
  if elementum --profile="$PROFILE" auth status; then
    success "Profile '$PROFILE' is authenticated."
  else
    die "Authentication appears to have failed for profile '$PROFILE'."
  fi

  if confirm "Install/refresh coding-agent playbooks (elementum playbooks install) now?" y; then
    if confirm "Install them globally for this user (~/.agents/skills) instead of the current directory?" y; then
      elementum playbooks install --yes --global
    else
      elementum playbooks install --yes
    fi
  fi

  export PROFILE
}

profile_is_authenticated() {
  local p="$1"
  elementum --profile="$p" auth status >/dev/null 2>&1
}

# ---------------------------------------------------------------------------
# Entity picker: browse/pull/create an app or element
# ---------------------------------------------------------------------------

# Prints "Name<TAB>Namespace" per existing object of the given kind.
list_entities() {
  local kind="$1" profile="$2"
  elementum --profile="$profile" list "$kind" --json 2>/dev/null | awk '
    /"Name":/ {
      line = $0
      sub(/^[^:]*:[[:space:]]*"/, "", line); sub(/",?[[:space:]]*$/, "", line)
      name = line
    }
    /"Namespace":/ {
      line = $0
      sub(/^[^:]*:[[:space:]]*"/, "", line); sub(/",?[[:space:]]*$/, "", line)
      print name "\t" line
    }
  ' | sed -e 's/\\u0026/\&/g' -e 's/\\"/"/g' -e 's/\\\\/\\/g'
}

pull_entity_by_namespace() {
  local kind="$1" namespace="$2" profile="$3"
  elementum --profile="$profile" pull "$kind" "$namespace"
}

# Lists existing objects of the given kind and lets the user pick one.
# Prints the chosen namespace to stdout; returns non-zero on cancel/empty.
browse_and_pick() {
  local kind="$1" profile="$2"
  info "Loading ${kind}..."
  local rows
  rows=$(list_entities "$kind" "$profile")
  if [ -z "$rows" ]; then
    warn "No ${kind} found in this org."
    return 1
  fi

  local names=() namespaces=()
  local name ns i=0
  while IFS=$'\t' read -r name ns; do
    [ -z "$ns" ] && continue
    i=$((i + 1))
    names[$i]="$name"
    namespaces[$i]="$ns"
    printf '  %2d) %-40s (%s)\n' "$i" "$name" "$ns" >&2
  done <<< "$rows"
  printf '   0) Cancel\n' >&2

  local choice
  choice=$(prompt "Select a number" "0")
  if [ -z "$choice" ] || [ "$choice" = "0" ]; then
    return 1
  fi
  if [ -z "${namespaces[$choice]:-}" ]; then
    warn "Invalid selection."
    return 1
  fi
  printf '%s' "${namespaces[$choice]}"
}

# Scaffolds a brand-new app or element (elementum new app|element).
create_new_entity() {
  local kind="$1" label="$2" profile="$3"
  local name namespace category handle
  name=$(prompt_required "$label display name")
  namespace=$(prompt_required "$label namespace (immutable, lowercase letters only)")

  info "Existing categories in this org:"
  elementum --profile="$profile" list categories 2>/dev/null | sed 's/^/    /' >&2

  category=$(prompt_required "Category name (from the list above, or org.ts)")
  handle=$(prompt "Platform handle (optional)" "")

  local args=(new "$kind" --name "$name" --namespace "$namespace" --category "$category")
  [ -n "$handle" ] && args+=(--handle "$handle")

  info "Running: elementum ${args[*]}"
  if elementum "${args[@]}"; then
    success "Scaffolded new $label '$name' at namespace '$namespace'."
    return 0
  fi
  warn "Failed to scaffold the new $label."
  return 1
}

# Guided menu: pull an existing app/element by name, browse the org's
# existing ones, or create a brand-new one. Retries on a not-found pull
# instead of aborting the whole script.
select_and_pull_entity() {
  local profile="$1"
  local did_something=1

  while true; do
    heading "What would you like to work on?"
    printf '  1) Pull an existing app (I know the namespace)\n' >&2
    printf '  2) Pull an existing element (I know the namespace)\n' >&2
    printf '  3) Browse existing apps and choose one\n' >&2
    printf '  4) Browse existing elements and choose one\n' >&2
    printf '  5) Create a new app\n' >&2
    printf '  6) Create a new element\n' >&2
    printf '  7) Skip\n' >&2

    local choice
    choice=$(prompt "Choice" "7")

    case "$choice" in
      1)
        local ns
        ns=$(prompt "App namespace to pull" "")
        [ -z "$ns" ] && continue
        if pull_entity_by_namespace app "$ns" "$profile"; then did_something=0; break; fi
        warn "Pulling app '$ns' failed — it may not exist in this org, or the pull hit an error (see output above). Try again."
        ;;
      2)
        local ns
        ns=$(prompt "Element namespace to pull" "")
        [ -z "$ns" ] && continue
        if pull_entity_by_namespace element "$ns" "$profile"; then did_something=0; break; fi
        warn "Pulling element '$ns' failed — it may not exist in this org, or the pull hit an error (see output above). Try again."
        ;;
      3)
        local ns
        if ns=$(browse_and_pick apps "$profile"); then
          info "Pulling app '$ns'..."
          if pull_entity_by_namespace app "$ns" "$profile"; then did_something=0; break; fi
          warn "Pulling '$ns' failed — see output above. Try again."
        fi
        ;;
      4)
        local ns
        if ns=$(browse_and_pick elements "$profile"); then
          info "Pulling element '$ns'..."
          if pull_entity_by_namespace element "$ns" "$profile"; then did_something=0; break; fi
          warn "Pulling '$ns' failed — see output above. Try again."
        fi
        ;;
      5)
        create_new_entity app "App" "$profile" && { did_something=0; break; }
        ;;
      6)
        create_new_entity element "Element" "$profile" && { did_something=0; break; }
        ;;
      7|"")
        info "Skipping."
        return 0
        ;;
      *)
        warn "Unrecognized choice: $choice"
        ;;
    esac
  done

  if [ "$did_something" -eq 0 ] && confirm "Typecheck and build the workspace now?" y; then
    npx tsc --noEmit && elementum build \
      && success "Typecheck and build succeeded." \
      || warn "Typecheck/build reported issues; review the output above."
  fi
}

# ---------------------------------------------------------------------------
# Step 3: bootstrap a local workspace and (optionally) pull an app
# ---------------------------------------------------------------------------

run_workspace_bootstrap() {
  heading "Bootstrap a local workspace"

  if ! command -v node >/dev/null 2>&1; then
    warn "Node.js was not found. The EDK workspace needs Node 24."
    if command -v brew >/dev/null 2>&1 && confirm "Install it now with Homebrew (brew install node@24)?" n; then
      brew install node@24 || die "Failed to install Node via Homebrew."
    else
      die "Install Node 24 (e.g. via nvm or Homebrew) and re-run this script."
    fi
  fi

  if [ -n "${PROFILE:-}" ]; then
    info "Using profile '$PROFILE' from the authentication step."
  else
    PROFILE=$(prompt "Profile to use for this workspace" "default")
  fi
  if ! profile_is_authenticated "$PROFILE"; then
    warn "Profile '$PROFILE' is not authenticated yet."
    if confirm "Authenticate it now?" y; then
      run_auth_setup
    else
      die "A profile must be authenticated before bootstrapping a workspace."
    fi
  fi

  local default_root="$HOME/elementum-workspace"
  local workspace_root
  workspace_root=$(prompt "Workspace parent directory" "$default_root")
  mkdir -p "$workspace_root" || die "Could not create $workspace_root"
  cd "$workspace_root" || die "Could not enter $workspace_root"
  info "Working in $(pwd)"

  if [ ! -f package.json ]; then
    info "Initializing package.json..."
    npm init -y >/dev/null || die "npm init failed."
  fi

  info "Installing @elementumai/edk..."
  npm install @elementumai/edk || die "npm install failed."

  info "Pulling org references..."
  info "(If profile '$PROFILE' already has a workspace elsewhere on disk, the pull targets that existing location rather than $workspace_root.)"
  local pull_output org_root
  pull_output=$(elementum --profile="$PROFILE" pull org --data-only 2>&1)
  local pull_status=$?
  printf '%s\n' "$pull_output"
  [ $pull_status -eq 0 ] || die "pull org failed."

  org_root=$(printf '%s\n' "$pull_output" | grep -o '"orgRoot"[[:space:]]*:[[:space:]]*"[^"]*"' | tail -1 | sed -n 's/.*"orgRoot"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p')

  if [ -n "$org_root" ] && [ -d "$org_root" ]; then
    if [ "$org_root" != "$(pwd)" ]; then
      info "Profile '$PROFILE' is bound to $org_root; switching there."
    fi
    cd "$org_root" || die "Could not enter $org_root"
    info "Organization workspace: $(pwd)"
  else
    warn "Could not determine the organization root from the pull output above."
    warn "cd into it yourself and run 'elementum --profile=$PROFILE init'."
    return
  fi

  info "Running elementum init..."
  elementum --profile="$PROFILE" init || die "elementum init failed."

  select_and_pull_entity "$PROFILE"

  success "Workspace ready at $(pwd)"
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

main() {
  heading "Elementum EDK Setup"

  check_cli

  heading "What would you like to do?"
  printf '  1) Authenticate this computer only\n' >&2
  printf '  2) Bootstrap a local workspace only (assumes this computer is already authenticated)\n' >&2
  printf '  3) Both: authenticate, then bootstrap a workspace\n' >&2
  printf '  4) Exit\n' >&2

  local choice
  choice=$(prompt "Choice" "3")

  case "$choice" in
    1) run_auth_setup ;;
    2) run_workspace_bootstrap ;;
    3) run_auth_setup; run_workspace_bootstrap ;;
    4) info "Nothing to do."; exit 0 ;;
    *) die "Unrecognized choice: $choice" ;;
  esac

  heading "Done"
  success "Elementum EDK setup complete."
}

main "$@"
