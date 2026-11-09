# deliverables.md — 산출물 종류별 제작 규칙

모든 산출물은 40-spec/PRD.md·SRS.md와 30-refine/evidence.md에서만 내용을 가져온다. 제작 순서는 공통: 초안 → fact-checker → style-editor → verify 스크립트 → (judge-simulator) → 사용자. 파일은 `50-deliverables/<종류>/` 아래에 두고 이름에 버전을 적는다.

## 1. 종류 목록 (`/contest:make <종류>`)

| 종류 | 템플릿 | 핵심 규칙 |
|---|---|---|
| `기획서` | templates/proposal-generic.md 또는 00-inputs의 공식 양식 | 양식이 있으면 양식 항목이 목차. 본문 합쇼체+1인칭. 숫자마다 참고자료 번호. 사람 경험 【】 |
| `지원서` | brief.md §6 폼 필드 | 문항 → 평가 축 매핑표 먼저. 글자 수(count_chars) 준수. 붙여넣기용 `.txt`(□·①·→만) 동시 생성 |
| `슬라이드` | templates/slides-12.md 또는 공식 pptx 템플릿 | 헤드라인 한 줄+근거 하나, 장당 250~400자, 도식 밝은 배경·한글 폰트. pptx면 저장마다 템플릿 대조 검증 |
| `보충자료` | templates/supplement.md | 한 장에 한 증명(타임라인·연쇄·전후 비교). 첨부 개수·용량·파일명 규칙 |
| `화면예시` | templates/supplement.md 별도 절 | 실제 UI 조사 → HTML/CSS 렌더 2x → 장식 배지·상담 말투 제거 → PDF. 화면마다 기획서 항목 번호. 기존 디자인 체계 유지 |
| `mvp-plan` | templates/mvp-plan.md | 기능×통과 기준, 한 줄기 완성, 일정+버퍼, 하네스, 스냅샷 데모. **사용자 승인 전 코드 금지** |
| `mvp` | mvp-plan 승인본 | mvp-builder: 테스트 먼저 → 구현. any 금지, .env. UI는 impeccable(아래 §3) |
| `project` | SRS §8 | 단계별(PoC → 수직 절단 → MVP → 평가 → 코드 프리즈). 단계마다 통과 기준과 구현 상태 갱신 |
| `readme` | templates/README-project.md | 실행·테스트·데모 URL·라이선스·기존/신규 코드 구분 |
| `매뉴얼` | templates/manual.md | 온·오프라인 설치, 설정 파일 전문, 연결 확인, 좋은 질문/나쁜 질문, FAQ |
| `시연대본` | templates/demo-script.md | 60~90초 장면 4개, 실제 데이터, 실패 대비 녹화본 |
| `발표대본` | templates/demo-script.md §B + slides | Assertion-Evidence, 발표자 노트는 구어체, 10분이면 시연 3~4분 |
| `예상질문` | templates/judge-review.md §6, references/judge-bank.md | 10개 + 한 문장 답 + 근거 E-ID. 첫 질문은 외울 수 있게 |
| `회고` | templates/retrospective.md | 결과·효과 있었던 패턴·피드백·지원서용 문단 |
| `custom <설명>` | — | 위 규칙을 적용해 사용자가 설명한 산출물 |

## 2. 문서 산출물 공통
- 작업용 사본에서 쓰고 공식 양식으로 옮긴 뒤 [최종] 파일로 확정. 양식에서 직접 고친 내용은 작업용에도 되가져온다.
- 문서 머리에 메모(글자 수, 붙여넣기 방법, 제출 전 지울 것)를 두고 제출 전 지운다.
- 출처 표기는 본문 각주 [n] + 부록 목록(매체·제목·날짜·URL). 문장마다 괄호 출처를 달지 않는다.
- AI 활용 고지 문단을 넣는다. 실제 작업 범위와 맞게(축소 표현은 심사위원이 가장 먼저 의심하는 항목이라 오히려 손해). 예: "국내외 사례 조사와 자료 요약, 초안 작성에 생성형 AI(Claude)를 썼습니다. 주제 선정, 아이디어 구성, 사실 확인, 최종 수정은 제가 직접 했습니다."
- 기대효과는 절제. "기대효과를 크게 적고 싶지는 않습니다. 확실한 건 ~라는 정도입니다."
- 편집 가능한 형태(Google Doc·docx)와 붙여넣기용 txt를 함께 준다. 사용자는 "내가 읽고 수정할 수 있게"를 원한다.

## 3. UI·MVP 산출물과 impeccable
설치돼 있으면(`/impeccable`이 뜨면) 다음 순서. 없으면 references/mvp-dev.md §4 폴백 규칙.
1. `/impeccable init` — PRODUCT.md를 PRD §1·§5·§6으로 채운다(사용자 질문에 PRD 내용으로 답).
2. `/impeccable shape` — 코드 전에 UX를 계획(한 줄기 흐름 기준).
3. 구현 후 `/impeccable critique <화면>` → `/impeccable audit` → `/impeccable polish` → `/impeccable harden`(오류·빈 상태·i18n·overflow) → `/impeccable adapt`(화면 크기) → `/impeccable onboard`(첫 실행·빈 상태).
4. 좁게 요청한다("/impeccable critique the 결과 카드"). 전체 페이지 한 번보다 한 영역 깊게.
5. 라이브 모드는 로컬 개발 서버에서만. 배포 사이트에 주입하지 않는다.

## 4. 문체 단계와 im-not-ai
설치돼 있으면(Skill 도구 목록에 `humanize-korean:humanize-scan`이 있으면): Skill 도구로 `humanize-korean:humanize-scan`을 불러 전체 패스가 필요한지 보고, 필요하면 `humanize-korean:humanize-korean`(장르·강도 옵션은 스킬 도움말 참고). 원칙은 그대로 따른다: 의미·수치·고유명사·직접 인용 불변, 탐지된 곳만 수정, 장르 유지, 변경률 30% 경고·50% 중단. 그다음 `scripts/check_style.py --genre body` 로 S1 0건 확인. 없으면 references/style-ko.md 규칙으로 style-editor가 직접 고친다.

## 5. 발표 자료 규칙 (Table_shot·KIC에서 확정)
- 제목이 주장, 본문은 근거 하나(Assertion-Evidence). 10/20/30.
- 짧은 문구, 실측 숫자, 증상-원인-해결 표, 전후 비교, 한계 공개.
- 사족 제거: 프로젝트 외 설명·캡션·푸터 삭제.
- 발표자 노트는 반말 구어체 대본("책 보다가 GPT한테 물어보고 싶을 때").
- 시연 장면을 미리 3~4개 정하고 백업 캡처를 준비.
- 비개발 팀원을 위한 코드 해설 문서(파일별 라인 범위)로 질의응답 대비.

## 6. 영상
- 1차 접수 시연 60~90초(현대차), 소개 영상 2~3분(알파). 장면 4개를 먼저 정한다. 실제 데이터, 가상이면 화면에 표시.
