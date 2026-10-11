#!/usr/bin/env bash
# provision-ec2.sh: launch one fresh, tagged EC2 instance for one target and attempt.
#
# Usage:
#   provision-ec2.sh --run-id ID --target linux|windows [--distro ubuntu|arch|amazon]
#                    [--attempt N]
#
# Reads <state>/<run-id>/run.env from preflight.sh (region, caller CIDR, TTL,
# instance type, volume size). Creates, all tagged with the run id and scope:
#   - linux:   an ephemeral key pair and a security group allowing tcp/22
#              from the caller's /32 only. The key is ed25519, except on Arch,
#              where it is a locally generated RSA 4096 key imported into EC2,
#              because the Arch Linux wiki notes that cloud-init on the Arch EC2
#              images does not accept EC (ed25519/ECDSA) keys.
#   - windows: a security group with no ingress, plus an IAM role and instance
#              profile (AmazonSSMManagedInstanceCore) so SSM can reach it
#   - the instance and its root volume (DeleteOnTermination=true)
# The instance runs `shutdown` at the TTL with shutdown behavior "terminate",
# so it removes itself even if this machine crashes.
#
# Every resource is tagged agentic-tools:expires-at with a time computed when
# this script runs (now + TTL + EXPIRES_SLACK_MINUTES), not when preflight ran,
# so `teardown.sh --orphans` never sweeps an attempt that is still inside its TTL.
#
# Arch Linux AMIs: Arch publishes no official AMIs and no public SSM parameter.
# The community images listed at https://arch-ami-list.drzee.net are resolved
# through its API, https://arch-ami-api.drzee.net/<region>/<arch>/std/latest,
# which returns JSON shaped like {"arch_amis":[{"ami":"ami-...","region":...,
# "arch":"x86_64"|"aarch64","kerneltype":"std","creation_time":...}]}. The
# resolved image's owner account and name are logged so they can be checked.
# There is no default owner account. If the API is unreachable or has no image
# for the region, set AMI_ID, or set ARCH_AMI_OWNER to an account you have
# verified yourself (the newest image named arch-linux-* from that owner is used).
#
# On any failure or interruption, the trap tears down everything this scope
# created. On success it writes <state>/<run-id>/<target>-a<N>.env.
# Optional env overrides: AMI_ID, ARCH_AMI_OWNER, ARCH_AMI_API.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source-path=SCRIPTDIR source=lib.sh
. "$SCRIPT_DIR/lib.sh"

RUN_ID="" ; TARGET="" ; DISTRO="ubuntu" ; ATTEMPT=1
while [ $# -gt 0 ]; do
  case "$1" in
    --run-id) RUN_ID="$2"; shift 2 ;;
    --target) TARGET="$2"; shift 2 ;;
    --distro) DISTRO="$2"; shift 2 ;;
    --attempt) ATTEMPT="$2"; shift 2 ;;
    *) die "unknown argument: $1" 2 ;;
  esac
done
valid_run_id "$RUN_ID"
case "$TARGET" in linux|windows) ;; *) die "--target must be linux or windows" 2 ;; esac
[[ "$ATTEMPT" =~ ^[1-3]$ ]] || die "--attempt must be 1, 2 or 3" 2
require_cmd aws ssh ssh-keygen
load_run_env "$RUN_ID"
# Per-resource expiry, computed at launch time. This overrides the estimate in run.env.
EXPIRES_AT="$(utc_plus_minutes $((TTL_HOURS * 60 + EXPIRES_SLACK_MINUTES)))"
RD="$(run_dir "$RUN_ID")"
SCOPE="$TARGET-a$ATTEMPT"
NAME="$RUN_ID-$SCOPE"
A=(aws --region "$REGION")

if [ -f "$RD/$SCOPE.env" ]; then
  die "$SCOPE already provisioned for this run; use the next --attempt for a fresh instance" 2
fi

