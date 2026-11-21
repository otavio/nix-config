# Defaults (DC_USER, DC_AGE_DAYS, DC_DIRENV_PATHS, DC_YOCTO_PATHS,
# DC_CACHE_EXCLUDES, DC_STEPS) are injected by the NixOS module.

usage() {
  cat <<EOF
Usage: disk-cleanup [--apply] [--age DAYS] [--only STEPS] [--skip STEPS]

Dry-run by default: reports what would be removed. Pass --apply to delete.

Steps (comma-separated): ${DC_STEPS}
  direnv   drop .direnv of projects idle for more than --age days
  results  drop nix 'result' links and /tmp gcroots older than --age days
  yocto    drop build*/tmp* of Yocto builds idle for more than --age days
  docker   prune rootful and rootless docker (containers/images/cache older
           than --age days, all unused volumes)
  caches   drop files in ~/.cache not modified for --age days
  nix-gc   delete profile generations older than --age days and collect garbage
  balance  btrfs balance of / to return half-empty chunks to the free pool
EOF
}

orig_args=("$@")
apply=0
age="$DC_AGE_DAYS"
only=""
skip=""
while (($#)); do
  case "$1" in
  --apply) apply=1 ;;
  --age)
    age="$2"
    shift
    ;;
  --only)
    only="$2"
    shift
    ;;
  --skip)
    skip="$2"
    shift
    ;;
  -h | --help)
    usage
    exit 0
    ;;
  *)
    usage >&2
    exit 2
    ;;
  esac
  shift
done

if ((EUID != 0)); then
  exec /run/wrappers/bin/sudo "$0" "${orig_args[@]}"
fi

home=$(getent passwd "$DC_USER" | cut -d: -f6)
uid=$(id -u "$DC_USER")
now=$(date +%s)
cutoff=$((now - age * 86400))
total_bytes=0

enabled() {
  local s="$1"
  if [[ -n $only ]]; then
    [[ ",$only," == *",$s,"* ]] || return 1
  fi
  [[ ",$skip," != *",$s,"* ]]
}

header() { printf '\n== %s\n' "$*"; }
human() { numfmt --to=iec --suffix=B "$1"; }
mtime() { stat -c %Y "$@" 2>/dev/null | sort -n | tail -1; }
dir_bytes() { du -sxb "$1" 2>/dev/null | cut -f1; }

remove() {
  local path="$1" bytes="${2:-0}"
  total_bytes=$((total_bytes + bytes))
  if ((apply)); then
    rm -rf --one-file-system -- "$path"
    printf '  removed  %8s  %s\n' "$(human "$bytes")" "$path"
  else
    printf '  would rm %8s  %s\n' "$(human "$bytes")" "$path"
  fi
}

run() {
  if ((apply)); then
    "$@"
  else
    printf '  would run: %s\n' "$*"
  fi
}

project_last_used() {
  local dir="$1" gitdir index=""
  if [[ -d $dir/.git ]]; then
    index="$dir/.git/index"
  elif [[ -f $dir/.git ]]; then
    gitdir=$(sed -n 's/^gitdir: //p' "$dir/.git")
    [[ $gitdir == /* ]] || gitdir="$dir/$gitdir"
    index="$gitdir/index"
  fi
  # shellcheck disable=SC2046
  mtime "$dir" "$dir/.direnv" $(find "$dir/.direnv" -maxdepth 1 -name 'flake-profile-*' 2>/dev/null) ${index:+"$index"}
}

step_direnv() {
  header "direnv roots idle for more than ${age}d"
  local paths=() p envdir proj
  for p in $DC_DIRENV_PATHS; do
    [[ -d $home/$p ]] && paths+=("$home/$p")
  done
  ((${#paths[@]})) || return 0
  while IFS= read -r -d '' envdir; do
    proj=$(dirname "$envdir")
    if (($(project_last_used "$proj") < cutoff)); then
      remove "$envdir" "$(dir_bytes "$envdir")"
    fi
  done < <(find "${paths[@]}" -xdev -maxdepth 6 \
    \( -name .direnv -type d -print0 -prune \) -o \
    \( -type d \( -name .git -o -name node_modules -o -name target \
    -o -name 'tmp' -o -name 'tmp-*' -o -name sstate-cache -o -name downloads \) -prune \))
}

step_results() {
  header "nix result links and /tmp gcroots older than ${age}d"
  local root link
  for root in /nix/var/nix/gcroots/auto/*; do
    link=$(readlink "$root") || continue
    [[ -L $link ]] || continue
    [[ $link == */.direnv/* ]] && continue
    [[ $link == /tmp/* || $(basename "$link") == result* ]] || continue
    (($(stat -c %Y "$link") < cutoff)) || continue
    remove "$link" 0
  done
}

step_yocto() {
  header "Yocto build/tmp of builds idle for more than ${age}d"
  if pgrep -f 'bitbake-server|bin/bitbake' >/dev/null; then
    echo "  skipped: bitbake is running"
    return 0
  fi
  local p conf build tmp last
  for p in $DC_YOCTO_PATHS; do
    [[ -d $home/$p ]] || continue
    while IFS= read -r -d '' conf; do
      build=$(dirname "$(dirname "$conf")")
      # shellcheck disable=SC2046
      last=$(mtime "$build/bitbake-cookerdaemon.log" $(find "$build" -maxdepth 1 -name 'tmp*' -type d) $(find "$build"/tmp*/log/cooker -type f 2>/dev/null))
      ((${last:-0} < cutoff)) || continue
      for tmp in "$build"/tmp "$build"/tmp-*; do
        [[ -d $tmp ]] && remove "$tmp" "$(dir_bytes "$tmp")"
      done
    done < <(find "$home/$p" -xdev -maxdepth 5 -path '*/conf/local.conf' -print0)
  done
}

