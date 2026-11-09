# contest-agent 저장소 작업 규칙 (플러그인 개발용)

이 폴더는 Claude Code 플러그인 `contest`의 소스다. 공모전 작업 공간이 아니다(작업 공간은 `/contest:init`으로 따로 만든다).

## 구조와 역할
- `.claude-plugin/plugin.json`, `marketplace.json` — 매니페스트. 버전은 둘 다 같이 올린다.
- `skills/<name>/SKILL.md` — 명령 `/contest:<name>`. 500줄 이하. 공통 지식은 `references/`에 두고 `${CLAUDE_SKILL_DIR}/../../references/…`로 참조한다.
- `agents/<name>.md` — 서브에이전트. 본문이 시스템 프롬프트다. 대화 맥락을 모르므로 입력 파일 경로를 호출자가 넘긴다.
- `hooks/hooks.json` — PostToolUse(Write|Edit) → `scripts/post_write_check.sh` (경고만, exit 0).
- `scripts/` — 결정적 검사. 모두 `python3 -I`로 실행, 외부 패키지 없음.
- `templates/` — 작업 공간에 복사되는 문서 뼈대. `{{NAME}}`, `{{TYPE}}`, `{{DATE}}` 치환.
- `references/` — 절차·기준·사례. 사실은 `materials/research.md`·`playbook.md`에서만 가져온다.

## 수정 규칙
1. 사용자(최종은) 원칙 그대로: 계획 승인 전 구현 금지, 요청한 것만, 꼭 필요한 것만 수정, 테스트 먼저, any 금지, 시크릿은 .env.
2. 스킬·에이전트 본문은 한국어, 명령·파일명·프런트매터 키는 영어.
3. 새 규칙을 넣을 때 출처(사례 파일 또는 사용자 발언)가 있어야 한다. 추측 규칙은 "제안"으로 표시하고 사용자 확인 뒤 반영.
4. 스크립트를 고치면 `tests/`의 샘플로 재실행해 exit 코드와 출력이 기대와 같은지 확인한다(샘플이 없으면 먼저 만든다).
5. 검증: `claude plugin validate .` → `claude --plugin-dir .`에서 `/contest:help`, `/contest:init demo --type dev` 드라이런 → 에이전트가 `/agents`에 12개 보이는지 → 훅이 `50-deliverables/*.md` 저장 시 경고를 내는지.
6. 외부 플러그인(impeccable, im-not-ai) 코드를 복사하지 않는다. 명령 이름이 바뀌면 `references/deliverables.md` §3·§4와 `skills/make`만 고친다.
7. 개인정보(팀원 이름·연락처), API Key, 공모전 제출물 원문은 커밋하지 않는다. `materials/`에는 사용자가 넣는 자료만 두고 `.gitignore`로 민감 파일을 막는다.
