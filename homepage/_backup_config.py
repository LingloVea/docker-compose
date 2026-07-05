#!/usr/bin/env python3
"""按全局规则用 Python 备份 homepage 配置目录。"""
import os
import shutil
import datetime
from pathlib import Path

BASE = Path("/Users/linglo/Documents/Docker/homepage")
SRC = BASE / "config"
DATE_TAG = datetime.datetime.now().strftime("%Y%m%d_%H%M%S")
DST = BASE / f"config_backup_{DATE_TAG}"

if not SRC.exists():
    raise SystemExit(f"源目录不存在: {SRC}")

shutil.copytree(SRC, DST, symlinks=True, dirs_exist_ok=False)
print(f"备份完成: {DST}")
for entry in sorted(DST.iterdir()):
    print(f"  {entry.name}")
