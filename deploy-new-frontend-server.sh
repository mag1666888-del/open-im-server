#!/bin/bash

# OpenIM 服务端新增前端服务部署脚本
# 通用部署方案，适用于任何服务器环境

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 配置变量（请根据实际情况修改）
FRONTEND_SOURCE_DIR="/opt/im-frontend"  # 前端源代码目录
OPENIM_SERVER_DIR="/opt/open-im-server"  # OpenIM 服务器目录
DOCKER_REGISTRY=""  # Docker 镜像仓库地址（可选）

# 日志函数
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

# 显示帮助信息
show_help() {
    echo "OpenIM 服务端新增前端服务部署脚本"
    echo ""
    echo "用法: $0 [选项]"
    echo ""
    echo "选项:"
    echo "  -h, --help              显示此帮助信息"
    echo "  -s, --source DIR        前端源代码目录路径"
    echo "  -d, --destination DIR   OpenIM 服务器目录路径"
    echo "  -r, --registry URL      Docker 镜像仓库地址（可选）"
    echo "  -b, --build             构建 Docker 镜像"
    echo "  -p, --push              推送镜像到仓库"
    echo "  -deploy, --deploy       部署服务"
    echo "  -restart, --restart     重启服务"
    echo "  -stop, --stop           停止服务"
    echo "  -logs, --logs           查看日志"
    echo "  -status, --status       查看状态"
    echo "  -clean, --clean         清理未使用的镜像"
    echo ""
    echo "示例:"
    echo "  $0 --source /opt/im-frontend --destination /opt/open-im-server --build --deploy"
    echo "  $0 --source /opt/im-frontend --destination /opt/open-im-server --registry registry.example.com --build --push --deploy"
}

# 检查必需的工具
check_requirements() {
    log_info "检查系统要求..."
    
    # 检查操作系统
    if [ -f /etc/redhat-release ]; then
        log_info "检测到 CentOS/RHEL 系统"
        OS_TYPE="centos"
    elif [ -f /etc/debian_version ]; then
        log_info "检测到 Debian/Ubuntu 系统"
        OS_TYPE="debian"
    else
        log_warning "未知操作系统，继续执行..."
        OS_TYPE="unknown"
    fi
    
    # 检查 Docker
    if ! command -v docker &> /dev/null; then
        log_error "Docker 未安装，请先安装 Docker"
        if [ "$OS_TYPE" = "centos" ]; then
            log_info "CentOS 安装 Docker 命令:"
            log_info "sudo yum install -y yum-utils"
            log_info "sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo"
            log_info "sudo yum install -y docker-ce docker-ce-cli containerd.io"
            log_info "sudo systemctl start docker"
            log_info "sudo systemctl enable docker"
        fi
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
    if ! command -v docker-compose &> /dev/null; then
        log_error "Docker Compose 未安装，请先安装 Docker Compose"
        if [ "$OS_TYPE" = "centos" ]; then
            log_info "CentOS 安装 Docker Compose 命令:"
            log_info "sudo curl -L \"https://github.com/docker/compose/releases/latest/download/docker-compose-\$(uname -s)-\$(uname -m)\" -o /usr/local/bin/docker-compose"
            log_info "sudo chmod +x /usr/local/bin/docker-compose"
        fi
        exit 1
    fi
    
    # 检查目录是否存在
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
    
    # 检查端口占用
    if netstat -tlnp 2>/dev/null | grep -q :11003; then
        log_warning "端口 11003 已被占用，新服务可能无法启动"
    fi
    
    if netstat -tlnp 2>/dev/null | grep -q :11004; then
        log_warning "端口 11004 已被占用，新服务可能无法启动"
    fi
    
    log_success "系统要求检查通过"
}

# 创建环境变量文件
create_env_file() {
    log_info "创建环境变量文件..."
    
    cat > "$OPENIM_SERVER_DIR/docker-compose.env" << EOF
# OpenIM Docker Compose 环境变量

# 现有服务镜像
OPENIM_WEB_FRONT_IMAGE=openim-web-front:latest
OPENIM_ADMIN_FRONT_IMAGE=openim-admin-front:latest

# 新增前端服务镜像
OPENIM_ADMIN_NEW_FRONT_1_IMAGE=${DOCKER_REGISTRY}openim-admin-new-front-1:latest
OPENIM_ADMIN_NEW_FRONT_2_IMAGE=${DOCKER_REGISTRY}openim-admin-new-front-2:latest

# 其他服务镜像
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

# 构建 Docker 镜像
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
    docker build -f Dockerfile.admin-new-front-1 -t ${DOCKER_REGISTRY}openim-admin-new-front-1:latest .
    log_success "openim-admin-new-front-1 镜像构建完成"
    
    # 构建 front-2 镜像
    log_info "构建 openim-admin-new-front-2 镜像..."
    docker build -f Dockerfile.admin-new-front-2 -t ${DOCKER_REGISTRY}openim-admin-new-front-2:latest .
    log_success "openim-admin-new-front-2 镜像构建完成"
    
    # 清理临时文件
    log_info "清理临时文件..."
    rm -f "$FRONTEND_SOURCE_DIR/Dockerfile.admin-new-front-1"
    rm -f "$FRONTEND_SOURCE_DIR/Dockerfile.admin-new-front-2"
    rm -rf "$FRONTEND_SOURCE_DIR/config"
}

