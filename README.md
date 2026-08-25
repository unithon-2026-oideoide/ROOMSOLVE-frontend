# frontend

집 하자보수 매칭 플랫폼 (세입자 / 임대인 / 수리기사) Flutter 앱.

Figma "ROOMSOLVE 와이어프레임" 디자인을 기준으로 색상/타이포그래피 테마와 전체
화면 UI가 적용되어 있습니다. 자세한 내용은 [디자인 적용 완료](#디자인-적용-완료)
섹션을 참고하세요.

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
  core/
    role_routes.dart        # role별 홈/요청 경로, role 라벨 헬퍼 (router.dart와 설정 화면이 공유)
  providers/
    auth_provider.dart      # 로그인 상태 및 현재 사용자 role 전역 관리 (Provider)
  theme/
    app_colors.dart         # Figma 색상 토큰 (브랜드 블루 램프, 그레이스케일, 액센트)
    app_text_styles.dart    # Figma 타이포그래피 램프 (Title/Subtitle/Body/Button/Caption)
    app_theme.dart          # 위 토큰으로 구성한 앱 전역 ThemeData
  widgets/
    app_top_bar.dart        # 공용 "ROOMSOLVE" 상단 바
    app_bottom_nav.dart     # 공용 하단 탭(홈/신고·요청/설정)
  models/                   # API 응답 모델 (User, Report, Quote, Vendor) + technician_job.dart(목업)
  services/                 # 도메인별 API 호출 (auth/report/quote/landlord)
  screens/
    auth/                   # 로그인, 회원가입(카드형 유형 선택 포함)
    tenant/                 # 세입자: 홈, 신고 생성/추가정보, 분석 결과(자가조치·제조사AS·업체매칭),
                             # 방문 일정, 수리 진행 현황, 신고 내역/상세
    landlord/                # 임대인: 대시보드, 요청 관리/상세(승인·거절), 방문 일정, 호실 관리, 자동 승인 설정
    technician/               # 수리기사: 홈, 배정 작업 목록, 작업 상세, 수리 완료 확인 (백엔드 API 없어 목업 데이터)
    settings/                 # 공용: 설정, 계정 정보, 사용자 유형 변경, 알림 설정
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

## 디자인 적용 완료

Figma 파일 "ROOMSOLVE 와이어프레임"(fileKey `haIm2BdzxDs72DhVpDuNkg`) Page 1의
프레임 29개를 모두 화면에 반영했습니다. 기존 화면의 API 연동 로직(report_service,
landlord_service 등 호출과 에러 처리)은 그대로 두고 레이아웃/스타일만 교체했습니다.

| 프레임 | 화면 파일 | 상태 |
| --- | --- | --- |
| 로그인 | `screens/auth/login_screen.dart` | 완료 |
| 유형 선택 | `screens/auth/signup_screen.dart` | 완료 (회원가입 폼 + 카드형 유형 선택 통합) |
| 세입자 - 홈 | `screens/tenant/tenant_home_screen.dart` | 완료 |
| 세입자 - 새 문제 신고 | `screens/tenant/report_create_screen.dart` | 완료 (1단계: 설명+사진) |
| 세입자 - 추가정보입력 | `screens/tenant/report_additional_info_screen.dart` | 완료 (2단계: AI 분석 호출) |
| 세입자 - 자가조치가이드 | `screens/tenant/report_result_screen.dart` (`_SelfFixView`) | 완료 |
| 세입자 - 제조사AS | `screens/tenant/report_result_screen.dart` (`_ManufacturerAsView`) | 완료 |
| 세입자 - 전문 업체 매칭 | `screens/tenant/report_result_screen.dart` (`_VendorMatchView`) | 완료 |
| 세입자 - 방문 일정 확정 | `screens/tenant/report_visit_schedule_screen.dart` | 완료 |
| 세입자 - 수리 진행 현황 | `screens/tenant/report_progress_screen.dart` | 완료 |
| 임대인 - 홈 | `screens/landlord/landlord_dashboard_screen.dart` | 완료 |
| 임대인 - 수리요청 / 수리요청 상세 | `screens/landlord/request_detail_screen.dart` | 완료 (두 디자인을 하나의 상세 화면으로 통합) |
| 임대인 - 수리요청 거절 | `request_detail_screen.dart` 내 확인 다이얼로그 | 완료 |
| 임대인 - 승인 거절 안내 | `screens/landlord/request_rejected_screen.dart` | 완료 |
| 임대인 - 수리요청관리 | `screens/landlord/landlord_requests_screen.dart` | 완료 |
| 임대인 - 자동처리 한도 설정 | `screens/landlord/auto_approval_setting_screen.dart` | 완료 |
| 임대인 - 방문 일정 확정 | `screens/landlord/landlord_visit_schedule_screen.dart` | 완료 |
| 임대인 - 호실 관리 화면 | `screens/landlord/landlord_units_screen.dart` | 완료 |
| 수리기사 홈 화면 | `screens/technician/technician_home_screen.dart` | 완료 (목업 데이터) |
| 배정 작업 목록 화면 | `screens/technician/technician_job_list_screen.dart` | 완료 (목업 데이터) |
| 작업 상세 화면 | `screens/technician/job_detail_screen.dart` | 완료 (목업 데이터) |
| 수리 완료 확인 화면 | `screens/technician/repair_complete_screen.dart` | 완료 (목업 데이터) |
| 신고 내역 화면 | `screens/tenant/report_list_screen.dart` | 완료 |
| 신고 내역 상세 화면 | `screens/tenant/report_detail_screen.dart` | 완료 |
| 설정 화면 | `screens/settings/settings_screen.dart` | 완료 (로그아웃 버튼을 여기로 이동) |
| 사용자 유형 변경 화면 | `screens/settings/role_change_screen.dart` | 완료 |
| 알림 설정 화면 | `screens/settings/notification_settings_screen.dart` | 완료 (로컬 상태만) |
| 계정 정보 화면 | `screens/settings/account_info_screen.dart` | 완료 |

### 남은 작업

- **아이콘 에셋**: 하단 탭, 상태 배지 등은 Material Icons로 대체했습니다.
  Figma의 실제 SVG 아이콘(예: `settings`, `home`, `send`, `arrow-up-right`)으로
  교체하려면 `download_assets` 등으로 원본을 받아 `assets/icons/`에 추가하고
  각 화면에서 `Icon(...)` 대신 `Image.asset(...)`으로 바꿔야 합니다.
- **실제 폰트 파일 추가**: 원래 디자인 폰트는 Pretendard이지만, Google Fonts
  카탈로그에 없어 `google_fonts` 패키지로 Noto Sans KR을 대체 사용 중입니다
  (`lib/theme/app_text_styles.dart` 상단 주석 참고). Pretendard 실물 폰트를
  쓰려면 `.ttf`를 `assets/fonts/`에 추가하고 `pubspec.yaml`의 `fonts:` 섹션에
  등록한 뒤 `AppTextStyles`의 `GoogleFonts.notoSansKr(...)` 호출을
  `TextStyle(fontFamily: 'Pretendard', ...)`로 교체하면 됩니다.
- **수리기사 화면 백엔드 연동**: `technician/` 화면 4개는 대응하는 백엔드
  API/서비스가 아직 없어 `lib/models/technician_job.dart`의 로컬 목업 데이터를
  사용합니다. `technician_service.dart`와 실제 작업 배정 API가 추가되면
  목업을 서버 데이터로 교체해야 합니다.
- **디자인에 없던 값 보완**: 방문 일정(날짜/시간/업체), 자동처리 한도 금액,
  신고 내역 상세의 위치/긴급도 등 일부 필드는 백엔드 응답에 대응 필드가 없어
  디자인의 예시 값을 그대로 쓰고 있습니다. 관련 API가 확정되면 실데이터로
  교체해야 합니다 (각 파일 상단 주석에 `TODO`로 표시).
- **알림 수신 채널/설정 저장**: `notification_settings_screen.dart`는 저장 시
  서버에 반영되지 않고 로컬 상태만 바뀝니다. 알림 설정 API가 추가되면 연동이
  필요합니다.

## 테스트

```bash
flutter test
```
