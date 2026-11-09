#!/usr/bin/env bash
# 스크립트 회귀 테스트. 기대 exit 코드가 다르면 실패로 끝난다.
set -u
cd "$(dirname "$0")/.."
S=scripts; T=tests/samples; fail=0
expect() { local want=$1; shift; "$@" >/dev/null 2>&1; local got=$?; if [ "$got" -eq "$want" ]; then echo "ok   ($got) $*"; else echo "FAIL (got $got, want $want) $*"; fail=1; fi; }
expect 1 python3 -I $S/scan_placeholders.py $T/placeholders-and-ai-style.md --plain
expect 0 python3 -I $S/scan_placeholders.py $T/clean-body.txt --plain
sp=$(mktemp -d); scanp() { python3 -I $S/scan_placeholders.py "$@"; }
printf '# {{NAME}} 제안서\n작성일 {{DATE}}\n' > "$sp/var.md";                expect 1 scanp "$sp/var.md"
printf -- '- [ ] 요강 확인\n* [ ] 양식\n+ [ ] 첨부\n1. [ ] 서명\n10) [ ] 제출\n  - [ ] 들여쓴 항목\n' > "$sp/box.md"
expect 0 scanp "$sp/box.md"
expect 1 scanp "$sp/box.md" --plain
printf '값: [ ]\n[ ]\n배열 []\n' > "$sp/empty.md";                             expect 1 scanp "$sp/empty.md"
out=$(scanp "$sp/empty.md" 2>&1)
if echo "$out" | grep -q '합계 3건'; then echo "ok   scan_placeholders flags all 3 empty brackets"; else echo "FAIL scan_placeholders missed an empty bracket"; fail=1; fi
expect 2 scanp "$T/clean-body.txt" "$sp/none.md"
expect 2 scanp "$T/clean-body.txt" --allow
rm -rf "$sp"
expect 1 python3 -I $S/check_style.py $T/placeholders-and-ai-style.md --genre body
expect 0 python3 -I $S/check_style.py $T/clean-body.txt --genre body
expect 0 python3 -I $S/check_style.py $T/clean-body.txt --genre body --strict
s2=$(mktemp); printf '이 계획에 대한 설명입니다.\n예산에 대한 근거를 적습니다.\n일정에 대한 표를 붙입니다.\n' > "$s2"
expect 0 python3 -I $S/check_style.py "$s2" --genre body
out=$(python3 -I $S/check_style.py "$s2" --genre body --strict 2>&1); rc=$?
if [ $rc -eq 1 ] && echo "$out" | grep -q "실패" && ! echo "$out" | grep -q Traceback; then echo "ok   (1) --strict fails on S2 x3 without crashing"; else echo "FAIL (got $rc) --strict on S2 x3"; fail=1; fi
rm -f "$s2"
expect 2 python3 -I $S/check_style.py $T/clean-body.txt --genre essay
expect 2 python3 -I $S/check_style.py $T/clean-body.txt --genre
expect 2 python3 -I $S/check_style.py $T/no-such-file.md
expect 1 python3 -I $S/count_chars.py $T/clean-body.txt --limit 100
expect 0 python3 -I $S/count_chars.py $T/clean-body.txt --limit 5000
cntc() { python3 -I $S/count_chars.py "$@"; }
expect 0 cntc $T/clean-body.txt --limit 5,000
expect 0 cntc $T/clean-body.txt --limit '5,000자 이내'
expect 2 cntc $T/clean-body.txt --limit 1만자
expect 2 cntc $T/clean-body.txt --limit
expect 2 cntc $T/clean-body.txt --limt 5000
expect 2 cntc --limit 5000 $T/clean-body.txt
expect 2 cntc $T/no-such-file.txt --limit 5000
cm=$(mktemp -d); printf '머리말\n[본문]\n가나다\n[끝]\n꼬리말이 아주 깁니다\n' > "$cm/m.txt"
if cntc "$cm/m.txt" --start '[본문]' --end '[끝]' | grep -q '공백 포함 *: 3자'; then echo "ok   count_chars counts only between the markers"; else echo "FAIL count_chars counted outside the markers"; fail=1; fi
expect 2 cntc "$cm/m.txt" --start '[없는 표식]'
expect 2 cntc "$cm/m.txt" --start '[본문]' --end '[없는 끝]'
rm -rf "$cm"
expect 1 python3 -I $S/trace_numbers.py $T/numbers.md --against $T/evidence.md
expect 0 python3 -I $S/trace_numbers.py $T/numbers.md --against $T/evidence.md --warn
tn=$(mktemp -d); tnum() { python3 -I $S/trace_numbers.py "$@"; }
printf '| E037 | 참가 인원 | 미정 | 출처 | 2026-11-05 | 2026-11-05 | ✅ |\n' > "$tn/ev.md"
printf '| E001 | 모집 | 300명 | 출처 | 2026-10-01 | 2026-11-05 | ✅ |\n' > "$tn/ev2.md"
t() { printf '%s\n' "$2" > "$tn/$1.md"; }
t eid '참가 인원은 37명입니다.';            expect 1 tnum "$tn/eid.md" --against "$tn/ev.md"
t date '모집은 11명입니다.';                expect 1 tnum "$tn/date.md" --against "$tn/ev.md"
t comma '참가자는 2,000명입니다.';          expect 1 tnum "$tn/comma.md" --against "$tn/ev.md"
t unit '예산은 2025억 원입니다.';           expect 1 tnum "$tn/unit.md" --against "$tn/ev.md"
t hangul '공시는 총525건입니다.';           expect 1 tnum "$tn/hangul.md" --against "$tn/ev.md"
t dotted '2026.11.09 기준으로 정리했습니다.'; expect 0 tnum "$tn/dotted.md" --against "$tn/ev.md"
t kdate '2026년 10월 1일 300명 모집, 제12회 대회.'; expect 0 tnum "$tn/kdate.md" --against "$tn/ev2.md"
expect 1 tnum "$tn/eid.md" --against "$tn/eid.md"
out=$(tnum "$tn/eid.md" --against "$tn/ev.md" "$tn/none.md" 2>&1)
if echo "$out" | grep -q "대조 파일 없음"; then echo "ok   trace_numbers warns on a missing --against file"; else echo "FAIL trace_numbers silent on a missing --against file"; fail=1; fi
expect 2 tnum "$tn/none.md" --against "$tn/ev.md"
rm -rf "$tn"
tmp=$(mktemp -d); mkdir -p "$tmp/50-deliverables"; cp $T/placeholders-and-ai-style.md "$tmp/50-deliverables/x.md"
out=$(echo "{\"tool_input\":{\"file_path\":\"$tmp/50-deliverables/x.md\"}}" | CLAUDE_PLUGIN_ROOT=$PWD bash $S/post_write_check.sh); rc=$?
if [ $rc -eq 0 ] && echo "$out" | grep -q "자리표시"; then echo "ok   (0) hook warns"; else echo "FAIL hook"; fail=1; fi
if echo "$out" | python3 -I -c 'import json,sys; d=json.load(sys.stdin); sys.exit(not ("자리표시" in d["hookSpecificOutput"]["additionalContext"] and d.get("systemMessage")))' 2>/dev/null; then echo "ok   hook JSON reaches Claude and user"; else echo "FAIL hook JSON (additionalContext/systemMessage)"; fail=1; fi
cp $T/clean-body.txt "$tmp/50-deliverables/ok.md"
out=$(echo "{\"tool_input\":{\"file_path\":\"$tmp/50-deliverables/ok.md\"}}" | bash $S/post_write_check.sh); rc=$?
if [ $rc -eq 0 ] && echo "$out" | python3 -I -c 'import json,sys; d=json.load(sys.stdin); sys.exit("systemMessage" in d)' 2>/dev/null; then echo "ok   (0) hook silent to user when clean"; else echo "FAIL hook clean"; fail=1; fi
rm -rf "$tmp"
sc=$(mktemp -d); for t in dev idea ad application program; do expect 0 python3 -I $S/scaffold.py "$sc/$t" --type $t --templates templates; done
if grep -rq "{{" "$sc"; then echo "FAIL template braces left"; fail=1; else echo "ok   no {{ }} left after scaffold"; fi
if grep -rq "템플릿 없음" "$sc"; then echo "FAIL scaffold wrote a stub for a missing template"; fail=1; else echo "ok   every scaffolded file came from a template"; fi
empty=$(mktemp -d); expect 2 python3 -I $S/scaffold.py "$sc/no-tpl" --type idea --templates "$empty"
if [ -e "$sc/no-tpl" ]; then echo "FAIL scaffold created a folder despite missing templates"; fail=1; else echo "ok   missing templates stop before creating anything"; fi
rmdir "$empty"
expect 2 python3 -I $S/scaffold.py "$sc/x" --type
expect 2 python3 -I $S/scaffold.py "$sc/x" --bogus
here=$PWD; ( cd "$sc" && python3 -I "$here/$S/scaffold.py" --type idea >/dev/null 2>&1 ); rc=$?
if [ $rc -eq 2 ] && [ ! -e "$sc/--type" ]; then echo "ok   (2) an option is not taken as the folder name"; else echo "FAIL (got $rc, want 2) scaffold took an option as the folder name"; fail=1; fi
expect 1 python3 -I $S/scaffold.py "$sc/dev" --type dev --templates templates
rm -rf "$sc"
names=$(ls agents | sed 's/\.md$//' | paste -sd'|' -)
hits=$(grep -rnoE "(^|[^:a-z-])($names)([^a-z-]|$)" skills)
if [ -z "$hits" ]; then echo "ok   skills name agents as contest:<agent>"; else echo "FAIL agent names without the contest: prefix:"; echo "$hits"; fail=1; fi
hits=$(grep -rnoE '(^|[^/}A-Za-z_-])(references|templates|scripts)/' agents skills)
if [ -z "$hits" ]; then echo "ok   agents and skills reach plugin files through \${CLAUDE_PLUGIN_ROOT}"; else echo "FAIL relative plugin paths (they resolve against the workspace):"; echo "$hits"; fail=1; fi
hits=$(for a in $(grep -L '^tools:.*Write' agents/*.md); do
  grep -q '최종 응답' "$a" || echo "  $a: no Write tool and no 최종 응답 contract"
  n=$(basename "$a" .md)
  for s in $(grep -l "contest:$n" skills/*/SKILL.md); do grep -q '응답 전문' "$s" || echo "  $s: calls contest:$n but never saves its 응답 전문"; done
done)
if [ -z "$hits" ]; then echo "ok   read-only agents answer in full and their callers save it"; else echo "FAIL read-only agent output would be lost:"; echo "$hits"; fail=1; fi
hits=$(for a in $(grep -lE 'impeccable|humanize' agents/*.md); do grep -q '^tools:.*Skill' "$a" || echo "  $a"; done)
if [ -z "$hits" ]; then echo "ok   agents that use external skills have the Skill tool"; else echo "FAIL agents told to use external skills lack the Skill tool:"; echo "$hits"; fail=1; fi
hits=$(grep -lE '^(permissionMode|hooks|mcpServers):' agents/*.md | sed 's/^/  /')
if [ -z "$hits" ]; then echo "ok   no frontmatter that plugin agents ignore"; else echo "FAIL plugin agents ignore permissionMode/hooks/mcpServers:"; echo "$hits"; fail=1; fi
[ $fail -eq 0 ] && echo "ALL OK" || { echo "SOME FAILED"; exit 1; }
