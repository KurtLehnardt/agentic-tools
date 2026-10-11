#!/usr/bin/env bash
# preflight.sh: verify AWS identity, region, quota, and cost before any launch.
# Creates nothing in AWS. Writes <state>/<run-id>/run.env for the other scripts.
#
# Usage:
#   preflight.sh [--targets linux,windows,mac] [--instance-type t3.large]
#                [--region R] [--ttl-hours 2] [--volume-gb 30]
#
# Prints a human summary to stderr and RUN_ID=<id> as the last stdout line.
# Exit codes: 0 ready, 1 a check failed, 2 usage error.
set -euo pipefail
# shellcheck source-path=SCRIPTDIR source=lib.sh
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

TARGETS="linux"
INSTANCE_TYPE="t3.large"
REGION_ARG=""
TTL_HOURS=2
VOLUME_GB=30
while [ $# -gt 0 ]; do
  case "$1" in
    --targets) TARGETS="$2"; shift 2 ;;
    --instance-type) INSTANCE_TYPE="$2"; shift 2 ;;
    --region) REGION_ARG="$2"; shift 2 ;;
    --ttl-hours) TTL_HOURS="$2"; shift 2 ;;
    --volume-gb) VOLUME_GB="$2"; shift 2 ;;
    *) die "unknown argument: $1" 2 ;;
  esac
done
[[ "$TTL_HOURS" =~ ^[1-9][0-9]?$ ]] || die "--ttl-hours must be 1-99" 2

needs_aws=0
needs_mac=0
IFS=',' read -r -a target_list <<<"$TARGETS"
for t in "${target_list[@]}"; do
  case "$t" in
    linux|windows) needs_aws=1 ;;
    mac) needs_mac=1 ;;
    *) die "unknown target '$t' (linux, windows, mac)" 2 ;;
  esac
done

RUN_ID="vi-$(date -u +%Y%m%d%H%M%S)-$(od -An -N2 -tx1 /dev/urandom | tr -d ' \n')"
# Earliest possible expiry, used only as a fallback for local-only runs. Each
# provisioned resource gets its own expires-at tag computed at launch time by
# provision-ec2.sh or mac-vm.sh, so a later attempt is never considered expired
# just because preflight ran long ago.
EXPIRES_AT="$(utc_plus_hours "$TTL_HOURS")"
ACCOUNT="" ; ARN="" ; REGION="" ; CALLER_CIDR="" ; VCPUS="" ; MEM_MIB=""

if [ "$needs_aws" = 1 ]; then
  require_cmd aws curl
  if ! ident="$(aws sts get-caller-identity --query '[Account,Arn]' --output text 2>/dev/null)"; then
    die "no usable AWS credentials. Export them in your shell profile (~/.zshrc) or set AWS_PROFILE, then retry. Never paste keys into chat."
  fi
  read -r ACCOUNT ARN <<<"$ident"
  REGION="$(resolve_region "$REGION_ARG")"
  CALLER_IP="$(curl -fsS --max-time 10 https://checkip.amazonaws.com | tr -d '[:space:]')"
  [[ "$CALLER_IP" =~ ^[0-9.]+$ ]] || die "could not determine caller public IPv4"
  CALLER_CIDR="$CALLER_IP/32"

  read -r VCPUS MEM_MIB < <(aws --region "$REGION" ec2 describe-instance-types \
    --instance-types "$INSTANCE_TYPE" \
    --query 'InstanceTypes[0].[VCpuInfo.DefaultVCpus,MemoryInfo.SizeInMiB]' --output text) ||
    die "instance type $INSTANCE_TYPE not offered in $REGION"

  # L-1216C47A = Running On-Demand Standard (A, C, D, H, I, M, R, T, Z) instances, in vCPUs.
  QUOTA="$(aws --region "$REGION" service-quotas get-service-quota --service-code ec2 \
    --quota-code L-1216C47A --query 'Quota.Value' --output text 2>/dev/null || echo unknown)"

  ORPHANS="$(aws --region "$REGION" ec2 describe-instances \
    --filters "Name=tag-key,Values=$TAG_KEY" \
      "Name=instance-state-name,Values=pending,running,stopping,stopped" \
    --query 'length(Reservations[].Instances[])' --output text)"
