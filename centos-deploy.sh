#!/bin/bash

# OpenIM 新增前端服务部署脚本 - CentOS 专用版
# 在现有 OpenIM 系统基础上添加两个新的前端服务

set -e

# 配置变量（请根据实际情况修改）
FRONTEND_SOURCE_DIR="/opt/im-frontend"  # 前端源代码目录
OPENIM_SERVER_DIR="/opt/open-im-server"  # OpenIM 服务器目录

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 检查 CentOS 系统
check_centos() {
    log_info "检查 CentOS 系统..."
    
    if [ ! -f /etc/redhat-release ]; then
        log_error "此脚本仅支持 CentOS/RHEL 系统"
        exit 1
    fi
    
    log_info "检测到 CentOS 系统: $(cat /etc/redhat-release)"
}

# 检查系统要求
check_requirements() {
    log_info "检查系统要求..."
    
    # 检查 Docker
    if ! command -v docker &> /dev/null; then
        log_error "Docker 未安装，请先安装 Docker"
        log_info "安装命令:"
        log_info "sudo yum install -y yum-utils"
        log_info "sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo"
        log_info "sudo yum install -y docker-ce docker-ce-cli containerd.io"
        log_info "sudo systemctl start docker"
        log_info "sudo systemctl enable docker"
        exit 1
    fi
    
    # 检查 Docker 服务状态
    if ! systemctl is-active --quiet docker; then
        log_warning "Docker 服务未运行，尝试启动..."
        sudo systemctl start docker
        if ! systemctl is-active --quiet docker; then
            log_error "Docker 服务启动失败"
            exit 1
        fi
    fi
    
    # 检查 Docker Compose
    if ! docker compose version &> /dev/null; then
        log_error "Docker Compose 未安装，请先安装 Docker Compose"
        log_info "安装命令:"
        log_info "sudo curl -L \"https://github.com/docker/compose/releases/latest/download/docker-compose-\$(uname -s)-\$(uname -m)\" -o /usr/local/bin/docker-compose"
        log_info "sudo chmod +x /usr/local/bin/docker-compose"
        log_info "或者使用新版本: docker compose plugin"
        exit 1
    fi
    
    # 检查目录
    if [ ! -d "$FRONTEND_SOURCE_DIR" ]; then
        log_error "前端源代码目录不存在: $FRONTEND_SOURCE_DIR"
        log_info "请确保前端源代码已上传到服务器"
        exit 1
    fi
    
    if [ ! -d "$OPENIM_SERVER_DIR" ]; then
        log_error "OpenIM 服务器目录不存在: $OPENIM_SERVER_DIR"
        log_info "请确保 OpenIM 服务器目录存在"
        exit 1
    fi
    
    # 检查必需的文件
    if [ ! -f "$OPENIM_SERVER_DIR/docker-compose.yml" ]; then
        log_error "docker-compose.yml 文件不存在"
        exit 1
    fi
    
    if [ ! -f "$OPENIM_SERVER_DIR/Dockerfile.admin-new-front-1" ]; then
        log_error "Dockerfile.admin-new-front-1 文件不存在"
        exit 1
    fi
    
    if [ ! -f "$OPENIM_SERVER_DIR/Dockerfile.admin-new-front-2" ]; then
        log_error "Dockerfile.admin-new-front-2 文件不存在"
        exit 1
    fi
    
    log_success "系统要求检查通过"
}

# 配置防火墙
configure_firewall() {
    log_info "配置防火墙..."
    
    if systemctl is-active --quiet firewalld; then
        log_info "配置防火墙规则..."
        sudo firewall-cmd --permanent --add-port=11003/tcp
        sudo firewall-cmd --permanent --add-port=11004/tcp
        sudo firewall-cmd --reload
        log_success "防火墙配置完成"
    else
        log_warning "防火墙未运行，跳过配置"
    fi
}

# 创建环境变量文件
create_env_file() {
    log_info "创建环境变量文件..."
    
    cat > "$OPENIM_SERVER_DIR/docker-compose.env" << 'EOF'
# OpenIM Docker Compose 环境变量
# 数据目录
DATA_DIR=./data
MONGO_BACKUP_DIR=./backup

# 镜像配置
MONGO_IMAGE=mongo:7.0
REDIS_IMAGE=redis:7.2-alpine
ETCD_IMAGE=quay.io/coreos/etcd:v3.5.10
KAFKA_IMAGE=bitnami/kafka:3.6
MINIO_IMAGE=minio/minio:latest

# 前端服务镜像
OPENIM_WEB_FRONT_IMAGE=openim-web-front:latest
OPENIM_ADMIN_FRONT_IMAGE=openim-admin-front:latest
OPENIM_ADMIN_NEW_FRONT_1_IMAGE=openim-admin-new-front-1:latest
OPENIM_ADMIN_NEW_FRONT_2_IMAGE=openim-admin-new-front-2:latest

# 监控服务镜像
PROMETHEUS_IMAGE=prom/prometheus:latest
ALERTMANAGER_IMAGE=prom/alertmanager:latest
GRAFANA_IMAGE=grafana/grafana:latest
NODE_EXPORTER_IMAGE=prom/node-exporter:latest

# 端口配置
PROMETHEUS_PORT=9090
ALERTMANAGER_PORT=9093
GRAFANA_PORT=3000
EOF
    
    log_success "环境变量文件创建完成"
}

