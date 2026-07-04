#!/usr/bin/env python3
"""Generate (or --check) the self-referential Quine.lean from scripts/template.lean.

The template is the final file text with the ASCII token `__PAYLOAD__` where the decimal
digits of `N` are to stand. This is a single deterministic pass -- no fixpoint iteration --
because the encoded `body` (template with the payload site collapsed to one marker byte) has
a length independent of how many digits `N` turns out to have.

Encoding (mirrors Quine.lean's `decode`/`splice`):
  body  = template with `__PAYLOAD__` replaced by one marker byte 0x01
  N     = fold over body: start 1 (sentinel), then N = N*1000 + (1 if marker else ord(ch))
  out   = body with the marker byte replaced by the decimal string of N   == Quine.lean

Usage:
  python3 scripts/gen_quine.py            # (re)generate Quine.lean
  python3 scripts/gen_quine.py --check    # regenerate in memory, byte-compare, nonzero on drift
"""
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)                       # lean_quine/
TEMPLATE = os.path.join(HERE, "template.lean")
TARGET = os.path.join(ROOT, "Quine.lean")
TOKEN = "__PAYLOAD__"
MARKER = "\x01"


def fail(msg: str):
    print(f"gen_quine: {msg}", file=sys.stderr)
    sys.exit(1)


def build():
    with open(TEMPLATE, "rb") as f:
        raw = f.read()

    # --- Assert the template is a clean ASCII/LF/no-tab source. ---
    try:
        text = raw.decode("ascii")
    except UnicodeDecodeError as e:
        fail(f"template is not valid ASCII: {e}")
    for i, b in enumerate(raw):
        if b == 0x0A:            # LF is the only allowed control byte
            continue
        if b == 0x09:
            fail(f"template contains a tab at byte {i}")
        if b < 0x20 or b > 0x7E:
            fail(f"template contains a non-ASCII/control byte {b} at offset {i}")
    if raw[-1:] != b"\n":
        fail("template must end with a trailing newline")
    if b"\r" in raw:
        fail("template contains a CR (must be LF-only)")
    if MARKER.encode() in raw:
        fail("template contains a raw 0x01 marker byte")
    n_tokens = text.count(TOKEN)
    if n_tokens != 1:
        fail(f"template must contain exactly one {TOKEN} (found {n_tokens})")

    # --- Encode. ---
    body = text.replace(TOKEN, MARKER)
    N = 1                                          # leading sentinel group
    for ch in body:
        code = ord(ch)
        group = 1 if ch == MARKER else code
        if group != 1 and not (group == 10 or 32 <= group <= 126):
            fail(f"body char code {code} out of the allowed ASCII range")
        N = N * 1000 + group
    digits = str(N)
    output = body.replace(MARKER, digits)
    return text, body, N, digits, output


def verify(text, body, N, digits, output):
    # Independent re-decode: peel base-1000 groups down to the sentinel, re-splice, compare.
    groups = []
    n = N
    while n >= 2:                                  # mirrors Lean `decode`'s `n < 2` stop
        groups.append(n % 1000)
        n //= 1000
    groups.reverse()                               # front-to-back (source order)
    rebuilt = "".join(digits if g == 1 else chr(g) for g in groups)
    if rebuilt != output:
        fail("independent re-decode does not reproduce the generated file")

    # Idempotence: put __PAYLOAD__ back at the template's payload offset -> recover template.
    pos = text.index(TOKEN)
    recovered = output[:pos] + TOKEN + output[pos + len(digits):]
    if recovered != text:
        fail("idempotence check failed: re-tokenizing the digit run does not recover the template")

    # Sanity: exactly one marker group (value 1) among the interior groups.
    if groups.count(1) != 1:
        fail(f"expected exactly one marker group, found {groups.count(1)}")


def main():
    check = "--check" in sys.argv
    text, body, N, digits, output = build()
    verify(text, body, N, digits, output)
    out_bytes = output.encode("ascii")

    if check:
        try:
            with open(TARGET, "rb") as f:
                existing = f.read()
        except FileNotFoundError:
            fail("Quine.lean does not exist; run gen_quine.py without --check first")
        if existing != out_bytes:
            fail(f"Quine.lean ({len(existing)} bytes) differs from generator output ({len(out_bytes)} bytes)")
        print(f"OK: Quine.lean matches generator ({len(out_bytes)} bytes, N has {len(digits)} digits)")
    else:
        with open(TARGET, "wb") as f:
            f.write(out_bytes)
        print(f"wrote Quine.lean ({len(out_bytes)} bytes, N has {len(digits)} digits, {len(body)} source groups)")


if __name__ == "__main__":
    main()
