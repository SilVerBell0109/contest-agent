# contest — 소프트웨어 공모전 원스톱 에이전트 (Claude Code 플러그인)

공모전 조사 → 주제 추천 → 고도화 → PRD·SRS → 기획서·슬라이드·MVP·발표자료 제작 → 검수까지를 Claude Code 안에서 진행합니다. 모든 산출물은 PRD·SRS와 근거 원장(evidence.md, E-ID)에서만 내용을 가져오고, 근거 없는 숫자는 쓰지 않습니다.

실제 공모전 8건(코스콤 AI Agent Challenge 우수상, SW마에스트로, 알파프로젝트, 하나증권, KIC, 현대차 오도, DCA, 패크크)의 작업 기록에서 뽑은 절차·기준·실수 목록이 들어 있습니다.

## 설치

```
/plugin marketplace add SilVerBell0109/contest-agent
/plugin install contest@contest-agent
```

비공개 저장소라 저장소 접근 권한이 필요합니다. Claude Code는 대화형 입력 없이 git을 실행하므로, SSH라면 암호를 묻지 않는 키(ssh-agent에 등록)와 known_hosts가, HTTPS라면 `gh auth login` 후 `gh auth setup-git`으로 저장한 자격이 있어야 합니다. 환경 변수 `GITHUB_TOKEN`만으로는 설치되지 않습니다. SSH 키가 없는 기기는 `CLAUDE_CODE_PLUGIN_PREFER_HTTPS=1`을 설정합니다.

업데이트: 이 마켓플레이스는 자동 업데이트가 기본으로 꺼져 있습니다. `/plugin marketplace update contest-agent` 또는 `claude plugin update contest@contest-agent`로 받습니다. 새 버전은 `plugin.json`의 `version`이 올라가야 설치됩니다.

권한: 스킬과 에이전트는 설치된 플러그인 폴더의 `references/`·`templates/`와 플러그인 데이터 폴더(말투 가이드)를 읽습니다. 이 경로는 작업 폴더 밖이라 대화형 모드에서는 읽을 때마다 승인 창이 뜨고(백그라운드 에이전트의 승인 창도 메인 세션에 뜹니다), `claude -p`·dontAsk 같은 무인 실행에서는 읽기가 거부되어 규칙 없이 진행됩니다. `~/.claude/settings.json`의 `permissions.allow`에 아래 두 항목을 넣으면 묻지 않고 읽습니다(이미 `allow` 배열이 있으면 두 항목만 더합니다).

```json
{
  "permissions": {
    "allow": [
      "Read(~/.claude/plugins/cache/contest-agent/**)",
      "Read(~/.claude/plugins/data/contest-contest-agent/**)"
    ]
  }
}
```

권장 외부 플러그인(없어도 동작, 있으면 품질이 오릅니다):

```
/plugin marketplace add pbakaus/impeccable
/plugin install impeccable@impeccable          # UI 품질(/impeccable …)

/plugin marketplace add epoko77-ai/im-not-ai
/plugin install humanize-korean@im-not-ai       # 한국어 AI 티 제거(/humanize …)
```

로컬 테스트: `claude --plugin-dir ./contest-agent` → `/contest:help`.

## 사용 흐름

| 단계 | 명령 | 관문 |
|---|---|---|
| 0 | `/contest:init 하나증권-2026 --type idea` | 공모전 하나 = 폴더 하나 |
| 1 | `/contest:research https://…요강` | 요강 전수 추출, 주최사·분야·사용자·경쟁 조사, evidence.md |
| 2 | `/contest:topics` | 후보 3~5 + 수상 관문 비교 + 단독 추천 → **사용자가 번호로 선택** |
| 3 | `/contest:refine` | 고도화 라운드 + 모의 심사 → 자동 4항목 점검 |
| 4 | `/contest:spec` | PRD·SRS·traceability → **사용자 승인** |
| 5 | `/contest:make 기획서` / `슬라이드` / `화면예시` / `mvp-plan` → **승인** → `mvp` … | 초안 → 사실 검증 → 문체 → 검수 → 모의 심사 |
| — | `/contest:verify`, `/contest:judge <파일>`, `/contest:status`, `/contest:run <요강>` | 보조 |

`/contest:run <요강>` 하나로 1·2단계를 연속 실행하고 주제 선택에서 멈춥니다. `--continue`로 3·4단계, `--make 기획서 슬라이드`로 5단계.

## 작업 공간 구조

```
<공모전 폴더>/
  CONTEST.md          상태판(단계·관문·산출물·결정·열린 질문)
  CLAUDE.md           이 폴더의 규칙(진실의 원천, 표기, 문체, .env)
  00-inputs/          요강·양식·사용자 자료 (이 공모전 것만)
  10-research/        brief, org, domain, users, competitors
  20-topics/          topics.md (관문 1 기록)
  30-refine/          evidence.md(E-ID 원장), design.md, judge-preview.md
  40-spec/            PRD.md, SRS.md, traceability.md (승인 표시)
  50-deliverables/    산출물(종류별 폴더, 버전 파일명)
  90-verify/          검수·사실 검증·문체·모의 심사 보고서
```

## 할루시네이션 방지 장치

1. **E-ID 근거 원장**: 숫자·인용마다 출처·발행일·확인일·등급(✅/⚠️/❓)·확인 방법. `trace_numbers.py`가 산출물의 숫자를 원장과 대조.
2. **단일 진실 원천**: 승인된 PRD·SRS 밖의 기능·숫자는 산출물에 들어가지 않음. 변경은 `--update`로 기록·전파.
3. **표기 규칙**: `【 】` 사용자가 채울 것, `[가정]`, `[예시값]`, `[확인 필요]`. 제출 전 `scan_placeholders.py` 0건.
4. **분리된 검증자**: fact-checker(읽기 전용), judge-simulator(초안 작성자와 분리), style-editor(의미 불변).
5. **결정적 스크립트**: 자리표시·문체(S1/S2/S3)·글자 수(줄바꿈 2자)·숫자 추적. 작업 공간의 `50-deliverables/`·`40-spec/` 문서(.md·.txt)를 저장할 때마다 훅이 경고(차단하지 않음).
6. **사람 정보 생성 금지**: 사용자·팀원 경험·이력·지원 동기는 사용자가 직접 씁니다.

## 구성

- `skills/` 11개 명령(`/contest:*`), `agents/` 12개 서브에이전트, `hooks/` 저장 후 점검, `scripts/` 6개, `templates/` 23개, `references/` 절차·기준·사례(cases/ 8건), `materials/` 원자료(연구 보고서). 플레이북 `materials/playbook.md`는 팀원 실명·팀 문서 링크가 있어 저장소에 올리지 않고 소유자 기기에만 둡니다(플러그인 실행에는 쓰지 않음).
- 사용자 원칙: 기획과 코딩 분리(승인 전 코드 금지) · 테스트 먼저 · 요청한 것만 · any 금지 · 시크릿은 .env · 본문은 합쇼체+1인칭, AI 티 제거.

## 라이선스
MIT(`LICENSE`). 다음 외부 프로젝트는 본문을 복제하지 않고 설치해 호출합니다: pbakaus/impeccable(Apache License 2.0), epoko77-ai/im-not-ai(Humanize KR, MIT License).
