/// 수리기사 화면은 아직 백엔드 연동 전 단계(스켈레톤)라서, 화면을 채워 보여줄
/// 로컬 목업 데이터만 정의한다. TODO: technician_service.dart + 실제 작업 배정
/// API가 추가되면 이 목업 대신 서버 데이터를 사용하도록 교체해야 한다.
enum TechnicianJobStatus { scheduled, inProgress, onHold, completed }

class TechnicianJob {
  const TechnicianJob({
    required this.id,
    required this.title,
    required this.unit,
    required this.tenantName,
    required this.address,
    required this.visitTime,
    required this.priority,
    required this.status,
    required this.symptomDescription,
    required this.instruction,
    required this.contactPhone,
    required this.receivedAt,
    this.estimatedCost,
    this.actualCost,
  });

  final String id;
  final String title;
  final String unit;
  final String tenantName;
  final String address;
  final String visitTime;
  final String priority;
  final TechnicianJobStatus status;
  final String symptomDescription;
  final String instruction;
  final String contactPhone;
  final String receivedAt;
  final String? estimatedCost;
  final String? actualCost;

  String get statusLabel {
    switch (status) {
      case TechnicianJobStatus.scheduled:
        return '방문 예정';
      case TechnicianJobStatus.inProgress:
        return '진행 중';
      case TechnicianJobStatus.onHold:
        return '보류';
      case TechnicianJobStatus.completed:
        return '완료';
    }
  }
}

const mockTechnicianJobs = [
  TechnicianJob(
    id: 'job-1',
    title: '욕실 누수 수리',
    unit: '101호',
    tenantName: '김세입자',
    address: '서울 마포구 서교동 123',
    visitTime: '오전 10:00',
    priority: '긴급',
    status: TechnicianJobStatus.scheduled,
    symptomDescription: '욕실 세면대 하부에서 물이 계속 새고 있습니다.',
    instruction: '배관 연결부 점검 후 필요시 부품 교체. 교체가 필요한 경우 사전 승인 요청 필수.',
    contactPhone: '010-0000-0001',
    receivedAt: '2025년 6월 3일',
    estimatedCost: '150,000원',
  ),
  TechnicianJob(
    id: 'job-2',
    title: '보일러 점검 및 교체',
    unit: '105호',
    tenantName: '최세입자',
    address: '서울 은평구 불광동 45',
    visitTime: '오후 1:30',
    priority: '일반',
    status: TechnicianJobStatus.scheduled,
    symptomDescription: '보일러가 작동하지 않고 온수가 나오지 않습니다.',
    instruction: '보일러 점화 계통 점검 후 상태 보고.',
    contactPhone: '010-0000-0002',
    receivedAt: '2025년 6월 2일',
    estimatedCost: '200,000원',
  ),
  TechnicianJob(
    id: 'job-3',
    title: '거실 전기 콘센트 불량',
    unit: '203호',
    tenantName: '이세입자',
    address: '서울 서대문구 홍제동 78',
    visitTime: '오후 4:00',
    priority: '낮음',
    status: TechnicianJobStatus.inProgress,
    symptomDescription: '거실 콘센트에 전원이 들어오지 않습니다.',
    instruction: '배선 및 차단기 점검.',
    contactPhone: '010-0000-0003',
    receivedAt: '2025년 6월 1일',
    estimatedCost: '80,000원',
    actualCost: '80,000원',
  ),
  TechnicianJob(
    id: 'job-4',
    title: '주방 배수관 막힘',
    unit: '401호',
    tenantName: '정세입자',
    address: '서울 마포구 연남동 12',
    visitTime: '일정 미정',
    priority: '부품 대기',
    status: TechnicianJobStatus.onHold,
    symptomDescription: '주방 싱크대 배수구에서 물이 내려가지 않고 역류합니다. 악취도 동반됩니다.',
    instruction: '배수관 내부 이물질 제거 후 상태 점검. 교체 필요 부품 입고 대기 중.',
    contactPhone: '010-0000-0004',
    receivedAt: '2025년 5월 30일',
    estimatedCost: '120,000원',
  ),
];
