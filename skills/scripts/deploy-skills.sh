#!/usr/bin/env bash
# deploy-skills.sh — 按 skill-index.yaml 清理 agent profile 的过期 skill
# 用法:
#   bash deploy-skills.sh                 → 列出待删 skill + 提示确认后备份删除
#   bash deploy-skills.sh --dry-run       → 只列出要删的，不下手
#   bash deploy-skills.sh --index path    → 自定义 skill-index.yaml 路径
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
DEFAULT_INDEX="$SCRIPT_DIR/../skill-index.yaml"
DRY_RUN=0
INDEX_FILE="$DEFAULT_INDEX"
BACKUP_DIR="$HOME/.hermes/skills-backup-$(date +%Y%m%d)"
PROFILES_DIR="$HOME/.hermes/profiles"

# $HOME 可能被 profile 路径覆盖
if [ ! -d "$PROFILES_DIR" ]; then
  REAL_HOME=$(python3 -c "import pwd, os; print(pwd.getpwuid(os.getuid()).pw_dir)" 2>/dev/null || echo "/home/$USER")
  PROFILES_DIR="$REAL_HOME/.hermes/profiles"
  BACKUP_DIR="$REAL_HOME/.hermes/skills-backup-$(date +%Y%m%d)"
fi

while [ $# -gt 0 ]; do
  case "$1" in
    --dry-run) DRY_RUN=1; shift ;;
    --index) INDEX_FILE="$2"; shift 2 ;;
    --add-skill)
      SKILL_NAME="$2"
      shift 2
      echo "→ 代理到 deploy-skill.sh --add --skill $SKILL_NAME --apply"
      exec bash "$SCRIPT_DIR/deploy-skill.sh" --add --skill "$SKILL_NAME" --apply
      ;;
    *) echo "未知参数: $1"; echo "用法: $0 [--dry-run] [--index path] [--add-skill name]"; exit 1 ;;
  esac
done

[ -f "$INDEX_FILE" ] || { echo "索引不存在: $INDEX_FILE"; exit 1; }
[ -d "$PROFILES_DIR" ] || { echo "profiles 不存在: $PROFILES_DIR"; exit 1; }

# 获取角色的允许 skill（auto+manual）
get_allowed() {
  python3 -c "
import yaml, json
with open('$INDEX_FILE') as f:
    d = yaml.safe_load(f)
try:
    a = set(d['roles']['$1'].get('auto',[]) or [])
    m = set(d['roles']['$1'].get('manual',[]) or [])
    print(json.dumps(sorted(a|m), ensure_ascii=False))
except: print(json.dumps([]))
" 2>/dev/null
}

# 扫描 skill 目录（支持 category/skill 嵌套）
scan_skills() {
  local base="$1"
  for d in "$base"/*/; do
    [ -d "$d" ] || continue
    local name=$(basename "$d")
    [ -f "$d/SKILL.md" ] || [ -d "$d" ] || continue
    # 是否有子 skill 目录
    local has_sub=0
    for sub in "$d"/*/; do
      [ -d "$sub" ] && [ -f "$sub/SKILL.md" ] && { has_sub=1; break; }
    done
    if [ "$has_sub" -eq 1 ]; then
      for sub in "$d"/*/; do
        [ -d "$sub" ] || continue
        local sname=$(basename "$sub")
        echo "${name}/${sname}"
      done
    else
      echo "$name"
    fi
  done | sort
}

echo "=========================================="
echo " deploy-skills.sh — Skill 清理"
echo "=========================================="
echo ""
echo "索引:    $INDEX_FILE"
echo "备份:    $BACKUP_DIR"
echo "模式:    $([ "$DRY_RUN" -eq 1 ] && echo 'DRY RUN' || echo '需确认后执行')"
echo ""

TOTAL_DEL=0
TOTAL_KEEP=0
TO_DELETE=()

for profile_dir in "$PROFILES_DIR"/*/; do
  [ -d "$profile_dir" ] || continue
  agent=$(basename "$profile_dir")
  skills_dir="$profile_dir/skills"
  [ -d "$skills_dir" ] || { echo "  $agent: 无 skills"; echo ""; continue; }

  role="${agent%-agent}"
  allowed=$(get_allowed "$role")
  ac=$(echo "$allowed" | python3 -c "import sys,json; print(len(json.load(sys.stdin)))" 2>/dev/null || echo 0)
  an=$(echo "$allowed" | python3 -c "import sys,json; print(', '.join(json.load(sys.stdin)))" 2>/dev/null || echo 无)

  echo "── $agent ($role) ──"
  echo "  允许: $ac → $an"
  echo ""

  while IFS= read -r skill_path_name; do
    [ -z "$skill_path_name" ] && continue
    # 确定文件系统路径
    if [[ "$skill_path_name" == */* ]]; then
      fs_path="$skills_dir/$skill_path_name"
    else
      fs_path="$skills_dir/$skill_path_name"
    fi
    # 叶子名用于匹配 allowed 列表
    leaf="${skill_path_name##*/}"

    is_ok=$(echo "$allowed" | python3 -c "
import sys,json
a=set(json.load(sys.stdin))
print('yes' if '$leaf' in a else 'no')
" 2>/dev/null)

    if [ "$is_ok" = "yes" ]; then
      echo "    OK  $skill_path_name"
      TOTAL_KEEP=$((TOTAL_KEEP + 1))
    else
      echo "    DEL $skill_path_name"
      echo "        → $BACKUP_DIR/${agent}/${skill_path_name}"
      TOTAL_DEL=$((TOTAL_DEL + 1))
      TO_DELETE+=("${agent}:${skill_path_name}:${fs_path}")
    fi
  done < <(scan_skills "$skills_dir")
  echo ""
done

echo "=========================================="
echo " 汇总: 保留 $TOTAL_KEEP / 删除 $TOTAL_DEL"
echo ""

[ "$TOTAL_DEL" -eq 0 ] && { echo "无需清理"; exit 0; }

if [ "$DRY_RUN" -eq 1 ]; then
  echo "DRY RUN — 人工审批后执行: bash $0"
  echo "备份路径: $BACKUP_DIR"
  exit 0
fi

read -r -p "确认删除 $TOTAL_DEL 个? (y/N): " CONFIRM
[ "$CONFIRM" != "y" ] && [ "$CONFIRM" != "Y" ] && { echo "取消"; exit 0; }

echo ""
for entry in "${TO_DELETE[@]}"; do
  IFS=':' read -r ag sk fp <<< "$entry"
  target="$BACKUP_DIR/${ag}/${sk}"
  echo "  cp $fp → $target"
  mkdir -p "$(dirname "$target")"
  cp -r "$fp" "$target"
  rm -rf "$fp"
done

echo ""
echo "完成。备份: $BACKUP_DIR"