fi

# Approximate us-east-1 on-demand Linux prices (USD/hour). Other regions differ by up to ~30%.
price_linux() {
  case "$1" in
    t3.medium) echo 0.0416 ;; t3.large) echo 0.0832 ;; t3.xlarge) echo 0.1664 ;;
    t3.2xlarge) echo 0.3328 ;; m7i.large) echo 0.1008 ;; m7i.xlarge) echo 0.2016 ;;
    m7i.2xlarge) echo 0.4032 ;; r7i.xlarge) echo 0.2646 ;; r7i.2xlarge) echo 0.5292 ;;
    g5.xlarge) echo 1.006 ;; *) echo "" ;;
  esac
}

EST_LINE="no EC2 targets"
if [ "$needs_aws" = 1 ]; then
  base="$(price_linux "$INSTANCE_TYPE")"
  if [ -z "$base" ]; then
    EST_LINE="unknown price for $INSTANCE_TYPE; check https://aws.amazon.com/ec2/pricing/on-demand/"
  else
    EST_LINE="$(awk -v b="$base" -v v="$VCPUS" -v ttl="$TTL_HOURS" -v gb="$VOLUME_GB" \
      -v t="$TARGETS" -v it="$INSTANCE_TYPE" 'BEGIN {
        n = split(t, a, ","); total = 0
        for (i = 1; i <= n; i++) {
          if (a[i] == "linux")   { h = b; g = gb }
          else if (a[i] == "windows") { h = b + v * ((it ~ /^t3/) ? 0.0138 : 0.046); g = (gb < 60 ? 60 : gb) }
          else continue
          total += h * ttl + g * 0.08 / 730 * ttl
        }
        printf "about $%.2f per attempt if every instance lives the full TTL; worst case 3 attempts = $%.2f", total, total * 3
      }')"
  fi
fi

RD="$(run_dir "$RUN_ID")"
mkdir -p "$RD/transcripts"
chmod 700 "$RD"
cat >"$RD/run.env" <<ENV
RUN_ID=$RUN_ID
REGION=$REGION
ACCOUNT=$ACCOUNT
CALLER_CIDR=$CALLER_CIDR
TTL_HOURS=$TTL_HOURS
EXPIRES_AT=$EXPIRES_AT
INSTANCE_TYPE=$INSTANCE_TYPE
VOLUME_GB=$VOLUME_GB
TARGETS=$TARGETS
ENV

{
  echo "== validate-install preflight =="
  echo "run id:        $RUN_ID"
  echo "targets:       $TARGETS"
  if [ "$needs_aws" = 1 ]; then
    echo "account:       $ACCOUNT"
    echo "identity:      $ARN"
    echo "region:        $REGION"
    echo "ingress from:  $CALLER_CIDR only"
    echo "instance type: $INSTANCE_TYPE ($VCPUS vCPU, $((MEM_MIB / 1024)) GiB RAM)"
    echo "vCPU quota:    $QUOTA (standard on-demand, L-1216C47A)"
    echo "existing tagged instances in region: $ORPHANS"
  fi
  if [ "$needs_mac" = 1 ]; then
    if command -v tart >/dev/null 2>&1; then echo "mac VM:        tart"
    elif command -v utmctl >/dev/null 2>&1; then echo "mac VM:        utm (utmctl)"
    else echo "mac VM:        UNAVAILABLE (install tart: brew install cirruslabs/cli/tart)"; fi
  fi
  echo "hard TTL:      $TTL_HOURS h after each launch; every EC2 instance terminates itself then"
  echo "tag:           $TAG_KEY=$RUN_ID"
  echo "cost estimate: $EST_LINE"
} >&2

echo "RUN_ID=$RUN_ID"
