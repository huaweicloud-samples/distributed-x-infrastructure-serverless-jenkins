# 部署指南

本指南详细说明如何在华为云上部署 Jenkins CI/CD 平台。整个部署分为两个阶段：基础设施部署（Terraform）和 Jenkins 应用部署（Kubernetes Manifest）。

## 前置条件

### 1. 华为云服务开通

确保已开通以下服务：

| 服务 | 用途 |
|------|------|
| CCE（云容器引擎） | 托管 Kubernetes 集群 |
| SFS Turbo（弹性文件服务） | Jenkins 持久化存储 |
| ELB（弹性负载均衡） | Jenkins Web UI 公网入口 |
| SWR（容器镜像仓库） | Jenkins 控制器镜像存储 |
| CBR（云备份） | 文件系统自动备份 |
| KMS（密钥管理服务） | 加密密钥管理 |
| VPC（虚拟私有云） | 网络隔离 |
| DNS（云解析服务） | 自定义域名解析（可选） |

### 2. 工具安装

| 工具 | 版本要求 | 说明 |
|------|---------|------|
| Terraform | >= 1.5 | 基础设施部署 |
| kubectl | >= 1.28 | Kubernetes 命令行工具 |
| Docker | 任意版本 | 构建 Jenkins 控制器镜像 |
| hcloud（KooCLI） | 最新版 | 华为云命令行工具，用于获取集群认证 |

### 3. 凭证准备

在华为云「我的凭证」页面获取 Access Key 和 Secret Key，并通过环境变量设置：

```bash
export HW_ACCESS_KEY="<your-access-key>"
export HW_SECRET_KEY="<your-secret-key>"
```

### 4. SSH 密钥对

在华为云控制台预先创建 SSH 密钥对，用于 CCE 节点登录。默认密钥对名称为 `jenkins-keypair`，可通过 `ssh_key_pair` 变量修改。

### 5. 区域选择

默认使用 cn-north-4（北京四），可通过 `region` 变量修改。确保所选区域支持上述所有服务。

## 第一阶段：构建并推送 Jenkins 镜像

### 步骤 1：构建镜像

```bash
cd scripts
chmod +x build.sh
./build.sh cn-north-4 jenkins-org lts-jdk17
```

参数说明：
- `cn-north-4`：区域
- `jenkins-org`：SWR 组织名称
- `lts-jdk17`：镜像标签

预期输出：

```
=== 构建 Jenkins 控制器镜像 ===
[+] Building 45.2s
 => => writing image sha256:abcdef...
=== 登录 SWR ===
Login Succeeded
=== 打标签并推送 ===
Pushed: swr.cn-north-4.myhuaweicloud.com/jenkins-org/jenkins-controller:lts-jdk17
=== 完成 ===
```

> 如果无法构建自定义镜像，可直接使用官方 Jenkins 镜像 `jenkins/jenkins:lts-jdk17`，在第二阶段部署时替换镜像地址即可。

## 第二阶段：部署基础设施

### 步骤 2：初始化 Terraform

```bash
cd infra
terraform init
```

预期输出：

```
Initializing the backend...
Initializing provider plugins...
- Reusing previously downloaded huaweicloud/huaweicloud (v1.70.0)
Terraform has been successfully initialized!
```

### 步骤 3：查看部署计划

```bash
terraform plan -var="jenkins_admin_password=YourSecurePassword"
```

查看将创建的资源列表，确认无误后进入下一步。

### 步骤 4：执行部署

```bash
terraform apply -var="jenkins_admin_password=YourSecurePassword"
```

部署过程中会创建以下资源：

| 资源 | 数量 | 说明 |
|------|------|------|
| VPC + 子网 | 各 1 | 网络基础 |
| 安全组 | 3 | ELB / CCE / SFS |
| CCE 集群 | 1 | 托管 Kubernetes 集群 |
| CCE 节点池 | 2 | 控制器节点池 + 代理节点池 |
| ELB v3 | 1 | 公网负载均衡（含监听器、后端池、健康检查） |
| EIP | 2 | CCE 公网端点 + ELB 公网 IP |
| SFS Turbo | 1 | Jenkins 持久化存储 |
| SWR | 1 | 容器镜像仓库（组织 + 仓库） |
| KMS | 1 | 加密密钥 |
| CBR | 1 | 备份保险库 + 备份策略 |
| DNS | 1 | 域名记录（可选） |

