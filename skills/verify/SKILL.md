---
name: verify
description: 산출물 제출 전 검수. 자리표시·문체·글자 수·숫자 추적 스크립트 → 사실 검증 → 요강 대조 → 90-verify/report. 사용자가 "검수해줘", "제출해도 될까", "체크해줘"라고 할 때 사용.
argument-hint: "[파일 경로…] [--plain] [--limit N] [--genre body|form|slides] [--strict]"
---

# /contest:verify — 검수

절차는 `${CLAUDE_SKILL_DIR}/../../references/verify-checklist.md`, 항목은 `${CLAUDE_SKILL_DIR}/../../templates/submission-checklist.md`. 스크립트는 `${CLAUDE_SKILL_DIR}/../../scripts/`(모두 `python3 -I`).

## 대상
`$ARGUMENTS`의 파일. 없으면 `50-deliverables/` 아래 최신 버전 파일 전부와 CONTEST.md 산출물 표의 미검수 항목.

## 절차(순서대로, 결과를 표로 모은다)
1. `scan_placeholders.py <파일>` — 제출용 txt는 `--plain`(마크다운 잔재까지). 허용 태그 없음. 0건이어야 ✅.
2. `check_style.py <파일> --genre <장르>` — S1 0건 ✅. `--strict`면 S2 ≥3도 ❌. 코드·양식 항목명은 제외.
3. `count_chars.py <파일> --limit N` — brief.md의 글자 수 제한. 줄바꿈 2자(crlf) 기준도 제한 안이어야 ✅.
4. `trace_numbers.py <파일> --against 30-refine/evidence.md 40-spec/PRD.md 40-spec/SRS.md` — 미추적 0건 ✅. 미추적은 E-ID 등록 또는 [예시값]/[가정] 표기 후 제출 전 해소.
5. im-not-ai 설치 시 `/humanize-scan <파일>` 결과(AI 패턴 밀도)를 기록.
6. **fact-checker** 호출(수동 전수 대조: 인용 존재, 요약↔본문, 산출물 이름 통일, 경쟁 평가 공정성, 스펙 밖 내용, 사람·경험, 절대 표현).
7. 요강 대조(brief.md §2·§7): 분량·형식·용량·첨부 수·파일명·메일 제목·CC·기재 금지·필수 포함(AI 고지·라이선스·해시태그).
8. 일관성(traceability §4): 새 기능이 목표·KPI·유저플로우·일정·역할·예산·기대효과에 모두 있는가. 텍스트판↔그림판 표 일치. 기획서↔슬라이드↔README 이름·수치 일치.
9. 개인정보·보안: 실명·연락처·소속, 공유 링크·GitHub 노출, API Key, `.env` 커밋 여부(`git ls-files | grep -E '\.env$'`), 서명·동의서는 사용자 몫.
10. 라이선스 표와 뺀 데이터, 심사표 대응(traceability §1 빈칸 0), AI 활용 고지가 실제 범위와 맞는지.
11. 접수 절차 리허설: 폼 필드 ↔ txt 문단 대응, 임시저장 ≠ 제출, 첨부 순서, 제출 확인 메일.

## 출력
`90-verify/report-<날짜>.md`: 항목별 ✅/❌/⚠️, 고칠 위치(파일·절·줄), 담당(사용자/에이전트), 재검수 필요 여부. CONTEST.md 산출물 표 갱신.

사용자에게: ❌ 목록(위치 포함)과 사용자가 직접 해야 할 것(【 】 채우기, 서명, 폼 입력). ❌가 하나라도 있으면 **"제출 가능"이라고 말하지 않는다**. 모두 ✅면 "스크립트·사실 검증·요강 대조 기준으로 제출 가능. 최종 확인은 사용자" 한 줄.
