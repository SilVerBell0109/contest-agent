#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""공모전 작업 공간을 만든다. 공모전 하나당 폴더 하나.

사용법:
  python3 scaffold.py <폴더명> [--type dev|idea|ad|application|program] [--templates <templates 디렉터리>]
결과:
  <폴더명>/
    CONTEST.md            상태판(단계·관문·결정·마감)
    CLAUDE.md             이 작업 공간에서 Claude가 지킬 규칙
    00-inputs/            요강 원문·양식·사용자 제공 자료
    10-research/          brief.md org.md domain.md users.md competitors.md
    20-topics/            topics.md
    30-refine/            evidence.md design.md judge-preview.md
    40-spec/              PRD.md SRS.md traceability.md
    50-deliverables/      생성 산출물
    90-verify/            검수 보고
"""
import datetime as dt
import sys
from pathlib import Path

TYPES = {"dev": "개발형", "idea": "아이디어 제안형", "ad": "광고·크리에이티브형", "application": "프로그램 지원서형", "program": "학내·연수 프로그램형"}
LAYOUT = {
    "10-research": ["brief.md", "org.md", "domain.md", "users.md", "competitors.md"],
    "20-topics": ["topics.md"],
    "30-refine": ["evidence.md", "design.md", "judge-preview.md"],
    "40-spec": ["PRD.md", "SRS.md", "traceability.md"],
    "50-deliverables": [],
    "90-verify": [],
    "00-inputs": [],
}
# 작업 공간 파일명과 템플릿 파일명이 다를 때만 적는다.
SOURCES = {"judge-preview.md": "judge-review.md"}


def main(argv):
    if not argv or argv[0].startswith("-"):
        print(__doc__); return 2
    name = argv[0]
    ctype = "dev"
    templates = Path(__file__).resolve().parent.parent / "templates"
    i = 1
    while i < len(argv):
        if argv[i] not in ("--type", "--templates") or i + 1 >= len(argv):
            print(f"알 수 없는 옵션이거나 값이 없습니다: {argv[i]}\n{__doc__}"); return 2
        if argv[i] == "--type":
            ctype = argv[i + 1]
        else:
            templates = Path(argv[i + 1])
        i += 2
    if ctype not in TYPES:
        print(f"알 수 없는 유형: {ctype}. 선택: {', '.join(TYPES)}"); return 2
    root = Path(name)
    if root.exists() and any(root.iterdir()):
        print(f"폴더가 비어 있지 않습니다: {root}. 공모전 하나당 새 폴더를 쓰십시오."); return 1
    needed = [SOURCES.get(f, f) for files in LAYOUT.values() for f in files] + ["CONTEST.md", "CLAUDE.workspace.md"]
    missing = [t for t in needed if not (templates / t).is_file()]
    if missing:
        print(f"템플릿이 없습니다({templates}): {', '.join(missing)}. 아무것도 만들지 않았습니다."); return 2
    root.mkdir(parents=True, exist_ok=True)
    today = dt.date.today().isoformat()

    def render(body: str) -> str:
        return (body.replace("{{NAME}}", Path(name).name).replace("{{TYPE}}", TYPES[ctype])
                .replace("{{TYPE_KEY}}", ctype).replace("{{DATE}}", today))

    for d, files in LAYOUT.items():
        (root / d).mkdir(exist_ok=True)
        for f in files:
            body = (templates / SOURCES.get(f, f)).read_text(encoding="utf-8")
            (root / d / f).write_text(render(body), encoding="utf-8")
    (root / "50-deliverables" / ".gitkeep").touch()
    (root / "90-verify" / ".gitkeep").touch()
    (root / "00-inputs" / "README.md").write_text(
        "# 00-inputs\n\n요강 원문(PDF·HTML 저장본), 공식 양식 파일, 운영진 Q&A 캡처, 사용자가 직접 쓴 메모를 여기에 둔다.\n"
        "링크만 있는 것은 brief.md의 '출처' 절에 URL과 확인일을 적는다.\n", encoding="utf-8")
    for fname, tname in (("CONTEST.md", "CONTEST.md"), ("CLAUDE.md", "CLAUDE.workspace.md")):
        (root / fname).write_text(render((templates / tname).read_text(encoding="utf-8")), encoding="utf-8")
    print(f"작업 공간 생성: {root.resolve()}  (유형: {TYPES[ctype]})")
    print("다음: 00-inputs/에 요강·양식을 넣고 `/contest:research <URL 또는 파일>` 을 실행하십시오.")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
