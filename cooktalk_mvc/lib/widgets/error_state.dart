import 'package:flutter/material.dart';

class ErrorState extends StatelessWidget {
  final String message;
  final String? details;
  final VoidCallback? onRetry;
  final IconData icon;

  const ErrorState({
    super.key,
    required this.message,
    this.details,
    this.onRetry,
    this.icon = Icons.error_outline,
  });

  factory ErrorState.network({VoidCallback? onRetry}) {
    return ErrorState(
      message: '네트워크 연결을 확인해주세요',
      details: '인터넷 연결이 불안정하거나\n연결되어 있지 않습니다',
      icon: Icons.wifi_off,
      onRetry: onRetry,
    );
  }

  factory ErrorState.apiError({String? message, VoidCallback? onRetry}) {
    return ErrorState(
      message: message ?? '서버에 문제가 발생했습니다',
      details: '잠시 후 다시 시도해주세요',
      icon: Icons.cloud_off,
      onRetry: onRetry,
    );
  }

  factory ErrorState.geminiError({VoidCallback? onRetry}) {
    return ErrorState(
      message: 'AI 분석 중 오류가 발생했습니다',
      details: 'Gemini API 키를 확인하거나\n잠시 후 다시 시도해주세요',
      icon: Icons.psychology_outlined,
      onRetry: onRetry,
    );
  }

  factory ErrorState.ocrError({VoidCallback? onRetry}) {
    return ErrorState(
      message: '텍스트를 인식할 수 없습니다',
      details: '이미지가 선명하지 않거나\n레시피 텍스트가 없습니다',
      icon: Icons.document_scanner_outlined,
      onRetry: onRetry,
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: scheme.errorContainer.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 40,
                color: scheme.error,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              message,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: scheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            if (details != null) ...[
              const SizedBox(height: 8),
              Text(
                details!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('다시 시도'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
