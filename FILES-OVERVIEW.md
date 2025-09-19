# OpenIM 新增前端服务 - 文件清单

## 📁 核心文件

### 部署脚本
- **`centos-deploy.sh`** - CentOS 专用部署脚本（推荐）
- **`deploy-new-frontend-server.sh`** - 通用部署脚本

### Docker 配置
- **`docker-compose.yml`** - 已更新，包含新的前端服务配置
- **`Dockerfile.admin-new-front-1`** - Front-1 构建文件（代理到 47.239.126.22）
- **`Dockerfile.admin-new-front-2`** - Front-2 构建文件（代理到 47.83.254.218）

### NGINX 配置
- **`config/nginx-admin-new-front-1.conf`** - Front-1 NGINX 配置
- **`config/nginx-admin-new-front-2.conf`** - Front-2 NGINX 配置
- **`config/nginx-admin-new-front-1-template.conf`** - Front-1 配置模板
- **`config/nginx-admin-new-front-2-template.conf`** - Front-2 配置模板

### 文档
- **`DEPLOYMENT-GUIDE.md`** - 主要部署指南

## 🚀 快速使用

### CentOS 服务器（推荐）

```bash
# 1. 进入 OpenIM 服务器目录
cd /opt/open-im-server

# 2. 修改脚本中的路径（如需要）
nano centos-deploy.sh

# 3. 执行部署
./centos-deploy.sh
```

### 其他 Linux 服务器

```bash
# 1. 进入 OpenIM 服务器目录
cd /opt/open-im-server

# 2. 执行部署
./deploy-new-frontend-server.sh \
  --source /opt/im-frontend \
  --destination /opt/open-im-server \
  --build \
  --deploy
```

## 📊 服务配置

| 服务名称 | 端口 | 代理服务器 | 说明 |
|---------|------|-----------|------|
| openim-admin-new-front-1 | 11003 | 47.239.126.22 | 新的后台前端 1 |
| openim-admin-new-front-2 | 11004 | 47.83.254.218 | 新的后台前端 2 |

## 🔧 管理命令

```bash
# 查看服务状态
docker-compose --env-file docker-compose.env ps

# 查看服务日志
docker-compose --env-file docker-compose.env logs -f openim-admin-new-front-1

# 重启服务
docker-compose --env-file docker-compose.env restart openim-admin-new-front-1

# 停止服务
docker-compose --env-file docker-compose.env stop openim-admin-new-front-1
```

## ⚠️ 注意事项

1. 确保端口 11003 和 11004 未被占用
2. 确保前端源代码已上传到服务器
3. 确保服务器可以访问后端服务
4. 确保 Docker 和 Docker Compose 已安装
