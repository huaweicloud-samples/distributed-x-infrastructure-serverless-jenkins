# ============================================================================
# ELB 负载均衡（使用 v3 ELB API）
# ============================================================================
# 为 Jenkins 控制器提供外部访问入口，通过 EIP 暴露 HTTP 服务。
# ============================================================================

# --- 弹性公网 IP ---

resource "huaweicloud_vpc_eip" "jenkins" {
  name = "${local.name_prefix}-eip"

  publicip {
    type = "5_bgp"
  }

  bandwidth {
    name        = "${local.name_prefix}-bandwidth"
    size        = 5
    share_type  = "PER"
    charge_mode = "traffic"
  }

  tags = local.common_tags
}

# --- 负载均衡器 ---

resource "huaweicloud_elb_loadbalancer" "jenkins" {
  name              = "${local.name_prefix}-lb"
  vpc_id            = local.vpc_id
  ipv4_subnet_id  = local.neutron_subnet
  availability_zone = [var.availability_zone]
  ipv4_eip_id       = huaweicloud_vpc_eip.jenkins.id

  tags = local.common_tags

  lifecycle {
    ignore_changes = [l4_flavor_id, l7_flavor_id]
  }
}

# --- 监听器 ---

resource "huaweicloud_elb_listener" "jenkins" {
  name             = "${local.name_prefix}-listener"
  protocol         = "TCP"
  protocol_port    = var.elb_listener_port
  loadbalancer_id  = huaweicloud_elb_loadbalancer.jenkins.id

  tags = local.common_tags
}

# --- 后端服务器组 ---

resource "huaweicloud_elb_pool" "jenkins" {
  name        = "${local.name_prefix}-pool"
  protocol    = "TCP"
  lb_method   = "ROUND_ROBIN"
  listener_id = huaweicloud_elb_listener.jenkins.id
}

# --- 健康检查 ---

resource "huaweicloud_elb_monitor" "jenkins" {
  pool_id     = huaweicloud_elb_pool.jenkins.id
  protocol    = "TCP"
  interval    = 10
  timeout     = 5
  max_retries = 3
}
