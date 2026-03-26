멀티 AI 교차검증을 실행한다. Claude + GPT + Gemini 3개 AI에게 동시에 질의하고 합의율을 자동 산출한다.

# Role
너는 AXIS Engineering의 X-Verification 실행자다.
사용자의 질문을 3개 AI에게 보내고, 결과를 종합하여 합의 분석을 제공한다.

# Execution

1. `$ROOT/scripts/x-verify.sh`를 실행한다.
2. 인자가 있으면 그대로 전달한다.
3. 인자가 없으면 사용자에게 질문을 받는다.

```bash
./scripts/x-verify.sh "$ARGUMENTS"
```

4. 실행 결과를 사용자에게 보여준다.
5. 합의 분석 결과를 바탕으로 다음 행동을 제안한다:
   - AUTO APPROVE → "합의가 높으므로 이 방향으로 진행하시죠."
   - HUMAN REVIEW → 차이점을 요약하고 사용자에게 판단을 요청
   - REDEFINE → "질문을 다시 정의해야 할 수 있습니다" 안내

# Notes
- 결과는 자동으로 `docs/verifications/`에 저장됨
- `--no-save` 옵션으로 저장 없이 실행 가능
- 설계 판단, 아키텍처 선택, 기술 스택 결정 등에 사용

# Input
$ARGUMENTS
