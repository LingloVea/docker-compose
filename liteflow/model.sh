#!/bin/bash
# model.sh - LiteLLM 动态模型管理（零重启）
# 用法:
#   添加模型:  ./model.sh add name:<模型名> model:<实际模型> api:<密钥> url:<接口地址>
#   按ID删除:  ./model.sh del id:<模型ID>
#   按条件删除: ./model.sh del model:<实际模型> url:<接口地址>
#   查看帮助:  ./model.sh

set -e

# ===== 自动加载脚本所在目录下的 .env =====
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ENV_FILE="$SCRIPT_DIR/.env"
if [ -f "$ENV_FILE" ]; then
  set -a
  source "$ENV_FILE"
  set +a
fi

MASTER_KEY="${LITELLM_MASTER_KEY:?错误：请在 .env 中设置 LITELLM_MASTER_KEY}"
BASE_URL="http://localhost:${LITELLM_PORT:-4001}"

# ===== 帮助信息 =====
usage() {
  echo "用法:"
  echo "  添加模型:       $0 add name:<模型名> model:<实际模型> api:<密钥> url:<接口地址>"
  echo "  按ID删除:       $0 del id:<模型ID>"
  echo "  按条件删除:     $0 del model:<实际模型> url:<接口地址>"
  echo ""
  echo "示例:"
  echo "  $0 add name:claude model:nvidia_nim/deepseek-v4-flash api:nvapi-xxx url:https://integrate.api.nvidia.com/v1"
  echo "  $0 del id:12345678-abcd-..."
  echo "  $0 del model:nvidia_nim/deepseek-v4-flash url:https://integrate.api.nvidia.com/v1"
  exit 1
}

ACTION="$1"
shift || true

# ===== 添加模型 =====
if [ "$ACTION" = "add" ]; then
  declare -A PARAMS
  for arg in "$@"; do
    case "$arg" in
      name:*|model:*|api:*|url:*)
        key="${arg%%:*}"
        value="${arg#*:}"
        PARAMS[$key]="$value"
        ;;
      *)
        echo "未知参数: $arg"
        usage
        ;;
    esac
  done

  NAME="${PARAMS[name]:?缺少 name:}"
  MODEL="${PARAMS[model]:?缺少 model:}"
  API_KEY="${PARAMS[api]:?缺少 api:}"
  API_BASE="${PARAMS[url]:-}"

  echo "➕ 添加模型: $NAME → $MODEL"
  curl -s -X POST "$BASE_URL/model/new" \
    -H "Authorization: Bearer $MASTER_KEY" \
    -H "Content-Type: application/json" \
    -d "{
      \"model_name\": \"$NAME\",
      \"litellm_params\": {
        \"model\": \"$MODEL\",
        \"api_key\": \"$API_KEY\",
        \"api_base\": \"$API_BASE\"
      }
    }"
  printf "\n✅ 已添加\n"

# ===== 删除模型 =====
elif [ "$ACTION" = "del" ]; then
  declare -A PARAMS
  for arg in "$@"; do
    case "$arg" in
      id:*|model:*|url:*)
        key="${arg%%:*}"
        value="${arg#*:}"
        PARAMS[$key]="$value"
        ;;
      *)
        echo "未知参数: $arg"
        usage
        ;;
    esac
  done

  # 情况1：按ID直接删除
  if [ -n "${PARAMS[id]}" ]; then
    ID="${PARAMS[id]}"
    echo "🗑️  删除模型 ID: $ID"
    curl -s -X POST "$BASE_URL/model/delete" \
      -H "Authorization: Bearer $MASTER_KEY" \
      -H "Content-Type: application/json" \
      -d "{\"id\": \"$ID\"}"
    printf "\n✅ 已删除\n"

  # 情况2：按 model + url 精确匹配删除
  elif [ -n "${PARAMS[model]}" ] && [ -n "${PARAMS[url]}" ]; then
    SEARCH_MODEL="${PARAMS[model]}"
    SEARCH_URL="${PARAMS[url]}"
    echo "🔍 查找模型: $SEARCH_MODEL @ $SEARCH_URL"

    # 调用 /model/info 并用 python3 过滤匹配的 id
    MATCHES=$(curl -s "$BASE_URL/model/info" \
      -H "Authorization: Bearer $MASTER_KEY" | \
      python3 -c "
import sys, json
matches = []
for m in json.load(sys.stdin).get('data', []):
    p = m['litellm_params']
    if p.get('model') == '$SEARCH_MODEL' and p.get('api_base') == '$SEARCH_URL':
        matches.append(m['model_info']['id'])
if len(matches) == 1:
    print(matches[0])
elif len(matches) == 0:
    print('NONE')
else:
    print('MULTIPLE:' + ','.join(matches))
")

    if [[ "$MATCHES" == NONE ]]; then
      echo "❌ 未找到匹配的模型"
      exit 1
    elif [[ "$MATCHES" == MULTIPLE:* ]]; then
      echo "❌ 找到多条匹配记录，请使用具体的 ID 删除："
      IFS=',' read -ra IDS <<< "${MATCHES#MULTIPLE:}"
      for one_id in "${IDS[@]}"; do
        echo "   $one_id"
      done
      exit 1
    else
      ID="$MATCHES"
      echo "🗑️  删除模型 ID: $ID"
      curl -s -X POST "$BASE_URL/model/delete" \
        -H "Authorization: Bearer $MASTER_KEY" \
        -H "Content-Type: application/json" \
        -d "{\"id\": \"$ID\"}"
      printf "\n✅ 已删除\n"
    fi

  else
    echo "错误：删除需要 id: 或同时提供 model: + url:"
    usage
  fi

else
  usage
fi
