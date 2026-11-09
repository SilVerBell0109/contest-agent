---
name: status
description: 작업 공간의 CONTEST.md 상태판을 실제 파일 상태와 맞춰 갱신하고 다음 할 일·마감까지 남은 날·사용자가 채워야 할 것을 보여 준다. "어디까지 했지", "다음 뭐 해", "상태" 질문에 사용.
argument-hint: "[--fix]"
allowed-tools: Read, Glob, Grep, Edit, Bash(date *), Bash(ls *), Bash(python3 -I ${CLAUDE_PLUGIN_ROOT}/scripts/scan_placeholders.py *)
---

# /contest:status — 상태판

## 절차
1. 현재 폴더(또는 상위)의 `CONTEST.md`를 찾는다. 없으면 `/contest:init` 안내.
2. 실제 파일로 단계 판정:
   - 1단계: `10-research/brief.md`·`org.md`·`domain.md`·`competitors.md`·`users.md`가 있고 자리표시 스캔 통과(exit 0. 사용자가 채울 `【 】`은 허용하고 5에서 센다). 스캔 명령(이 형태 그대로, 따옴표 없이, 다른 명령과 `;`·`&&`로 잇지 말고 단독으로 — 허용 규칙과 같아야 승인 없이 실행된다): `python3 -I ${CLAUDE_PLUGIN_ROOT}/scripts/scan_placeholders.py 10-research/brief.md 10-research/org.md 10-research/domain.md 10-research/competitors.md 10-research/users.md --allow 가정,예시값,확인,자리표시`
     - 빈 템플릿은 스캔을 통과하므로 내용도 본다: brief.md §1 표에 원문과 출처가 채워진 행이 1개 이상, `30-refine/evidence.md` 원장에 주장이 채워진 E-ID 행이 1개 이상(템플릿의 빈 E001 행은 세지 않는다). 하나라도 아니면 1단계는 ⏳.
   - 2단계: `20-topics/topics.md`에 관문 1 기록(선택 번호·날짜).
   - 3단계: `30-refine/design.md` + `judge-preview.md`, CONTEST.md 3단계 완료 표시.
   - 4단계: `40-spec/PRD.md` 머리에 `승인:`.
   - 5단계: `50-deliverables/` 산출물별 최신 버전과 `90-verify/` 보고서 유무.
3. CONTEST.md 표와 다르면 `--fix`일 때만 고치고, 아니면 차이를 보고한다.
4. 마감: CONTEST.md 기본 정보 표의 공식 마감·실질 마감 행(비어 있으면 `10-research/brief.md` §8 일정표)과 오늘(`date`)을 비교해 남은 날을 적는다. 실질 마감이 지났으면 굵게가 아니라 첫 줄에 적는다.
5. "사용자가 채워야 할 것" 목록: `10-research/`·`40-spec/`·`50-deliverables/` 문서와 CONTEST.md의 `【 】` 개수(`python3 -I ${CLAUDE_PLUGIN_ROOT}/scripts/scan_placeholders.py <파일…>` 출력에서 `자리표시(【】)` 줄 수, 실행 방식은 위와 같다)와 CONTEST.md 열린 질문.

## 출력(사용자에게, 10줄 이내)
- 공모전 이름·유형·남은 날(실질/공식).
- 단계 ✅/⏳ 한 줄.
- 산출물 표(이름·버전·fact/style/verify/judge).
- 다음 명령 하나.
- 사용자가 직접 할 것(【 】 수, 서명·폼·운영진 문의).
