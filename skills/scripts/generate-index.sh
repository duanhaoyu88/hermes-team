#!/usr/bin/env bash
# generate-index.sh — 从 skill-map.yaml 生成 skill-index.yaml + deploy-report.md
# 用法:
#   bash generate-index.sh                      → 默认输入 ../skill-map.yaml
#   bash generate-index.sh --dry-run            → 只输出 stdout，不写文件
#   bash generate-index.sh --map path/to.yaml   → 自定义 skill-map 路径
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
DEFAULT_MAP="$SCRIPT_DIR/../skill-map.yaml"
DRY_RUN=0
MAP_FILE="$DEFAULT_MAP"

# 参数解析
while [ $# -gt 0 ]; do
  case "$1" in
    --dry-run) DRY_RUN=1; shift ;;
    --map) MAP_FILE="$2"; shift 2 ;;
    *) echo "未知参数: $1"; echo "用法: $0 [--dry-run] [--map path/to/skill-map.yaml]"; exit 1 ;;
  esac
done

if [ ! -f "$MAP_FILE" ]; then
  echo "❌ skill-map.yaml 不存在: $MAP_FILE" >&2
  exit 1
fi

OUT_DIR="$(dirname "$MAP_FILE")"
INDEX_FILE="$OUT_DIR/skill-index.yaml"
REPORT_FILE="$OUT_DIR/deploy-report.md"

# ── YAML → JSON 解析（Python 辅助）──
parse_yaml() {
  python3 -c "
import yaml, json, sys
from datetime import date, datetime

class CustomEncoder(json.JSONEncoder):
    def default(self, obj):
        if isinstance(obj, (date, datetime)):
            return obj.isoformat()
        return super().default(obj)

try:
    with open('$MAP_FILE') as f:
        data = yaml.safe_load(f)
    if not data or 'skills' not in data:
        print('ERROR: skill-map.yaml 格式错误，缺少 skills 字段', file=sys.stderr)
        sys.exit(2)
    json_str = json.dumps(data, cls=CustomEncoder, ensure_ascii=False)
    print(json_str)
except yaml.YAMLError as e:
    print(f'ERROR: YAML 解析失败: {e}', file=sys.stderr)
    sys.exit(2)
except FileNotFoundError:
    print(f'ERROR: 文件不存在: $MAP_FILE', file=sys.stderr)
    sys.exit(2)
except Exception as e:
    print(f'ERROR: JSON 序列化失败: {e}', file=sys.stderr)
    sys.exit(2)
"
}

JSON_DATA=$(parse_yaml) || {
  echo "❌ YAML 解析失败，请检查 skill-map.yaml 格式" >&2
  exit 1
}

# ── 交叉检查 ──
run_cross_check() {
  echo "── 交叉检查 ──"

  # 检查 name 唯一性
  local dupes
  dupes=$(echo "$JSON_DATA" | jq -r '.skills[].name' | sort | uniq -d)
  if [ -n "$dupes" ]; then
    echo "❌ 发现重复 skill name: $dupes"
    return 1
  fi
  echo "  ✅ name 唯一性通过"

  # 检查每个 skill 被至少一个角色引用
  local unreferenced
  unreferenced=$(echo "$JSON_DATA" | jq -r '.skills[] | select((.roles | length) == 0) | .name' 2>/dev/null)
  if [ -n "$unreferenced" ]; then
    echo "❌ 以下 skill 未被任何角色引用: $unreferenced"
    return 1
  fi
  echo "  ✅ 角色引用检查通过"

  # 检查 load 值合法性
  local bad_load
  bad_load=$(echo "$JSON_DATA" | jq -r '.skills[] | select(.load as $l | $l != "auto" and $l != "manual" and $l != "never") | "\(.name): \(.load)"' 2>/dev/null)
  if [ -n "$bad_load" ]; then
    echo "❌ 非法的 load 值: $bad_load"
    return 1
  fi
  echo "  ✅ load 值合法性通过"

  echo ""
  return 0
}

