#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""제출 본문 글자 수를 접수 사이트 기준으로 센다.

사용법:
  python3 count_chars.py <파일> [--limit 5000] [--start "[아이디어 작성]"] [--end "[끝]"]
  --start/--end : 파일 안에서 셀 구간의 시작·끝 표식(없으면 전체)
출력: 공백 포함 / 공백 제외 / 줄바꿈을 2자로 셀 때 / 바이트(UTF-8) / 제한 대비 여유
종료 코드: 제한을 넘으면 1.
"""
import sys
from pathlib import Path


def main(argv):
    if not argv:
        print(__doc__); return 2
    path = Path(argv[0]); limit = None; start = end = None
    i = 1
    while i < len(argv):
        if argv[i] == "--limit":
            limit = int(argv[i + 1]); i += 2
        elif argv[i] == "--start":
            start = argv[i + 1]; i += 2
        elif argv[i] == "--end":
            end = argv[i + 1]; i += 2
        else:
            i += 1
    text = path.read_text(encoding="utf-8")
    if start and start in text:
        text = text.split(start, 1)[1]
    if end and end in text:
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
