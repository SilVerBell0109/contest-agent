---
name: init
description: 공모전 하나를 위한 작업 공간 폴더를 만든다(CONTEST.md, CLAUDE.md, 00-inputs~90-verify, 템플릿 복사). 새 공모전을 시작할 때 사용.
argument-hint: "<폴더명> [--type dev|idea|ad|application|program]"
disable-model-invocation: true
allowed-tools: Bash(python3 -I ${CLAUDE_PLUGIN_ROOT}/scripts/scaffold.py *), Bash(ls *), Read, Write, Edit
---

# /contest:init — 작업 공간 만들기

공모전 하나 = 폴더 하나. 다른 공모전 자료가 섞이면 주제가 오염된다(실제 사례: 다른 공모전 링크가 붙어 엉뚱한 후보가 생김). 반드시 새 폴더에서 시작한다.

## 인자
`$ARGUMENTS` = `<폴더명> [--type …]`. 유형을 안 주면 AskUserQuestion 도구로 아래 번호 중 하나를 고르게 한다(같은 턴 안에서 답을 받아야 이 명령의 실행 허용이 유지된다). 그 도구를 쓸 수 없으면 목록을 보여 주고 `/contest:init <폴더명> --type <유형>`으로 다시 실행해 달라고 한 뒤 멈춘다:
1. dev — 개발형(MVP·GitHub·시연 영상·발표)
2. idea — 아이디어 제안형(기획서 본문 + 첨부)
3. ad — 광고·크리에이티브(브리프보드·시안)
4. application — 프로그램·해커톤 지원서(문항별, 글자 수)
5. program — 학내·연수 프로그램(신청서·중간보고서, 양식 고정)

## 절차
1. 실행(이 형태 그대로, 따옴표 없이, 다른 명령과 `;`·`&&`로 잇지 말고 단독으로 — 허용 규칙과 같아야 승인 없이 실행된다): `python3 -I ${CLAUDE_PLUGIN_ROOT}/scripts/scaffold.py <폴더명> --type <유형> --templates ${CLAUDE_PLUGIN_ROOT}/templates`
   - 폴더가 비어 있지 않으면 스크립트가 거부한다. 다른 이름을 제안한다.
2. 생성 결과(`ls`)를 확인하고 사용자에게 **채워야 할 것**을 묻는다(한 번에, 번호로):
   1. 요강 URL 또는 PDF/이미지 → `00-inputs/`에 넣거나 URL을 알려 달라.
   2. 공식 양식 파일(docx·pptx·hwp) 있으면 `00-inputs/`에.
   3. 참가 형태(개인/팀, 팀이면 인원과 역할 — 팀원 정보는 사용자가 직접 쓴다).
   4. 공식 마감과 실질 마감(기본값: 공식 마감 − 3일, 팀이면 − 5일).
   5. 이미 정한 주제나 후보가 있는가(있으면 topics 단계에서 1번 후보로 둔다).
3. 답을 `CONTEST.md` 기본 정보 표와 "사용자가 채워야 할 것"에 적는다. 모르는 항목은 비운 채 둔다.
4. 사용자 자산 연결: 본인 문체 가이드 파일(예: `~/Downloads/보고서_말투_가이드.md`)이 있는지 묻고 경로를 받는다. 있으면 복사할지 확인한 뒤 Read로 읽어 `${CLAUDE_PLUGIN_DATA}/style/user-report-tone.md`에 Write로 저장한다(이미 있으면 덮어쓸지 먼저 묻는다). 이 위치는 플러그인 업데이트에도 남고 모든 작업 공간이 함께 쓰며 문체 기준에서 우선 적용된다. 플러그인을 제거하면(`--keep-data` 없이) 지워지므로 원본은 따로 둔다고 알린다.
5. 다음 명령 안내: 새 폴더로 옮겨 Claude Code를 다시 연다(`cd <폴더명>` 뒤 `claude` — 작업 공간의 CLAUDE.md가 읽히고 다른 명령이 그 폴더를 기준으로 동작한다). 그다음 `/contest:research <요강 URL 또는 00-inputs 파일>` 또는 `/contest:run <요강>`.

## 금지
- 요강·주제·팀원 정보를 추측해 채우지 않는다.
- 기존 폴더를 덮어쓰지 않는다.
