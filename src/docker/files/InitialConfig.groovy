// ============================================================================
// Jenkins 初始化脚本
// ============================================================================
// 在 Jenkins 启动时执行，设置管理员密码并禁用安装向导。
// ============================================================================

import jenkins.model.*
import hudson.security.*
import org.jenkinsci.plugins.scriptsecurity.scripts.*

def instance = Jenkins.getInstance()

// 设置本地安全域
def realm = new hudson.security.HudsonPrivateSecurityRealm(false)
instance.setSecurityRealm(realm)

// 从环境变量获取管理员密码
def adminPassword = System.getenv('JENKINS_ADMIN_PASSWORD') ?: 'ChangeMe123!'

// 创建或更新 admin 用户
def user = realm.createAccount('admin', adminPassword)
user.save()

// 设置全权限策略
def strategy = new FullControlOnceInitializedAuthorizationStrategy()
instance.setAuthorizationStrategy(strategy)

// 保存配置
instance.save()

println "Jenkins initial configuration completed."
