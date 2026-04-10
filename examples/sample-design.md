# [Design] 사용자 인증

> Nova Engineering — CPS Framework
> 작성일: 2026-03-21
> Plan 문서: examples/sample-plan.md

---

## Context (설계 배경)

### Plan 요약
- 핵심 문제: 인증 시스템이 없어 사용자를 식별할 수 없고, API를 보호할 수 없다
- 선택한 방안: JWT 이중 토큰 (Access 15분 + Refresh 7일) 기반 인증

### 설계 원칙
- **보안 우선**: 비밀번호 해싱, 토큰 회전, HTTPS 전제
- **단순성**: 필요 최소한의 인증 흐름만 구현 (소셜 로그인은 2차)
- **Stateless 지향**: Access Token 검증에 DB 조회 불필요

---

## Problem (설계 과제)

### 기술적 과제

| # | 과제 | 복잡도 | 의존성 |
|---|------|--------|--------|
| 1 | 사용자 테이블 스키마 확장 (password_hash, refresh_token) | 낮음 | 없음 |
| 2 | JWT 발급/검증 모듈 구현 | 중간 | 없음 |
| 3 | 인증 API 엔드포인트 (register, login, refresh, logout) | 중간 | 과제#1, #2 |
| 4 | AuthGuard 미들웨어 및 기존 라우트 적용 | 중간 | 과제#2 |
| 5 | Refresh Token 회전(rotation) 및 탈취 감지 | 높음 | 과제#3 |
| 6 | 비밀번호 재설정 이메일 흐름 | 중간 | 과제#1 |

### 기존 시스템과의 접점
- `users` 테이블: 기존 email, name 필드에 인증 관련 컬럼 추가
- API 라우트: 기존 비보호 라우트에 AuthGuard 적용 필요 (점진적 적용)
- 프론트엔드: axios interceptor에서 401 수신 시 자동 토큰 갱신 로직 필요

---

## Solution (설계 상세)

### 아키텍처

```
┌──────────────┐     ┌────────────────────────────────┐     ┌──────────┐
│   Frontend   │────→│          NestJS Backend         │────→│ PostgreSQL│
│   (Next.js)  │←────│                                 │←────│          │
└──────────────┘     │  ┌──────────┐  ┌────────────┐  │     └──────────┘
                     │  │AuthModule│  │ AuthGuard   │  │
                     │  │          │  │ (미들웨어)   │  │
                     │  │ - register│  │             │  │
                     │  │ - login  │  │ JWT 검증    │  │
                     │  │ - refresh│  │ → 통과/거부  │  │
                     │  │ - logout │  │             │  │
                     │  └──────────┘  └────────────┘  │
                     └────────────────────────────────┘

[인증 흐름]
1. 로그인 → Access Token + Refresh Token 발급
2. API 호출 → Authorization: Bearer {accessToken}
3. AuthGuard → JWT 서명 검증 (DB 조회 없음)
4. Access Token 만료 → Refresh Token으로 갱신
5. Refresh Token 사용 시 → 기존 폐기 + 새 쌍 발급 (회전)
```

### 데이터 모델

```sql
-- 기존 users 테이블 확장 마이그레이션
ALTER TABLE users ADD COLUMN password_hash VARCHAR(255) NOT NULL;
ALTER TABLE users ADD COLUMN refresh_token_hash VARCHAR(255);
ALTER TABLE users ADD COLUMN refresh_token_expires_at TIMESTAMP;
ALTER TABLE users ADD COLUMN password_reset_token VARCHAR(255);
ALTER TABLE users ADD COLUMN password_reset_expires_at TIMESTAMP;
ALTER TABLE users ADD COLUMN failed_login_attempts INTEGER DEFAULT 0;
ALTER TABLE users ADD COLUMN locked_until TIMESTAMP;
```

```typescript
// src/auth/entities/user.entity.ts (인증 관련 필드)
interface UserAuth {
  id: string;              // UUID, PK
  email: string;           // UNIQUE, 로그인 식별자
  password_hash: string;   // bcrypt 해시 (라운드 12)
  refresh_token_hash: string | null;    // 해시된 Refresh Token
  refresh_token_expires_at: Date | null;
  failed_login_attempts: number;        // 연속 실패 횟수
  locked_until: Date | null;            // 계정 잠금 시각
}
```

```typescript
// JWT Payload
interface JwtPayload {
  sub: string;    // user.id
  email: string;
  iat: number;    // 발급 시각
  exp: number;    // 만료 시각
}
```

### API 설계

| Method | Endpoint | 설명 | 인증 필요 |
|--------|----------|------|----------|
| POST | /auth/register | 회원가입 | X |
| POST | /auth/login | 로그인 (토큰 발급) | X |
| POST | /auth/refresh | Access Token 갱신 | X (Refresh Token) |
| POST | /auth/logout | 로그아웃 (Refresh Token 무효화) | O |
| POST | /auth/reset-password/request | 비밀번호 재설정 요청 (이메일 발송) | X |
| POST | /auth/reset-password/confirm | 비밀번호 재설정 확인 | X (Reset Token) |
| GET | /auth/me | 현재 사용자 정보 조회 | O |

**POST /auth/register**
```json
// Request
{ "email": "user@example.com", "password": "SecureP@ss1", "name": "홍길동" }

// Response 201
{ "id": "uuid", "email": "user@example.com", "name": "홍길동", "createdAt": "2026-03-21T..." }

// Error 409
{ "statusCode": 409, "message": "이미 등록된 이메일입니다" }
```