# 构建镜像
build_images() {
    log_info "构建 Docker 镜像..."
    
    # 复制 Dockerfile 到前端源代码目录
    log_info "复制 Dockerfile 到前端源代码目录..."
    cp "$OPENIM_SERVER_DIR/Dockerfile.admin-new-front-1" "$FRONTEND_SOURCE_DIR/"
    cp "$OPENIM_SERVER_DIR/Dockerfile.admin-new-front-2" "$FRONTEND_SOURCE_DIR/"
    cp -r "$OPENIM_SERVER_DIR/config" "$FRONTEND_SOURCE_DIR/"
    
    # 进入前端源代码目录
    cd "$FRONTEND_SOURCE_DIR"
    
    # 构建 front-1 镜像
    log_info "构建 openim-admin-new-front-1 镜像..."
    docker build -f Dockerfile.admin-new-front-1 -t openim-admin-new-front-1:latest .
    log_success "openim-admin-new-front-1 镜像构建完成"
    
    # 构建 front-2 镜像
    log_info "构建 openim-admin-new-front-2 镜像..."
    docker build -f Dockerfile.admin-new-front-2 -t openim-admin-new-front-2:latest .
    log_success "openim-admin-new-front-2 镜像构建完成"
    
    # 清理临时文件
    log_info "清理临时文件..."
    rm -f "$FRONTEND_SOURCE_DIR/Dockerfile.admin-new-front-1"
    rm -f "$FRONTEND_SOURCE_DIR/Dockerfile.admin-new-front-2"
    rm -rf "$FRONTEND_SOURCE_DIR/config"
}

# 检查现有服务
check_existing_services() {
    log_info "检查现有 OpenIM 服务..."
    
    cd "$OPENIM_SERVER_DIR"
    
    # 检查是否有运行中的 OpenIM 服务
    if docker compose ps 2>/dev/null | grep -q "openim"; then
        log_success "发现运行中的 OpenIM 服务"
        log_info "现有服务状态:"
        docker compose ps | grep "openim" || true
    else
        log_warning "未发现运行中的 OpenIM 服务"
        log_info "将仅启动新的前端服务"
    fi
}

# 部署服务
deploy_services() {
    log_info "部署服务..."
    
    # 进入 OpenIM 服务器目录
    cd "$OPENIM_SERVER_DIR"
    
    # 检查现有服务
    check_existing_services
    
    # 启动新服务
    log_info "启动 openim-admin-new-front-1 服务..."
    if docker compose --env-file docker-compose.env up -d openim-admin-new-front-1; then
        log_success "openim-admin-new-front-1 服务已启动 (端口 11003)"
    else
        log_error "openim-admin-new-front-1 服务启动失败"
        return 1
    fi
    
    log_info "启动 openim-admin-new-front-2 服务..."
    if docker compose --env-file docker-compose.env up -d openim-admin-new-front-2; then
        log_success "openim-admin-new-front-2 服务已启动 (端口 11004)"
    else
        log_error "openim-admin-new-front-2 服务启动失败"
        return 1
    fi
}

# 验证部署
verify_deployment() {
    log_info "验证部署..."
    
    # 等待服务启动
    sleep 10
    
    # 检查服务状态
    log_info "服务状态:"
    docker compose --env-file docker-compose.env ps | grep admin-new-front
    
    # 测试服务访问
    log_info "测试服务访问..."
    
    if curl -f http://localhost:11003/ > /dev/null 2>&1; then
        log_success "openim-admin-new-front-1 (端口 11003) 访问正常"
    else
        log_warning "openim-admin-new-front-1 (端口 11003) 访问异常"
    fi
    
    if curl -f http://localhost:11004/ > /dev/null 2>&1; then
        log_success "openim-admin-new-front-2 (端口 11004) 访问正常"
    else
        log_warning "openim-admin-new-front-2 (端口 11004) 访问异常"
    fi
}

# 显示服务信息
show_service_info() {
    log_info "新前端服务信息:"
    echo ""
    echo "服务名称: openim-admin-new-front-1"
    echo "访问地址: http://$(hostname -I | awk '{print $1}'):11003"
    echo "代理服务器: 47.239.126.22"
    echo "API 路径: /api/admin/*, /api/user/*, /api/im/*"
    echo ""
    echo "服务名称: openim-admin-new-front-2"
    echo "访问地址: http://$(hostname -I | awk '{print $1}'):11004"
    echo "代理服务器: 47.83.254.218"
    echo "API 路径: /api/admin/*, /api/user/*, /api/im/*"
    echo ""
    echo "管理命令:"
    echo "  查看状态: docker compose --env-file docker-compose.env ps"
    echo "  查看日志: docker compose --env-file docker-compose.env logs -f openim-admin-new-front-1"
    echo "  重启服务: docker compose --env-file docker-compose.env restart openim-admin-new-front-1"
    echo "  停止服务: docker compose --env-file docker-compose.env stop openim-admin-new-front-1"
}

# 主函数
main() {
    log_info "开始部署 OpenIM 新前端服务到 CentOS 服务器..."
    
    # 检查 CentOS 系统
    check_centos
    
    # 检查系统要求
    check_requirements
    
    # 配置防火墙
    configure_firewall
    
    # 创建环境变量文件
    create_env_file
    
    # 构建镜像
    build_images
    
    # 部署服务
    deploy_services
    
    # 验证部署
    verify_deployment
    
    # 显示服务信息
    show_service_info
    
    log_success "部署完成！"
}

# 运行主函数
main "$@"
