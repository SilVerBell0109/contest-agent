#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""제출 본문 글자 수를 접수 사이트 기준으로 센다.

사용법:
  python3 count_chars.py <파일> [--limit 5000] [--start "[아이디어 작성]"] [--end "[끝]"]
  --limit       : 글자 수 제한. 5000·5,000·5,000자·5,000자 이내 모두 받는다
  --start/--end : 파일 안에서 셀 구간의 시작·끝 표식(주지 않으면 전체, 주었는데 없으면 오류)
출력: 공백 포함 / 공백 제외 / 줄바꿈을 2자로 셀 때 / 바이트(UTF-8) / 제한 대비 여유
종료 코드: 제한 이내 0, 제한 초과 1, 사용법 오류·파일 없음·표식 없음 2.
"""
import re
import sys
from pathlib import Path

LIMIT_RX = re.compile(r"\s*(\d{1,3}(?:,\d{3})+|\d+)\s*(?:자)?\s*(?:이내|이하)?\s*")


def main(argv):
    if not argv or argv[0].startswith("-"):
        print(__doc__); return 2
    path = Path(argv[0]); limit = None; start = end = None
    i = 1
    while i < len(argv):
        if argv[i] not in ("--limit", "--start", "--end") or i + 1 >= len(argv):
            print(f"알 수 없는 옵션이거나 값이 없습니다: {argv[i]}\n{__doc__}"); return 2
        opt, val = argv[i], argv[i + 1]; i += 2
        if opt == "--limit":
            m = LIMIT_RX.fullmatch(val)
            if not m:
                print(f"--limit 값은 숫자로 적으십시오(예: 5000, 5,000자): {val}"); return 2
            limit = int(m.group(1).replace(",", ""))
        elif opt == "--start":
            start = val
        else:
            end = val
    if not path.is_file():
        print(f"파일이 없습니다: {path}"); return 2
    text = path.read_text(encoding="utf-8")
    if start:
        if start not in text:
            print(f"[오류] 시작 표식이 파일에 없습니다: {start}"); return 2
        text = text.split(start, 1)[1]
    if end:
        if end not in text:
            print(f"[오류] 끝 표식이 {'시작 표식 뒤에' if start else '파일에'} 없습니다: {end}"); return 2
        text = text.split(end, 1)[0]
    text = text.strip("\n")
    with_space = len(text)
    no_space = len("".join(text.split()))
    newlines = text.count("\n")
    crlf = with_space + newlines  # 사이트가 줄바꿈을 \r\n(2자)으로 세는 경우
    print(f"공백 포함       : {with_space:,}자")
    print(f"공백 제외       : {no_space:,}자")
    print(f"줄바꿈 2자 기준 : {crlf:,}자  (줄바꿈 {newlines}개)")
    print(f"UTF-8 바이트    : {len(text.encode('utf-8')):,}")
    if limit:
        worst = max(with_space, crlf)
        print(f"제한 {limit:,}자 대비 여유: {limit - worst:,}자 (보수적 기준 {worst:,}자)")
        return 1 if worst > limit else 0
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
