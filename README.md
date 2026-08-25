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
    auth_storage.dart       # access token/user id/name/phone 로컬 저장 (flutter_secure_storage)
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
  models/                   # API 응답 모델 (User, Report, Quote, Vendor) + technician_job.dart(실제 데이터+목업 폴백)
  services/                 # 도메인별 API 호출 (auth/report/repair/quote/landlord) + technician_job_loader.dart
  screens/
    auth/                   # 로그인, 회원가입(카드형 유형 선택 포함)
    tenant/                 # 세입자: 홈, 신고 생성/추가정보, 분석 결과(자가조치·제조사AS·업체매칭),
                             # 방문 일정, 수리 진행 현황, 신고 내역/상세
    landlord/                # 임대인: 대시보드, 요청 관리/상세(승인·거절), 방문 일정, 호실 관리, 자동 승인 설정
    technician/               # 수리기사: 홈, 배정 작업 목록, 작업 상세, 수리 완료 확인
    settings/                 # 공용: 설정, 계정 정보, 사용자 유형 변경, 알림 설정
```

## 백엔드 연동

- 백엔드: `unithon-2026-oideoide/ROOMSOLVE-backend` (Node.js/Express), Swagger 문서:
  `http://134.185.108.221:3000/api-docs/#/`
- 인증은 Supabase Auth 기반이며, 로그인/회원가입 응답(`{user, session}`)의
  `session.access_token`을 `flutter_secure_storage`에 저장하고 이후 모든 요청에
  `Authorization: Bearer <token>` 헤더로 자동 첨부합니다 (`core/api_client.dart`의
  인터셉터). 사용자 id/name/phone도 함께 저장해 앱 재시작 후에도 role 변경,
  계정 정보 화면 등에서 쓸 수 있게 했습니다.
- 현재 백엔드 API가 전부 준비되어 있지 않을 수 있어서, 모든 API 호출 실패는
  `ApiException`으로 정규화되어 화면에 에러 메시지만 표시하고 앱이 죽지 않도록
  처리했습니다.

### 실제로 연결된 API

- 인증: `POST /api/auth/login`, `POST /api/auth/signup`
- 사용자: `PATCH /api/users/{id}/role` (사용자 유형 변경 화면)
- 신고: `POST /api/reports`, `GET /api/reports`, `GET /api/reports/{id}`,
  `POST /api/reports/analyze`, `POST /api/uploads`
- 자가수리 챗봇: `POST /api/reports/chat` (자가조치가이드 화면, 무상태 — 대화
  기록은 클라이언트가 들고 매 요청에 함께 보냄)
- 수리 진행: `GET /api/repair/timeline`(수리 진행 현황/신고 내역 상세),
  `GET /api/repair/schedule`(방문 일정 확정 화면·수리기사 배정 작업 목록),
  `POST /api/repair/schedule`(수리기사의 "방문 가능 시간 제출"),
  `POST /api/repair/status`(수리기사의 "확인 및 전송" = 완료 처리)
- 업체 매칭 / 제조사 A/S: `POST /api/vendors/match`, `GET /api/manufacturer-as`
- 임대인: `GET/PATCH /api/landlord/requests`, `GET /api/landlord/properties`,
  `POST /api/landlord/auto-approval-policy`
- 견적: `POST/GET /api/quotes`, `PATCH /api/quotes/{id}/status` (`quote_service.dart`,
  현재 화면에서 직접 쓰지는 않음)

### 알아둘 점 / 알려진 제약

- `PATCH /api/repair/schedule/{id}/confirm`(방문 일정 확정)은 서비스 메서드
  (`RepairService.confirmSchedule`)만 만들어 두었고 아직 어떤 화면에서도 호출하지
  않습니다.
