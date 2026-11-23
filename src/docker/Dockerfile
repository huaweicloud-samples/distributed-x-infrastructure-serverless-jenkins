# ============================================================================
# Jenkins Controller Docker Image
# ============================================================================
# 基于 Jenkins LTS + JDK 17，预装 Kubernetes 插件，
# 通过 JCasC（Configuration-as-Code）实现声明式配置。
# ============================================================================

FROM jenkins/jenkins:lts-jdk17

# 切换为 root 安装插件
USER root

# 安装基础工具
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    gettext-base \
    && rm -rf /var/lib/apt/lists/*

# 复制插件列表并安装
COPY files/plugins.txt /usr/share/jenkins/ref/plugins.txt
RUN jenkins-plugin-cli --plugin-file /usr/share/jenkins/ref/plugins.txt

# 复制 JCasC 配置
COPY files/jenkins.yaml.tpl /usr/share/jenkins/ref/jenkins.yaml.tpl

# 复制初始化 Groovy 脚本
COPY files/InitialConfig.groovy /usr/share/jenkins/ref/init.groovy.d/InitialConfig.groovy

# 设置环境变量
ENV CASC_JENKINS_CONFIG=/var/jenkins_config/jenkins.yaml
ENV JAVA_OPTS="-Djenkins.install.runSetupWizard=false"

# 切换回 jenkins 用户
USER jenkins
