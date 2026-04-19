#!/usr/bin/env python3
"""Nova Privacy Filter — 14 patterns + Shannon entropy heuristic.

stdin: JSON object (extra payload)
stdout: JSON with _extra (cleaned) + _redacted (bool) + _reasons (list of pattern names)

Sprint 1 — Nova v5.12.0 관찰성 레이어.
"""
import json
import math
import re
import sys
from collections import Counter

PATTERNS = [
    ('anthropic_api', r'sk-ant-[A-Za-z0-9_-]{20,}'),
    ('openai_api',    r'sk-(?:proj-)?[A-Za-z0-9]{20,}'),
    ('github_pat',    r'gh[pous]_[A-Za-z0-9]{36,}'),
    ('slack_token',   r'xox[baprs]-[A-Za-z0-9-]{10,}'),
    ('stripe_live',   r'sk_live_[A-Za-z0-9]{24,}'),
    ('stripe_test',   r'sk_test_[A-Za-z0-9]{24,}'),
    ('google_api',    r'AIza[A-Za-z0-9_-]{35}'),
    ('aws_access',    r'AKIA[0-9A-Z]{16}'),
    ('aws_secret',    r'(?i)aws_?secret[^\s]{0,5}[\'"=:][A-Za-z0-9/+=]{40}'),
    ('bearer',        r'[Bb]earer [A-Za-z0-9._-]+'),
    ('jwt',           r'eyJ[A-Za-z0-9_-]+\.eyJ[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+'),
    ('password_kv',   r'(?i)(?:password|passwd|pwd)\s*[=:]\s*\S+'),
    ('env_value',     r'^[A-Z][A-Z0-9_]{2,}=[^\s]{8,}$'),
    ('private_key',   r'-----BEGIN (?:(?:RSA|EC|OPENSSH) )?PRIVATE KEY-----'),
]

HIGH_ENTROPY_THRESHOLD = 4.5
HIGH_ENTROPY_MIN_LEN = 48  # Sprint 1 Evaluator Issue #3: 40→48로 완화 (긴 base64 payload 오탐 방어)
HIGH_ENTROPY_PATTERN = re.compile(r'[A-Za-z0-9_/+=-]{' + str(HIGH_ENTROPY_MIN_LEN) + r',}')


def shannon_entropy(s: str) -> float:
    if not s:
        return 0.0
    counts = Counter(s)
    length = len(s)
    return -sum((n / length) * math.log2(n / length) for n in counts.values())


def scrub(s, reasons):
    if not isinstance(s, str):
        return s
    out = s
    for name, pat in PATTERNS:
        flags = re.MULTILINE if name == 'env_value' else 0
        if re.search(pat, out, flags=flags):
            out = re.sub(pat, f'<redacted:{name}>', out, flags=flags)
            if name not in reasons:
                reasons.append(name)

    for match in HIGH_ENTROPY_PATTERN.finditer(out):
        token = match.group(0)
        if token.startswith('<redacted'):
            continue
        if shannon_entropy(token) > HIGH_ENTROPY_THRESHOLD:
            out = out.replace(token, '<redacted:high_entropy>')
            if 'high_entropy' not in reasons:
                reasons.append('high_entropy')
    return out


SENSITIVE_KEYS = re.compile(
    r'(?i)(password|passwd|pwd|secret|token|api[_-]?key|auth|credential|private[_-]?key)$'
)


def walk(obj, reasons, parent_key: str = ''):
    if isinstance(obj, dict):
        out = {}
        for k, v in obj.items():
            if isinstance(v, str) and SENSITIVE_KEYS.search(str(k)) and v:
                out[k] = f'<redacted:sensitive_key:{k}>'
                if 'sensitive_key' not in reasons:
                    reasons.append('sensitive_key')
            else:
                out[k] = walk(v, reasons, parent_key=str(k))
        return out
    if isinstance(obj, list):
        return [walk(v, reasons, parent_key) for v in obj]
    if isinstance(obj, str):
        return scrub(obj, reasons)
    return obj


def main() -> int:
    raw = sys.stdin.read()
    try:
        data = json.loads(raw) if raw.strip() else {}
    except json.JSONDecodeError:
        data = {}

    reasons: list = []
    cleaned = walk(data, reasons)
    print(json.dumps({
        '_extra': cleaned,
        '_redacted': bool(reasons),
        '_reasons': reasons,
    }, ensure_ascii=False))
    return 0


if __name__ == '__main__':
    sys.exit(main())
