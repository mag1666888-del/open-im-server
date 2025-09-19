# OpenIM 新增前端服务部署指南

本指南说明如何在现有 OpenIM 系统基础上添加两个新的前端服务。

## 🎯 目标

在现有 OpenIM 系统基础上添加：
- **openim-admin-new-front-1**: 端口 11003，代理到 47.239.126.22
- **openim-admin-new-front-2**: 端口 11004，代理到 47.83.254.218

## 📋 前提条件

### 系统要求
- Linux 服务器（推荐 CentOS 7/8/9）
- Docker 已安装并运行
- Docker Compose 已安装
- 前端源代码已上传到服务器

### 目录结构
```
/opt/
├── im-frontend/          # 前端源代码目录
│   ├── package.json
│   ├── src/
│   └── ...
└── open-im-server/       # OpenIM 服务器目录
    ├── docker-compose.yml
    ├── Dockerfile.admin-new-front-1
    ├── Dockerfile.admin-new-front-2
    ├── config/
    ├── deploy-new-frontend-server.sh  # 通用部署脚本
    └── centos-deploy.sh              # CentOS 专用脚本
```

## 🚀 快速部署

### 方法一：CentOS 专用脚本（推荐）

```bash
# 1. 进入 OpenIM 服务器目录
cd /opt/open-im-server

# 2. 修改脚本中的路径（如需要）
nano centos-deploy.sh

# 3. 执行部署
./centos-deploy.sh
```

### 方法二：通用部署脚本

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

## 📊 服务详情

### 新增服务配置

| 服务名称 | 端口 | 代理服务器 | 容器名称 |
|---------|------|-----------|----------|
| openim-admin-new-front-1 | 11003 | 47.239.126.22 | openim-admin-new-front-1 |
| openim-admin-new-front-2 | 11004 | 47.83.254.218 | openim-admin-new-front-2 |

### API 路径映射

两个服务都支持完整的 API 代理：
- `/api/admin/*` → 管理后台服务 (端口 10009)
- `/api/user/*` → 用户服务 (端口 10008)
- `/api/im/*` → IM系统服务 (端口 10002)

## 🔧 管理命令

### 查看服务状态

```bash
# 查看所有服务
docker-compose --env-file docker-compose.env ps

# 仅查看新添加的服务
docker-compose --env-file docker-compose.env ps | grep admin-new-front
```

### 查看服务日志

```bash
# 查看 front-1 日志
docker-compose --env-file docker-compose.env logs -f openim-admin-new-front-1

# 查看 front-2 日志
docker-compose --env-file docker-compose.env logs -f openim-admin-new-front-2
```

### 重启服务

```bash
# 重启所有新服务
docker-compose --env-file docker-compose.env restart openim-admin-new-front-1
docker-compose --env-file docker-compose.env restart openim-admin-new-front-2
```

### 停止服务

```bash
# 停止新服务
docker-compose --env-file docker-compose.env stop openim-admin-new-front-1
docker-compose --env-file docker-compose.env stop openim-admin-new-front-2
```

## 🔍 验证部署

### 1. 检查服务运行状态

```bash
docker-compose --env-file docker-compose.env ps | grep admin-new-front
```

应该看到类似输出：
```
openim-admin-new-front-1   openim-admin-new-front-1:latest   Up      0.0.0.0:11003->80/tcp
openim-admin-new-front-2   openim-admin-new-front-2:latest   Up      0.0.0.0:11004->80/tcp
```

### 2. 测试服务访问

```bash
# 测试 front-1
curl -I http://localhost:11003/
# 应该返回 HTTP/1.1 200 OK

# 测试 front-2
curl -I http://localhost:11004/
# 应该返回 HTTP/1.1 200 OK
```

### 3. 测试 API 代理

```bash
# 测试 front-1 API 代理
curl http://localhost:11003/api/admin/account/info
curl http://localhost:11003/api/user/search/full
curl http://localhost:11003/api/im/user/get_users

# 测试 front-2 API 代理
curl http://localhost:11004/api/admin/account/info
curl http://localhost:11004/api/user/search/full
curl http://localhost:11004/api/im/user/get_users
```

## ⚠️ 注意事项

1. **端口冲突**: 确保端口 11003 和 11004 未被占用
2. **现有服务**: 新服务不会影响现有的 OpenIM 服务
3. **网络配置**: 确保服务器可以访问后端服务
4. **资源使用**: 确保服务器有足够资源运行新服务
5. **防火墙**: 确保防火墙允许访问新端口

## 🔧 故障排除

### 1. 端口被占用

```bash
# 检查端口占用
netstat -tlnp | grep :11003
netstat -tlnp | grep :11004

# 停止占用端口的服务
sudo lsof -ti:11003 | xargs kill -9
sudo lsof -ti:11004 | xargs kill -9
```

### 2. 镜像构建失败

```bash
# 检查 Dockerfile 路径
ls -la /opt/im-frontend/Dockerfile.admin-new-front-*

# 检查前端源代码
ls -la /opt/im-frontend/package.json

# 重新构建
docker build -f /opt/im-frontend/Dockerfile.admin-new-front-1 -t openim-admin-new-front-1:latest /opt/im-frontend/
```

### 3. 服务启动失败

```bash
# 查看详细错误日志
docker-compose --env-file docker-compose.env logs openim-admin-new-front-1

# 检查环境变量
cat docker-compose.env

# 检查 docker-compose.yml 配置
grep -A 10 "openim-admin-new-front-1" docker-compose.yml
```

### 4. API 代理失败

```bash
# 检查 NGINX 配置
docker exec openim-admin-new-front-1 cat /etc/nginx/conf.d/default.conf

# 测试后端连接
docker exec openim-admin-new-front-1 curl -f http://47.239.126.22:10009/health
docker exec openim-admin-new-front-2 curl -f http://47.83.254.218:10009/health
```

## 📊 监控和维护

### 查看资源使用

```bash
# 查看容器资源使用
docker stats openim-admin-new-front-1 openim-admin-new-front-2

# 查看系统资源
htop
```

### 日志管理

```bash
# 实时查看日志
docker-compose --env-file docker-compose.env logs -f

# 查看最近日志
docker-compose --env-file docker-compose.env logs --tail=100 openim-admin-new-front-1
```

## 🎉 完成

部署完成后，您将拥有：

1. **原有的 OpenIM 服务** - 继续正常运行
2. **新的前端服务 1** - http://your-server:11003 (代理到 47.239.126.22)
3. **新的前端服务 2** - http://your-server:11004 (代理到 47.83.254.218)

所有服务都使用相同的后端 API，但通过不同的前端界面访问。

## 📞 技术支持

如遇到问题，请检查：

1. **Docker 状态**: `docker info`
2. **服务状态**: `docker-compose --env-file docker-compose.env ps`
3. **日志信息**: `docker-compose --env-file docker-compose.env logs`
4. **网络连接**: `ping` 后端服务器
5. **端口占用**: `netstat -tlnp | grep :1100`
