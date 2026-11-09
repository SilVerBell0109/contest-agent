#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""산출물의 숫자가 근거 원장(evidence.md)이나 스펙(PRD/SRS)에 있는지 대조한다.

사용법:
  python3 trace_numbers.py <산출물.md> --against <evidence.md> [<PRD.md> <SRS.md> ...] [--warn]
규칙:
  - 세 자리 이상 숫자, %·억·만·원·달러·건·명·개·초·분·시간·GB·MB·ms 단위가 붙은 숫자, 소수점 숫자를 추출
  - 쉼표·공백을 제거해 정규화한 뒤, 대조 파일에서 E-ID·날짜·시각을 지운 숫자 토큰 가운데 같은 값을 찾는다
    (부분 문자열이 아니라 숫자 단위로 비교: E037의 37, 2026-11-05의 11은 근거가 아니다)
  - 연도(단위 없는 19xx·20xx), 시각(09:00), 날짜(11/5·2026-11-05·2026.11.05·10월 1일), 회차(제12회)는 뺀다
  - 대상 파일 자신은 대조 목록에서 빼고, 없는 대조 파일은 경고한다
  - 찾지 못한 숫자를 줄 번호와 함께 보고한다. --warn이 없으면 미추적 1건이라도 있으면 실패
종료 코드: 미추적 0건이면 0, 아니면 1(--warn이면 항상 0), 사용법 오류·대상 파일 없음 2.
"""
import re
import sys
from pathlib import Path

UNITS = r"%|억|만|천|원|달러|\$|건|명|개|종목|초|분|시간|일|주|GB|MB|KB|ms|배|점|쪽|장|행|회|km|m\b|cm"
# 한글 바로 뒤 숫자(총525건)는 잡고, 영문·밑줄 뒤(E037, file_100)와 날짜·소수 이어짐은 뺀다.
NUM_RX = re.compile(
    r"(?<![0-9A-Za-z_/:.,-])"
    r"(\d{1,3}(?:,\d{3})+(?:\.\d+)?|\d+\.\d+|\d{3,}|\d+(?=\s?(?:" + UNITS + r")))"
)
UNIT_AFTER_RX = re.compile(r"\s?(?:" + UNITS + r")")
YEAR_RX = re.compile(r"^(19|20)\d{2}$")
SKIP_SPAN = re.compile(r"\d{4}[.-]\d{1,2}[.-]\d{1,2}|\d{1,2}:\d{2}|\d{1,2}/\d{1,2}|제\s?\d+\s?(?:회|차|기|조|항|호)|\d{1,2}월\s?\d{1,2}일")


def norm(s: str) -> str:
    return s.replace(",", "").replace(" ", "")


def extract(text: str):
    skips = [s.span() for s in SKIP_SPAN.finditer(text)]
    out = []
    for m in NUM_RX.finditer(text):
        raw = m.group(1)
        n = norm(raw)
        if YEAR_RX.match(n) and "," not in raw and not UNIT_AFTER_RX.match(text, m.end()):
            continue
        a, b = m.span(1)
        if any(s <= a and b <= e for s, e in skips):
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
    if not target.is_file():
        print(f"대상 파일이 없습니다: {target}\n{__doc__}"); return 2
    against = [p for p in against if p.resolve() != target.resolve()]
    for p in against:
        if not p.exists():
            print(f"[경고] 대조 파일 없음: {p}")
    src = "\n".join(p.read_text(encoding="utf-8", errors="replace") for p in against if p.exists())
    src = re.sub(r"\bE-?\d+\b", " ", src)
    src = re.sub(r"\d{4}[-.]\d{1,2}[-.]\d{1,2}|\d{1,2}:\d{2}", " ", src)
    corpus = {norm(x) for x in re.findall(r"\d[\d,]*(?:\.\d+)?", src)}
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
