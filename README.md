# frontend

집 하자보수 매칭 플랫폼 (세입자 / 임대인 / 수리기사) Flutter 앱.

디자인 시안이 아직 없어서, 현재는 화면 구조·네비게이션·API 연동 뼈대만 잡혀 있고
UI는 기본 Material 위젯으로만 구성되어 있습니다. 실제 디자인은 이후 별도로 적용합니다.

## 시작하기

```bash
flutter pub get
```

`.env.example`을 복사해 `.env`를 만들고 백엔드 주소를 채워주세요.

```bash
cp .env.example .env
# .env
# API_BASE_URL=http://localhost:3000
```

```bash
flutter run
```

## 프로젝트 구조

```
lib/
  main.dart                # 앱 진입점, .env 로드, Provider/GoRouter 초기화
  router.dart               # go_router 라우팅, 로그인 여부/role 기반 리다이렉트
  core/
    api_client.dart         # dio 기반 공통 API 클라이언트 (.env의 API_BASE_URL 사용)
    auth_storage.dart       # access token 로컬 저장 (flutter_secure_storage)
  providers/
    auth_provider.dart      # 로그인 상태 및 현재 사용자 role 전역 관리 (Provider)
  models/                   # API 응답 모델 (User, Report, Quote, Vendor)
  services/                 # 도메인별 API 호출 (auth/report/quote/landlord)
  screens/
    auth/                   # 로그인, 회원가입(role 선택 포함)
    tenant/                 # 세입자: 홈, 요청 등록(사진+설명), 분석 결과, 요청 내역
    landlord/                # 임대인: 대시보드, 요청 상세(승인/거절), 자동 승인 설정
    technician/               # 수리기사: 스켈레톤만 (추후 구현)
```

## 백엔드 연동

- 백엔드: `unithon-2026-oideoide/ROOMSOLVE-backend` (Node.js/Express)
- 인증은 Supabase Auth 기반이며, 로그인/회원가입 응답의 access token을
  `flutter_secure_storage`에 저장하고 이후 모든 요청에 `Authorization: Bearer <token>`
  헤더로 자동 첨부합니다 (`core/api_client.dart`의 인터셉터).
- 현재 백엔드 API가 전부 준비되어 있지 않을 수 있어서, 모든 API 호출 실패는
  `ApiException`으로 정규화되어 화면에 에러 메시지만 표시하고 앱이 죽지 않도록
  처리했습니다.

## 상태관리

Provider를 사용합니다 (러닝커브가 낮아 팀 전체가 빠르게 익힐 수 있어 선택).
로그인 상태/역할은 `providers/auth_provider.dart`의 `AuthProvider`에서 관리하며,
`router.dart`가 이를 구독해 로그인 여부와 역할에 따라 리다이렉트합니다.

## 디자인 적용 시 교체 안내

디자인 시안이 나오면 아래 폴더/파일 위주로 교체하면 됩니다. 라우팅 구조와 API 연동
로직(`core/`, `services/`, `providers/`, `router.dart`)은 그대로 유지한 채 화면
내부 위젯만 바꾸면 됩니다.

- `lib/screens/**/*.dart` — 각 화면의 `// TODO: 디자인 적용 필요` 표시된 위젯들을
  실제 디자인 컴포넌트로 교체
- 공통 테마/컬러/타이포그래피를 적용하려면 `lib/main.dart`의 `MaterialApp.router`
  `theme:` 부분에 `ThemeData`를 디자인 시스템에 맞게 정의
- 공통 위젯(버튼, 카드, 입력 필드 등)이 정해지면 `lib/widgets/` 폴더를 새로 만들어
  재사용 컴포넌트로 분리하는 것을 권장합니다.

## 테스트

```bash
flutter test
```
