# CCE 集群公网端点 EIP
resource "huaweicloud_vpc_eip" "cce_public" {
  publicip {
    type = "5_bgp"
  }
  bandwidth {
    name        = "${local.name_prefix}-cce-bandwidth"
    size        = 5
    share_type  = "PER"
    charge_mode = "traffic"
  }
  tags = local.common_tags
}