# 推送镜像到仓库
push_images() {
    if [ -z "$DOCKER_REGISTRY" ]; then
        log_warning "未指定 Docker 仓库，跳过推送"
        return
    fi
    
    log_info "推送镜像到仓库..."
    
    # 推送 front-1 镜像
    log_info "推送 openim-admin-new-front-1 镜像..."
    docker push ${DOCKER_REGISTRY}openim-admin-new-front-1:latest
    log_success "openim-admin-new-front-1 镜像推送完成"
    
    # 推送 front-2 镜像
    log_info "推送 openim-admin-new-front-2 镜像..."
    docker push ${DOCKER_REGISTRY}openim-admin-new-front-2:latest
    log_success "openim-admin-new-front-2 镜像推送完成"
}

# 检查现有 OpenIM 服务
check_existing_services() {
    log_info "检查现有 OpenIM 服务..."
    
    cd "$OPENIM_SERVER_DIR"
    
    # 检查是否有运行中的 OpenIM 服务
    if docker-compose ps 2>/dev/null | grep -q "openim"; then
        log_success "发现运行中的 OpenIM 服务"
        log_info "现有服务状态:"
        docker-compose ps | grep "openim" || true
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
    if docker-compose --env-file docker-compose.env up -d openim-admin-new-front-1; then
        log_success "openim-admin-new-front-1 服务已启动 (端口 11003)"
    else
        log_error "openim-admin-new-front-1 服务启动失败"
        return 1
    fi
    
    log_info "启动 openim-admin-new-front-2 服务..."
    if docker-compose --env-file docker-compose.env up -d openim-admin-new-front-2; then
        log_success "openim-admin-new-front-2 服务已启动 (端口 11004)"
    else
        log_error "openim-admin-new-front-2 服务启动失败"
        return 1
    fi
}

# 重启服务
restart_services() {
    log_info "重启服务..."
    
    cd "$OPENIM_SERVER_DIR"
    
    docker-compose --env-file docker-compose.env restart openim-admin-new-front-1
    docker-compose --env-file docker-compose.env restart openim-admin-new-front-2
    
    log_success "服务重启完成"
}

# 停止服务
stop_services() {
    log_info "停止服务..."
    
    cd "$OPENIM_SERVER_DIR"
    
    docker-compose --env-file docker-compose.env stop openim-admin-new-front-1
    docker-compose --env-file docker-compose.env stop openim-admin-new-front-2
    
    log_success "服务已停止"
}

# 查看日志
show_logs() {
    log_info "查看服务日志..."
    
    cd "$OPENIM_SERVER_DIR"
    
    echo "=== openim-admin-new-front-1 日志 ==="
    docker-compose --env-file docker-compose.env logs -f openim-admin-new-front-1
}

