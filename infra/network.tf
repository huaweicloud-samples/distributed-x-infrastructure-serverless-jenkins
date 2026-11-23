# ============================================================================
# 网络基础设施（VPC、子网、安全组）
# ============================================================================

# --- VPC ---

data "huaweicloud_vpc" "existing" {
  count = var.vpc_id != "" ? 1 : 0
  id    = var.vpc_id
}

resource "huaweicloud_vpc" "new" {
  count       = var.vpc_id == "" ? 1 : 0
  name        = "${local.name_prefix}-vpc"
  cidr        = var.vpc_cidr
  description = "VPC for Jenkins on CCE"
  tags        = local.common_tags
}

locals {
  vpc_id = var.vpc_id != "" ? data.huaweicloud_vpc.existing[0].id : huaweicloud_vpc.new[0].id
}

# --- 子网 ---

data "huaweicloud_vpc_subnet" "existing" {
  count = var.subnet_id != "" ? 1 : 0
  id    = var.subnet_id
}

resource "huaweicloud_vpc_subnet" "new" {
  count       = var.subnet_id == "" ? 1 : 0
  name        = "${local.name_prefix}-subnet"
  vpc_id      = local.vpc_id
  cidr        = var.subnet_cidr
  gateway_ip  = "10.0.1.1"
  description = "Subnet for Jenkins on CCE"
  tags        = local.common_tags
}

locals {
  subnet_id      = var.subnet_id != "" ? data.huaweicloud_vpc_subnet.existing[0].id : huaweicloud_vpc_subnet.new[0].id
  neutron_subnet = var.subnet_id != "" ? data.huaweicloud_vpc_subnet.existing[0].id : huaweicloud_vpc_subnet.new[0].subnet_id
}

# --- 安全组：ELB 公网入口 ---

resource "huaweicloud_networking_secgroup" "elb" {
  name        = "${local.name_prefix}-sg-elb"
  description = "Security group for ELB public access"
  tags        = local.common_tags
}

resource "huaweicloud_networking_secgroup_rule" "elb_http" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 80
  port_range_max    = 80
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = huaweicloud_networking_secgroup.elb.id
}

# --- 安全组：CCE 内部通信 ---

resource "huaweicloud_networking_secgroup" "cce" {
  name        = "${local.name_prefix}-sg-cce"
  description = "Security group for CCE internal traffic"
  tags        = local.common_tags
}

resource "huaweicloud_networking_secgroup_rule" "cce_internal" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 1
  port_range_max    = 65535
  remote_ip_prefix  = var.vpc_cidr
  security_group_id = huaweicloud_networking_secgroup.cce.id
}

# --- 安全组：SFS Turbo NFS 访问 ---

resource "huaweicloud_networking_secgroup" "sfs" {
  name        = "${local.name_prefix}-sg-sfs"
  description = "Security group for SFS Turbo NFS access"
  tags        = local.common_tags
}

resource "huaweicloud_networking_secgroup_rule" "sfs_nfs" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 2049
  port_range_max    = 2049
  remote_ip_prefix  = var.vpc_cidr
  security_group_id = huaweicloud_networking_secgroup.sfs.id
}

resource "huaweicloud_networking_secgroup_rule" "sfs_nfs_udp" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "udp"
  port_range_min    = 2049
  port_range_max    = 2049
  remote_ip_prefix  = var.vpc_cidr
  security_group_id = huaweicloud_networking_secgroup.sfs.id
}
