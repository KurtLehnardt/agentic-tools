#!/usr/bin/env bash
# teardown.sh: delete every resource carrying the validate-install run tag,
# then verify with a tag sweep that nothing remains. Idempotent: running it
# twice, or on a run that never launched anything, is a no-op that exits 0.
#
# Usage:
#   teardown.sh --run-id ID [--region R] [--scope linux-a1] [--dry-run]
#   teardown.sh --orphans [--region R | --all-regions] [--include-active] [--dry-run]
#
# --run-id    sweep one run (all scopes, or only --scope).
# --orphans   find every run id carrying the tag key and sweep each one. Runs
#             whose agentic-tools:expires-at tag is still in the future are
#             skipped unless --include-active, because they may belong to a
#             validation another session is running right now. Expiry tags of
#             an attempt whose instance is already terminated do not count.
#
# Only resources whose tag agentic-tools:validate-install equals the run id
# are touched (IAM entries must also live under /agentic-tools/validate-install/).
# Local VMs are matched by the exact name prefix <run-id>-mac-.
# Order: instances (wait for terminated) -> security groups -> key pairs ->
# leftover volumes -> IAM instance profiles and roles -> local VMs and key files.
#
# Exit codes: 0 verified clean, 1 resources remain, 2 usage error.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source-path=SCRIPTDIR source=lib.sh
. "$SCRIPT_DIR/lib.sh"

RUN_ID="" ; ORPHANS=0 ; REGION_ARG="" ; ALL_REGIONS=0 ; SCOPE="" ; DRY=0 ; INCLUDE_ACTIVE=0
while [ $# -gt 0 ]; do
  case "$1" in
    --run-id) RUN_ID="$2"; shift 2 ;;
    --orphans) ORPHANS=1; shift ;;
    --region) REGION_ARG="$2"; shift 2 ;;
    --all-regions) ALL_REGIONS=1; shift ;;
    --scope) SCOPE="$2"; shift 2 ;;
    --include-active) INCLUDE_ACTIVE=1; shift ;;
    --dry-run) DRY=1; shift ;;
    *) die "unknown argument: $1" 2 ;;
  esac
done
if [ "$ORPHANS" = 1 ]; then
  [ -z "$RUN_ID" ] || die "use --run-id or --orphans, not both" 2
else
  valid_run_id "$RUN_ID"
fi

act() {  # act CMD... : run, or print under --dry-run
  if [ "$DRY" = 1 ]; then log "DRY-RUN: $*"; else "$@"; fi
}

HAVE_AWS=0
if command -v aws >/dev/null 2>&1 && aws sts get-caller-identity >/dev/null 2>&1; then HAVE_AWS=1; fi

REGIONS=()
if [ "$HAVE_AWS" = 1 ]; then
  if [ "$ALL_REGIONS" = 1 ]; then
    read -r -a REGIONS <<<"$(aws ec2 describe-regions --query 'Regions[].RegionName' --output text)"
  elif [ -n "$REGION_ARG" ]; then
    REGIONS=("$REGION_ARG")
  elif [ -n "$RUN_ID" ] && [ -f "$(run_dir "$RUN_ID")/run.env" ]; then
    REGIONS=("$(sed -n 's/^REGION=//p' "$(run_dir "$RUN_ID")/run.env")")
    [ -n "${REGIONS[0]}" ] || REGIONS=("$(resolve_region "")")
  else
    REGIONS=("$(resolve_region "")")
  fi
else
  log "WARNING: no usable AWS credentials; only local VMs and files can be cleaned"
fi

set_filters() {  # set_filters RUN_ID -> F=(EC2 tag filters for this run and scope)
  F=("Name=tag:$TAG_KEY,Values=$1")
  [ -z "$SCOPE" ] || F+=("Name=tag:$SCOPE_TAG_KEY,Values=$SCOPE")
}

# --- discovery ----------------------------------------------------------------
list_instances() { set_filters "$2"
  aws --region "$1" ec2 describe-instances --filters "${F[@]}" \
    "Name=instance-state-name,Values=pending,running,stopping,stopped,shutting-down" \
    --query 'Reservations[].Instances[].InstanceId' --output text; }
