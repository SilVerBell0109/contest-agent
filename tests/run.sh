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
printf 'TBD입니다\nTODO로 남김\nXXX님께 보냄\n' > "$sp/tbd.md"
if scanp "$sp/tbd.md" 2>&1 | grep -q '합계 3건'; then echo "ok   scan_placeholders flags TODO/TBD/XXX before a Korean particle"; else echo "FAIL scan_placeholders missed TODO/TBD/XXX before a Korean particle"; fail=1; fi
printf '실행은 `main()`으로 합니다.\n\n```json\n{"args": [], "run": "start()"}\n```\n\nloadConfig() 뒤에 시작합니다.\n' > "$sp/code.md"; expect 0 scanp "$sp/code.md"
printf '이름( )\n연락처 ()\n' > "$sp/paren.md"
if scanp "$sp/paren.md" 2>&1 | grep -q '합계 2건'; then echo "ok   scan_placeholders still flags empty ( ) in prose"; else echo "FAIL scan_placeholders missed an empty ( ) in prose"; fail=1; fi
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
cs=$(mktemp -d); cst() { python3 -I $S/check_style.py "$@"; }
printf '| 기능 | 기존 | 제안 |\n|---|---|---|\n| 오프라인 | ✅ | ❌ |\n' > "$cs/form.md"; expect 0 cst "$cs/form.md" --genre form
printf '❶ 문제 ❷ 해결 ❸ 효과\n' > "$cs/slides.md"; expect 0 cst "$cs/slides.md" --genre slides
printf '검증 결과 ✅ 통과입니다.\n' > "$cs/body.md"; expect 1 cst "$cs/body.md" --genre body
printf '🚀 출시 계획\n' > "$cs/rocket.md"; expect 1 cst "$cs/rocket.md" --genre slides
printf '이것은 사과입니다. 저것은 배입니다. 그것은 감입니다. 여기는 집입니다. 거기는 학교입니다. 저기는 공원입니다.\n' > "$cs/rhythm.md"
out=$(cst "$cs/rhythm.md" --genre body --strict 2>&1); rc=$?
if [ $rc -eq 1 ] && printf '%s\n' "$out" | grep -qF "리듬: '~니다.' 연속 6"; then echo "ok   (1) rhythm counts every '~니다.' ending, not only '~습니다.'"; else echo "FAIL (got $rc) rhythm missed six '~입니다.' endings"; fail=1; fi
rm -rf "$cs"
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
printf '| E120 | 참가 인원 | 미정 | 출처 | 2026-11-05 | 2026-11-05 | ✅ |\n' > "$tn/ev.md"
printf '| E001 | 모집 | 300명 | 출처 | 2026-10-01 | 2026-11-05 | ✅ |\n' > "$tn/ev2.md"
t() { printf '%s\n' "$2" > "$tn/$1.md"; }
t eid '참가 인원은 120명입니다.';           expect 1 tnum "$tn/eid.md" --against "$tn/ev.md"
t date '모집은 11명입니다.';                expect 1 tnum "$tn/date.md" --against "$tn/ev.md"
t comma '참가자는 2,000명입니다.';          expect 1 tnum "$tn/comma.md" --against "$tn/ev.md"
t unit '예산은 2025억 원입니다.';           expect 1 tnum "$tn/unit.md" --against "$tn/ev.md"
t hangul '공시는 총525건입니다.';           expect 1 tnum "$tn/hangul.md" --against "$tn/ev.md"
t dotted '2026.11.09 기준으로 정리했습니다.'; expect 0 tnum "$tn/dotted.md" --against "$tn/ev.md"
t kdate '2026년 10월 1일 300명 모집, 제12회 대회.'; expect 0 tnum "$tn/kdate.md" --against "$tn/ev2.md"
tgrep() { local want=$1 msg=$2; shift 2; if tnum "$@" 2>&1 | grep -q "미추적 ${want}개"; then echo "ok   trace_numbers $msg"; else echo "FAIL trace_numbers $msg (want 미추적 ${want}개)"; fail=1; fi; }
printf '근거는 E120에 있습니다.\n발표는 11월 5일입니다.\n기사: https://news.example.com/2025/11/25/a\n' > "$tn/ev3.md"
t eidp '참가 인원은 120명이고 5명이 발표하며 25명을 뽑습니다.'
tgrep 3 "ignores E120에, 11월 5일 and URL digits in --against" "$tn/eidp.md" --against "$tn/ev3.md"
cp templates/PRD.md templates/SRS.md "$tn/"
t spec '처리 시간이 10% 줄고 12명이 평균 4.2점을 줬습니다.'
tgrep 3 "ignores PRD/SRS structure numbers (headings, §, IDs, versions, paths)" "$tn/spec.md" --against "$tn/ev.md" "$tn/PRD.md" "$tn/SRS.md"
t units '시장 규모는 12조 원, 매장은 35곳, 대상은 40가구입니다.'; tgrep 3 "extracts 조·곳·가구" "$tn/units.md" --against "$tn/ev.md"
t signs '전년 대비 -15%, 목표는 20-30%입니다.';                tgrep 2 "extracts -15% and the top of 20-30%" "$tn/signs.md" --against "$tn/ev.md"
t jeom '경제 100조 원 규모이고 실제 3회 시연했습니다.';          tgrep 2 "keeps numbers after 경제/실제 (제N회 only as a word)" "$tn/jeom.md" --against "$tn/ev.md"
t age '20대·30대 직장인과 1인 가구가 주 사용자입니다.';          expect 0 tnum "$tn/age.md" --against "$tn/ev.md"
expect 1 tnum "$tn/dotted.md" "$tn/eid.md" --against "$tn/ev.md"
expect 2 tnum "$tn/eid.md" "$tn/none.md" --against "$tn/ev.md"
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
hits=$(grep -rnE '/humanize(-scan)? <' skills agents references/deliverables.md)
if [ -z "$hits" ]; then echo "ok   im-not-ai is reached through the Skill tool, not slash commands"; else echo "FAIL slash commands the model cannot invoke:"; echo "$hits"; fail=1; fi
hits=$(for s in $(grep -lE '\$[0-9]' skills/*/SKILL.md); do grep -q '\$ARGUMENTS' "$s" || echo "  $s: uses \$0 but never \$ARGUMENTS"; done; grep -n '나머지 `\$ARGUMENTS`' skills/*/SKILL.md)
if [ -z "$hits" ]; then echo "ok   skills with \$0 also read the whole \$ARGUMENTS"; else echo "FAIL flags would be dropped (\$ARGUMENTS is the whole string):"; echo "$hits"; fail=1; fi
hits=$(grep -n '/contest:init' skills/*/SKILL.md | grep -vE '^skills/(init|help)/' | grep -v '안내')
if [ -z "$hits" ]; then echo "ok   other skills only tell the user to run /contest:init"; else echo "FAIL /contest:init is user-only (disable-model-invocation):"; echo "$hits"; fail=1; fi
hits=$(for s in skills/*/SKILL.md; do n=$(basename "$(dirname "$s")"); [ "$n" = help ] && continue
  row=$(grep "^| \`/contest:$n" skills/help/SKILL.md)
  for f in $(sed -n 's/^argument-hint: //p' "$s" | grep -oE -- '--[a-z-]+' | sort -u); do printf '%s\n' "$row" | grep -qF -- "$f" || echo "  /contest:$n row lacks $f"; done
done)
if [ -z "$hits" ]; then echo "ok   help lists every flag of each argument-hint"; else echo "FAIL help table misses flags:"; echo "$hits"; fail=1; fi
hits=$(for s in skills/*/SKILL.md; do at=$(sed -n 's/^allowed-tools: //p' "$s")
  for x in $(grep -oE 'python3 -I \$\{CLAUDE_PLUGIN_ROOT\}/scripts/[a-z_]+\.py' "$s" | sed 's|.*/||' | sort -u); do
    printf '%s\n' "$at" | grep -qF "Bash(python3 -I \${CLAUDE_PLUGIN_ROOT}/scripts/$x *)" || echo "  $s: runs $x without a matching allowed-tools rule"; done
  for x in count_chars trace_numbers scan_placeholders; do grep -q "$x" "$s" && ! grep -q "python3 -I \${CLAUDE_PLUGIN_ROOT}/scripts/$x.py" "$s" && echo "  $s: names $x without its command"; done
done)
if [ -z "$hits" ]; then echo "ok   skills give script commands with matching allowed-tools rules"; else echo "FAIL script commands:"; echo "$hits"; fail=1; fi
hits=$( { grep -rn '승인: <날짜> <사용자 문구>' agents skills; grep -rn '승인 표시' agents skills; grep -n 'mvp-plan\.md' agents/*.md skills/*/SKILL.md
  for f in skills/spec/SKILL.md skills/make/SKILL.md agents/mvp-builder.md; do grep -q '`승인: <날짜> "<사용자 문구>"`' "$f" || echo "  $f: approval line differs from spec"; done; } )
if [ -z "$hits" ]; then echo "ok   one approval line format; mvp-builder reads the versioned mvp-plan file"; else echo "FAIL approval line or mvp-plan path:"; echo "$hits"; fail=1; fi
hits=$(for a in agents/*.md; do sed -n 's/^description: //p' "$a" | grep -E 'proactively|반드시|에도 사용' | grep -vq 'contest 작업 공간' && echo "  $a"; done)
if [ -z "$hits" ]; then echo "ok   auto-triggering agent descriptions are scoped to contest workspaces"; else echo "FAIL agent descriptions that trigger outside a contest workspace:"; echo "$hits"; fail=1; fi
hits=$(grep -rnE '4~6개|심사 기준 배점, 주최사 빈틈|여덟 단계\)' skills agents; for f in skills/topics/SKILL.md agents/topic-strategist.md; do grep -q '추천 1·차선 1' "$f" || echo "  $f: no 추천 1·차선 1 for the field choice"; done)
if [ -z "$hits" ]; then echo "ok   topics follow topic-selection.md (field criteria, 5~6 conditions)"; else echo "FAIL topics differ from references/topic-selection.md:"; echo "$hits"; fail=1; fi
if [ "$(grep -c -- '--only' skills/research/SKILL.md)" -ge 2 ]; then echo "ok   research says what --only does"; else echo "FAIL research takes --only but never handles it"; fail=1; fi
hits=$(for tok in $(grep -ohE '\{\{[A-Z_]+\}\}' $(ls templates/*.md | grep -vE '/(CONTEST|CLAUDE\.workspace)\.md$') | sort -u); do grep -qF "$tok" skills/make/SKILL.md || echo "  $tok"; done)
if [ -z "$hits" ]; then echo "ok   make fills the {{ }} that scaffold leaves in later templates"; else echo "FAIL make never says how to fill:"; echo "$hits"; fail=1; fi
if python3 -I -c 'import json,sys; m=json.load(open(".claude-plugin/marketplace.json", encoding="utf-8")); sys.exit(0 if m.get("description") and all("version" not in p for p in m["plugins"]) else 1)'; then echo "ok   marketplace has a description; version lives only in plugin.json"; else echo "FAIL marketplace.json needs a top-level description and no plugins[].version (plugin.json wins silently)"; fail=1; fi
if [ "$(tail -n 1 LICENSE)" = "SOFTWARE." ]; then echo "ok   LICENSE is the bare MIT text"; else echo "FAIL LICENSE has text after the MIT body (GitHub then shows Other)"; fail=1; fi
hits=$(for w in 'gh auth setup-git' 'CLAUDE_CODE_PLUGIN_PREFER_HTTPS=1' 'claude plugin update contest@contest-agent' 'pbakaus/impeccable(Apache License 2.0)' 'playbook.md' 'Read(~/.claude/plugins/cache/contest-agent/**)' 'Read(~/.claude/plugins/data/contest-contest-agent/**)'; do grep -qF -- "$w" README.md || echo "  README lacks: $w"; done)
if [ -z "$hits" ]; then echo "ok   README covers private install, updates, read permissions, external licenses, local-only playbook"; else echo "FAIL README:"; echo "$hits"; fail=1; fi
hits=$(for f in agents/fact-checker.md skills/verify/SKILL.md; do grep -qF '`40-spec/PRD.md`면 `--against 30-refine/evidence.md`만' "$f" && grep -qF '`40-spec/SRS.md`면 `--against 30-refine/evidence.md 40-spec/PRD.md`' "$f" || echo "  $f"; done)
if [ -z "$hits" ]; then echo "ok   PRD and SRS are not traced against each other"; else echo "FAIL PRD and SRS would trace their numbers through each other:"; echo "$hits"; fail=1; fi
hits=$( { grep -qF '슬라이드·발표대본 → **contest:deck-builder**' skills/make/SKILL.md && echo "  skills/make: step 1 hands slides to deck-builder before 2~4"
  grep -E '^- `슬라이드`' skills/make/SKILL.md | grep -qF '2(사실 검증)·3(문체)·4(검수)를 outline.md에 실행' || echo "  skills/make: slides reach deck-builder unchecked"
  grep -qF '`.pptx`' skills/verify/SKILL.md || echo "  skills/verify: runs the text scripts on .pptx"; } )
if [ -z "$hits" ]; then echo "ok   slides are checked as outline.md before deck-builder; verify skips binaries"; else echo "FAIL slide checks would run on a .pptx:"; echo "$hits"; fail=1; fi
scan1='python3 -I ${CLAUDE_PLUGIN_ROOT}/scripts/scan_placeholders.py 10-research/brief.md 10-research/org.md 10-research/domain.md 10-research/competitors.md 10-research/users.md --allow 가정,예시값,확인,자리표시'
hits=$( for f in skills/status/SKILL.md skills/research/SKILL.md; do grep -qF -- "\`$scan1\`" "$f" || echo "  $f: stage-1 scan is not the shared 5-file command with 자리표시 allowed"; done
  grep -qF '`10-research/`·`40-spec/`·`50-deliverables/` 문서와 CONTEST.md의 `【 】`' skills/status/SKILL.md || echo "  skills/status: 【 】 count skips 10-research/ and CONTEST.md" )
if [ -z "$hits" ]; then echo "ok   stage 1 allows the user's 【 】 and status/research scan the same files"; else echo "FAIL stage 1 can never pass (users.md must keep 【 】):"; echo "$hits"; fail=1; fi
u1=$(mktemp -d); printf '# 사용자\n- 팀원 경험: 【 】\n- 월 10명 [가정]\n' > "$u1/users.md"; expect 1 scanp "$u1/users.md" --allow 가정,예시값,확인; expect 0 scanp "$u1/users.md" --allow 가정,예시값,확인,자리표시; rm -rf "$u1"
if grep -qF '사용자 담당 ❌만 남으면 그 목록(위치 포함)을 보고하고 멈춘다' skills/make/SKILL.md && ! grep -qF '❌가 있으면 1로 돌아간다' skills/make/SKILL.md; then echo "ok   make stops on user-owned ❌ instead of looping"; else echo "FAIL make would loop forever on ❌ only the user can fix (【 】, 서명)"; fail=1; fi
g2=$(awk '/^## 관문 2 —/{f=1;print;next} /^## /{f=0} f' skills/refine/SKILL.md)
hits=$(for w in '문제 크기' '여기서만 되는 기능' '범위 경계' '성공 기준 표' 'process.md' 'CONTEST.md 관문 2 행 비고'; do printf '%s\n' "$g2" | grep -qF -- "$w" || echo "  관문 2 lacks: $w"; done)
if [ -z "$hits" ]; then echo "ok   refine 관문 2 checks the four process.md §2 items"; else echo "FAIL refine 관문 2 differs from references/process.md §2 and CONTEST.md:"; echo "$hits"; fail=1; fi
rows=$(awk '/^### 후보 A/{f=1;next} /^### /{f=0} f && /^\| / && !/^\| 항목 / && !/^\|---/' templates/topics.md | sed -e 's/^| //' -e 's/ *|.*$//' -e 's/ *(.*$//')
hits=$( [ "$(printf '%s\n' "$rows" | grep -c .)" -eq 11 ] || echo "  templates/topics.md §1 card no longer has 11 rows"
  printf '%s\n' "$rows" | while IFS= read -r r; do grep -qF -- "$r" agents/topic-strategist.md || echo "  topic-strategist lacks: $r"; done
  grep -n '한 줄 정의 / 사용자와 장면' agents/topic-strategist.md )
if [ -z "$hits" ]; then echo "ok   topic-strategist writes the 11-row card of templates/topics.md §1"; else echo "FAIL topic-strategist card differs from templates/topics.md §1:"; echo "$hits"; fail=1; fi
[ $fail -eq 0 ] && echo "ALL OK" || { echo "SOME FAILED"; exit 1; }
