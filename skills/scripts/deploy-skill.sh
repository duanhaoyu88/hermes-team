#!/usr/bin/env bash
# deploy-skill.sh — 将 skill 实体部署到所有相关 agent profile
# 用法:
#   bash deploy-skill.sh --add --skill <name> --dry-run    # 预览
#   bash deploy-skill.sh --add --skill <name> --apply      # 执行
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SKILLS_DIR="$SCRIPT_DIR/.."
INDEX_FILE="$SKILLS_DIR/skill-index.yaml"
DRY_RUN=0
APPLY=0
SKILL_NAME=""

while [ $# -gt 0 ]; do
  case "$1" in
    --add) shift ;;
    --skill) SKILL_NAME="$2"; shift 2 ;;
    --dry-run) DRY_RUN=1; shift ;;
    --apply) APPLY=1; shift ;;
    *) echo "未知参数: $1"; exit 1 ;;
  esac
done

[ -n "$SKILL_NAME" ] || { echo "用法: $0 --add --skill <name> [--dry-run|--apply]"; exit 1; }
[ "$DRY_RUN" -eq 1 ] || [ "$APPLY" -eq 1 ] || { echo "需要 --dry-run 或 --apply"; exit 1; }

# 查找 skill 源
find_source() {
  local name="$1"
  # 1. hermes-team/skills/<name>/ 目录
  if [ -d "$SKILLS_DIR/$name" ] && [ -f "$SKILLS_DIR/$name/SKILL.md" ]; then
    echo "$SKILLS_DIR/$name"
    return
  fi
  # 2. 扫描 agent profiles 找已有副本
  local profiles="/home/duanhaoyu/.hermes/profiles"
  if [ ! -d "$profiles" ]; then
    REAL_HOME=$(python3 -c "import pwd, os; print(pwd.getpwuid(os.getuid()).pw_dir)" 2>/dev/null || echo "/home/$USER")
    profiles="$REAL_HOME/.hermes/profiles"
  fi
  for pd in "$profiles"/*/; do
    [ -d "$pd" ] || continue
    local found
    found=$(find "$pd/skills" -maxdepth 4 -path "*/$name/SKILL.md" 2>/dev/null | head -1)
    if [ -n "$found" ]; then
      dirname "$found"
      return
    fi
  done
  echo ""
}

SOURCE=$(find_source "$SKILL_NAME")
if [ -z "$SOURCE" ]; then
  echo "❌ 找不到 skill '$SKILL_NAME' 的源文件。"
  echo "   请在 hermes-team/skills/$SKILL_NAME/ 下创建 SKILL.md"
  exit 1
fi

echo "Skill 源: $SOURCE"

# 读 roles 列表
ROLES=$(python3 -c "
import yaml, json
with open('$INDEX_FILE') as f:
    d = yaml.safe_load(f)
roles = []
for role, data in d.get('roles', {}).items():
    all_skills = set(data.get('auto', []) or []) | set(data.get('manual', []) or [])
    if '$SKILL_NAME' in all_skills:
        roles.append(role)
print(' '.join(roles))
" 2>/dev/null)

if [ -z "$ROLES" ]; then
  echo "❌ skill-index.yaml 中没有角色引用 '$SKILL_NAME'"
  exit 1
fi

echo "目标角色: $ROLES"
echo ""

PROFILES_DIR="/home/duanhaoyu/.hermes/profiles"
if [ ! -d "$PROFILES_DIR" ]; then
  REAL_HOME=$(python3 -c "import pwd, os; print(pwd.getpwuid(os.getuid()).pw_dir)" 2>/dev/null || echo "/home/$USER")
  PROFILES_DIR="$REAL_HOME/.hermes/profiles"
fi

COPIED=0
SKIPPED=0

for role in $ROLES; do
  agent="${role}-agent"
  target="$PROFILES_DIR/$agent/skills/$SKILL_NAME"

  if [ -d "$target" ]; then
    echo "  ⏭️  $agent: 已存在，跳过"
    SKIPPED=$((SKIPPED + 1))
    continue
  fi

  echo "  📋 $agent: $SOURCE → $target"
  if [ "$APPLY" -eq 1 ]; then
    mkdir -p "$(dirname "$target")"
    cp -r "$SOURCE" "$target"
  fi
  COPIED=$((COPIED + 1))
done

echo ""
echo "=========================================="
echo " 汇总: 复制 $COPIED / 跳过 $SKIPPED"
if [ "$DRY_RUN" -eq 1 ]; then
  echo " DRY RUN — 未执行"
else
  echo " ✅ 完成"
fi
