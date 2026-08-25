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

class _SignupScreenState extends State<SignupScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  UserRole _selectedRole = UserRole.tenant;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
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
          );
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