- 백엔드에 "기사 목록 조회" API가 없어서, 임대인 화면에서 수리기사를 골라
  방문 일정을 새로 등록하는 흐름은 구현하지 않았습니다. 현재는 수리기사가
  자기 자신을(`technicianId` = 로그인한 사용자 id) 스스로 일정에 등록하는
  방식(`job_detail_screen.dart`의 "방문 가능 시간 제출")만 가능합니다.

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
| 세입자 - 자가조치가이드 | `screens/tenant/report_result_screen.dart` (`_SelfFixView`) | 완료 (`POST /api/reports/chat` 실연동) |
| 세입자 - 제조사AS | `screens/tenant/report_result_screen.dart` (`_ManufacturerAsView`) | 완료 |
| 세입자 - 전문 업체 매칭 | `screens/tenant/report_result_screen.dart` (`_VendorMatchView`) | 완료 |
| 세입자 - 방문 일정 확정 | `screens/tenant/report_visit_schedule_screen.dart` | 완료 (`GET /api/repair/schedule` 실연동, 일정 없으면 예시값) |
| 세입자 - 수리 진행 현황 | `screens/tenant/report_progress_screen.dart` | 완료 (`GET /api/repair/timeline` 실연동) |
| 임대인 - 홈 | `screens/landlord/landlord_dashboard_screen.dart` | 완료 |
| 임대인 - 수리요청 / 수리요청 상세 | `screens/landlord/request_detail_screen.dart` | 완료 (두 디자인을 하나의 상세 화면으로 통합) |
| 임대인 - 수리요청 거절 | `request_detail_screen.dart` 내 확인 다이얼로그 | 완료 |
| 임대인 - 승인 거절 안내 | `screens/landlord/request_rejected_screen.dart` | 완료 |
| 임대인 - 수리요청관리 | `screens/landlord/landlord_requests_screen.dart` | 완료 |
| 임대인 - 자동처리 한도 설정 | `screens/landlord/auto_approval_setting_screen.dart` | 완료 |
| 임대인 - 방문 일정 확정 | `screens/landlord/landlord_visit_schedule_screen.dart` | 완료 (`GET /api/repair/schedule` 실연동, 일정 없으면 예시값) |
| 임대인 - 호실 관리 화면 | `screens/landlord/landlord_units_screen.dart` | 완료 |
| 수리기사 홈 화면 | `screens/technician/technician_home_screen.dart` | 완료 (`GET /api/repair/schedule?technicianId=` 실연동, 배정 없으면 목업) |
| 배정 작업 목록 화면 | `screens/technician/technician_job_list_screen.dart` | 완료 (위와 동일) |
| 작업 상세 화면 | `screens/technician/job_detail_screen.dart` | 완료 ("방문 가능 시간 제출"이 `POST /api/repair/schedule` 실호출) |
| 수리 완료 확인 화면 | `screens/technician/repair_complete_screen.dart` | 완료 ("확인 및 전송"이 `POST /api/repair/status` 실호출) |
| 신고 내역 화면 | `screens/tenant/report_list_screen.dart` | 완료 |
| 신고 내역 상세 화면 | `screens/tenant/report_detail_screen.dart` | 완료 (타임라인은 `GET /api/repair/timeline` 실연동) |
| 설정 화면 | `screens/settings/settings_screen.dart` | 완료 (로그아웃 버튼을 여기로 이동) |
| 사용자 유형 변경 화면 | `screens/settings/role_change_screen.dart` | 완료 (`PATCH /api/users/{id}/role` 실연동) |
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
- **수리기사 상세 필드**: `RepairSchedule`/`Report` 응답에 위치, 세입자 연락처,
  작업 지시 문구가 없어 `작업 상세 화면`에서 이 항목들은 "정보 없음"으로
  표시됩니다. 관련 필드가 백엔드에 추가되면 `TechnicianJob.fromApi`
  (`lib/models/technician_job.dart`)만 고치면 됩니다.
- **임대인의 수리기사 배정**: "기사 목록 조회" API가 없어 임대인이 직접
  기사를 골라 일정을 잡는 화면/버튼은 만들지 않았습니다. 관련 API가 생기면
  `RepairService.createSchedule`을 그대로 재사용해 연결할 수 있습니다.
- **방문 일정 확정(confirm) 액션**: `RepairService.confirmSchedule`
  (`PATCH /api/repair/schedule/{id}/confirm`)은 만들어 뒀지만 아직 어떤 버튼도
  호출하지 않습니다. 방문 일정을 누가/언제 확정하는지 플로우가 정해지면
  연결해야 합니다.
- **자동처리 한도 금액 조회**: `POST /api/landlord/auto-approval-policy`만
  있고 현재 설정값을 읽는 GET이 없어, 임대인 홈의 "이번 달 자동처리 사용액"
  카드는 디자인의 예시 숫자를 그대로 씁니다.
- **알림 수신 채널/설정 저장**: `notification_settings_screen.dart`는 저장 시
  서버에 반영되지 않고 로컬 상태만 바뀝니다. 알림 설정 API가 추가되면 연동이
  필요합니다.
- **디자인에 없던 값 보완**: 신고 내역 상세의 위치/비용 부담, 요청 상세의
  "예상 비용"·"업체 평점" 등 일부 필드는 백엔드 응답에 대응 필드가 없어
  디자인의 예시 값을 그대로 쓰고 있습니다(각 파일 상단 주석에 `TODO`로 표시).

## 테스트

```bash
flutter test
```
