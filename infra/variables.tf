# ============================================================================
# 变量定义
# ============================================================================

variable "region" {
  description = "华为云区域"
  type        = string
  default     = "cn-north-4"
}

variable "name_prefix" {
  description = "资源命名前缀"
  type        = string
  default     = "sjenkins"
  validation {
    condition     = length(var.name_prefix) >= 3 && length(var.name_prefix) <= 20
    error_message = "name_prefix 长度须在 3~20 字符之间。"
  }
}

# --- 网络 ---

variable "vpc_id" {
  description = "已有 VPC ID。留空则自动创建新 VPC。"
  type        = string
  default     = ""
}

variable "vpc_cidr" {
  description = "新建 VPC 的 CIDR（仅在 vpc_id 为空时生效）"
  type        = string
  default     = "10.0.0.0/16"
}

variable "subnet_id" {
  description = "已有子网 ID。留空则自动创建新子网。"
  type        = string
  default     = ""
}

variable "subnet_cidr" {
  description = "新建子网的 CIDR（仅在 subnet_id 为空时生效）"
  type        = string
  default     = "10.0.1.0/24"
}

variable "availability_zone" {
  description = "可用区"
  type        = string
  default     = "cn-north-4a"
}

# --- CCE 集群 ---

variable "cce_cluster_flavor" {
  description = "CCE 集群规格"
  type        = string
  default     = "cce.s1.small"
}

variable "cce_controller_node_flavor" {
  description = "Jenkins 控制器节点池规格"
  type        = string
  default     = "s6.large.2"
}

variable "cce_controller_node_count" {
  description = "Jenkins 控制器节点池初始节点数"
  type        = number
  default     = 1
}

variable "cce_agent_node_flavor" {
  description = "Jenkins 代理节点池规格"
  type        = string
  default     = "s6.large.2"
}

variable "cce_agent_min_count" {
  description = "Jenkins 代理节点池最小节点数"
  type        = number
  default     = 0
}

variable "cce_agent_max_count" {
  description = "Jenkins 代理节点池最大节点数"
  type        = number
  default     = 5
}

# --- SWR 容器镜像 ---

variable "swr_organization" {
  description = "SWR 组织名称"
  type        = string
  default     = "jenkins-org"
}

variable "jenkins_image_tag" {
  description = "Jenkins 控制器镜像标签"
  type        = string
  default     = "lts-jdk17"
}

# --- Jenkins 配置 ---

variable "jenkins_admin_password" {
  description = "Jenkins 管理员初始密码"
  type        = string
  sensitive   = true
  default     = "ChangeMe123!"
}

variable "jenkins_controller_cpu" {
  description = "Jenkins 控制器 Pod CPU 请求"
  type        = string
  default     = "1000m"
}

variable "jenkins_controller_memory" {
  description = "Jenkins 控制器 Pod 内存请求"
  type        = string
  default     = "2Gi"
}

variable "jenkins_agent_cpu" {
  description = "Jenkins 代理 Pod CPU 请求"
  type        = string
  default     = "500m"
}

variable "jenkins_agent_memory" {
  description = "Jenkins 代理 Pod 内存请求"
  type        = string
  default     = "1Gi"
}

# --- SFS 文件存储 ---

variable "sfs_share_type" {
  description = "SFS Turbo 文件系统规格（STANDARD / PERFORMANCE）"
  type        = string
  default     = "STANDARD"
}

variable "sfs_size_gb" {
  description = "SFS Turbo 文件系统容量（GB）"
  type        = number
  default     = 500
}

# --- ELB 负载均衡 ---

variable "elb_listener_port" {
  description = "ELB 监听端口"
  type        = number
  default     = 80
}

variable "enable_elb_eip" {
  description = "是否为 ELB 绑定弹性公网 IP"
  type        = bool
  default     = true
}

# --- DNS 域名（可选）---

variable "dns_zone_id" {
  description = "DNS 公网 Zone ID。留空则不创建 DNS 记录。"
  type        = string
  default     = ""
}

variable "dns_domain_name" {
  description = "Jenkins 访问域名（仅在 dns_zone_id 非空时生效）"
  type        = string
  default     = "jenkins.example.com"
}

# --- CBR 备份 ---

variable "cbr_backup_retention_days" {
  description = "CBR 备份保留天数"
  type        = number
  default     = 30
}

variable "cbr_backup_frequency" {
  description = "CBR 备份频率（cron 表达式，默认每天凌晨 2 点）"
  type        = string
  default     = "0 2 * * *"
}

# --- SSH 密钥对 ---

variable "ssh_key_pair" {
  description = "CCE 节点 SSH 密钥对名称（需在华为云控制台预先创建）"
  type        = string
  default     = "jenkins-keypair"
}
