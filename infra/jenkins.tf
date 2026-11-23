# ============================================================================
# Jenkins Kubernetes 资源部署
# ============================================================================
# CCE 集群创建后，通过 kubectl 部署 Jenkins K8s 资源：
# - Namespace
# - Secret（管理员密码）
# - PV/PVC（SFS NFS 挂载）
# - ConfigMap（JCasC 配置）
# - Deployment（Jenkins 控制器）
# - Service（Web UI + Agent JNLP）
# ============================================================================

# --- 生成 K8s 清单文件 ---

resource "null_resource" "jenkins_k8s_manifests" {
  triggers = {
    cluster_id   = huaweicloud_cce_cluster.jenkins.id
    sfs_location = huaweicloud_sfs_turbo.jenkins_home.export_location
    swr_image    = "${huaweicloud_swr_organization.jenkins.name}/${huaweicloud_swr_repository.controller.name}:${var.jenkins_image_tag}"
  }

  provisioner "local-exec" {
    command = <<-EOT
      mkdir -p ${path.module}/k8s_manifests

      cat > ${path.module}/k8s_manifests/namespace.yaml << 'NS'
apiVersion: v1
kind: Namespace
metadata:
  name: jenkins
  labels:
    app: jenkins
NS

      cat > ${path.module}/k8s_manifests/secret.yaml << 'SEC'
apiVersion: v1
kind: Secret
metadata:
  name: jenkins-admin-password
  namespace: jenkins
type: Opaque
stringData:
  jenkins-admin-password: "${var.jenkins_admin_password}"
SEC

      cat > ${path.module}/k8s_manifests/pv.yaml << PV
apiVersion: v1
kind: PersistentVolume
metadata:
  name: jenkins-home-pv
spec:
  capacity:
    storage: ${var.sfs_size_gb}Gi
  accessModes:
    - ReadWriteMany
  nfs:
    server: ${huaweicloud_sfs_turbo.jenkins_home.export_location}
    path: "/"
  persistentVolumeReclaimPolicy: Retain
  storageClassName: nfs
PV

      cat > ${path.module}/k8s_manifests/pvc.yaml << 'PVC'
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: jenkins-home-pvc
  namespace: jenkins
spec:
  accessModes:
    - ReadWriteMany
  resources:
    requests:
      storage: ${var.sfs_size_gb}Gi
  volumeName: jenkins-home-pv
  storageClassName: nfs
PVC

      cat > ${path.module}/k8s_manifests/configmap.yaml << 'CM'
apiVersion: v1
kind: ConfigMap
metadata:
  name: jenkins-casc-config
  namespace: jenkins
data:
  jenkins.yaml: |
    jenkins:
      systemMessage: "Jenkins on Huawei Cloud CCE"
      numExecutors: 0
      mode: EXCLUSIVE
      securityRealm:
        local:
          allowsSignup: false
          users:
            - id: "admin"
              password: "${var.jenkins_admin_password}"
      authorizationStrategy:
        globalMatrix:
          permissions:
            - "Overall/Administer:admin"
            - "Overall/Read:authenticated"
      clouds:
        - kubernetes:
            name: "cce-kubernetes"
            serverUrl: "https://kubernetes.default.svc"
            namespace: "jenkins"
            jenkinsUrl: "http://jenkins-ui.jenkins.svc.cluster.local:80"
            jenkinsTunnel: "jenkins-agent.jenkins.svc.cluster.local:50000"
            connectTimeout: 5
            readTimeout: 15
            maxRequestsPerHost: 32
            retentionTimeout: 5
            waitForPodSec: 600
            templates:
              - name: "kubernetes-agent"
                namespace: "jenkins"
                label: "kubernetes-agent"
                nodeUsageMode: NORMAL
                containers:
                  - name: "jnlp"
                    image: "jenkins/inbound-agent:latest"
                    args: "^$${computer.jnlpmac} ^$${computer.name}"
                    resourceRequestCpu: "${var.jenkins_agent_cpu}"
                    resourceRequestMemory: "${var.jenkins_agent_memory}"
                    resourceLimitCpu: "${var.jenkins_agent_cpu}"
                    resourceLimitMemory: "${var.jenkins_agent_memory}"
                workspaceVolume:
                  emptyDirWorkspaceVolume:
                    memory: false
                idleMinutes: 10
                activeDeadlineSeconds: 1200
                showRawYaml: false
  plugins.txt: |
$(sed 's/^/    /' ${path.module}/../src/docker/files/plugins.txt 2>/dev/null || echo "    jenkins-kubernetes-plugin")
CM

      cat > ${path.module}/k8s_manifests/deployment.yaml << DEP
apiVersion: apps/v1
kind: Deployment
metadata:
  name: jenkins-controller
  namespace: jenkins
  labels:
    app: jenkins
    role: controller
spec:
  replicas: 1
  selector:
    matchLabels:
      app: jenkins
      role: controller
  template:
    metadata:
      labels:
        app: jenkins
        role: controller
    spec:
      containers:
        - name: jenkins
          image: ${huaweicloud_swr_organization.jenkins.name}/${huaweicloud_swr_repository.controller.name}:${var.jenkins_image_tag}
          ports:
            - containerPort: 8080
              name: http
            - containerPort: 50000
              name: agent
          env:
            - name: JENKINS_ADMIN_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: jenkins-admin-password
                  key: jenkins-admin-password
            - name: CASC_JENKINS_CONFIG
              value: /var/jenkins_config/jenkins.yaml
          volumeMounts:
            - name: jenkins-home
              mountPath: /var/jenkins_home
            - name: jenkins-casc-config
              mountPath: /var/jenkins_config
              readOnly: true
          resources:
            requests:
              cpu: ${var.jenkins_controller_cpu}
              memory: ${var.jenkins_controller_memory}
          livenessProbe:
            httpGet:
              path: /login
              port: 8080
            initialDelaySeconds: 120
            periodSeconds: 30
            timeoutSeconds: 10
            failureThreshold: 5
          readinessProbe:
            httpGet:
              path: /login
              port: 8080
            initialDelaySeconds: 60
            periodSeconds: 10
            timeoutSeconds: 5
            failureThreshold: 3
      volumes:
        - name: jenkins-home
          persistentVolumeClaim:
            claimName: jenkins-home-pvc
        - name: jenkins-casc-config
          configMap:
            name: jenkins-casc-config
DEP

      cat > ${path.module}/k8s_manifests/service.yaml << 'SVC'
apiVersion: v1
kind: Service
metadata:
  name: jenkins-ui
  namespace: jenkins
  annotations:
    kubernetes.io/elb.autocreate: "false"
    kubernetes.io/elb.id: "${huaweicloud_elb_loadbalancer.jenkins.id}"
spec:
  type: LoadBalancer
  selector:
    app: jenkins
    role: controller
  ports:
    - name: http
      port: 80
      targetPort: 8080
---
apiVersion: v1
kind: Service
metadata:
  name: jenkins-agent
  namespace: jenkins
spec:
  type: ClusterIP
  selector:
    app: jenkins
    role: controller
  ports:
    - name: agent
      port: 50000
      targetPort: 50000
SVC

      echo "K8s manifests generated successfully in ${path.module}/k8s_manifests/"
    EOT
  }
}