SUCCESS=0
rollback() {
  local rc=$?
  if [ "$SUCCESS" != 1 ]; then
    log "provisioning $SCOPE failed or was interrupted (rc=$rc); tearing down this scope"
    "$SCRIPT_DIR/teardown.sh" --run-id "$RUN_ID" --region "$REGION" --scope "$SCOPE" || \
      log "scope teardown reported leftovers; run: $SCRIPT_DIR/teardown.sh --run-id $RUN_ID --region $REGION"
  fi
  exit "$rc"
}
trap rollback EXIT
trap 'exit 130' INT TERM

tags_json() {  # tags_json RESOURCE_TYPE
  printf '{"ResourceType":"%s","Tags":[{"Key":"%s","Value":"%s"},{"Key":"%s","Value":"%s"},{"Key":"%s","Value":"%s"},{"Key":"Name","Value":"%s"}]}' \
    "$1" "$TAG_KEY" "$RUN_ID" "$SCOPE_TAG_KEY" "$SCOPE" "$EXPIRES_TAG_KEY" "$EXPIRES_AT" "$NAME"
}
iam_tags=("Key=$TAG_KEY,Value=$RUN_ID" "Key=$SCOPE_TAG_KEY,Value=$SCOPE" "Key=$EXPIRES_TAG_KEY,Value=$EXPIRES_AT")

# --- architecture and AMI ---------------------------------------------------
CPU_ARCH="$("${A[@]}" ec2 describe-instance-types --instance-types "$INSTANCE_TYPE" \
  --query 'InstanceTypes[0].ProcessorInfo.SupportedArchitectures[0]' --output text)"
case "$CPU_ARCH" in x86_64) U_ARCH=amd64 ;; arm64) U_ARCH=arm64 ;; *) die "unsupported arch $CPU_ARCH" ;; esac

ssm_param() { "${A[@]}" ssm get-parameter --name "$1" --query 'Parameter.Value' --output text; }
if [ -n "${AMI_ID:-}" ]; then
  AMI="$AMI_ID"
elif [ "$TARGET" = windows ]; then
  [ "$CPU_ARCH" = x86_64 ] || die "Windows needs an x86_64 instance type"
  AMI="$(ssm_param /aws/service/ami-windows-latest/Windows_Server-2022-English-Full-Base)"
else
  case "$DISTRO" in
    ubuntu) AMI="$(ssm_param "/aws/service/canonical/ubuntu/server/24.04/stable/current/$U_ARCH/hvm/ebs-gp3/ami-id")" ;;
    amazon) AMI="$(ssm_param "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-$CPU_ARCH")" ;;
    arch)
      # See the header comment: community AMIs from arch-ami-list.drzee.net, no default owner.
      if [ -n "${ARCH_AMI_OWNER:-}" ]; then
        AMI="$("${A[@]}" ec2 describe-images --owners "$ARCH_AMI_OWNER" \
          --filters "Name=name,Values=arch-linux-*" "Name=architecture,Values=$CPU_ARCH" \
          --query 'sort_by(Images,&CreationDate)[-1].ImageId' --output text)"
      else
        require_cmd curl python3
        D_ARCH="$CPU_ARCH"; [ "$CPU_ARCH" = arm64 ] && D_ARCH=aarch64
        API="${ARCH_AMI_API:-https://arch-ami-api.drzee.net}/$REGION/$D_ARCH/std/latest"
        AMI="$(curl -fsS --max-time 20 "$API" 2>/dev/null | python3 -c '
import json, sys
try:
    amis = json.load(sys.stdin).get("arch_amis") or []
except ValueError:
    amis = []
