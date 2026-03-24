# Docker Compose 配置集

> Docker Compose YAML 配置文件集合，用于快速部署常用服务

## 📁 目录结构

```
Docker/
├── Data/              # 数据持久化目录
├── movies/            # 影视服务配置
├── music/             # 音乐服务配置
├── Openlist/          # Openlist 服务
└── OpenWebui/         # OpenWebUI 服务
```

## 🚀 快速开始

```bash
# 进入服务目录
cd movies

# 启动服务
docker-compose up -d

# 查看日志
docker-compose logs -f
```

## 📦 已配置服务

| 服务 | 目录 | 说明 |
|------|------|------|
| OpenWebUI | `OpenWebui/` | 开源 Web UI 服务 |
| Openlist | `Openlist/` | 列表管理服务 |
| Movies | `movies/` | 影视相关服务 |
| Music | `music/` | 音乐相关服务 |

## ⚙️ Docker 镜像加速

配置文件中使用的镜像加速：

```bash
# 南京大学镜像
ghrc.nju.edu.cn
```

## 📄 许可证

MIT License