# --- 应用 K8s 清单（需要 kubectl，如果不可用则跳过）---

resource "null_resource" "jenkins_k8s_apply" {
  depends_on = [null_resource.jenkins_k8s_manifests]

  triggers = {
    cluster_id    = huaweicloud_cce_cluster.jenkins.id
    manifest_hash = null_resource.jenkins_k8s_manifests.id
  }

  provisioner "local-exec" {
    command = <<-EOT
      if ! command -v kubectl &> /dev/null; then
        echo "WARNING: kubectl not found. K8s manifests generated but not applied."
        echo "To apply manually: install kubectl, get kubeconfig, then run:"
        echo "  kubectl apply -f ${path.module}/k8s_manifests/"
        exit 0
      fi

      export KUBECONFIG=${path.module}/kubeconfig.yaml
      kubectl --region ${var.region} cce auth --cluster-id ${huaweicloud_cce_cluster.jenkins.id} --kubeconfig $$KUBECONFIG

      kubectl apply -f ${path.module}/k8s_manifests/namespace.yaml
      kubectl apply -f ${path.module}/k8s_manifests/secret.yaml
      kubectl apply -f ${path.module}/k8s_manifests/pv.yaml
      kubectl apply -f ${path.module}/k8s_manifests/pvc.yaml
      kubectl apply -f ${path.module}/k8s_manifests/configmap.yaml
      kubectl apply -f ${path.module}/k8s_manifests/deployment.yaml
      kubectl apply -f ${path.module}/k8s_manifests/service.yaml

      echo "Jenkins K8s resources applied successfully."
    EOT
  }
}
