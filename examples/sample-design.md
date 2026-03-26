# [Design] 사용자 인증

> AXIS Engineering — CPS Framework
> 작성일: 2026-03-22
> Plan 문서: `examples/sample-plan.md`

---

## Context (설계 배경)

### Plan 요약
- 핵심 문제: 사용자 식별 및 권한 관리 시스템 부재로 개인화 서비스와 데이터 보호 불가
- 선택한 방안: JWT Access Token(15분) + Refresh Token 로테이션(7일), HttpOnly 쿠키 저장

### 설계 원칙
- **보안 우선**: 금융 데이터를 다루므로 토큰 관리, 비밀번호 해싱 등 보안을 최우선
- **점진적 확장**: MVP에서는 이메일+카카오 인증만, 이후 소셜 로그인 추가가 용이한 구조
- **단순성**: 불필요한 추상화를 피하고, 인증 미들웨어 하나로 보호 API를 일관 처리

---

## Problem (설계 과제)

### 기술적 과제

| # | 과제 | 복잡도 | 의존성 |
|---|------|--------|--------|
| 1 | JWT 발급/검증 미들웨어 구현 | 중간 | 없음 |
| 2 | Refresh Token 로테이션 및 DB 저장 로직 | 높음 | 과제 1 |
| 3 | 카카오 OAuth 2.0 연동 | 중간 | 과제 1 |
| 4 | 역할 기반 접근 제어 (RBAC) 미들웨어 | 낮음 | 과제 1 |
| 5 | 비밀번호 해싱 및 검증 | 낮음 | 없음 |

### 기존 시스템과의 접점
- **Express.js 라우터**: 기존 API 라우터에 인증 미들웨어를 추가해야 함
- **PostgreSQL**: 기존 DB에 users, refresh_tokens 테이블 추가
- **Next.js 프론트엔드**: 로그인 페이지 추가, API 호출 시 쿠키 자동 전송 설정 (credentials: 'include')

---

## Solution (설계 상세)

### 아키텍처

```
┌─────────────────┐         ┌──────────────────────────────────┐
│   Next.js App   │         │         Express.js API            │
│                 │         │                                    │
│  /login         │ ──────> │  POST /api/auth/login              │
│  /signup        │ ──────> │  POST /api/auth/signup             │
│  /oauth/kakao   │ ──────> │  GET  /api/auth/kakao              │
│                 │         │  GET  /api/auth/kakao/callback      │
│                 │         │                                    │
│  보호된 페이지   │ ──────> │  [authMiddleware] 보호된 API        │
│                 │ <────── │  401 → 자동으로 /api/auth/refresh   │
└─────────────────┘         └────────────┬───────────────────────┘
                                         │
                                         ▼
                            ┌──────────────────────┐
                            │     PostgreSQL        │
                            │  ┌────────────────┐   │
                            │  │ users           │   │
                            │  │ refresh_tokens  │   │
                            │  └────────────────┘   │
                            └──────────────────────┘
```

### 데이터 모델

```sql
-- 사용자 테이블
CREATE TABLE users (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email       VARCHAR(255) UNIQUE NOT NULL,
    password    VARCHAR(255),           -- 소셜 로그인 전용 사용자는 NULL
    name        VARCHAR(100) NOT NULL,
    role        VARCHAR(20) DEFAULT 'user',  -- 'user' | 'admin'
    provider    VARCHAR(20) DEFAULT 'local', -- 'local' | 'kakao'
    provider_id VARCHAR(255),           -- 소셜 로그인 시 외부 ID
    created_at  TIMESTAMPTZ DEFAULT NOW(),
    updated_at  TIMESTAMPTZ DEFAULT NOW()
);

-- Refresh Token 테이블
CREATE TABLE refresh_tokens (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id     UUID REFERENCES users(id) ON DELETE CASCADE,
    token       VARCHAR(512) NOT NULL,
    device_info VARCHAR(255),           -- User-Agent 기반 디바이스 식별
    expires_at  TIMESTAMPTZ NOT NULL,
    created_at  TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_refresh_tokens_user_id ON refresh_tokens(user_id);
CREATE INDEX idx_refresh_tokens_token ON refresh_tokens(token);
```

```typescript
// src/types/auth.ts
interface User {
    id: string;
    email: string;
    name: string;
    role: 'user' | 'admin';
    provider: 'local' | 'kakao';
}

interface JwtPayload {
    sub: string;      // user.id
    email: string;
    role: string;
    iat: number;
    exp: number;
}

interface TokenPair {
    accessToken: string;
    refreshToken: string;
}
```

### API 설계

| Method | Endpoint | 설명 | 인증 |
|--------|----------|------|------|
| POST | /api/auth/signup | 이메일 회원가입 | 불필요 |
| POST | /api/auth/login | 이메일 로그인 | 불필요 |
| POST | /api/auth/refresh | Access Token 갱신 | Refresh Token |
| POST | /api/auth/logout | 로그아웃 (Refresh Token 폐기) | 필요 |
| GET | /api/auth/me | 현재 사용자 정보 조회 | 필요 |
| GET | /api/auth/kakao | 카카오 OAuth 시작 (리다이렉트) | 불필요 |
| GET | /api/auth/kakao/callback | 카카오 OAuth 콜백 처리 | 불필요 |

