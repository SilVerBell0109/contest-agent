#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""한국어 산출물의 AI-티·번역투·문체 규칙 위반을 센다 (결정적 1차 검사).

im-not-ai(humanize-korean)의 심각도 체계(S1 결정적 / S2 3회 이상이면 문제 / S3 겹칠 때만)와
하나증권 기획서 B-7 문체 기준을 합쳐 만든 간이 검사기다. LLM 없이 돌아간다.

사용법:
  python3 check_style.py <파일...> [--genre body|form|slides] [--strict] [--json]
  --genre body   지원서·기획서 본문(합쇼체·1인칭 산문) — 기본값
  --genre form   개조식 양식(소마 기획서처럼 '~다'체·불릿 허용)
  --genre slides 슬라이드 헤드라인(명사구 허용)
  --strict       S2가 3회 이상이면 실패 처리(기본은 S1만 실패)
종료 코드: 통과 0, 실패 1, 사용법 오류·파일 없음 2.
"""
import json
import re
import sys
from pathlib import Path

# (라벨, 정규식, 심각도, 설명)
RULES = [
    # ---- D. AI 상투구 (S1) ----
    ("상투구: 드물지 않다", r"드물지\s*않", "S1", "사람이 안 쓰는 문어체. '자주 있다/흔하다'로"),
    ("상투구: ~의 영역이다", r"의\s*영역이", "S1", "삭제하거나 구체 서술로"),
    ("상투구: ~를 다룬다/다루는", r"(을|를)\s*다룬다", "S1", "무엇을 어떻게 하는지 동사로"),
    ("상투구: ~할 자리다", r"할\s*자리(다|입니다)", "S1", "삭제"),
    ("상투구: 순서를 밟는다", r"순서를\s*밟", "S1", "구체 동작으로"),
    ("상투구: 시사하는 바가 크다", r"시사하는\s*바", "S1", "무엇을 뜻하는지 직접 쓰기"),
    ("상투구: 크게 N가지로 나눌 수 있다", r"크게\s*\S+\s*가지로\s*(나눌|나뉩|구분)", "S1", "바로 항목으로"),
    ("상투구: 결론적으로/그러므로 남발", r"(결론적으로|그러므로|따라서)\s*,?", "S2", "문서당 1회 이하"),
    ("상투구: ~할 때입니다 결말", r"할\s*때입니다\.", "S2", "경구형 마무리 삭제"),
    ("과장어: 혁신적/압도적/획기적/게임체인저", r"(혁신적|압도적|획기적|게임\s*체인저|패러다임\s*(전환|시프트))", "S1", "수치·사실로 대체"),
    # ---- A. 번역투 ----
    ("번역투: ~에 대한/대해", r"에\s*대(한|해|하여)", "S2", "조사로 바로 잇기('~의', '~을')"),
    ("번역투: ~을/를 통해", r"(을|를)\s*통해", "S2", "'~로', '~해서'"),
    ("번역투: ~적인", r"[가-힣]+적인\s", "S2", "형용사·동사로"),
    ("번역투: ~하기 위한/위해 남발", r"(하기\s*위한|하기\s*위해|을\s*위해|를\s*위해)", "S2", "'~하려고', '~에'"),
    ("번역투: ~에 있어서", r"에\s*있어서?", "S1", "'~에서', '~할 때'"),
    ("번역투: 가지고 있다", r"가지고\s*있", "S1", "'있다', '갖췄다'"),
    ("번역투: 이중 피동(되어진다/되어지)", r"되어\s*지", "S1", "능동 또는 단일 피동"),
    ("번역투: 이루어지다/만들어지다", r"(이루어|이뤄|만들어)\s*(지|집|진)", "S2", "행위자를 주어로"),
    ("번역투: ~라는 점에서", r"라는\s*점에서", "S2", "'~라서'"),
    ("번역투: ~에 기반하여/기반한", r"에\s*기반(하여|한|해)", "S2", "'~를 바탕으로', '~로'"),
    ("번역투: ~할 수 있다 남발", r"할\s*수\s*있(다|습니다|어)", "S3", "확정 서술 가능하면 단정으로(정책·의학 글은 예외)"),
    # ---- C. 구조 ----
    ("구조: 'A가 아니라 B' 대구", r"(가|이)\s*아니라\s", "S2", "3회 이상이면 하나만 남기기"),
    ("구조: X에서 Y로 전환 공식", r"에서\s*[가-힣\s]{1,12}(으)?로\s*(바꾸|전환|옮기)", "S2", "두 문장으로 풀기"),
    ("구조: 첫째/둘째/셋째", r"(첫째|둘째|셋째)\s*,", "S2", "산문으로 묶거나 표로"),
    ("구조: 1) 2) 3) 나열", r"(?m)^\s*[1-9]\)\s", "S3", "양식이 요구할 때만"),
    ("구조: 'N가지입니다' 개수 예고", r"[두세네다섯여섯일곱\d]+\s*가지(입니다|가\s*있습니다|로\s*나뉩니다)", "S2", "개수 예고 없이 바로 항목"),
    # ---- J. 시각 장식 ----
    ("장식: 줄표(—/–)", r"[—–]", "S1", "쉼표·마침표·괄호로"),
    ("장식: 마크다운 굵게 **", r"\*\*", "S2", "제출 본문에서는 제거"),
    ("장식: 이모지", r"[\U0001F300-\U0001FAFF☀-➿]", "S1", "제출물에서 제거"),
    ("장식: '라벨: 내용' 목록 반복", r"(?m)^\s*[-•]\s*[가-힣A-Za-z ]{1,12}\s*:\s", "S3", "3개 이상 연속이면 산문으로"),
]

GENRE_SKIP = {
    "form": {"구조: 첫째/둘째/셋째", "구조: 1) 2) 3) 나열", "장식: '라벨: 내용' 목록 반복", "장식: 마크다운 굵게 **"},
    "slides": {"장식: 마크다운 굵게 **", "구조: 1) 2) 3) 나열", "장식: '라벨: 내용' 목록 반복"},
    "body": set(),
}


def analyze(text: str, genre: str):
    results = []
    for label, rx, sev, fix in RULES:
        if label in GENRE_SKIP.get(genre, set()):
            continue
        hits = [m for m in re.finditer(rx, text)]
        if not hits:
            continue
        lines = sorted({text.count("\n", 0, m.start()) + 1 for m in hits})
        results.append({"label": label, "severity": sev, "count": len(hits), "lines": lines[:12], "fix": fix})
    # 리듬: 같은 종결어미 반복(문단 안에서 '~습니다.'만 6회 이상 연속)
    sents = re.split(r"(?<=[.!?])\s+", text)
    run, max_run = 0, 0
    for s in sents:
        if s.strip().endswith("습니다."):
            run += 1; max_run = max(max_run, run)
        else:
            run = 0
    if max_run >= 6:
        results.append({"label": "리듬: '~습니다.' 연속 %d문장" % max_run, "severity": "S2", "count": max_run,
                        "lines": [], "fix": "단문·명사형·질문 등을 섞기"})
    return results


def verdict(results, strict: bool):
    s1 = sum(r["count"] for r in results if r["severity"] == "S1")
    s2_fail = [r for r in results if r["severity"] == "S2" and r["count"] >= 3]
    failed = s1 > 0 or (strict and bool(s2_fail))
    return failed, s1, s2_fail


def main(argv):
    files, genre, strict, as_json = [], "body", False, False
    i = 0
    while i < len(argv):
        a = argv[i]
        if a == "--genre":
            if i + 1 >= len(argv) or argv[i + 1] not in GENRE_SKIP:
                print(f"--genre 값은 {'|'.join(GENRE_SKIP)} 중 하나입니다.\n{__doc__}"); return 2
            genre = argv[i + 1]; i += 2; continue
        if a == "--strict":
            strict = True; i += 1; continue
        if a == "--json":
            as_json = True; i += 1; continue
        files.append(Path(a)); i += 1
    if not files:
        print(__doc__); return 2
    missing = [str(f) for f in files if not f.is_file()]
    if missing:
        print(f"파일이 없습니다: {', '.join(missing)}"); return 2
    overall_fail = False
    report = {}
    for f in files:
        text = f.read_text(encoding="utf-8", errors="replace")
        res = analyze(text, genre)
        failed, s1, s2_fail = verdict(res, strict)
        overall_fail |= failed
        report[str(f)] = {"failed": failed, "S1": s1, "findings": res}
        if not as_json:
            print(f"== {f}  (genre={genre})  {'실패' if failed else '통과'}  S1={s1}")
            for r in sorted(res, key=lambda r: (r["severity"], -r["count"])):
                ln = ",".join(map(str, r["lines"])) if r["lines"] else "-"
                print(f"  {r['severity']} ×{r['count']:<3} {r['label']:<34} L{ln}\n        → {r['fix']}")
    if as_json:
        print(json.dumps(report, ensure_ascii=False, indent=2))
    return 1 if overall_fail else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
