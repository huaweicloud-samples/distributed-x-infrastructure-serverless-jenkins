# ============================================================================
# DNS 域名解析（可选）
# ============================================================================
# 为 Jenkins Web UI 配置自定义域名。
# 仅在 dns_zone_id 非空时创建。
# ============================================================================

resource "huaweicloud_dns_recordset" "jenkins" {
  count       = var.dns_zone_id != "" ? 1 : 0
  zone_id     = var.dns_zone_id
  name        = var.dns_domain_name
  type        = "CNAME"
  ttl         = 300
  records     = [huaweicloud_elb_loadbalancer.jenkins.id]
}