list_sgs() { set_filters "$2"
  aws --region "$1" ec2 describe-security-groups --filters "${F[@]}" --query 'SecurityGroups[].GroupId' --output text; }
list_keys() { set_filters "$2"
  aws --region "$1" ec2 describe-key-pairs --filters "${F[@]}" --query 'KeyPairs[].KeyPairId' --output text; }
list_vols() { set_filters "$2"
  aws --region "$1" ec2 describe-volumes --filters "${F[@]}" --query 'Volumes[].VolumeId' --output text; }

iam_has_run_tag() {  # iam_has_run_tag role|profile NAME RUN_ID
  local q
  if [ "$1" = role ]; then
    q="$(aws iam list-role-tags --role-name "$2" --query "Tags[?Key=='$TAG_KEY'].Value" --output text 2>/dev/null || true)"
  else
    q="$(aws iam list-instance-profile-tags --instance-profile-name "$2" --query "Tags[?Key=='$TAG_KEY'].Value" --output text 2>/dev/null || true)"
  fi
  [ "$q" = "$3" ] || return 1
  [ -z "$SCOPE" ] || [[ "$2" == *"-$SCOPE" ]]
}

list_iam() {  # list_iam role|profile RUN_ID -> names carrying the run tag
  local names n
  if [ "$1" = role ]; then
    names="$(aws iam list-roles --path-prefix "$IAM_PATH" --query 'Roles[].RoleName' --output text 2>/dev/null || true)"
  else
    names="$(aws iam list-instance-profiles --path-prefix "$IAM_PATH" --query 'InstanceProfiles[].InstanceProfileName' --output text 2>/dev/null || true)"
  fi
  for n in $names; do
    [[ "$n" == "$2"-* ]] && iam_has_run_tag "$1" "$n" "$2" && printf '%s\n' "$n"
  done
  return 0
}

list_local_vms() {  # list_local_vms RUN_ID
  local prefix="$1-mac-"
  [ -z "$SCOPE" ] || prefix="$1-$SCOPE"
  if command -v tart >/dev/null 2>&1; then
    tart list --source local --quiet 2>/dev/null | grep -E "^${prefix}" || true
  fi
  if command -v utmctl >/dev/null 2>&1; then
    utmctl list 2>/dev/null | awk '{print $NF}' | grep -E "^${prefix}" || true
  fi
}

# --- sweep one run -------------------------------------------------------------
sweep_region() {  # sweep_region REGION RUN_ID
  local r="$1" id="$2" ids x tries
  ids="$(list_instances "$r" "$id")"
  if [ -n "$ids" ]; then
    log "[$r] terminating instances: $ids"
    # shellcheck disable=SC2086
    act aws --region "$r" ec2 terminate-instances --instance-ids $ids >/dev/null
    # shellcheck disable=SC2086
    [ "$DRY" = 1 ] || aws --region "$r" ec2 wait instance-terminated --instance-ids $ids
  fi
  for x in $(list_sgs "$r" "$id"); do
    for tries in 1 2 3 4 5 6 7 8 9 10 11 12; do
      if act aws --region "$r" ec2 delete-security-group --group-id "$x" 2>/dev/null; then
        log "[$r] deleted security group $x"; break
      fi
      [ "$tries" = 12 ] && log "[$r] could not delete security group $x (still in use?)"
      sleep 10   # ENIs of terminated instances detach asynchronously
    done
  done
  for x in $(list_keys "$r" "$id"); do
    act aws --region "$r" ec2 delete-key-pair --key-pair-id "$x" && log "[$r] deleted key pair $x"
  done
  for x in $(list_vols "$r" "$id"); do
    if act aws --region "$r" ec2 delete-volume --volume-id "$x" 2>/dev/null; then
      log "[$r] deleted volume $x"
    else
      log "[$r] volume $x not deletable yet (attached?)"
    fi
  done
}

