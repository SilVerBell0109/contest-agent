#!/usr/bin/env bash
# 스크립트 회귀 테스트. 기대 exit 코드가 다르면 실패로 끝난다.
set -u
cd "$(dirname "$0")/.."
S=scripts; T=tests/samples; fail=0
expect() { local want=$1; shift; "$@" >/dev/null 2>&1; local got=$?; if [ "$got" -eq "$want" ]; then echo "ok   ($got) $*"; else echo "FAIL (got $got, want $want) $*"; fail=1; fi; }
expect 1 python3 -I $S/scan_placeholders.py $T/placeholders-and-ai-style.md --plain
expect 0 python3 -I $S/scan_placeholders.py $T/clean-body.txt --plain
expect 1 python3 -I $S/check_style.py $T/placeholders-and-ai-style.md --genre body
expect 0 python3 -I $S/check_style.py $T/clean-body.txt --genre body
expect 1 python3 -I $S/count_chars.py $T/clean-body.txt --limit 100
expect 0 python3 -I $S/count_chars.py $T/clean-body.txt --limit 5000
expect 1 python3 -I $S/trace_numbers.py $T/numbers.md --against $T/evidence.md
expect 0 python3 -I $S/trace_numbers.py $T/numbers.md --against $T/evidence.md --warn
tmp=$(mktemp -d); mkdir -p "$tmp/50-deliverables"; cp $T/placeholders-and-ai-style.md "$tmp/50-deliverables/x.md"
out=$(echo "{\"tool_input\":{\"file_path\":\"$tmp/50-deliverables/x.md\"}}" | CLAUDE_PLUGIN_ROOT=$PWD bash $S/post_write_check.sh); rc=$?
if [ $rc -eq 0 ] && echo "$out" | grep -q "자리표시"; then echo "ok   (0) hook warns"; else echo "FAIL hook"; fail=1; fi
rm -rf "$tmp"
sc=$(mktemp -d); for t in dev idea ad application program; do expect 0 python3 -I $S/scaffold.py "$sc/$t" --type $t --templates templates; done
if grep -rq "{{" "$sc"; then echo "FAIL template braces left"; fail=1; else echo "ok   no {{ }} left after scaffold"; fi
expect 1 python3 -I $S/scaffold.py "$sc/dev" --type dev --templates templates
rm -rf "$sc"
[ $fail -eq 0 ] && echo "ALL OK" || { echo "SOME FAILED"; exit 1; }
