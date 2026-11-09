#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""산출물에 남은 자리표시·메타 문구·마크다운 잔재를 찾는다.

사용법:
  python3 scan_placeholders.py <파일...> [--allow 가정,예시값] [--plain]
  --allow  : 허용할 표기(쉼표 구분). 기본은 전부 금지.
  --plain  : 일반 텍스트 제출물 검사 모드(마크다운 기호 **, #, |, 체크박스도 잡음)
종료 코드: 발견 0건이면 0, 아니면 1, 사용법 오류·대상 파일 없음 2(있는 파일은 먼저 검사해 보여 준다).
"""
import re
import sys
from pathlib import Path

PATTERNS = {
    "자리표시(【】)": re.compile(r"【[^】]*】"),
    "치환 안 된 변수": re.compile(r"\{\{[A-Z_]+\}\}"),
    "[확인 필요]": re.compile(r"\[\s*(원문\s*)?확인\s*필요\s*\]"),
    "[가정]": re.compile(r"\[\s*가정\s*\]"),
    "[예시값]": re.compile(r"\[\s*예시값?\s*\]"),
    "[작성 예정]/[확정 필요]": re.compile(r"\[\s*(작성\s*예정|확정\s*필요|기입\s*필요|링크\s*추가\s*예정)\s*\]"),
    "(기입 필요)": re.compile(r"\(\s*(기입\s*필요|이력\s*보완\s*요망|제\s*추측입니다\s*—\s*삭제)\s*\)"),
    # \b는 한글도 단어 문자로 봐서 'TBD입니다'를 놓친다. 영문·숫자·밑줄만 경계로 본다.
    "TODO/TBD/FIXME": re.compile(r"(?<![A-Za-z0-9_])(TODO|TBD|FIXME|XXX)(?![A-Za-z0-9_])"),
    "메타 지시문": re.compile(r"\((사용자\s*원칙|메모|이\s*줄은\s*지울\s*것)[^)]*\)|…?\.png를\s*삽입|배점에\s*유리|제출\s*전에\s*(이\s*메모|지운다|지워)"),
    # 목록 체크박스(- [ ], 1. [ ])는 빈 값이 아니다. --plain에서는 PLAIN_ONLY가 잡는다.
    # 함수 호출 main()은 빼고, 코드 블록·`코드` 안은 CODE_BLIND로 건너뛴다.
    "빈 괄호 값": re.compile(r"(?<![-*+]\s)(?<!\d[.)]\s)\[\s*\]|(?<![A-Za-z0-9_])\(\s*\)|○○|◯◯|xxx|N건|N명|N%"),
    "양식 안내문 잔재": re.compile(r"✅\s*(무엇을|기존|관련|시간|접근|결과물)|파란\s*안내문"),
}
PLAIN_ONLY = {
    "마크다운 굵게(**)": re.compile(r"\*\*[^*]+\*\*|\*\*"),
    "마크다운 헤더(#)": re.compile(r"^\s{0,3}#{1,6}\s", re.M),
    "마크다운 표(|)": re.compile(r"^\s*\|.*\|\s*$", re.M),
    "취소선 변환 위험(~)": re.compile(r"~[^~\n]+~"),
    "마크다운 체크박스(- [ ])": re.compile(r"^\s*(?:[-*+]|\d+[.)])\s+\[[ xX]?\]", re.M),
}
# 코드 예시(README·매뉴얼의 main(), "args": [])를 빈 값으로 보지 않을 규칙
CODE_BLIND = {"빈 괄호 값"}
CODE_RX = re.compile(r"^ {0,3}(```|~~~).*?^ {0,3}\1[^\n]*$|`[^`\n]+`", re.M | re.S)


def mask_code(text: str) -> str:
    """코드 블록과 `코드`를 같은 길이의 공백으로 바꿔 줄 번호·위치를 유지한다."""
    return CODE_RX.sub(lambda m: re.sub(r"[^\n]", " ", m.group(0)), text)


def scan(path: Path, allow: set, plain: bool):
    text = path.read_text(encoding="utf-8", errors="replace")
    masked = mask_code(text)
    hits = []
    pats = dict(PATTERNS)
    if plain:
        pats.update(PLAIN_ONLY)
    for label, rx in pats.items():
        if any(a in label for a in allow):
            continue
        for m in rx.finditer(masked if label in CODE_BLIND else text):
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
            if i + 1 >= len(argv) or argv[i + 1].startswith("--"):
                print(f"--allow 뒤에 허용할 표기를 쉼표로 적으십시오(예: --allow 가정,예시값).\n{__doc__}"); return 2
            allow = set(x.strip() for x in argv[i + 1].split(",") if x.strip()); i += 2; continue
        if a == "--plain":
            plain = True; i += 1; continue
        files.append(Path(a)); i += 1
    if not files:
        print(__doc__); return 2
    total, missing = 0, []
    for f in files:
        if not f.is_file():
            print(f"[없음] {f}"); missing.append(str(f)); continue
        hits = scan(f, allow, plain)
        total += len(hits)
        print(f"== {f} : {len(hits)}건")
        for line_no, label, snip in hits:
            print(f"  L{line_no:<5} {label:<22} … {snip} …")
    print(f"\n합계 {total}건" + ("" if total == 0 else " → 제출 전에 전부 해소해야 합니다."))
    if missing:
        print(f"[오류] 대상 파일 없음 {len(missing)}개: {', '.join(missing)}. 검사하지 못한 파일이 있어 통과로 보지 않습니다.")
        return 2
    return 0 if total == 0 else 1


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
