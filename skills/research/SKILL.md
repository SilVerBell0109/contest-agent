---
name: research
description: 공모전 1단계 조사. 요강 전수 추출(brief.md) → 주최사(org.md) → 분야·경쟁(domain.md, competitors.md) → 사용자(users.md)를 서브에이전트로 조사하고 모든 사실을 evidence.md에 E-ID로 등록한다.
argument-hint: "[요강 URL 또는 00-inputs 파일 경로…] [--only brief|org|domain|users|competitors]"
allowed-tools: Bash(python3 -I ${CLAUDE_PLUGIN_ROOT}/scripts/scan_placeholders.py *)
---

# /contest:research — 1단계 조사

조사는 판단 재료를 만드는 단계다. 사용자는 "내가 판단할 수 있도록 자세히"를 원한다. 요약하지 말고 사실·숫자·날짜·출처를 모은다. 추천은 아직 하지 않는다.

## 사전 확인
1. 현재 폴더(또는 상위)에서 `CONTEST.md`를 찾는다. 없으면 `/contest:init`을 안내하고 멈춘다.
2. `$ARGUMENTS`의 URL·파일이 **이 공모전의 것인지** CONTEST.md 기본 정보와 대조한다. 다른 공모전 이름이 보이면 사용자에게 확인한다(오염 방지).
3. 규칙 파일을 읽는다: `${CLAUDE_SKILL_DIR}/../../references/process.md`, `evidence-rules.md`, `org-research.md`, `intake-checklist.md`, `contest-types.md`(CONTEST.md의 유형 절).

## 절차
서브에이전트(Agent 도구)를 순서대로 부른다. 프롬프트에는 **작업 공간 절대 경로, 참조 파일 절대 경로(`${CLAUDE_SKILL_DIR}/../../references/…`), 템플릿 경로, 유형**을 넣는다. 서브에이전트는 대화 맥락을 모른다.

1. **contest:brief-analyst** → `10-research/brief.md`, CONTEST.md 기본 정보. 결과에서 "운영진에게 물을 것"과 "가장 위험한 제약"을 사용자에게 바로 보여 준다.
2. **contest:org-researcher** → `10-research/org.md`, `30-refine/evidence.md` E-ID 등록 시작.
3. **contest:domain-researcher** → `10-research/domain.md`, `10-research/competitors.md`(두 축 중복 점검). 2·3은 병렬 가능.
4. **contest:user-researcher** → `10-research/users.md`(페르소나·as-is·to-be 유저플로우·사람 이야기·시연 장면 후보).
5. 유형 보강: `ad`면 contest:org-researcher에 "전년도 수상작 문법 분석" 추가, `application`이면 contest:brief-analyst에 "문항 → 평가 축 매핑"과 "주최사 사업 모델" 추가, `program`이면 양식 고정 규칙(항목 추가·삭제 금지, ✅ 질문) 추출을 강조한다.
6. **통합 점검**(메인 에이전트가 직접):
   - evidence.md의 E-ID 번호 중복·누락, ✅/⚠️/❓ 개수.
   - 네 문서가 서로 어긋나는 사실(예: 주최사 인원 수가 org와 domain에서 다름)을 찾아 evidence에 "상충" 표기.
   - 기한·분량을 CONTEST.md 기본 정보 표(공식 마감·실질 마감·제출물 행)에 옮긴다. 세부는 brief.md §2(분량·형식)·§7(금지 사항)·§8(일정표)에 둔다.
   - `python3 -I ${CLAUDE_PLUGIN_ROOT}/scripts/scan_placeholders.py 10-research/brief.md 10-research/org.md 10-research/domain.md 10-research/competitors.md 10-research/users.md --allow 가정,예시값,확인`(이 형태 그대로, 따옴표 없이, 다른 명령과 `;`·`&&`로 잇지 말고 단독으로 — 허용 규칙과 같아야 승인 없이 실행된다)로 추측 채움이 없는지 확인.
7. CONTEST.md "단계와 관문" 표에서 1단계를 완료로 바꾸고 날짜를 적는다. 네 문서가 빈 템플릿 그대로이거나 evidence.md에 채워진 E-ID가 없으면 완료로 바꾸지 않는다(`/contest:status` 1단계 기준과 같다).

## 사용자에게 보고(짧게, 번호로)
- 요강에서 가장 위험한 제약 1~2개(글자 수·첨부 수·개인정보 금지·마감 시각).
- 주최사 5단 요약 각 한 줄.
- 분야에서 지금 바뀌는 것 2~3개, 빈틈 후보 2~3개.
- 운영진에게 물어볼 질문 목록(사용자가 직접 보낸다).
- 확인 못 한 것(❓ 목록).
- 다음: `/contest:topics`. 사용자가 "분야는 어디가 좋을까?"라고 물으면 topics에서 분야 기준 4개로 답한다고 안내.

## 금지
- 조사 단계에서 주제를 추천하거나 기획서 문장을 쓰지 않는다.
- 숫자를 출처 없이 적지 않는다. 2차 보도만 있으면 ⚠️, 원문 못 찾으면 ❓.
- 사용자·팀원의 경험을 지어내지 않는다(【 】로 비운다).