# 查看状态
show_status() {
    log_info "查看服务状态..."
    
    cd "$OPENIM_SERVER_DIR"
    
    echo "=== 服务状态 ==="
    docker-compose --env-file docker-compose.env ps | grep admin-new-front
    
    echo ""
    echo "=== 端口占用 ==="
    netstat -tlnp | grep :11003 || echo "端口 11003 未被占用"
    netstat -tlnp | grep :11004 || echo "端口 11004 未被占用"
    
    echo ""
    echo "=== 服务访问测试 ==="
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

# 清理未使用的镜像
clean_images() {
    log_info "清理未使用的 Docker 镜像..."
    docker image prune -f
    log_success "清理完成"
}

# 创建部署包
create_deployment_package() {
    log_info "创建部署包..."
    
    PACKAGE_DIR="/tmp/openim-new-frontend-deployment"
    mkdir -p "$PACKAGE_DIR"
    
    # 复制必需文件
    cp "$OPENIM_SERVER_DIR/docker-compose.yml" "$PACKAGE_DIR/"
    cp "$OPENIM_SERVER_DIR/Dockerfile.admin-new-front-1" "$PACKAGE_DIR/"
    cp "$OPENIM_SERVER_DIR/Dockerfile.admin-new-front-2" "$PACKAGE_DIR/"
    cp -r "$OPENIM_SERVER_DIR/config" "$PACKAGE_DIR/"
    
    # 创建部署脚本
    cat > "$PACKAGE_DIR/deploy.sh" << 'EOF'
#!/bin/bash
# 简化的部署脚本

set -e

echo "开始部署 OpenIM 新前端服务..."

# 创建环境变量文件
cat > docker-compose.env << 'ENV_EOF'
OPENIM_WEB_FRONT_IMAGE=openim-web-front:latest
OPENIM_ADMIN_FRONT_IMAGE=openim-admin-front:latest
OPENIM_ADMIN_NEW_FRONT_1_IMAGE=openim-admin-new-front-1:latest
OPENIM_ADMIN_NEW_FRONT_2_IMAGE=openim-admin-new-front-2:latest
PROMETHEUS_IMAGE=prom/prometheus:latest
ALERTMANAGER_IMAGE=prom/alertmanager:latest
GRAFANA_IMAGE=grafana/grafana:latest
NODE_EXPORTER_IMAGE=prom/node-exporter:latest
PROMETHEUS_PORT=9090
ALERTMANAGER_PORT=9093
GRAFANA_PORT=3000
ENV_EOF

# 构建镜像
echo "构建镜像..."
docker build -f Dockerfile.admin-new-front-1 -t openim-admin-new-front-1:latest .
docker build -f Dockerfile.admin-new-front-2 -t openim-admin-new-front-2:latest .

# 启动服务
echo "启动服务..."
docker-compose --env-file docker-compose.env up -d openim-admin-new-front-1
docker-compose --env-file docker-compose.env up -d openim-admin-new-front-2

echo "部署完成！"
echo "服务访问地址："
echo "  Front-1: http://localhost:11003"
echo "  Front-2: http://localhost:11004"
EOF
    
    chmod +x "$PACKAGE_DIR/deploy.sh"
    
    # 创建压缩包
    tar -czf "/tmp/openim-new-frontend-deployment.tar.gz" -C /tmp openim-new-frontend-deployment
    
    log_success "部署包创建完成: /tmp/openim-new-frontend-deployment.tar.gz"
    log_info "部署包包含:"
    log_info "  - docker-compose.yml"
    log_info "  - Dockerfile.admin-new-front-1"
    log_info "  - Dockerfile.admin-new-front-2"
    log_info "  - config/ 目录"
    log_info "  - deploy.sh 部署脚本"
}

# 主函数
main() {
    # 默认值
    BUILD=false
    PUSH=false
    DEPLOY=false
    RESTART=false
    STOP=false
    LOGS=false
    STATUS=false
    CLEAN=false
    CREATE_PACKAGE=false
    
    # 解析命令行参数
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            -s|--source)
                FRONTEND_SOURCE_DIR="$2"
                shift 2
                ;;
            -d|--destination)
                OPENIM_SERVER_DIR="$2"
                shift 2
                ;;
            -r|--registry)
                DOCKER_REGISTRY="$2"
                shift 2
                ;;
            -b|--build)
                BUILD=true
                shift
                ;;
            -p|--push)
                PUSH=true
                shift
                ;;
            -deploy|--deploy)
                DEPLOY=true
                shift
                ;;
            -restart|--restart)
                RESTART=true
                shift
                ;;
            -stop|--stop)
                STOP=true
                shift
                ;;
            -logs|--logs)
                LOGS=true
                shift
                ;;
            -status|--status)
                STATUS=true
                shift
                ;;
            -clean|--clean)
                CLEAN=true
                shift
                ;;
            --create-package)
                CREATE_PACKAGE=true
                shift
                ;;
            *)
                log_error "未知参数: $1"
                show_help
                exit 1
                ;;
        esac
    done
    
    # 检查系统要求
    check_requirements
    
    # 创建环境变量文件
    create_env_file
    
    # 执行操作
    if [ "$BUILD" = true ]; then
        build_images
    fi
    
    if [ "$PUSH" = true ]; then
        push_images
    fi
    
    if [ "$DEPLOY" = true ]; then
        deploy_services
    fi
    
    if [ "$RESTART" = true ]; then
        restart_services
    fi
    
    if [ "$STOP" = true ]; then
        stop_services
    fi
    
    if [ "$LOGS" = true ]; then
        show_logs
    fi
    
    if [ "$STATUS" = true ]; then
        show_status
    fi
    
    if [ "$CLEAN" = true ]; then
        clean_images
    fi
    
    if [ "$CREATE_PACKAGE" = true ]; then
        create_deployment_package
    fi
    
    # 如果没有指定任何操作，显示状态
    if [ "$BUILD" = false ] && [ "$PUSH" = false ] && [ "$DEPLOY" = false ] && [ "$RESTART" = false ] && [ "$STOP" = false ] && [ "$LOGS" = false ] && [ "$STATUS" = false ] && [ "$CLEAN" = false ] && [ "$CREATE_PACKAGE" = false ]; then
        show_status
    fi
    
    log_success "操作完成"
}

# 运行主函数
main "$@"