**요청/응답 예시 (로그인)**:
```
POST /api/auth/login
Content-Type: application/json

{ "email": "user@example.com", "password": "SecureP@ss1" }

→ 200 OK
Set-Cookie: access_token=eyJ...; HttpOnly; Secure; SameSite=Strict; Max-Age=900
Set-Cookie: refresh_token=eyJ...; HttpOnly; Secure; SameSite=Strict; Path=/api/auth/refresh; Max-Age=604800

{ "user": { "id": "uuid", "email": "user@example.com", "name": "홍길동", "role": "user" } }
```

### 핵심 로직

```
[회원가입 플로우]
1. 이메일 중복 확인
2. 비밀번호 검증 (8자 이상, 영문+숫자+특수문자)
3. bcrypt로 비밀번호 해싱 (salt rounds: 12)
4. users 테이블에 저장
5. Token Pair 발급 → 쿠키에 설정
6. 사용자 정보 반환

[Refresh Token 로테이션 플로우]
1. 클라이언트가 /api/auth/refresh 요청
2. 쿠키에서 Refresh Token 추출
3. DB에서 해당 토큰 조회
   - 없으면 → 401 (토큰 탈취 의심, 해당 user의 모든 Refresh Token 삭제)
   - 만료 → 401
4. 기존 Refresh Token 삭제
5. 새 Access Token + 새 Refresh Token 발급
6. 새 Refresh Token DB 저장
7. 쿠키에 새 토큰 설정

[카카오 OAuth 플로우]
1. /api/auth/kakao → 카카오 인증 페이지로 리다이렉트
2. 사용자가 카카오에서 인증
3. /api/auth/kakao/callback으로 authorization code 수신
4. 카카오 API에서 access token 교환
5. 카카오 API에서 사용자 프로필 조회
6. provider_id로 기존 사용자 확인
   - 있으면 → 기존 계정으로 로그인
   - 없으면 → 신규 계정 생성 (password: NULL)
7. Token Pair 발급 → 프론트엔드로 리다이렉트
```

### 에러 처리
- **이메일 중복 (409)**: "이미 등록된 이메일입니다" 메시지 반환. 소셜 로그인 계정이면 해당 provider 안내
- **잘못된 비밀번호 (401)**: "이메일 또는 비밀번호가 올바르지 않습니다" (보안상 어느 쪽이 틀린지 구분하지 않음)
- **토큰 만료 (401)**: Access Token 만료 시 프론트엔드가 자동으로 /refresh 호출, Refresh Token도 만료면 로그인 페이지로 리다이렉트
- **토큰 탈취 감지 (401)**: Refresh Token이 DB에 없는 경우 해당 사용자의 모든 세션 강제 만료
- **카카오 API 장애 (502)**: "소셜 로그인 서비스가 일시적으로 불안정합니다. 잠시 후 다시 시도해주세요"
- **권한 부족 (403)**: "이 기능에 대한 접근 권한이 없습니다"

---

## 검증 계약 (Verification Contract)

> Generator(구현자)와 Evaluator(검증자)가 사전에 합의하는 성공 조건.
> `/gap` 실행 시 이 목록을 기준으로 평가한다.

### 기능 검증 조건

| # | 조건 | 우선순위 |
|---|------|---------|
| 1 | 사용자가 이메일/비밀번호로 회원가입하면 계정이 생성되고 자동 로그인되어야 한다 | Critical |
| 2 | 로그인 성공 시 Access Token(15분)과 Refresh Token(7일)이 HttpOnly 쿠키로 설정되어야 한다 | Critical |
| 3 | Access Token 만료 후 /api/auth/refresh 호출 시 새 토큰 쌍이 발급되어야 한다 | Critical |
| 4 | Refresh Token 재사용 시 해당 사용자의 모든 Refresh Token이 삭제되어야 한다 (탈취 감지) | Critical |
| 5 | 카카오 로그인으로 신규 가입과 기존 계정 로그인이 모두 동작해야 한다 | Critical |
| 6 | admin 역할이 아닌 사용자가 관리자 API 접근 시 403이 반환되어야 한다 | Critical |
| 7 | 비밀번호는 bcrypt로 해싱되어 DB에 평문이 저장되지 않아야 한다 | Critical |
| 8 | 로그아웃 시 Refresh Token이 DB에서 삭제되고 쿠키가 제거되어야 한다 | Critical |
| 9 | 잘못된 비밀번호로 로그인 시 이메일/비밀번호 중 어느 것이 틀렸는지 구분하지 않아야 한다 | Nice-to-have |
| 10 | 동시에 여러 디바이스에서 로그인이 가능해야 한다 | Nice-to-have |

### 역방향 검증 체크리스트
- [ ] Plan의 MECE 4개 영역(인증, 인가, 세션 관리, 계정 관리)이 모두 설계에 반영되었는가?
- [ ] 설계의 각 API 엔드포인트가 Plan의 구현 범위 항목과 1:1 매핑되는가?
- [ ] Refresh Token 로테이션 로직에서 동시 요청(race condition) 엣지 케이스가 처리되는가?
- [ ] 카카오 로그인 실패 시(사용자 취소, API 장애) 에러 처리가 정의되었는가?

### 평가 기준
- **기능**: 검증 조건 #1~#8이 모두 통과하는가?
- **설계 품질**: 인증 미들웨어가 일관되게 적용되고, 소셜 로그인 추가가 용이한 구조인가?
- **단순성**: 자체 인증 서버 없이 Express.js 미들웨어로 깔끔하게 처리되는가?
