---
name: refine
description: 공모전 3단계 고도화. 선택된 주제를 주최사·근거·유저플로우·리스크·심사 대응 축으로 깊게 설계해 30-refine/design.md를 만들고 모의 심사로 약점을 메운다. 관문 2(자동 4항목)로 끝난다.
argument-hint: "[--rounds N] [사용자의 한 줄 지시…]"
allowed-tools: Bash(python3 -I ${CLAUDE_PLUGIN_ROOT}/scripts/trace_numbers.py *), Bash(python3 -I ${CLAUDE_PLUGIN_ROOT}/scripts/scan_placeholders.py *)
---

# /contest:refine — 3단계 고도화 (관문 2)

고도화의 계기는 항상 사용자의 한 줄이었다("더 자세히 조사해줘", "KIC라서 넣을 기능은?", "심사위원이 뭘 물을까?"). `$ARGUMENTS`에 그 한 줄이 있으면 그것이 이번 라운드의 목표다. 없으면 아래 라운드 순서를 따른다(라운드마다 겨냥할 방향은 `${CLAUDE_SKILL_DIR}/../../references/design-patterns.md` §5).

## 사전 확인
- `20-topics/topics.md`의 관문 1 기록(선택 번호)이 없으면 `/contest:topics`로 돌려보낸다.
- 읽을 규칙: `design-patterns.md`, `evidence-rules.md`, `judge-bank.md`, `user-criteria.md`, 유형별 절(`contest-types.md`).

## 라운드 순서
각 라운드는 **조사 → design.md 갱신 → evidence.md 등록 → 사용자에게 3줄 보고** 로 끝낸다. `--rounds N`이 없으면 1~5를 한 번씩 돈다. 어느 경우든 관문 2 전에 6(모의 심사)을 한 번 이상(최대 2회) 한다. 서브에이전트를 부를 때는 프롬프트에 작업 공간 절대 경로와 이번 라운드 목표를 넣는다(서브에이전트는 대화 맥락을 모른다).
1. **주최사 밀착**: "주최사라서 넣는 기능" 2개 이상(org.md 5단·자산에서), 호칭·용어 적용, 주최사 민감 쟁점(국감·제재·사고)에 대한 선제 문장. contest:org-researcher 추가 호출 가능.
2. **근거 강화**: 핵심 주장 5개마다 1차 자료 E-ID. 직접 셀 수 있는 숫자는 센다(건수·인원·비율) — 센 방법을 evidence에. 연출한 숫자를 실측으로 교체. 과장 수위 조정("~로 바꾼다" → "~하려고 한다", "N건 이내" → "N건 안팎").
3. **유저플로우·시연**: users.md to-be 흐름을 화면·입력·반응 단위로 확정, 전후 시각표, 시연 장면 3~4개, 빈 상태·오류·오프라인 처리. contest:user-researcher 추가 호출 가능.
4. **범위·기술·일정**: 한 줄기 완성 기준으로 P0/P1/P2, 공개 벤치마크·데이터 라이선스로 범위를 자른 근거, 기능×통과 기준, 일정+버퍼+축소 순서, 신뢰성 설계(결정적 계산, 검증 게이트, 상태 전이·멱등, 인젝션 방어), 보안·개인정보 기본값 표. 뺀 데이터·기능과 이유를 "범위 밖"에.
5. **경쟁·차별**: 기능 단위 ○△× 비교표(△는 조건부로 인정, 공정하게), "이미 있지 않나"에 대한 한 문장 답, 폐기 후보의 가치를 확장 1순위로 흡수.
6. **모의 심사**: contest:judge-simulator 호출 → 응답 전문을 `30-refine/judge-preview.md`에 저장(배점표 채점, 예상 질문 10개 + 한 문장 답, 첫 질문). 점수가 깎인 위치를 design.md에 반영. 최대 2회.

## 관문 2 — 자동 점검 4항목(모두 통과해야 다음 단계)
1. design.md의 모든 숫자가 E-ID를 가진다: `python3 -I ${CLAUDE_PLUGIN_ROOT}/scripts/trace_numbers.py 30-refine/design.md --against 30-refine/evidence.md`(이 형태 그대로, 따옴표 없이, 다른 명령과 `;`·`&&`로 잇지 말고 단독으로 — 허용 규칙과 같아야 승인 없이 실행된다).
2. 자리표시·메타 문장 없음(가정·예시값·확인 필요 태그는 허용): `python3 -I ${CLAUDE_PLUGIN_ROOT}/scripts/scan_placeholders.py 30-refine/design.md --allow 가정,예시값,확인`(실행 방식은 1과 같다).
3. judge-preview.md의 예상 질문 10개 모두에 "답이 있는 절 번호"가 있다(보강 필요 0).
4. 심사 기준 항목마다 design.md에 대응 절이 있다(traceability 초안: 심사 기준 ↔ design 절).
실패 항목은 고치고 다시 돈다. 통과하면 CONTEST.md 3단계 완료, 다음: `/contest:spec`.

## 사용자에게 보고(라운드마다 3줄, 끝에 요약)
- 이번 라운드에서 바뀐 결정 1~2개와 이유 한 문장.
- 새로 확인한 숫자(E-ID)와 교체한 연출 숫자.
- 사용자에게 물을 것(번호 선택지 3개 이내). 사용자는 "전부 반영"처럼 짧게 답한다 → design.md 변경 기록에 그대로 적는다.

## 금지
- 조사 없이 기능을 늘리는 것. 기능 추가는 항상 심사 기준 대응·주최사 자산·사용자 장면 중 하나에 묶여야 한다.
- 사용자·팀원 경험을 지어내는 것(【 】).
- 관문 2 미통과 상태에서 spec으로 넘어가는 것.
