# ============================================================================
# KMS 密钥管理
# ============================================================================
# 为 SFS Turbo 文件存储和 CBR 备份提供加密密钥。
# ============================================================================

resource "huaweicloud_kms_key" "jenkins" {
  key_alias    = "${local.name_prefix}-kms-key-v2"
  pending_days = 7
  key_description = "Jenkins KMS key"
  region       = var.region
}
