#!/usr/bin/env bash
# mac-vm.sh: create or delete a fresh local macOS VM for one attempt.
#
# Usage:
#   mac-vm.sh create --run-id ID [--attempt N] [--memory-gb 8]
#   mac-vm.sh delete --run-id ID [--attempt N]
#
# Uses tart when installed, otherwise UTM's utmctl. The VM is named
# <run-id>-mac-a<N>; local VMs cannot carry tags, so that name prefix is the
# run tag and teardown.sh matches on it.
#
# tart:  clones $MAC_IMAGE (default ghcr.io/cirruslabs/macos-sequoia-vanilla:latest,
#        a stock macOS with no Homebrew, SSH on, user admin). The first pull is
#        about 25 GB. An ephemeral ed25519 key is installed with `tart exec` when
#        the image has the Tart Guest Agent. The vanilla image does not, so it
#        needs sshpass (brew install sshpass) and the image's published default
#        password. The non-vanilla base image has the agent but ships Homebrew,
#        which hides missing-prerequisite bugs.
# utm:   clones $UTM_BASE_VM, which must already have Remote Login enabled and
#        accept the key in $UTM_SSH_KEY for $UTM_SSH_USER. utmctl cannot set a
#        clone's memory or inject keys, so prepare the base VM once by hand.
#
# On success, create writes <state>/<run-id>/mac-a<N>.env with TRANSPORT=ssh,
# so remote-exec.sh drives it exactly like a Linux instance.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source-path=SCRIPTDIR source=lib.sh
. "$SCRIPT_DIR/lib.sh"

ACTION="${1:-}"; shift || true
RUN_ID="" ; ATTEMPT=1 ; MEM_GB=8
while [ $# -gt 0 ]; do
  case "$1" in
    --run-id) RUN_ID="$2"; shift 2 ;;
    --attempt) ATTEMPT="$2"; shift 2 ;;
    --memory-gb) MEM_GB="$2"; shift 2 ;;
    *) die "unknown argument: $1" 2 ;;
  esac
done
valid_run_id "$RUN_ID"
SCOPE="mac-a$ATTEMPT"
VM="$RUN_ID-$SCOPE"
RD="$(run_dir "$RUN_ID")"
mkdir -p "$RD"

if command -v tart >/dev/null 2>&1; then ENGINE=tart
elif command -v utmctl >/dev/null 2>&1; then ENGINE=utm
else die "no local VM engine: brew install cirruslabs/cli/tart" 2; fi

delete_vm() {
  if [ "$ENGINE" = tart ]; then
    if tart list --source local --quiet 2>/dev/null | grep -qx "$VM"; then
      tart stop "$VM" >/dev/null 2>&1 || true
      tart delete "$VM"
      log "deleted tart VM $VM"
    fi
  else
    if utmctl list 2>/dev/null | grep -q " $VM\$"; then
      utmctl stop "$VM" >/dev/null 2>&1 || true
      utmctl delete "$VM"
      log "deleted UTM VM $VM"
    fi
  fi
  rm -f "$RD/$SCOPE.env" "$RD/$SCOPE.key" "$RD/$SCOPE.key.pub"
}

case "$ACTION" in
  delete) delete_vm; exit 0 ;;
  create) ;;
  *) die "usage: mac-vm.sh create|delete --run-id ID [--attempt N]" 2 ;;
esac

[ -f "$RD/$SCOPE.env" ] && die "$SCOPE already exists for this run; use the next --attempt" 2
SUCCESS=0
cleanup_on_fail() {
  local rc=$?
  [ "$SUCCESS" = 1 ] || { log "mac VM create failed (rc=$rc); deleting $VM"; delete_vm || true; }
  exit "$rc"
}
trap cleanup_on_fail EXIT
trap 'exit 130' INT TERM

# Local VMs have no self-terminating TTL, but teardown.sh --orphans uses this
# per-attempt expiry (computed now, not at preflight) to leave active runs alone.
EXPIRES_AT="$(utc_plus_minutes $(( $(sed -n 's/^TTL_HOURS=//p' "$RD/run.env" 2>/dev/null || echo 2) * 60 + EXPIRES_SLACK_MINUTES )))"
KEY="$RD/$SCOPE.key"
ssh-keygen -q -t ed25519 -N '' -C "$VM" -f "$KEY"

if [ "$ENGINE" = tart ]; then
  IMAGE="${MAC_IMAGE:-ghcr.io/cirruslabs/macos-sequoia-vanilla:latest}"
  log "cloning $IMAGE -> $VM (first pull is large)"
  tart clone "$IMAGE" "$VM"
  tart set "$VM" --memory "$((MEM_GB * 1024))"
  nohup tart run --no-graphics "$VM" >"$RD/$SCOPE-tart.log" 2>&1 &
  IP="$(tart ip "$VM" --wait 300)"
  USER_NAME="admin"
  PUB="$(cat "$KEY.pub")"
  if tart exec "$VM" true >/dev/null 2>&1; then
    tart exec "$VM" /bin/sh -c "mkdir -p ~/.ssh && chmod 700 ~/.ssh && echo '$PUB' >> ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys"
  elif command -v sshpass >/dev/null 2>&1; then
    # The cirruslabs images ship a published default password; it is not a user secret.
    SSHPASS="${MAC_IMAGE_PASSWORD:-admin}" sshpass -e ssh-copy-id -i "$KEY.pub" \
      -o StrictHostKeyChecking=accept-new -o UserKnownHostsFile="$RD/known_hosts" "$USER_NAME@$IP" >/dev/null
  else
    die "cannot install the SSH key: upgrade tart (for tart exec) or brew install sshpass"
  fi
else
  : "${UTM_BASE_VM:?set UTM_BASE_VM to a prepared base VM name}"
  : "${UTM_SSH_USER:?set UTM_SSH_USER}"
  : "${UTM_SSH_KEY:?set UTM_SSH_KEY to the private key the base VM accepts}"
  utmctl clone "$UTM_BASE_VM" --name "$VM"
  utmctl start "$VM"
  IP=""
  for _ in $(seq 1 60); do
    IP="$(utmctl ip-address "$VM" 2>/dev/null | head -n1 || true)"
    [ -n "$IP" ] && break
    sleep 5
  done
  [ -n "$IP" ] || die "UTM VM $VM never reported an IP"
  USER_NAME="$UTM_SSH_USER"
  cp "$UTM_SSH_KEY" "$KEY" && chmod 600 "$KEY"
fi

for _ in $(seq 1 60); do
  if ssh -i "$KEY" -o BatchMode=yes -o ConnectTimeout=5 -o StrictHostKeyChecking=accept-new \
      -o UserKnownHostsFile="$RD/known_hosts" "$USER_NAME@$IP" true 2>/dev/null; then
    READY=1; break
  fi
  sleep 5
done
[ "${READY:-0}" = 1 ] || die "SSH to $VM ($IP) never succeeded"

cat >"$RD/$SCOPE.env" <<ENV
SCOPE=$SCOPE
TARGET=mac
DISTRO=macos
TRANSPORT=ssh
INSTANCE_ID=$VM
PUBLIC_IP=$IP
SSH_USER=$USER_NAME
KEY_FILE=$KEY
REGION=local
EXPIRES_AT=$EXPIRES_AT
ENV
SUCCESS=1
log "ready: $SCOPE -> $VM ($IP) via $ENGINE"
echo "SCOPE=$SCOPE"
