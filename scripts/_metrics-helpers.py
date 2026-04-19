#!/usr/bin/env python3
"""Nova Metrics Python helpers — stdin JSONL, KPI aggregation.

Usage: <jsonl stream> | python3 scripts/_metrics-helpers.py <kpi_name>
Prints: "<numerator> <denominator>" — to be fed to bash format_ratio.
"""
import json
import sys


def read_events():
    events = []
    for line in sys.stdin:
        try:
            events.append(json.loads(line))
        except Exception:
            continue
    return events


def calc_process_consistency(events):
    plans = {}
    sprints = []
    for e in events:
        extra = e.get("extra", {}) or {}
        oid = extra.get("orchestration_id", "")
        et = e.get("event_type", "")
        ts = e.get("timestamp_epoch", 0)
        if et == "plan_created":
            plans.setdefault(oid, []).append(ts)
        elif et == "sprint_completed" and extra.get("planned_files", 0) >= 3:
            sprints.append((oid, ts))
    num = 0
    for oid, sts in sprints:
        if any(pts < sts for pts in plans.get(oid, [])):
            num += 1
    return num, len(sprints)


def calc_gap_detection_rate(events):
    fails = []
    resolutions = {}
    for e in events:
        extra = e.get("extra", {}) or {}
        oid = extra.get("orchestration_id", "")
        et = e.get("event_type", "")
        ts = e.get("timestamp_epoch", 0)
        if et == "evaluator_verdict" and extra.get("verdict") == "FAIL":
            fails.append((oid, ts))
        elif (et == "sprint_completed" and extra.get("verdict") == "PASS") or \
             (et == "phase_transition" and extra.get("to_status") == "completed"):
            resolutions.setdefault(oid, []).append(ts)
    num = sum(1 for oid, fts in fails if any(rts > fts for rts in resolutions.get(oid, [])))
    return num, len(fails)


def calc_multi_perspective(events):
    total = 0
    changed = 0
    for e in events:
        if e.get("event_type") == "jury_verdict":
            total += 1
            if (e.get("extra", {}) or {}).get("changed_direction") is True:
                changed += 1
    return changed, total


def main():
    if len(sys.argv) < 2:
        print("0 0")
        return 1
    kpi = sys.argv[1]
    events = read_events()
    if kpi == "process_consistency":
        n, d = calc_process_consistency(events)
    elif kpi == "gap_detection_rate":
        n, d = calc_gap_detection_rate(events)
    elif kpi == "multi_perspective_impact":
        n, d = calc_multi_perspective(events)
    else:
        print("0 0")
        return 1
    print(f"{n} {d}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