print(amis[0]["ami"] if amis and str(amis[0].get("ami", "")).startswith("ami-") else "")
' || true)"
        [ -n "$AMI" ] || die "no Arch Linux AMI for $REGION/$D_ARCH from $API. Set AMI_ID to an Arch image you trust, or ARCH_AMI_OWNER to an owner account you have verified." 2
      fi
      [[ "$AMI" =~ ^ami- ]] || die "could not resolve an Arch Linux AMI (set AMI_ID or ARCH_AMI_OWNER)" 2
      log "Arch Linux AMI $AMI: $("${A[@]}" ec2 describe-images --image-ids "$AMI" \
        --query 'Images[0].[OwnerId,Name]' --output text | tr '\t' ' ') (community image, not published by Arch Linux)" ;;
    *) die "--distro must be ubuntu, arch or amazon" 2 ;;
  esac
fi
[[ "$AMI" =~ ^ami- ]] || die "could not resolve an AMI for $TARGET/$DISTRO (set AMI_ID to override)"
ROOT_DEV="$("${A[@]}" ec2 describe-images --image-ids "$AMI" --query 'Images[0].RootDeviceName' --output text)"
case "$DISTRO" in ubuntu) SSH_USER=ubuntu ;; amazon) SSH_USER=ec2-user ;; arch) SSH_USER=arch ;; esac
[ "$TARGET" = windows ] && SSH_USER=""

# --- network: default VPC, caller-only security group -----------------------
VPC="$("${A[@]}" ec2 describe-vpcs --filters Name=isDefault,Values=true --query 'Vpcs[0].VpcId' --output text)"
[[ "$VPC" =~ ^vpc- ]] || die "no default VPC in $REGION"
SG="$("${A[@]}" ec2 create-security-group --group-name "$NAME" \
  --description "validate-install $NAME (ephemeral)" --vpc-id "$VPC" \
  --tag-specifications "$(tags_json security-group)" --query GroupId --output text)"
if [ "$TARGET" = linux ]; then
  "${A[@]}" ec2 authorize-security-group-ingress --group-id "$SG" \
    --ip-permissions "IpProtocol=tcp,FromPort=22,ToPort=22,IpRanges=[{CidrIp=$CALLER_CIDR,Description=validate-install-caller}]" >/dev/null
fi

# --- access: ephemeral key pair (linux) or SSM instance profile (windows) ---
KEY_FILE="" ; KEY_ARGS=() ; PROFILE_ARGS=()
if [ "$TARGET" = linux ]; then
  KEY_FILE="$RD/$SCOPE.pem"
  if [ "$DISTRO" = arch ]; then
    # cloud-init on the Arch EC2 images rejects EC keys (Arch Linux wiki, "Arch
    # Linux AMIs for Amazon Web Services"). EC2 create-key-pair only makes RSA
    # 2048, so generate RSA 4096 locally and import the public half.
    ( umask 077; ssh-keygen -q -t rsa -b 4096 -m PEM -N '' -C "$NAME" -f "$KEY_FILE" )
    "${A[@]}" ec2 import-key-pair --key-name "$NAME" --public-key-material "fileb://$KEY_FILE.pub" \
      --tag-specifications "$(tags_json key-pair)" >/dev/null
    rm -f "$KEY_FILE.pub"
  else
    ( umask 077
      "${A[@]}" ec2 create-key-pair --key-name "$NAME" --key-type ed25519 \
        --tag-specifications "$(tags_json key-pair)" --query KeyMaterial --output text >"$KEY_FILE" )
  fi
  KEY_ARGS=(--key-name "$NAME")
else
  aws iam create-role --role-name "$NAME" --path "$IAM_PATH" --tags "${iam_tags[@]}" \
    --assume-role-policy-document '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":{"Service":"ec2.amazonaws.com"},"Action":"sts:AssumeRole"}]}' >/dev/null
  aws iam attach-role-policy --role-name "$NAME" \
    --policy-arn arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore
  aws iam create-instance-profile --instance-profile-name "$NAME" --path "$IAM_PATH" --tags "${iam_tags[@]}" >/dev/null
  aws iam add-role-to-instance-profile --instance-profile-name "$NAME" --role-name "$NAME"
  PROFILE_ARGS=(--iam-instance-profile "Name=$NAME")
