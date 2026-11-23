# ============================================================================
# SFS Turbo 文件存储
# ============================================================================
# 为 Jenkins 控制器提供 JENKINS_HOME 持久化存储。
# SFS Turbo 支持 NFS 协议挂载到 CCE 节点。
# ============================================================================

resource "huaweicloud_sfs_turbo" "jenkins_home" {
  name              = "${local.name_prefix}-jenkins-home"
  size              = var.sfs_size_gb
  share_type        = var.sfs_share_type
  vpc_id            = local.vpc_id
  subnet_id         = local.subnet_id
  security_group_id = huaweicloud_networking_secgroup.sfs.id
  availability_zone = var.availability_zone

  tags = local.common_tags
}
