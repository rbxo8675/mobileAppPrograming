import 'package:flutter/material.dart';
import 'dart:async';
import '../models/recipe.dart';

class CookingGuideView extends StatefulWidget {
  final Recipe recipe;

  const CookingGuideView({super.key, required this.recipe});

  @override
  State<CookingGuideView> createState() => _CookingGuideViewState();
}

class _CookingGuideViewState extends State<CookingGuideView> {
  int _currentStep = 0;
  bool _isPlaying = false;
  bool _isMuted = false;
  int _timerSeconds = 0;
  bool _isTimerActive = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  double get progress => (_currentStep + 1) / widget.recipe.steps.length;

  void _toggleVoice() {
    setState(() => _isPlaying = !_isPlaying);
    
    if (_isPlaying) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${_currentStep + 1}단계: ${widget.recipe.steps[_currentStep].instruction}'),
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _nextStep() {
    if (_currentStep < widget.recipe.steps.length - 1) {
      setState(() {
        _currentStep++;
        _isPlaying = false;
        _isTimerActive = false;
        _timerSeconds = 0;
      });
      _timer?.cancel();
    } else {
      _showCompletionDialog();
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
        _isPlaying = false;
        _isTimerActive = false;
        _timerSeconds = 0;
      });
      _timer?.cancel();
    }
  }

  void _startTimer(int minutes) {
    setState(() {
      _timerSeconds = minutes * 60;
      _isTimerActive = true;
    });
    
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timerSeconds > 0) {
        setState(() => _timerSeconds--);
      } else {
        timer.cancel();
        setState(() => _isTimerActive = false);
        _showTimerCompleteSnackBar();
      }
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    setState(() {
      _isTimerActive = false;
      _timerSeconds = 0;
    });
  }

  String _formatTime(int seconds) {
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  void _showTimerCompleteSnackBar() {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⏰ 타이머가 완료되었습니다!'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('요리 완성! 🎉'),
        content: const Text('멋진 요리가 완성되었습니다!\n완성된 요리 사진을 찍어서 기록해보세요.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('완료'),
          ),
          FilledButton.icon(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('📸 사진이 저장되었습니다!')),
              );
            },
            icon: const Icon(Icons.camera_alt),
            label: const Text('사진 촬영'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final currentStepText = widget.recipe.steps[_currentStep].instruction;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.recipe.title),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showRecipeInfo(context),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildProgressBar(scheme),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCurrentStepCard(scheme, currentStepText),
                  const SizedBox(height: 16),
                  _buildTimerCard(scheme),
                  const SizedBox(height: 16),
                  _buildIngredientsCard(scheme),
                ],
              ),
            ),
          ),
          _buildVoiceControls(scheme),
        ],
      ),
    );
  }

  Widget _buildProgressBar(ColorScheme scheme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '단계 ${_currentStep + 1} / ${widget.recipe.steps.length}',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '${(progress * 100).round()}% 완료',
                style: TextStyle(
                  color: scheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: scheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(scheme.primary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentStepCard(ColorScheme scheme, String stepText) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: scheme.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${_currentStep + 1}',
                      style: TextStyle(
                        color: scheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '단계 ${_currentStep + 1}',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              stepText,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                height: 1.6,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimerCard(ColorScheme scheme) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              _formatTime(_timerSeconds),
              style: TextStyle(
                fontSize: 56,
                fontWeight: FontWeight.bold,
                color: _isTimerActive ? scheme.primary : scheme.onSurfaceVariant,
                fontFamily: 'monospace',
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FilledButton.tonalIcon(
                  onPressed: _isTimerActive ? null : () => _startTimer(5),
                  icon: const Icon(Icons.timer),
                  label: const Text('5분'),
                ),
                const SizedBox(width: 8),
                FilledButton.tonalIcon(
                  onPressed: _isTimerActive ? null : () => _startTimer(10),
                  icon: const Icon(Icons.timer),
                  label: const Text('10분'),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: _isTimerActive ? _stopTimer : null,
                  icon: const Icon(Icons.stop),
                  label: const Text('정지'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIngredientsCard(ColorScheme scheme) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '필요한 재료',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            ...widget.recipe.ingredients.map((ingredient) {
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle_outline, 
                      size: 20, 
                      color: scheme.primary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        ingredient,
                        style: const TextStyle(fontSize: 15),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildVoiceControls(ColorScheme scheme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            _ControlButton(
              icon: Icons.skip_previous,
              onTap: _prevStep,
              enabled: _currentStep > 0,
              color: scheme.surfaceContainerHighest,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton.icon(
                onPressed: _toggleVoice,
                icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
                label: Text(_isPlaying ? '일시정지' : '음성 가이드'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            _ControlButton(
              icon: Icons.volume_off,
              onTap: () => setState(() => _isMuted = !_isMuted),
              enabled: true,
              color: _isMuted ? scheme.errorContainer : scheme.surfaceContainerHighest,
            ),
            const SizedBox(width: 12),
            _ControlButton(
              icon: _currentStep == widget.recipe.steps.length - 1 
                  ? Icons.check 
                  : Icons.skip_next,
              onTap: _nextStep,
              enabled: true,
              color: scheme.primaryContainer,
            ),
          ],
        ),
      ),
    );
  }

  void _showRecipeInfo(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.recipe.title,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            _InfoRow(
              icon: Icons.schedule,
              label: '조리시간',
              value: '${widget.recipe.durationMinutes}분',
            ),
            if (widget.recipe.servings != null)
              _InfoRow(
                icon: Icons.people_alt,
                label: '인분',
                value: '${widget.recipe.servings}인분',
              ),
            if (widget.recipe.difficulty != null)
              _InfoRow(
                icon: Icons.signal_cellular_alt,
                label: '난이도',
                value: widget.recipe.difficulty!,
              ),
          ],
        ),
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool enabled;
  final Color color;

  const _ControlButton({
    required this.icon,
    required this.onTap,
    required this.enabled,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: enabled ? color : color.withOpacity(0.3),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 56,
          height: 56,
          alignment: Alignment.center,
          child: Icon(
            icon,
            color: enabled 
                ? Theme.of(context).colorScheme.onSurface 
                : Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 12),
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.w600)),
          Text(value),
        ],
      ),
    );
  }
}
