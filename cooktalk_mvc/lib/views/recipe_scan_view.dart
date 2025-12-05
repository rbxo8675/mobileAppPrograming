import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../data/services/ocr_service.dart';
import '../models/recipe.dart';
import '../core/utils/logger.dart';
import '../core/utils/snackbar_utils.dart';
import '../widgets/error_state.dart';

class RecipeScanView extends StatefulWidget {
  const RecipeScanView({super.key});

  @override
  State<RecipeScanView> createState() => _RecipeScanViewState();
}

class _RecipeScanViewState extends State<RecipeScanView> {
  final OcrService _ocrService = OcrService();
  final ImagePicker _imagePicker = ImagePicker();
  
  File? _selectedImage;
  bool _isProcessing = false;
  String? _extractedText;
  Recipe? _scannedRecipe;
  String? _errorMessage;

  @override
  void dispose() {
    _ocrService.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (pickedFile == null) return;

      setState(() {
        _selectedImage = File(pickedFile.path);
        _extractedText = null;
        _scannedRecipe = null;
        _errorMessage = null;
      });

      await _processImage();
    } catch (e) {
      Logger.error('Failed to pick image', e);
      setState(() {
        _errorMessage = '이미지를 선택할 수 없습니다';
      });
    }
  }

  Future<void> _processImage() async {
    if (_selectedImage == null) return;

    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      final extractedText = await _ocrService.extractTextFromImage(_selectedImage!);
      setState(() {
        _extractedText = extractedText;
      });

      final recipeData = await _ocrService.parseRecipeFromText(extractedText);
      
      final recipe = _convertToRecipe(recipeData);
      
      setState(() {
        _scannedRecipe = recipe;
        _isProcessing = false;
      });

      Logger.info('Recipe scanned successfully: ${recipe.title}');
    } catch (e) {
      Logger.error('Failed to process image', e);
      setState(() {
        _isProcessing = false;
        _errorMessage = '레시피를 인식할 수 없습니다. 다른 이미지를 시도해보세요.';
      });
    }
  }

  Recipe _convertToRecipe(Map<String, dynamic> data) {
    final stepsData = data['steps'] as List<dynamic>? ?? [];
    final steps = stepsData.map((step) {
      if (step is Map<String, dynamic>) {
        return RecipeStep(
          instruction: step['instruction'] as String? ?? '',
          timerMinutes: step['timerMinutes'] as int?,
          autoStart: step['autoStart'] as bool? ?? false,
        );
      } else if (step is String) {
        return RecipeStep(instruction: step);
      }
      return RecipeStep(instruction: '');
    }).toList();

    return Recipe(
      id: 'scanned_${DateTime.now().millisecondsSinceEpoch}',
      title: data['title'] as String? ?? '스캔된 레시피',
      durationMinutes: data['durationMinutes'] as int? ?? 30,
      ingredients: (data['ingredients'] as List<dynamic>?)?.cast<String>() ?? [],
      steps: steps,
      description: data['description'] as String?,
      servings: data['servings'] as int?,
      difficulty: data['difficulty'] as String?,
      tags: (data['tags'] as List<dynamic>?)?.cast<String>() ?? [],
    );
  }

  void _saveRecipe() {
    if (_scannedRecipe == null) return;
    
    Navigator.pop(context, _scannedRecipe);
    SnackBarUtils.showSuccess(
      context,
      '레시피가 저장되었습니다',
    );
  }

  void _editRecipe() {
    if (_scannedRecipe == null) return;
    
    SnackBarUtils.showInfo(
      context,
      '레시피 수정 기능은 곧 추가됩니다',
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('레시피북 스캔'),
        centerTitle: false,
      ),
      body: _selectedImage == null
          ? _buildImagePickerPrompt(scheme)
          : _buildScanResult(scheme),
      floatingActionButton: _selectedImage == null
          ? null
          : FloatingActionButton.extended(
              onPressed: _isProcessing ? null : () => _pickImage(ImageSource.camera),
              icon: const Icon(Icons.camera_alt),
              label: const Text('다시 촬영'),
            ),
    );
  }

  Widget _buildImagePickerPrompt(ColorScheme scheme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.book_outlined,
              size: 100,
              color: scheme.primary.withOpacity(0.5),
            ),
            const SizedBox(height: 24),
            Text(
              '레시피북을 스캔하세요',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              '요리책이나 레시피 사진을 촬영하면\nAI가 자동으로 레시피를 추출합니다',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 48),
            FilledButton.icon(
              onPressed: () => _pickImage(ImageSource.camera),
              icon: const Icon(Icons.camera_alt),
              label: const Text('카메라로 촬영'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () => _pickImage(ImageSource.gallery),
              icon: const Icon(Icons.photo_library),
              label: const Text('갤러리에서 선택'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScanResult(ColorScheme scheme) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildImagePreview(scheme),
                const SizedBox(height: 16),
                if (_isProcessing) _buildLoadingCard(scheme),
                if (_errorMessage != null) _buildErrorCard(scheme),
                if (_extractedText != null && !_isProcessing) 
                  _buildExtractedTextCard(scheme),
                if (_scannedRecipe != null) _buildRecipeCard(scheme),
              ],
            ),
          ),
        ),
        if (_scannedRecipe != null) _buildBottomActions(scheme),
      ],
    );
  }

  Widget _buildImagePreview(ColorScheme scheme) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Image.file(
              _selectedImage!,
              fit: BoxFit.cover,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Icon(Icons.photo, size: 16, color: scheme.primary),
                const SizedBox(width: 8),
                Text(
                  '선택된 이미지',
                  style: TextStyle(
                    color: scheme.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: _isProcessing ? null : () => _pickImage(ImageSource.gallery),
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('변경'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingCard(ColorScheme scheme) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 80,
                  height: 80,
                  child: CircularProgressIndicator(
                    color: scheme.primary,
                    strokeWidth: 6,
                  ),
                ),
                Icon(
                  Icons.auto_awesome,
                  size: 40,
                  color: scheme.primary,
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              'AI가 레시피를 분석하고 있습니다',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              '텍스트를 추출하고 구조화하는 중...',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorCard(ColorScheme scheme) {
    return ErrorState.ocrError(
      onRetry: () async {
        setState(() {
          _errorMessage = null;
          _selectedImage = null;
        });
        await _pickImage(ImageSource.camera);
      },
    );
  }

  Widget _buildExtractedTextCard(ColorScheme scheme) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ExpansionTile(
        leading: Icon(Icons.text_fields, color: scheme.primary),
        title: const Text('추출된 텍스트'),
        subtitle: Text('${_extractedText!.length}자'),
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
            ),
            child: Text(
              _extractedText!,
              style: TextStyle(
                fontSize: 12,
                color: scheme.onSurfaceVariant,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecipeCard(ColorScheme scheme) {
    final recipe = _scannedRecipe!;
    
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
                Icon(Icons.check_circle, color: scheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '레시피 인식 완료',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: scheme.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              recipe.title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            if (recipe.description != null)
              Text(
                recipe.description!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                _InfoChip(
                  icon: Icons.schedule,
                  label: '${recipe.durationMinutes}분',
                  scheme: scheme,
                ),
                if (recipe.servings != null)
                  _InfoChip(
                    icon: Icons.people_alt,
                    label: '${recipe.servings}인분',
                    scheme: scheme,
                  ),
                if (recipe.difficulty != null)
                  _InfoChip(
                    icon: Icons.signal_cellular_alt,
                    label: recipe.difficulty!,
                    scheme: scheme,
                  ),
              ],
            ),
            if (recipe.tags.isNotEmpty) ...[
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: recipe.tags.map((tag) => Chip(
                  label: Text(tag),
                  labelStyle: TextStyle(fontSize: 12, color: scheme.onSecondaryContainer),
                  backgroundColor: scheme.secondaryContainer,
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                )).toList(),
              ),
            ],
            const SizedBox(height: 20),
            Text(
              '재료 (${recipe.ingredients.length}개)',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ...recipe.ingredients.take(3).map((ingredient) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Icon(Icons.fiber_manual_record, size: 8, color: scheme.primary),
                  const SizedBox(width: 8),
                  Text(ingredient),
                ],
              ),
            )),
            if (recipe.ingredients.length > 3)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '외 ${recipe.ingredients.length - 3}개',
                  style: TextStyle(
                    fontSize: 12,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
            const SizedBox(height: 16),
            Text(
              '조리 단계 (${recipe.steps.length}단계)',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ...recipe.steps.take(2).toList().asMap().entries.map((entry) {
              final index = entry.key;
              final step = entry.value;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: scheme.primaryContainer,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: scheme.onPrimaryContainer,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: Text(step.instruction)),
                  ],
                ),
              );
            }),
            if (recipe.steps.length > 2)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '외 ${recipe.steps.length - 2}단계',
                  style: TextStyle(
                    fontSize: 12,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomActions(ColorScheme scheme) {
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
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _editRecipe,
                icon: const Icon(Icons.edit),
                label: const Text('수정'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: FilledButton.icon(
                onPressed: _saveRecipe,
                icon: const Icon(Icons.save),
                label: const Text('레시피 저장'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final ColorScheme scheme;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.scheme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: scheme.onSurfaceVariant),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: scheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
