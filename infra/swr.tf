# ============================================================================
# SWR 容器镜像仓库
# ============================================================================
# 存储 Jenkins 控制器自定义镜像。
# ============================================================================

resource "huaweicloud_swr_organization" "jenkins" {
  name = var.swr_organization
}

resource "huaweicloud_swr_repository" "controller" {
  organization = huaweicloud_swr_organization.jenkins.name
  name         = "jenkins-controller"
  is_public    = false
  category     = "other"
  description  = "Jenkins controller image with Kubernetes plugin"
}
