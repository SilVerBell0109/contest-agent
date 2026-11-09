#!/usr/bin/env bash
# PostToolUse(Write|Edit) 훅. 공모전 작업 공간의 스펙·산출물 파일이 바뀌면
# 자리표시와 문체 규칙을 가볍게 스캔해 경고만 낸다(차단하지 않음, exit 0).
set -u
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INPUT="$(cat)"
FILE="$(printf '%s' "$INPUT" | python3 -c 'import json,sys
try:
    d=json.load(sys.stdin); print(d.get("tool_input",{}).get("file_path",""))
except Exception: print("")' 2>/dev/null)"
[ -z "$FILE" ] && exit 0
case "$FILE" in
  *.md|*.txt) ;;
  *) exit 0 ;;
esac
case "$FILE" in
  */50-deliverables/*)
    echo "[contest 훅] 산출물 변경 감지: $FILE"
    python3 -I "$HERE/scan_placeholders.py" "$FILE" --allow 가정,예시값 2>/dev/null | tail -n 6
    python3 -I "$HERE/check_style.py" "$FILE" --genre body 2>/dev/null | head -n 12
    ;;
  */40-spec/*)
    echo "[contest 훅] 스펙 변경 감지: $FILE (자리표시만 점검)"
    python3 -I "$HERE/scan_placeholders.py" "$FILE" --allow 가정,예시값,확인 2>/dev/null | tail -n 3
    ;;
esac
exit 0
