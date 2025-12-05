import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../controllers/recipe_controller.dart';

class AddRecipeSheet extends StatefulWidget {
  const AddRecipeSheet({super.key});

  @override
  State<AddRecipeSheet> createState() => _AddRecipeSheetState();
}

class _AddRecipeSheetState extends State<AddRecipeSheet>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;

  // Manual form controllers
  final _titleCtrl = TextEditingController();
  final _durationCtrl = TextEditingController(text: '20');
  final _ingredientsCtrl = TextEditingController();
  final _stepsCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  
  // 이미지 선택
  final ImagePicker _picker = ImagePicker();
  XFile? _selectedImage;

  // YouTube
  final _ytCtrl = TextEditingController();
  bool _loadingYt = false;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    _titleCtrl.dispose();
    _durationCtrl.dispose();
    _ingredientsCtrl.dispose();
    _stepsCtrl.dispose();
    _descCtrl.dispose();
    _ytCtrl.dispose();
    super.dispose();
  }
  
  /// 갤러리에서 이미지 선택
  Future<void> _pickImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      
      if (image != null) {
        setState(() {
          _selectedImage = image;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('이미지 선택 실패: $e')),
        );
      }
    }
  }
  
  /// 카메라로 사진 촬영
  Future<void> _pickImageFromCamera() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      
      if (image != null) {
        setState(() {
          _selectedImage = image;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('사진 촬영 실패: $e')),
        );
      }
    }
  }
  
  /// 이미지 선택 다이얼로그
  void _showImagePickerDialog() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('갤러리에서 선택'),
              onTap: () {
                Navigator.pop(context);
                _pickImageFromGallery();
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('카메라로 촬영'),
              onTap: () {
                Navigator.pop(context);
                _pickImageFromCamera();
              },
            ),
            if (_selectedImage != null)
              ListTile(
                leading: const Icon(Icons.delete),
                title: const Text('이미지 제거'),
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    _selectedImage = null;
                  });
                },
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 12,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 4,
              width: 36,
              decoration: BoxDecoration(
                color: scheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            TabBar(
              controller: _tab,
              tabs: const [
                Tab(text: '수기 입력'),
                Tab(text: 'YouTube 추출'),
              ],
            ),
            Flexible(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxHeight: 420,
                  minHeight: 200,
                ),
                child: TabBarView(
                  controller: _tab,
                  children: [
                    _buildManual(context),
                    _buildYouTube(context),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildManual(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          TextField(
            controller: _titleCtrl,
            decoration: const InputDecoration(labelText: '제목'),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _descCtrl,
            decoration: const InputDecoration(labelText: '설명(선택)'),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _durationCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: '소요 시간(분)'),
          ),
          const SizedBox(height: 12),
          
          // === 이미지 선택 섹션 ===
          _buildImagePicker(),
          
          const SizedBox(height: 12),
          TextField(
            controller: _ingredientsCtrl,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: '재료 (쉼표로 구분 또는 줄바꿈)',
              hintText: '예) 김치, 밥, 계란\n또는 줄바꿈으로 입력',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _stepsCtrl,
            maxLines: 5,
            decoration: const InputDecoration(
              labelText: '조리 단계 (줄마다 1단계)',
              hintText: '예) 김치볶기\n밥 넣고 비비기\n계란 올리기',
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () async {
                final title = _titleCtrl.text.trim();
                if (title.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('제목을 입력해 주세요')),
                  );
                  return;
                }
                final duration = int.tryParse(_durationCtrl.text) ?? 20;
                final ingredients = _splitLinesOrComma(_ingredientsCtrl.text);
                final steps = _splitLines(_stepsCtrl.text);
                
                try {
                  // 데이터베이스에 저장
                  await context.read<RecipeController>().addManualRecipe(
                        title: title,
                        durationMinutes: duration,
                        ingredients: ingredients,
                        steps: steps,
                        imagePath: _selectedImage?.path, // 로컬 파일 경로 저장
                        description: _descCtrl.text.trim().isEmpty
                            ? null
                            : _descCtrl.text.trim(),
                  );
                  
                  if (!mounted) return;
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('레시피가 저장되었습니다!')),
                  );
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('저장 실패: $e')),
                  );
                }
              },
              child: const Text('추가하기'),
            ),
          ),
        ],
      ),
    );
  }
  
  /// 이미지 선택 위젯
  Widget _buildImagePicker() {
    return InkWell(
      onTap: _showImagePickerDialog,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        height: 200,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.5),
            width: 1,
          ),
        ),
        child: _selectedImage == null
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_photo_alternate,
                    size: 48,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '이미지 추가 (선택)',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '탭하여 갤러리 또는 카메라 선택',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              )
            : Stack(
                children: [
                  // 선택된 이미지 표시
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      File(_selectedImage!.path),
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  // 변경 버튼
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.edit, color: Colors.white),
                        onPressed: _showImagePickerDialog,
                        tooltip: '이미지 변경',
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildYouTube(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: _ytCtrl,
          decoration: const InputDecoration(
            labelText: 'YouTube 링크',
            hintText: 'https://www.youtube.com/watch?v=...'
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: _loadingYt
                ? null
                : () async {
                    final url = _ytCtrl.text.trim();
                    if (url.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('링크를 입력해 주세요')),
                      );
                      return;
                    }
                    setState(() => _loadingYt = true);
                    await context.read<RecipeController>().importFromYouTube(url);
                    if (!mounted) return;
                    setState(() => _loadingYt = false);
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('YouTube에서 레시피를 추가했습니다')),
                    );
                  },
            child: _loadingYt
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('가져오기'),
          ),
        ),
      ],
    );
  }

  List<String> _splitLinesOrComma(String raw) {
    if (raw.contains(',')) {
      return raw
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }
    return _splitLines(raw);
  }

  List<String> _splitLines(String raw) {
    return raw
        .split(RegExp(r'[\r\n]+'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }
}
