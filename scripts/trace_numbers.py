#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""산출물의 숫자가 근거 원장(evidence.md)이나 스펙(PRD/SRS)에 있는지 대조한다.

사용법:
  python3 trace_numbers.py <산출물.md> --against <evidence.md> [<PRD.md> <SRS.md> ...] [--warn]
규칙:
  - 세 자리 이상 숫자, %·억·만·원·달러·건·명·개·초·분·시간·GB·MB·ms 단위가 붙은 숫자, 소수점 숫자를 추출
  - 쉼표·공백을 제거해 정규화한 뒤 대조 파일 전체에서 같은 숫자를 찾는다
  - 연도(19xx·20xx)와 시각(09:00)·날짜(11/5)는 추적 대상에서 뺀다(별도 표기 규칙으로 관리)
  - 찾지 못한 숫자를 줄 번호와 함께 보고한다. --warn이 없으면 미추적 1건이라도 있으면 실패
종료 코드: 미추적 0건이면 0, 아니면 1(--warn이면 항상 0).
"""
import re
import sys
from pathlib import Path

NUM_RX = re.compile(
    r"(?<![\w/:.-])"
    r"(\d{1,3}(?:,\d{3})+(?:\.\d+)?|\d+\.\d+|\d{3,}|\d+(?=\s?(%|억|만|천|원|달러|\$|건|명|개|종목|초|분|시간|일|주|GB|MB|KB|ms|배|점|쪽|장|행|회|km|m\b|cm)))"
)
YEAR_RX = re.compile(r"^(19|20)\d{2}$")
TIME_RX = re.compile(r"\d{1,2}:\d{2}")
DATE_RX = re.compile(r"\d{1,2}/\d{1,2}")


def norm(s: str) -> str:
    return s.replace(",", "").replace(" ", "")


def extract(text: str):
    out = []
    for m in NUM_RX.finditer(text):
        raw = m.group(1)
        n = norm(raw)
        if YEAR_RX.match(n):
            continue
        ctx = text[max(0, m.start() - 6): m.end() + 6]
        if TIME_RX.search(ctx) or DATE_RX.search(ctx):
            continue
        line_no = text.count("\n", 0, m.start()) + 1
        out.append((line_no, raw, n, text[max(0, m.start() - 25): m.end() + 25].replace("\n", " ")))
    return out


def main(argv):
    if not argv or "--against" not in argv:
        print(__doc__); return 2
    idx = argv.index("--against")
    target = Path(argv[0])
    against = [Path(p) for p in argv[idx + 1:] if not p.startswith("--")]
    warn = "--warn" in argv
    corpus = norm("\n".join(p.read_text(encoding="utf-8", errors="replace") for p in against if p.exists()))
    text = target.read_text(encoding="utf-8", errors="replace")
    nums = extract(text)
    untraced = [(ln, raw, ctx) for ln, raw, n, ctx in nums if n not in corpus]
    print(f"== {target}: 숫자 {len(nums)}개 중 미추적 {len(untraced)}개 (대조: {', '.join(str(p) for p in against)})")
    for ln, raw, ctx in untraced:
        print(f"  L{ln:<5} {raw:<14} … {ctx} …")
    if untraced:
        print("\n미추적 숫자는 evidence.md에 E-ID로 등록하거나 [예시값]/[가정] 표기 후 제출 전에 해소하십시오.")
    return 0 if (warn or not untraced) else 1


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
