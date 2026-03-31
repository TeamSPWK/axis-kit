#!/usr/bin/env bash

# Nova Engineering — SessionStart Hook
# 매 세션 시작 시 최소한의 규칙만 주입. 상세는 커맨드 호출 시 로드.

cat << 'NOVA_EOF'
{
  "hookSpecificOutput": {
    "hookEventName": "SessionStart",
    "additionalContext": "# Nova Engineering\n\n프로젝트에 NOVA-STATE.md가 있으면 세션 시작 시 반드시 읽는다.\n\n## 자동 적용 규칙 (요약)\n\n1. **복잡도 판단**: 간단(1~2파일)→바로 구현, 보통(3~7)→Plan→구현, 복잡(8+)→Plan→Design→스프린트 분할. 사용자가 '빠르게 해줘'라면 생략 가능.\n2. **검증 분리**: 구현 후 검증은 반드시 독립 서브에이전트로 실행. 자기가 쓴 코드를 자기가 평가하지 않는다.\n3. **NOVA-STATE.md 갱신**: Nova 커맨드 실행 후 반드시 업데이트. 건너뛰지 마라.\n\n## Nova 커맨드\n\n| 커맨드 | 설명 |\n|--------|------|\n| /nova:plan | CPS Plan 문서 |\n| /nova:design | CPS Design 문서 |\n| /nova:review | 적대적 코드 리뷰 (--fix로 자동 수정) |\n| /nova:verify | review + gap 통합 검증 |\n| /nova:gap | 설계↔구현 검증 |\n| /nova:xv | 멀티 AI 교차검증 |\n| /nova:auto | 구현→검증 자율 실행 |\n| /nova:init | 새 프로젝트 초기 설정 |\n| /nova:next | 다음 할 일 추천 |\n| /nova:propose | 규칙 제안 |\n| /nova:metrics | 도입 수준 측정 |"
  }
}
NOVA_EOF

exit 0
