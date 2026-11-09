#!/usr/bin/env bash
# PostToolUse(Write|Edit) 훅. 공모전 작업 공간의 스펙·산출물 파일이 바뀌면
# 자리표시와 문체 규칙을 가볍게 스캔해 경고만 낸다(차단하지 않음, exit 0).
# exit 0의 평문 stdout은 Claude에게 가지 않으므로 결과를 JSON으로 낸다:
# additionalContext는 Claude에게, systemMessage는 발견이 있을 때만 사용자에게 보인다.
# 훅 출력 상한(10,000자)을 넘지 않도록 9,000자에서 자른다.
set -u
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INPUT="$(cat)"
FILE="$(printf '%s' "$INPUT" | python3 -I -c 'import json,sys
try:
    d=json.load(sys.stdin); print(d.get("tool_input",{}).get("file_path",""))
except Exception: print("")' 2>/dev/null)"
[ -z "$FILE" ] && exit 0
case "$FILE" in
  *.md|*.txt) ;;
  *) exit 0 ;;
esac
found=0
case "$FILE" in
  */50-deliverables/*)
    P="$(python3 -I "$HERE/scan_placeholders.py" "$FILE" --allow 가정,예시값 2>/dev/null)" || found=1
    S="$(python3 -I "$HERE/check_style.py" "$FILE" --genre body 2>/dev/null)" || found=1
    MSG="[contest 훅] 산출물 변경 감지: $FILE
$(printf '%s\n' "$P" | tail -n 6)
$(printf '%s\n' "$S" | head -n 12)"
    ;;
  */40-spec/*)
    P="$(python3 -I "$HERE/scan_placeholders.py" "$FILE" --allow 가정,예시값,확인 2>/dev/null)" || found=1
    MSG="[contest 훅] 스펙 변경 감지: $FILE (자리표시만 점검)
$(printf '%s\n' "$P" | tail -n 3)"
    ;;
  *) exit 0 ;;
esac
printf '%s' "$MSG" | python3 -I -c 'import json,sys
msg=sys.stdin.read()[:9000]; out={"hookSpecificOutput": {"hookEventName": "PostToolUse", "additionalContext": msg}}
if sys.argv[1] == "1": out["systemMessage"] = msg
print(json.dumps(out, ensure_ascii=False))' "$found"
exit 0
