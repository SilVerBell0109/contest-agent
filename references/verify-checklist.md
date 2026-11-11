# verify-checklist.md — 제출 전 검수 절차

체크리스트 본문은 templates/submission-checklist.md. 여기는 실행 순서와 스크립트 사용법. 아래 `${CLAUDE_PLUGIN_ROOT}`는 이 파일에서는 치환되지 않는다. 실제 실행은 `/contest:verify` 절차 1~4의 명령(치환된 플러그인 경로) 그대로 한다.

## 1. 실행 순서 (`/contest:verify <산출물 경로…>`)
1. **자리표시**: `python3 -I ${CLAUDE_PLUGIN_ROOT}/scripts/scan_placeholders.py <파일> [--plain]` — 제출 본문(txt)은 `--plain`으로 마크다운 잔재까지. 0건이어야 통과.
2. **문체**: `python3 -I ${CLAUDE_PLUGIN_ROOT}/scripts/check_style.py <파일> --genre body|form|slides [--strict]` — S1 0건. 설치돼 있으면 `/humanize-scan`도.
3. **글자 수**: `python3 -I ${CLAUDE_PLUGIN_ROOT}/scripts/count_chars.py <파일> --limit N [--start 표식 --end 표식]` — 줄바꿈 2자 기준으로도 제한 안.
4. **숫자 추적**: `python3 -I ${CLAUDE_PLUGIN_ROOT}/scripts/trace_numbers.py <산출물> --against 30-refine/evidence.md 40-spec/PRD.md 40-spec/SRS.md` — 미추적 0건. 미추적은 E-ID 등록 또는 [예시값]·[가정] 표기 후 제출 전 해소.
5. **fact-checker 서브에이전트**: 숫자 일치, 인용 존재, 요약↔본문 일치, 경쟁 평가 공정성, 산출물 이름 통일, 스펙 밖 내용.
6. **일관성**: traceability §4 — 새 기능이 목표·KPI·유저플로우·일정·역할·예산·기대효과에 있나. 텍스트판·그림판 일치.
7. **형식**: 페이지·글자 크기·파일 형식·용량·첨부 개수·파일명·메일 제목·CC.
8. **개인정보·보안**: 실명·연락처·소속 금지 규정, 공유 링크·GitHub 노출, API Key, .env.
9. **라이선스 표**와 뺀 데이터.
10. **심사표 대응**: traceability §1 빈칸 없음, 감점 선제 대응, 가산점 조건.
11. **AI 활용 고지** 문장이 실제 범위와 맞는지.
12. **접수 절차**: 폼 필드 → 붙여넣기용 txt → 임시저장 → 첨부 → 최종 제출(임시저장≠제출).

결과는 `90-verify/report-<날짜>.md`에 항목별 ✅/❌와 고칠 위치로 기록하고 CONTEST.md 산출물 표를 갱신한다. ❌가 하나라도 있으면 "제출 가능"이라고 말하지 않는다.

## 2. 글자 수·형식의 함정
- 사이트가 줄바꿈을 2자로 셀 수 있다. 보수적 기준으로 맞춘다.
- 일반 텍스트 칸에 붙일 때 살아남는 기호만 쓴다(□, ①, →). 마크다운 굵게·헤더·표는 깨진다.
- 폼에 타이머가 있으면 들어가자마자 임시저장.
- 첨부 파일명 규칙(지원자명_보충자료명)과 용량, PDF 한글 폰트 임베드.
- pptx는 공식 템플릿과 대조 검증, PDF 변환 후 장별 이미지로 레이아웃 확인.

## 3. 산출물끼리의 대조
- 지원서 txt ↔ 편집용 문서의 문단 수·내용 완전 일치.
- 요약 칸 ↔ 본문(BM·숫자·기능 이름).
- 기획서 ↔ 슬라이드 ↔ README의 서비스명·기능명·수치.
