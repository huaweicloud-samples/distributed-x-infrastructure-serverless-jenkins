# ============================================================================
# 输出
# ============================================================================

output "cce_cluster_id" {
  description = "CCE 集群 ID"
  value       = huaweicloud_cce_cluster.jenkins.id
}

output "cce_cluster_name" {
  description = "CCE 集群名称"
  value       = huaweicloud_cce_cluster.jenkins.name
}

output "swr_repository" {
  description = "SWR 镜像仓库地址"
  value       = "${huaweicloud_swr_organization.jenkins.name}/${huaweicloud_swr_repository.controller.name}"
}

output "sfs_turbo_id" {
  description = "SFS Turbo 文件系统 ID"
  value       = huaweicloud_sfs_turbo.jenkins_home.id
}

output "sfs_mount_address" {
  description = "SFS 挂载地址"
  value       = huaweicloud_sfs_turbo.jenkins_home.export_location
}

output "elb_id" {
  description = "ELB 负载均衡器 ID"
  value       = huaweicloud_elb_loadbalancer.jenkins.id
}

output "elb_public_ip" {
  description = "ELB 公网 IP（若已绑定 EIP）"
  value       = huaweicloud_vpc_eip.jenkins.address
}

output "jenkins_url" {
  description = "Jenkins Web UI 访问地址"
  value = var.dns_zone_id != "" ? "http://${var.dns_domain_name}" : (
    "http://${huaweicloud_vpc_eip.jenkins.address}"
  )
}

output "cbr_vault_id" {
  description = "CBR 备份库 ID"
  value       = huaweicloud_cbr_vault.jenkins.id
}

output "kms_key_id" {
  description = "KMS 密钥 ID"
  value       = huaweicloud_kms_key.jenkins.id
}

output "jenkins_namespace" {
  description = "Jenkins 所在 K8s Namespace"
  value       = "jenkins"
}

output "jenkins_admin_password_secret" {
  description = "Jenkins 管理员密码所在 K8s Secret 名称"
  value       = "jenkins-admin-password"
}
