# ============================================================================
# Jenkins Configuration-as-Code (JCasC)
# ============================================================================
# 声明式配置 Jenkins，替代手动 Web UI 配置。
# Kubernetes 插件配置 Jenkins 代理在 CCE 集群中动态创建 Pod。
# ============================================================================

jenkins:
  systemMessage: "Jenkins on Huawei Cloud CCE"
  numExecutors: 0
  mode: EXCLUSIVE

  securityRealm:
    local:
      allowsSignup: false
      users:
        - id: "admin"
          password: "${JENKINS_ADMIN_PASSWORD}"

  authorizationStrategy:
    globalMatrix:
      permissions:
        - "Overall/Administer:admin"
        - "Overall/Read:authenticated"

  # Kubernetes 云配置 — 在 CCE 集群中动态调度 Jenkins 代理
  clouds:
    - kubernetes:
        name: "cce-kubernetes"
        serverUrl: "https://kubernetes.default.svc"
        namespace: "${agent_namespace}"
        jenkinsUrl: "http://jenkins-ui.jenkins.svc.cluster.local:80"
        jenkinsTunnel: "jenkins-agent.jenkins.svc.cluster.local:50000"
        connectTimeout: 5
        readTimeout: 15
        maxRequestsPerHost: 32
        retentionTimeout: 5
        waitForPodSec: 600

        # 代理 Pod 模板
        templates:
          - name: "kubernetes-agent"
            namespace: "${agent_namespace}"
            label: "kubernetes-agent"
            nodeUsageMode: NORMAL

            # 容器定义
            containers:
              - name: "jnlp"
                image: "jenkins/inbound-agent:latest"
                args: "^${computer.jnlpmac} ^${computer.name}"
                resourceRequestCpu: "${jenkins_agent_cpu}"
                resourceRequestMemory: "${jenkins_agent_memory}"
                resourceLimitCpu: "${jenkins_agent_cpu}"
                resourceLimitMemory: "${jenkins_agent_memory}"

            # 工作空间卷
            workspaceVolume:
              emptyDirWorkspaceVolume:
                memory: false

            # Pod 退出后自动清理
            idleMinutes: 10
            activeDeadlineSeconds: 1200
            showRawYaml: false

# 凭据
credentials:
  system:
    systemCredentialsProvider:
      credentialConfigurations:
        - basicSSHUserPrivateKey:
            scope: SYSTEM
            id: "jenkins-agent-ssh"
            username: "jenkins"
            description: "SSH key for Jenkins agents"
            privateKeySource:
              directEntry:
                privateKey: "${JENKINS_AGENT_SSH_KEY:-}"

# 工具
tool:
  git:
    installations:
      - name: "Default"
        home: "git"
