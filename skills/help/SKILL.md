---
name: help
description: contest 플러그인 사용법과 현재 단계에서 다음에 할 명령을 안내한다. 사용자가 "공모전", "contest", "어떻게 시작해", "다음에 뭐 해" 등을 물을 때 사용.
user-invocable: true
---

# /contest:help — 안내와 라우팅

이 플러그인은 소프트웨어 공모전을 **조사 → 주제 → 고도화 → PRD·SRS → 산출물 제작 → 검수** 순서로 진행하는 원스톱 에이전트다. 모든 산출물은 `40-spec/PRD.md`·`SRS.md`와 `30-refine/evidence.md`(E-ID 근거 원장)에서만 내용을 가져온다. 근거 없는 숫자는 쓰지 않는다.

## 명령
| 명령 | 하는 일 | 관문 |
|---|---|---|
| `/contest:init <폴더> [--type dev\|idea\|ad\|application\|program]` | 작업 공간 생성(공모전 하나 = 폴더 하나) | — |
| `/contest:research [요강 URL·파일…] [--only brief\|org\|domain\|users\|competitors]` | 요강 전수 추출 → 주최사·분야·사용자·경쟁 조사 → evidence.md | — |
| `/contest:topics [분야·후보…] [--pick N]` | 후보 3~5개 + 수상 관문 비교 + 단독 추천 | **관문 1: 사용자가 번호로 선택** |
| `/contest:refine [--rounds N]` | 선택 주제 고도화(design.md), 모의 심사 | 관문 2: 자동 4항목 점검 |
| `/contest:spec [--from-inputs] [--update '변경 요청…']` | PRD·SRS·traceability 작성 | **관문 3: 사용자 승인** |
| `/contest:make <종류> [--template 양식] [--limit N] [--judge] [--no-humanize]` | 기획서·지원서·슬라이드·보충자료·화면예시·mvp-plan·mvp·project·readme·매뉴얼·시연대본·발표대본·예상질문·회고·custom | mvp는 **관문 4: mvp-plan 승인** |
| `/contest:verify [파일…] [--plain] [--limit N] [--genre body\|form\|slides] [--strict]` | 자리표시·문체·글자 수·숫자 추적·사실 검증·요강 대조 → 90-verify/report | — |
| `/contest:judge <파일> [--round N] [--persona peer\|expert\|both]` | 심사위원 모의(배점표 채점 + 예상 질문 10개) | — |
| `/contest:status [--fix]` | CONTEST.md 상태판 갱신·다음 할 일 | — |
| `/contest:run <요강…>` | 1·2단계 연속 실행 후 관문 1에서 멈춤. `--continue [--pick N]`로 3·4단계, `--make <종류…>`로 5단계 | 관문마다 멈춤 |

## 지금 무엇을 해야 하나
1. 현재 폴더(또는 상위)에 `CONTEST.md`가 없으면 → `/contest:init`.
2. 있으면 CONTEST.md의 "단계와 관문" 표에서 첫 미완료 단계를 찾아 그 명령을 안내한다. `/contest:status`가 같은 일을 한다.
3. 사용자가 단계를 건너뛰려 하면(예: 조사 없이 기획서) 왜 안 되는지 한 줄(근거 원장이 비어 숫자를 쓸 수 없음)과 최소 경로(`/contest:run`)를 제시한다. 단, 사용자가 이미 PRD·SRS 수준의 자료를 00-inputs에 넣었다면 `/contest:spec --from-inputs`로 흡수할 수 있다고 알린다.

## 외부 플러그인(권장)
- UI 품질: `/plugin marketplace add pbakaus/impeccable` → `/plugin install impeccable@impeccable`
- 한국어 AI 티 제거: `/plugin marketplace add epoko77-ai/im-not-ai` → `/plugin install humanize-korean@im-not-ai`
없어도 동작한다(폴백 규칙 내장). 설치 여부는 `/impeccable`·`/humanize` 명령이 자동완성에 뜨는지로 확인한다.

## 사용자 원칙(항상)
기획과 코딩 분리(승인 전 코드 금지) · 불확실하면 질문 · 요청한 것만 · 꼭 필요한 것만 수정 · 성공 기준 먼저 · any 금지 · 시크릿은 .env · 본문은 합쇼체+1인칭, AI 티 제거 · 모르는 건 모른다고.
