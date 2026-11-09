#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""산출물에 남은 자리표시·메타 문구·마크다운 잔재를 찾는다.

사용법:
  python3 scan_placeholders.py <파일...> [--allow 가정,예시값] [--plain]
  --allow  : 허용할 표기(쉼표 구분). 기본은 전부 금지.
  --plain  : 일반 텍스트 제출물 검사 모드(마크다운 기호 **, #, | 도 잡음)
종료 코드: 발견 0건이면 0, 아니면 1.
"""
import re
import sys
from pathlib import Path

PATTERNS = {
    "자리표시(【】)": re.compile(r"【[^】]*】"),
    "[확인 필요]": re.compile(r"\[\s*(원문\s*)?확인\s*필요\s*\]"),
    "[가정]": re.compile(r"\[\s*가정\s*\]"),
    "[예시값]": re.compile(r"\[\s*예시값?\s*\]"),
    "[작성 예정]/[확정 필요]": re.compile(r"\[\s*(작성\s*예정|확정\s*필요|기입\s*필요|링크\s*추가\s*예정)\s*\]"),
    "(기입 필요)": re.compile(r"\(\s*(기입\s*필요|이력\s*보완\s*요망|제\s*추측입니다\s*—\s*삭제)\s*\)"),
    "TODO/TBD/FIXME": re.compile(r"\b(TODO|TBD|FIXME|XXX)\b"),
    "메타 지시문": re.compile(r"\((사용자\s*원칙|메모|이\s*줄은\s*지울\s*것)[^)]*\)|…?\.png를\s*삽입|배점에\s*유리|제출\s*전에\s*(이\s*메모|지운다|지워)"),
    "빈 괄호 값": re.compile(r"\[\s*\]|\(\s*\)|○○|◯◯|xxx|N건|N명|N%"),
    "양식 안내문 잔재": re.compile(r"✅\s*(무엇을|기존|관련|시간|접근|결과물)|파란\s*안내문"),
}
PLAIN_ONLY = {
    "마크다운 굵게(**)": re.compile(r"\*\*[^*]+\*\*|\*\*"),
    "마크다운 헤더(#)": re.compile(r"^\s{0,3}#{1,6}\s", re.M),
    "마크다운 표(|)": re.compile(r"^\s*\|.*\|\s*$", re.M),
    "취소선 변환 위험(~)": re.compile(r"~[^~\n]+~"),
}


def scan(path: Path, allow: set, plain: bool):
    text = path.read_text(encoding="utf-8", errors="replace")
    hits = []
    pats = dict(PATTERNS)
    if plain:
        pats.update(PLAIN_ONLY)
    for label, rx in pats.items():
        if any(a in label for a in allow):
            continue
        for m in rx.finditer(text):
            line_no = text.count("\n", 0, m.start()) + 1
            snippet = text[max(0, m.start() - 20): m.end() + 20].replace("\n", " ")
            hits.append((line_no, label, snippet.strip()))
    return hits


def main(argv):
    files, allow, plain = [], set(), False
    i = 0
    while i < len(argv):
        a = argv[i]
        if a == "--allow":
            allow = set(x.strip() for x in argv[i + 1].split(",") if x.strip()); i += 2; continue
        if a == "--plain":
            plain = True; i += 1; continue
        files.append(Path(a)); i += 1
    if not files:
        print(__doc__); return 2
    total = 0
    for f in files:
        if not f.exists():
            print(f"[없음] {f}"); continue
        hits = scan(f, allow, plain)
        total += len(hits)
        print(f"== {f} : {len(hits)}건")
        for line_no, label, snip in hits:
            print(f"  L{line_no:<5} {label:<22} … {snip} …")
    print(f"\n합계 {total}건" + ("" if total == 0 else " → 제출 전에 전부 해소해야 합니다."))
    return 0 if total == 0 else 1


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