docker_prune() {
  local hours=$((age * 24))
  docker container prune -f --filter "until=${hours}h"
  docker image prune -a -f --filter "until=${hours}h"
  docker builder prune -a -f --filter "until=${hours}h"
  docker volume prune -a -f
}

step_docker() {
  header "docker (rootful and rootless)"
  local sock
  for sock in /run/docker.sock "/run/user/$uid/docker.sock"; do
    [[ -S $sock ]] || continue
    echo "  $sock"
    export DOCKER_HOST="unix://$sock"
    if ((apply)); then
      docker_prune | sed 's/^/    /'
    else
      docker system df | sed 's/^/    /'
      echo "    volumes that would be removed:"
      docker volume ls -q -f dangling=true | sed 's/^/      /'
    fi
    unset DOCKER_HOST
  done
}

step_caches() {
  header "$home/.cache files untouched for more than ${age}d"
  local cache="$home/.cache" args=() e bytes
  [[ -d $cache ]] || return 0
  for e in $DC_CACHE_EXCLUDES; do
    args+=(-path "$cache/$e" -prune -o)
  done
  bytes=$(find "$cache" -xdev "${args[@]}" -type f -mmin "+$((age * 1440))" -printf '%s\n' | awk '{s+=$1} END{print s+0}')
  total_bytes=$((total_bytes + bytes))
  if ((apply)); then
    find "$cache" -xdev "${args[@]}" -type f -mmin "+$((age * 1440))" -delete
    find "$cache" -xdev -mindepth 2 -type d -empty -delete
    echo "  removed $(human "$bytes")"
  else
    echo "  would remove $(human "$bytes")"
  fi
}

step_nix_gc() {
  header "nix generations older than ${age}d and garbage collection"
  local profile
  for profile in "$home"/.local/state/nix/profiles/*; do
    [[ $profile == *-link ]] && continue
    [[ -L $profile ]] || continue
    if ((apply)); then
      runuser -u "$DC_USER" -- nix-env -p "$profile" --delete-generations "${age}d"
    else
      runuser -u "$DC_USER" -- nix-env -p "$profile" --delete-generations "${age}d" --dry-run 2>&1 | sed 's/^/  /'
    fi
  done
  if ((apply)); then
    nix-collect-garbage --delete-older-than "${age}d"
  else
    nix-collect-garbage --delete-older-than "${age}d" --dry-run 2>&1 | sed 's/^/  /'
    echo "  (store paths freed by the steps above are only collectable after --apply)"
  fi
}

step_balance() {
  header "btrfs balance /"
  btrfs filesystem usage -T / 2>/dev/null | sed -n '1,12p' | sed 's/^/  /'
  run btrfs balance start -dusage=50 -musage=50 /
}

avail_before=$(df -B1 --output=avail / | tail -1)
((apply)) || echo "DRY RUN: nothing will be deleted. Pass --apply to clean up."

for s in ${DC_STEPS//,/ }; do
  enabled "$s" || continue
  "step_${s//-/_}"
done

header "summary"
if ((apply)); then
  avail_after=$(df -B1 --output=avail / | tail -1)
  echo "  free space: $(human "$avail_before") -> $(human "$avail_after")"
else
  echo "  files listed above: $(human "$total_bytes") (apparent size, before nix-gc)"
fi