预期输出：

```
Apply complete! Resources: 25 added, 0 changed, 0 destroyed.

Outputs:
cce_cluster_id = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
cce_cluster_name = "sjenkins-cluster"
elb_public_ip = "xxx.xxx.xxx.xxx"
jenkins_url = "http://xxx.xxx.xxx.xxx"
sfs_mount_address = "xxx.xxx.xxx.xxx:/"
swr_repository = "jenkins-org/jenkins-controller"
```

### 步骤 5：配置 K8s 认证

部署完成后，获取 CCE 集群的 Kubernetes 认证信息：

```bash
# 获取集群 ID
CLUSTER_ID=$(terraform output -raw cce_cluster_id)

# 使用 hcloud 获取认证
hcloud CCE CreateKubernetesClusterCert --cluster_id=${CLUSTER_ID} --region=cn-north-4 --duration=30 > kubeconfig.json

# 配置 kubectl
# 将 kubeconfig.json 中的 server 替换为公网端点
# 公网端点可通过 hcloud CCE ShowCluster --cluster_id=${CLUSTER_ID} 获取
```

## 第三阶段：部署 Jenkins 应用

### 步骤 6：创建 Kubernetes 资源

```bash
# 创建 Namespace
kubectl create namespace jenkins

# 创建 Jenkins 管理员密码 Secret
kubectl create secret generic jenkins-admin-password \
  --namespace=jenkins \
  --from-literal=password=YourSecurePassword

# 部署 Jenkins 控制器
kubectl apply -f infra/k8s_manifests/deployment.yaml -n jenkins

# 创建 Service
kubectl apply -f infra/k8s_manifests/service.yaml -n jenkins
```

### 步骤 7：配置 ELB 后端

将 CCE 节点添加为 ELB 后端成员，使外部流量能转发到 Jenkins：

```bash
# 获取 CCE 节点 IP
NODE_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}')

# 获取 NodePort
NODE_PORT=$(kubectl get svc jenkins-service -n jenkins -o jsonpath='{.spec.ports[?(@.name=="http")].nodePort}')

# 获取 ELB 后端池 ID
POOL_ID=$(terraform output -raw elb_pool_id)

# 获取子网 ID
SUBNET_ID=$(terraform output -raw subnet_neutron_id)

# 添加后端成员
hcloud ELB CreateMember \
  --pool_id=${POOL_ID} \
  --region=cn-north-4 \
  --member.address=${NODE_IP} \
  --member.protocol_port=${NODE_PORT} \
  --member.subnet_cidr_id=${SUBNET_ID}
```

### 步骤 8：处理节点 Taint

CCE 节点可能带有 `node.kubernetes.io/route-unreachable` taint，导致 Pod 无法调度。如果 Pod 处于 Pending 状态，需要在 Deployment 中添加 toleration：

```yaml
spec:
  template:
    spec:
      tolerations:
        - key: node.kubernetes.io/route-unreachable
          effect: NoSchedule
          operator: Exists
```

## 第四阶段：验证部署

### 步骤 9：验证 Jenkins Pod 状态

```bash
kubectl get pods -n jenkins
```

预期输出：

```
NAME                                  READY   STATUS    RESTARTS   AGE
jenkins-controller-xxxx-xxxx-xxxx     1/1     Running   0          2m
```

### 步骤 10：验证 Jenkins Web UI

```bash
# 获取 Jenkins 访问地址
terraform output jenkins_url

# 在浏览器中打开该地址，应看到 Jenkins 登录页面
```

### 步骤 11：获取初始管理员密码

首次访问 Jenkins 时需要管理员密码进行解锁：

```bash
# 从 Pod 日志获取初始密码
kubectl logs jenkins-controller-xxxx-xxxx-xxxx -n jenkins | grep "password to proceed" -A 2

# 或从 Pod 内文件获取
kubectl exec jenkins-controller-xxxx-xxxx-xxxx -n jenkins -- cat /var/jenkins_home/secrets/initialAdminPassword
```

### 步骤 12：完成 Jenkins 初始化