sweep_iam() {  # sweep_iam RUN_ID (IAM is global)
  local id="$1" n r p
  for n in $(list_iam profile "$id"); do
    for r in $(aws iam get-instance-profile --instance-profile-name "$n" --query 'InstanceProfile.Roles[].RoleName' --output text); do
      act aws iam remove-role-from-instance-profile --instance-profile-name "$n" --role-name "$r"
    done
    act aws iam delete-instance-profile --instance-profile-name "$n" && log "deleted instance profile $n"
  done
  for n in $(list_iam role "$id"); do
    for p in $(aws iam list-attached-role-policies --role-name "$n" --query 'AttachedPolicies[].PolicyArn' --output text); do
      act aws iam detach-role-policy --role-name "$n" --policy-arn "$p"
    done
    act aws iam delete-role --role-name "$n" && log "deleted role $n"
  done
}

sweep_local() {  # sweep_local RUN_ID
  local id="$1" vm rd
  for vm in $(list_local_vms "$id"); do
    if command -v tart >/dev/null 2>&1 && tart list --source local --quiet | grep -qx "$vm"; then
      act tart stop "$vm" >/dev/null 2>&1 || true
      act tart delete "$vm" && log "deleted tart VM $vm"
    elif command -v utmctl >/dev/null 2>&1; then
      act utmctl stop "$vm" >/dev/null 2>&1 || true
      act utmctl delete "$vm" && log "deleted UTM VM $vm"
    fi
  done
  rd="$(run_dir "$id")"
  if [ -d "$rd" ]; then
    # Keys go; transcripts and run.env stay for the report.
    if [ -n "$SCOPE" ]; then
      act rm -f "$rd/$SCOPE.pem" "$rd/$SCOPE.key" "$rd/$SCOPE.key.pub" "$rd/$SCOPE.env" "$rd/$SCOPE.userdata"
    else
      act find "$rd" -maxdepth 1 \( -name '*.pem' -o -name '*.key' -o -name '*.key.pub' -o -name '*.userdata' -o -name '*-a[0-9].env' \) -delete
    fi
  fi
}

count_remaining() {  # count_remaining RUN_ID -> prints leftovers, returns count via stdout last line
  local id="$1" r n=0 x
  for r in ${REGIONS[@]+"${REGIONS[@]}"}; do
    for x in $(list_instances "$r" "$id") $(list_sgs "$r" "$id") $(list_keys "$r" "$id") $(list_vols "$r" "$id"); do
      log "REMAINING [$r] $x"; n=$((n + 1))
    done
  done
  if [ "$HAVE_AWS" = 1 ]; then
    for x in $(list_iam profile "$id") $(list_iam role "$id"); do log "REMAINING [iam] $x"; n=$((n + 1)); done
  fi
  for x in $(list_local_vms "$id"); do log "REMAINING [local] $x"; n=$((n + 1)); done
  echo "$n"
}

