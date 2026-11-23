#!/bin/bash
# ============================================================================
# Jenkins 控制器镜像构建与推送脚本
# ============================================================================
# 将 Jenkins 控制器镜像构建并推送到华为云 SWR。
# 用法: ./build.sh <region> <swr-organization> <image-tag>
# ============================================================================

set -euo pipefail

REGION="${1:-cn-north-4}"
SWR_ORG="${2:-jenkins-org}"
IMAGE_TAG="${3:-lts-jdk17}"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
DOCKER_DIR="${SCRIPT_DIR}/../src/docker"

echo "=== 构建 Jenkins 控制器镜像 ==="
docker build -t jenkins-controller:${IMAGE_TAG} "${DOCKER_DIR}"

echo "=== 登录 SWR ==="
SWR_LOGIN=$(docker login -u "$(echo $HW_ACCESS_KEY)" -p "$(echo $HW_SECRET_KEY)" swr.${REGION}.myhuaweicloud.com 2>&1) || {
  echo "SWR 登录失败，请确保已设置 HW_ACCESS_KEY 和 HW_SECRET_KEY 环境变量"
  exit 1
}

echo "=== 打标签并推送 ==="
SWR_ADDRESS="swr.${REGION}.myhuaweicloud.com/${SWR_ORG}/jenkins-controller:${IMAGE_TAG}"
docker tag jenkins-controller:${IMAGE_TAG} "${SWR_ADDRESS}"
docker push "${SWR_ADDRESS}"

echo "=== 完成 ==="
echo "镜像地址: ${SWR_ADDRESS}"
