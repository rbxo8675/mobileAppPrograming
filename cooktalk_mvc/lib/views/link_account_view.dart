import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/auth_controller.dart';
import '../core/utils/logger.dart';

class LinkAccountView extends StatefulWidget {
  const LinkAccountView({super.key});

  @override
  State<LinkAccountView> createState() => _LinkAccountViewState();
}

class _LinkAccountViewState extends State<LinkAccountView> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _displayNameController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _displayNameController.dispose();
    super.dispose();
  }

  Future<void> _linkWithEmail() async {
    if (!_formKey.currentState!.validate()) return;

    final authController = context.read<AuthController>();
    final success = await authController.linkAnonymousWithEmail(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      displayName: _displayNameController.text.trim(),
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('계정이 성공적으로 연결되었습니다!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop(true);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authController.errorMessage ?? '계정 연결에 실패했습니다.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _linkWithGoogle() async {
    final authController = context.read<AuthController>();
    final success = await authController.linkAnonymousWithGoogle();

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Google 계정이 성공적으로 연결되었습니다!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop(true);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authController.errorMessage ?? 'Google 계정 연결에 실패했습니다.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authController = context.watch<AuthController>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('로그인 / 회원가입'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 안내 메시지
              Card(
                color: theme.colorScheme.primaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 48,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '로그인하고 더 많은 기능을 이용하세요',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '지금은 게스트로 사용 중입니다.\n로그인하면 모든 기기에서 데이터를 확인할 수 있어요.',
                        style: theme.textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Google 로그인
              ElevatedButton.icon(
                onPressed: authController.isLoading ? null : _linkWithGoogle,
                icon: Image.asset(
                  'assets/images/google_logo.png',
                  height: 24,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(Icons.login);
                  },
                ),
                label: const Text('Google로 계속하기'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black87,
                ),
              ),
              const SizedBox(height: 24),

              // 구분선
              Row(
                children: [
                  const Expanded(child: Divider()),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      '또는',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  const Expanded(child: Divider()),
                ],
              ),
              const SizedBox(height: 24),

              // 이메일 폼
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 닉네임
                    TextFormField(
                      controller: _displayNameController,
                      decoration: const InputDecoration(
                        labelText: '닉네임',
                        hintText: '사용할 닉네임을 입력하세요',
                        prefixIcon: Icon(Icons.person),
                        border: OutlineInputBorder(),
                      ),
                      textInputAction: TextInputAction.next,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return '닉네임을 입력하세요';
                        }
                        if (value.trim().length < 2) {
                          return '닉네임은 2자 이상이어야 합니다';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // 이메일
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: '이메일',
                        hintText: 'example@email.com',
                        prefixIcon: Icon(Icons.email),
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return '이메일을 입력하세요';
                        }
                        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                            .hasMatch(value)) {
                          return '올바른 이메일 형식이 아닙니다';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // 비밀번호
                    TextFormField(
                      controller: _passwordController,
                      decoration: InputDecoration(
                        labelText: '비밀번호',
                        hintText: '6자 이상 입력하세요',
                        prefixIcon: const Icon(Icons.lock),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                        border: const OutlineInputBorder(),
                      ),
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.done,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '비밀번호를 입력하세요';
                        }
                        if (value.length < 6) {
                          return '비밀번호는 6자 이상이어야 합니다';
                        }
                        return null;
                      },
                      onFieldSubmitted: (_) => _linkWithEmail(),
                    ),
                    const SizedBox(height: 24),

                    // 연결 버튼
                    FilledButton(
                      onPressed: authController.isLoading ? null : _linkWithEmail,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: authController.isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              '로그인 / 회원가입',
                              style: TextStyle(fontSize: 16),
                            ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 나중에 하기
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('나중에 하기'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