**POST /auth/login**
```json
// Request
{ "email": "user@example.com", "password": "SecureP@ss1" }

// Response 200
{
  "accessToken": "eyJhbG...",
  "refreshToken": "dGhpcyBpcyBh...",
  "expiresIn": 900
}

// Error 401
{ "statusCode": 401, "message": "이메일 또는 비밀번호가 올바르지 않습니다" }
```

**POST /auth/refresh**
```json
// Request
{ "refreshToken": "dGhpcyBpcyBh..." }

// Response 200 — 새 토큰 쌍 발급 (Refresh Token 회전)
{
  "accessToken": "eyJhbG...(new)",
  "refreshToken": "bmV3IHJl...(new)",
  "expiresIn": 900
}
```

### 핵심 로직

```
[회원가입 흐름]
1. 이메일 중복 확인 → 중복 시 409 반환
2. 비밀번호 유효성 검증 (8자 이상, 대소문자+숫자+특수문자)
3. bcrypt.hash(password, 12) → password_hash 저장
4. 사용자 레코드 생성 → 201 반환

[로그인 흐름]
1. 이메일로 사용자 조회 → 없으면 401
2. 계정 잠금 여부 확인 → locked_until > now 이면 423
3. bcrypt.compare(password, password_hash) → 불일치 시:
   - failed_login_attempts += 1
   - 5회 이상 실패 시 locked_until = now + 30분
   - 401 반환
4. 일치 시:
   - failed_login_attempts = 0
   - Access Token 생성 (만료: 15분)
   - Refresh Token 생성 (만료: 7일)
   - Refresh Token 해시하여 DB 저장
   - 토큰 쌍 반환

[Refresh Token 회전]
1. 전달된 Refresh Token을 해시하여 DB의 해시와 비교
2. 불일치 → 탈취 의심 → 해당 사용자의 모든 Refresh Token 무효화 + 401
3. 일치 + 만료 전 → 새 Access Token + 새 Refresh Token 발급
4. 기존 Refresh Token 해시 교체 (회전 완료)
```

### 에러 처리

- **이메일 중복 (409 Conflict)**: "이미 등록된 이메일입니다" — 가입 화면에서 안내
- **잘못된 자격증명 (401 Unauthorized)**: "이메일 또는 비밀번호가 올바르지 않습니다" — 어느 쪽이 틀렸는지 구분하지 않음 (보안)
- **계정 잠금 (423 Locked)**: "로그인 시도가 너무 많습니다. 30분 후 다시 시도해주세요"
- **만료된 Access Token (401)**: 프론트엔드 interceptor가 자동으로 /auth/refresh 호출
- **만료/무효 Refresh Token (401)**: 로그인 페이지로 리다이렉트
- **Refresh Token 재사용 감지 (401)**: 모든 세션 무효화, 강제 재로그인 유도
- **비밀번호 정책 위반 (400 Bad Request)**: 구체적 위반 사항 안내

---

## 검증 계약 (Verification Contract)

> Generator(구현자)와 Evaluator(검증자)가 사전에 합의하는 성공 조건.
> `/nova:verify` 실행 시 이 목록을 기준으로 평가한다.

### 기능 검증 조건

| # | 조건 | 우선순위 |
|---|------|---------|
| 1 | 유효한 이메일/비밀번호로 회원가입하면 201과 사용자 정보가 반환되어야 한다 | Critical |
| 2 | 등록된 이메일/비밀번호로 로그인하면 accessToken과 refreshToken이 반환되어야 한다 | Critical |
| 3 | 유효한 Access Token으로 보호된 API에 접근하면 정상 응답을 받아야 한다 | Critical |
| 4 | 만료되었거나 유효하지 않은 Access Token으로 접근하면 401이 반환되어야 한다 | Critical |
| 5 | 유효한 Refresh Token으로 갱신 요청하면 새 토큰 쌍이 발급되어야 한다 | Critical |
| 6 | 사용된 Refresh Token은 재사용 시 401이 반환되고 모든 세션이 무효화되어야 한다 | Critical |
| 7 | 비밀번호가 DB에 bcrypt 해시로 저장되어야 한다 (평문 저장 금지) | Critical |
| 8 | 로그인 5회 연속 실패 시 계정이 30분간 잠금되어야 한다 | Critical |
| 9 | 로그아웃 시 Refresh Token이 DB에서 무효화되어야 한다 | Critical |
| 10 | 비밀번호 재설정 요청 시 이메일로 재설정 링크가 발송되어야 한다 | Nice-to-have |
| 11 | 재설정 토큰은 1시간 후 만료되어야 한다 | Nice-to-have |

### 역방향 검증 체크리스트
- [ ] 모든 Plan 요구사항이 설계에 반영되었는가?
  - 신원 확인 → register/login API ✓
  - 세션 유지 → JWT 이중 토큰 ✓
  - API 보호 → AuthGuard ✓
  - 비밀번호 보안 → bcrypt + 계정 잠금 ✓
  - 소셜 로그인 → 2차 범위로 명시 ✓
- [ ] 설계의 각 컴포넌트가 Plan의 문제를 해결하는가?
- [ ] 누락된 엣지 케이스가 없는가?
  - Refresh Token 탈취 시나리오 ✓
  - 동시 다중 기기 로그인 → 현재 설계는 단일 Refresh Token (추후 확장 가능)

### 평가 기준
- **기능**: 검증 조건 #1~#9 (Critical)이 모두 동작하는가?
- **설계 품질**: AuthModule이 독립적으로 동작하며 다른 모듈에 영향을 주지 않는가?
- **단순성**: JWT 라이브러리(jsonwebtoken/passport-jwt) 표준 사용, 자체 암호화 구현 없음
