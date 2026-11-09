# Claude Code에 붙여 넣을 프롬프트 — contest 플러그인 조립·검증

> 사용법: 이 압축을 푼 `contest-agent/` 폴더에서 `claude`를 실행하고 아래 `---` 사이의 내용을 그대로 붙여 넣습니다. 플러그인 파일은 이미 다 들어 있습니다. Claude Code가 할 일은 **검증·드라이런·수정·배포 준비**입니다. 새로 설계하거나 파일을 대량으로 다시 쓰게 하지 마십시오.

---

## 맥락

나는 최종은(국민대 소프트웨어학부, SW마에스트로 17기, 목표: 금융권 백엔드 개발자). 이 폴더는 내가 공모전을 준비할 때 쓸 Claude Code 플러그인 `contest`의 소스다. 실제 공모전 8건(코스콤 우수상, 소마, 알파프로젝트, 하나증권, KIC, 현대차 오도, DCA, 패크크)의 작업 기록에서 뽑은 절차·기준·실수 목록이 `references/`와 `materials/`에 들어 있다.

플러그인의 목표: 공모전 요강을 주면 **① 조사(주최사·분야·사용자·경쟁) → ② 주제 추천(내가 선택) → ③ 고도화 → ④ PRD·SRS(내가 승인) → ⑤ 내가 지시하는 산출물(기획서·슬라이드·화면예시·MVP·본 프로젝트·README·매뉴얼·발표자료) 제작·검수**를 원스텝으로 진행하되, 근거(E-ID) 없는 숫자와 PRD·SRS 밖의 내용은 절대 만들지 않는 것이다. 외부 플러그인 pbakaus/impeccable(UI)와 epoko77-ai/im-not-ai(한국어 AI 티 제거)는 복사하지 않고 설치해 호출한다.

## 내 작업 원칙 (이 작업에도 적용)
1. 기획과 코딩 분리: 수정 계획을 먼저 보여 주고 내 승인 뒤 고친다. 단, 아래 "단계"의 검증·드라이런은 승인 없이 바로 한다.
2. 불확실하면 추측하지 말고 묻는다. 해석이 여러 개면 모두 제시한다. 더 단순한 방법이 있으면 먼저 말한다.
3. 요청한 것만. 추측으로 기능·추상화·옵션을 넣지 않는다.
4. 꼭 필요한 것만 수정. 관련 없는 파일·문장·포맷을 건드리지 않는다. 데드 코드는 삭제 대신 언급.
5. 성공 기준 먼저. 각 단계의 "통과 기준"을 만족해야 다음 단계로 간다.
6. any 타입 금지. API 키·시크릿은 .env에만.

## 자료 위치
- 플러그인: `.claude-plugin/`, `skills/`(11), `agents/`(12), `hooks/`, `scripts/`(6), `templates/`(23), `references/`(+cases/ 8).
- 설계 근거: `plan.md`(제작 계획·파일 트리·수용 기준·열린 질문), `materials/research.md`(채팅 분석), `materials/playbook.md`(원자료 플레이북).
- 규칙 요약: `CLAUDE.md`(저장소 규칙), `README.md`(사용자용).

## 단계 (순서대로, 단계마다 결과와 통과 여부를 한 줄씩 보고)

### 1. 구조 검증
- `claude plugin validate .` 실행. 오류 0. (명령이 없으면 Claude Code 버전을 알려 주고 `.claude-plugin/plugin.json`·`marketplace.json`을 공식 스키마와 수동 대조.)
- `python3 -c "import json,sys;[json.load(open(p)) for p in ['.claude-plugin/plugin.json','.claude-plugin/marketplace.json','hooks/hooks.json']]"` 통과.
- 모든 `skills/*/SKILL.md`와 `agents/*.md`의 프런트매터가 파싱되는지(YAML), `name`이 폴더명/파일명과 같은지, SKILL.md가 500줄 이하인지 확인.
- 통과 기준: 오류 0, 경고는 목록으로 보고.

### 2. 공식 문서 대조
- Claude Code 공식 문서(skills, sub-agents, plugins, hooks)를 WebFetch로 읽고 다음을 확인: 프런트매터 키 이름(`disable-model-invocation`, `argument-hint`, `allowed-tools`, 에이전트의 `tools`/`model`/`maxTurns`/`permissionMode`), `${CLAUDE_SKILL_DIR}`·`${CLAUDE_PLUGIN_ROOT}` 치환 위치, 플러그인 에이전트의 호출 이름(네임스페이스 여부), 훅 JSON 형식.
- 어긋나는 키가 있으면 **수정 목록**으로 제시(파일·줄·현재→수정). 내 승인 뒤 고친다.
- 통과 기준: 수정 목록이 비거나 내가 승인한 수정이 반영됨.

### 3. 스크립트 테스트
- `bash tests/run.sh` 실행. 샘플은 `tests/samples/`에 있다(자리표시·AI 상투구 본문, 깨끗한 본문, 숫자 추적용 산출물과 evidence). 16개 항목이 전부 `ok`이고 마지막 줄이 `ALL OK`여야 한다.
- 추가로 직접 확인: `python3 -I scripts/check_style.py tests/samples/placeholders-and-ai-style.md --genre form --json` → form 장르에서 합쇼체·개조식 관련 규칙이 꺼지는지(JSON의 규칙 목록 비교).
- 통과 기준: `ALL OK`. 어긋나면 스크립트를 고치되(원칙 4) 고친 내용을 보고. 샘플 파일은 바꾸지 않는다.