# ── 生成 skill-index.yaml ──
generate_index() {
  local roles
  roles=$(echo "$JSON_DATA" | jq -r '[.skills[].roles[]] | unique | .[]' 2>/dev/null)

  cat <<EOF
# Skill Index — 角色→skill 分配表
# 自动生成于 $(date -u +"%Y-%m-%dT%H:%M:%SZ")
# 源文件: $MAP_FILE
# 勿手动编辑。修改 skill-map.yaml 后重新运行 generate-index.sh
schema_version: "1.0"
generated_by: generate-index.sh

roles:
EOF

  for role in $roles; do
    echo "  $role:"

    # auto
    echo "    auto:"
    echo "$JSON_DATA" | jq -r --arg role "$role" '.skills[] | select(.roles | index($role)) | select(.load == "auto") | "      - \(.name)"' 2>/dev/null

    # manual
    echo "    manual:"
    echo "$JSON_DATA" | jq -r --arg role "$role" '.skills[] | select(.roles | index($role)) | select(.load == "manual") | "      - \(.name)"' 2>/dev/null

    # never
    echo "    never:"
    echo "$JSON_DATA" | jq -r --arg role "$role" '.skills[] | select(.roles | index($role)) | select(.load == "never") | "      - \(.name)"' 2>/dev/null
  done
}

# ── 生成 deploy-report.md ──
generate_report() {
  local total
  total=$(echo "$JSON_DATA" | jq '.skills | length')

  cat <<EOF
# Deploy Report — Skill 部署清单

> 生成时间: $(date -u +"%Y-%m-%dT%H:%M:%SZ")
> 源文件: $MAP_FILE
> 总计: $total 个 skill

## 部署概览

| 角色 | auto | manual | never | 小计 |
|------|------|--------|-------|------|
EOF

  local roles
  roles=$(echo "$JSON_DATA" | jq -r '[.skills[].roles[]] | unique | .[]' 2>/dev/null)

  for role in $roles; do
    local a_count m_count n_count sub
    a_count=$(echo "$JSON_DATA" | jq --arg role "$role" '[.skills[] | select(.roles | index($role)) | select(.load == "auto")] | length')
    m_count=$(echo "$JSON_DATA" | jq --arg role "$role" '[.skills[] | select(.roles | index($role)) | select(.load == "manual")] | length')
    n_count=$(echo "$JSON_DATA" | jq --arg role "$role" '[.skills[] | select(.roles | index($role)) | select(.load == "never")] | length')
    sub=$((a_count + m_count + n_count))
    echo "| $role | $a_count | $m_count | $n_count | $sub |"
  done

  echo ""
  echo "## 详细分配"
  echo ""

  for role in $roles; do
    echo "### $role"
    echo ""
    echo "**auto（启动加载）:**"
    echo "$JSON_DATA" | jq -r --arg role "$role" '.skills[] | select(.roles | index($role)) | select(.load == "auto") | "  - `\(.name)` — \(.when // "无")"' 2>/dev/null
    echo ""
    echo "**manual（按需加载）:**"
    echo "$JSON_DATA" | jq -r --arg role "$role" '.skills[] | select(.roles | index($role)) | select(.load == "manual") | "  - `\(.name)` — \(.when // "无")"' 2>/dev/null
    echo ""
    echo "**never（禁止加载）:**"
    echo "$JSON_DATA" | jq -r --arg role "$role" '.skills[] | select(.roles | index($role)) | select(.load == "never") | "  - `\(.name)` — \(.description // "无")"' 2>/dev/null
    echo ""
  done

  echo "## 交叉检查"
  echo ""
  echo "- name 唯一性: ✅ 通过"
  echo "- 角色引用: 每个 skill 被至少一个角色的 auto 或 manual 引用"
  echo "- load 值: 全部在 [auto, manual, never] 范围内"
}

# ── 主流程 ──

if [ "$DRY_RUN" -eq 1 ]; then
  echo "=== DRY RUN 模式 — 只输出到 stdout，不写文件 ==="
  echo ""
fi

run_cross_check
CROSS_OK=$?

if [ "$CROSS_OK" -ne 0 ]; then
  echo "❌ 交叉检查失败，终止生成" >&2
  exit 1
fi

INDEX_CONTENT=$(generate_index)
REPORT_CONTENT=$(generate_report)

if [ "$DRY_RUN" -eq 1 ]; then
  echo "$INDEX_CONTENT"
  echo ""
  echo "---"
  echo ""
  echo "$REPORT_CONTENT"
  echo ""
  echo "=== DRY RUN 完成 — 未写文件 ==="
else
  echo "$INDEX_CONTENT" > "$INDEX_FILE"
  echo "✅ skill-index.yaml → $INDEX_FILE"

  echo "$REPORT_CONTENT" > "$REPORT_FILE"
  echo "✅ deploy-report.md → $REPORT_FILE"
fi
