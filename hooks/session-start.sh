#!/usr/bin/env bash

# Nova Engineering — SessionStart Hook
# 매 세션 시작 시 핵심 규칙을 경량 주입. 상세는 커맨드 호출 시 로드.

cat << 'NOVA_EOF'
{
  "hookSpecificOutput": {
    "hookEventName": "SessionStart",
    "additionalContext": "# Nova Engineering\n\n프로젝트에 NOVA-STATE.md가 있으면 세션 시작 시 반드시 읽는다.\n\n## 프로젝트 규칙 우선순위\n\n프로젝트에 .claude/rules/가 있으면 해당 규칙이 Nova 규칙보다 우선한다. Nova는 프로젝트 규칙을 보완하는 역할이다.\n\n## 자동 적용 규칙\n\n1. **복잡도 판단**: 간단(1~2파일)→바로 구현, 보통(3~7)→Plan→구현, 복잡(8+)→Plan→Design→스프린트 분할. 인증/DB/결제는 한 단계 상향. 작업 중 파일이 초기 예상을 넘으면 재판단.\n2. **검증 분리 (필수)**: 구현 후 검증은 반드시 독립 서브에이전트로 실행. 예외 없음. 검증(Evaluator)은 생략 불가. 배포 포함 작업은 매번 경량 검증 실행.\n3. **검증 기준**: 기능 동작(요구사항 원문과 대조), 데이터 관통(입력→저장→로드→표시→사용자 전달), 설계 정합성, 에러 핸들링/엣지 케이스, 경계값(0/음수/빈값/최대값).\n4. **실행 검증 우선**: '코드 존재' ≠ '동작'. 테스트 통과 ≠ 검증 완료. 핵심 로직은 경계값(0/음수/빈값)으로 크래시 확인 필수. 환경 변경은 3단계(현재값→변경→반영 확인).\n5. **검증 경량화**: 기본은 Lite. --strict 요청 시에만 풀 검증.\n6. **스프린트 분할**: 8+파일 수정은 독립 검증 가능한 스프린트로 분할. 전환 이력을 NOVA-STATE.md에 기록.\n7. **블로커 분류**: Auto-Resolve→자동, Soft-Block→기록 후 계속, Hard-Block(데이터 손실/보안/사용자 오판단)→즉시 중단. 불확실하면 Hard-Block. 같은 실패 2회 반복 시 강제 분류. 리뷰 시 크래시/데이터 손상/오판단→Hard-Block.\n8. **NOVA-STATE.md 갱신 (CRITICAL)**: 마지막에 몰아서 하지 않는다. 즉시 트리거: 배포/테스트/스프린트/블로커/검증 결과. Known Gaps(미커버 영역) 필수 기록.\n9. **긴급 모드 (--emergency)**: 프로덕션 장애 시 즉시 수정. 검증은 사후 실행. NOVA-STATE.md에 기록 필수.\n\n## Nova 커맨드\n\n/nova:plan, /nova:design, /nova:review (--fix), /nova:verify, /nova:gap, /nova:xv, /nova:auto, /nova:init, /nova:next, /nova:propose, /nova:metrics"
  }
}
NOVA_EOF

exit 0
