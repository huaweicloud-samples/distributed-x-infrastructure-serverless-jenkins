# ============================================================================
# CCE 集群（云容器引擎）
# ============================================================================
# 在 CCE 托管 Kubernetes 集群上运行 Jenkins 控制器和代理。
# 控制面免运维，节点池支持自动伸缩。
# ============================================================================

# --- CCE 集群 ---

resource "huaweicloud_cce_cluster" "jenkins" {
  name                   = "${local.name_prefix}-cluster"
  flavor_id              = var.cce_cluster_flavor
  vpc_id                 = local.vpc_id
  subnet_id              = local.subnet_id
  container_network_type = "vpc-router"
  security_group_id      = huaweicloud_networking_secgroup.cce.id
  eip                   = huaweicloud_vpc_eip.cce_public.address

  tags = local.common_tags
}

# --- 控制器节点池（运行 Jenkins 控制器）---

resource "huaweicloud_cce_node_pool" "controller" {
  cluster_id         = huaweicloud_cce_cluster.jenkins.id
  name               = "${local.name_prefix}-controller-pool"
  flavor_id          = var.cce_controller_node_flavor
  initial_node_count = var.cce_controller_node_count
  os                 = "Huawei Cloud EulerOS 2.0"
  subnet_id          = local.subnet_id
  availability_zone  = var.availability_zone
  key_pair           = "cce-fastapi-starter-keypair"

  root_volume {
    size       = 50
    volumetype = "SSD"
  }

  data_volumes {
    size       = 100
    volumetype = "SSD"
  }

  tags = local.common_tags
}

# --- 代理节点池（运行 Jenkins 构建代理，自动伸缩）---

resource "huaweicloud_cce_node_pool" "agent" {
  cluster_id         = huaweicloud_cce_cluster.jenkins.id
  name               = "${local.name_prefix}-agent-pool"
  flavor_id          = var.cce_agent_node_flavor
  initial_node_count = var.cce_agent_min_count
  os                 = "Huawei Cloud EulerOS 2.0"
  subnet_id          = local.subnet_id
  availability_zone  = var.availability_zone
  key_pair           = "cce-fastapi-starter-keypair"

  min_node_count           = var.cce_agent_min_count
  max_node_count           = var.cce_agent_max_count
  scale_down_cooldown_time = 300

  root_volume {
    size       = 50
    volumetype = "SSD"
  }

  data_volumes {
    size       = 100
    volumetype = "SSD"
  }

  tags = local.common_tags
}