fi

# --- user data: hard TTL backstop -------------------------------------------
UD="$RD/$SCOPE.userdata"
if [ "$TARGET" = linux ]; then
  printf '#!/bin/bash\nshutdown -h +%d\n' "$((TTL_HOURS * 60))" >"$UD"
  VOL="$VOLUME_GB"
else
  printf '<powershell>\nshutdown /s /t %d\n</powershell>\n' "$((TTL_HOURS * 3600))" >"$UD"
  VOL=$(( VOLUME_GB < 60 ? 60 : VOLUME_GB ))
fi

# --- launch (retry while a new instance profile propagates) -----------------
IID=""
for try in 1 2 3 4 5 6; do
  if IID="$("${A[@]}" ec2 run-instances --image-id "$AMI" --instance-type "$INSTANCE_TYPE" \
      --count 1 --security-group-ids "$SG" ${KEY_ARGS[@]+"${KEY_ARGS[@]}"} ${PROFILE_ARGS[@]+"${PROFILE_ARGS[@]}"} \
      --instance-initiated-shutdown-behavior terminate \
      --metadata-options HttpTokens=required \
      --block-device-mappings "DeviceName=$ROOT_DEV,Ebs={VolumeSize=$VOL,VolumeType=gp3,DeleteOnTermination=true}" \
      --user-data "file://$UD" \
      --tag-specifications "$(tags_json instance)" "$(tags_json volume)" \
      --query 'Instances[0].InstanceId' --output text 2>"$RD/$SCOPE.launch.err")"; then
    break
  fi
  if [ "$TARGET" != windows ] || [ "$try" -ge 6 ]; then
    die "run-instances failed: $(cat "$RD/$SCOPE.launch.err")"
  fi
  log "launch attempt $try failed (instance profile may still be propagating); retrying in 10s"
  sleep 10
done
log "launched $IID ($TARGET/$DISTRO, $INSTANCE_TYPE) in $REGION"
"${A[@]}" ec2 wait instance-running --instance-ids "$IID"
PUBLIC_IP="$("${A[@]}" ec2 describe-instances --instance-ids "$IID" \
  --query 'Reservations[0].Instances[0].PublicIpAddress' --output text)"

# --- wait for access ----------------------------------------------------------
if [ "$TARGET" = linux ]; then
  for _ in $(seq 1 60); do
    if ssh -i "$KEY_FILE" -o BatchMode=yes -o ConnectTimeout=5 -o StrictHostKeyChecking=accept-new \
        -o UserKnownHostsFile="$RD/known_hosts" "$SSH_USER@$PUBLIC_IP" true 2>/dev/null; then
      READY=1; break
    fi
    sleep 5
  done
else
  for _ in $(seq 1 60); do
    st="$("${A[@]}" ssm describe-instance-information --filters "Key=InstanceIds,Values=$IID" \
      --query 'InstanceInformationList[0].PingStatus' --output text 2>/dev/null || true)"
    if [ "$st" = Online ]; then READY=1; break; fi
    sleep 10
  done
fi
[ "${READY:-0}" = 1 ] || die "$IID never became reachable"

cat >"$RD/$SCOPE.env" <<ENV
SCOPE=$SCOPE
TARGET=$TARGET
DISTRO=$DISTRO
TRANSPORT=$([ "$TARGET" = linux ] && echo ssh || echo ssm)
INSTANCE_ID=$IID
PUBLIC_IP=$PUBLIC_IP
SSH_USER=$SSH_USER
KEY_FILE=$KEY_FILE
REGION=$REGION
EXPIRES_AT=$EXPIRES_AT
ENV
SUCCESS=1
log "ready: $SCOPE -> $IID ($PUBLIC_IP)"
echo "SCOPE=$SCOPE"
