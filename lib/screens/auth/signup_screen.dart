import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/user.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _RoleOption {
  const _RoleOption(this.role, this.title, this.description);
  final UserRole role;
  final String title;
  final String description;
}

const _roleOptions = [
  _RoleOption(UserRole.tenant, '세입자', '수리 문제를 신고하고 해결 진행 상황을 확인합니다.'),
  _RoleOption(UserRole.landlord, '임대인', '수리 요청을 검토하고 수리 진행을 승인 관리합니다.'),
  _RoleOption(UserRole.technician, '수리기사', '배정된 수리 작업을 확인하고 현장 처리를 등록합니다.'),
];

/// 백엔드 REPAIR_CATEGORIES(src/types/index.ts)와 값이 동일해야 한다.
/// 수리기사 회원가입 시 전문 분야(categories) 선택에 쓰인다.
const _categoryOptions = [
  ('plumbing', '배관·누수'),
  ('electrical', '전기·조명'),
  ('heating', '냉난방'),
  ('appliance', '가전'),
  ('door_window', '문·창문'),
  ('interior', '인테리어'),
  ('pest', '해충 방역'),
  ('other', '기타'),
];

class _SignupScreenState extends State<SignupScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _businessNumberController = TextEditingController();
  final _landlordCodeController = TextEditingController();
  UserRole _selectedRole = UserRole.tenant;
  final Set<String> _selectedCategories = {};
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _businessNumberController.dispose();
    _landlordCodeController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_selectedRole == UserRole.technician) {
      if (_businessNumberController.text.trim().isEmpty) {
        setState(() => _errorMessage = '사업자등록번호를 입력해주세요.');
        return;
      }
      if (_selectedCategories.isEmpty) {
        setState(() => _errorMessage = '전문 분야를 최소 1개 선택해주세요.');
        return;
      }
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      await context.read<AuthProvider>().signup(
            email: _emailController.text.trim(),
            password: _passwordController.text,
            name: _nameController.text.trim(),
            role: _selectedRole,
            businessNumber: _selectedRole == UserRole.technician
                ? _businessNumberController.text.trim()
                : null,
            categories: _selectedRole == UserRole.technician ? _selectedCategories.toList() : null,
          );

      if (!mounted) return;

      // 세입자가 가입 시 임대인 초대 코드를 함께 입력했으면 바로 연결을 시도한다.
      // 실패해도(코드 오타 등) 가입 자체는 이미 끝났으니 화면을 막지 않고, 나중에
      // 설정 > 임대인 연결에서 다시 시도할 수 있다는 안내만 보여준다.
      final landlordCode = _landlordCodeController.text.trim();
      if (_selectedRole == UserRole.tenant && landlordCode.isNotEmpty) {
        try {
          await context.read<AuthProvider>().linkLandlord(landlordCode);
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('임대인 연결에 실패했습니다. 설정 > 임대인 연결에서 다시 시도해주세요: $e')),
            );
            await Future.delayed(const Duration(milliseconds: 1200));
          }
        }
      }

      if (mounted) context.go('/');
    } catch (e) {
      setState(() => _errorMessage = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  InputDecoration _pillDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: AppTextStyles.bodyRegular14(color: AppColors.gray5),
      filled: true,
      fillColor: AppColors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(25),
        borderSide: BorderSide.none,
      ),
    );
  }

  Widget _categoryChip(String value, String label) {
    final selected = _selectedCategories.contains(value);
    return GestureDetector(
      onTap: () => setState(() {
        if (selected) {
          _selectedCategories.remove(value);
        } else {
          _selectedCategories.add(value);
        }
      }),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.brandMain : AppColors.gray2,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: AppTextStyles.bodyRegular14(color: selected ? AppColors.white : AppColors.gray8),
        ),
      ),
    );
  }

  /// 수리기사(technician) 선택 시에만 보이는 사업자등록번호 + 전문 분야 입력.
  /// 백엔드가 role=technician일 때 둘 다 필수로 요구한다(auth.controller.ts).
  Widget _technicianFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 20),
        Text('업체 정보', style: AppTextStyles.subtitleBold18(color: AppColors.brandDark)),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(25),
            boxShadow: AppColors.dropShadow,
          ),
          child: TextField(
            controller: _businessNumberController,
            style: AppTextStyles.bodyRegular14(color: AppColors.black),
            decoration: _pillDecoration('사업자등록번호 (예: 123-45-67890)'),
          ),
        ),
        const SizedBox(height: 16),
        Text('전문 분야 (최소 1개 선택)', style: AppTextStyles.bodyRegular14(color: AppColors.gray6)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [for (final c in _categoryOptions) _categoryChip(c.$1, c.$2)],
        ),
      ],
    );
  }

  /// 세입자(tenant) 선택 시에만 보이는 임대인 초대 코드 입력. 선택 사항이라
  /// 비워두고 가입해도 되고, 나중에 설정 > 임대인 연결에서 입력해도 된다.
  Widget _tenantFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 20),
        Text('임대인 연결 (선택)', style: AppTextStyles.subtitleBold18(color: AppColors.brandDark)),
        const SizedBox(height: 8),
        Text(
          '임대인에게 받은 초대 코드가 있다면 입력해주세요. 나중에 설정에서도 연결할 수 있습니다.',
          style: AppTextStyles.bodyRegular14(color: AppColors.gray6),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(25),
            boxShadow: AppColors.dropShadow,
          ),
          child: TextField(
            controller: _landlordCodeController,
            textCapitalization: TextCapitalization.characters,
            style: AppTextStyles.bodyRegular14(color: AppColors.black),
            decoration: _pillDecoration('임대인 초대 코드 (예: AB12CD)'),
          ),
        ),
      ],
    );
  }

  Widget _roleCard(_RoleOption option) {
    final selected = _selectedRole == option.role;
    return GestureDetector(
      onTap: () => setState(() => _selectedRole = option.role),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 25),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(5),
          border: Border.all(
            color: selected ? AppColors.brandMain : Colors.transparent,
            width: 2,
          ),
          boxShadow: AppColors.dropShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(option.title, style: AppTextStyles.subtitleBold22(color: AppColors.brandDarkest)),
            const SizedBox(height: 7),
            Text(option.description, style: AppTextStyles.bodyRegular14(color: AppColors.gray8)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('회원가입', style: AppTextStyles.titleBold30(color: AppColors.brandDark)),
              const SizedBox(height: 32),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: AppColors.dropShadow,
                ),
                child: TextField(
                  controller: _nameController,
                  style: AppTextStyles.bodyRegular14(color: AppColors.black),
                  decoration: _pillDecoration('이름'),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: AppColors.dropShadow,
                ),
                child: TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: AppTextStyles.bodyRegular14(color: AppColors.black),
                  decoration: _pillDecoration('이메일'),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: AppColors.dropShadow,
                ),
                child: TextField(
                  controller: _passwordController,
                  obscureText: true,
                  style: AppTextStyles.bodyRegular14(color: AppColors.black),
                  decoration: _pillDecoration('비밀번호'),
                ),
              ),
              const SizedBox(height: 32),
              Text('이용 유형 선택', style: AppTextStyles.titleBold30(color: AppColors.brandDark)),
              const SizedBox(height: 20),
              for (final option in _roleOptions) ...[
                _roleCard(option),
                const SizedBox(height: 20),
              ],
              if (_selectedRole == UserRole.technician) _technicianFields(),
              if (_selectedRole == UserRole.tenant) _tenantFields(),
              if (_errorMessage != null) ...[
                Text(_errorMessage!, style: AppTextStyles.bodyRegular12(color: AppColors.accentRed)),
                const SizedBox(height: 12),
              ],
              SizedBox(
                height: 47,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.brandLight,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.white),
                        )
                      : Text('시작하기', style: AppTextStyles.subtitleBold18(color: AppColors.white)),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => context.canPop() ? context.pop() : context.go('/login'),
                child: Text('이미 계정이 있으신가요? 로그인하기', style: AppTextStyles.bodyRegular14(color: AppColors.gray6)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
