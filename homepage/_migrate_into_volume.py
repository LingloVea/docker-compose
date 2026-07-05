#!/usr/bin/env python3
"""把宿主机备份目录内容迁移进 Docker 命名卷 homepage_homepage-config。"""
import os
import subprocess
import sys
import tempfile

SRC = "/Users/linglo/Documents/Docker/homepage/config_backup_20260706_063702"
VOLUME = "homepage_homepage-config"

# 检查源目录
if not os.path.isdir(SRC):
    sys.exit(f"错误: 源目录不存在: {SRC}")

# 列出备份目录中的文件
entries = sorted(os.listdir(SRC))
if not entries:
    sys.exit("错误: 备份目录为空")

print(f"备份目录: {SRC}")
print(f"目标卷: {VOLUME}")
print(f"文件列表: {', '.join(entries)}")

# 创建临时容器，将卷挂载到 /target
print("创建临时容器...")
container_id = subprocess.check_output(
    ["docker", "run", "-d", "--rm", "-v", f"{VOLUME}:/target", "alpine", "tail", "-f", "/dev/null"],
    text=True
).strip()
print(f"容器 ID: {container_id[:12]}")

try:
    # 使用 docker cp 将备份目录内容复制到容器的 /target/
    print("迁移配置文件...")
    subprocess.check_call(
        ["docker", "cp", f"{SRC}/.", f"{container_id}:/target/"]
    )
    print("迁移完成!")
finally:
    # 清理临时容器
    print("清理临时容器...")
    subprocess.check_call(["docker", "stop", container_id])
