# 공모전 원스톱 에이전트 — 제작 계획 (plan.md)

작성일 2026-11-09 · 입력: research.md(채팅 분석), materials/playbook.md(Drive 분석), pbakaus/impeccable, epoko77-ai/im-not-ai · 실행 주체: Claude Code

---

## 1. 목표와 범위

**목표.** 소프트웨어 공모전 하나를 넣으면 조사 → 주제 추천 → 고도화 → PRD·SRS → 요청하는 모든 산출물(기획서, 슬라이드, MVP, 본 프로젝트, 발표 자료)을 한 흐름으로 만들어 주는 Claude Code 플러그인. PRD·SRS를 단일 진실 원천(SSOT)으로 두고, 모든 산출물은 그 안의 내용과 근거 원장(evidence.md)에서만 나온다.

**포함.** 개발형·아이디어 제안형 공모전을 1순위로, 광고·크리에이티브형과 프로그램 지원서형은 유형별 참고 문서와 템플릿까지만(산출물 파이프라인은 공유).

**제외.** 실제 접수 폼 제출(사용자가 직접), 팀원 개인정보·이력 작성(【】로 비움), 유료 데이터 구매, 결과 추적 자동화(2차 과제).

## 2. 형태 결정

| 선택지 | 판단 |
|---|---|
| 단일 스킬 | 단계가 10개라 SKILL.md 500줄 한도를 넘고, 초안 작성자와 심사위원 모의를 분리할 수 없음 |
| 에이전트 팀(실험 기능) | 환경변수로 켜야 하고 세션 복원이 안 됨. 연구·검토처럼 병렬 가치가 큰 단계에만 쓰면 되므로 기본값으로 두지 않음 |
| **플러그인(스킬 + 서브에이전트 + 훅)** | 단계마다 스킬(`/contest:research` 등), 역할마다 서브에이전트, 쓰기 직후 검증 훅. GitHub 마켓플레이스로 설치 가능. **채택** |

공모전 하나당 폴더 하나를 쓴다(채팅 교차 오염 사례의 교훈). 플러그인은 도구이고, 각 공모전은 `/contest:init`으로 만든 작업 공간이다.

## 3. 유저플로우 → 명령 매핑

| 사용자 흐름 | 명령 | 산출물 | 관문 |
|---|---|---|---|
| 0. 시작 | `/contest:init <폴더> --type dev` | 작업 공간, CONTEST.md 상태판 | — |
| 1. 공모전 조사 | `/contest:research <URL·파일>` | brief.md(요강·양식·Q&A·접수 폼·플랫폼), org.md(주최사 5단), domain.md(분야·선행 대회·수상작), users.md(예상 사용자·유저플로우), competitors.md(기존 서비스·경쟁 참가자) | — |
| 2. 주제 추천 | `/contest:topics` | topics.md: 후보 3~5 카드, 중복 점검, 수상 관문 순위, 추천 1·차선 1 | **관문 1: 사용자가 고른다** |
| 3. 고도화 | `/contest:refine` | evidence.md(근거 원장 E-ID), design.md(기능·수치 규칙·유저플로우·구성도·리스크·KPI·일정), judge-preview.md | 관문 2: 자동 점검 4항목 |
| 4. PRD·SRS | `/contest:spec` | PRD.md, SRS.md, traceability.md | **관문 3: 사용자 승인** |
| 5. 산출물 | `/contest:make <종류>` | 기획서·슬라이드·보충자료·화면예시·mvp-plan·mvp·project·readme·매뉴얼·시연대본·발표대본·예상질문·지원서·회고 | 산출물마다 fact-check → style → verify |
| 보조 | `/contest:judge`, `/contest:verify`, `/contest:status`, `/contest:run` | 심사위원 모의, 제출 전 검수, 상태판, 1~2단계 연속 실행 | |

## 4. 할루시네이션 방지 설계

1. **근거 원장.** 모든 사실은 evidence.md의 E-ID(출처 URL·확인일·확신도 ✅⚠️❓·확인 방법)를 달고 들어온다. 직접 집계는 조건(기간·질의·집계일)을 함께 적는다.
2. **SSOT.** PRD·SRS 승인 뒤 산출물은 그 안의 기능·수치·용어만 쓴다. 새 사실이나 기능이 필요하면 산출물이 아니라 스펙 변경 요청(change log)으로 올린다.
3. **표기 규칙.** 확인 못 한 값은 [확인 필요], 가정은 [가정], 가상 예시는 [예시값], 사용자가 채울 것은 【】. 제출본에는 이 표기가 0건이어야 통과.
4. **분리된 검증자.** fact-checker(읽기 전용)가 산출물의 숫자·인용·고유명사를 evidence.md와 대조하고, judge-simulator는 초안을 쓴 에이전트와 다른 컨텍스트에서 채점한다.
5. **스크립트 검증.** 자리표시 스캔, 금칙어·AI-티 검사, 글자 수(공백·줄바꿈 규칙), 숫자 추적(산출물의 숫자가 원장에 있는지)을 훅과 `/contest:verify`에서 돌린다.
6. **사람 것은 비운다.** 팀원 경험·이력·연락처·서명·본인 체험은 절대 생성하지 않고 묻는다.

## 5. 외부 스킬 통합

