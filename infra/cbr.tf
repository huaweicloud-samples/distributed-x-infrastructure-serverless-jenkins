# ============================================================================
# CBR 云备份
# ============================================================================
# 为 SFS Turbo 文件系统提供自动备份策略，保护 Jenkins 状态数据。
# ============================================================================

# --- CBR 备份策略 ---

resource "huaweicloud_cbr_policy" "jenkins" {
  name = "${local.name_prefix}-backup-policy"
  type = "backup"

  backup_cycle {
    interval        = 1
    execution_times = ["02:00"]
  }

  enabled = true
}

# --- CBR 备份库 ---

resource "huaweicloud_cbr_vault" "jenkins" {
  name            = "${local.name_prefix}-vault"
  type            = "turbo"
  size            = var.sfs_size_gb
  protection_type = "backup"
  policy_id       = huaweicloud_cbr_policy.jenkins.id

  tags = local.common_tags
}
