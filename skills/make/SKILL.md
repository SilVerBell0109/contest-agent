---
name: make
description: 공모전 5단계. 승인된 PRD·SRS를 바탕으로 사용자가 지시한 산출물(기획서·지원서·슬라이드·보충자료·화면예시·mvp-plan·mvp·project·readme·매뉴얼·시연대본·발표대본·예상질문·회고·custom)을 초안 → 사실 검증 → 문체 → 검수 → (모의 심사) 순서로 만든다.
argument-hint: "<종류> [--template 00-inputs/양식.docx] [--limit 글자수] [--judge] [--no-humanize] [설명…]"
---

# /contest:make — 5단계 산출물 제작

`$0` = 종류, 나머지 `$ARGUMENTS` = 옵션·설명. 종류별 규칙은 `${CLAUDE_SKILL_DIR}/../../references/deliverables.md`, 문체는 `style-ko.md`, 개발은 `mvp-dev.md`.

## 사전 확인
1. `40-spec/PRD.md` 머리에 승인 표시가 없으면 `/contest:spec`으로 돌려보낸다. 예외: `회고`, `예상질문`(기존 산출물 대상).
2. 공식 양식(`--template` 또는 00-inputs의 docx/pptx/hwp)이 있으면 양식 항목이 곧 목차다. 양식 원문을 먼저 읽고 항목·글자 크기·금지(항목 추가·삭제)·안내문 삭제 규칙을 `50-deliverables/<종류>/format-rules.md`에 적는다.
3. 글자 수 제한(`--limit` 또는 brief.md)이 있으면 줄바꿈 2자 기준으로 보수적으로 잡는다.

## 공통 파이프라인
1. **초안**: 템플릿(`${CLAUDE_SKILL_DIR}/../../templates/<해당>.md`)을 PRD·SRS·evidence 내용으로 채운다. 숫자는 E-ID가 있는 것만, 사용자 경험·팀원 정보·지원 동기는 `【 】`, 가정은 `[가정]`, 예시값은 `[예시값]`. 파일명에 버전(`v1`), 머리에 변경 로그와 제출 전 지울 메모.
   - 종류별 담당: 슬라이드·발표대본 → **deck-builder**, 화면예시 → **ui-designer**, mvp·project → **mvp-builder**, 나머지 문서는 메인 에이전트가 직접 쓴다.
2. **사실 검증**: **fact-checker** 호출. '차단' 0이 될 때까지 고친다(고치는 쪽은 초안 작성자).
3. **문체**(`form`·코드 제외): im-not-ai가 설치돼 있고 `--no-humanize`가 아니면 `/humanize-scan <파일>` → 필요 시 `/humanize <파일>`(의미 불변·30% 경고·50% 중단). 그다음 **style-editor** 호출(check_style S1 0건, 전/후 표).
4. **검수**: `/contest:verify <파일>` 절차 실행(자리표시 `--plain`은 제출용 txt에, 글자 수, 숫자 추적, 요강 대조). ❌가 있으면 1로 돌아간다.
5. **모의 심사**(`--judge` 또는 기획서·슬라이드·지원서 기본): **judge-simulator** → 90-verify. 깎인 항목을 고치고 재검수. 최대 2회.
6. **인도**: 편집 가능한 형태(md + docx/pptx/pdf, 요청 시 Google Doc) + 폼 접수면 붙여넣기용 `.txt`(□·①·→만, 마크다운 없음). CONTEST.md 산출물 표에 fact/style/verify/judge 결과와 버전을 기록.

## 종류별 요점(상세는 deliverables.md)
- `기획서`: 양식 없으면 proposal-generic 14절. AI 활용 고지 문단 필수. 기대효과 절제. 출처는 각주 번호 + 부록.
- `지원서`: 문항 → 평가 축 매핑표 먼저 보여 주고 승인 뒤 초안. 지원 동기는 사용자가 직접(【 】). 글자 수 count_chars.
- `슬라이드`: outline(slides-12) 먼저 → 사용자 확인 → deck-builder. 발표자 노트 구어체.
- `보충자료`: 한 장에 한 증명. 첨부 수·용량·파일명 규칙.
- `화면예시`: 실제 UI 조사 → HTML/CSS 렌더 → AI 티 제거 → 화면마다 기획서 항목 번호 → PDF.
- `mvp-plan`: 기능×통과 기준, 한 줄기, 일정+버퍼, 하네스, 데모 방식. **관문 4: 사용자 승인 전 코드 금지.** 승인 문구를 머리에 기록.
- `mvp` / `project`: mvp-plan 승인 확인 → mvp-builder(테스트 먼저, any 금지, .env, 한 줄기 완성, 하네스 수치). UI는 ui-designer + impeccable.
- `readme`·`매뉴얼`: 기존/응용/신규 코드 구분, 오프라인 설치, 연결 확인, 좋은/나쁜 질문.
- `시연대본`·`발표대본`: 60~90초 4장면 / Assertion-Evidence, 첫 질문의 한 문장 답.
- `예상질문`: judge-bank 기준 10개 + 한 문장 답 + 절 번호.
- `회고`: 결과·효과 있었던 패턴·피드백·지원서용 문단(경험 서술 순서).
- `custom <설명>`: 위 규칙을 적용해 사용자가 설명한 것. 어느 템플릿이 가장 가까운지 먼저 말한다.

## 사용자 말 → 동작
- "AI 티 나" + 문장 하나 → 그 패턴을 문서 전체에서 찾아 고치고 전/후 표 제시.
- "프로젝트 외 내용 다 빼줘" → 사족·캡션·푸터·설명 삭제.
- "내가 읽고 고칠 수 있게" → docx/Google Doc + md 동시 제공.
- "전부 반영" → 변경 기록에 그대로 적고 재검수.
- "심사가 목적이야" → 앱 대신 반응형 웹, 한 흐름 완성, 근거 시트 시연.

## 금지
- PRD·SRS에 없는 기능·숫자를 산출물에서 새로 만드는 것. 필요하면 `/contest:spec --update`.
- 자리표시·메타 문장이 남은 파일을 "제출 가능"이라고 말하는 것.
- 사용자 승인 없는 mvp 코드 작성. 시크릿 하드코딩. any 타입.
- 실명·연락처·소속 금지 규정을 어기는 문장. 공식 로고·타인 이미지 삽입.