| 외부 | 쓰는 지점 | 없을 때 |
|---|---|---|
| **im-not-ai** (`/humanize-scan`, `/humanize`, `/humanize-korean`, MIT) | `/contest:make` 산출물의 문체 단계. 의미·수치·고유명사 불변, 변경률 30% 경고·50% 중단을 그대로 따름. 장르는 지원서 본문=합쇼체·1인칭, 양식 개조식=유지 | references/style-ko.md의 B-7 규칙 + scripts/check_style.py |
| **impeccable** (`/impeccable init·shape·critique·audit·polish·harden·adapt·onboard`, Apache-2.0) | `make mvp`·`make project`·`make 화면예시`의 UI 단계. PRODUCT.md는 PRD에서 채움 | references/mvp-dev.md의 anti-slop 규칙 |
| 사용자 기존 자산 | `~/Downloads/보고서_말투_가이드.md`, korean-report-tone 스킬 → references/style/user-report-tone.md로 복사 | B-7 요약으로 대체 |

## 6. 파일 트리

```
contest-agent/
├── .claude-plugin/plugin.json, marketplace.json
├── CLAUDE_CODE_PROMPT.md        Claude Code에 붙여 넣을 조립·검증 지시
├── plan.md, README.md, LICENSE(MIT)
├── hooks/hooks.json             Write·Edit 직후 자리표시·금칙어 스캔
├── scripts/                     scaffold.py, check_style.py, count_chars.py, scan_placeholders.py, trace_numbers.py, post_write_check.sh
├── skills/<단계>/SKILL.md       help, init, research, topics, refine, spec, make, verify, judge, status, run
├── agents/*.md                  brief-analyst, org-researcher, domain-researcher, user-researcher, topic-strategist, spec-writer, fact-checker, judge-simulator, style-editor, ui-designer, mvp-builder, deck-builder
├── references/                  process, contest-types, intake-checklist, org-research, topic-selection, evidence-rules, design-patterns, prd-srs-guide, deliverables, mvp-dev, style-ko, verify-checklist, judge-bank, user-criteria, cases/8건
├── templates/                   CONTEST, CLAUDE.workspace, brief, org, domain, users, competitors, topics, evidence, design, PRD, SRS, traceability, judge-review, mvp-plan, proposal-generic, slides-12, supplement, demo-script, README-project, manual, retrospective, submission-checklist
└── materials/                   playbook.md, research.md (원자료)
```

## 7. Claude Code가 할 일 (체크리스트)

- [ ] 1. materials/와 references/를 읽고 빠진 지식·모순을 목록으로 보고 (research.md 보완)
- [ ] 2. 이 plan.md를 검토해 수정 제안 → 사용자 승인 대기
- [ ] 3. 플러그인 파일을 점검·보완: frontmatter 필드가 Claude Code 문서와 맞는지, 스킬 간 경로(`${CLAUDE_SKILL_DIR}/../../references/`)가 실제로 해석되는지
- [ ] 4. `claude plugin validate .` 통과
- [ ] 5. scripts/ 단위 테스트(샘플 입력으로 자리표시·금칙어·글자 수·숫자 추적 결과 확인)
- [ ] 6. 외부 플러그인 설치 확인: `/plugin marketplace add pbakaus/impeccable`, `/plugin marketplace add epoko77-ai/im-not-ai` → `/plugin install humanize-korean@im-not-ai`. 미설치 시 폴백 문서가 안내되는지 확인
- [ ] 7. 사용자 자산 복사: `~/Downloads/보고서_말투_가이드.md` → references/style/user-report-tone.md (있을 때)
- [ ] 8. 드라이런: `claude --plugin-dir .` 로 `/contest:init demo --type dev` → 샘플 요강으로 `/contest:research` → `/contest:topics` 까지 돌려 산출물 형식 확인
- [ ] 9. README.md(설치·사용·규칙), LICENSE, marketplace.json 확정
- [ ] 10. git init → 첫 커밋. 원격 푸시는 사용자가 수행

## 8. 수용 기준

- 모든 스킬이 `/contest:<이름>`으로 뜨고 `claude plugin validate` 통과
- 산출물 파일에 [확인 필요]·【】가 남아 있으면 `/contest:verify`가 실패로 보고
- `/contest:make 기획서` 결과의 모든 숫자가 evidence.md의 E-ID로 추적됨(trace_numbers.py 0건 미추적)
- 서브에이전트 설명 합계가 15,000토큰 경고 아래
- SKILL.md 각 500줄 이하, 상세는 references/로

## 9. 트레이드오프

- 서브에이전트는 대화 맥락을 못 보므로 스킬이 매번 파일 경로와 규칙을 프롬프트에 다시 적어 넘긴다(토큰 비용 ↑, 일관성 ↑).
- 외부 플러그인 의존: 설치가 안 된 환경을 위해 폴백 규칙을 넣되, 두 저장소의 본문은 복제하지 않는다(라이선스는 허용하지만 업데이트 추적이 어려움).
- 광고형·지원서형은 파이프라인을 공유하되 1차 버전에서는 참고 문서 수준. 산출물 종류를 늘리는 건 사용 뒤 결정.

## 10. 열린 질문

1. 플러그인 이름 `contest`(명령 `/contest:...`)로 괜찮은지
2. 기본 모델 배분: 조사·검증 서브에이전트는 sonnet, 스펙·심사위원 모의는 inherit — 비용 대비 괜찮은지
3. 에이전트 팀 모드를 연구 단계 옵션으로 넣을지(기본 꺼짐)
4. 결과 추적(수상 여부 기록)과 회고 자동화는 2차로 미뤄도 되는지
