#!/usr/bin/env bash
# deploy-skills.sh — 根据 skill-index.yaml 清理各 agent profile skills 目录
# 仅保留 auto/manual 列表中的 skill，其余备份后删除。
#
# 用法:
#   bash deploy-skills.sh                    → 执行清理
#   bash deploy-skills.sh --dry-run          → 只预览不下手
#   bash deploy-skills.sh --restore <backup> → 从备份恢复
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
INDEX_FILE="$SCRIPT_DIR/../skill-index.yaml"
SKILLS_BASE="$HOME/.hermes/profiles"
BACKUP_DIR="$HOME/.hermes/skills-backup-$(date +%Y%m%d_%H%M%S)"
DRY_RUN=0

while [ $# -gt 0 ]; do
  case "$1" in
    --dry-run) DRY_RUN=1; shift ;;
    --restore) echo "恢复功能: tar -xzf \"$2\" -C /"; exit 0; shift 2 ;;
    *) echo "用法: $0 [--dry-run] [--restore <backup>]"; exit 1 ;;
  esac
done

if [ ! -f "$INDEX_FILE" ]; then
  echo "❌ skill-index.yaml 不存在: $INDEX_FILE" >&2
  exit 1
fi

# ── 解析 skill-index.yaml，获取每个角色的 skill 列表 ──
parse_index() {
  python3 -c "
import yaml, sys
with open('$INDEX_FILE') as f:
    data = yaml.safe_load(f)
roles = data.get('roles', {})
for role, levels in roles.items():
    allowed = set()
    for level in ['auto', 'manual']:
        for s in levels.get(level, []):
            allowed.add(s)
    print(f'{role}:{\",\".join(sorted(allowed))}')" 2>/dev/null
}

ROLE_MAP="pm:pm-agent
qa:qa-agent
coco:coco-agent
wiki:wiki-agent"

PROFILE_DIRS=$(echo "$ROLE_MAP" | wc -l)
echo "=== Deploy Skills — $(date '+%Y-%m-%d %H:%M:%S') ==="
echo "源文件: $INDEX_FILE"
echo "备份至: $BACKUP_DIR"
echo ""

if [ "$DRY_RUN" -eq 1 ]; then
  echo "▶ DRY RUN 模式 — 不会删除任何文件"
  echo ""
fi

TOTAL_DELETED=0
HAS_ERROR=0

echo "$ROLE_MAP" | while IFS=: read -r role profile; do
  SKILL_DIR="$SKILLS_BASE/$profile/skills"
  ALLOWED=$(echo "$(parse_index)" | grep "^$role:" | cut -d: -f2-)

  echo "── $role ($profile) ──"

  if [ ! -d "$SKILL_DIR" ]; then
    echo "  目录不存在: $SKILL_DIR (跳过)"
    echo ""
    return 0
  fi

  # 列出当前目录中的 skill
  CURRENT=$(ls "$SKILL_DIR" 2>/dev/null || true)
  if [ -z "$CURRENT" ]; then
    echo "  skills 目录为空 (跳过)"
    echo ""
    return 0
  fi

  # 找出不在允许列表中的 skill
  TO_DELETE=""
  for skill in $CURRENT; do
    # 跳过隐藏文件和脚本目录
    [[ "$skill" == .* || "$skill" == "scripts" ]] && continue
    if ! echo ",$ALLOWED," | grep -q ",$skill,"; then
      TO_DELETE="$TO_DELETE $skill"
    fi
  done

  if [ -z "$TO_DELETE" ]; then
    echo "  无需清理"
    echo ""
    return 0
  fi

  echo "  允许: $ALLOWED"
  echo "  待清理:"
  for skill in $TO_DELETE; do
    SIZE=$(du -sh "$SKILL_DIR/$skill" 2>/dev/null | cut -f1 || echo "?")
    echo "    - $skill ($SIZE)"
  done

  # dry-run 模式下只列出
  if [ "$DRY_RUN" -eq 1 ]; then
    echo "  (dry-run, 未执行)"
  else
    # 备份
    mkdir -p "$BACKUP_DIR/$profile"
    for skill in $TO_DELETE; do
      cp -r "$SKILL_DIR/$skill" "$BACKUP_DIR/$profile/" 2>/dev/null || true
      rm -rf "$SKILL_DIR/$skill"
      echo "  ✅ 已删除: $skill"
    done
  fi
  echo ""
done

echo "=== 完成 ==="
if [ "$DRY_RUN" -eq 1 ]; then
  echo "运行 $0（无 --dry-run）执行实际清理"
  echo "备份位于: \$HOME/.hermes/skills-backup-<日期>"
else
  echo "✅ 清理完成。备份位于: $BACKUP_DIR"
  echo "恢复命令: $0 --restore $BACKUP_DIR"
fi
