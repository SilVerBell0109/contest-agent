#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""산출물의 숫자가 근거 원장(evidence.md)이나 스펙(PRD/SRS)에 있는지 대조한다.

사용법:
  python3 trace_numbers.py <산출물.md...> --against <evidence.md> [<PRD.md> <SRS.md> ...] [--warn]
규칙:
  - 세 자리 이상 숫자, %·조·억·만·원·달러·건·명·개·곳·가구·초·분·시간·GB·MB·ms 단위가 붙은 숫자, 소수점 숫자를 추출
    (음수 -15%의 15, 범위 20-30%의 30도 추출. 20대 같은 연령대는 단위로 보지 않는다)
  - 쉼표·공백을 제거해 정규화한 뒤, 대조 파일에서 근거가 아닌 숫자를 지운 숫자 토큰 가운데 같은 값을 찾는다
    (지우는 것: URL, ID·버전(E120·FR-001·P0·v0.1), 절 번호(## 4.1, §13), 경로 접두(30-refine/), 날짜·시각·회차.
     부분 문자열이 아니라 숫자 단위로 비교: E120의 120, 2026-11-05의 11은 근거가 아니다)
  - 연도(단위 없는 19xx·20xx), 시각(09:00), 날짜(11/5·2026-11-05·2026.11.05·10월 1일), 회차(제12회)는 뺀다
  - 대상 파일 자신은 대조 목록에서 빼고, 없는 대조 파일은 경고한다
  - 찾지 못한 숫자를 줄 번호와 함께 보고한다. --warn이 없으면 미추적 1건이라도 있으면 실패
종료 코드: 모든 대상의 미추적이 0건이면 0, 아니면 1(--warn이면 항상 0),
          사용법 오류·대상 파일 없음 2(있는 파일은 먼저 검사해 보여 준다).
"""
import re
import sys
from pathlib import Path

UNITS = r"%|조|억|만|천|원|달러|\$|건|명|개|곳|가구|종목|초|분|시간|일|주|GB|MB|KB|ms|배|점|쪽|장|행|회|km|m\b|cm"
NUM = r"\d{1,3}(?:,\d{3})+(?:\.\d+)?|\d+\.\d+|\d{3,}|\d+(?=\s?(?:" + UNITS + r"))"
# 한글 바로 뒤 숫자(총525건)는 잡고, 영문·밑줄 뒤(E037, file_100)와 날짜·소수 이어짐은 뺀다.
# 음수(-15%)와 범위 위쪽(20-30%의 30)은 따로 잡는다. 단위 없는 '숫자-숫자'(010-1234-5678)는 그대로 뺀다.
NUM_RX = re.compile(
    r"(?<![0-9A-Za-z_/:.,-])(" + NUM + r")"
    r"|(?<=-)(?<![^\s(]-)(" + NUM + r")"
    r"|(?<=\d-)(\d+(?:\.\d+)?(?=\s?(?:" + UNITS + r")))"
)
UNIT_AFTER_RX = re.compile(r"\s?(?:" + UNITS + r")")
YEAR_RX = re.compile(r"^(19|20)\d{2}$")
# '제'는 낱말 첫머리일 때만 회차로 본다(경제 100조, 실제 3회는 숫자).
SKIP_SPAN = re.compile(r"\d{4}[.-]\d{1,2}[.-]\d{1,2}|\d{1,2}:\d{2}|\d{1,2}/\d{1,2}|(?<![가-힣])제\s?\d+\s?(?:회|차|기|조|항|호)|\d{1,2}월\s?\d{1,2}일")
# 대조 파일에서 근거가 아닌 숫자. 순서가 중요하다(URL·슬래시 날짜를 먼저 지워야 11/25 같은 조각이 남지 않는다).
NOT_EVIDENCE = [
    re.compile(r"https?://\S+"),
    re.compile(r"\d{4}[-./]\d{1,2}[-./]\d{1,2}"),
    SKIP_SPAN,
    re.compile(r"\d{4}년|\d{1,2}월"),
    re.compile(r"^[ \t]{0,3}#{1,6}[ \t]*\d+(?:\.\d+)*\.?(?=[ \t]|$)", re.M),
    re.compile(r"§\s?\d+(?:\.\d+)*"),
    re.compile(r"(?<![0-9A-Za-z_])[A-Za-z]{1,4}-?\d+(?:[.-]\d+)*"),
    re.compile(r"(?<![0-9])\d+-(?=[A-Za-z])"),
]


def norm(s: str) -> str:
    return s.replace(",", "").replace(" ", "")


def extract(text: str):
    skips = [s.span() for s in SKIP_SPAN.finditer(text)]
    out = []
    for m in NUM_RX.finditer(text):
        g = m.lastindex
        raw = m.group(g)
        n = norm(raw)
        if YEAR_RX.match(n) and "," not in raw and not UNIT_AFTER_RX.match(text, m.end()):
            continue
        a, b = m.span(g)
        if any(s <= a and b <= e for s, e in skips):
            continue
        line_no = text.count("\n", 0, m.start()) + 1
        out.append((line_no, raw, n, text[max(0, m.start() - 25): m.end() + 25].replace("\n", " ")))
    return out


def corpus_of(paths):
    src = "\n".join(p.read_text(encoding="utf-8", errors="replace") for p in paths)
    for rx in NOT_EVIDENCE:
        src = rx.sub(" ", src)
    return {norm(x) for x in re.findall(r"\d[\d,]*(?:\.\d+)?", src)}


def main(argv):
    if "--against" not in argv:
        print(__doc__); return 2
    idx = argv.index("--against")
    targets = [Path(p) for p in argv[:idx] if not p.startswith("--")]
    against_all = [Path(p) for p in argv[idx + 1:] if not p.startswith("--")]
    warn = "--warn" in argv
    if not targets:
        print(__doc__); return 2
    for p in against_all:
        if not p.exists():
            print(f"[경고] 대조 파일 없음: {p}")
    failed, missing = False, []
    for target in targets:
        if not target.is_file():
            print(f"[없음] {target}"); missing.append(str(target)); continue
        against = [p for p in against_all if p.exists() and p.resolve() != target.resolve()]
        corpus = corpus_of(against)
        nums = extract(target.read_text(encoding="utf-8", errors="replace"))
        untraced = [(ln, raw, ctx) for ln, raw, n, ctx in nums if n not in corpus]
        print(f"== {target}: 숫자 {len(nums)}개 중 미추적 {len(untraced)}개 (대조: {', '.join(str(p) for p in against)})")
        for ln, raw, ctx in untraced:
            print(f"  L{ln:<5} {raw:<14} … {ctx} …")
        failed = failed or bool(untraced)
    if failed:
        print("\n미추적 숫자는 evidence.md에 E-ID로 등록하거나 [예시값]/[가정] 표기 후 제출 전에 해소하십시오.")
    if missing:
        print(f"[오류] 대상 파일 없음 {len(missing)}개: {', '.join(missing)}. 검사하지 못한 파일이 있어 통과로 보지 않습니다.")
        return 2
    return 0 if (warn or not failed) else 1


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
