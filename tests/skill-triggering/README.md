# Skill Triggering Fixtures

각 Nova 스킬이 실제로 트리거되는지 프롬프트 fixture로 검증하기 위한 디렉토리.
obra/superpowers의 `tests/skill-triggering/` 패턴을 Nova에 흡수.

## 구조

- `prompts/{skill-name}-positive.txt` — 해당 스킬이 **반드시 발동해야** 하는 사용자 프롬프트 1개
- `prompts/{skill-name}-negative.txt` — 해당 스킬이 **발동하면 안 되는** 유사 맥락 프롬프트 (선택)

## 실행

구조 검증(fixture 존재 여부):

```bash
bash tests/test-skill-triggering.sh
```

실제 LLM 트리거 검증은 `/nova:field-test`로 수동 수행. 자동화는 향후 스프린트.

## 규약

- 각 `skills/*/SKILL.md`에 1:1 대응하는 `-positive.txt` 제출 의무
- 한 줄 자연어 프롬프트. 복잡한 시나리오 금지.
- 프롬프트는 사용자 말투로 작성 ("...해줘", "...이 필요해요" 등)
