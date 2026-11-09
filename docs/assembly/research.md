# contest 플러그인 조립·검증 기록

작업: CLAUDE_CODE_PROMPT.md 1~10단계 + plan.md §7 → GitHub 업로드 (2026-11-09 시작)
이어받을 때: 이 파일부터 읽는다. 로그·임시 파일은 작업 임시 폴더 `$J=~/.claude/jobs/a72d83da/tmp/`(커밋하지 않음)(logs/, docs/, hookfix/, e2e-brief.md, tools/summ.py)에 있었다(push 뒤 모두 삭제 — 로그·감사 원문은 이 파일의 요약만 남음). 옛 스크래치패드(/private/tmp/claude-…)는 더 쓰지 않는다. 예외: E2E 작업 공간은 `/private/tmp/contest-e2e-a72d83da` — `$J`가 보호 경로 `.claude/` 아래라 그 안에서는 쓰기가 거부된다.

## 결정(Ruling) — 틀렸을 때 비용
- 이름: 저장소 `contest-agent`, 플러그인 `contest`, 마켓플레이스 `contest-agent` — 기존 문서 전부와 일치. 바꾸면 README·plan·명령 표기 전부 수정.
- 공개 범위: **private** — references/user-criteria.md·materials/에 개인 이력과 공모전 기록이 있음. 공개하려면 `gh repo edit --visibility public` (개인정보 점검 후).
- "model = opus": 워크플로 에이전트만 opus. 플러그인 에이전트의 `model` 프런트매터는 그대로(sonnet/inherit). 바꾸려면 agents/*.md 6개 수정.
- 사용자가 "만들어서 올려 줘"라고 했으므로 형식·호환 수정은 사전 승인 없이 적용하되, 원본 기준 커밋 뒤 **수정마다 별도 커밋**(되돌리기 쉬움). 내용(규칙·사례·문장) 문제는 보고만.
- `~/Downloads/보고서_말투_가이드.md`: 복사하지 않고 마지막에 묻는다(프롬프트가 "묻고"라고 지시, 파일 권한 600 = 비공개 자산).
- 외부 플러그인(impeccable, im-not-ai): 설치하지 않고 이름·명령만 확인.
- 저장소 위치: `~/Downloads/contest-agent` 그대로.

## 단계 결과
- 1 구조 검증: **통과**. `claude plugin validate .` exit 0, 경고 3(마켓플레이스 description 없음 / 루트 CLAUDE.md는 플러그인 컨텍스트로 안 읽힘 — 의도대로 / icon 없음). JSON 3개 파싱 OK. 프런트매터 23/23 YAML 파싱·name 일치·SKILL.md 500줄 이하. 에이전트 description 합계 1,274자.
- 2 공식 문서 대조: 감사 완료(확정 66·반박 2), 수정 목록을 영역별 커밋으로 반영 중(아래 '커밋'·'다음 할 일'). 첫 실행(wf_ee3202b6-d4f)은 백그라운드 전환 지점에서 실패(완료 에이전트 0) → 임시 경로와 실측 결함을 프롬프트에 넣고 재실행 **wf_8ff2e8e5-9b7**(task wq95me1wn, opus, platform/wiring/publish + 반박 검증).
- 3 스크립트 테스트: **통과**. `bash tests/run.sh` 16/16 ok, `ALL OK`. form 장르는 sample에서 걸리던 '구조: 첫째/둘째/셋째', '장식: 마크다운 굵게 **' 2개 규칙이 꺼짐(body 10건 → form 8건, S1=2 동일). 참고: 합쇼체 전용 규칙은 없고 리듬('~습니다.' 6연속) 규칙은 장르 무관(check_style.py:76-86).
- 4 스캐폴드: **통과**. 5유형 모두 17파일·8폴더 생성, `{{` 잔재 0, 비어 있지 않은 폴더 재실행 시 exit 1 + 거부 메시지.
- 5 로드: 명령 11(contest:help…verify), 에이전트 12 — 런타임 이름은 `contest:<agent>` 네임스페이스. 훅 등록 1 확인(hook_started `PostToolUse:Write`).

## 수정 전 기준선(RED) — 깨끗한 환경: `claude -p --plugin-dir <repo> --setting-sources project --strict-mcp-config --model opus`
- 개인정보 점검(커밋 대상 92개 파일): 이메일·전화·키·주민번호·절대경로 0건. `materials/playbook.md:1045-1086`에 본인 Drive 문서 링크 55개 — materials 내용 수정 금지라 유지, private 저장소라 보고만(공개 전 Drive 공유 설정 확인 필요).
- init: `/contest:init e2e-base --type idea` → scaffold.py Bash 호출이 **권한 거부**("This command requires approval", 따옴표+`$PWD` 형태는 "Quoted text … can't be checked"). allowed-tools 패턴 `Bash(python3 ${CLAUDE_SKILL_DIR}/../../scripts/scaffold.py *)`가 본문 명령 `python3 -I "…/scaffold.py" …`과 안 맞음 → 헤드리스에선 init 실패, 대화형에선 매번 승인 프롬프트. 로그: logs/base-init.jsonl
- 훅: `50-deliverables/test.md`("드물지 않습니다"+"【기입】") Write → 훅은 실행되고 stdout에 경고 2종(자리표시 L2, S1 상투구 L1), exit 0, 저장 성공. **그러나 Claude는 "훅 메시지 없음"** — exit 0 평문 stdout은 모델에 전달되지 않음. 로그: logs/base-hook.jsonl

- status: 1단계 판정에 스캔 스크립트 명령이 본문에 없어 모델이 grep으로 대체, 플러그인 폴더 `ls` 복합 명령 1건 거부. scaffold가 `30-refine/judge-preview.md`를 빈 파일로 만든다는 관찰(템플릿 없음). 로그: logs/red-status.jsonl

## 수정 준비(사본에서 RED→GREEN 확인, 저장소 미반영)
- 훅: `$J/hookfix/` 사본에서 post_write_check.sh를 JSON 출력(`hookSpecificOutput.additionalContext` 항상 + 발견 시 `systemMessage`)으로 바꾸고 tests/run.sh에 JSON 전달·깨끗한 파일 무알림 검사 2줄 추가. RED: 새 검사 FAIL(logs/hookfix-red.txt) → GREEN: 18 ok, ALL OK(logs/hookfix-green.txt).
- init/status: allowed-tools를 `Bash(python3 -I ${CLAUDE_PLUGIN_ROOT}/scripts/<x>.py *)`로, 본문 명령을 따옴표 없는 같은 형태로 맞춘다(status는 스캔 명령을 본문에 명시).
- 스킬의 에이전트 호출 표기 `contest:` 접두(judge/make/refine/research/spec/topics/verify).
- Ruling: 훅 JSON — 평문 stdout은 exit 0에서 Claude에 안 감(hooks 문서) — 틀리면 훅 경고가 중복 표시될 뿐.
- Ruling: init/status 명령은 따옴표 없는 `${CLAUDE_PLUGIN_ROOT}` — 권한 규칙이 따옴표+변수를 검사 못 함 — 플러그인 경로에 공백이 있으면 깨짐(캐시 경로 `~/.claude/plugins/cache/...`엔 공백 없음).

- init GREEN(사본 `$J/plug`, 권한 플래그 없음): scaffold.py 단독 호출이 승인 없이 실행·작업 공간 생성. 남은 거부 2건은 모델이 명령을 `;`로 이어 붙인 것과 `ls ~/Downloads/보고서_말투_가이드.md`(작업 폴더 밖 → 헤드리스 차단, 대화형은 승인 프롬프트). 로그: logs/green-init.jsonl
- status GREEN: 스캔 스크립트를 단독 실행(승인 없음)해 1단계 판정. 이어 붙인 첫 시도 1건만 거부. 로그: logs/green-status.jsonl → 본문에 "단독으로(;·&&로 잇지 말고)" 문구 추가 예정.
- 새 결함(배선): scaffold.py LAYOUT이 `30-refine/judge-preview.md`의 템플릿으로 없는 `templates/judge-preview.md`를 찾아 "(템플릿 없음: <절대 경로>)" 빈 파일을 만든다. 실제 템플릿은 `judge-review.md`(agents/judge-simulator.md:29 "템플릿 judge-review.md 형식으로"). 사본에서 tests/run.sh에 "템플릿 없음" 검사 추가 → RED(logs/scaffold-red.txt) → scaffold.py에 `SOURCES = {"judge-preview.md": "judge-review.md"}` → GREEN 19 ok(logs/scaffold-green.txt).
- Ruling: 새 템플릿 파일을 만들지 않고 scaffold에서 이름을 잇는다 — templates/ 내용 추가는 금지 범위 — 틀리면 judge-preview.md 첫 줄 제목이 "judge-review.md"로 보이는 정도.
- 내용 관찰(보고만): status 1단계 기준 "파일 있음 + 자리표시 스캔 통과"는 손대지 않은 빈 템플릿도 통과한다(GREEN 실행에서 모델이 스스로 지적).

- 같은 방식으로 research(scan_placeholders)·refine(trace_numbers)·verify(스크립트 4종)에 `allowed-tools: Bash(python3 -I ${CLAUDE_PLUGIN_ROOT}/scripts/<x>.py *)` 추가, 본문 명령을 따옴표 없는 같은 형태로 + "단독 실행" 문구(init·status 포함). 사본 validate exit 0, tests ALL OK(logs/plug-validate.txt, plug-tests.txt). allowed-tools는 허용만 하고 제한하지 않음(skills 문서 404행).
- E2E 실행 스크립트 준비: `$J/tools/e2e.sh <플러그인 폴더>` (init → 요강 복사 → research --only brief[acceptEdits, 웹 금지] → status → 훅).

## 감사 분류(wf_8ff2e8e5-9b7) — 확정 66 · 반박 2. 원문: $J/audit-result.json, 요약: $J/audit-summary.txt, 배선: $J/audit-wiring.txt
- ID 체계: PS-nn(플랫폼 사양), W-nn(배선), DC-nn(문서·내용). 형식·배선은 고치고, 내용(규칙·사례·문장)·소유자 판단은 보고만.

## 커밋(main)
- 4190cad 원본 기준(+ .gitignore 갱신: playbook·바이너리·00-inputs 제외). `git ls-files | grep -E '\.env$|00-inputs/'` 0건.
- 84fb01d 훅 JSON 출력(additionalContext 항상, 발견 시 systemMessage, 9,000자 상한). tests 18 ok.
- 3c1bddc init: allowed-tools와 본문 명령 일치(따옴표 없는 단독 실행), 유형 미지정 시 AskUserQuestion(같은 턴) 또는 재실행 안내, 말투 가이드는 `${CLAUDE_PLUGIN_DATA}/style/user-report-tone.md`로 복사(묻고, 덮어쓰기 전 확인).
- 1e7f93a research/refine/verify/topics/status 스크립트 명령을 허용 규칙과 같은 형태로 + 단독 실행 문구, status 1단계 판정에 내용 조건(W10), 마감은 CONTEST.md 기본 정보 행(W09), verify의 humanize는 Skill 목록에 있을 때만.
- 6c6aced scaffold: judge-preview.md ← judge-review 템플릿(SOURCES), 템플릿 누락 시 폴더 만들기 전 exit 2, 옵션 값 누락·알 수 없는 옵션·옵션을 폴더명으로 준 경우 exit 2. tests 24 ok, ALL OK.
- 538a76a check_style: `--strict`가 S1 0건이면 예외로 죽던 문제(W01), `--genre` 값 검사·없는 파일 exit 2(W21). tests 30 ok.
- 5ef5c19 trace_numbers: 숫자 토큰 단위 대조, E-ID·날짜·시각·회차 제외, 자기 자신 대조 제외, 없는 대조 파일 경고, 대상 없음 exit 2(W06/W12/W17). tests 40 ok. (5dcf7ef의 메시지 테스트 수만 고쳐 amend)
- e9e4e7d scan_placeholders: 대상 파일 하나라도 없으면 exit 2(W13), `{{[A-Z_]+}}` 탐지·목록 체크박스 제외(W19), `--allow` 값 검사(W21). tests 47 ok, ALL OK.
- 8d66019 count_chars: `--limit` 5,000·5,000자·이내 허용(W20), 표식 없음·없는 파일·값 없는/알 수 없는 옵션 exit 2(W20/W21). tests 57 ok, ALL OK.
- 8ab71f8 스킬→`contest:<agent>`(PS-19), 에이전트 경로 `${CLAUDE_PLUGIN_ROOT}/…`(PS-11/13/W14), judge-simulator·fact-checker 응답 전문 반환+호출자 저장(W02/W07), 호출 프롬프트에 작업 공간 절대 경로(W14), ui-designer Skill 도구(PS-09), mvp-builder permissionMode 삭제(PS-18), refine 라운드 순서(W08/DC-12, 7번에서 당겨옴). 새 lint 5개(접두·상대 경로·읽기 전용 응답 계약·Skill 도구·무시되는 프런트매터). tests 62 ok, ALL OK, validate exit 0.
- 1b43840 run은 init 명령을 안내하고 멈춤(PS-03), judge `$ARGUMENTS`에서 `--round`·`--persona`(PS-06), make: im-not-ai를 Skill 도구로(PS-05/DC-02)·count_chars 명령+allowed-tools(PS-20)·`{{NAME}}`·승인 줄 형식 통일(W18), research `--only`(W16), topics·topic-strategist 분야 기준·조건 5~6개·추천 1·차선 1(DC-04), mvp-builder 버전 파일(W18), help 표에 모든 플래그, 자동 호출 description을 contest 작업 공간으로 한정(PS-21). 새 lint 10개. tests 72 ok, ALL OK, validate exit 0(경고 3 동일).
- 26249ed marketplace 최상위 description·plugins[].version 삭제(PS-15/16, CLAUDE.md:6 규칙도), LICENSE는 MIT 원문만(DC-14, 외부 프로젝트 안내는 README 라이선스 절로), README 비공개 설치 전제·수동 업데이트 명령·playbook 로컬 전용(DC-07). 새 lint 3개. tests 75 ok, ALL OK, validate exit 0(경고 2: 루트 CLAUDE.md 의도, 아이콘 없음).

## 결정(Ruling) 추가 — 틀렸을 때 비용
- playbook은 익명화 대신 .gitignore로 제외(저장소 규칙 7, materials 내용 수정 금지) — 다른 클론엔 playbook이 없음(런타임 의존 없음).
- 기준 커밋에 갱신된 .gitignore를 포함("원본 그대로"에서 벗어남) — playbook이 이력에 한 번도 들어가지 않게. 비용: 기준 커밋이 원본과 .gitignore만 다름.
- 말투 가이드 위치를 plan의 `references/style/` 대신 `${CLAUDE_PLUGIN_DATA}/style/` — PLUGIN_ROOT는 업데이트마다 바뀌고 캐시엔 로컬 파일이 없음. 비용: `--keep-data` 없이 제거하면 함께 지워짐(init이 경고).
- run→init(PS-03): init은 수동 유지, run은 작업 공간이 없으면 init 명령을 알려 주고 멈춘다 — 허용 범위가 턴 단위라 자동 연결이 승인 프롬프트를 부름. 비용: 한 단계 더 입력.
- judge-simulator·fact-checker는 전체 결과를 반환하고 호출자(스킬)가 저장 — 에이전트 tools에 Write가 없음. 비용: 스킬 본문이 저장 단계를 하나 더 가짐.
- scan_placeholders는 대상 파일이 하나라도 없으면 exit 2(있는 파일 결과는 먼저 출력) — 감사 W13 제안·check_style과 같은 기준, 검사 못 한 파일은 통과가 아님. 비용: 없는 파일을 섞어 넘기는 호출자는 0·1 대신 2를 받음(현재 호출자는 scaffold가 만드는 파일만 넘김).
- 체크박스 제외 때문에 `--plain` 제출물의 `- [ ]`가 빠지지 않게 PLAIN_ONLY에 '마크다운 체크박스' 규칙 추가(감사 제안 밖 1줄) — 비용: plain 모드 출력 라벨만 바뀜.
- count_chars `--limit`은 숫자(쉼표·'자'·'이내/이하' 허용)만 받고 '1만자'는 exit 2 — 감사 제안(숫자 아닌 글자 제거)은 '1만자'를 1로 읽음. 비용: 모델이 숫자로 바꿔 다시 실행.
- count_chars 알 수 없는 옵션은 exit 2(W21 범위를 넓힘) — `--limt` 같은 오타가 무시되면 제한 검사 없이 0(통과)이 나옴. 비용: 없음(문서화된 옵션만 사용).
- 이 기록 파일은 마지막에 커밋(4행의 절대 경로는 ~로 바꿈).
- 에이전트 본문은 입력 줄에만 `${CLAUDE_PLUGIN_ROOT}/references/<파일>` 전체 경로, 제목·재언급은 파일 이름만 — 비용: 에이전트가 다른 파일을 읽을 수 있으나 입력 줄이 구분해 줌.
- 작업 공간 템플릿(PRD·SRS·traceability·topics·users)의 상대 경로는 그대로 — scaffold가 작업 공간으로 복사하므로 상대 경로가 맞음. 비용: 없음.
- style-editor 장르 대응: 지원서·기획서 본문·매뉴얼→body, 보충자료·표·개조식 양식→form, 슬라이드 헤드라인·발표자 노트→slides — check_style이 세 값만 받고 form/slides가 끄는 규칙은 S2/S3뿐. 비용: 매뉴얼에 S2/S3 지적이 더 나옴.
- 스킬은 `${CLAUDE_SKILL_DIR}/../../references|templates/…` 경로 유지 — 스킬 본문에서도 치환되고 이미 동작 확인. 비용: 없음.
- refine L10/L16/L17(W08/DC-12)을 7번에서 당겨 이번 커밋에 — L16 제목의 상대 경로를 지워야 했음. 6(모의 심사)은 관문 2 전에 1회 이상. 비용: 커밋 범위가 감사 항목 하나를 더 품음.
- fact-checker 스크립트 줄에 '경로는 작업 공간 루트 기준' — 세션 cwd가 작업 공간 루트라는 전제. 비용: 다른 cwd에서 부르면 상대 경로 인자가 어긋남(호출자가 절대 경로를 넘김).
- brief-analyst·org-researcher의 '호출자가 넘긴' 삭제 — references는 에이전트가 직접 읽음. 비용: 없음.
- PS-09(Skill 도구)·PS-18(permissionMode)을 이번 커밋에 당겨옴 — 새 lint가 같은 줄을 검사. 비용: 없음.
- spec의 사실 검증 저장 파일명은 `90-verify/factcheck-PRD-SRS-<날짜>.md` — 한 응답이 두 파일을 다룸. 비용: 파일명 규칙이 하나 늘어남.
- 감사의 refine·verify·topics 줄 번호가 한 줄씩 어긋나 실제 줄로 고침. 비용: 없음.
- deliverables.md:42는 명령 이름만 바꿈(저장소 CLAUDE.md 규칙 6이 §3·§4 명령 이름 수정을 허용). references의 상대 `scripts/…` 경로(deliverables:42, style-ko:24·30, verify-checklist:6-9)는 내용 수정 금지라 그대로 두고 소유자 질문으로 보고. 비용: 모델이 작업 공간에서 상대 경로로 실행하면 실패 후 플러그인 경로를 찾음.
- humanize는 Skill 도구로 부르고 결과는 스킬이 알려 준 경로(보통 `_workspace/<실행>/final.md`)에서 읽으며, 작업 공간에 생긴 `_workspace/`는 `90-verify/humanize/`로 옮김. 비용: im-not-ai가 스킬 이름을 바꾸면 deliverables §4와 make만 고치면 됨.
- 추천 1·차선 1은 분야 선택(topic-selection.md §1, topics.md §0)에만 적용, 주제 추천은 단독 추천 유지. 비용: 주제에도 차선을 원하면 topics·topic-strategist 한 줄씩.
- judge `--round` 3 이상이면 심사하지 않고 수확 체감을 알림(기존 금지 조항과 같은 기준). 비용: 사용자가 플래그 없이 다시 요청해야 함.
- make는 `{{NAME}}`만 채움 — scaffold 뒤 템플릿에 남는 유일한 토큰(새 토큰이 생기면 lint가 잡음). 비용: 없음.
- research `--only`: domain·competitors 둘 다 domain-researcher(요청 파일 하나만), 7(1단계 완료 표시)은 하지 않음. 비용: 부분 실행으로는 1단계가 완료되지 않음.
- 사람이 직접 입력하는 `/humanize` 표기(help:33, style-ko:24, verify-checklist:7, README)는 그대로(DC-02) — 사람용 안내이고 references는 내용 수정 금지. 비용: 모델이 style-ko를 읽고 슬래시 명령을 시도할 수 있으나 make·verify의 Skill 도구 지시가 우선.
- init의 `~/Downloads/보고서_말투_가이드.md`는 '예:'로만 남김. 비용: 다른 사용자에게 소유자 경로가 예시로 보임.
- 버전은 plugin.json에만(0.1.0 유지) — 커밋 SHA 추적으로 바꿀지는 소유자 결정. 비용: 릴리스마다 plugin.json을 올리지 않으면 설치본이 갱신되지 않음.
- .gitignore는 이미 DC-05 범위(`.env.*`, 전역 docx·pptx·hwp·hwpx·pdf, `.claude/settings.local.json`, `references/style/`)를 덮음 — 추가 수정 없음.
- 아이콘(ICON_MISSING)은 만들지 않음 — 플러그인 디렉터리 제출용 경고이고 동작과 무관. 비용: 공개 디렉터리에 낼 때 512px 이상 PNG 필요.
- tests는 `$( )` 안에서 `case`를 쓰지 않음 — macOS 기본 bash 3.2가 패턴의 `)`를 잘못 해석(문법 오류). 비용: 없음.

## E2E(6·7단계) — `bash $J/tools/e2e.sh <repo>`
- 1차(로그 `$J/logs/run1/`): 작업 공간이 `$J/e2e`(`~/.claude/jobs/…` 아래)여서 research·훅 단계의 Write/Edit가 전부 "sensitive file"로 거부 → **무효**. Claude Code 2.1.314는 어느 `.claude/` 아래든 보호 경로로 보고 acceptEdits에서도 쓰기를 막는다(safetyCheck). 플러그인 결함 아님 — 실사용 작업 폴더는 `.claude/` 밖.
  - init 통과(작업 공간 생성). status는 빈 템플릿 기준으로 바르게 판정. verify는 없는 파일을 거부하고 "제출 가능"이라 하지 않음.
- 발견(플랫폼 동작, 실사용자 영향): 스킬·에이전트가 `${CLAUDE_PLUGIN_ROOT}/references|templates/…`를 Read하면 작업 폴더 밖 읽기라서 대화형은 승인 프롬프트(백그라운드 에이전트도 메인 세션에 프롬프트를 띄움), `-p`·dontAsk에서만 "Path is outside allowed working directories"로 거부된다(최종 리뷰 publish-1 지적으로 정정). 2.1.314 읽기 판정에 설치 플러그인 루트 자동 허용이 없다(`~/.claude/plugins` 허용은 `blockReadsOutsideWorkingDirectories` 설정 때만). → 최종 리뷰 결과와 함께 분류(README 권한 안내 후보).
- 2차(task bos9q5gl6): 작업 공간 `/private/tmp/contest-e2e-a72d83da`(보호 경로 밖), `--allowedTools "Read(//<repo>/**)"`(= 사용자가 플러그인 폴더 읽기를 승인한 상태, 쓰기 권한은 주지 않음). 5단계 모두 exit 0, 로그 `$J/logs/e2e-*.jsonl`·`.summ.txt`.
  - 6단계 **통과**: research가 `contest:brief-analyst`(전경)를 불러 templates·references 5개를 Read로 읽음(거부 0) → `scan_placeholders.py 10-research/brief.md --allow 확인` 0건·exit 0, "요강에 없음" 20회, CONTEST.md 기본 정보 8행 채움(사용자 몫인 팀 여부·목표 혜택만 【 】). status는 1단계 미완(org·domain·users 빈 템플릿, E-ID 0), 남은 날수 22·20·25일(11-09 기준 맞음), 다음 명령 `/contest:research`로 바르게 보고.
  - 7단계 **통과**: 훅이 test.md 저장 뒤 JSON(`additionalContext`+`systemMessage`)으로 경고 2종(자리표시 L2, S1 상투구 L1) 출력, exit 0, 저장 성공, Claude가 훅 메시지를 그대로 인용(1차 기준선의 "훅 메시지 없음" 해소).
  - verify **통과**(plan §8): 스크립트 4종 실행, fact-checker(백그라운드로 실행됨) 결과를 호출자가 `90-verify/factcheck-…md`로 저장, 보고서 "결론: 제출 불가(❌ 7건)", "제출 가능" 0회, CONTEST.md 산출물 표에 ❌ 행 추가.
  - 읽기 허용 규칙 확인: 작업 폴더 밖 플러그인 파일 Read가 `-p`의 하위 에이전트 안에서도 허용 규칙 하나로 통과 → 설치본에는 `Read(~/.claude/plugins/cache/contest-agent/**)` 규칙이 같은 효과(경로만 다름).
  - 거부 2건(단계 2·5 각 1): 모델이 즉석으로 `;`로 이은 복합 Bash 명령 — 플러그인 지시 명령이 아님. 대화형에선 승인 프롬프트 1회. → 사소 항목 후보.

## 최종 리뷰(wgdlz325t: opus 리뷰 3 + 검증 + critic) 분류 — 병합 25건 + critic 7건
- 반박됨(수정 없음): wiring-7, wiring-8, wiring-9, publish-2.
- 수정 1회 대상(효과 기준 중요): scripts-4·6(scan_placeholders 한글 조사 앞 TODO, 코드 속 `()`·`[]`), scripts-1·2·7(trace 대조 말뭉치에 PRD·SRS 구조 숫자·조사 붙은 E-ID·한국어 날짜·URL이 남음, eid 테스트가 엉뚱한 이유로 통과), scripts-3(조·곳·음수·범위·"경제 100조" 누락), scripts-8(대상 여러 개면 첫 파일만 검사), wiring-2(PRD↔SRS 상호 대조), wiring-3(슬라이드는 검사 전에 deck-builder로 넘어가 .pptx를 헛검사), critic-1(1단계 스캔이 user-researcher가 남겨야 하는 【 】로 영구 실패), critic-2(make 검수가 사용자 몫 ❌에서 무한 루프), publish-1+critic-7(README 읽기 허용 안내: cache·data 두 경로).
- Final: Ruling: publish-1을 사소→중요로 올림 — `-p`·무인 실행에서는 references·templates·말투 가이드 읽기가 거부돼 스킬이 근거 없이 진행하고, 대화형에서도 이유 모를 승인 프롬프트가 뜸. 소유자가 맥미니 무인 세션을 쓰므로 효과가 큼 — 틀렸다면 비용은 README 몇 줄과 lint 1개.
- Final: minor (deferred): wiring-1 `--update` 뒤 옛 `승인:` 줄이 남음(재승인 전 세션이 끊기면 make가 미승인 변경으로 진행).
- Final: minor (deferred): wiring-4 `--from-inputs` 문서가 spec-writer 프롬프트에 명시되지 않음(관문 3 검토가 잡음).
- Final: minor (deferred): wiring-5 org·domain 병렬 실행 시 E-ID 번호 충돌 가능(6단계 중복 검사가 일부 완화).
- Final: minor (deferred): wiring-6 `--pick N`에 기록만 하는 분기가 없음.
- Final: minor (deferred): wiring-10 `.before-style.md` 사본이 50-deliverables에 남아 훅·검사 대상이 됨.
- Final: minor (deferred): wiring-11 research·topics 일부 에이전트 프롬프트에 입력(요강 경로 등) 누락.
- Final: minor (deferred): wiring-12 status L21 `<파일…>` glob 표기(실제 경로 나열 지시 없음).
- Final: minor (deferred): scripts-5 CP949·UTF-16 입력은 0건 통과, count_chars는 Traceback(exit 1), BOM 1자 계산.
- Final: minor (deferred): scripts-9 훅이 txt 산출물에 `--plain`을 쓰지 않음.
- Final: minor (deferred): scripts-10 예외(디렉터리 인자 등) 종료 코드 1이 문서상 '미추적/초과'와 겹침.
- Final: minor (deferred): scripts-11 `expect`가 출력을 버려 Traceback도 `expect 1`을 통과.
- Final: minor (deferred): critic-3 PRD·SRS 템플릿 3행의 옛 '상태: 초안 / 승인( )' 칸(고친다면 spec L27 문구에서).
- Final: minor (deferred): critic-4 작업 공간 CLAUDE.md L6 `plan.md`·L21 `scripts/check_style.py`가 작업 공간에 없음.
- Final: minor (deferred): critic-5 저장소 CLAUDE.md 규칙 6의 이름 변경 목록에 skills/verify·agents/ui-designer 누락.
- Final: minor (deferred): critic-6 spec-writer L15 PRD 절 번호가 템플릿과 다름.
- Final: minor (deferred): critic-7 후반 style-editor가 말투 가이드 읽기 실패를 '없음'으로 처리.
- Final: minor (deferred): E2E 2차에서 모델이 즉석으로 만든 `;` 복합 Bash 2건 거부(플러그인 지시 명령 아님).

## 다음 할 일(순서대로, 스크립트 수정마다 tests RED→GREEN)
1. (완료 538a76a) check_style W01(`--strict`가 깨끗한 파일도 실패 → L93 `failed = s1 > 0 or (strict and bool(s2_fail))`), W21(장르 검사·파일 없음).
2. (완료 5ef5c19) trace_numbers W06/W12/W17(E-ID·날짜·시각 숫자 제외, 단위 상수 공유, 자기 자신 대조 제외, 대조 파일 없음 경고). 기존 기대값 유지·샘플 불변.
3. (완료 e9e4e7d) scan_placeholders W13(대상 하나라도 없음 → 2), W19(`{{[A-Z_]+}}` 탐지, 체크박스 `[ ]` 제외), W21(`--allow` 검사).
4. (완료 8d66019) count_chars W20("5,000" 허용, 시작·끝 표식 없음 오류), W21.
5. (완료 8ab71f8) 스킬 본문의 에이전트 호출 `contest:<agent>` 표기(PS-19). 에이전트 본문 상대 경로 → `${CLAUDE_PLUGIN_ROOT}/…`(PS-11/13/W14).
6. (완료 8ab71f8) judge-simulator·fact-checker 결과 반환+호출자 저장(PS-07/08, W02/W07), ui-designer tools에 Skill(PS-09).
7. (완료 1b43840) run(PS-03), judge `$ARGUMENTS`(PS-06), make humanize·$0 문구·count_chars 명령(PS-05/DC-02/PS-20), refine 라운드 순서(W08/DC-12), research `--only` 대응(W16), topics 기준(DC-04/W23), mvp-builder(PS-18/W18), 에이전트 description 범위(PS-21).
8. (완료 26249ed) marketplace description·version(PS-15/16, CLAUDE.md:6), LICENSE MIT 인식(DC-14), README 비공개 설치 전제·playbook 로컬 전용(DC-07).
9. (완료 ddec9b8·7cd2e59·4d596f8·f8bfb4b·40c6cdb·285e177·8522a80) 최종 리뷰 워크플로 wgdlz325t(opus ≤3)·E2E 2차 bos9q5gl6 결과 분류 → 수정 1회(각각 RED→GREEN, 스위트 92/92). 수정·판정·보류는 아래 '최종 리뷰 수정 1회'와 위 분류 절.
10. (완료 99d601a) push(private, SilVerBell0109/contest-agent): 원격 main = 로컬 99d601a, PRIVATE, 추적 파일 91 = 원격 91, 민감 파일 0.
    - 원격 설치 확인(격리한 `CLAUDE_CONFIG_DIR`, HTTPS + gh 자격): `claude plugin marketplace add SilVerBell0109/contest-agent`·`claude plugin install contest@contest-agent` exit 0, `contest@contest-agent` 0.1.0 enabled. 캐시 `plugins/cache/contest-agent/contest/0.1.0/`(README 허용 규칙 경로와 같음), 스킬 11·에이전트 12·hooks.json, 저장소와 바이트 동일(`.in_use` 표식만 다름), 실제 `~/.claude` 설정 무변경.
    - HEAD 재검증: `claude plugin validate .` exit 0(경고 ICON_MISSING 1), `bash tests/run.sh` 92/92 ALL OK, scaffold 5유형 모두 17파일·하위 폴더 7·`{{` 0, 비어 있지 않은 폴더 재실행 exit 1, SKILL.md 최대 52줄(make), 에이전트 description 합계 1,397자.
    - `$J`·`/private/tmp/contest-e2e-a72d83da` 삭제. 남은 일(저장소 밖): 최종 보고, 메모리 파일.

## 최종 리뷰 수정 1회(각 RED→GREEN, 전체 스위트)
- Final: fixed scripts-4 (TODO/TBD/XXX + 한글 조사) — run.sh "flags TODO/TBD/XXX before a Korean particle" RED→GREEN, suite 78/78
- Final: fixed scripts-6 (코드 속 `main()`·`"args": []`) — run.sh `expect 0 scanp code.md` RED→GREEN(+ 산문 `( )` 회귀 가드), suite 78/78
- Final: fixed scripts-1·2 (대조 말뭉치에 PRD·SRS 구조 숫자, 조사 붙은 E-ID·한국어 날짜·URL) — run.sh "ignores PRD/SRS structure numbers"·"ignores E120에, 11월 5일 and URL digits" RED→GREEN, suite 86/86
- Final: fixed scripts-3 (조·곳·가구·음수·범위 위쪽·"경제 100조") — run.sh "extracts 조·곳·가구"·"extracts -15% and the top of 20-30%"·"keeps numbers after 경제/실제" RED→GREEN(+ 20대·1인 가구 회귀 가드), suite 86/86
- Final: fixed scripts-7 (eid 테스트가 엉뚱한 이유로 통과) — eid를 E120 대 120명으로 바꿈, ID 제거를 지운 돌연변이에서 3개 FAIL 확인, suite 86/86
- Final: fixed scripts-8 (대상 여러 개면 첫 파일만) — run.sh `expect 1 tnum dotted.md eid.md`·`expect 2 tnum eid.md none.md` RED→GREEN, suite 86/86
- Final: Ruling: scripts-3의 '대'는 단위에 넣지 않음 — '20대·30대' 연령대 표기가 근거 없는 숫자로 잡혀 정상 문서가 실패한다 — 비용: '차량 50대' 같은 두 자리 대수는 추출되지 않는다(세 자리 이상은 원래 잡힘)
- Final: Ruling: SRS 템플릿의 "단계 2" 같은 산문 숫자는 대조 말뭉치에 남김 — 산문 속 숫자는 근거인지 구조인지 규칙으로 가를 수 없다 — 비용: 산출물의 한 자리 '2명'류가 템플릿 산문으로 추적된 것처럼 보일 수 있다
- Final: fixed wiring-2 (PRD↔SRS 상호 대조) — fact-checker L18·verify L19에 대상별 대조 목록, run.sh "PRD and SRS are not traced against each other" RED→GREEN, suite 87/87
- Final: fixed wiring-3 (슬라이드가 검사 전에 deck-builder로, .pptx 헛검사) — make L20·L30, verify 대상 절, run.sh "slides are checked as outline.md before deck-builder; verify skips binaries" RED→GREEN, suite 88/88
- Final: fixed critic-1 (1단계 스캔이 user-researcher의 【 】로 영구 실패) — status L13·L21·research L31 같은 5파일 명령 + 자리표시 허용, run.sh "stage 1 allows the user's 【 】 and status/research scan the same files" RED→GREEN(+ users.md 허용 전후 가드), suite 91/91
- Final: fixed critic-2 (make 검수가 사용자 몫 ❌에서 무한 반복) — make L23 담당별 분기, run.sh "make stops on user-owned ❌ instead of looping" RED→GREEN, suite 92/92
- Final: fixed publish-1·critic-7 (설치 사용자의 플러그인 references·templates·데이터 폴더 읽기가 무인 실행에서 거부되고 대화형은 매번 승인 창) — README 권한 문단과 `permissions.allow` 두 규칙, run.sh README lint에 두 규칙 추가 RED→GREEN, suite 92/92
- Final: Ruling: references/verify-checklist.md L9의 `--against … PRD SRS` 전체 목록은 고치지 않음 — references 내용 금지 규칙(형식 오류만 수정)이고 실제 실행 지시는 skills/verify·agents/fact-checker가 대상별로 줄인다 — 비용: 체크리스트만 보고 직접 실행하면 PRD↔SRS가 서로를 근거로 삼아 미추적 숫자를 놓칠 수 있다

## 소유자 위임 후속 (2026-11-10)
소유자 지시 "너의 추천대로 나머지 진행해줘". 지난 보고에서 추천한 항목만 처리한다. 수정마다 테스트 RED→GREEN, 전체 스위트, 커밋 1개.
- Ruling: "나머지"의 범위 = 추천 항목(W15·W22·W23·W24, 상대 `scripts/` 경로 PS-24·PS-25·critic-4, critic-7 후반, 옛 말투 가이드 경로 문서, 0.1.1 배포, 맥북 사용자 범위 설치·말투 가이드 복사·허용 규칙 2개) — 보류 15건과 맥미니 설치는 추천에 없었다 — 비용: 소유자가 전부를 뜻했다면 15건이 한 세션 더 밀린다.
- Ruling: 위임은 추천한 항목에 한해 references·templates 내용 금지를 푼다 — CLAUDE_CODE_PROMPT 금지는 소유자가 정한 규칙이고 이번 지시가 그 소유자에게서 왔다. 추천 밖 내용은 여전히 형식 오류만 고친다 — 비용: 소유자가 추천 범위도 원문 유지를 원했다면 W22·W23·W24 문구를 되돌려야 한다.
- Ruling: DC-09(materials/research.md:342-354 claude.ai 대화 링크 13개)는 비공개인 동안 그대로 둔다 — 링크는 로그인한 소유자만 열리고 저장소가 비공개다. 공개 전환 전 점검 목록에 남긴다 — 비용: 저장소를 공개로 돌리면서 이 줄을 놓치면 대화 주소가 노출된다.
- Ruling: DC-18(플레이북 "1,091줄")은 고치지 않음 — 파일은 줄바꿈으로 끝나는 1090줄이고 편집기는 1,091줄로 보인다. materials/는 보호 대상이고 playbook.md는 gitignore — 비용: `wc -l`로 세는 사람에게 1 차이가 보인다.
- 진행: W15 refine 관문 2가 process.md §2 4항목(문제 크기·여기서만 되는 기능 둘·범위 경계·성공 기준 표)을 보도록 고침. 기존 4개(숫자 추적·자리표시·예상 질문 절 번호·심사 기준 대응)는 '관문 2 전 사전 점검'으로 옮기고 명령은 그대로. run.sh "refine 관문 2 checks the four process.md §2 items" RED→GREEN, suite 93/93.
- Ruling: W22 기호 이모지(U+2600~27BF: ✅❌❶★⚠)는 본문(body)에서만 S1, 양식(form)·슬라이드(slides)에서는 S2 — 소마·KIC 양식의 비교표와 슬라이드 번호가 S1로 막혀 정상 산출물이 실패했다. 그림 이모지(🚀 등 U+1F300~)는 모든 장르 S1 유지 — 비용: 매뉴얼은 body로 검사하므로 좋은 예/나쁜 예의 ✅/❌는 여전히 S1로 막히고, 양식·슬라이드의 기호는 S2 안내만 남아 `--strict`에서 3개 이상일 때만 실패한다.
- Ruling: 리듬 검사를 '~습니다.'에서 '~니다.'로 넓힘 — '~입니다.'로 끝나는 합쇼체 6연속을 놓쳤다 — 비용: 합쇼체 본문에 S2 리듬 지적이 늘지만 실패는 `--strict`에서 6연속 이상일 때뿐이다.
- 진행: W22 check_style 기호 이모지 장르별 등급·리듬 '~니다.', style-editor 리듬 문구. run.sh form 표 ✅❌ → 0, slides ❶❷❸ → 0, "rhythm counts every '~니다.' ending" RED→GREEN(+ body ✅ → 1, slides 🚀 → 1 회귀 가드, clean-body `--strict` 통과 유지), suite 98/98.
- 진행: W23 topic-strategist 카드를 templates/topics.md §1의 11항목 이름·순서로 맞춤. 옛 항목 중 템플릿에 없던 것(○△×, 데이터 공개 여부, 핵심 기술, 리스크, 예상 첫 질문)은 가장 가까운 행의 괄호 안으로 옮김. run.sh "topic-strategist writes the 11-row card of templates/topics.md §1"(템플릿 행을 직접 읽어 대조, 11행 아니면 실패) RED→GREEN, suite 99/99.
- 진행: W24 templates/judge-review.md §6에 '답이 있는 절' 열(refine 사전 점검 3이 읽는 칸), judge L15·refine 6단계가 라운드 번호를 프롬프트에 넣고 judge-simulator가 '(라운드 _)'를 채움(없으면 1). run.sh "judge-review records the answering section and the round number" RED→GREEN, suite 100/100.
- Ruling: references의 스크립트 명령은 지우지 않고 `${CLAUDE_PLUGIN_ROOT}/scripts/…`로 적은 뒤 "이 파일에서는 치환되지 않으니 `/contest:verify`·style-editor의 명령 그대로"라는 안내를 붙임 — Read로 읽는 references는 치환되지 않아 상대 경로 `scripts/`는 작업 공간 기준으로 풀렸다. 사용법 설명은 남기고 실행 주체를 치환되는 쪽으로 돌린다 — 비용: 안내를 무시하고 글자 그대로 Bash에 넣으면 `/scripts/…`로 풀려 "파일 없음"으로 바로 실패한다(엉뚱한 파일을 돌리지는 않는다).
- Ruling: 작업 공간 CLAUDE.md의 "plan.md 승인"을 관문 4의 `50-deliverables/mvp-plan/` 최신 파일 머리 `승인:` 줄로 바꿈 — 작업 공간에는 plan.md가 없고, make가 mvp 전에 확인하는 것도 이 줄이다 — 비용: 소유자가 별도 plan.md를 뜻했다면 그 낱말을 되돌려야 한다.
- 진행: PS-24·PS-25·critic-4 verify-checklist 1~4·style-ko §3·deliverables §4의 상대 `scripts/` 경로를 플러그인 경로로, 작업 공간 CLAUDE.md L6(plan.md)·L21(scripts/check_style.py)을 실제 파일·명령으로. run.sh "references and templates name scripts by plugin path; workspace rules name real files" RED(9건)→GREEN, suite 101/101.
- Ruling: style-editor가 말투 가이드를 '파일 없음' 말고 다른 이유(권한·허용 폴더 밖)로 못 읽으면 멈추지 않고 style-ko.md만으로 진행하되, 보고와 90-verify 기록 머리에 경로와 허용 규칙을 남긴다 — 무인 실행에서 문체 단계 전체가 멈추는 것보다 낫고, 조용히 '없음'으로 치던 것이 문제였다 — 비용: 그 회차의 문체는 사용자 말투 대신 기본 규칙으로 고쳐져, 규칙을 넣은 뒤 다시 돌려야 한다.
- 진행: critic-7 후반 style-editor 입력에 읽기 거부 처리, 보고 형식에 '말투 가이드: 적용/없음/읽기 거부'. run.sh "style-editor reports a refused tone-guide read instead of treating it as absent" RED→GREEN, suite 102/102.