### 4. 스캐폴드 드라이런
- 임시 폴더에서 `python3 -I scripts/scaffold.py demo --type dev --templates ./templates` → 폴더 트리 출력. CONTEST.md·CLAUDE.md의 `{{…}}` 치환이 남아 있지 않은지 `grep -r "{{" demo/` 0건. 비어 있지 않은 폴더에 재실행 시 거부되는지.
- 5개 유형(dev/idea/ad/application/program) 모두 생성되는지.
- 통과 기준: 5개 모두 생성, 치환 잔재 0, 거부 동작 확인. demo 폴더는 삭제.

### 5. 플러그인 로드와 명령 확인
- `claude --plugin-dir .`로 새 세션을 열어 `/contest:help`가 뜨고 11개 명령이 자동완성에 보이는지, `/agents`에 12개 에이전트가 보이는지 확인한다(직접 확인이 안 되는 환경이면 확인 방법을 나에게 안내).
- 에이전트가 `contest:brief-analyst`처럼 네임스페이스로 보이면 `skills/*/SKILL.md`에서 에이전트 호출 표기를 그 이름으로 맞추는 수정 목록을 제시.
- 통과 기준: 명령 11, 에이전트 12, 훅 등록 1.

### 6. 엔드투엔드 드라이런 (가상 공모전, 네트워크 조사는 최소)
- `/contest:init e2e-demo --type idea` → `00-inputs/brief.md`에 가상 요강(심사 기준 4항목 배점, 5,000자 제한, 첨부 3개, 개인정보 기재 금지, 마감일)을 내가 아닌 네가 적되 **"가상 요강"이라고 머리에 표기**.
- `/contest:research 00-inputs/brief.md --only brief` → brief.md가 요강을 전수 추출하는지, 비어 있는 항목을 "요강에 없음"으로 두는지.
- `/contest:status` → 단계 판정이 맞는지.
- 여기까지만. 주제 추천·고도화는 실제 공모전에서 내가 한다.
- 통과 기준: brief.md에 추측 채움 0(scan_placeholders `--allow 확인` 통과), CONTEST.md 갱신.

### 7. 훅 동작 확인
- e2e-demo의 `50-deliverables/test.md`에 "드물지 않습니다"와 "【기입】"을 포함한 문장을 Write로 저장 → 훅이 경고를 출력하는지(저장은 막지 않음).
- 통과 기준: 경고 2종 출력, exit 0.

### 8. 문체 자산 연결 (있을 때만)
- `~/Downloads/보고서_말투_가이드.md`가 있으면 `${CLAUDE_PLUGIN_DATA}/style/user-report-tone.md`(`~/.claude/plugins/data/contest-contest-agent/style/`)로 복사할지 묻고, 복사하면 `references/style-ko.md` 머리의 "사용자 자산 우선" 문장이 실제 경로를 가리키는지 확인.
- `korean-report-tone` 스킬이 설치돼 있으면 `skills/make/SKILL.md` 문체 단계에 호출 한 줄 추가를 제안(승인 뒤).

### 9. 저장소 준비
- `.gitignore`가 이미 있다. `.env`, 드라이런 폴더(`demo/`, `e2e-demo/`), `**/00-inputs/*`, 양식 원문(docx·pptx·hwp·pdf)이 막혀 있는지 확인하고 빠진 것만 보완한다.
- `git init` → 첫 커밋 메시지는 `feat: contest plugin v0.1.0 — 공모전 원스톱 에이전트`. 원격은 `SilVerBell0109/contest-agent`로 내가 만들 테니 `git remote add` 명령만 알려 달라.
- 통과 기준: `git status` 깨끗, 민감 파일 미추적(`git ls-files | grep -E '\.env$|00-inputs/'` 0건).

### 10. 보고
- 각 단계의 통과/실패, 내가 승인해야 할 수정 목록, 설치 명령 3줄(`/plugin marketplace add SilVerBell0109/contest-agent`, impeccable, im-not-ai), 첫 실전 사용법 한 줄(`/contest:run <요강 URL>`).
- `plan.md` 10장 열린 질문 4개(플러그인 이름, 모델 배분, 에이전트 팀 옵션, 결과 추적)에 대한 네 의견을 각 한 줄로.

## 금지
- `references/`·`templates/`·`materials/`의 **내용(규칙·사례·문장)** 을 다시 쓰거나 "개선"하지 않는다. 형식 오류(YAML·경로·치환)만 고친다.
- impeccable·im-not-ai의 코드나 규칙을 이 저장소로 복사하지 않는다.
- 실제 공모전 조사(웹 검색)를 드라이런에서 하지 않는다. 가상 요강으로만.
- 내 이력·팀원 정보를 어디에도 추가하지 않는다(`references/user-criteria.md` §5에 있는 확인된 사실만 유지).
- 테스트 없이 "확인했다"고 보고하지 않는다. 실행 결과(명령과 출력 요약)를 함께 보고한다.

---

## 붙여 넣은 뒤 내가 할 일
1. 단계 2·5에서 나온 수정 목록 승인.
2. GitHub에 `contest-agent` 저장소 생성 후 push.
3. 실전: 새 폴더에서 `claude` → `/contest:run <요강 URL>` → 주제 선택 → `/contest:run --continue` → PRD·SRS 승인 → `/contest:make 기획서` …
