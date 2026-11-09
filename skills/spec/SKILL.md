---
name: spec
description: 공모전 4단계. design.md·evidence.md를 PRD.md·SRS.md·traceability.md로 옮겨 단일 진실 원천을 만들고 사용자 승인(관문 3)을 받는다. 이후 모든 산출물은 여기서만 내용을 가져온다.
argument-hint: "[--from-inputs] [--update '변경 요청…']"
---

# /contest:spec — 4단계 PRD·SRS (관문 3)

PRD·SRS는 산출물의 유일한 원천이다. 여기 없는 기능·숫자는 기획서·슬라이드·코드 어디에도 들어가지 않는다. 규칙: `${CLAUDE_SKILL_DIR}/../../references/prd-srs-guide.md`.

## 사전 확인
- 관문 2 통과 기록(CONTEST.md 3단계 완료)이 없으면 `/contest:refine`으로. 단, `--from-inputs`면 사용자가 00-inputs에 둔 기존 기획서·스펙을 흡수한다: 먼저 그 문서의 숫자를 evidence.md에 E-ID로 등록하고(출처 = 사용자 문서, 등급 ⚠️), 그다음 아래 절차.
- `--update "…"`면 이미 승인된 PRD·SRS의 변경 요청이다: 변경 절·근거·날짜를 §변경 기록에 적고, traceability §4로 **일관성 전파**(목표·KPI·유저플로우·일정·역할·예산·기대효과·산출물)를 확인한 뒤 재승인을 받는다.

## 절차
1. **spec-writer** 서브에이전트 호출 → `40-spec/PRD.md`, `SRS.md`, `traceability.md`. 프롬프트에 작업 공간·references·템플릿 절대 경로, 유형, brief.md의 심사 기준 표, 사용자 작업 원칙(any 금지, .env, 테스트 먼저)을 넣는다.
2. **fact-checker** 호출(PRD·SRS 대상) → 숫자·E-ID·범위 밖·자리표시 점검. '차단'이 있으면 spec-writer에게 돌려 고친다.
3. 메인 에이전트 점검:
   - PRD §7 기능 표의 각 행에 심사 기준 대응 칸이 채워져 있는가. 없는 기능은 P2 또는 범위 밖.
   - SRS의 AC가 전부 측정 가능한가(숫자·조건·방법). "정확하게/빠르게/편리하게" 검색해 0건.
   - PRD §6 유저플로우에 빈 상태·오류·오프라인 중 하나 이상.
   - 보안: 시크릿 .env, 개인정보 최소 수집·보관 기간·관련 법.
   - traceability §1에 심사 기준 빈칸 0.
4. **관문 3 — 사용자 승인 요청**. 보여 주는 형식:
   - 한 줄 정의 / P0 기능(이름만) / 범위 밖으로 둔 것과 이유 한 줄씩 / 열린 질문(번호 선택지, 3개 이내) / "승인하시면 이 PRD·SRS를 기준으로 산출물을 만듭니다. 승인 뒤 변경은 `/contest:spec --update`로 기록합니다."
   - 사용자가 읽고 고칠 수 있게 파일 경로를 알려 준다. 여기서 **멈춘다**.
5. 승인("오케이", "반영해줘", "승인")이 오면 PRD·SRS 머리에 `승인: <날짜> "<사용자 문구>"`를 적고 CONTEST.md 4단계 완료·결정 기록. 다음: `/contest:make <종류>`.
   - 사용자가 수정 메모를 주면 반영 → 변경 기록 → 다시 승인 요청(주석 루프).

## 금지
- 승인 전에 50-deliverables를 만들기 시작하는 것(mvp-plan 포함).
- design.md에 없는 결정을 PRD에서 새로 내리는 것(필요하면 사용자에게 열린 질문으로).
- 승인 뒤 PRD·SRS를 변경 기록 없이 고치는 것.
