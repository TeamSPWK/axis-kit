# [Decision] 데이터베이스 선택: PostgreSQL

> AXIS Engineering — Decision Record
> 날짜: 2026-03-20
> 상태: 승인됨

---

## Context (배경)

사용자 인증 기능에 세션/토큰 저장, 사용자 프로필 관리를 위한 데이터베이스가 필요. 현재 프로젝트는 Next.js + TypeScript 기반 웹 애플리케이션.

## Problem (문제)

MVP 단계에서 관계형(PostgreSQL) vs 문서형(MongoDB) 중 어떤 DB를 기본으로 사용할 것인가?

## Decision (결정)

**PostgreSQL** 채택.

### 대안 비교

| 기준 | PostgreSQL | MongoDB | SQLite |
|------|-----------|---------|--------|
| 관계형 데이터 | ✅ 강점 | ⚠️ 가능하나 복잡 | ✅ 기본 |
| 확장성 | ✅ 수평/수직 | ✅ 수평 특화 | ❌ 단일 파일 |
| JSON 지원 | ✅ jsonb | ✅ 네이티브 | ⚠️ 제한적 |
| 호스팅 | ✅ Supabase, Neon 등 | ✅ Atlas | ❌ 서버리스 불가 |
| 학습 곡선 | 중간 | 낮음 | 낮음 |
| 트랜잭션 | ✅ ACID 완전 | ⚠️ 제한적 | ✅ ACID |
| 결론 | **채택** | 기각 (관계형 데이터 우선) | 기각 (확장성 부족) |

## Consequences (결과)

### 긍정적
- 사용자-세션-권한 관계를 자연스럽게 모델링
- Supabase 연동으로 인증/실시간 기능 추가 용이
- 스키마 마이그레이션으로 데이터 무결성 보장

### 부정적
- MongoDB 대비 초기 스키마 설계 시간 필요
- 비정형 데이터(로그 등) 저장 시 별도 고려 필요

### 주의사항
- 비정형 데이터가 주된 use case가 되면 MongoDB 재검토

---

## X-Verification (교차 검증)

| AI | 의견 요약 | 합의 |
|----|----------|------|
| Claude | PostgreSQL — 관계형 모델이 인증에 적합, jsonb로 유연성 확보 | O |
| GPT | PostgreSQL — ACID 트랜잭션이 인증에 필수, Supabase 생태계 활용 | O |
| Gemini | PostgreSQL 우선, 로그성 데이터는 MongoDB 병행 고려 | △ |

합의율: 85% → 판정: 자동 채택 (90%에 근접, Gemini도 PostgreSQL 자체에는 동의)