1. 在浏览器中打开 Jenkins URL
2. 输入初始管理员密码
3. 选择安装推荐插件或跳过插件安装
4. 创建管理员用户
5. 确认 Jenkins URL 配置
6. 开始使用 Jenkins

## 变量配置

### 常用变量

| 变量 | 说明 | 默认值 |
|------|------|--------|
| `region` | 华为云区域 | cn-north-4 |
| `name_prefix` | 资源命名前缀 | sjenkins |
| `vpc_id` | 已有 VPC ID（留空自动创建） | "" |
| `subnet_id` | 已有子网 ID（留空自动创建） | "" |
| `vpc_cidr` | 新建 VPC 的 CIDR | 10.0.0.0/16 |
| `subnet_cidr` | 新建子网的 CIDR | 10.0.1.0/24 |
| `cce_cluster_flavor` | CCE 集群规格 | cce.s1.small |
| `cce_controller_node_flavor` | 控制器节点规格 | s6.large.2 |
| `cce_agent_node_flavor` | 代理节点规格 | s6.large.2 |
| `cce_agent_min_count` | 代理节点最小数 | 0 |
| `cce_agent_max_count` | 代理节点最大数 | 5 |
| `sfs_size_gb` | SFS 容量（GB） | 500 |
| `jenkins_admin_password` | Jenkins 管理员密码 | ChangeMe123! |
| `ssh_key_pair` | CCE 节点 SSH 密钥对名称 | jenkins-keypair |
| `enable_elb_eip` | 是否为 ELB 绑定 EIP | true |
| `dns_zone_id` | DNS Zone ID（留空不创建） | "" |
| `dns_domain_name` | Jenkins 访问域名 | jenkins.example.com |
| `cbr_backup_retention_days` | 备份保留天数 | 30 |

### 使用已有 VPC

```bash
terraform apply \
  -var="vpc_id=your-vpc-id" \
  -var="subnet_id=your-subnet-id" \
  -var="jenkins_admin_password=YourSecurePassword"
```

### 配置自定义域名

```bash
terraform apply \
  -var="dns_zone_id=your-zone-id" \
  -var="dns_domain_name=jenkins.yourdomain.com" \
  -var="jenkins_admin_password=YourSecurePassword"
```

## 故障排除

### Pod 处于 Pending 状态

**原因**：CCE 节点带有 taint，Pod 无法调度。

**解决**：在 Deployment 中添加 toleration：

```bash
kubectl edit deployment jenkins-controller -n jenkins
```

在 `spec.template.spec` 下添加：

```yaml
tolerations:
  - key: node.kubernetes.io/route-unreachable
    effect: NoSchedule
    operator: Exists
```

### Jenkins 离线提示

**原因**：CCE 节点无法访问外网，Jenkins 无法下载插件。

**解决**：在初始化向导中选择「跳过插件安装」，后续可通过手动上传 `.hpi` 文件安装插件。

### ELB 健康检查异常

**原因**：ELB 后端成员未添加或 NodePort 不正确。

**解决**：

```bash
# 检查后端成员状态
hcloud ELB ListMembers --pool_id=${POOL_ID} --region=cn-north-4

# 检查 NodePort
kubectl get svc jenkins-service -n jenkins
```

### CCE 集群创建超时

**原因**：集群规格或节点规格在所选区域不可用。

**解决**：确认规格可用后重试，或更换规格：

```bash
terraform apply \
  -var="cce_cluster_flavor=cce.s1.medium" \
  -var="cce_controller_node_flavor=s6.medium.2" \
  -var="jenkins_admin_password=YourSecurePassword"
```

## 清理资源

### 删除 Jenkins 应用

```bash
kubectl delete deployment jenkins-controller -n jenkins
kubectl delete service jenkins-service -n jenkins
kubectl delete namespace jenkins
```

### 删除 ELB 后端成员

```bash
hcloud ELB DeleteMember \
  --pool_id=${POOL_ID} \
  --member_id=${MEMBER_ID} \
  --region=cn-north-4
```

### 销毁基础设施

```bash
cd infra
terraform destroy -var="jenkins_admin_password=YourSecurePassword"
```

执行后所有云资源将被释放，避免残留。