run_expires_at() {  # run_expires_at RUN_ID -> the latest expires-at that still counts for the run, or empty
  # Each attempt tags its resources with its own expiry, so take the maximum:
  # the run is active while any attempt is still inside its TTL. An attempt
  # whose instance is already terminated is over, so the expiry tags on its
  # leftover security groups are ignored; otherwise a crashed attempt's
  # security group would shield the whole run from the sweep until its TTL
  # ends. A security group whose scope has no terminated instance still
  # counts, because a provision that is running right now creates the group
  # before it launches the instance.
  local id="$1" r dead q="Tags[?Key=='$EXPIRES_TAG_KEY'].Value[]"
  {
    for r in ${REGIONS[@]+"${REGIONS[@]}"}; do
      dead="$(aws --region "$r" ec2 describe-instances \
        --filters "Name=tag:$TAG_KEY,Values=$id" "Name=instance-state-name,Values=terminated" \
        --query "Reservations[].Instances[].Tags[?Key=='$SCOPE_TAG_KEY'].Value[]" --output text 2>/dev/null || true)"
      aws --region "$r" ec2 describe-security-groups --filters "Name=tag:$TAG_KEY,Values=$id" \
        --query "SecurityGroups[].[Tags[?Key=='$SCOPE_TAG_KEY'].Value|[0],Tags[?Key=='$EXPIRES_TAG_KEY'].Value|[0]]" \
        --output text 2>/dev/null |
        DEAD="$dead" awk -F'\t' 'BEGIN { n = split(ENVIRON["DEAD"], d, /[ \t\n]+/); for (i = 1; i <= n; i++) if (d[i] != "") dead[d[i]] = 1 }
          !($1 in dead) { print $2 }' || true
      aws --region "$r" ec2 describe-instances \
        --filters "Name=tag:$TAG_KEY,Values=$id" "Name=instance-state-name,Values=pending,running,stopping,stopped,shutting-down" \
        --query "Reservations[].Instances[].$q" --output text 2>/dev/null || true
    done
    # Local (mac) attempts have no AWS tags; read this machine's run.env and scope files.
    cat "$(run_dir "$id")"/*.env 2>/dev/null | sed -n 's/^EXPIRES_AT=//p' || true
  } | tr '\t' '\n' | grep -E '^[0-9]{4}-[0-9]{2}-[0-9]{2}T' | sort | tail -n1 || true
}

discover_run_ids() {
  local r
  {
    for r in ${REGIONS[@]+"${REGIONS[@]}"}; do
      aws --region "$r" ec2 describe-tags --filters "Name=key,Values=$TAG_KEY" \
        --query 'Tags[].Value' --output text 2>/dev/null | tr '\t' '\n'
    done
    if [ "$HAVE_AWS" = 1 ]; then
      aws iam list-roles --path-prefix "$IAM_PATH" --query 'Roles[].RoleName' --output text 2>/dev/null |
        tr '\t' '\n' | grep -oE '^vi-[0-9]{14}-[0-9a-f]{4}' || true
    fi
    if command -v tart >/dev/null 2>&1; then
      tart list --source local --quiet 2>/dev/null | grep -oE '^vi-[0-9]{14}-[0-9a-f]{4}(-mac-a[0-9])$' |
        grep -oE '^vi-[0-9]{14}-[0-9a-f]{4}' || true
    fi
  } | grep -E "$RUN_ID_RE" | sort -u
}

sweep_run() {
  local id="$1" r
  log "sweeping run $id${SCOPE:+ (scope $SCOPE)} in: ${REGIONS[*]:-local only}"
  for r in ${REGIONS[@]+"${REGIONS[@]}"}; do sweep_region "$r" "$id"; done
  [ "$HAVE_AWS" = 1 ] && sweep_iam "$id"
  sweep_local "$id"
}

# --- main ------------------------------------------------------------------------
TARGET_RUNS=()
if [ "$ORPHANS" = 1 ]; then
  NOW="$(now_utc)"
  for id in $(discover_run_ids); do
    exp="$(run_expires_at "$id")"
    if [ -n "$exp" ] && [[ "$exp" > "$NOW" ]] && [ "$INCLUDE_ACTIVE" = 0 ]; then
      log "skipping $id: TTL runs until $exp, it may be active (pass --include-active to sweep it)"
      continue
    fi
    TARGET_RUNS+=("$id")
  done
  [ "${#TARGET_RUNS[@]}" -gt 0 ] || { log "no orphaned validate-install resources found"; exit 0; }
else
  TARGET_RUNS=("$RUN_ID")
fi

FAILED=0
for id in "${TARGET_RUNS[@]}"; do
  sweep_run "$id"
  if [ "$DRY" = 1 ]; then continue; fi
  left="$(count_remaining "$id" | tail -n1)"
  aws_expected=1
  if [ "$ORPHANS" = 0 ] && [ -f "$(run_dir "$id")/run.env" ] &&
     [ -z "$(sed -n 's/^REGION=//p' "$(run_dir "$id")/run.env")" ]; then aws_expected=0; fi
  if [ "$HAVE_AWS" = 0 ] && [ "$aws_expected" = 1 ]; then
    log "NOT VERIFIED: no AWS credentials, so AWS resources for $id could not be checked"
    FAILED=1
  elif [ "$left" = 0 ]; then
    log "VERIFIED: 0 resources tagged $TAG_KEY=$id remain${SCOPE:+ for scope $SCOPE}"
  else
    log "NOT CLEAN: $left resources tagged $id remain; re-run: $0 --run-id $id ${REGIONS[0]:+--region ${REGIONS[0]}}"
    FAILED=1
  fi
done
exit "$FAILED"
